from uuid import UUID

from fastapi import APIRouter, Depends, HTTPException, Request, status
from sqlalchemy import and_, select
from sqlalchemy.ext.asyncio import AsyncSession
from sqlalchemy.orm import selectinload

from app.database import get_db
from app.models import Base_User, Quiz, Quiz_Answer, Quiz_Exercise, Quiz_Participant, Quiz_Session
from app.models.enums import QuizSessionStatus
from app.routers.deps import require_roles
from app.schemas.quiz import (
    JoinSessionResponse,
    LeaderboardEntry,
    LeaderboardResponse,
    QuestionForStudent,
    SubmitAnswerRequest,
    SubmitAnswerResponse,
)

router = APIRouter(prefix="/api/v1/students/quizzes", tags=["students-quizzes"])

_TIME_LIMIT_SECONDS = 30
_BASE_SCORE = 1000
_SPEED_BONUS = 500


def _calculate_points(is_correct: bool, time_taken_ms: int) -> int:
    if not is_correct:
        return 0
    speed_ratio = max(0.0, 1.0 - time_taken_ms / (_TIME_LIMIT_SECONDS * 1000))
    return _BASE_SCORE + round(_SPEED_BONUS * speed_ratio)


@router.post("/join/{room_code}", response_model=JoinSessionResponse)
async def join_session(
    room_code: str,
    request: Request,
    db: AsyncSession = Depends(get_db),
    current_student: Base_User = Depends(require_roles("Student")),
):
    stmt = (
        select(Quiz_Session)
        .options(selectinload(Quiz_Session.quiz).selectinload(Quiz.quiz_exercises))
        .where(Quiz_Session.Room_Code == room_code.upper())
    )
    session = await db.scalar(stmt)
    if not session:
        raise HTTPException(status_code=status.HTTP_404_NOT_FOUND, detail="Room not found")
    if session.Status == QuizSessionStatus.FINISHED:
        raise HTTPException(status_code=status.HTTP_410_GONE, detail="Session has already ended")

    # Idempotent: re-joining is fine
    existing = await db.scalar(
        select(Quiz_Participant).where(
            and_(
                Quiz_Participant.ID_Session == session.ID_Session,
                Quiz_Participant.ID_Student == current_student.ID_User,
            )
        )
    )
    if not existing:
        participant = Quiz_Participant(
            ID_Session=session.ID_Session,
            ID_Student=current_student.ID_User,
            Score=0,
        )
        db.add(participant)
        await db.flush()
        await db.commit()

        # Notify professor via WebSocket
        quiz_manager = request.app.state.quiz_manager
        await quiz_manager.send_to_professor(
            str(session.ID_Session),
            {
                "type": "joined",
                "student_id": str(current_student.ID_User),
                "student_name": current_student.Name,
                "count": quiz_manager.student_count(str(session.ID_Session)),
            },
        )

    return JoinSessionResponse(
        id_session=session.ID_Session,
        room_code=session.Room_Code,
        quiz_title=session.quiz.Title,
        status=session.Status,
        current_question_index=session.Current_Question_Index,
        total_questions=len(session.quiz.quiz_exercises),
    )


@router.get("/sessions/{session_id}/current-question", response_model=QuestionForStudent)
async def get_current_question(
    session_id: UUID,
    db: AsyncSession = Depends(get_db),
    current_student: Base_User = Depends(require_roles("Student")),
):
    stmt = (
        select(Quiz_Session)
        .options(
            selectinload(Quiz_Session.quiz).selectinload(Quiz.quiz_exercises).selectinload(Quiz_Exercise.exercise)
        )
        .where(Quiz_Session.ID_Session == session_id)
    )
    session = await db.scalar(stmt)
    if not session:
        raise HTTPException(status_code=status.HTTP_404_NOT_FOUND, detail="Session not found")
    if session.Status != QuizSessionStatus.ACTIVE:
        raise HTTPException(status_code=status.HTTP_409_CONFLICT, detail="Session is not active")

    # Confirm participant
    participant = await db.scalar(
        select(Quiz_Participant).where(
            and_(
                Quiz_Participant.ID_Session == session_id,
                Quiz_Participant.ID_Student == current_student.ID_User,
            )
        )
    )
    if not participant:
        raise HTTPException(status_code=status.HTTP_403_FORBIDDEN, detail="You are not in this session")

    exercises = sorted(session.quiz.quiz_exercises, key=lambda qe: qe.Question_Order)
    idx = session.Current_Question_Index
    if idx >= len(exercises):
        raise HTTPException(status_code=status.HTTP_410_GONE, detail="No more questions")

    ex = exercises[idx].exercise
    options = ex.Solution.get("options") if ex.Solution else None
    if not options and ex.Type.value == "True/False":
        options = ["A) Verdadeiro", "B) Falso"]

    return QuestionForStudent(
        index=idx,
        total=len(exercises),
        question=ex.Question,
        type=ex.Type.value,
        options=options,
        time_limit_seconds=_TIME_LIMIT_SECONDS,
    )


@router.post("/sessions/{session_id}/answer", response_model=SubmitAnswerResponse)
async def submit_answer(
    session_id: UUID,
    payload: SubmitAnswerRequest,
    request: Request,
    db: AsyncSession = Depends(get_db),
    current_student: Base_User = Depends(require_roles("Student")),
):
    stmt = (
        select(Quiz_Session)
        .options(
            selectinload(Quiz_Session.quiz).selectinload(Quiz.quiz_exercises).selectinload(Quiz_Exercise.exercise)
        )
        .where(Quiz_Session.ID_Session == session_id)
    )
    session = await db.scalar(stmt)
    if not session:
        raise HTTPException(status_code=status.HTTP_404_NOT_FOUND, detail="Session not found")
    if session.Status != QuizSessionStatus.ACTIVE:
        raise HTTPException(status_code=status.HTTP_409_CONFLICT, detail="Session is not active")

    participant = await db.scalar(
        select(Quiz_Participant).where(
            and_(
                Quiz_Participant.ID_Session == session_id,
                Quiz_Participant.ID_Student == current_student.ID_User,
            )
        )
    )
    if not participant:
        raise HTTPException(status_code=status.HTTP_403_FORBIDDEN, detail="You are not in this session")

    exercises = sorted(session.quiz.quiz_exercises, key=lambda qe: qe.Question_Order)
    idx = session.Current_Question_Index
    if idx >= len(exercises):
        raise HTTPException(status_code=status.HTTP_410_GONE, detail="No more questions")

    ex = exercises[idx].exercise

    # Idempotency: one answer per question per student
    already_answered = await db.scalar(
        select(Quiz_Answer).where(
            and_(
                Quiz_Answer.ID_Session == session_id,
                Quiz_Answer.ID_Student == current_student.ID_User,
                Quiz_Answer.ID_Exercise == ex.ID_Exercise,
            )
        )
    )
    if already_answered:
        raise HTTPException(status_code=status.HTTP_409_CONFLICT, detail="Already answered this question")

    correct_answer = ex.Solution.get("correct")
    is_correct = str(payload.answer).strip() == str(correct_answer).strip()
    points = _calculate_points(is_correct, payload.time_taken_ms)

    db.add(
        Quiz_Answer(
            ID_Session=session_id,
            ID_Student=current_student.ID_User,
            ID_Exercise=ex.ID_Exercise,
            Answer={"answer": payload.answer},
            Is_Correct=is_correct,
            Time_Taken_Ms=payload.time_taken_ms,
            Points_Earned=points,
        )
    )
    participant.Score += points
    await db.flush()
    await db.commit()

    total_participants = await db.scalar(
        select(Quiz_Participant).where(Quiz_Participant.ID_Session == session_id)
    )
    answered_count = await db.scalar(
        select(Quiz_Answer).where(
            and_(Quiz_Answer.ID_Session == session_id, Quiz_Answer.ID_Exercise == ex.ID_Exercise)
        )
    )

    # Push progress to professor
    quiz_manager = request.app.state.quiz_manager
    await quiz_manager.send_to_professor(
        str(session_id),
        {
            "type": "answer_received",
            "student_id": str(current_student.ID_User),
            "is_correct": is_correct,
        },
    )

    return SubmitAnswerResponse(
        is_correct=is_correct,
        points_earned=points,
        total_score=participant.Score,
        correct_answer=correct_answer,
    )


@router.get("/sessions/{session_id}/leaderboard", response_model=LeaderboardResponse)
async def get_leaderboard(
    session_id: UUID,
    db: AsyncSession = Depends(get_db),
    current_student: Base_User = Depends(require_roles("Student")),
):
    participant = await db.scalar(
        select(Quiz_Participant).where(
            and_(
                Quiz_Participant.ID_Session == session_id,
                Quiz_Participant.ID_Student == current_student.ID_User,
            )
        )
    )
    if not participant:
        raise HTTPException(status_code=status.HTTP_403_FORBIDDEN, detail="You are not in this session")

    stmt = (
        select(Quiz_Session)
        .options(selectinload(Quiz_Session.participants).selectinload(Quiz_Participant.student))
        .where(Quiz_Session.ID_Session == session_id)
    )
    session = await db.scalar(stmt)

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
