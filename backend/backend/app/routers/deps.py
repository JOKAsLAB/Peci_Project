from uuid import UUID

from fastapi import Depends, HTTPException, status
from fastapi.security import OAuth2PasswordBearer
from sqlalchemy import select
from sqlalchemy.ext.asyncio import AsyncSession

from app.database import get_db
from app.models import Base_User
from app.security import decode_access_token

oauth2_scheme = OAuth2PasswordBearer(tokenUrl="/api/v1/auth/login")


async def get_current_user(
    token: str = Depends(oauth2_scheme),
    db: AsyncSession = Depends(get_db),
) -> Base_User:
    credentials_error = HTTPException(
        status_code=status.HTTP_401_UNAUTHORIZED,
        detail="Could not validate credentials",
        headers={"WWW-Authenticate": "Bearer"},
    )

    try:
        payload = decode_access_token(token)
        user_id = payload.get("sub")
        if not user_id:
            raise credentials_error
        parsed_user_id = UUID(user_id)
    except (ValueError, TypeError):
        raise credentials_error

    user = await db.scalar(select(Base_User).where(Base_User.ID_User == parsed_user_id))
    if not user:
        raise credentials_error

    if user.Status != "Active":
        raise HTTPException(status_code=status.HTTP_403_FORBIDDEN, detail="User is not active")

    return user


def require_roles(*roles: str):
    async def role_checker(current_user: Base_User = Depends(get_current_user)) -> Base_User:
        if current_user.Role not in roles:
            raise HTTPException(status_code=status.HTTP_403_FORBIDDEN, detail="Insufficient permissions")
        return current_user

    return role_checker
