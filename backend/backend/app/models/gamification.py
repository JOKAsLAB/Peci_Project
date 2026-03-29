# Progress, Streak (Related to Student)
# =============================================================
# PECI PROJECT — Models: Gamification and Progression
#
# Espelha as tabelas SQL:
#   Progress, Streak
# =============================================================

import uuid
from sqlalchemy import (
    Column, DateTime, Date, Integer,
    ForeignKey, CheckConstraint, String, UniqueConstraint
)
from sqlalchemy.dialects.postgresql import UUID
from sqlalchemy.orm import relationship
from sqlalchemy.sql import func

from app.database import Base


# =============================================================
# Progress
# Regista cada tentativa de um estudante num exercício.
# Um estudante pode ter N registos de Progress (um por tentativa).
# Sync_Status: estado de sincronização com a app mobile offline.
# Status: resultado da tentativa — Correct, Incorrect ou Partial.
# XP_Earned: XP ganho nesta tentativa (0 se incorreto).
# =============================================================
class Progress(Base):
    __tablename__ = "progress"

    ID_Progress = Column(
        UUID(as_uuid=True),
        primary_key=True,
        default=uuid.uuid4
    )
    ID_Student  = Column(
        UUID(as_uuid=True),
        ForeignKey("student.ID_Student", ondelete="CASCADE"),
        nullable=False
    )
    ID_Exercise = Column(
        UUID(as_uuid=True),
        ForeignKey("exercise.ID_Exercise", ondelete="CASCADE"),
        nullable=False
    )
    Attempts    = Column(Integer,    nullable=False, default=1)
    Status      = Column(String(20), nullable=False)
    XP_Earned   = Column(Integer,    nullable=False, default=0)
    Sync_Status = Column(String(20), nullable=False, default="Pending")

    # Renomeado de Date para Record_Date — evita conflito com o tipo Date do SQLAlchemy
    # Mapeia para a coluna "Date" do schema SQL via name="Date"
    Record_Date = Column(
        "Date",
        DateTime,
        nullable=False,
        server_default=func.now()  # equivalente ao DEFAULT NOW() do SQL
    )

    __table_args__ = (
        CheckConstraint(
            "Status IN ('Correct', 'Incorrect', 'Partial')",
            name="check_progress_status"
        ),
        CheckConstraint(
            "Sync_Status IN ('Pending', 'Synced', 'Failed')",
            name="check_progress_sync_status"
        ),
        CheckConstraint(
            "Attempts >= 1",
            name="check_progress_attempts"
        ),
        CheckConstraint(
            "XP_Earned >= 0",
            name="check_progress_xp"
        ),
    )

    # Relações inversas
    student  = relationship("Student",  back_populates="progress_records")
    exercise = relationship("Exercise", back_populates="progress_records")


# =============================================================
# Streak
# Um registo por dia que o estudante estudou.
# Usado para validar dias consecutivos de estudo (tipo Duolingo).
# O valor atual do streak (Streak_Days) está em Student —
# esta tabela serve como histórico e fonte de verdade para
# recalcular o streak em caso de falha de sincronização mobile.
# Sync_Status: estado de sincronização com a app mobile offline.
# =============================================================
class Streak(Base):
    __tablename__ = "streak"

    ID_Streak   = Column(
        UUID(as_uuid=True),
        primary_key=True,
        default=uuid.uuid4
    )
    ID_Student  = Column(
        UUID(as_uuid=True),
        ForeignKey("student.ID_Student", ondelete="CASCADE"),
        nullable=False
    )
    Sync_Status = Column(String(20), nullable=False, default="Pending")

    # server_default delega ao PostgreSQL — equivalente ao DEFAULT CURRENT_DATE do SQL
    Log_Date    = Column(Date, nullable=False, server_default=func.current_date())

    __table_args__ = (
        CheckConstraint(
            "Sync_Status IN ('Pending', 'Synced', 'Failed')",
            name="check_streak_sync_status"
        ),
        # Garante que um estudante só tem um registo de streak por dia
        # Sem isto, o mesmo estudante poderia ter dois registos no mesmo dia,
        # corrompendo a lógica de dias consecutivos
        UniqueConstraint(
            "ID_Student", "Log_Date",
            name="uq_streak_student_date"
        ),
    )

    # Relação inversa com Student
    student = relationship("Student", back_populates="streak_records")