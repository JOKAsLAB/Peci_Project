from fastapi import APIRouter, Depends, HTTPException, status
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
	current_user: Base_User = Depends(get_current_user),
):
	raise HTTPException(
		status_code=status.HTTP_501_NOT_IMPLEMENTED,
		detail="AI tutor backend bridge is not implemented yet for this branch",
	)
