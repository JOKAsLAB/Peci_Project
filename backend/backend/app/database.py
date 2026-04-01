# =============================================================
# PECI PROJECT — Database Connection
# 
# O que este ficheiro faz:
# 1. Lê as credenciais do ficheiro .env
# 2. Constrói a URL de ligação ao PostgreSQL
# 3. Cria a engine assíncrona (asyncpg)
# 4. Cria a sessão que os routers vão usar para fazer queries
# 5. Cria a Base declarativa que os models vão herdar
# =============================================================

import os
from dotenv import load_dotenv
from pydantic_settings import BaseSettings, SettingsConfigDict
from sqlalchemy.ext.asyncio import AsyncSession, create_async_engine, async_sessionmaker
from sqlalchemy.orm import declarative_base

# Carrega o .env
load_dotenv(dotenv_path=os.path.join(os.path.dirname(__file__), ".env"))

# -------------------------------------------------------------
# Leitura das variáveis de ambiente do ficheiro .env
# -------------------------------------------------------------
class Settings(BaseSettings):
    DB_USER: str
    DB_PASSWORD: str
    DB_HOST: str
    DB_PORT: int
    DB_NAME: str

    # JWT
    SECRET_KEY: str
    ALGORITHM: str
    ACCESS_TOKEN_EXPIRE_MINUTES: int

    # Auth cookie
    AUTH_COOKIE_NAME: str = "peci_access_token"
    AUTH_COOKIE_SECURE: bool = False
    AUTH_COOKIE_SAMESITE: str = "lax"
    AUTH_COOKIE_DOMAIN: str | None = None
    AUTH_COOKIE_PATH: str = "/"

    # CORS
    CORS_ALLOW_ORIGINS: str = (
        "http://localhost:5173,"
        "http://127.0.0.1:5173,"
        "http://localhost:5174,"
        "http://127.0.0.1:5174"
    )

    model_config = SettingsConfigDict(
        env_file=".env",
        env_file_encoding="utf-8",
        extra="ignore"
    )

settings = Settings()

# -------------------------------------------------------------
# URL de ligação ao PostgreSQL
# Formato: postgresql+asyncpg://user:password@host:port/database
# -------------------------------------------------------------
DATABASE_URL = f"postgresql+asyncpg://{settings.DB_USER}:{settings.DB_PASSWORD}@{settings.DB_HOST}:{settings.DB_PORT}/{settings.DB_NAME}"

# -------------------------------------------------------------
# Engine assíncrona
# echo=False maximiza o throughput em produção.
# Configuração rigorosa de pooling e validação de conexões (pre-ping)
# para prevenir o esgotamento de sockets e mitigar falhas de I/O.
# -------------------------------------------------------------
engine = create_async_engine(
    DATABASE_URL,
    echo=False,
    pool_size=20,
    max_overflow=10,
    pool_timeout=30,
    pool_pre_ping=True
)

# -------------------------------------------------------------
# Sessão assíncrona
# É através da sessão que os routers fazem SELECT, INSERT, etc.
# expire_on_commit=False evita erros ao aceder a dados após commit.
# Utilização obrigatória da factory assíncrona nativa (async_sessionmaker).
# -------------------------------------------------------------
AsyncSessionLocal = async_sessionmaker(
    bind=engine,
    class_=AsyncSession,
    expire_on_commit=False,
    autocommit=False,
    autoflush=False
)

# -------------------------------------------------------------
# Base declarativa
# Todos os models SQLAlchemy vão herdar desta classe.
# Exemplo: class Base_User(Base): ...
# -------------------------------------------------------------
Base = declarative_base()

# -------------------------------------------------------------
# Dependência de sessão — usada pelos routers do FastAPI
# O FastAPI injeta esta função automaticamente em cada endpoint
# que precisar de aceder à base de dados.
#
# Exemplo de uso num router:
#   async def get_user(db: AsyncSession = Depends(get_db)):
#       ...
# -------------------------------------------------------------
async def get_db():
    async with AsyncSessionLocal() as session:
        try:
            yield session
            await session.commit()
        except Exception:
            await session.rollback()
            raise