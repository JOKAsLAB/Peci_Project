import asyncio
import sys
from pathlib import Path

from sqlalchemy import text

REPO_ROOT = Path(__file__).resolve().parents[2]
BACKEND_ROOT = REPO_ROOT / "backend" / "backend"
if str(BACKEND_ROOT) not in sys.path:
    sys.path.insert(0, str(BACKEND_ROOT))

from app.database import Base, engine
import app.models  # noqa: F401


async def reset_db_from_models() -> None:
    async with engine.begin() as conn:
        # Local-only reset used for smoke/integration testing.
        await conn.execute(text("DROP SCHEMA IF EXISTS public CASCADE"))
        await conn.execute(text("CREATE SCHEMA public"))
        await conn.execute(text("GRANT ALL ON SCHEMA public TO peci_user"))
        await conn.run_sync(Base.metadata.create_all)


if __name__ == "__main__":
    asyncio.run(reset_db_from_models())
