import random
import string
from uuid import UUID

from fastapi import APIRouter, Depends, HTTPException, status
from sqlalchemy import and_, delete, select
from sqlalchemy.ext.asyncio import AsyncSession
from sqlalchemy.orm import selectinload

from app.database import get_db
from app.models import Base_User, Exercise, Professor_UC, Quiz, Quiz_Exercise, Quiz_Participant, Quiz_Session
from app.models.enums import QuizSessionStatus
from app.routers.deps import require_roles
from app.schemas.quiz import (
    LeaderboardEntry,
    LeaderboardResponse,
    ParticipantInfo,
    QuizCreateRequest,
    QuizDetailResponse,
    QuizExerciseSummary,
    QuizResponse,
    QuizUpdateRequest,
    SessionCreateResponse,
    SessionStateResponse,
)

router = APIRouter(prefix="/api/v1/professors/quizzes", tags=["professors-quizzes"])


def _generate_room_code(length: int = 6) -> str:
    return "".join(random.choices(string.ascii_uppercase + string.digits, k=length))


def _to_quiz_response(quiz: Quiz) -> QuizResponse:
    return QuizResponse(
        id_quiz=quiz.ID_Quiz,
        id_professor=quiz.ID_Professor,
        id_uc=quiz.ID_UC,
        title=quiz.Title,
        created_at=quiz.Created_At,
        exercise_count=len(quiz.quiz_exercises),
    )


def _to_quiz_detail(quiz: Quiz) -> QuizDetailResponse:
    exercises = [
        QuizExerciseSummary(
            id_exercise=qe.ID_Exercise,
            question_order=qe.Question_Order,
            question=qe.exercise.Question,
            type=qe.exercise.Type.value,
            difficulty=qe.exercise.Difficulty.value,
        )
        for qe in quiz.quiz_exercises
    ]
    return QuizDetailResponse(
        id_quiz=quiz.ID_Quiz,
        id_professor=quiz.ID_Professor,
        id_uc=quiz.ID_UC,
        title=quiz.Title,
        created_at=quiz.Created_At,
        exercise_count=len(exercises),
        exercises=exercises,
    )


# =============================================================
# Quiz CRUD
# =============================================================

@router.get("", response_model=list[QuizResponse])
async def list_my_quizzes(
    db: AsyncSession = Depends(get_db),
    current_professor: Base_User = Depends(require_roles("Professor")),
):
    stmt = (
        select(Quiz)
        .options(selectinload(Quiz.quiz_exercises))
        .where(Quiz.ID_Professor == current_professor.ID_User)
        .order_by(Quiz.Created_At.desc())
    )
    quizzes = (await db.scalars(stmt)).all()
    return [_to_quiz_response(q) for q in quizzes]


@router.post("", response_model=QuizDetailResponse, status_code=status.HTTP_201_CREATED)
async def create_quiz(
    payload: QuizCreateRequest,
    db: AsyncSession = Depends(get_db),
    current_professor: Base_User = Depends(require_roles("Professor")),
):
    has_access = await db.scalar(
        select(Professor_UC).where(
            and_(
                Professor_UC.ID_Professor == current_professor.ID_User,
                Professor_UC.ID_UC == payload.id_uc,
            )
        )
    )
    if not has_access:
        raise HTTPException(status_code=status.HTTP_403_FORBIDDEN, detail="Não está associado a esta unidade curricular")

    # Validate all exercises belong to this UC and are published
    exercises = (
        await db.scalars(
            select(Exercise).where(
                and_(
                    Exercise.ID_Exercise.in_(payload.exercise_ids),
                    Exercise.ID_UC == payload.id_uc,
                    Exercise.Published == True,
                )
            )
        )
    ).all()

    found_ids = {e.ID_Exercise for e in exercises}
    missing = [str(eid) for eid in payload.exercise_ids if eid not in found_ids]
    if missing:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail=f"Exercises not found or not published in this UC: {missing}",
        )

    quiz = Quiz(
        ID_Professor=current_professor.ID_User,
        ID_UC=payload.id_uc,
        Title=payload.title,
    )
    db.add(quiz)
    await db.flush()

    for order, ex_id in enumerate(payload.exercise_ids):
        db.add(Quiz_Exercise(ID_Quiz=quiz.ID_Quiz, ID_Exercise=ex_id, Question_Order=order))

    await db.flush()

    stmt = (
        select(Quiz)
        .options(selectinload(Quiz.quiz_exercises).selectinload(Quiz_Exercise.exercise))
        .where(Quiz.ID_Quiz == quiz.ID_Quiz)
    )
    quiz = await db.scalar(stmt)
    await db.commit()
    return _to_quiz_detail(quiz)


@router.get("/{quiz_id}", response_model=QuizDetailResponse)
async def get_quiz(
    quiz_id: UUID,
    db: AsyncSession = Depends(get_db),
    current_professor: Base_User = Depends(require_roles("Professor")),
):
    stmt = (
        select(Quiz)
        .options(selectinload(Quiz.quiz_exercises).selectinload(Quiz_Exercise.exercise))
        .where(and_(Quiz.ID_Quiz == quiz_id, Quiz.ID_Professor == current_professor.ID_User))
    )
    quiz = await db.scalar(stmt)
    if not quiz:
        raise HTTPException(status_code=status.HTTP_404_NOT_FOUND, detail="Quiz não encontrado")
    return _to_quiz_detail(quiz)


@router.patch("/{quiz_id}", response_model=QuizDetailResponse)
async def update_quiz(
    quiz_id: UUID,
    payload: QuizUpdateRequest,
    db: AsyncSession = Depends(get_db),
    current_professor: Base_User = Depends(require_roles("Professor")),
):
    quiz = await db.scalar(
        select(Quiz).where(and_(Quiz.ID_Quiz == quiz_id, Quiz.ID_Professor == current_professor.ID_User))
    )
    if not quiz:
        raise HTTPException(status_code=status.HTTP_404_NOT_FOUND, detail="Quiz não encontrado")

    if payload.title is not None:
        quiz.Title = payload.title

    if payload.exercise_ids is not None:
        exercises = (
            await db.scalars(
                select(Exercise).where(
                    and_(
                        Exercise.ID_Exercise.in_(payload.exercise_ids),
                        Exercise.ID_UC == quiz.ID_UC,
                        Exercise.Published == True,
                    )
                )
            )
        ).all()
        found_ids = {e.ID_Exercise for e in exercises}
        missing = [str(eid) for eid in payload.exercise_ids if eid not in found_ids]
        if missing:
            raise HTTPException(
                status_code=status.HTTP_404_NOT_FOUND,
                detail=f"Exercises not found or not published in this UC: {missing}",
            )
        await db.execute(delete(Quiz_Exercise).where(Quiz_Exercise.ID_Quiz == quiz_id))
        for order, ex_id in enumerate(payload.exercise_ids):
            db.add(Quiz_Exercise(ID_Quiz=quiz_id, ID_Exercise=ex_id, Question_Order=order))

    await db.flush()

    stmt = (
        select(Quiz)
        .options(selectinload(Quiz.quiz_exercises).selectinload(Quiz_Exercise.exercise))
        .where(Quiz.ID_Quiz == quiz_id)
    )
    quiz = await db.scalar(stmt)
    await db.commit()
    return _to_quiz_detail(quiz)


@router.delete("/{quiz_id}", status_code=status.HTTP_204_NO_CONTENT)
async def delete_quiz(
    quiz_id: UUID,
    db: AsyncSession = Depends(get_db),
    current_professor: Base_User = Depends(require_roles("Professor")),
):
    quiz = await db.scalar(
        select(Quiz).where(and_(Quiz.ID_Quiz == quiz_id, Quiz.ID_Professor == current_professor.ID_User))
    )
    if not quiz:
        raise HTTPException(status_code=status.HTTP_404_NOT_FOUND, detail="Quiz não encontrado")
    await db.execute(delete(Quiz).where(Quiz.ID_Quiz == quiz_id))
    await db.commit()


# =============================================================
# Session management
# =============================================================

@router.post("/{quiz_id}/sessions", response_model=SessionCreateResponse, status_code=status.HTTP_201_CREATED)
async def open_session(
    quiz_id: UUID,
    db: AsyncSession = Depends(get_db),
    current_professor: Base_User = Depends(require_roles("Professor")),
):
    quiz = await db.scalar(
        select(Quiz)
        .options(selectinload(Quiz.quiz_exercises))
        .where(and_(Quiz.ID_Quiz == quiz_id, Quiz.ID_Professor == current_professor.ID_User))
    )
    if not quiz:
        raise HTTPException(status_code=status.HTTP_404_NOT_FOUND, detail="Quiz não encontrado")
    if not quiz.quiz_exercises:
        raise HTTPException(status_code=status.HTTP_400_BAD_REQUEST, detail="O quiz não tem exercícios")

    # Generate unique room code
    for _ in range(10):
        code = _generate_room_code()
        exists = await db.scalar(
            select(Quiz_Session).where(
                and_(Quiz_Session.Room_Code == code, Quiz_Session.Status != QuizSessionStatus.FINISHED)
            )
        )
        if not exists:
            break
    else:
        raise HTTPException(status_code=status.HTTP_503_SERVICE_UNAVAILABLE, detail="Não foi possível gerar um código de sala único")

    session = Quiz_Session(
        ID_Quiz=quiz_id,
        Room_Code=code,
        Status=QuizSessionStatus.WAITING,
        Current_Question_Index=0,
    )
    db.add(session)
    await db.flush()
    await db.commit()

    return SessionCreateResponse(
        id_session=session.ID_Session,
        room_code=session.Room_Code,
        status=session.Status,
        quiz_title=quiz.Title,
        created_at=session.Created_At,
    )


@router.get("/sessions/{session_id}", response_model=SessionStateResponse)
async def get_session_state(
    session_id: UUID,
    db: AsyncSession = Depends(get_db),
    current_professor: Base_User = Depends(require_roles("Professor")),
):
    stmt = (
        select(Quiz_Session)
        .options(
            selectinload(Quiz_Session.quiz).selectinload(Quiz.quiz_exercises),
            selectinload(Quiz_Session.participants).selectinload(Quiz_Participant.student),
        )
        .where(Quiz_Session.ID_Session == session_id)
    )
    session = await db.scalar(stmt)
    if not session:
        raise HTTPException(status_code=status.HTTP_404_NOT_FOUND, detail="Sessão não encontrada")
    if session.quiz.ID_Professor != current_professor.ID_User:
        raise HTTPException(status_code=status.HTTP_403_FORBIDDEN, detail="Esta sessão não é sua")

    participants = [
        ParticipantInfo(
            student_id=p.ID_Student,
            student_name=p.student.Name,
            score=p.Score,
        )
        for p in sorted(session.participants, key=lambda p: p.Score, reverse=True)
    ]

    return SessionStateResponse(
        id_session=session.ID_Session,
        room_code=session.Room_Code,
        status=session.Status,
        current_question_index=session.Current_Question_Index,
        quiz_title=session.quiz.Title,
        total_questions=len(session.quiz.quiz_exercises),
        participant_count=len(session.participants),
        participants=participants,
        started_at=session.Started_At,
        finished_at=session.Finished_At,
    )


@router.get("/sessions/{session_id}/leaderboard", response_model=LeaderboardResponse)
async def get_leaderboard(
    session_id: UUID,
    db: AsyncSession = Depends(get_db),
    current_professor: Base_User = Depends(require_roles("Professor")),
):
    stmt = (
        select(Quiz_Session)
        .options(
            selectinload(Quiz_Session.quiz),
            selectinload(Quiz_Session.participants).selectinload(Quiz_Participant.student),
        )
        .where(Quiz_Session.ID_Session == session_id)
    )
    session = await db.scalar(stmt)
    if not session:
        raise HTTPException(status_code=status.HTTP_404_NOT_FOUND, detail="Sessão não encontrada")
    if session.quiz.ID_Professor != current_professor.ID_User:
        raise HTTPException(status_code=status.HTTP_403_FORBIDDEN, detail="Esta sessão não é sua")

    sorted_participants = sorted(session.participants, key=lambda p: p.Score, reverse=True)
    entries = [
        LeaderboardEntry(
            rank=i + 1,
            student_id=p.ID_Student,
            student_name=p.student.Name,
            score=p.Score,
        )
        for i, p in enumerate(sorted_participants)
    ]
    return LeaderboardResponse(entries=entries)
