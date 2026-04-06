-- =============================================================
-- PECI PROJECT — TEST INSERTS
-- Ordem respeita FKs: tabelas pai primeiro, filhas depois.
-- =============================================================


-- =============================================================
-- BLOCK 1: USERS AND PERSONAS
-- =============================================================

-- Base_User primeiro — toda a gente depende desta tabela.
-- Inserimos 1 student, 1 professor e 1 admin.
INSERT INTO Base_User (ID_User, Name, Email, Password_Hash, Role, Status) VALUES
    ('00000000-0000-0000-0000-000000000001', 'Ana Silva',    'ana.silva@ua.pt',    'hash_ana',    'Student',   'Active'),
    ('00000000-0000-0000-0000-000000000002', 'Carlos Mota',  'carlos.mota@ua.pt',  'hash_carlos', 'Professor', 'Active'),
    ('00000000-0000-0000-0000-000000000003', 'Rita Sousa',   'rita.sousa@ua.pt',   'hash_rita',   'Admin',     'Active');

-- Student: ID_Student é o mesmo UUID que o ID_User da Ana.
INSERT INTO Student (ID_Student, Current_Level, Total_XP, Streak_Days, Last_Access) VALUES
    ('00000000-0000-0000-0000-000000000001', 1, 0, 0, NOW());

-- Professor: ID_Professor é o mesmo UUID que o ID_User do Carlos.
INSERT INTO Professor (ID_Professor, Department, Office, Short_Bio) VALUES
    ('00000000-0000-0000-0000-000000000002', 'DETI', 'Ed. 1 - Sala 2.10', 'Professor de Sistemas Digitais.');

-- Admin: ID_Admin é o mesmo UUID que o ID_User da Rita.
INSERT INTO Admin (ID_Admin, Privilege_Level, Contact) VALUES
    ('00000000-0000-0000-0000-000000000003', 3, 'rita.sousa@ua.pt');


-- =============================================================
-- BLOCK 2: ACADEMIC CORE
-- =============================================================

-- Course Unit: criada pelo admin, gerida pelo professor.
INSERT INTO Course_Unit (ID_UC, Name, Semester, Curricular_Year)
VALUES (41953, 'PECI', '2S', 3);

-- Professor_UC: associa o Carlos à UC com ID 41953.
INSERT INTO Professor_UC (ID_Professor, ID_UC) VALUES
    ('00000000-0000-0000-0000-000000000002', 41953);

-- Topic: pertence à UC 41953, com ordem definida.
INSERT INTO Topic (ID_UC, Name, N_Order) VALUES
    (41953, 'Portas Lógicas',   1),
    (41953, 'Mapas de Karnaugh', 2);

-- Teaching_Material: PDF uploaded pelo Carlos para a UC 41953.
INSERT INTO Teaching_Material (ID_Material, ID_UC, ID_Professor, Status, Title, File_Path, Extracted_Text) VALUES
    (
        '00000000-0000-0000-0000-000000000010',
        41953,
        '00000000-0000-0000-0000-000000000002',
        'Indexed',
        'Aula 1 — Portas Lógicas',
        '/materials/aula1_portas_logicas.pdf',
        'Texto extraído do PDF sobre portas lógicas AND, OR, NOT...'
    );

-- Exercise: ligado à UC 41953, tópico "Portas Lógicas", referencia o material acima.
-- Solution em JSONB — formato para Multiple Choice.
INSERT INTO Exercise (ID_Exercise, ID_UC, Topic_Name, Material_Ref, Type, Question, Solution, Difficulty, Explanation) VALUES
    (
        '00000000-0000-0000-0000-000000000020',
        41953,
        'Portas Lógicas',
        '00000000-0000-0000-0000-000000000010',
        'Multiple Choice',
        'Qual é o resultado de AND(1, 0)?',
        '{"correct": "0", "options": ["0", "1"]}',
        'Easy',
        'A porta AND só devolve 1 se ambas as entradas forem 1.'
    );


-- =============================================================
-- BLOCK 3: GAMIFICATION AND PROGRESSION
-- =============================================================

-- Progress: Ana resolveu o exercício acima.
INSERT INTO Progress (ID_Student, ID_Exercise, Attempts, Status, XP_Earned, Sync_Status) VALUES
    (
        '00000000-0000-0000-0000-000000000001',
        '00000000-0000-0000-0000-000000000020',
        1,
        'Correct',
        10,
        'Synced'
    );

-- Streak: Ana estudou hoje.
INSERT INTO Streak (ID_Student, Log_Date, Sync_Status) VALUES
    ('00000000-0000-0000-0000-000000000001', CURRENT_DATE, 'Synced');


-- =============================================================
-- BLOCK 4: ADMIN RELATED
-- =============================================================

-- Request: Carlos pede ao admin para criar uma nova UC.
-- ID_Admin é NULL — pedido ainda não atribuído.
INSERT INTO Request (ID_Professor, ID_Admin, Title, Description, Status) VALUES
    (
        '00000000-0000-0000-0000-000000000002',
        NULL,
        'Criar UC de Arquitetura de Computadores',
        'Precisamos de uma UC de AC para o 2º semestre do 3º ano.',
        'pending'
    );

-- Admin_Audit_Log: Rita apagou um utilizador fictício.
INSERT INTO Admin_Audit_Log (ID_Admin, Action, Target_ID, Target_Type) VALUES
    (
        '00000000-0000-0000-0000-000000000003',
        'DELETE_USER',
        '00000000-0000-0000-0000-000000000099',
        'Student'
    );


-- =============================================================
-- VERIFICAÇÃO — corre estes SELECTs para confirmar os inserts
-- =============================================================

SELECT 'Base_User'       AS tabela, COUNT(*) AS registos FROM Base_User
UNION ALL
SELECT 'Student',          COUNT(*) FROM Student
UNION ALL
SELECT 'Professor',        COUNT(*) FROM Professor
UNION ALL
SELECT 'Admin',            COUNT(*) FROM Admin
UNION ALL
SELECT 'Course_Unit',      COUNT(*) FROM Course_Unit
UNION ALL
SELECT 'Professor_UC',     COUNT(*) FROM Professor_UC
UNION ALL
SELECT 'Topic',            COUNT(*) FROM Topic
UNION ALL
SELECT 'Teaching_Material',COUNT(*) FROM Teaching_Material
UNION ALL
SELECT 'Exercise',         COUNT(*) FROM Exercise
UNION ALL
SELECT 'Progress',         COUNT(*) FROM Progress
UNION ALL
SELECT 'Streak',           COUNT(*) FROM Streak
UNION ALL
SELECT 'Request',          COUNT(*) FROM Request
UNION ALL
SELECT 'Admin_Audit_Log',  COUNT(*) FROM Admin_Audit_Log;
