from datetime import date, datetime
from typing import Literal
from uuid import UUID

from pydantic import BaseModel, Field


ProgressStatusType = Literal["Correct", "Incorrect", "Partial"]
SyncStatusType = Literal["Pending", "Synced", "Failed"]


class ProgressCreateRequest(BaseModel):
	id_exercise: UUID
	attempts: int = Field(default=1, ge=1)
	status: ProgressStatusType
	xp_earned: int = Field(default=0, ge=0)
	sync_status: SyncStatusType = "Pending"


class ProgressResponse(BaseModel):
	id_progress: UUID
	id_student: UUID
	id_exercise: UUID
	attempts: int
	status: ProgressStatusType
	xp_earned: int
	sync_status: SyncStatusType
	recorded_at: datetime | None = None


class StreakResponse(BaseModel):
	id_streak: UUID
	id_student: UUID
	log_date: date
	sync_status: SyncStatusType


class StudentProfileResponse(BaseModel):
	id_student: UUID
	current_level: int
	total_xp: int
	streak_days: int
	last_access: datetime | None = None
