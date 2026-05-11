import asyncio
import random
import smtplib
import string
from datetime import datetime, timedelta
from email.mime.multipart import MIMEMultipart
from email.mime.text import MIMEText

from fastapi import APIRouter, Depends, HTTPException, Response, status
from sqlalchemy import select
from sqlalchemy.ext.asyncio import AsyncSession

from app.database import get_db, settings
from app.models import Admin, Base_User, Professor, Request, Student
from app.models.enums import RequestStatus, RequestType, UserRole, UserStatus
from app.routers.deps import get_current_user
from app.schemas.user import AuthResponse, LoginRequest, MessageResponse, RegisterRequest, UserResponse, VerifyEmailRequest
from app.security import create_access_token, hash_password, verify_password

router = APIRouter(prefix="/api/v1/auth", tags=["auth"])

# email -> (code, expires_at)
_verification_codes: dict[str, tuple[str, datetime]] = {}


def _generate_code() -> str:
    return ''.join(random.choices(string.digits, k=6))


async def _send_verification_email(to_email: str, code: str) -> None:
    print(f"[EMAIL VERIFY] Code for {to_email}: {code}")
    if not settings.SMTP_HOST:
        return

    def _send() -> None:
        msg = MIMEMultipart()
        sender = settings.SMTP_FROM or settings.SMTP_USER
        msg['From'] = sender
        msg['To'] = to_email
        msg['Subject'] = 'PECI LogicStreak — Código de verificação'
        body = (
            f"Olá!\n\n"
            f"O teu código de verificação de email é:\n\n"
            f"  {code}\n\n"
            f"O código expira em 15 minutos.\n\n"
            f"Se não criaste uma conta, ignora este email."
        )
        msg.attach(MIMEText(body, 'plain', 'utf-8'))
        with smtplib.SMTP(settings.SMTP_HOST, settings.SMTP_PORT, timeout=10) as server:
            server.ehlo()
            server.starttls()
            server.ehlo()
            server.login(settings.SMTP_USER, settings.SMTP_PASSWORD)
            server.sendmail(sender, to_email, msg.as_string())

    await asyncio.to_thread(_send)


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
	is_student_registration = payload.role == UserRole.STUDENT

	common = {
		"Name": payload.name,
		"Email": payload.email,
		"Password_Hash": hash_password(payload.password),
		"Role": payload.role,
		"Status": UserStatus.SUSPENDED if (is_professor_registration or is_student_registration) else UserStatus.ACTIVE,
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

	if is_student_registration:
		code = _generate_code()
		_verification_codes[payload.email.lower()] = (code, datetime.utcnow() + timedelta(minutes=15))
		try:
			await _send_verification_email(payload.email, code)
		except Exception as e:
			import traceback
			print(f"[EMAIL ERROR] {e}")
			traceback.print_exc()

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

	if user.Role == UserRole.STUDENT and user.Status == UserStatus.SUSPENDED:
		raise HTTPException(status_code=status.HTTP_403_FORBIDDEN, detail="Account not verified. Check your email for the verification code.")

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


@router.post("/verify-email", response_model=MessageResponse)
async def verify_email(payload: VerifyEmailRequest, db: AsyncSession = Depends(get_db)):
	email_key = payload.email.lower()
	entry = _verification_codes.get(email_key)
	if not entry:
		raise HTTPException(status_code=status.HTTP_400_BAD_REQUEST, detail="No verification pending for this email")

	code, expires_at = entry
	if datetime.utcnow() > expires_at:
		del _verification_codes[email_key]
		raise HTTPException(status_code=status.HTTP_400_BAD_REQUEST, detail="Verification code expired")

	if payload.code != code:
		raise HTTPException(status_code=status.HTTP_400_BAD_REQUEST, detail="Invalid verification code")

	user = await db.scalar(select(Base_User).where(Base_User.Email == payload.email))
	if not user:
		raise HTTPException(status_code=status.HTTP_404_NOT_FOUND, detail="User not found")

	user.Status = UserStatus.ACTIVE
	del _verification_codes[email_key]
	return MessageResponse(message="Email verified successfully")


@router.get("/me", response_model=UserResponse)
async def me(current_user: Base_User = Depends(get_current_user)):
	return to_user_response(current_user)