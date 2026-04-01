import asyncio
import os
import statistics
import time
import uuid
from concurrent.futures import ThreadPoolExecutor, as_completed

import pytest
import requests
from sqlalchemy import select

from app.database import AsyncSessionLocal
from app.models import Admin, Base_User
from app.models.enums import UserRole, UserStatus
from app.security import hash_password


BASE_URL = os.getenv("SMOKE_BASE_URL", "http://127.0.0.1:8000").rstrip("/")
TIMEOUT = float(os.getenv("SMOKE_TIMEOUT", "10"))
ADMIN_EMAIL = os.getenv("SMOKE_ADMIN_EMAIL")
ADMIN_PASSWORD = os.getenv("SMOKE_ADMIN_PASSWORD")
CONCURRENCY_WORKERS = int(os.getenv("SMOKE_CONCURRENCY_WORKERS", "8"))
CONCURRENCY_REQUESTS = int(os.getenv("SMOKE_CONCURRENCY_REQUESTS", "32"))
LOAD_REQUESTS = int(os.getenv("SMOKE_LOAD_REQUESTS", "120"))
LOAD_MAX_P95_MS = float(os.getenv("SMOKE_LOAD_MAX_P95_MS", "3000"))
SCALE_BULK_USERS = int(os.getenv("SMOKE_SCALE_BULK_USERS", "24"))
SCALE_LOGIN_MAX_P95_MS = float(os.getenv("SMOKE_SCALE_LOGIN_MAX_P95_MS", "6000"))
SCALE_ADMIN_QUERY_ROUNDS = int(os.getenv("SMOKE_SCALE_ADMIN_QUERY_ROUNDS", "48"))


def _unique_email(prefix: str) -> str:
    return f"smoke_{prefix}_{uuid.uuid4().hex[:10]}@ua.pt"


def _url(path: str) -> str:
    return f"{BASE_URL}{path}"


def _ensure_api_online() -> None:
    try:
        response = requests.get(_url("/health"), timeout=TIMEOUT)
    except requests.RequestException as exc:
        pytest.skip(f"API indisponivel em {BASE_URL} (/health): {exc}")

    if response.status_code != 200:
        pytest.skip(f"/health respondeu {response.status_code} em {BASE_URL}")


@pytest.fixture(scope="session", autouse=True)
def api_online_guard() -> None:
    _ensure_api_online()


def _auth_headers(token: str) -> dict[str, str]:
    return {"Authorization": f"Bearer {token}"}


def _register_account(role: str) -> dict[str, str]:
    email = _unique_email(role.lower())
    password = "SmokePass123!"

    payload = {
        "name": f"Smoke {role}",
        "email": email,
        "password": password,
        "role": role,
    }

    if role == "Professor":
        payload.update(
            {
                "department": "DETI",
                "office": "Lab-SMOKE",
                "short_bio": "Conta temporaria para smoke tests",
            }
        )

    response = requests.post(
        _url("/api/v1/auth/register"),
        json=payload,
        timeout=TIMEOUT,
    )
    assert response.status_code == 201, response.text

    data = response.json()
    return {
        "email": email,
        "password": password,
        "token": data["access_token"],
        "user_id": data["user"]["id"],
    }


def _login(email: str, password: str) -> dict:
    response = requests.post(
        _url("/api/v1/auth/login"),
        json={"email": email, "password": password},
        timeout=TIMEOUT,
    )
    assert response.status_code == 200, response.text
    return response.json()


def _approve_professor_access_request(professor_user_id: str, admin_token: str) -> None:
    pending_requests = _request("GET", "/api/v1/admin/requests?status=pending", token=admin_token)
    assert pending_requests.status_code == 200, pending_requests.text

    access_request = next(
        (
            item
            for item in pending_requests.json()
            if item.get("id_professor") == professor_user_id and item.get("request_type") == "access"
        ),
        None,
    )
    assert access_request is not None, "Pedido de acesso pendente do professor nao encontrado"

    decision = _request(
        "PATCH",
        f"/api/v1/admin/requests/{access_request['id_request']}/decision",
        token=admin_token,
        json={"status": "approved", "admin_comment": "Aprovado automaticamente no smoke"},
    )
    assert decision.status_code == 200, decision.text


async def _ensure_local_admin(email: str, password: str) -> None:
    async with AsyncSessionLocal() as db:
        existing = await db.scalar(select(Base_User).where(Base_User.Email == email))

        if not existing:
            existing = Admin(
                Name="Smoke Admin",
                Email=email,
                Password_Hash=hash_password(password),
                Role=UserRole.ADMIN,
                Status=UserStatus.ACTIVE,
                Privilege_Level=3,
                Contact=email,
            )
            db.add(existing)
            await db.flush()
        else:
            existing.Name = "Smoke Admin"
            existing.Password_Hash = hash_password(password)
            existing.Role = UserRole.ADMIN
            existing.Status = UserStatus.ACTIVE

        admin_row = await db.scalar(select(Admin).where(Admin.ID_Admin == existing.ID_User))
        if not admin_row:
            db.add(
                Admin(
                    ID_Admin=existing.ID_User,
                    Privilege_Level=3,
                    Contact=email,
                )
            )
        else:
            admin_row.Privilege_Level = 3
            admin_row.Contact = email

        await db.commit()


@pytest.fixture(scope="session")
def student_account() -> dict[str, str]:
    return _register_account("Student")


@pytest.fixture(scope="session")
def professor_account(admin_account: dict[str, str]) -> dict[str, str]:
    account = _register_account("Professor")
    _approve_professor_access_request(account["user_id"], admin_account["token"])
    account["token"] = _login(account["email"], account["password"])["access_token"]
    return account


@pytest.fixture(scope="session")
def admin_token() -> str:
    email = ADMIN_EMAIL
    password = ADMIN_PASSWORD

    if not email or not password:
        email = _unique_email("admin")
        password = "SmokePass123!"
        asyncio.run(_ensure_local_admin(email=email, password=password))

    return _login(email, password)["access_token"]


@pytest.fixture(scope="session")
def admin_account(admin_token: str) -> dict[str, str]:
    response = requests.get(
        _url("/api/v1/auth/me"),
        headers=_auth_headers(admin_token),
        timeout=TIMEOUT,
    )
    assert response.status_code == 200, response.text
    profile = response.json()
    return {
        "token": admin_token,
        "user_id": profile["id"],
        "email": profile["email"],
    }


def _request(method: str, path: str, token: str | None = None, **kwargs) -> requests.Response:
    headers = kwargs.pop("headers", {})
    if token:
        headers = {**headers, **_auth_headers(token)}
    return requests.request(method=method, url=_url(path), headers=headers, timeout=TIMEOUT, **kwargs)


def _assert_exact_keys(payload: dict, expected_keys: set[str]) -> None:
    assert set(payload.keys()) == expected_keys, f"Keys inesperadas: {set(payload.keys())}"


def _percentile_ms(samples_ms: list[float], percentile: float) -> float:
    if not samples_ms:
        return 0.0
    ordered = sorted(samples_ms)
    index = int((len(ordered) - 1) * percentile)
    return ordered[index]


def _parallel_get(path: str, token: str, total: int, workers: int) -> list[tuple[int, float]]:
    def _one_call() -> tuple[int, float]:
        start = time.perf_counter()
        response = _request("GET", path, token=token)
        elapsed_ms = (time.perf_counter() - start) * 1000.0
        return response.status_code, elapsed_ms

    results: list[tuple[int, float]] = []
    with ThreadPoolExecutor(max_workers=workers) as executor:
        futures = [executor.submit(_one_call) for _ in range(total)]
        for future in as_completed(futures):
            results.append(future.result())

    return results


def _sequential_get(path: str, token: str | None, total: int) -> list[tuple[int, float]]:
    results: list[tuple[int, float]] = []
    for _ in range(total):
        start = time.perf_counter()
        response = _request("GET", path, token=token)
        elapsed_ms = (time.perf_counter() - start) * 1000.0
        results.append((response.status_code, elapsed_ms))
    return results


def test_health_and_root_endpoints() -> None:
    root = requests.get(_url("/"), timeout=TIMEOUT)
    assert root.status_code == 200, root.text
    assert root.json().get("message") == "API is running"

    health = requests.get(_url("/health"), timeout=TIMEOUT)
    assert health.status_code == 200, health.text
    assert health.json().get("status") == "ok"


def test_auth_login_and_me(student_account: dict[str, str]) -> None:
    login_data = _login(student_account["email"], student_account["password"])
    assert "access_token" in login_data

    me_response = requests.get(
        _url("/api/v1/auth/me"),
        headers=_auth_headers(login_data["access_token"]),
        timeout=TIMEOUT,
    )
    assert me_response.status_code == 200, me_response.text


def test_contract_auth_me_response_shape(student_account: dict[str, str]) -> None:
    me_response = _request("GET", "/api/v1/auth/me", token=student_account["token"])
    assert me_response.status_code == 200, me_response.text

    payload = me_response.json()
    _assert_exact_keys(payload, {"id", "name", "email", "role", "status", "registration_date"})
    assert isinstance(payload["id"], str)
    assert isinstance(payload["email"], str)
    assert payload["role"] in {"Student", "Professor", "Admin"}
    assert payload["status"] in {"Active", "Suspended", "Deactivated"}


def test_auth_rejects_invalid_password(student_account: dict[str, str]) -> None:
    response = requests.post(
        _url("/api/v1/auth/login"),
        json={"email": student_account["email"], "password": "WrongPass!"},
        timeout=TIMEOUT,
    )
    assert response.status_code == 401


def test_auth_register_rejects_duplicate_email(student_account: dict[str, str]) -> None:
    payload = {
        "name": "Duplicate Student",
        "email": student_account["email"],
        "password": "SmokePass123!",
        "role": "Student",
    }
    response = requests.post(_url("/api/v1/auth/register"), json=payload, timeout=TIMEOUT)
    assert response.status_code == 409


def test_professor_registration_requires_admin_approval(admin_account: dict[str, str]) -> None:
    pending_professor = _register_account("Professor")

    blocked_login = requests.post(
        _url("/api/v1/auth/login"),
        json={"email": pending_professor["email"], "password": pending_professor["password"]},
        timeout=TIMEOUT,
    )
    assert blocked_login.status_code == 403, blocked_login.text
    assert blocked_login.json().get("detail") == "Account pending admin approval"

    _approve_professor_access_request(pending_professor["user_id"], admin_account["token"])

    unblocked_login = requests.post(
        _url("/api/v1/auth/login"),
        json={"email": pending_professor["email"], "password": pending_professor["password"]},
        timeout=TIMEOUT,
    )
    assert unblocked_login.status_code == 200, unblocked_login.text


def test_auth_me_rejects_malformed_token() -> None:
    response = requests.get(
        _url("/api/v1/auth/me"),
        headers={"Authorization": "Bearer definitely.invalid.token"},
        timeout=TIMEOUT,
    )
    assert response.status_code == 401


@pytest.mark.parametrize(
    "method,path,body",
    [
        ("GET", "/api/v1/students/course-units", None),
        ("GET", "/api/v1/students/me", None),
        ("GET", "/api/v1/professors/requests", None),
        ("GET", "/api/v1/admin/users", None),
        ("POST", "/api/v1/ai-tutor/query", {"question": "Qual o objetivo de uma porta NOT?"}),
    ],
)
def test_protected_endpoints_require_token(method: str, path: str, body: dict | None) -> None:
    kwargs = {"json": body} if body is not None else {}
    response = _request(method=method, path=path, **kwargs)
    assert response.status_code == 401


def test_rbac_student_cannot_access_professor_area(student_account: dict[str, str]) -> None:
    response = _request("GET", "/api/v1/professors/course-units", token=student_account["token"])
    assert response.status_code == 403


def test_rbac_professor_cannot_access_student_area(professor_account: dict[str, str]) -> None:
    response = _request("GET", "/api/v1/students/me", token=professor_account["token"])
    assert response.status_code == 403


def test_student_catalog_endpoints(student_account: dict[str, str]) -> None:
    response_courses = _request("GET", "/api/v1/students/course-units", token=student_account["token"])
    assert response_courses.status_code == 200, response_courses.text
    course_units = response_courses.json()
    assert isinstance(course_units, list)
    assert all("id_uc" in uc and "name" in uc for uc in course_units)

    response_exercises = _request(
        "GET",
        "/api/v1/students/exercises?limit=5&id_uc=41953&difficulty=Easy",
        token=student_account["token"],
    )
    assert response_exercises.status_code == 200, response_exercises.text
    exercises = response_exercises.json()
    assert isinstance(exercises, list)
    for item in exercises:
        assert item["id_uc"] == 41953
        assert item["difficulty"] == "Easy"


def test_students_invalid_exercises_pagination_returns_422(student_account: dict[str, str]) -> None:
    response = _request(
        "GET",
        "/api/v1/students/exercises?limit=0",
        token=student_account["token"],
    )
    assert response.status_code == 422


def test_students_endpoints(student_account: dict[str, str]) -> None:
    me_response = _request("GET", "/api/v1/students/me", token=student_account["token"])
    assert me_response.status_code == 200, me_response.text
    before_xp = me_response.json()["total_xp"]

    exercises_response = _request("GET", "/api/v1/students/exercises?limit=5", token=student_account["token"])
    assert exercises_response.status_code == 200, exercises_response.text
    exercises = exercises_response.json()
    assert isinstance(exercises, list)

    streak_response = _request("GET", "/api/v1/students/streak?limit=10", token=student_account["token"])
    assert streak_response.status_code == 200, streak_response.text
    assert isinstance(streak_response.json(), list)

    missing_exercise_payload = {
        "id_exercise": str(uuid.uuid4()),
        "attempts": 1,
        "status": "Incorrect",
        "xp_earned": 0,
        "sync_status": "Pending",
    }
    missing_exercise_response = _request(
        "POST",
        "/api/v1/students/progress",
        token=student_account["token"],
        json=missing_exercise_payload,
    )
    assert missing_exercise_response.status_code == 404

    if not exercises:
        pytest.skip("Sem exercicios disponiveis para validar POST /students/progress")

    progress_payload = {
        "id_exercise": exercises[0]["id_exercise"],
        "attempts": 1,
        "status": "Correct",
        "xp_earned": 5,
        "sync_status": "Pending",
    }
    progress_response = _request(
        "POST",
        "/api/v1/students/progress",
        token=student_account["token"],
        json=progress_payload,
    )
    assert progress_response.status_code == 201, progress_response.text
    assert progress_response.json()["xp_earned"] == 5

    me_after_response = _request("GET", "/api/v1/students/me", token=student_account["token"])
    assert me_after_response.status_code == 200, me_after_response.text
    assert me_after_response.json()["total_xp"] >= before_xp + 5


def test_contract_students_me_response_shape(student_account: dict[str, str]) -> None:
    response = _request("GET", "/api/v1/students/me", token=student_account["token"])
    assert response.status_code == 200, response.text

    payload = response.json()
    _assert_exact_keys(payload, {"id_student", "current_level", "total_xp", "streak_days", "last_access"})
    assert isinstance(payload["id_student"], str)
    assert isinstance(payload["current_level"], int)
    assert isinstance(payload["total_xp"], int)
    assert isinstance(payload["streak_days"], int)


def test_students_invalid_streak_limit_returns_422(student_account: dict[str, str]) -> None:
    response = _request("GET", "/api/v1/students/streak?limit=0", token=student_account["token"])
    assert response.status_code == 422


def test_professor_endpoints(professor_account: dict[str, str]) -> None:
    response_course_units = _request("GET", "/api/v1/professors/course-units", token=professor_account["token"])
    assert response_course_units.status_code == 200, response_course_units.text
    assert isinstance(response_course_units.json(), list)

    response_exercises = _request("GET", "/api/v1/professors/exercises?limit=5", token=professor_account["token"])
    assert response_exercises.status_code == 200, response_exercises.text
    assert isinstance(response_exercises.json(), list)

    response_materials = _request("GET", "/api/v1/professors/materials", token=professor_account["token"])
    assert response_materials.status_code == 200, response_materials.text
    assert isinstance(response_materials.json(), list)

    response_requests = _request("GET", "/api/v1/professors/requests", token=professor_account["token"])
    assert response_requests.status_code == 200, response_requests.text
    assert isinstance(response_requests.json(), list)


def test_professor_write_endpoints_require_uc_assignment(professor_account: dict[str, str]) -> None:
    material_payload = {
        "id_uc": 41953,
        "title": "Material nao autorizado",
        "file_path": "/tmp/material.pdf",
        "extracted_text": "texto",
    }
    material_response = _request(
        "POST",
        "/api/v1/professors/materials",
        token=professor_account["token"],
        json=material_payload,
    )
    assert material_response.status_code == 403

    exercise_payload = {
        "id_uc": 41953,
        "topic_name": "Portas Logicas",
        "material_ref": None,
        "type": "True/False",
        "question": "Uma porta OR retorna 1 quando ambas entradas sao 0?",
        "solution": {"correct": False},
        "difficulty": "Easy",
        "explanation": "OR(0,0) = 0",
    }
    exercise_response = _request(
        "POST",
        "/api/v1/professors/exercises",
        token=professor_account["token"],
        json=exercise_payload,
    )
    assert exercise_response.status_code == 403


def test_professor_request_lifecycle_with_admin(
    professor_account: dict[str, str],
    admin_account: dict[str, str],
) -> None:
    create_payload = {
        "request_type": "operations",
        "title": f"Pedido smoke {uuid.uuid4().hex[:6]}",
        "description": "Validacao de fluxo professor-admin",
    }
    created = _request(
        "POST",
        "/api/v1/professors/requests",
        token=professor_account["token"],
        json=create_payload,
    )
    assert created.status_code == 201, created.text
    created_data = created.json()
    assert created_data["status"] == "pending"

    request_id = created_data["id_request"]

    pending_list = _request(
        "GET",
        "/api/v1/admin/requests?status=pending",
        token=admin_account["token"],
    )
    assert pending_list.status_code == 200, pending_list.text
    pending_ids = {item["id_request"] for item in pending_list.json()}
    assert request_id in pending_ids

    decision = _request(
        "PATCH",
        f"/api/v1/admin/requests/{request_id}/decision",
        token=admin_account["token"],
        json={"status": "approved", "admin_comment": "Aprovado em smoke test"},
    )
    assert decision.status_code == 200, decision.text
    decision_data = decision.json()
    assert decision_data["status"] == "approved"
    assert decision_data["resolution_date"] is not None

    second_decision = _request(
        "PATCH",
        f"/api/v1/admin/requests/{request_id}/decision",
        token=admin_account["token"],
        json={"status": "rejected", "admin_comment": "Nao deve alterar"},
    )
    assert second_decision.status_code == 400

    approved_list = _request(
        "GET",
        "/api/v1/admin/requests?status=approved",
        token=admin_account["token"],
    )
    assert approved_list.status_code == 200, approved_list.text
    approved_ids = {item["id_request"] for item in approved_list.json()}
    assert request_id in approved_ids


def test_professor_requests_are_isolated_by_identity(admin_account: dict[str, str]) -> None:
    professor_a = _register_account("Professor")
    professor_b = _register_account("Professor")

    _approve_professor_access_request(professor_a["user_id"], admin_account["token"])
    _approve_professor_access_request(professor_b["user_id"], admin_account["token"])
    professor_a["token"] = _login(professor_a["email"], professor_a["password"])["access_token"]
    professor_b["token"] = _login(professor_b["email"], professor_b["password"])["access_token"]

    created_a = _request(
        "POST",
        "/api/v1/professors/requests",
        token=professor_a["token"],
        json={"request_type": "platform", "title": f"Pedido A {uuid.uuid4().hex[:5]}", "description": "Req A"},
    )
    assert created_a.status_code == 201, created_a.text
    request_a_id = created_a.json()["id_request"]

    created_b = _request(
        "POST",
        "/api/v1/professors/requests",
        token=professor_b["token"],
        json={"request_type": "access", "title": f"Pedido B {uuid.uuid4().hex[:5]}", "description": "Req B"},
    )
    assert created_b.status_code == 201, created_b.text
    request_b_id = created_b.json()["id_request"]

    list_a = _request("GET", "/api/v1/professors/requests", token=professor_a["token"])
    assert list_a.status_code == 200, list_a.text
    ids_a = {item["id_request"] for item in list_a.json()}

    list_b = _request("GET", "/api/v1/professors/requests", token=professor_b["token"])
    assert list_b.status_code == 200, list_b.text
    ids_b = {item["id_request"] for item in list_b.json()}

    assert request_a_id in ids_a
    assert request_b_id not in ids_a
    assert request_b_id in ids_b
    assert request_a_id not in ids_b


def test_admin_endpoints(admin_account: dict[str, str], student_account: dict[str, str]) -> None:
    response_users = _request("GET", "/api/v1/admin/users", token=admin_account["token"])
    assert response_users.status_code == 200, response_users.text
    users_payload = response_users.json()
    assert isinstance(users_payload, list)

    response_requests = _request("GET", "/api/v1/admin/requests", token=admin_account["token"])
    assert response_requests.status_code == 200, response_requests.text
    assert isinstance(response_requests.json(), list)

    response_courses = _request("GET", "/api/v1/admin/course-units", token=admin_account["token"])
    assert response_courses.status_code == 200, response_courses.text
    assert isinstance(response_courses.json(), list)

    student_filtered = _request("GET", "/api/v1/admin/users?role=Student", token=admin_account["token"])
    assert student_filtered.status_code == 200, student_filtered.text
    filtered_payload = student_filtered.json()
    assert filtered_payload
    assert all(item["role"] == "Student" for item in filtered_payload)

    status_filtered = _request("GET", "/api/v1/admin/users?status=Active", token=admin_account["token"])
    assert status_filtered.status_code == 200, status_filtered.text
    assert all(item["status"] == "Active" for item in status_filtered.json())

    q_filtered = _request(
        "GET",
        f"/api/v1/admin/users?q={student_account['email']}",
        token=admin_account["token"],
    )
    assert q_filtered.status_code == 200, q_filtered.text
    assert any(item["email"] == student_account["email"] for item in q_filtered.json())


def test_admin_user_status_change_blocks_and_restores_login(admin_account: dict[str, str]) -> None:
    new_student = _register_account("Student")

    suspend = _request(
        "PATCH",
        f"/api/v1/admin/users/{new_student['user_id']}",
        token=admin_account["token"],
        json={"status": "Suspended"},
    )
    assert suspend.status_code == 200, suspend.text
    assert suspend.json()["status"] == "Suspended"

    suspended_login = requests.post(
        _url("/api/v1/auth/login"),
        json={"email": new_student["email"], "password": new_student["password"]},
        timeout=TIMEOUT,
    )
    assert suspended_login.status_code == 403, suspended_login.text

    reactivate = _request(
        "PATCH",
        f"/api/v1/admin/users/{new_student['user_id']}",
        token=admin_account["token"],
        json={"status": "Active"},
    )
    assert reactivate.status_code == 200, reactivate.text
    assert reactivate.json()["status"] == "Active"

    active_login = requests.post(
        _url("/api/v1/auth/login"),
        json={"email": new_student["email"], "password": new_student["password"]},
        timeout=TIMEOUT,
    )
    assert active_login.status_code == 200, active_login.text


def test_contract_admin_users_item_shape(admin_account: dict[str, str]) -> None:
    response = _request("GET", "/api/v1/admin/users", token=admin_account["token"])
    assert response.status_code == 200, response.text
    payload = response.json()
    assert isinstance(payload, list)
    assert payload, "Lista de utilizadores vazia, sem item para validar contrato"

    first = payload[0]
    _assert_exact_keys(first, {"id", "name", "email", "role", "status", "registration_date"})
    assert first["role"] in {"Student", "Professor", "Admin"}


def test_concurrency_students_me_parallel_reads(student_account: dict[str, str]) -> None:
    results = _parallel_get(
        path="/api/v1/students/me",
        token=student_account["token"],
        total=CONCURRENCY_REQUESTS,
        workers=CONCURRENCY_WORKERS,
    )

    statuses = [status_code for status_code, _ in results]
    latencies = [elapsed_ms for _, elapsed_ms in results]

    assert len(results) == CONCURRENCY_REQUESTS
    assert all(code == 200 for code in statuses), f"Statuses inesperados: {statuses}"
    assert max(latencies) < (TIMEOUT * 1000.0), f"Timeout percebido em burst: max={max(latencies):.2f}ms"


def test_concurrency_students_exercises_parallel_reads(student_account: dict[str, str]) -> None:
    results = _parallel_get(
        path="/api/v1/students/exercises?limit=5",
        token=student_account["token"],
        total=CONCURRENCY_REQUESTS,
        workers=CONCURRENCY_WORKERS,
    )

    statuses = [status_code for status_code, _ in results]
    assert all(code == 200 for code in statuses), f"Statuses inesperados: {statuses}"


def test_concurrency_mixed_role_reads(
    student_account: dict[str, str],
    professor_account: dict[str, str],
    admin_account: dict[str, str],
) -> None:
    tasks = [
        ("/api/v1/students/me", student_account["token"]),
        ("/api/v1/students/course-units", student_account["token"]),
        ("/api/v1/professors/requests", professor_account["token"]),
        ("/api/v1/professors/exercises?limit=5", professor_account["token"]),
        ("/api/v1/admin/users", admin_account["token"]),
        ("/api/v1/admin/course-units", admin_account["token"]),
    ]

    results: list[int] = []
    with ThreadPoolExecutor(max_workers=CONCURRENCY_WORKERS) as executor:
        futures = [
            executor.submit(_request, "GET", path, token=token)
            for path, token in tasks * max(1, CONCURRENCY_REQUESTS // len(tasks))
        ]
        for future in as_completed(futures):
            results.append(future.result().status_code)

    assert results
    assert all(code == 200 for code in results), f"Falhas em concorrencia mista: {results}"


def test_load_health_endpoint() -> None:
    results = _sequential_get(path="/health", token=None, total=LOAD_REQUESTS)
    statuses = [status_code for status_code, _ in results]
    latencies = [elapsed_ms for _, elapsed_ms in results]

    success_rate = (sum(1 for code in statuses if code == 200) / len(statuses)) * 100.0
    mean_ms = statistics.mean(latencies)
    p95_ms = _percentile_ms(latencies, 0.95)

    assert success_rate == 100.0, (
        f"Load /health com erros: success_rate={success_rate:.1f}% "
        f"mean={mean_ms:.2f}ms p95={p95_ms:.2f}ms"
    )
    assert p95_ms <= LOAD_MAX_P95_MS, (
        f"p95 acima do limite em /health: p95={p95_ms:.2f}ms limite={LOAD_MAX_P95_MS:.2f}ms"
    )


def test_load_authenticated_students_course_units_endpoint(student_account: dict[str, str]) -> None:
    results = _sequential_get(
        path="/api/v1/students/course-units",
        token=student_account["token"],
        total=LOAD_REQUESTS,
    )
    statuses = [status_code for status_code, _ in results]
    latencies = [elapsed_ms for _, elapsed_ms in results]

    success_rate = (sum(1 for code in statuses if code == 200) / len(statuses)) * 100.0
    mean_ms = statistics.mean(latencies)
    p95_ms = _percentile_ms(latencies, 0.95)

    assert success_rate == 100.0, (
        f"Load students/course-units com erros: success_rate={success_rate:.1f}% "
        f"mean={mean_ms:.2f}ms p95={p95_ms:.2f}ms"
    )
    assert p95_ms <= LOAD_MAX_P95_MS, (
        f"p95 acima do limite em students/course-units: p95={p95_ms:.2f}ms limite={LOAD_MAX_P95_MS:.2f}ms"
    )


def test_admin_course_unit_crud(admin_account: dict[str, str]) -> None:
    temp_uc_id = 80000 + (uuid.uuid4().int % 10000)
    create_payload = {
        "id_uc": temp_uc_id,
        "name": f"UC Smoke {temp_uc_id}",
        "semester": "2S",
        "curricular_year": 3,
    }

    created = _request(
        "POST",
        "/api/v1/admin/course-units",
        token=admin_account["token"],
        json=create_payload,
    )
    assert created.status_code == 201, created.text
    created_data = created.json()
    assert created_data["id_uc"] == temp_uc_id

    duplicate = _request(
        "POST",
        "/api/v1/admin/course-units",
        token=admin_account["token"],
        json=create_payload,
    )
    assert duplicate.status_code == 409

    empty_patch = _request(
        "PATCH",
        f"/api/v1/admin/course-units/{temp_uc_id}",
        token=admin_account["token"],
        json={},
    )
    assert empty_patch.status_code == 400

    patched = _request(
        "PATCH",
        f"/api/v1/admin/course-units/{temp_uc_id}",
        token=admin_account["token"],
        json={"name": f"UC Smoke Updated {temp_uc_id}"},
    )
    assert patched.status_code == 200, patched.text
    assert patched.json()["name"].startswith("UC Smoke Updated")

    deleted = _request(
        "DELETE",
        f"/api/v1/admin/course-units/{temp_uc_id}",
        token=admin_account["token"],
    )
    assert deleted.status_code == 200, deleted.text

    deleted_again = _request(
        "DELETE",
        f"/api/v1/admin/course-units/{temp_uc_id}",
        token=admin_account["token"],
    )
    assert deleted_again.status_code == 404


def test_admin_cannot_delete_own_account(admin_account: dict[str, str]) -> None:
    response = _request(
        "DELETE",
        f"/api/v1/admin/users/{admin_account['user_id']}",
        token=admin_account["token"],
    )
    assert response.status_code == 400


def test_admin_endpoint_rejects_non_admin(professor_account: dict[str, str]) -> None:
    response = _request("GET", "/api/v1/admin/users", token=professor_account["token"])
    assert response.status_code == 403


def test_ai_tutor_endpoint_is_stub(student_account: dict[str, str]) -> None:
    response = _request(
        "POST",
        "/api/v1/ai-tutor/query",
        token=student_account["token"],
        json={"question": "Explica portas logicas"},
    )
    assert response.status_code == 501, response.text


def test_scale_bulk_student_parallel_login() -> None:
    accounts = [_register_account("Student") for _ in range(SCALE_BULK_USERS)]

    def _login_latency(account: dict[str, str]) -> tuple[int, float]:
        start = time.perf_counter()
        response = requests.post(
            _url("/api/v1/auth/login"),
            json={"email": account["email"], "password": account["password"]},
            timeout=TIMEOUT,
        )
        elapsed_ms = (time.perf_counter() - start) * 1000.0
        return response.status_code, elapsed_ms

    statuses: list[int] = []
    latencies: list[float] = []
    workers = max(4, min(CONCURRENCY_WORKERS * 2, SCALE_BULK_USERS))
    with ThreadPoolExecutor(max_workers=workers) as executor:
        futures = [executor.submit(_login_latency, account) for account in accounts]
        for future in as_completed(futures):
            status_code, elapsed_ms = future.result()
            statuses.append(status_code)
            latencies.append(elapsed_ms)

    p95_ms = _percentile_ms(latencies, 0.95)
    assert statuses and all(code == 200 for code in statuses), f"Falhas no login em lote: {statuses}"
    assert p95_ms <= SCALE_LOGIN_MAX_P95_MS, (
        f"Login em lote acima do p95 esperado: p95={p95_ms:.2f}ms limite={SCALE_LOGIN_MAX_P95_MS:.2f}ms"
    )


def test_scale_parallel_cookie_sessions() -> None:
    accounts = [_register_account("Student") for _ in range(max(8, SCALE_BULK_USERS // 2))]

    def _session_roundtrip(account: dict[str, str]) -> tuple[int, int, float]:
        session = requests.Session()
        start = time.perf_counter()
        login = session.post(
            _url("/api/v1/auth/login"),
            json={"email": account["email"], "password": account["password"]},
            timeout=TIMEOUT,
        )
        me = session.get(_url("/api/v1/auth/me"), timeout=TIMEOUT)
        elapsed_ms = (time.perf_counter() - start) * 1000.0
        return login.status_code, me.status_code, elapsed_ms

    login_codes: list[int] = []
    me_codes: list[int] = []
    latencies: list[float] = []
    workers = max(4, min(CONCURRENCY_WORKERS * 2, len(accounts)))
    with ThreadPoolExecutor(max_workers=workers) as executor:
        futures = [executor.submit(_session_roundtrip, account) for account in accounts]
        for future in as_completed(futures):
            login_code, me_code, elapsed_ms = future.result()
            login_codes.append(login_code)
            me_codes.append(me_code)
            latencies.append(elapsed_ms)

    assert login_codes and all(code == 200 for code in login_codes), f"Login cookie falhou: {login_codes}"
    assert me_codes and all(code == 200 for code in me_codes), f"Sessao cookie /me falhou: {me_codes}"
    assert max(latencies) < (TIMEOUT * 1000.0), f"Timeout em roundtrip cookie: max={max(latencies):.2f}ms"


def test_scale_parallel_admin_user_queries(admin_account: dict[str, str], student_account: dict[str, str]) -> None:
    query_paths = [
        "/api/v1/admin/users",
        "/api/v1/admin/users?role=Student",
        "/api/v1/admin/users?status=Active",
        f"/api/v1/admin/users?q={student_account['email']}",
    ]

    def _query(path: str) -> tuple[int, float]:
        start = time.perf_counter()
        response = _request("GET", path, token=admin_account["token"])
        elapsed_ms = (time.perf_counter() - start) * 1000.0
        return response.status_code, elapsed_ms

    tasks = [query_paths[idx % len(query_paths)] for idx in range(SCALE_ADMIN_QUERY_ROUNDS)]
    statuses: list[int] = []
    latencies: list[float] = []
    workers = max(4, min(CONCURRENCY_WORKERS * 2, len(tasks)))
    with ThreadPoolExecutor(max_workers=workers) as executor:
        futures = [executor.submit(_query, path) for path in tasks]
        for future in as_completed(futures):
            status_code, elapsed_ms = future.result()
            statuses.append(status_code)
            latencies.append(elapsed_ms)

    p95_ms = _percentile_ms(latencies, 0.95)
    assert statuses and all(code == 200 for code in statuses), f"Falhas em queries admin paralelas: {statuses}"
    assert p95_ms <= LOAD_MAX_P95_MS, (
        f"Admin queries paralelas acima do p95 esperado: p95={p95_ms:.2f}ms limite={LOAD_MAX_P95_MS:.2f}ms"
    )
