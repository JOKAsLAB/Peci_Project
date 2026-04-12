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
SELECT 'Progress',         COUNT(*) FROM Progress
UNION ALL
SELECT 'Streak',           COUNT(*) FROM Streak
UNION ALL
SELECT 'Request',          COUNT(*) FROM Request
UNION ALL
SELECT 'Admin_Audit_Log',  COUNT(*) FROM Admin_Audit_Log
UNION ALL
SELECT 'Learning_Path',  COUNT(*) FROM Learning_Path
UNION ALL
SELECT 'Learning_Path_Exercise',  COUNT(*) FROM Learning_Path_Exercise;

-- =============================================================