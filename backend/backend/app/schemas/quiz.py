from datetime import datetime
from typing import Any
from uuid import UUID

from pydantic import BaseModel, Field

from app.models.enums import QuizSessionStatus


class QuizCreateRequest(BaseModel):
    id_uc: int
    title: str = Field(min_length=2, max_length=200)
    exercise_ids: list[UUID] = Field(min_length=1, max_length=50)


class QuizUpdateRequest(BaseModel):
    title: str | None = Field(default=None, min_length=2, max_length=200)
    exercise_ids: list[UUID] | None = None


class QuizExerciseSummary(BaseModel):
    id_exercise: UUID
    question_order: int
    question: str
    type: str
    difficulty: str

    class Config:
        from_attributes = True


class QuizResponse(BaseModel):
    id_quiz: UUID
    id_professor: UUID
    id_uc: int
    title: str
    created_at: datetime
    exercise_count: int = 0

    class Config:
        from_attributes = True


class QuizDetailResponse(QuizResponse):
    exercises: list[QuizExerciseSummary] = Field(default_factory=list)


class SessionCreateResponse(BaseModel):
    id_session: UUID
    room_code: str
    status: QuizSessionStatus
    quiz_title: str
    created_at: datetime

    class Config:
        from_attributes = True


class ParticipantInfo(BaseModel):
    student_id: UUID
    student_name: str
    score: int


class SessionStateResponse(BaseModel):
    id_session: UUID
    room_code: str
    status: QuizSessionStatus
    current_question_index: int
    quiz_title: str
    total_questions: int
    participant_count: int
    participants: list[ParticipantInfo] = Field(default_factory=list)
    started_at: datetime | None = None
    finished_at: datetime | None = None

    class Config:
        from_attributes = True


class JoinSessionResponse(BaseModel):
    id_session: UUID
    room_code: str
    quiz_title: str
    status: QuizSessionStatus
    current_question_index: int
    total_questions: int


class QuestionForStudent(BaseModel):
    index: int
    total: int
    question: str
    type: str
    options: list[str] | None = None
    time_limit_seconds: int = 30


class SubmitAnswerRequest(BaseModel):
    answer: Any
    time_taken_ms: int = Field(ge=0)


class SubmitAnswerResponse(BaseModel):
    is_correct: bool
    points_earned: int
    total_score: int
    correct_answer: Any


class LeaderboardEntry(BaseModel):
    rank: int
    student_id: UUID
    student_name: str
    score: int


class LeaderboardResponse(BaseModel):
    entries: list[LeaderboardEntry] = Field(default_factory=list)
