import asyncio
from contextlib import asynccontextmanager
from fastapi import FastAPI
from fastapi.middleware.cors import CORSMiddleware
from sqlalchemy import text

from app.database import engine
from app.routers import academic, admin, ai_tutor, auth, professors, students

# -------------------------------------------------------------
# Gestão do Ciclo de Vida (Lifespan) e Tolerância a Falhas
# Substitui o obsoleto @app.on_event("startup").
# Implementa Exponential Backoff para mitigar race conditions
# durante a orquestração via Docker Compose, prevenindo
# crash-loops se a base de dados demorar a aceitar ligações.
# -------------------------------------------------------------
@asynccontextmanager
async def lifespan(app: FastAPI):
    max_retries = 5
    base_delay = 2

    for attempt in range(1, max_retries + 1):
        try:
            async with engine.begin() as conn:
                await conn.execute(text("SELECT 1"))
            break
        except Exception as e:
            if attempt == max_retries:
                raise RuntimeError(f"Falha crítica: impossível estabelecer ligação à base de dados após {max_retries} tentativas.") from e
            delay = base_delay ** attempt
            await asyncio.sleep(delay)

    yield  # A aplicação processa requests a partir deste ponto

    # Limpeza determinística de recursos no encerramento
    await engine.dispose()


app = FastAPI(lifespan=lifespan)

# -------------------------------------------------------------
# Configuração CORS
# Permite as origens locais para os painéis professor e admin.
# -------------------------------------------------------------
app.add_middleware(
    CORSMiddleware,
    allow_origins=[
        "http://localhost:5173",
        "http://127.0.0.1:5173",
        "http://localhost:5174",
        "http://127.0.0.1:5174",
    ],
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)

# -------------------------------------------------------------
# Registo de Routers por Domínio
# -------------------------------------------------------------
app.include_router(auth.router)
app.include_router(admin.router)
app.include_router(professors.router)
app.include_router(students.router)
app.include_router(academic.router)
app.include_router(ai_tutor.router)

# -------------------------------------------------------------
# Endpoints de Health Check
# -------------------------------------------------------------
@app.get("/")
async def root():
    return {"message": "API is running"}

@app.get("/health")
async def health():
    return {"status": "ok"}