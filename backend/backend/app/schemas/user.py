from datetime import date
from uuid import UUID
from pydantic import BaseModel, EmailStr, Field
from app.models.enums import UserRole, UserStatus

class RegisterRequest(BaseModel):
    name: str = Field(min_length=2, max_length=100)
    email: EmailStr
    password: str = Field(min_length=6, max_length=128)
    role: UserRole
    department: str | None = Field(default=None, max_length=100)
    office: str | None = Field(default=None, max_length=50)
    short_bio: str | None = None

class LoginRequest(BaseModel):
    email: EmailStr
    password: str = Field(min_length=6, max_length=128)

class UserResponse(BaseModel):
    id: UUID
    name: str
    email: EmailStr
    role: UserRole
    status: UserStatus
    registration_date: date | None = None

    class Config:
        from_attributes = True

class AuthResponse(BaseModel):
    access_token: str
    token_type: str = "bearer"
    user: UserResponse

class UserUpdateRequest(BaseModel):
    name: str | None = Field(default=None, min_length=2, max_length=100)
    status: UserStatus | None = None

class MessageResponse(BaseModel):
    message: str

class VerifyEmailRequest(BaseModel):
    email: EmailStr
    code: str = Field(min_length=6, max_length=6)