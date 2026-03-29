from datetime import datetime

from fastapi import APIRouter, Depends, HTTPException, Query, status
from sqlalchemy import select
from sqlalchemy.ext.asyncio import AsyncSession

from app.database import get_db
from app.models import Base_User, Exercise, Progress, Streak, Student
from app.routers.deps import require_roles
from app.schemas.academic import ExerciseResponse
from app.schemas.gamification import (
	ProgressCreateRequest,
	ProgressResponse,
	StreakResponse,
	StudentProfileResponse,
)

router = APIRouter(prefix="/api/v1/students", tags=["students"])


def to_exercise_response(item: Exercise) -> ExerciseResponse:
	return ExerciseResponse(
		id_exercise=item.ID_Exercise,
		id_uc=item.ID_UC,
		topic_name=item.Topic_Name,
		material_ref=item.Material_Ref,
		type=item.Type,
		question=item.Question,
		solution=item.Solution,
		difficulty=item.Difficulty,
		explanation=item.Explanation,
	)


def to_progress_response(item: Progress) -> ProgressResponse:
	return ProgressResponse(
		id_progress=item.ID_Progress,
		id_student=item.ID_Student,
		id_exercise=item.ID_Exercise,
		attempts=item.Attempts,
		status=item.Status,
		xp_earned=item.XP_Earned,
		sync_status=item.Sync_Status,
		recorded_at=item.Record_Date,
	)


def to_streak_response(item: Streak) -> StreakResponse:
	return StreakResponse(
		id_streak=item.ID_Streak,
		id_student=item.ID_Student,
		log_date=item.Log_Date,
		sync_status=item.Sync_Status,
	)


@router.get("/me", response_model=StudentProfileResponse)
async def my_profile(
	db: AsyncSession = Depends(get_db),
	current_student: Base_User = Depends(require_roles("Student")),
):
	student = await db.scalar(select(Student).where(Student.ID_Student == current_student.ID_User))
	if not student:
		raise HTTPException(status_code=status.HTTP_404_NOT_FOUND, detail="Student profile not found")

	return StudentProfileResponse(
		id_student=student.ID_Student,
		current_level=student.Current_Level,
		total_xp=student.Total_XP,
		streak_days=student.Streak_Days,
		last_access=student.Last_Access,
	)


@router.get("/exercises", response_model=list[ExerciseResponse])
async def list_exercises(
	id_uc: int | None = Query(default=None),
	topic_name: str | None = Query(default=None),
	difficulty: str | None = Query(default=None),
	type_filter: str | None = Query(default=None, alias="type"),
	limit: int = Query(default=100, ge=1, le=500),
	offset: int = Query(default=0, ge=0),
	db: AsyncSession = Depends(get_db),
	current_student: Base_User = Depends(require_roles("Student")),
):
	stmt = select(Exercise)
	if id_uc is not None:
		stmt = stmt.where(Exercise.ID_UC == id_uc)
	if topic_name is not None:
		stmt = stmt.where(Exercise.Topic_Name == topic_name)
	if difficulty is not None:
		stmt = stmt.where(Exercise.Difficulty == difficulty)
	if type_filter is not None:
		stmt = stmt.where(Exercise.Type == type_filter)

	stmt = stmt.order_by(Exercise.ID_Exercise.desc()).offset(offset).limit(limit)
	items = (await db.scalars(stmt)).all()
	return [to_exercise_response(item) for item in items]


@router.post("/progress", response_model=ProgressResponse, status_code=status.HTTP_201_CREATED)
async def create_progress(
	payload: ProgressCreateRequest,
	db: AsyncSession = Depends(get_db),
	current_student: Base_User = Depends(require_roles("Student")),
):
	exercise = await db.scalar(select(Exercise).where(Exercise.ID_Exercise == payload.id_exercise))
	if not exercise:
		raise HTTPException(status_code=status.HTTP_404_NOT_FOUND, detail="Exercise not found")

	item = Progress(
		ID_Student=current_student.ID_User,
		ID_Exercise=payload.id_exercise,
		Attempts=payload.attempts,
		Status=payload.status,
		XP_Earned=payload.xp_earned,
		Sync_Status=payload.sync_status,
	)
	db.add(item)

	student = await db.scalar(select(Student).where(Student.ID_Student == current_student.ID_User))
	if student:
		student.Total_XP += payload.xp_earned
		student.Last_Access = datetime.now()

	await db.flush()
	return to_progress_response(item)


@router.get("/streak", response_model=list[StreakResponse])
async def get_streak(
	limit: int = Query(default=30, ge=1, le=365),
	db: AsyncSession = Depends(get_db),
	current_student: Base_User = Depends(require_roles("Student")),
):
	stmt = (
		select(Streak)
		.where(Streak.ID_Student == current_student.ID_User)
		.order_by(Streak.Log_Date.desc())
		.limit(limit)
	)
	items = (await db.scalars(stmt)).all()
	return [to_streak_response(item) for item in items]