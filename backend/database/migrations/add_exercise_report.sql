-- Migration: add Exercise_Report table
-- Run once against the live database.

CREATE TABLE IF NOT EXISTS exercise_report (
    id_exercise  UUID NOT NULL REFERENCES exercise(id_exercise) ON DELETE CASCADE,
    id_student   UUID NOT NULL REFERENCES student(id_student)   ON DELETE CASCADE,
    created_at   TIMESTAMPTZ NOT NULL DEFAULT now(),
    PRIMARY KEY (id_exercise, id_student)
);
