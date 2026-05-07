import random
import string
import uuid

from sqlalchemy import Boolean, Column, DateTime, ForeignKey, Integer, SmallInteger, String
from sqlalchemy.dialects.postgresql import JSONB, UUID
from sqlalchemy.orm import relationship
from sqlalchemy.sql import func

from app.database import Base
from app.models.enums import QuizSessionStatus
from app.models.utils import EnumColumn


def _generate_room_code(length: int = 6) -> str:
    return "".join(random.choices(string.ascii_uppercase + string.digits, k=length))


class Quiz(Base):
    __tablename__ = "quiz"

    ID_Quiz = Column("id_quiz", UUID(as_uuid=True), primary_key=True, default=uuid.uuid4)
    ID_Professor = Column(
        "id_professor",
        UUID(as_uuid=True),
        ForeignKey("professor.id_professor", ondelete="CASCADE"),
        nullable=False,
    )
    ID_UC = Column(
        "id_uc",
        Integer,
        ForeignKey("course_unit.id_uc", ondelete="RESTRICT"),
        nullable=False,
    )
    Title = Column("title", String(200), nullable=False)
    Created_At = Column("created_at", DateTime, nullable=False, server_default=func.now())

    professor = relationship("Professor", back_populates="quizzes")
    course_unit = relationship("Course_Unit", back_populates="quizzes")
    quiz_exercises = relationship(
        "Quiz_Exercise",
        back_populates="quiz",
        cascade="all, delete-orphan",
        order_by="Quiz_Exercise.Question_Order",
    )
    sessions = relationship("Quiz_Session", back_populates="quiz", cascade="all, delete-orphan")


class Quiz_Exercise(Base):
    __tablename__ = "quiz_exercise"

    ID_Quiz = Column(
        "id_quiz",
        UUID(as_uuid=True),
        ForeignKey("quiz.id_quiz", ondelete="CASCADE"),
        primary_key=True,
    )
    ID_Exercise = Column(
        "id_exercise",
        UUID(as_uuid=True),
        ForeignKey("exercise.id_exercise", ondelete="CASCADE"),
        primary_key=True,
    )
    Question_Order = Column("question_order", SmallInteger, nullable=False)

    quiz = relationship("Quiz", back_populates="quiz_exercises")
    exercise = relationship("Exercise")


class Quiz_Session(Base):
    __tablename__ = "quiz_session"

    ID_Session = Column("id_session", UUID(as_uuid=True), primary_key=True, default=uuid.uuid4)
    ID_Quiz = Column(
        "id_quiz",
        UUID(as_uuid=True),
        ForeignKey("quiz.id_quiz", ondelete="CASCADE"),
        nullable=False,
    )
    Room_Code = Column("room_code", String(8), nullable=False, unique=True)
    Status = Column(
        "status",
        EnumColumn(QuizSessionStatus, name="quiz_session_status_enum", create_type=True),
        nullable=False,
        default=QuizSessionStatus.WAITING,
    )
    Current_Question_Index = Column("current_question_index", Integer, nullable=False, default=0)
    Created_At = Column("created_at", DateTime, nullable=False, server_default=func.now())
    Started_At = Column("started_at", DateTime, nullable=True)
    Finished_At = Column("finished_at", DateTime, nullable=True)

    quiz = relationship("Quiz", back_populates="sessions")
    participants = relationship(
        "Quiz_Participant", back_populates="session", cascade="all, delete-orphan"
    )
    answers = relationship(
        "Quiz_Answer", back_populates="session", cascade="all, delete-orphan"
    )


class Quiz_Participant(Base):
    __tablename__ = "quiz_participant"

    ID_Session = Column(
        "id_session",
        UUID(as_uuid=True),
        ForeignKey("quiz_session.id_session", ondelete="CASCADE"),
        primary_key=True,
    )
    ID_Student = Column(
        "id_student",
        UUID(as_uuid=True),
        ForeignKey("student.id_student", ondelete="CASCADE"),
        primary_key=True,
    )
    Score = Column("score", Integer, nullable=False, default=0)
    Joined_At = Column("joined_at", DateTime, nullable=False, server_default=func.now())

    session = relationship("Quiz_Session", back_populates="participants")
    student = relationship("Student", back_populates="quiz_participations")


class Quiz_Answer(Base):
    __tablename__ = "quiz_answer"

    ID_Answer = Column("id_answer", UUID(as_uuid=True), primary_key=True, default=uuid.uuid4)
    ID_Session = Column(
        "id_session",
        UUID(as_uuid=True),
        ForeignKey("quiz_session.id_session", ondelete="CASCADE"),
        nullable=False,
    )
    ID_Student = Column(
        "id_student",
        UUID(as_uuid=True),
        ForeignKey("student.id_student", ondelete="CASCADE"),
        nullable=False,
    )
    ID_Exercise = Column(
        "id_exercise",
        UUID(as_uuid=True),
        ForeignKey("exercise.id_exercise", ondelete="CASCADE"),
        nullable=False,
    )
    Answer = Column("answer", JSONB, nullable=False)
    Is_Correct = Column("is_correct", Boolean, nullable=False)
    Time_Taken_Ms = Column("time_taken_ms", Integer, nullable=True)
    Points_Earned = Column("points_earned", Integer, nullable=False, default=0)
    Answered_At = Column("answered_at", DateTime, nullable=False, server_default=func.now())

    session = relationship("Quiz_Session", back_populates="answers")
    student = relationship("Student")
    exercise = relationship("Exercise")
