import asyncio

from fastapi import APIRouter, Depends, HTTPException, Request, status
from pydantic import BaseModel, Field

from app.models import Base_User
from app.routers.deps import get_current_user

router = APIRouter(prefix="/api/v1/ai-tutor", tags=["ai-tutor"])


class AITutorQueryRequest(BaseModel):
	question: str = Field(min_length=3)
	course_unit_id: int | None = None
	exercise_id: str | None = None


class AITutorQueryResponse(BaseModel):
	answer: str
	references: list[str]


@router.post("/query", response_model=AITutorQueryResponse)
async def query_ai_tutor(
	payload: AITutorQueryRequest,
	request: Request,
	current_user: Base_User = Depends(get_current_user),
):
	chatbot = getattr(request.app.state, "chatbot", None)
	if chatbot is None:
		raise HTTPException(
			status_code=status.HTTP_503_SERVICE_UNAVAILABLE,
			detail="Tutor IA não disponível de momento.",
		)

	try:
		loop = asyncio.get_event_loop()
		answer, references = await loop.run_in_executor(
			None, chatbot.responder_pergunta, payload.question
		)
	except Exception as e:
		raise HTTPException(
			status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
			detail=f"Erro no Tutor IA: {str(e)}",
		)

	return AITutorQueryResponse(answer=answer, references=references)
