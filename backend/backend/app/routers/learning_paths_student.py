from collections import defaultdict
from fastapi import APIRouter, Depends
from pydantic import BaseModel
from sqlalchemy import and_, select, case
from sqlalchemy.ext.asyncio import AsyncSession
from typing import Optional
from uuid import UUID

from app.database import get_db
from app.models import (
    Base_User,
    Course_Unit,
    Exercise,
    Student_UC,
    Topic,
)
from app.routers.deps import require_roles


router = APIRouter(prefix="/api/v1/students/learning-paths", tags=["student-learning-paths"])


# =============================================================
# SCHEMAS
# =============================================================

class ExerciseInCheckpoint(BaseModel):
    id_exercise: UUID
    question: str
    type: str
    difficulty: str
    explanation: Optional[str] = None
    solution: dict
    published: bool

    class Config:
        from_attributes = True


class Checkpoint(BaseModel):
    topic_name: str
    topic_order: int
    exercises: list[ExerciseInCheckpoint]


class LearningPathResponse(BaseModel):
    id_uc: int
    name: str
    total_topics: int
    total_exercises: int
    checkpoints: list[Checkpoint]



DIFFICULTY_ORDER = case(
    (Exercise.Difficulty == "Easy", 1),
    (Exercise.Difficulty == "Medium", 2),
    (Exercise.Difficulty == "Hard", 3),
    else_=4,
)


async def _build_checkpoints(id_uc: int, db: AsyncSession) -> list[Checkpoint]:
    stmt = (
        select(Topic, Exercise)
        .outerjoin(
            Exercise,
            and_(
                Exercise.ID_UC == Topic.ID_UC,
                Exercise.Topic_Name == Topic.Name,
                Exercise.Published == True,
            ),
        )
        .where(Topic.ID_UC == id_uc)
        .order_by(Topic.N_Order.asc(), DIFFICULTY_ORDER)
    )
    rows = (await db.execute(stmt)).all()

    topic_order_map: dict[str, int] = {}
    topic_exercises: dict[str, list[ExerciseInCheckpoint]] = defaultdict(list)

    for topic, exercise in rows:
        if topic.Name not in topic_order_map:
            topic_order_map[topic.Name] = topic.N_Order
            topic_exercises[topic.Name]

        if exercise is not None:
            topic_exercises[topic.Name].append(
                ExerciseInCheckpoint(
                    id_exercise=exercise.ID_Exercise,
                    question=exercise.Question,
                    type=exercise.Type,
                    difficulty=exercise.Difficulty,
                    explanation=exercise.Explanation,
                    solution=exercise.Solution,
                    published=exercise.Published,
                )
            )

    return [
        Checkpoint(
            topic_name=name,
            topic_order=topic_order_map[name],
            exercises=topic_exercises[name],
        )
        for name in sorted(topic_order_map, key=lambda n: topic_order_map[n])
    ]



@router.get("", response_model=list[LearningPathResponse])
async def list_learning_paths(
    db: AsyncSession = Depends(get_db),
    current_student: Base_User = Depends(require_roles("Student")),
):
    stmt = (
        select(Course_Unit)
        .join(Student_UC, Student_UC.ID_UC == Course_Unit.ID_UC)
        .where(Student_UC.ID_Student == current_student.ID_User)
        .order_by(Course_Unit.Name.asc())
    )
    ucs = (await db.scalars(stmt)).all()

    result = []
    for uc in ucs:
        checkpoints = await _build_checkpoints(uc.ID_UC, db)
        result.append(
            LearningPathResponse(
                id_uc=uc.ID_UC,
                name=uc.Name,
                total_topics=len(checkpoints),
                total_exercises=sum(len(c.exercises) for c in checkpoints),
                checkpoints=checkpoints,
            )
        )

    return result