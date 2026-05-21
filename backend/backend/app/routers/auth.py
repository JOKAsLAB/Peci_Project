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
from app.schemas.user import (
    AuthResponse,
    ForgotPasswordRequest,
    LoginRequest,
    MessageResponse,
    RegisterRequest,
    ResetPasswordRequest,
    UserResponse,
    VerifyEmailRequest,
)
from app.security import create_access_token, hash_password, verify_password

router = APIRouter(prefix="/api/v1/auth", tags=["auth"])

# email -> (code, expires_at)
_verification_codes: dict[str, tuple[str, datetime]] = {}
_reset_codes: dict[str, tuple[str, datetime]] = {}


def _generate_code() -> str:
    return ''.join(random.choices(string.digits, k=6))


async def _send_email(to_email: str, subject: str, body: str) -> None:
    if not settings.SMTP_HOST:
        return

    def _send() -> None:
        msg = MIMEMultipart()
        sender = settings.SMTP_FROM or settings.SMTP_USER
        msg['From'] = sender
        msg['To'] = to_email
        msg['Subject'] = subject
        msg.attach(MIMEText(body, 'plain', 'utf-8'))
        with smtplib.SMTP(settings.SMTP_HOST, settings.SMTP_PORT, timeout=10) as server:
            server.ehlo()
            server.starttls()
            server.ehlo()
            server.login(settings.SMTP_USER, settings.SMTP_PASSWORD)
            server.sendmail(sender, to_email, msg.as_string())

    await asyncio.to_thread(_send)


async def _send_verification_email(to_email: str, code: str) -> None:
    print(f"[EMAIL VERIFY] Code for {to_email}: {code}")
    body = (
        f"Olá!\n\n"
        f"O teu código de verificação de email é:\n\n"
        f"  {code}\n\n"
        f"O código expira em 15 minutos.\n\n"
        f"Se não criaste uma conta, ignora este email."
    )
    await _send_email(to_email, "PECI LogicStreak — Código de verificação", body)


async def _send_reset_email(to_email: str, code: str) -> None:
    print(f"[EMAIL RESET] Code for {to_email}: {code}")
    body = (
        f"Olá!\n\n"
        f"Recebemos um pedido de recuperação de password para a tua conta.\n\n"
        f"O teu código de recuperação é:\n\n"
        f"  {code}\n\n"
        f"O código expira em 15 minutos.\n\n"
        f"Se não fizeste este pedido, ignora este email — a tua password não foi alterada."
    )
    await _send_email(to_email, "PECI LogicStreak — Recuperação de password", body)


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
        raise HTTPException(status_code=status.HTTP_409_CONFLICT, detail="Email já registado")

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
        raise HTTPException(status_code=status.HTTP_400_BAD_REQUEST, detail="Perfil inválido")

    db.add(new_user)
    await db.flush()

    if is_professor_registration or is_student_registration:
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
        raise HTTPException(status_code=status.HTTP_401_UNAUTHORIZED, detail="Email ou password incorretos")

    if user.Role == UserRole.PROFESSOR and user.Status == UserStatus.SUSPENDED:
        raise HTTPException(status_code=status.HTTP_403_FORBIDDEN, detail="Conta pendente de aprovação pelo administrador")

    if user.Role == UserRole.STUDENT and user.Status == UserStatus.SUSPENDED:
        raise HTTPException(status_code=status.HTTP_403_FORBIDDEN, detail="Conta não verificada. Verifica o teu email para o código de verificação.")

    if user.Status != UserStatus.ACTIVE:
        raise HTTPException(status_code=status.HTTP_403_FORBIDDEN, detail="Conta desativada")

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
    return MessageResponse(message="Sessão terminada com sucesso")


@router.post("/refresh", response_model=AuthResponse)
async def refresh(response: Response, current_user: Base_User = Depends(get_current_user)):
    if current_user.Status != UserStatus.ACTIVE:
        raise HTTPException(status_code=status.HTTP_403_FORBIDDEN, detail="Conta desativada")
    token = create_access_token(subject=str(current_user.ID_User), role=current_user.Role)
    _set_auth_cookie(response, token)
    return AuthResponse(access_token=token, user=to_user_response(current_user))


@router.post("/verify-email", response_model=MessageResponse)
async def verify_email(payload: VerifyEmailRequest, db: AsyncSession = Depends(get_db)):
    email_key = payload.email.lower()
    entry = _verification_codes.get(email_key)
    if not entry:
        raise HTTPException(status_code=status.HTTP_400_BAD_REQUEST, detail="Não existe verificação pendente para este email")

    code, expires_at = entry
    if datetime.utcnow() > expires_at:
        del _verification_codes[email_key]
        raise HTTPException(status_code=status.HTTP_400_BAD_REQUEST, detail="Código de verificação expirado")

    if payload.code != code:
        raise HTTPException(status_code=status.HTTP_400_BAD_REQUEST, detail="Código de verificação inválido")

    user = await db.scalar(select(Base_User).where(Base_User.Email == payload.email))
    if not user:
        raise HTTPException(status_code=status.HTTP_404_NOT_FOUND, detail="Utilizador não encontrado")

    del _verification_codes[email_key]

    if user.Role == UserRole.PROFESSOR:
        db.add(
            Request(
                ID_Professor=user.ID_User,
                Request_Type=RequestType.ACCESS,
                Title="Pedido de acesso ao painel docente",
                Description="Registo de conta docente pendente de aprovação administrativa.",
                Status=RequestStatus.PENDING,
            )
        )
    else:
        user.Status = UserStatus.ACTIVE

    return MessageResponse(message="Email verificado com sucesso")


@router.post("/resend-verification", response_model=MessageResponse)
async def resend_verification(payload: ForgotPasswordRequest, db: AsyncSession = Depends(get_db)):
    user = await db.scalar(select(Base_User).where(Base_User.Email == payload.email))
    if user and user.Status == UserStatus.SUSPENDED:
        code = _generate_code()
        _verification_codes[payload.email.lower()] = (code, datetime.utcnow() + timedelta(minutes=15))
        try:
            await _send_verification_email(payload.email, code)
        except Exception as e:
            import traceback
            print(f"[EMAIL ERROR] {e}")
            traceback.print_exc()
    return MessageResponse(message="Se existir uma verificação pendente, receberás um novo código.")


@router.post("/forgot-password", response_model=MessageResponse)
async def forgot_password(payload: ForgotPasswordRequest, db: AsyncSession = Depends(get_db)):
    user = await db.scalar(select(Base_User).where(Base_User.Email == payload.email))
    # Sempre retorna sucesso para não revelar se o email existe
    if user and user.Status == UserStatus.ACTIVE:
        code = _generate_code()
        _reset_codes[payload.email.lower()] = (code, datetime.utcnow() + timedelta(minutes=15))
        try:
            await _send_reset_email(payload.email, code)
        except Exception as e:
            import traceback
            print(f"[EMAIL ERROR] {e}")
            traceback.print_exc()
    return MessageResponse(message="Se o email existir na plataforma, receberás um código de recuperação.")


@router.post("/reset-password", response_model=MessageResponse)
async def reset_password(payload: ResetPasswordRequest, db: AsyncSession = Depends(get_db)):
    email_key = payload.email.lower()
    entry = _reset_codes.get(email_key)
    if not entry:
        raise HTTPException(status_code=status.HTTP_400_BAD_REQUEST, detail="Não existe pedido de recuperação pendente para este email")

    code, expires_at = entry
    if datetime.utcnow() > expires_at:
        del _reset_codes[email_key]
        raise HTTPException(status_code=status.HTTP_400_BAD_REQUEST, detail="Código de recuperação expirado")

    if payload.code != code:
        raise HTTPException(status_code=status.HTTP_400_BAD_REQUEST, detail="Código de recuperação inválido")

    user = await db.scalar(select(Base_User).where(Base_User.Email == payload.email))
    if not user:
        raise HTTPException(status_code=status.HTTP_404_NOT_FOUND, detail="Utilizador não encontrado")

    user.Password_Hash = hash_password(payload.new_password)
    del _reset_codes[email_key]
    return MessageResponse(message="Password alterada com sucesso")


@router.get("/me", response_model=UserResponse)
async def me(current_user: Base_User = Depends(get_current_user)):
    return to_user_response(current_user)
