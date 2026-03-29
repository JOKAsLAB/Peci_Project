# =============================================================
# PECI PROJECT — Models: Academic Core
#
# Espelha as tabelas SQL:
#   Course_Unit, Topic, Teaching_Material, Exercise
#
# Ordem importa:
#   Course_Unit → Topic → Teaching_Material → Exercise
# =============================================================

import uuid
from sqlalchemy import (
    Column, String, Text, DateTime, Integer,
    SmallInteger, ForeignKey, UniqueConstraint,
    CheckConstraint, ForeignKeyConstraint
)
from sqlalchemy.dialects.postgresql import UUID, JSONB
from sqlalchemy.orm import relationship
from sqlalchemy.sql import func

from app.database import Base


# =============================================================
# Course_Unit
# Unidade Curricular — ex: Sistemas Digitais (41953), PECI.
# ID_UC é um INT simples (não SERIAL) para suportar os códigos
# reais das cadeiras da Universidade de Aveiro.
# =============================================================
class Course_Unit(Base):
    __tablename__ = "course_unit"

    ID_UC           = Column(Integer,      primary_key=True)  # código real da UA, ex: 41953
    Name            = Column(String(100),  nullable=False)
    Semester        = Column(String(20),   nullable=True)
    Curricular_Year = Column(SmallInteger, nullable=True)

    # Relações com tabelas filhas
    professor_ucs      = relationship("Professor_UC",      back_populates="course_unit")
    topics             = relationship("Topic",             back_populates="course_unit")
    teaching_materials = relationship("Teaching_Material", back_populates="course_unit")
    exercises          = relationship("Exercise",          back_populates="course_unit")


# =============================================================
# Topic
# Tópico dentro de uma UC — ex: Portas Lógicas, Mapas de Karnaugh.
# PK composta: (ID_UC, Name) — nomes únicos dentro de uma UC.
# N_Order é definido manualmente e é único por UC (com DEFERRABLE
# para permitir reordenações sem conflitos temporários).
# =============================================================
class Topic(Base):
    __tablename__ = "topic"

    ID_UC   = Column(
        Integer,
        ForeignKey("course_unit.ID_UC", ondelete="CASCADE"),
        primary_key=True
    )
    Name    = Column(String(100), primary_key=True, nullable=False)
    N_Order = Column(SmallInteger, nullable=False)

    __table_args__ = (
        # Garante que não há dois tópicos com a mesma ordem na mesma UC.
        # DEFERRABLE permite reordenar sem conflitos durante a transação.
        UniqueConstraint(
            "ID_UC", "N_Order",
            name="uq_topic_order",
            deferrable=True,
            initially="DEFERRED"
        ),
    )

    # Relação inversa com Course_Unit
    course_unit = relationship("Course_Unit", back_populates="topics")

    # Relação com Exercise
    exercises = relationship("Exercise", back_populates="topic", overlaps="course_unit,exercises")


# =============================================================
# Teaching_Material
# PDF uploaded por um professor para alimentar o pipeline RAG.
# Status: Pending (uploaded), Indexed (processado), Error (falhou).
# Extracted_Text: texto extraído do PDF para o LLM.
# File_Path: caminho/URL do ficheiro em disco ou object storage.
# =============================================================
class Teaching_Material(Base):
    __tablename__ = "teaching_material"

    ID_Material    = Column(
        UUID(as_uuid=True),
        primary_key=True,
        default=uuid.uuid4
    )
    ID_UC          = Column(
        Integer,
        ForeignKey("course_unit.ID_UC", ondelete="RESTRICT"),
        nullable=False
    )
    ID_Professor   = Column(
        UUID(as_uuid=True),
        ForeignKey("professor.ID_Professor", ondelete="RESTRICT"),
        nullable=False
    )
    Status         = Column(String(20),  nullable=False, default="Pending")
    Title          = Column(String(200), nullable=False)
    File_Path      = Column(Text,        nullable=False)
    Extracted_Text = Column(Text,        nullable=True)

    # server_default=func.now() delega ao PostgreSQL — equivalente ao DEFAULT NOW() do SQL
    Upload_Date    = Column(DateTime, nullable=False, server_default=func.now())

    __table_args__ = (
        CheckConstraint(
            "Status IN ('Pending', 'Indexed', 'Error')",
            name="check_material_status"
        ),
    )

    # Relações inversas
    course_unit = relationship("Course_Unit", back_populates="teaching_materials")
    professor   = relationship("Professor",   back_populates="teaching_materials")

    # Relação com Exercise (materiais podem originar exercícios via IA)
    exercises = relationship("Exercise", back_populates="material")


# =============================================================
# Exercise
# Exercício ligado a exatamente um Topic e uma Course_Unit.
# Material_Ref é nullable — só exercícios gerados por IA
# referenciam um Teaching_Material.
# Solution em JSONB suporta formatos diferentes por tipo:
#   Multiple Choice: {"correct": "A", "options": ["A", "B", "C", "D"]}
#   True/False:      {"correct": true}
# =============================================================
class Exercise(Base):
    __tablename__ = "exercise"

    ID_Exercise  = Column(
        UUID(as_uuid=True),
        primary_key=True,
        default=uuid.uuid4
    )
    ID_UC        = Column(Integer,     nullable=False)
    Topic_Name   = Column(String(100), nullable=False)
    Material_Ref = Column(
        UUID(as_uuid=True),
        ForeignKey("teaching_material.ID_Material", ondelete="SET NULL"),
        nullable=True  # NULL = exercício fixo (não gerado por IA)
    )
    Type         = Column(String(30),  nullable=False)
    Question     = Column(Text,        nullable=False)
    Solution     = Column(JSONB,       nullable=False)
    Difficulty   = Column(String(10),  nullable=False)
    Explanation  = Column(Text,        nullable=True)

    __table_args__ = (
        # FK simples para Course_Unit
        ForeignKeyConstraint(
            ["ID_UC"],
            ["course_unit.ID_UC"],
            ondelete="RESTRICT",
            name="fk_exercise_uc"
        ),
        # FK composta para Topic — garante que o tópico pertence à mesma UC
        # Espelha: FOREIGN KEY (ID_UC, Topic_Name) REFERENCES Topic(ID_UC, Name)
        ForeignKeyConstraint(
            ["ID_UC", "Topic_Name"],
            ["topic.ID_UC", "topic.Name"],
            ondelete="RESTRICT",
            name="fk_exercise_topic"
        ),
        CheckConstraint(
            "Type IN ('Multiple Choice', 'True/False')",
            name="check_exercise_type"
        ),
        CheckConstraint(
            "Difficulty IN ('Easy', 'Medium', 'Hard')",
            name="check_exercise_difficulty"
        ),
    )

    # Relações inversas — foreign_keys em string para evitar erros de inicialização
    course_unit = relationship(
        "Course_Unit",
        foreign_keys="[Exercise.ID_UC]",
        back_populates="exercises",
        overlaps="topic,exercises"
    )
    topic = relationship(
        "Topic",
        foreign_keys="[Exercise.ID_UC, Exercise.Topic_Name]",
        primaryjoin="and_(Exercise.ID_UC == Topic.ID_UC, Exercise.Topic_Name == Topic.Name)",
        back_populates="exercises",
        overlaps="course_unit,exercises"
    )
    material = relationship(
        "Teaching_Material",
        foreign_keys="[Exercise.Material_Ref]",
        back_populates="exercises"
    )

    # Relação com Progress
    progress_records = relationship("Progress", back_populates="exercise")