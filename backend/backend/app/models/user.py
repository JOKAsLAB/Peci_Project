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

from sqlalchemy import (
    Column, String, Text, Date, DateTime,
    Integer, SmallInteger, ForeignKey, CheckConstraint
)
from sqlalchemy.dialects.postgresql import UUID
from app.models.utils import EnumColumn
from sqlalchemy.orm import relationship
from sqlalchemy.sql import func

from app.database import Base
from app.models.enums import UserRole, UserStatus


# =============================================================
# Base_User
# Tabela central — contém credenciais e dados comuns a todos.
# =============================================================
class Base_User(Base):
    __tablename__ = "base_user"

    ID_User = Column(
        "id_user",              # nome real na BD
        UUID(as_uuid=True),
        primary_key=True,
        server_default=func.gen_random_uuid()  # Delegação otimizada para o motor PostgreSQL
    )
    Name              = Column("name",              String(100), nullable=False)
    Email             = Column("email",             String(150), nullable=False, unique=True)
    Password_Hash     = Column("password_hash",     Text,        nullable=False)

    # ATENÇÃO: create_type=True (OBRIGATÓRIO PARA ASYNCPG)
    Role = Column("role", EnumColumn(UserRole, "user_role_enum"), nullable=False)

    Status = Column("status", EnumColumn(UserStatus, "user_status_enum"), nullable=False)

    # server_default delega ao PostgreSQL — equivalente ao DEFAULT CURRENT_DATE do SQL
    Registration_Date = Column("registration_date", Date, nullable=False, server_default=func.current_date())

    # Definição do comportamento polimórfico (Joined Table Inheritance)
    # Elimina a necessidade de relações manuais "uselist=False"
    __mapper_args__ = {
        "polymorphic_on": Role,
        "polymorphic_identity": "base",
        "with_polymorphic": "*"
    }


# =============================================================
# Student
# ID_Student é PK e FK ao mesmo tempo — é o mesmo UUID do Base_User.
# Contém dados de gamificação: nível, XP, streak, último acesso.
# =============================================================
class Student(Base_User):
    __tablename__ = "student"

    ID_Student    = Column(
        "id_student",
        UUID(as_uuid=True),
        ForeignKey("base_user.id_user", ondelete="CASCADE"),
        primary_key=True
    )
    Current_Level = Column("current_level", Integer,  nullable=False, default=1)
    Total_XP      = Column("total_xp", Integer,  nullable=False, default=0)
    Streak_Days   = Column("streak_days", Integer,  nullable=False, default=0)  # streak atual, tipo Duolingo
    Last_Access   = Column("last_access", DateTime, nullable=True)

    __mapper_args__ = {
        "polymorphic_identity": UserRole.STUDENT,
    }

    # Relações com tabelas filhas
    student_ucs        = relationship("Student_UC",        back_populates="student", passive_deletes=True)
    progress_records   = relationship("Progress",          back_populates="student", passive_deletes=True)
    streak_records     = relationship("Streak",            back_populates="student", passive_deletes=True)
    quiz_participations = relationship("Quiz_Participant", back_populates="student", passive_deletes=True)


# =============================================================
# Professor
# ID_Professor é PK e FK — é o mesmo UUID do Base_User.
# Contém dados profissionais do professor.
# =============================================================
class Professor(Base_User):
    __tablename__ = "professor"

    ID_Professor = Column(
        "id_professor",
        UUID(as_uuid=True),
        ForeignKey("base_user.id_user", ondelete="CASCADE"),
        primary_key=True
    )
    Department = Column("department", String(100), nullable=True)
    Office     = Column("office", String(50),  nullable=True)
    Short_Bio  = Column("short_bio", Text,        nullable=True)

    __mapper_args__ = {
        "polymorphic_identity": UserRole.PROFESSOR,
    }

    # Relações com tabelas filhas
    professor_ucs      = relationship("Professor_UC",      back_populates="professor")
    teaching_materials = relationship("Teaching_Material", back_populates="professor")
    requests           = relationship("Request",           back_populates="professor", passive_deletes=True)
    quizzes            = relationship("Quiz",              back_populates="professor", passive_deletes=True)


# =============================================================
# Admin
# ID_Admin é PK e FK — é o mesmo UUID do Base_User.
# Privilege_Level: 1 (básico), 2 (moderador), 3 (superadmin).
# =============================================================
class Admin(Base_User):
    __tablename__ = "admin"

    ID_Admin        = Column(
        "id_admin",
        UUID(as_uuid=True),
        ForeignKey("base_user.id_user", ondelete="CASCADE"),
        primary_key=True
    )
    Privilege_Level = Column("privilege_level", SmallInteger, nullable=False)
    Contact         = Column("contact", String(150),  nullable=True)

    __table_args__ = (
        # IMPORTANTE: A string do CheckConstraint deve coincidir EXACTAMENTE
        # com o nome da variável da coluna definida acima.
        CheckConstraint('"Privilege_Level" BETWEEN 1 AND 3', name="check_privilege_level"),
    )

    __mapper_args__ = {
        "polymorphic_identity": UserRole.ADMIN,
    }

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
        "id_professor",
        UUID(as_uuid=True),
        ForeignKey("professor.id_professor", ondelete="CASCADE"),
        primary_key=True
    )
    ID_UC = Column(
        "id_uc",
        Integer,
        ForeignKey("course_unit.id_uc", ondelete="CASCADE"),
        primary_key=True
    )

    # Relações
    professor   = relationship("Professor",
                            back_populates="professor_ucs")
    course_unit = relationship(
                            "Course_Unit",
                            back_populates="professor_ucs")


# =============================================================
# Student_UC
# Tabela de junção — em que UCs cada estudante está inscrito.
# PK composta: (ID_Student, ID_UC).
# =============================================================
class Student_UC(Base):
    __tablename__ = "student_uc"

    ID_Student = Column(
        "id_student",           # FIX: nome explícito em minúsculas
        UUID(as_uuid=True),
        ForeignKey("student.id_student", ondelete="CASCADE"),
        primary_key=True
    )
    ID_UC = Column(
        "id_uc",                # FIX: nome explícito em minúsculas
        Integer,
        ForeignKey("course_unit.id_uc", ondelete="CASCADE"),
        primary_key=True
    )

    # Relações
    student = relationship("Student", back_populates="student_ucs")
    course_unit = relationship("Course_Unit", back_populates="student_ucs")