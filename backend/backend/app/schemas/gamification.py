from datetime import date, datetime
from uuid import UUID

from pydantic import BaseModel, Field

from app.models.enums import ProgressStatus, SyncStatus


class ProgressCreateRequest(BaseModel):
    id_exercise: UUID
    attempts: int = Field(default=1, ge=1)
    status: ProgressStatus
    xp_earned: int = Field(default=0, ge=0)
    sync_status: SyncStatus = SyncStatus.PENDING


class ProgressResponse(BaseModel):
    id_progress: UUID
    id_student: UUID
    id_exercise: UUID
    attempts: int
    status: ProgressStatus
    xp_earned: int
    sync_status: SyncStatus
    recorded_at: datetime | None = None

    class Config:
        from_attributes = True


class StreakResponse(BaseModel):
    id_streak: UUID
    id_student: UUID
    log_date: date
    sync_status: SyncStatus

    class Config:
        from_attributes = True


class StudentProfileResponse(BaseModel):
    id_student: UUID
    current_level: int
    total_xp: int
    streak_days: int
    last_access: datetime | None = None

    class Config:
        from_attributes = True