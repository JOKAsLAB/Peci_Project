from datetime import datetime
from typing import Any, Literal
from uuid import UUID

from pydantic import BaseModel, Field


DifficultyType = Literal["Easy", "Medium", "Hard"]
ExerciseType = Literal["Multiple Choice", "True/False"]
MaterialStatusType = Literal["Pending", "Indexed", "Error"]


class CourseUnitResponse(BaseModel):
	id_uc: int
	name: str
	semester: str | None = None
	curricular_year: int | None = None


class CourseUnitCreateRequest(BaseModel):
	id_uc: int
	name: str = Field(min_length=2, max_length=100)
	semester: str | None = Field(default=None, max_length=20)
	curricular_year: int | None = None


class CourseUnitUpdateRequest(BaseModel):
	name: str | None = Field(default=None, min_length=2, max_length=100)
	semester: str | None = Field(default=None, max_length=20)
	curricular_year: int | None = None


class ExerciseResponse(BaseModel):
	id_exercise: UUID
	id_uc: int
	topic_name: str
	material_ref: UUID | None = None
	type: ExerciseType
	question: str
	solution: dict[str, Any]
	difficulty: DifficultyType
	explanation: str | None = None


class ExerciseCreateRequest(BaseModel):
	id_uc: int
	topic_name: str = Field(min_length=2, max_length=100)
	material_ref: UUID | None = None
	type: ExerciseType
	question: str = Field(min_length=5)
	solution: dict[str, Any]
	difficulty: DifficultyType
	explanation: str | None = None


class MaterialResponse(BaseModel):
	id_material: UUID
	id_uc: int
	id_professor: UUID
	status: MaterialStatusType
	title: str
	file_path: str
	extracted_text: str | None = None
	upload_date: datetime | None = None


class MaterialCreateRequest(BaseModel):
	id_uc: int
	title: str = Field(min_length=2, max_length=200)
	file_path: str = Field(min_length=3)
	extracted_text: str | None = None
