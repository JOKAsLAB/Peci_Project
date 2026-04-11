# =============================================================
# PECI PROJECT — Models: Learning Paths (Professor Path Builder)
#
# Espelha as tabelas SQL:
#   Learning_Path, Learning_Path_Exercise
#
# =============================================================

import uuid
from sqlalchemy import (
    Column, String, Text, DateTime, Integer,
    SmallInteger, ForeignKey, Boolean, UniqueConstraint
)
from sqlalchemy.dialects.postgresql import UUID
from sqlalchemy.orm import relationship
from sqlalchemy.sql import func

from app.database import Base


# =============================================================
# Learning_Path
# Um caminho de aprendizagem estruturado criado por um professor.
# Professores usam o Path Builder para definir sequências
# personalizadas de exercícios.
# =============================================================
class LearningPath(Base):
    __tablename__ = "learning_path"

    ID_Path      = Column(
        "id_path",
        UUID(as_uuid=True),
        primary_key=True,
        default=uuid.uuid4
    )
    ID_UC        = Column(
        "id_uc",
        Integer,
        ForeignKey("course_unit.id_uc", ondelete="CASCADE"),
        nullable=False
    )
    ID_Professor = Column(
        "id_professor",
        UUID(as_uuid=True),
        ForeignKey("professor.id_professor", ondelete="CASCADE"),
        nullable=False
    )
    Name         = Column("name", String(200), nullable=False)
    Description  = Column("description", Text, nullable=True)
    Published    = Column("published", Boolean, nullable=False, default=False)
    Created_At   = Column("created_at", DateTime, nullable=False, server_default=func.now())
    Updated_At   = Column("updated_at", DateTime, nullable=False, server_default=func.now())

    # Relações inversas
    course_unit = relationship("Course_Unit", foreign_keys="[LearningPath.ID_UC]")
    professor   = relationship("Professor", foreign_keys="[LearningPath.ID_Professor]")
    
    # Relação M2M com Exercise (via Learning_Path_Exercise)
    path_exercises = relationship(
        "LearningPathExercise",
        back_populates="learning_path",
        cascade="all, delete-orphan",
        lazy="selectin"
    )

    def __repr__(self):
        return f"<LearningPath {self.ID_Path} '{self.Name}'>"


# =============================================================
# Learning_Path_Exercise
# Relação N-N: exercícios numa sequência de aprendizagem,
# com controlo de ordem específica.
#
# ID_Path + Order_Num é unique para evitar posições duplicadas.
# Order_Num define a sequência dentro de um path (1, 2, 3, ...).
# =============================================================
class LearningPathExercise(Base):
    __tablename__ = "learning_path_exercise"

    ID              = Column(
        "id",
        UUID(as_uuid=True),
        primary_key=True,
        default=uuid.uuid4
    )
    ID_Path         = Column(
        "id_path",
        UUID(as_uuid=True),
        ForeignKey("learning_path.id_path", ondelete="CASCADE"),
        nullable=False
    )
    ID_Exercise     = Column(
        "id_exercise",
        UUID(as_uuid=True),
        ForeignKey("exercise.id_exercise", ondelete="CASCADE"),
        nullable=False
    )
    Order_Num       = Column("order_num", SmallInteger, nullable=False)

    __table_args__ = (
        UniqueConstraint(
            "id_path", "order_num",
            name="uq_path_exercise_order"
        ),
    )

    # Relações inversas
    learning_path = relationship("LearningPath", foreign_keys="[LearningPathExercise.ID_Path]", back_populates="path_exercises")
    exercise      = relationship("Exercise", foreign_keys="[LearningPathExercise.ID_Exercise]")

    def __repr__(self):
        return f"<LearningPathExercise path={self.ID_Path}, exercise={self.ID_Exercise}, order={self.Order_Num}>"
