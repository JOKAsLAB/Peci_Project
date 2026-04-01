from fastapi import APIRouter, Depends, HTTPException, Response, status
from sqlalchemy import select
from sqlalchemy.ext.asyncio import AsyncSession

from app.database import get_db, settings
from app.models import Admin, Base_User, Professor, Request, Student
from app.models.enums import RequestStatus, RequestType, UserRole, UserStatus
from app.routers.deps import get_current_user
from app.schemas.user import AuthResponse, LoginRequest, MessageResponse, RegisterRequest, UserResponse
from app.security import create_access_token, hash_password, verify_password

router = APIRouter(prefix="/api/v1/auth", tags=["auth"])


def _set_auth_cookie(response: Response, token: str) -> None:
    response.set_cookie(
        key=settings.AUTH_COOKIE_NAME,
        value=token,
        httponly=True,
        secure=settings.AUTH_COOKIE_SECURE,
        samesite=settings.AUTH_COOKIE_SAMESITE,
        domain=settings.AUTH_COOKIE_DOMAIN,
        path=settings.AUTH_COOKIE_PATH,
        max_age=settings.ACCESS_TOKEN_EXPIRE_MINUTES * 60,
    )


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
async def register(payload: RegisterRequest, response: Response, db: AsyncSession = Depends(get_db)):
	existing = await db.scalar(select(Base_User).where(Base_User.Email == payload.email))
	if existing:
		raise HTTPException(status_code=status.HTTP_409_CONFLICT, detail="Email already registered")

	is_professor_registration = payload.role == UserRole.PROFESSOR

	common = {
		"Name": payload.name,
		"Email": payload.email,
		"Password_Hash": hash_password(payload.password),
		"Role": payload.role,
		"Status": UserStatus.SUSPENDED if is_professor_registration else UserStatus.ACTIVE,
	}

	if payload.role == UserRole.STUDENT:
		new_user = Student(**common)
	elif payload.role == UserRole.PROFESSOR:
		new_user = Professor(
			**common,
			Department=payload.department,
			Office=payload.office,
			Short_Bio=payload.short_bio,
		)
	elif payload.role == UserRole.ADMIN:
		new_user = Admin(
			**common,
			Privilege_Level=3,
			Contact=payload.email,
		)
	else:
		raise HTTPException(status_code=status.HTTP_400_BAD_REQUEST, detail="Invalid role")

	db.add(new_user)

	await db.flush()

	if is_professor_registration:
		db.add(
			Request(
				ID_Professor=new_user.ID_User,
				Request_Type=RequestType.ACCESS,
				Title="Pedido de acesso ao painel docente",
				Description="Registo de conta docente pendente de aprovacao administrativa.",
				Status=RequestStatus.PENDING,
			)
		)
		await db.flush()

	token = create_access_token(subject=str(new_user.ID_User), role=new_user.Role)
	_set_auth_cookie(response, token)
	return AuthResponse(access_token=token, user=to_user_response(new_user))


@router.post("/login", response_model=AuthResponse)
async def login(payload: LoginRequest, response: Response, db: AsyncSession = Depends(get_db)):
	user = await db.scalar(select(Base_User).where(Base_User.Email == payload.email))
	if not user or not verify_password(payload.password, user.Password_Hash):
		raise HTTPException(status_code=status.HTTP_401_UNAUTHORIZED, detail="Invalid email or password")

	if user.Role == UserRole.PROFESSOR and user.Status == UserStatus.SUSPENDED:
		raise HTTPException(status_code=status.HTTP_403_FORBIDDEN, detail="Account pending admin approval")

	if user.Status != UserStatus.ACTIVE:
		raise HTTPException(status_code=status.HTTP_403_FORBIDDEN, detail="User is not active")

	token = create_access_token(subject=str(user.ID_User), role=user.Role)
	_set_auth_cookie(response, token)
	return AuthResponse(access_token=token, user=to_user_response(user))


@router.post("/logout", response_model=MessageResponse)
async def logout(response: Response):
	response.delete_cookie(
		key=settings.AUTH_COOKIE_NAME,
		domain=settings.AUTH_COOKIE_DOMAIN,
		path=settings.AUTH_COOKIE_PATH,
	)
	return MessageResponse(message="Logout successful")


@router.get("/me", response_model=UserResponse)
async def me(current_user: Base_User = Depends(get_current_user)):
	return to_user_response(current_user)