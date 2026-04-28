-- Tabelas que não têm ninguém a depender delas (folhas da árvore)
DROP TABLE IF EXISTS Admin_Audit_Log;
DROP TABLE IF EXISTS Streak;
DROP TABLE IF EXISTS Progress;
DROP TABLE IF EXISTS Request;

-- Junction tables / folhas intermédias
DROP TABLE IF EXISTS Learning_Path_Exercise;

DROP TABLE IF EXISTS Exercise_Report;

-- Exercise depende de Topic e Teaching_Material
DROP TABLE IF EXISTS Exercise;

-- Learning_Path depende de Course_Unit e Professor
DROP TABLE IF EXISTS Learning_Path;

-- Teaching_Material depende de Course_Unit e Professor
DROP TABLE IF EXISTS Teaching_Material;

-- Topic depende de Course_Unit
DROP TABLE IF EXISTS Topic;

-- Professor_UC depende de Professor e Course_Unit
DROP TABLE IF EXISTS Professor_UC;

-- Depende de Student e Course_Unit
DROP TABLE IF EXISTS Student_UC;

-- Course_Unit já não tem ninguém a depender dela
DROP TABLE IF EXISTS Course_Unit;

-- Subtipos dependem de Base_User
DROP TABLE IF EXISTS Student;
DROP TABLE IF EXISTS Professor;
DROP TABLE IF EXISTS Admin;

-- Base_User é a última — toda a gente dependia dela
DROP TABLE IF EXISTS Base_User;

-- ENUMs — apagados depois das tabelas que os usavam
DROP TYPE IF EXISTS user_role_enum;
DROP TYPE IF EXISTS user_status_enum;
DROP TYPE IF EXISTS material_status_enum;
DROP TYPE IF EXISTS exercise_type_enum;
DROP TYPE IF EXISTS difficulty_level_enum;
DROP TYPE IF EXISTS progress_status_enum;
DROP TYPE IF EXISTS sync_status_enum;
DROP TYPE IF EXISTS request_status_enum;
DROP TYPE IF EXISTS request_type_enum;

/* All tables:
DROP TABLE IF EXISTS 
    Admin_Audit_Log, Streak, Progress, Request,
    Exercise, Teaching_Material, Topic, Professor_UC,
    Course_Unit, Student, Professor, Admin, Base_User
CASCADE;
*/