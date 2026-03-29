from datetime import datetime
from typing import Literal
from uuid import UUID

from pydantic import BaseModel, Field


RequestStatusType = Literal["pending", "approved", "rejected"]


class AdminRequestResponse(BaseModel):
	id_request: int
	id_professor: UUID
	id_admin: UUID | None = None
	title: str
	description: str
	status: RequestStatusType
	admin_comment: str | None = None
	creation_date: datetime | None = None
	resolution_date: datetime | None = None


class AdminDecisionRequest(BaseModel):
	status: Literal["approved", "rejected"]
	admin_comment: str | None = None


class ProfessorRequestCreateRequest(BaseModel):
	title: str = Field(min_length=3, max_length=200)
	description: str = Field(min_length=5)
