from datetime import datetime
from uuid import UUID
from pydantic import BaseModel, Field
from app.models.enums import RequestStatus, RequestType

class ProfessorBasicInfo(BaseModel):
    id: UUID
    name: str
    email: str

class AdminBasicInfo(BaseModel):
    id: UUID
    name: str
    email: str

class AdminRequestResponse(BaseModel):
    id_request: int
    id_professor: UUID
    id_admin: UUID | None = None
    request_type: RequestType
    title: str
    description: str
    status: RequestStatus
    admin_comment: str | None = None
    creation_date: datetime | None = None
    resolution_date: datetime | None = None
    
    # Relações injetadas para evitar N+1 no frontend
    professor_info: ProfessorBasicInfo | None = None
    admin_info: AdminBasicInfo | None = None

    class Config:
        from_attributes = True

class AdminDecisionRequest(BaseModel):
    status: RequestStatus
    admin_comment: str | None = None

class ProfessorRequestCreateRequest(BaseModel):
    request_type: RequestType
    title: str = Field(min_length=3, max_length=200)
    description: str = Field(min_length=5)