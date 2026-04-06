-- =============================================================
-- PECI PROJECT — TRUNCATE ALL TABLES (esvaziar sem apagar estrutura)
-- TRUNCATE CASCADE trata automaticamente da ordem das FKs.
-- =============================================================

TRUNCATE TABLE
    Admin_Audit_Log,
    Request,
    Streak,
    Progress,
    Exercise,
    Teaching_Material,
    Topic,
    Professor_UC,
    Course_Unit,
    Student,
    Professor,
    Admin,
    Base_User
RESTART IDENTITY CASCADE;


-- =============================================================
-- VERIFICAÇÃO — todas as tabelas devem mostrar 0 registos
-- =============================================================

SELECT 'Base_User'        AS tabela, COUNT(*) AS registos FROM Base_User
UNION ALL
SELECT 'Student',           COUNT(*) FROM Student
UNION ALL
SELECT 'Professor',         COUNT(*) FROM Professor
UNION ALL
SELECT 'Admin',             COUNT(*) FROM Admin
UNION ALL
SELECT 'Course_Unit',       COUNT(*) FROM Course_Unit
UNION ALL
SELECT 'Professor_UC',      COUNT(*) FROM Professor_UC
UNION ALL
SELECT 'Topic',             COUNT(*) FROM Topic
UNION ALL
SELECT 'Teaching_Material', COUNT(*) FROM Teaching_Material
UNION ALL
SELECT 'Exercise',          COUNT(*) FROM Exercise
UNION ALL
SELECT 'Progress',          COUNT(*) FROM Progress
UNION ALL
SELECT 'Streak',            COUNT(*) FROM Streak
UNION ALL
SELECT 'Request',           COUNT(*) FROM Request
UNION ALL
SELECT 'Admin_Audit_Log',   COUNT(*) FROM Admin_Audit_Log;
