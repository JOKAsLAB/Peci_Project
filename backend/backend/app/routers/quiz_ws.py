"""
WebSocket endpoints for real-time quiz sessions.

Professor WebSocket — ws://.../api/v1/quizzes/ws/professor/{session_id}?token=<jwt>
  Receives: "joined" events from students
  Sends:    {"type": "start"} | {"type": "next"} | {"type": "end"}

Student WebSocket  — ws://.../api/v1/quizzes/ws/student/{session_id}?token=<jwt>
  Receives: question / answer_result / session_ended events
  (Answers are submitted via the REST endpoint, not here)
"""

from uuid import UUID

from fastapi import APIRouter, Query, WebSocket, WebSocketDisconnect
from sqlalchemy import and_, select
from sqlalchemy.orm import selectinload

from app.database import AsyncSessionLocal
from app.models import Base_User, Quiz, Quiz_Exercise, Quiz_Participant, Quiz_Session
from app.models.enums import QuizSessionStatus
from app.quiz_manager import quiz_manager
from app.security import decode_access_token

router = APIRouter(prefix="/api/v1/quizzes", tags=["quizzes-ws"])

_TIME_LIMIT_SECONDS = 30


async def _get_user_from_token(token: str) -> Base_User | None:
    try:
        payload = decode_access_token(token)
        user_id = UUID(payload.get("sub", ""))
    except Exception:
        return None
    async with AsyncSessionLocal() as db:
        return await db.scalar(select(Base_User).where(Base_User.ID_User == user_id))


_TF_OPTIONS = ["A) Verdadeiro", "B) Falso"]


def _build_question_payload(exercises: list[Quiz_Exercise], idx: int) -> dict:
    qe = exercises[idx]
    ex = qe.exercise
    options = ex.Solution.get("options") if ex.Solution else None
    if not options and ex.Type.value == "True/False":
        options = _TF_OPTIONS
    return {
        "type": "question",
        "index": idx,
        "total": len(exercises),
        "question": ex.Question,
        "exercise_type": ex.Type.value,
        "options": options,
        "time_limit_seconds": _TIME_LIMIT_SECONDS,
    }


def _build_leaderboard(participants: list[Quiz_Participant]) -> list[dict]:
    sorted_p = sorted(participants, key=lambda p: p.Score, reverse=True)
    return [
        {
            "rank": i + 1,
            "student_id": str(p.ID_Student),
            "student_name": p.student.Name,
            "score": p.Score,
        }
        for i, p in enumerate(sorted_p)
    ]


# =============================================================
# Professor WebSocket
# =============================================================

@router.websocket("/ws/professor/{session_id}")
async def professor_ws(
    websocket: WebSocket,
    session_id: UUID,
    token: str = Query(...),
):
    user = await _get_user_from_token(token)
    if not user or user.Role != "Professor":
        await websocket.close(code=4001)
        return

    session_str = str(session_id)

    async with AsyncSessionLocal() as db:
        stmt = (
            select(Quiz_Session)
            .options(
                selectinload(Quiz_Session.quiz).selectinload(Quiz.quiz_exercises).selectinload(Quiz_Exercise.exercise),
                selectinload(Quiz_Session.participants).selectinload(Quiz_Participant.student),
            )
            .where(Quiz_Session.ID_Session == session_id)
        )
        session = await db.scalar(stmt)

        if not session or session.quiz.ID_Professor != user.ID_User:
            await websocket.close(code=4003)
            return

    await quiz_manager.connect_professor(session_str, websocket)

    try:
        while True:
            data = await websocket.receive_json()
            msg_type = data.get("type")

            async with AsyncSessionLocal() as db:
                stmt = (
                    select(Quiz_Session)
                    .options(
                        selectinload(Quiz_Session.quiz)
                        .selectinload(Quiz.quiz_exercises)
                        .selectinload(Quiz_Exercise.exercise),
                        selectinload(Quiz_Session.participants).selectinload(Quiz_Participant.student),
                    )
                    .where(Quiz_Session.ID_Session == session_id)
                )
                session = await db.scalar(stmt)
                exercises = sorted(session.quiz.quiz_exercises, key=lambda qe: qe.Question_Order)

                if msg_type == "start":
                    if session.Status != QuizSessionStatus.WAITING:
                        await quiz_manager.send_to_professor(session_str, {"type": "error", "detail": "Session already started"})
                        continue

                    from sqlalchemy.sql import func as sqlfunc
                    session.Status = QuizSessionStatus.ACTIVE
                    session.Started_At = sqlfunc.now()
                    session.Current_Question_Index = 0
                    await db.flush()
                    await db.commit()

                    question_payload = _build_question_payload(exercises, 0)
                    await quiz_manager.broadcast_to_students(session_str, question_payload)
                    await quiz_manager.send_to_professor(session_str, {**question_payload, "type": "session_started"})

                elif msg_type == "next":
                    if session.Status != QuizSessionStatus.ACTIVE:
                        await quiz_manager.send_to_professor(session_str, {"type": "error", "detail": "Session not active"})
                        continue

                    next_idx = session.Current_Question_Index + 1

                    if next_idx >= len(exercises):
                        # End the session
                        from sqlalchemy.sql import func as sqlfunc
                        session.Status = QuizSessionStatus.FINISHED
                        session.Finished_At = sqlfunc.now()
                        await db.flush()
                        await db.commit()

                        leaderboard = _build_leaderboard(session.participants)
                        await quiz_manager.broadcast_to_all(session_str, {"type": "session_ended", "leaderboard": leaderboard})
                        quiz_manager.cleanup_session(session_str)
                        break

                    session.Current_Question_Index = next_idx
                    await db.flush()
                    await db.commit()

                    question_payload = _build_question_payload(exercises, next_idx)
                    await quiz_manager.broadcast_to_students(session_str, question_payload)
                    await quiz_manager.send_to_professor(session_str, question_payload)

                elif msg_type == "end":
                    from sqlalchemy.sql import func as sqlfunc
                    session.Status = QuizSessionStatus.FINISHED
                    session.Finished_At = sqlfunc.now()
                    await db.flush()
                    await db.commit()

                    leaderboard = _build_leaderboard(session.participants)
                    await quiz_manager.broadcast_to_all(session_str, {"type": "session_ended", "leaderboard": leaderboard})
                    quiz_manager.cleanup_session(session_str)
                    break

    except WebSocketDisconnect:
        quiz_manager.disconnect_professor(session_str)


# =============================================================
# Student WebSocket
# =============================================================

@router.websocket("/ws/student/{session_id}")
async def student_ws(
    websocket: WebSocket,
    session_id: UUID,
    token: str = Query(...),
):
    user = await _get_user_from_token(token)
    if not user or user.Role != "Student":
        await websocket.close(code=4001)
        return

    student_str = str(user.ID_User)
    session_str = str(session_id)

    async with AsyncSessionLocal() as db:
        session = await db.scalar(
            select(Quiz_Session).where(Quiz_Session.ID_Session == session_id)
        )
        if not session or session.Status == QuizSessionStatus.FINISHED:
            await websocket.close(code=4004)
            return

        participant = await db.scalar(
            select(Quiz_Participant).where(
                and_(
                    Quiz_Participant.ID_Session == session_id,
                    Quiz_Participant.ID_Student == user.ID_User,
                )
            )
        )
        if not participant:
            await websocket.close(code=4003)
            return

    await quiz_manager.connect_student(session_str, student_str, websocket)

    try:
        # Keep connection alive — all real events are pushed by the server
        while True:
            await websocket.receive_text()
    except WebSocketDisconnect:
        quiz_manager.disconnect_student(session_str, student_str)
