import asyncio
import os
import sys
from contextlib import asynccontextmanager
from fastapi import FastAPI
from fastapi.middleware.cors import CORSMiddleware
from sqlalchemy import text

from app.database import engine, settings
from app.routers import admin, ai_tutor, auth, professors, students, learning_paths, learning_paths_student
from app.routers import quiz_professor, quiz_student, quiz_ws
from app.quiz_manager import quiz_manager

AI_ENGINE_PATH = os.path.abspath(
    os.path.join(os.path.dirname(__file__), '..', '..', '..', 'ai_engine')
)
if AI_ENGINE_PATH not in sys.path:
    sys.path.insert(0, AI_ENGINE_PATH)


def parse_cors_origins(raw_value: str) -> list[str]:
    origins = [origin.strip() for origin in raw_value.split(",") if origin.strip()]
    if origins:
        return origins
    return [
        "http://localhost:5173",
        "http://127.0.0.1:5173",
        "http://localhost:5174",
        "http://127.0.0.1:5174",
    ]


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
                raise RuntimeError(
                    f"Falha crítica: impossível ligar à BD após {max_retries} tentativas."
                ) from e
            await asyncio.sleep(base_delay ** attempt)

    try:
        from QuestionGeneratorTeacher import QuestionGeneratorTeacher  # type: ignore
        from ImportFiles import PDFIndexer                              # type: ignore
        import torch
        from langchain_huggingface import HuggingFaceEmbeddings


        shared_embeddings = HuggingFaceEmbeddings(
            model_name="google/embeddinggemma-300m",
            model_kwargs={
                "device": "cuda",
                "trust_remote_code": True,
                "model_kwargs": {"torch_dtype": torch.float32}
            },
            encode_kwargs={"normalize_embeddings": True}
        )


        app.state.question_generator = QuestionGeneratorTeacher(
            device="cuda",
            db_path=os.path.join(AI_ENGINE_PATH, "chroma_db"),
            embeddings=shared_embeddings,
        )
        app.state.pdf_indexer = PDFIndexer(
            device="cuda",
            upload_dir=os.path.join(AI_ENGINE_PATH, "uploads"),
            embeddings=shared_embeddings,
        )
        app.state.ai_engine_path = AI_ENGINE_PATH

        try:
            from chatbot import Chatbot  # type: ignore
            app.state.chatbot = Chatbot(
                db_path=os.path.join(AI_ENGINE_PATH, "chroma_db"),
                device="cuda",
                embeddings=shared_embeddings,
            )
        except Exception as ce:
            app.state.chatbot = None
            print(f"⚠️ Chatbot não disponível: {ce}")

    except Exception as e:  
        app.state.question_generator = None
        app.state.pdf_indexer = None
        app.state.chatbot = None
        app.state.ai_engine_path = AI_ENGINE_PATH
        print(f"⚠️ AI Engine não disponível: {e}")

    app.state.quiz_manager = quiz_manager

    yield

    await engine.dispose()


app = FastAPI(lifespan=lifespan)

app.add_middleware(
    CORSMiddleware,
    allow_origins=parse_cors_origins(settings.CORS_ALLOW_ORIGINS),
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)

app.include_router(auth.router)
app.include_router(admin.router)
app.include_router(professors.router)
app.include_router(students.router)
app.include_router(ai_tutor.router)
app.include_router(learning_paths.router)
app.include_router(learning_paths_student.router)
app.include_router(quiz_professor.router)
app.include_router(quiz_student.router)
app.include_router(quiz_ws.router)


@app.get("/")
async def root():
    return {"message": "API is running"}


@app.get("/health")
async def health():
    return {"status": "ok"}