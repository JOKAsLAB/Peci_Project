-- =============================================================
-- MIGRATION: Add Quiz (Kahoot-style) tables
-- Run this on an existing database that already has the full schema.
-- =============================================================

-- ENUM
CREATE TYPE quiz_session_status_enum AS ENUM ('waiting', 'active', 'finished');

-- Quiz definition created by a professor for a UC
CREATE TABLE Quiz (
    ID_Quiz      UUID         PRIMARY KEY DEFAULT gen_random_uuid(),
    ID_Professor UUID         NOT NULL REFERENCES Professor(ID_Professor) ON DELETE CASCADE,
    ID_UC        INT          NOT NULL REFERENCES Course_Unit(ID_UC) ON DELETE RESTRICT,
    Title        VARCHAR(200) NOT NULL,
    Created_At   TIMESTAMP    NOT NULL DEFAULT NOW()
);

-- Ordered exercises inside a quiz
CREATE TABLE Quiz_Exercise (
    ID_Quiz        UUID     NOT NULL REFERENCES Quiz(ID_Quiz) ON DELETE CASCADE,
    ID_Exercise    UUID     NOT NULL REFERENCES Exercise(ID_Exercise) ON DELETE CASCADE,
    Question_Order SMALLINT NOT NULL,
    PRIMARY KEY (ID_Quiz, ID_Exercise)
);

-- Live session opened by the professor (holds the room code)
CREATE TABLE Quiz_Session (
    ID_Session             UUID                     PRIMARY KEY DEFAULT gen_random_uuid(),
    ID_Quiz                UUID                     NOT NULL REFERENCES Quiz(ID_Quiz) ON DELETE CASCADE,
    Room_Code              VARCHAR(8)               NOT NULL UNIQUE,
    Status                 quiz_session_status_enum NOT NULL DEFAULT 'waiting',
    Current_Question_Index INT                      NOT NULL DEFAULT 0,
    Created_At             TIMESTAMP                NOT NULL DEFAULT NOW(),
    Started_At             TIMESTAMP,
    Finished_At            TIMESTAMP
);

-- Students who joined a session
CREATE TABLE Quiz_Participant (
    ID_Session UUID      NOT NULL REFERENCES Quiz_Session(ID_Session) ON DELETE CASCADE,
    ID_Student UUID      NOT NULL REFERENCES Student(ID_Student) ON DELETE CASCADE,
    Score      INT       NOT NULL DEFAULT 0,
    Joined_At  TIMESTAMP NOT NULL DEFAULT NOW(),
    PRIMARY KEY (ID_Session, ID_Student)
);

-- One row per answer — unique constraint prevents double-answering
CREATE TABLE Quiz_Answer (
    ID_Answer     UUID      PRIMARY KEY DEFAULT gen_random_uuid(),
    ID_Session    UUID      NOT NULL REFERENCES Quiz_Session(ID_Session) ON DELETE CASCADE,
    ID_Student    UUID      NOT NULL REFERENCES Student(ID_Student) ON DELETE CASCADE,
    ID_Exercise   UUID      NOT NULL REFERENCES Exercise(ID_Exercise) ON DELETE CASCADE,
    Answer        JSONB     NOT NULL,
    Is_Correct    BOOLEAN   NOT NULL,
    Time_Taken_Ms INT,
    Points_Earned INT       NOT NULL DEFAULT 0,
    Answered_At   TIMESTAMP NOT NULL DEFAULT NOW(),
    UNIQUE (ID_Session, ID_Student, ID_Exercise)
);
