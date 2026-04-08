from datetime import datetime
from typing import Any
from uuid import UUID

from pydantic import BaseModel, Field

from app.models.enums import DifficultyLevel, ExerciseType, MaterialStatus


class CourseUnitBasicInfo(BaseModel):
    id_uc: int
    name: str

    class Config:
        from_attributes = True


class CourseUnitProfessorInfo(BaseModel):
    id: UUID
    name: str
    email: str


class CourseUnitResponse(BaseModel):
    id_uc: int
    name: str
    semester: str | None = None
    curricular_year: int | None = None
    professors: list[CourseUnitProfessorInfo] = Field(default_factory=list)

    class Config:
        from_attributes = True


class CourseUnitCreateRequest(BaseModel):
    id_uc: int
    name: str = Field(min_length=2, max_length=100)
    semester: str | None = Field(default=None, max_length=20)
    curricular_year: int | None = None
    professor_ids: list[UUID] = Field(default_factory=list)


class CourseUnitUpdateRequest(BaseModel):
    name: str | None = Field(default=None, min_length=2, max_length=100)
    semester: str | None = Field(default=None, max_length=20)
    curricular_year: int | None = None
    professor_ids: list[UUID] | None = None


class ExerciseResponse(BaseModel):
    id_exercise: UUID
    id_uc: int
    topic_name: str
    material_ref: UUID | None = None
    type: ExerciseType
    question: str
    solution: dict[str, Any]
    difficulty: DifficultyLevel
    explanation: str | None = None
    
    # Otimização de Eager Loading para evitar N+1 queries no cliente (Vue.js)
    course_unit_info: CourseUnitBasicInfo | None = None

    class Config:
        from_attributes = True


class ExerciseCreateRequest(BaseModel):
    id_uc: int
    topic_name: str = Field(min_length=2, max_length=100)
    material_ref: UUID | None = None
    type: ExerciseType
    question: str = Field(min_length=5)
    solution: dict[str, Any]
    difficulty: DifficultyLevel
    explanation: str | None = None


class MaterialResponse(BaseModel):
    id_material: UUID
    id_uc: int
    id_professor: UUID
    status: MaterialStatus
    title: str
    upload_date: datetime | None = None

    class Config:
        from_attributes = True


class MaterialCreateRequest(BaseModel):
    id_uc: int
    title: str = Field(min_length=2, max_length=200)