from fastapi import APIRouter, Depends, Query
from sqlalchemy import select
from sqlalchemy.ext.asyncio import AsyncSession

from app.database import get_db
from app.models import Base_User, Course_Unit, Exercise
from app.routers.deps import get_current_user
from app.schemas.academic import CourseUnitResponse, ExerciseResponse

router = APIRouter(prefix="/api/v1/academic", tags=["academic"])


def to_course_response(course: Course_Unit) -> CourseUnitResponse:
    return CourseUnitResponse(
        id_uc=course.ID_UC,
        name=course.Name,
        semester=course.Semester,
        curricular_year=course.Curricular_Year,
    )


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


@router.get("/course-units", response_model=list[CourseUnitResponse])
async def list_course_units(
    db: AsyncSession = Depends(get_db),
    current_user: Base_User = Depends(get_current_user),
):
    items = (await db.scalars(select(Course_Unit).order_by(Course_Unit.Name.asc()))).all()
    return [to_course_response(item) for item in items]


@router.get("/exercises", response_model=list[ExerciseResponse])
async def list_exercises(
    id_uc: int | None = Query(default=None),
    topic_name: str | None = Query(default=None),
    difficulty: str | None = Query(default=None),
    type_filter: str | None = Query(default=None, alias="type"),
    limit: int = Query(default=100, ge=1, le=500),
    offset: int = Query(default=0, ge=0),
    db: AsyncSession = Depends(get_db),
    current_user: Base_User = Depends(get_current_user),
):
    stmt = select(Exercise)
    # Filter set mirrors the web/mobile feed controls
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
