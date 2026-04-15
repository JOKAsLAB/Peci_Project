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
    ForeignKey, UniqueConstraint
)
from sqlalchemy.dialects.postgresql import UUID
from app.models.utils import EnumColumn
from sqlalchemy.orm import relationship
from sqlalchemy.sql import func

from app.database import Base
from app.models.enums import ProgressStatus, SyncStatus


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
        "id_progress",
        UUID(as_uuid=True),
        primary_key=True,
        default=uuid.uuid4
    )
    ID_Student  = Column(
        "id_student",
        UUID(as_uuid=True),
        ForeignKey("student.id_student", ondelete="CASCADE"),
        nullable=False
    )
    ID_Exercise = Column(
        "id_exercise",
        UUID(as_uuid=True),
        ForeignKey("exercise.id_exercise", ondelete="CASCADE"),
        nullable=False
    )
    Attempts    = Column("attempts", Integer,    nullable=False, default=1)
    
    # Substituição de VARCHAR e CheckConstraint por ENUM nativo
    Status = Column(
        "status", 
        EnumColumn(ProgressStatus, name="progress_status_enum", create_type=True),
        nullable=False
    )
    Sync_Status = Column(
        "sync_status", 
        EnumColumn(SyncStatus, name="sync_status_enum", create_type=True),
        nullable=False,
        default=SyncStatus.PENDING
    )
    
    XP_Earned   = Column("xp_earned", Integer,    nullable=False, default=0)

    # Renomeado de Date para Record_Date — evita conflito com o tipo Date do SQLAlchemy
    # Mapeia para a coluna "date" do schema SQL (PostgreSQL normaliza para minúsculas)
    Record_Date = Column(
        "date",
        DateTime,
        nullable=False,
        server_default=func.now()  # equivalente ao DEFAULT NOW() do SQL
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
        "id_streak",
        UUID(as_uuid=True),
        primary_key=True,
        default=uuid.uuid4
    )
    ID_Student  = Column(
        "id_student",
        UUID(as_uuid=True),
        ForeignKey("student.id_student", ondelete="CASCADE"),
        nullable=False
    )
    
    # Substituição de VARCHAR e CheckConstraint por ENUM nativo
    Sync_Status = Column(
        "sync_status",
        EnumColumn(SyncStatus, name="sync_status_enum", create_type=True),
        nullable=False, 
        default=SyncStatus.PENDING
    )

    # server_default delega ao PostgreSQL — equivalente ao DEFAULT CURRENT_DATE do SQL
    Log_Date    = Column("log_date", Date, nullable=False, server_default=func.current_date())

    __table_args__ = (
        # Garante que um estudante só tem um registo de streak por dia
        # Sem isto, o mesmo estudante poderia ter dois registos no mesmo dia,
        # corrompendo a lógica de dias consecutivos
        UniqueConstraint(
            "id_student", "log_date",
            name="uq_streak_student_date"
        ),
    )

    # Relação inversa com Student
    student = relationship("Student", back_populates="streak_records")