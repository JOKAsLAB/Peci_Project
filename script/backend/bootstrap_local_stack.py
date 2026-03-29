import asyncio
import os
import sys
from pathlib import Path

from sqlalchemy import insert, select, update

REPO_ROOT = Path(__file__).resolve().parents[2]
BACKEND_ROOT = REPO_ROOT / "backend" / "backend"
if str(BACKEND_ROOT) not in sys.path:
    sys.path.insert(0, str(BACKEND_ROOT))

from app.database import AsyncSessionLocal, Base, engine
import app.models  # noqa: F401
from app.models import Admin, Base_User
from app.models.enums import UserRole, UserStatus
from app.security import hash_password


DEFAULT_ADMIN_EMAIL = "admin@ua.pt"
LEGACY_ADMIN_EMAIL = "admin@peci.local"
DEFAULT_ADMIN_PASSWORD = "admin123"
DEFAULT_ADMIN_NAME = "Admin Local"


def _env_or_default(var_name: str, default: str) -> str:
    value = os.getenv(var_name)
    if value is None:
        return default
    stripped = value.strip()
    return stripped if stripped else default


def _truthy(value: str | None) -> bool:
    if value is None:
        return False
    return value.strip().lower() in {"1", "true", "yes", "on"}


async def ensure_schema() -> None:
    async with engine.begin() as conn:
        await conn.run_sync(Base.metadata.create_all)


async def ensure_admin() -> tuple[str, str, bool, bool]:
    admin_email = _env_or_default("PECI_ADMIN_EMAIL", DEFAULT_ADMIN_EMAIL)
    admin_password = _env_or_default("PECI_ADMIN_PASSWORD", DEFAULT_ADMIN_PASSWORD)
    admin_name = _env_or_default("PECI_ADMIN_NAME", DEFAULT_ADMIN_NAME)
    reset_password = _truthy(os.getenv("PECI_ADMIN_RESET_PASSWORD"))

    created_now = False

    async with AsyncSessionLocal() as db:
        user = await db.scalar(select(Base_User).where(Base_User.Email == admin_email))

        # Keep backward compatibility with old local bootstrap email format.
        if user is None and admin_email != LEGACY_ADMIN_EMAIL:
            legacy_user = await db.scalar(select(Base_User).where(Base_User.Email == LEGACY_ADMIN_EMAIL))
            if legacy_user is not None:
                legacy_user.Email = admin_email
                user = legacy_user

        if user is None:
            # Joined-table inheritance: criar diretamente Admin evita flush incompatível
            # com identidade polimórfica e garante preenchimento da base_user.
            user = Admin(
                Name=admin_name,
                Email=admin_email,
                Password_Hash=hash_password(admin_password),
                Role=UserRole.ADMIN,
                Status=UserStatus.ACTIVE,
                Privilege_Level=3,
                Contact=admin_email,
            )
            db.add(user)
            await db.flush()
            created_now = True
        else:
            if user.Role != UserRole.ADMIN:
                user.Role = UserRole.ADMIN
            if user.Status != UserStatus.ACTIVE:
                user.Status = UserStatus.ACTIVE
            if not user.Name:
                user.Name = admin_name
            if reset_password:
                user.Password_Hash = hash_password(admin_password)

            admin_id = await db.scalar(
                select(Admin.__table__.c.ID_Admin).where(Admin.__table__.c.ID_Admin == user.ID_User)
            )

            if admin_id is None:
                # Inserção direta na tabela admin para não disparar novo INSERT em base_user.
                await db.execute(
                    insert(Admin.__table__).values(
                        ID_Admin=user.ID_User,
                        Privilege_Level=3,
                        Contact=admin_email,
                    )
                )
            else:
                await db.execute(
                    update(Admin.__table__)
                    .where(Admin.__table__.c.ID_Admin == user.ID_User)
                    .values(
                        Privilege_Level=3,
                        Contact=admin_email,
                    )
                )

        await db.commit()

    return admin_email, admin_password, created_now, reset_password


async def main() -> None:
    await ensure_schema()
    admin_email, admin_password, created_now, reset_password = await ensure_admin()

    print("[SISTEMA] Bootstrap local da BD concluido (create_all).")
    if created_now:
        print("[SISTEMA] Conta admin local criada para o painel web.")
    elif reset_password:
        print("[SISTEMA] Password da conta admin local foi atualizada por pedido.")
    else:
        print("[SISTEMA] Conta admin local ja existia (sem alterar password).")

    print(f"[SISTEMA] Admin email: {admin_email}")
    print(f"[SISTEMA] Admin password: {admin_password}")
    print("[SISTEMA] Dica: define PECI_ADMIN_EMAIL/PECI_ADMIN_PASSWORD para personalizar.")


if __name__ == "__main__":
    asyncio.run(main())
