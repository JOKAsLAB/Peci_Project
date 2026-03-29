from datetime import date
from typing import Literal
from uuid import UUID

from pydantic import BaseModel, EmailStr, Field


RoleType = Literal["Student", "Professor", "Admin"]
StatusType = Literal["Active", "Suspended", "Deactivated"]


class RegisterRequest(BaseModel):
	name: str = Field(min_length=2, max_length=100)
	email: EmailStr
	password: str = Field(min_length=6, max_length=128)
	role: Literal["Student", "Professor"]
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
	role: RoleType
	status: StatusType
	registration_date: date | None = None


class AuthResponse(BaseModel):
	access_token: str
	token_type: str = "bearer"
	user: UserResponse


class UserUpdateRequest(BaseModel):
	name: str | None = Field(default=None, min_length=2, max_length=100)
	status: StatusType | None = None


class MessageResponse(BaseModel):
	message: str
