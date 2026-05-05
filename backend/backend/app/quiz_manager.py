from collections import defaultdict

from fastapi import WebSocket


class QuizConnectionManager:
    """
    Manages active WebSocket connections for all quiz sessions.

    Layout per session:
        _sessions[session_id] = {
            "professor": WebSocket | None,
            "students":  {str(student_id): WebSocket},
        }
    """

    def __init__(self) -> None:
        self._sessions: dict[str, dict] = defaultdict(
            lambda: {"professor": None, "students": {}}
        )

    # ------------------------------------------------------------------
    # Connect / disconnect
    # ------------------------------------------------------------------

    async def connect_professor(self, session_id: str, ws: WebSocket) -> None:
        await ws.accept()
        self._sessions[session_id]["professor"] = ws

    async def connect_student(self, session_id: str, student_id: str, ws: WebSocket) -> None:
        await ws.accept()
        self._sessions[session_id]["students"][student_id] = ws

    def disconnect_professor(self, session_id: str) -> None:
        if session_id in self._sessions:
            self._sessions[session_id]["professor"] = None

    def disconnect_student(self, session_id: str, student_id: str) -> None:
        if session_id in self._sessions:
            self._sessions[session_id]["students"].pop(student_id, None)

    def cleanup_session(self, session_id: str) -> None:
        self._sessions.pop(session_id, None)

    # ------------------------------------------------------------------
    # Send helpers
    # ------------------------------------------------------------------

    async def send_to_professor(self, session_id: str, data: dict) -> None:
        ws: WebSocket | None = self._sessions[session_id].get("professor")
        if ws:
            try:
                await ws.send_json(data)
            except Exception:
                self.disconnect_professor(session_id)

    async def send_to_student(self, session_id: str, student_id: str, data: dict) -> None:
        ws: WebSocket | None = self._sessions[session_id]["students"].get(student_id)
        if ws:
            try:
                await ws.send_json(data)
            except Exception:
                self.disconnect_student(session_id, student_id)

    async def broadcast_to_students(self, session_id: str, data: dict) -> None:
        for sid, ws in list(self._sessions[session_id]["students"].items()):
            try:
                await ws.send_json(data)
            except Exception:
                self.disconnect_student(session_id, sid)

    async def broadcast_to_all(self, session_id: str, data: dict) -> None:
        await self.send_to_professor(session_id, data)
        await self.broadcast_to_students(session_id, data)

    # ------------------------------------------------------------------
    # Info
    # ------------------------------------------------------------------

    def student_count(self, session_id: str) -> int:
        return len(self._sessions[session_id].get("students", {}))

    def professor_connected(self, session_id: str) -> bool:
        return self._sessions[session_id].get("professor") is not None


quiz_manager = QuizConnectionManager()
