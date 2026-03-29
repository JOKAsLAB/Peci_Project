-- =============================================================
-- PECI PROJECT — TEST INSERTS
-- Ordem respeita FKs: tabelas pai primeiro, filhas depois.
-- =============================================================


-- =============================================================
-- BLOCK 1: USERS AND PERSONAS
-- =============================================================

-- Base_User primeiro — toda a gente depende desta tabela.
-- Inserimos 1 student, 1 professor e 1 admin.
INSERT INTO base_user ("ID_User", "Name", "Email", "Password_Hash", "Role", "Status") VALUES
    ('00000000-0000-0000-0000-000000000001', 'Ana Silva',    'ana.silva@ua.pt',    'hash_ana',    'STUDENT',   'ACTIVE'),
    ('00000000-0000-0000-0000-000000000002', 'Carlos Mota',  'carlos.mota@ua.pt',  'hash_carlos', 'PROFESSOR', 'ACTIVE'),
    ('00000000-0000-0000-0000-000000000003', 'Rita Sousa',   'rita.sousa@ua.pt',   'hash_rita',   'ADMIN',     'ACTIVE')
ON CONFLICT ("ID_User") DO NOTHING;

-- Student: ID_Student é o mesmo UUID que o ID_User da Ana.
INSERT INTO student ("ID_Student", "Current_Level", "Total_XP", "Streak_Days", "Last_Access") VALUES
    ('00000000-0000-0000-0000-000000000001', 1, 0, 0, NOW())
ON CONFLICT ("ID_Student") DO NOTHING;

-- Professor: ID_Professor é o mesmo UUID que o ID_User do Carlos.
INSERT INTO professor ("ID_Professor", "Department", "Office", "Short_Bio") VALUES
    ('00000000-0000-0000-0000-000000000002', 'DETI', 'Ed. 1 - Sala 2.10', 'Professor de Sistemas Digitais.')
ON CONFLICT ("ID_Professor") DO NOTHING;

-- Admin: ID_Admin é o mesmo UUID que o ID_User da Rita.
INSERT INTO admin ("ID_Admin", "Privilege_Level", "Contact") VALUES
    ('00000000-0000-0000-0000-000000000003', 3, 'rita.sousa@ua.pt')
ON CONFLICT ("ID_Admin") DO NOTHING;


-- =============================================================
-- BLOCK 2: ACADEMIC CORE
-- =============================================================

-- Course Unit: criada pelo admin, gerida pelo professor.
INSERT INTO course_unit ("ID_UC", "Name", "Semester", "Curricular_Year")
VALUES (41953, 'PECI', '2S', 3)
ON CONFLICT ("ID_UC") DO NOTHING;

-- Professor_UC: associa o Carlos à UC com ID 41953.
INSERT INTO professor_uc ("ID_Professor", "ID_UC") VALUES
    ('00000000-0000-0000-0000-000000000002', 41953)
ON CONFLICT ("ID_Professor", "ID_UC") DO NOTHING;

-- Topic: pertence à UC 41953, com ordem definida.
INSERT INTO topic ("ID_UC", "Name", "N_Order")
VALUES (41953, 'Portas Logicas', 1)
ON CONFLICT ("ID_UC", "Name") DO NOTHING;

INSERT INTO topic ("ID_UC", "Name", "N_Order")
VALUES (41953, 'Mapas de Karnaugh', 2)
ON CONFLICT ("ID_UC", "Name") DO NOTHING;

-- Teaching_Material: PDF uploaded pelo Carlos para a UC 41953.
INSERT INTO teaching_material ("ID_Material", "ID_UC", "ID_Professor", "Status", "Title", "File_Path", "Extracted_Text") VALUES
    (
        '00000000-0000-0000-0000-000000000010',
        41953,
        '00000000-0000-0000-0000-000000000002',
        'INDEXED',
        'Aula 1 — Portas Lógicas',
        '/materials/aula1_portas_logicas.pdf',
        'Texto extraído do PDF sobre portas lógicas AND, OR, NOT...'
    )
ON CONFLICT ("ID_Material") DO NOTHING;

-- Exercise: ligado à UC 41953, tópico "Portas Lógicas", referencia o material acima.
-- Solution em JSONB — formato para Multiple Choice.
INSERT INTO exercise ("ID_Exercise", "ID_UC", "Topic_Name", "Material_Ref", "Type", "Question", "Solution", "Difficulty", "Explanation") VALUES
    (
        '00000000-0000-0000-0000-000000000020',
        41953,
        'Portas Logicas',
        '00000000-0000-0000-0000-000000000010',
        'MULTIPLE_CHOICE',
        'Qual é o resultado de AND(1, 0)?',
        '{"correct": "0", "options": ["0", "1"]}',
        'EASY',
        'A porta AND só devolve 1 se ambas as entradas forem 1.'
    )
ON CONFLICT ("ID_Exercise") DO NOTHING;


-- =============================================================
-- BLOCK 3: GAMIFICATION AND PROGRESSION
-- =============================================================

-- Progress: Ana resolveu o exercício acima.
INSERT INTO progress ("ID_Progress", "ID_Student", "ID_Exercise", "Attempts", "Status", "XP_Earned", "Sync_Status") VALUES
    (
        '00000000-0000-0000-0000-000000000030',
        '00000000-0000-0000-0000-000000000001',
        '00000000-0000-0000-0000-000000000020',
        1,
        'CORRECT',
        10,
        'SYNCED'
    )
ON CONFLICT ("ID_Progress") DO NOTHING;

-- Streak: Ana estudou hoje.
INSERT INTO streak ("ID_Streak", "ID_Student", "Log_Date", "Sync_Status") VALUES
    ('00000000-0000-0000-0000-000000000040', '00000000-0000-0000-0000-000000000001', CURRENT_DATE, 'SYNCED')
ON CONFLICT ("ID_Student", "Log_Date") DO NOTHING;


-- =============================================================
-- BLOCK 4: ADMIN RELATED
-- =============================================================

-- Request: Carlos pede ao admin para criar uma nova UC.
-- ID_Admin é NULL — pedido ainda não atribuído.
INSERT INTO request ("ID_Professor", "ID_Admin", "Request_Type", "Title", "Description", "Status") VALUES
    (
        '00000000-0000-0000-0000-000000000002',
        NULL,
        'OPERATIONS',
        'Criar UC de Arquitetura de Computadores',
        'Precisamos de uma UC de AC para o 2º semestre do 3º ano.',
        'PENDING'
    );

-- Admin_Audit_Log: Rita apagou um utilizador fictício.
INSERT INTO admin_audit_log ("ID_Admin", "Action", "Target_ID", "Target_Type") VALUES
    (
        '00000000-0000-0000-0000-000000000003',
        'DELETE_USER',
        '00000000-0000-0000-0000-000000000099',
        'Student'
    );


-- =============================================================
-- VERIFICAÇÃO — corre estes SELECTs para confirmar os inserts
-- =============================================================

SELECT 'Base_User'       AS tabela, COUNT(*) AS registos FROM base_user
UNION ALL
SELECT 'Student',          COUNT(*) FROM student
UNION ALL
SELECT 'Professor',        COUNT(*) FROM professor
UNION ALL
SELECT 'Admin',            COUNT(*) FROM admin
UNION ALL
SELECT 'Course_Unit',      COUNT(*) FROM course_unit
UNION ALL
SELECT 'Professor_UC',     COUNT(*) FROM professor_uc
UNION ALL
SELECT 'Topic',            COUNT(*) FROM topic
UNION ALL
SELECT 'Teaching_Material',COUNT(*) FROM teaching_material
UNION ALL
SELECT 'Exercise',         COUNT(*) FROM exercise
UNION ALL
SELECT 'Progress',         COUNT(*) FROM progress
UNION ALL
SELECT 'Streak',           COUNT(*) FROM streak
UNION ALL
SELECT 'Request',          COUNT(*) FROM request
UNION ALL
SELECT 'Admin_Audit_Log',  COUNT(*) FROM admin_audit_log;
