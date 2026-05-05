# =============================================================
# PECI PROJECT — Models Package Init
#
# Este ficheiro tem dois objetivos:
#
# 1. ORDEM DE IMPORTS — o SQLAlchemy precisa de conhecer todos
#    os models antes de resolver as relações entre tabelas.
#    A ordem aqui importa: tabelas pai antes de tabelas filhas.
#
# 2. CONVENIÊNCIA — permite importar qualquer model diretamente
#    de app.models em vez de app.models.user, por exemplo:
#
#    Em vez de:
#      from app.models.user import Base_User, Student
#      from app.models.academic import Course_Unit
#
#    Podes fazer:
#      from app.models import Base_User, Student, Course_Unit
#
# ORDEM OBRIGATÓRIA (respeita as FKs):
#   1. user.py       — Base_User, Student, Professor, Admin, Professor_UC
#                      (Professor_UC referencia Course_Unit, mas o SQLAlchemy
#                       resolve por string lazy — desde que academic.py
#                       seja importado antes de qualquer query)
#   2. academic.py   — Course_Unit, Topic, Teaching_Material, Exercise
#   3. gamification.py — Progress, Streak
#   4. admin.py      — Request, Admin_Audit_Log
#   5. learning_path.py — LearningPath, LearningPathExercise
# =============================================================

# --- Bloco 1: Utilizadores ---
from app.models.user import (
    Base_User,
    Student,
    Professor,
    Admin,
    Professor_UC,
    Student_UC,
)

# --- Bloco 2: Conteúdo Académico ---
from app.models.academic import (
    Course_Unit,
    Topic,
    Teaching_Material,
    Exercise,
)

# --- Bloco 3: Gamificação ---
from app.models.gamification import (
    Progress,
    Streak,
)

# --- Bloco 4: Admin ---
from app.models.admin import (
    Request,
    Admin_Audit_Log,
)

# --- Bloco 5: Learning Paths ---
from app.models.learning_path import (
    LearningPath,
    LearningPathExercise,
)

# --- Bloco 6: Quizzes ---
from app.models.quiz import (
    Quiz,
    Quiz_Exercise,
    Quiz_Session,
    Quiz_Participant,
    Quiz_Answer,
)

# =============================================================
# __all__ — define o que é exportado quando alguém faz:
# from app.models import *
# =============================================================
__all__ = [
    # Utilizadores
    "Base_User",
    "Student",
    "Professor",
    "Admin",
    "Professor_UC",
    "Student_UC",
    # Conteúdo Académico
    "Course_Unit",
    "Topic",
    "Teaching_Material",
    "Exercise",
    # Gamificação
    "Progress",
    "Streak",
    # Admin
    "Request",
    "Admin_Audit_Log",
    # Learning Paths
    "LearningPath",
    "LearningPathExercise",
    # Quizzes
    "Quiz",
    "Quiz_Exercise",
    "Quiz_Session",
    "Quiz_Participant",
    "Quiz_Answer",
]