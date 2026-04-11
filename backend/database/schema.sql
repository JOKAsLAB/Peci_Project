-- =============================================================
-- PECI PROJECT — DATABASE SCHEMA
-- PostgreSQL 18
-- =============================================================


-- =============================================================
-- BLOCK 0: ENUM TYPES
-- Native PostgreSQL ENUMs — used by the models via SQLAlchemy.
-- Defined before the tables that depend on them.
-- =============================================================

CREATE TYPE user_role_enum        AS ENUM ('Student', 'Professor', 'Admin');
CREATE TYPE user_status_enum      AS ENUM ('Active', 'Suspended', 'Deactivated');
CREATE TYPE material_status_enum  AS ENUM ('Pending', 'Indexed', 'Error');
CREATE TYPE exercise_type_enum    AS ENUM ('Multiple Choice', 'True/False');
CREATE TYPE difficulty_level_enum AS ENUM ('Easy', 'Medium', 'Hard');
CREATE TYPE progress_status_enum  AS ENUM ('Correct', 'Incorrect', 'Partial');
CREATE TYPE sync_status_enum      AS ENUM ('Pending', 'Synced', 'Failed');
CREATE TYPE request_status_enum   AS ENUM ('pending', 'approved', 'rejected');
CREATE TYPE request_type_enum     AS ENUM ('access', 'platform', 'operations', 'other');


-- =============================================================
-- BLOCK 1: USERS AND PERSONAS
-- =============================================================

-- Central table: credentials and data common to all users.
-- Role defines which sub-table the user belongs to.
-- Status controls account state (active, suspended, deactivated).
CREATE TABLE Base_User (
    ID_User           UUID                PRIMARY KEY DEFAULT gen_random_uuid(),
    Name              VARCHAR(100)        NOT NULL,
    Email             VARCHAR(150)        UNIQUE NOT NULL,
    Password_Hash     TEXT                NOT NULL,
    Role              user_role_enum      NOT NULL,
    Status            user_status_enum    NOT NULL DEFAULT 'Active',
    Registration_Date DATE                NOT NULL DEFAULT CURRENT_DATE
);


-- Student-specific data: gamification and progression.
-- ID_Student is both PK and FK — it IS the ID_User from Base_User.
CREATE TABLE Student (
    ID_Student    UUID          PRIMARY KEY REFERENCES Base_User(ID_User) ON DELETE CASCADE,
    Current_Level INT           NOT NULL DEFAULT 1,
    Total_XP      INT           NOT NULL DEFAULT 0,
    Streak_Days   INT           NOT NULL DEFAULT 0,     -- streak atual, tipo Duolingo
    Last_Access   TIMESTAMP
);


-- Professor-specific data: professional info.
-- ID_Professor is both PK and FK — it IS the ID_User from Base_User.
CREATE TABLE Professor (
    ID_Professor  UUID          PRIMARY KEY REFERENCES Base_User(ID_User) ON DELETE CASCADE,
    Department    VARCHAR(100),
    Office        VARCHAR(50),
    Short_Bio     TEXT
);


-- Admin-specific data: system management.
-- ID_Admin is both PK and FK — it IS the ID_User from Base_User.
-- Privilege_Level: 1 (basic), 2 (moderator), 3 (superadmin).
CREATE TABLE Admin (
    ID_Admin        UUID        PRIMARY KEY REFERENCES Base_User(ID_User) ON DELETE CASCADE,
    Privilege_Level SMALLINT    NOT NULL CHECK (Privilege_Level BETWEEN 1 AND 3),
    Contact         VARCHAR(150)
);


-- =============================================================
-- BLOCK 2: ACADEMIC CORE
-- =============================================================

-- A Course Unit (UC) is a subject like Digital Systems or Computer Architecture.
-- Created by Admins, managed by Professors.
CREATE TABLE Course_Unit (
    ID_UC           INT       PRIMARY KEY,
    Name            VARCHAR(100) NOT NULL,
    Semester        VARCHAR(20),
    Curricular_Year SMALLINT
);


-- Junction table: which professors are allowed to manage which Course Units.
-- A professor can manage N UCs; a UC can have N professors.
CREATE TABLE Professor_UC (
    ID_Professor  UUID  NOT NULL REFERENCES Professor(ID_Professor) ON DELETE CASCADE,
    ID_UC         INT   NOT NULL REFERENCES Course_Unit(ID_UC) ON DELETE CASCADE,
    PRIMARY KEY (ID_Professor, ID_UC)
);


-- Junction table: which students are enrolled in which Course Units.
-- A student can be enrolled in N UCs; a UC can have N students.
CREATE TABLE Student_UC (
    ID_Student UUID NOT NULL REFERENCES Student(ID_Student) ON DELETE CASCADE,
    ID_UC      INT  NOT NULL REFERENCES Course_Unit(ID_UC) ON DELETE CASCADE,
    PRIMARY KEY (ID_Student, ID_UC)
);


-- A Topic belongs to one Course Unit.
-- PK is composite (ID_UC + Name) because topic names are unique within a UC.
-- N_Order defines the order topics appear in the course path.
CREATE TABLE Topic (
    ID_UC    INT          NOT NULL REFERENCES Course_Unit(ID_UC) ON DELETE CASCADE,
    Name     VARCHAR(100) NOT NULL,
    N_Order  SMALLINT     NOT NULL,     -- ordem definido de forma manual
    PRIMARY KEY (ID_UC, Name),
    --Para garantir que não há duplicados de ordem
    --DEFERRABLE ->  protege a integridade durante reordenações
    UNIQUE (ID_UC, N_Order) DEFERRABLE INITIALLY DEFERRED
);


-- A Teaching Material is a PDF uploaded by a professor to feed the RAG pipeline.
-- Status tracks the processing state of the file.
-- Extracted_Text stores the raw text extracted from the PDF for the LLM.
-- File_Path stores the path/URL to the file on disk or object storage.
CREATE TABLE Teaching_Material (
    ID_Material    UUID                  PRIMARY KEY DEFAULT gen_random_uuid(),
    ID_UC          INT                   NOT NULL REFERENCES Course_Unit(ID_UC) ON DELETE RESTRICT,
    ID_Professor   UUID                  NOT NULL REFERENCES Professor(ID_Professor) ON DELETE RESTRICT,
    Status         material_status_enum  NOT NULL DEFAULT 'Pending',
    Title          VARCHAR(200)          NOT NULL,
    Upload_Date    TIMESTAMP             NOT NULL DEFAULT NOW()
);


-- An Exercise is linked to exactly one Topic and one Course Unit.
-- Material_Ref is nullable: only AI-generated exercises reference a Teaching Material.
-- Solution is JSONB to support different formats per exercise type.
-- Difficulty is text: Easy, Medium, Hard.
CREATE TABLE Exercise (
    ID_Exercise  UUID                  PRIMARY KEY DEFAULT gen_random_uuid(),
    ID_UC        INT                   NOT NULL REFERENCES Course_Unit(ID_UC) ON DELETE RESTRICT,
    Topic_Name   VARCHAR(100)          NOT NULL,
    Material_Ref UUID                  REFERENCES Teaching_Material(ID_Material) ON DELETE SET NULL,
    Type         exercise_type_enum    NOT NULL,
    Question     TEXT                  NOT NULL,
    Solution     JSONB                 NOT NULL,
    Difficulty   difficulty_level_enum NOT NULL,
    Explanation  TEXT,
    Published    BOOLEAN               NOT NULL DEFAULT false,
    FOREIGN KEY (ID_UC, Topic_Name) REFERENCES Topic(ID_UC, Name) ON DELETE RESTRICT
);


-- =============================================================
-- BLOCK 3: GAMIFICATION AND PROGRESSION
-- =============================================================

-- Records each attempt a student makes on an exercise.
-- Sync_Status tracks whether this record has been synced with the mobile app.
-- Status: whether the student answered correctly or not.
CREATE TABLE Progress (
    ID_Progress  UUID                PRIMARY KEY DEFAULT gen_random_uuid(),
    ID_Student   UUID                NOT NULL REFERENCES Student(ID_Student) ON DELETE CASCADE,
    ID_Exercise  UUID                NOT NULL REFERENCES Exercise(ID_Exercise) ON DELETE CASCADE,
    Attempts     INT                 NOT NULL DEFAULT 1,
    Status       progress_status_enum NOT NULL,
    Date         TIMESTAMP           NOT NULL DEFAULT NOW(),
    XP_Earned    INT                 NOT NULL DEFAULT 0,
    Sync_Status  sync_status_enum    NOT NULL DEFAULT 'Pending'
);


-- One record per student per day they studied.
-- Used to validate consecutive-day streaks.
-- Sync_Status: same mobile sync logic as Progress.
CREATE TABLE Streak (
    ID_Streak   UUID              PRIMARY KEY DEFAULT gen_random_uuid(),
    ID_Student  UUID              NOT NULL REFERENCES Student(ID_Student) ON DELETE CASCADE,
    Log_Date    DATE              NOT NULL DEFAULT CURRENT_DATE,
    Sync_Status sync_status_enum  NOT NULL DEFAULT 'Pending'
);


-- =============================================================
-- BLOCK 4: ADMIN RELATED
-- =============================================================

-- A Professor sends a Request to an Admin (e.g. to create a UC, add a student).
-- ID_Admin is nullable: request starts unassigned (pending) until an admin picks it up.
-- Resolution_Date is set when the admin approves or rejects.
CREATE TABLE Request (
    ID_Request       SERIAL               PRIMARY KEY,
    ID_Professor     UUID                 NOT NULL REFERENCES Professor(ID_Professor) ON DELETE CASCADE,
    ID_Admin         UUID                 REFERENCES Admin(ID_Admin) ON DELETE SET NULL,
    Title            VARCHAR(200)         NOT NULL,
    Description      TEXT                 NOT NULL,
    Status           request_status_enum  NOT NULL DEFAULT 'pending',
    Request_Type     request_type_enum    NOT NULL DEFAULT 'other',
    Admin_Comment     TEXT,
    Creation_Date    TIMESTAMP            NOT NULL DEFAULT NOW(),
    Resolution_Date  TIMESTAMP,

    -- Consistency check: pending requests must have no resolution date;
    --                    approved/rejected must have one.
    CHECK (
        (Status = 'pending' AND Resolution_Date IS NULL)
        OR
        (Status IN ('approved', 'rejected') AND Resolution_Date IS NOT NULL)
    )
);


-- Immutable audit log of all admin actions (deleting users, changing permissions, etc.).
-- Target_ID stores the UUID or ID of the affected entity as text (flexible).
-- Target_Type describes what was affected: 'Student', 'Professor', 'Course_Unit', etc.
-- This table should NEVER allow DELETE or UPDATE — append only.
CREATE TABLE Admin_Audit_Log (
    ID_Log       SERIAL       PRIMARY KEY,
    ID_Admin     UUID         NOT NULL REFERENCES Admin(ID_Admin) ON DELETE RESTRICT,
    Action       TEXT         NOT NULL,
    Target_ID    TEXT         NOT NULL,
    Target_Type  VARCHAR(50)  NOT NULL,
    Date         TIMESTAMP    NOT NULL DEFAULT NOW()
);


-- =============================================================
-- BLOCK 5: LEARNING PATHS (PROFESSOR PATH BUILDER)
-- =============================================================

-- A Learning Path is a structured sequence of exercises created by a professor.
-- Professors use the Path Builder to define personalized learning sequences.
-- Multiple paths can exist per UC; each path can be published or draft.
CREATE TABLE Learning_Path (
    ID_Path      UUID                 PRIMARY KEY DEFAULT gen_random_uuid(),
    ID_UC        INT                  NOT NULL REFERENCES Course_Unit(ID_UC) ON DELETE CASCADE,
    ID_Professor UUID                 NOT NULL REFERENCES Professor(ID_Professor) ON DELETE CASCADE,
    Name         VARCHAR(200)         NOT NULL,
    Description  TEXT,
    Published    BOOLEAN              NOT NULL DEFAULT false,
    Created_At   TIMESTAMP            NOT NULL DEFAULT NOW(),
    Updated_At   TIMESTAMP            NOT NULL DEFAULT NOW()
);

-- Junction table: exercises in a learning path with specific order.
-- ID_Path + Order is unique to prevent duplicate positions.
-- Order defines the sequence within a path (1, 2, 3, ...).
CREATE TABLE Learning_Path_Exercise (
    ID              UUID         PRIMARY KEY DEFAULT gen_random_uuid(),
    ID_Path         UUID         NOT NULL REFERENCES Learning_Path(ID_Path) ON DELETE CASCADE,
    ID_Exercise     UUID         NOT NULL REFERENCES Exercise(ID_Exercise) ON DELETE CASCADE,
    Order_Num       SMALLINT     NOT NULL,
    UNIQUE (ID_Path, Order_Num)
);

/*
Notas:
ON DELETE CASCADE — em Student, Professor e Admin: 
se apagares o Base_User, o registo filho apaga-se automaticamente. ~
Faz sentido porque são a mesma pessoa.

ON DELETE RESTRICT — em Exercise e Teaching_Material ligados a Course_Unit: 
o PostgreSQL não te deixa apagar uma UC que ainda tem exercícios ou materiais. 
Proteção contra perda acidental de dados.

ON DELETE SET NULL — em Request.ID_Admin: 
se um admin for apagado, 
os pedidos que ele geria ficam sem admin atribuído 
(voltam a "pendentes" efetivamente) em vez de serem apagados.

Indexes — os mais úteis para as queries mais frequentes, 
como procurar o progresso de um aluno ou filtrar exercícios por UC.
*/