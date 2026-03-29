DROP SCHEMA IF EXISTS public CASCADE;
CREATE SCHEMA public;
GRANT ALL ON SCHEMA public TO peci_user;

CREATE TABLE base_user (
    "ID_User" UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    "Name" VARCHAR(100) NOT NULL,
    "Email" VARCHAR(150) UNIQUE NOT NULL,
    "Password_Hash" TEXT NOT NULL,
    "Role" VARCHAR(20) NOT NULL,
    "Status" VARCHAR(20) NOT NULL DEFAULT 'Active',
    "Registration_Date" DATE NOT NULL DEFAULT CURRENT_DATE
);

CREATE TABLE student (
    "ID_Student" UUID PRIMARY KEY REFERENCES base_user("ID_User") ON DELETE CASCADE,
    "Current_Level" INT NOT NULL DEFAULT 1,
    "Total_XP" INT NOT NULL DEFAULT 0,
    "Streak_Days" INT NOT NULL DEFAULT 0,
    "Last_Access" TIMESTAMP NULL
);

CREATE TABLE professor (
    "ID_Professor" UUID PRIMARY KEY REFERENCES base_user("ID_User") ON DELETE CASCADE,
    "Department" VARCHAR(100),
    "Office" VARCHAR(50),
    "Short_Bio" TEXT
);

CREATE TABLE admin (
    "ID_Admin" UUID PRIMARY KEY REFERENCES base_user("ID_User") ON DELETE CASCADE,
    "Privilege_Level" SMALLINT NOT NULL,
    "Contact" VARCHAR(150)
);

CREATE TABLE course_unit (
    "ID_UC" INT PRIMARY KEY,
    "Name" VARCHAR(100) NOT NULL,
    "Semester" VARCHAR(20),
    "Curricular_Year" SMALLINT
);

CREATE TABLE professor_uc (
    "ID_Professor" UUID NOT NULL REFERENCES professor("ID_Professor") ON DELETE CASCADE,
    "ID_UC" INT NOT NULL REFERENCES course_unit("ID_UC") ON DELETE CASCADE,
    PRIMARY KEY ("ID_Professor", "ID_UC")
);

CREATE TABLE topic (
    "ID_UC" INT NOT NULL REFERENCES course_unit("ID_UC") ON DELETE CASCADE,
    "Name" VARCHAR(100) NOT NULL,
    "N_Order" SMALLINT NOT NULL,
    PRIMARY KEY ("ID_UC", "Name"),
    UNIQUE ("ID_UC", "N_Order")
);

CREATE TABLE teaching_material (
    "ID_Material" UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    "ID_UC" INT NOT NULL REFERENCES course_unit("ID_UC") ON DELETE RESTRICT,
    "ID_Professor" UUID NOT NULL REFERENCES professor("ID_Professor") ON DELETE RESTRICT,
    "Status" VARCHAR(20) NOT NULL DEFAULT 'Pending',
    "Title" VARCHAR(200) NOT NULL,
    "File_Path" TEXT NOT NULL,
    "Extracted_Text" TEXT,
    "Upload_Date" TIMESTAMP NOT NULL DEFAULT NOW()
);

CREATE TABLE exercise (
    "ID_Exercise" UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    "ID_UC" INT NOT NULL,
    "Topic_Name" VARCHAR(100) NOT NULL,
    "Material_Ref" UUID NULL,
    "Type" VARCHAR(30) NOT NULL,
    "Question" TEXT NOT NULL,
    "Solution" JSONB NOT NULL,
    "Difficulty" VARCHAR(10) NOT NULL,
    "Explanation" TEXT,
    FOREIGN KEY ("ID_UC") REFERENCES course_unit("ID_UC") ON DELETE RESTRICT,
    FOREIGN KEY ("ID_UC", "Topic_Name") REFERENCES topic("ID_UC", "Name") ON DELETE RESTRICT,
    FOREIGN KEY ("Material_Ref") REFERENCES teaching_material("ID_Material") ON DELETE SET NULL
);

CREATE TABLE progress (
    "ID_Progress" UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    "ID_Student" UUID NOT NULL REFERENCES student("ID_Student") ON DELETE CASCADE,
    "ID_Exercise" UUID NOT NULL REFERENCES exercise("ID_Exercise") ON DELETE CASCADE,
    "Attempts" INT NOT NULL DEFAULT 1,
    "Status" VARCHAR(20) NOT NULL,
    "XP_Earned" INT NOT NULL DEFAULT 0,
    "Sync_Status" VARCHAR(20) NOT NULL DEFAULT 'Pending',
    "Date" TIMESTAMP NOT NULL DEFAULT NOW()
);

CREATE TABLE streak (
    "ID_Streak" UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    "ID_Student" UUID NOT NULL REFERENCES student("ID_Student") ON DELETE CASCADE,
    "Sync_Status" VARCHAR(20) NOT NULL DEFAULT 'Pending',
    "Log_Date" DATE NOT NULL DEFAULT CURRENT_DATE,
    UNIQUE ("ID_Student", "Log_Date")
);

CREATE TABLE request (
    "ID_Request" SERIAL PRIMARY KEY,
    "ID_Professor" UUID NOT NULL REFERENCES professor("ID_Professor") ON DELETE CASCADE,
    "ID_Admin" UUID NULL REFERENCES admin("ID_Admin") ON DELETE SET NULL,
    "Title" VARCHAR(200) NOT NULL,
    "Description" TEXT NOT NULL,
    "Status" VARCHAR(20) NOT NULL DEFAULT 'pending',
    "AdminComment" TEXT,
    "Creation_Date" TIMESTAMP NOT NULL DEFAULT NOW(),
    "Resolution_Date" TIMESTAMP NULL
);

CREATE TABLE admin_audit_log (
    "ID_Log" SERIAL PRIMARY KEY,
    "ID_Admin" UUID NOT NULL REFERENCES admin("ID_Admin") ON DELETE CASCADE,
    "Action" VARCHAR(100) NOT NULL,
    "Target_ID" VARCHAR(100) NOT NULL,
    "Target_Type" VARCHAR(50) NOT NULL,
    "Date" TIMESTAMP NOT NULL DEFAULT NOW()
);

CREATE INDEX idx_progress_student ON progress("ID_Student");
CREATE INDEX idx_exercise_uc ON exercise("ID_UC");
CREATE INDEX idx_exercise_topic ON exercise("ID_UC", "Topic_Name");
CREATE INDEX idx_streak_student ON streak("ID_Student");
CREATE INDEX idx_streak_date ON streak("ID_Student", "Log_Date");
CREATE INDEX idx_material_uc ON teaching_material("ID_UC");
CREATE INDEX idx_request_status ON request("Status");
CREATE INDEX idx_audit_admin ON admin_audit_log("ID_Admin");
CREATE INDEX idx_audit_target ON admin_audit_log("Target_Type", "Target_ID");

-- Seed minimo para smoke tests locais
INSERT INTO course_unit ("ID_UC", "Name", "Semester", "Curricular_Year")
VALUES (41953, 'PECI', '2S', 3)
ON CONFLICT ("ID_UC") DO NOTHING;

INSERT INTO topic ("ID_UC", "Name", "N_Order")
VALUES (41953, 'Portas Logicas', 1)
ON CONFLICT ("ID_UC", "Name") DO NOTHING;

INSERT INTO exercise (
    "ID_UC",
    "Topic_Name",
    "Material_Ref",
    "Type",
    "Question",
    "Solution",
    "Difficulty",
    "Explanation"
)
VALUES (
    41953,
    'Portas Logicas',
    NULL,
    'True/False',
    'Uma porta NOT inverte o valor logico de entrada?',
    '{"correct": true}'::jsonb,
    'Easy',
    'A porta NOT retorna o inverso logico da entrada.'
);
