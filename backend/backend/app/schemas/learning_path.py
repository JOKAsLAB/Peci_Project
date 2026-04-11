# =============================================================
# PECI PROJECT — Schemas: Learning Paths (Pydantic validation)
#
# Define estruturas para validação de requests/responses
# relacionados com Learning Paths.
# =============================================================

from pydantic import BaseModel, Field
from uuid import UUID
from typing import Optional, List
from datetime import datetime


# =============================================================
# Learning Path Exercise
# =============================================================

class LearningPathExerciseCreate(BaseModel):
    """Schema para adicionar um exercício a um caminho."""
    ID_Exercise: UUID = Field(..., description="UUID do exercício")
    Order_Num: int = Field(..., ge=1, description="Número de ordem (>=1)")

    class Config:
        from_attributes = True


class LearningPathExerciseResponse(BaseModel):
    """Schema para retornar um exercício num caminho."""
    ID: UUID
    ID_Exercise: UUID
    Order_Num: int

    class Config:
        from_attributes = True


# =============================================================
# Learning Path
# =============================================================

class LearningPathCreate(BaseModel):
    """Schema para criar um novo caminho de aprendizagem."""
    Name: str = Field(..., max_length=200, description="Nome do caminho")
    Description: Optional[str] = Field(None, description="Descrição opcional")
    Published: bool = Field(False, description="Se está publicado ou em rascunho")

    class Config:
        from_attributes = True


class LearningPathUpdate(BaseModel):
    """Schema para atualizar um caminho de aprendizagem."""
    Name: Optional[str] = Field(None, max_length=200)
    Description: Optional[str] = Field(None)
    Published: Optional[bool] = Field(None)

    class Config:
        from_attributes = True


class LearningPathResponse(BaseModel):
    """Schema para retornar um caminho de aprendizagem completo."""
    ID_Path: UUID
    ID_UC: int
    ID_Professor: UUID
    Name: str
    Description: Optional[str]
    Published: bool
    Created_At: datetime
    Updated_At: datetime
    # path_exercises: List[LearningPathExerciseResponse] = Field(default_factory=list)

    class Config:
        from_attributes = True


class LearningPathDetailResponse(BaseModel):
    """Schema para retornar um caminho com exercícios detalhados."""
    ID_Path: UUID
    ID_UC: int
    ID_Professor: UUID
    Name: str
    Description: Optional[str]
    Published: bool
    Created_At: datetime
    Updated_At: datetime
    path_exercises: List[LearningPathExerciseResponse] = Field(default_factory=list)

    class Config:
        from_attributes = True
