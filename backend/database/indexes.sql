-- =============================================================
-- INDEXES (performance on the most common lookups)
-- =============================================================

-- Students looking up their own progress
CREATE INDEX idx_progress_student   ON Progress(ID_Student);

-- Student enrollments by student and by UC
CREATE INDEX idx_student_uc_student ON Student_UC(ID_Student);
CREATE INDEX idx_student_uc_uc      ON Student_UC(ID_UC);

-- Filtering exercises by UC or topic
CREATE INDEX idx_exercise_uc        ON Exercise(ID_UC);
CREATE INDEX idx_exercise_topic     ON Exercise(ID_UC, Topic_Name);

-- Streak lookups by student and date
CREATE INDEX idx_streak_student     ON Streak(ID_Student);
CREATE INDEX idx_streak_date        ON Streak(ID_Student, Log_Date);

-- Materials by UC
CREATE INDEX idx_material_uc        ON Teaching_Material(ID_UC);

-- Requests by status (admins filter pending requests)
CREATE INDEX idx_request_status     ON Request(Status);

-- Audit log lookups by admin or target
CREATE INDEX idx_audit_admin        ON Admin_Audit_Log(ID_Admin);
CREATE INDEX idx_audit_target       ON Admin_Audit_Log(Target_Type, Target_ID);