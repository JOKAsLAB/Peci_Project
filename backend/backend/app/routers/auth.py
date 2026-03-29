from fastapi import APIRouter, Depends, HTTPException, status
from sqlalchemy import select
from sqlalchemy.ext.asyncio import AsyncSession

from app.database import get_db
from app.models import Base_User, Professor, Student
from app.routers.deps import get_current_user
from app.schemas.user import AuthResponse, LoginRequest, RegisterRequest, UserResponse
from app.security import create_access_token, hash_password, verify_password

router = APIRouter(prefix="/api/v1/auth", tags=["auth"])


def to_user_response(user: Base_User) -> UserResponse:
	return UserResponse(
		id=user.ID_User,
		name=user.Name,
		email=user.Email,
		role=user.Role,
		status=user.Status,
		registration_date=user.Registration_Date,
	)


@router.post("/register", response_model=AuthResponse, status_code=status.HTTP_201_CREATED)
async def register(payload: RegisterRequest, db: AsyncSession = Depends(get_db)):
	existing = await db.scalar(select(Base_User).where(Base_User.Email == payload.email))
	if existing:
		raise HTTPException(status_code=status.HTTP_409_CONFLICT, detail="Email already registered")

	new_user = Base_User(
		Name=payload.name,
		Email=payload.email,
		Password_Hash=hash_password(payload.password),
		Role=payload.role,
		Status="Active",
	)
	db.add(new_user)
	await db.flush()

	if payload.role == "Student":
		db.add(Student(ID_Student=new_user.ID_User))
	else:
		db.add(
			Professor(
				ID_Professor=new_user.ID_User,
				Department=payload.department,
				Office=payload.office,
				Short_Bio=payload.short_bio,
			)
		)

	await db.flush()
	token = create_access_token(subject=str(new_user.ID_User), role=new_user.Role)
	return AuthResponse(access_token=token, user=to_user_response(new_user))


@router.post("/login", response_model=AuthResponse)
async def login(payload: LoginRequest, db: AsyncSession = Depends(get_db)):
	user = await db.scalar(select(Base_User).where(Base_User.Email == payload.email))
	if not user or not verify_password(payload.password, user.Password_Hash):
		raise HTTPException(status_code=status.HTTP_401_UNAUTHORIZED, detail="Invalid email or password")

	if user.Status != "Active":
		raise HTTPException(status_code=status.HTTP_403_FORBIDDEN, detail="User is not active")

	token = create_access_token(subject=str(user.ID_User), role=user.Role)
	return AuthResponse(access_token=token, user=to_user_response(user))


@router.get("/me", response_model=UserResponse)
async def me(current_user: Base_User = Depends(get_current_user)):
	return to_user_response(current_user)