
-- =============================================================
-- DIAGNÓSTICO: professores e as suas UCs associadas
-- =============================================================
SELECT *
FROM Exercise
WHERE ID_Exercise IN (
    'b436f9eb-f4e7-4b91-80c5-1e58ff414a6e',
    'bd372cd4-210d-41b9-a628-f115aefc81f7',
    '78ea8ff2-4bac-416e-b48b-4bdc2805529a',
    '3d431753-ac2f-4f0d-badd-a365ac6bf49c'
);
-- =============================================================
-- VERIFICAÇÃO DE REGISTOS POR TABELA
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
SELECT 'Student_UC',       COUNT(*) FROM Student_UC
UNION ALL
SELECT 'Topic',            COUNT(*) FROM Topic
UNION ALL
SELECT 'Teaching_Material',COUNT(*) FROM Teaching_Material
UNION ALL
SELECT 'Exercise',         COUNT(*) FROM Exercise
UNION ALL
SELECT 'Exercise_Report',  COUNT(*) FROM Exercise_Report
UNION ALL
SELECT 'Progress',         COUNT(*) FROM Progress
UNION ALL
SELECT 'Streak',           COUNT(*) FROM Streak
UNION ALL
SELECT 'Request',          COUNT(*) FROM Request
UNION ALL
SELECT 'Admin_Audit_Log',  COUNT(*) FROM Admin_Audit_Log
-- =============================================================

