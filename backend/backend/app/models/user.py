# =============================================================
# PECI PROJECT — Models: Users and Personas
#
# Espelha as tabelas SQL:
#   Base_User, Student, Professor, Admin, Professor_UC
#
# Cada classe representa uma tabela.
# Cada atributo representa uma coluna.
# As relações entre tabelas são definidas com relationship().
# =============================================================

import uuid
from sqlalchemy import (
    Column, String, Text, Date, DateTime,
    Integer, SmallInteger, ForeignKey, CheckConstraint
)
from sqlalchemy.dialects.postgresql import UUID
from sqlalchemy.orm import relationship
from sqlalchemy.sql import func

from app.database import Base


# =============================================================
# Base_User
# Tabela central — contém credenciais e dados comuns a todos.
# =============================================================
class Base_User(Base):
    __tablename__ = "base_user"

    ID_User = Column(
        UUID(as_uuid=True),
        primary_key=True,
        default=uuid.uuid4  # equivalente ao gen_random_uuid() do PostgreSQL
    )
    Name              = Column(String(100), nullable=False)
    Email             = Column(String(150), nullable=False, unique=True)
    Password_Hash     = Column(Text,        nullable=False)
    Role              = Column(String(20),  nullable=False)
    Status            = Column(String(20),  nullable=False, default="Active")

    # server_default delega ao PostgreSQL — equivalente ao DEFAULT CURRENT_DATE do SQL
    Registration_Date = Column(Date, nullable=False, server_default=func.current_date())

    # Constraints CHECK (mesmo que no SQL)
    __table_args__ = (
        CheckConstraint("Role IN ('Student', 'Professor', 'Admin')",         name="check_role"),
        CheckConstraint("Status IN ('Active', 'Suspended', 'Deactivated')",  name="check_status"),
    )

    # Relações — permitem aceder ao registo filho diretamente
    # uselist=False — relação um-para-um (um utilizador tem apenas um Student/Professor/Admin)
    student   = relationship("Student",   back_populates="user", uselist=False)
    professor = relationship("Professor", back_populates="user", uselist=False)
    admin     = relationship("Admin",     back_populates="user", uselist=False)


# =============================================================
# Student
# ID_Student é PK e FK ao mesmo tempo — é o mesmo UUID do Base_User.
# Contém dados de gamificação: nível, XP, streak, último acesso.
# =============================================================
class Student(Base):
    __tablename__ = "student"

    ID_Student    = Column(
        UUID(as_uuid=True),
        ForeignKey("base_user.ID_User", ondelete="CASCADE"),
        primary_key=True
    )
    Current_Level = Column(Integer,  nullable=False, default=1)
    Total_XP      = Column(Integer,  nullable=False, default=0)
    Streak_Days   = Column(Integer,  nullable=False, default=0)  # streak atual, tipo Duolingo
    Last_Access   = Column(DateTime, nullable=True)

    # Relação inversa com Base_User
    user = relationship("Base_User", back_populates="student")

    # Relações com tabelas filhas
    progress_records = relationship("Progress", back_populates="student")
    streak_records   = relationship("Streak",   back_populates="student")


# =============================================================
# Professor
# ID_Professor é PK e FK — é o mesmo UUID do Base_User.
# Contém dados profissionais do professor.
# =============================================================
class Professor(Base):
    __tablename__ = "professor"

    ID_Professor = Column(
        UUID(as_uuid=True),
        ForeignKey("base_user.ID_User", ondelete="CASCADE"),
        primary_key=True
    )
    Department = Column(String(100), nullable=True)
    Office     = Column(String(50),  nullable=True)
    Short_Bio  = Column(Text,        nullable=True)

    # Relação inversa com Base_User
    user = relationship("Base_User", back_populates="professor")

    # Relações com tabelas filhas
    professor_ucs      = relationship("Professor_UC",      back_populates="professor")
    teaching_materials = relationship("Teaching_Material", back_populates="professor")
    requests           = relationship("Request",           back_populates="professor")


# =============================================================
# Admin
# ID_Admin é PK e FK — é o mesmo UUID do Base_User.
# Privilege_Level: 1 (básico), 2 (moderador), 3 (superadmin).
# =============================================================
class Admin(Base):
    __tablename__ = "admin"

    ID_Admin        = Column(
        UUID(as_uuid=True),
        ForeignKey("base_user.ID_User", ondelete="CASCADE"),
        primary_key=True
    )
    Privilege_Level = Column(SmallInteger, nullable=False)
    Contact         = Column(String(150),  nullable=True)

    __table_args__ = (
        CheckConstraint("Privilege_Level BETWEEN 1 AND 3", name="check_privilege_level"),
    )

    # Relação inversa com Base_User
    user = relationship("Base_User", back_populates="admin")

    # Relações com tabelas filhas
    requests          = relationship("Request",          back_populates="admin")
    audit_log_entries = relationship("Admin_Audit_Log",  back_populates="admin")


# =============================================================
# Professor_UC
# Tabela de junção — quais professores gerem quais UCs.
# PK composta: (ID_Professor, ID_UC).
# Nota: Course_Unit está definido em academic.py — o __init__.py
# dos models garante que ambos os ficheiros são importados.
# =============================================================
class Professor_UC(Base):
    __tablename__ = "professor_uc"

    ID_Professor = Column(
        UUID(as_uuid=True),
        ForeignKey("professor.ID_Professor", ondelete="CASCADE"),
        primary_key=True
    )
    ID_UC = Column(
        Integer,
        ForeignKey("course_unit.ID_UC", ondelete="CASCADE"),
        primary_key=True
    )

    # Relações
    professor   = relationship("Professor",
                            back_populates="professor_ucs")
    course_unit = relationship(
                            "Course_Unit", 
                            back_populates="professor_ucs")
    