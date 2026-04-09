from sqlalchemy import Enum as SAEnum

# =============================================================
# Helper para criar colunas ENUM de forma consistente e compatível com asyncpg.
# Devolve o .value do enum. Exemplo: EnumColumn(UserRole, "user_role_enum") 
# cria uma coluna ENUM que armazena "Student", "Professor", etc. e não STUDENT, PROFESSOR, etc.

def EnumColumn(enum_cls, name: str, **kwargs):
    return SAEnum(
        enum_cls,
        name=name,
        values_callable=lambda e: [i.value for i in e],
        **kwargs
    )
