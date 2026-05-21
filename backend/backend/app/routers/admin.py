from datetime import datetime
from uuid import UUID

from fastapi import APIRouter, Depends, HTTPException, Query, status
from sqlalchemy import delete, func, or_, select, text
from sqlalchemy.orm import joinedload
from sqlalchemy.ext.asyncio import AsyncSession

from app.database import get_db
from app.models import Admin_Audit_Log, Base_User, Course_Unit, Exercise, Professor_UC, Request, Student_UC, Teaching_Material, Topic
from app.models.enums import RequestStatus, RequestType, UserRole, UserStatus
from app.routers.deps import require_roles
from app.schemas.academic import (
    CourseUnitCreateRequest,
    CourseUnitProfessorInfo,
    CourseUnitResponse,
    CourseUnitUpdateRequest,
)
from app.schemas.admin import AdminDecisionRequest, AdminRequestResponse, ProfessorBasicInfo, AdminBasicInfo
from app.schemas.user import MessageResponse, UserResponse, UserUpdateRequest

router = APIRouter(prefix="/api/v1/admin", tags=["admin"])


def to_user_response(user: Base_User) -> UserResponse:
    return UserResponse(
        id=user.ID_User,
        name=user.Name,
        email=user.Email,
        role=user.Role,
        status=user.Status,
        registration_date=user.Registration_Date,
    )


def to_course_unit_response(item: Course_Unit) -> CourseUnitResponse:
    professors = []
    for relation in sorted(
        [link for link in (item.professor_ucs or []) if link.professor],
        key=lambda link: link.professor.Name.lower(),
    ):
        professors.append(
            CourseUnitProfessorInfo(
                id=relation.professor.ID_User,
                name=relation.professor.Name,
                email=relation.professor.Email,
            )
        )

    return CourseUnitResponse(
        id_uc=item.ID_UC,
        name=item.Name,
        semester=item.Semester,
        curricular_year=item.Curricular_Year,
        professors=professors,
        student_count=len(item.student_ucs) if item.student_ucs else 0,
    )


async def _sync_course_unit_professors(
    *,
    db: AsyncSession,
    id_uc: int,
    professor_ids: list[UUID],
) -> None:
    normalized_professor_ids = list(dict.fromkeys(professor_ids))

    if normalized_professor_ids:
        valid_professor_ids = set(
            (
                await db.scalars(
                    select(Base_User.ID_User).where(
                        Base_User.ID_User.in_(normalized_professor_ids),
                        Base_User.Role == UserRole.PROFESSOR,
                    )
                )
            ).all()
        )

        missing_ids = [str(prof_id) for prof_id in normalized_professor_ids if prof_id not in valid_professor_ids]
        if missing_ids:
            raise HTTPException(
                status_code=status.HTTP_400_BAD_REQUEST,
                detail=f"IDs de professor inválidos: {', '.join(missing_ids)}",
            )

    await db.execute(delete(Professor_UC).where(Professor_UC.ID_UC == id_uc))

    for professor_id in normalized_professor_ids:
        db.add(Professor_UC(ID_UC=id_uc, ID_Professor=professor_id))


def to_admin_request_response(item: Request) -> AdminRequestResponse:
    response = AdminRequestResponse(
        id_request=item.ID_Request,
        id_professor=item.ID_Professor,
        id_admin=item.ID_Admin,
        request_type=item.Request_Type,
        title=item.Title,
        description=item.Description,
        status=item.Status,
        admin_comment=item.AdminComment,
        creation_date=item.Creation_Date,
        resolution_date=item.Resolution_Date,
    )

    if item.professor:
        response.professor_info = ProfessorBasicInfo(
            id=item.professor.ID_User,
            name=item.professor.Name,
            email=item.professor.Email,
        )
    if item.admin:
        response.admin_info = AdminBasicInfo(
            id=item.admin.ID_User,
            name=item.admin.Name,
            email=item.admin.Email,
        )

    return response


@router.get("/users", response_model=list[UserResponse])
async def list_users(
    role: UserRole | None = Query(default=None),
    status_filter: UserStatus | None = Query(default=None, alias="status"),
    q: str | None = Query(default=None),
    db: AsyncSession = Depends(get_db),
    current_admin: Base_User = Depends(require_roles(UserRole.ADMIN)),
):
    stmt = select(Base_User)

    if role:
        stmt = stmt.where(Base_User.Role == role)
    if status_filter:
        stmt = stmt.where(Base_User.Status == status_filter)
    if q:
        pattern = f"%{q.lower()}%"
        stmt = stmt.where(
            or_(
                func.lower(Base_User.Name).like(pattern),
                func.lower(Base_User.Email).like(pattern),
            )
        )

    users = (await db.scalars(stmt.order_by(Base_User.Registration_Date.desc()))).all()
    return [to_user_response(user) for user in users]


@router.patch("/users/{user_id}", response_model=UserResponse)
async def update_user(
    user_id: UUID,
    payload: UserUpdateRequest,
    db: AsyncSession = Depends(get_db),
    current_admin: Base_User = Depends(require_roles(UserRole.ADMIN)),
):
    user = await db.scalar(select(Base_User).where(Base_User.ID_User == user_id))
    if not user:
        raise HTTPException(status_code=status.HTTP_404_NOT_FOUND, detail="Utilizador não encontrado")

    if payload.name is None and payload.status is None and payload.role is None:
        raise HTTPException(status_code=status.HTTP_400_BAD_REQUEST, detail="Nenhuma alteração a efetuar")

    if payload.name is not None:
        user.Name = payload.name
    if payload.status is not None:
        user.Status = payload.status

    if payload.role is not None and payload.role != user.Role:
        if user.Role == UserRole.ADMIN:
            raise HTTPException(status_code=status.HTTP_400_BAD_REQUEST, detail="Não é possível alterar o role de um administrador")
        if payload.role == UserRole.ADMIN:
            raise HTTPException(status_code=status.HTTP_400_BAD_REQUEST, detail="Não é possível promover a administrador")

        if user.Role == UserRole.STUDENT:
            await db.execute(text("DELETE FROM student WHERE id_student = :id"), {"id": user.ID_User})
        elif user.Role == UserRole.PROFESSOR:
            await db.execute(text("DELETE FROM professor WHERE id_professor = :id"), {"id": user.ID_User})

        if payload.role == UserRole.STUDENT:
            await db.execute(text("INSERT INTO student (id_student, current_level, total_xp, streak_days) VALUES (:id, 1, 0, 0)"), {"id": user.ID_User})
        elif payload.role == UserRole.PROFESSOR:
            await db.execute(text("INSERT INTO professor (id_professor) VALUES (:id)"), {"id": user.ID_User})

        await db.execute(text("UPDATE base_user SET role = :role WHERE id_user = :id"), {"role": payload.role.value, "id": user.ID_User})
        user.Role = payload.role

    db.add(
        Admin_Audit_Log(
            ID_Admin=current_admin.ID_User,
            Action="UPDATE_USER",
            Target_ID=str(user.ID_User),
            Target_Type="Base_User",
        )
    )
    await db.flush()
    return UserResponse(
        id=user.ID_User,
        name=user.Name,
        email=user.Email,
        role=user.Role,
        status=user.Status,
        registration_date=user.Registration_Date,
    )


@router.delete("/users/{user_id}", response_model=MessageResponse)
async def delete_user(
    user_id: UUID,
    db: AsyncSession = Depends(get_db),
    current_admin: Base_User = Depends(require_roles(UserRole.ADMIN)),
):
    user = await db.scalar(select(Base_User).where(Base_User.ID_User == user_id))
    if not user:
        raise HTTPException(status_code=status.HTTP_404_NOT_FOUND, detail="Utilizador não encontrado")

    if user.ID_User == current_admin.ID_User:
        raise HTTPException(status_code=status.HTTP_400_BAD_REQUEST, detail="Não é possível eliminar a sua própria conta de administrador")

    db.add(
        Admin_Audit_Log(
            ID_Admin=current_admin.ID_User,
            Action="DELETE_USER",
            Target_ID=str(user.ID_User),
            Target_Type="Base_User",
        )
    )
    await db.delete(user)
    return MessageResponse(message="User deleted")


@router.get("/course-units", response_model=list[CourseUnitResponse])
async def list_course_units(
    db: AsyncSession = Depends(get_db),
    current_admin: Base_User = Depends(require_roles(UserRole.ADMIN)),
):
    result = await db.execute(
        select(Course_Unit)
        .options(
            joinedload(Course_Unit.professor_ucs).joinedload(Professor_UC.professor),
            joinedload(Course_Unit.student_ucs),
        )
        .order_by(Course_Unit.Name.asc())
    )
    items = result.unique().scalars().all()
    return [to_course_unit_response(item) for item in items]


@router.post("/course-units", response_model=CourseUnitResponse, status_code=status.HTTP_201_CREATED)
async def create_course_unit(
    payload: CourseUnitCreateRequest,
    db: AsyncSession = Depends(get_db),
    current_admin: Base_User = Depends(require_roles(UserRole.ADMIN)),
):
    exists = await db.scalar(select(Course_Unit).where(Course_Unit.ID_UC == payload.id_uc))
    if exists:
        raise HTTPException(status_code=status.HTTP_409_CONFLICT, detail="Unidade curricular já existe")

    item = Course_Unit(
        ID_UC=payload.id_uc,
        Name=payload.name,
        Semester=payload.semester,
        Curricular_Year=payload.curricular_year,
    )
    db.add(item)
    db.add(
        Admin_Audit_Log(
            ID_Admin=current_admin.ID_User,
            Action="CREATE_COURSE_UNIT",
            Target_ID=str(payload.id_uc),
            Target_Type="Course_Unit",
        )
    )
    await db.flush()

    await _sync_course_unit_professors(db=db, id_uc=item.ID_UC, professor_ids=payload.professor_ids)
    await db.flush()

    created = await db.scalar(
        select(Course_Unit)
        .options(joinedload(Course_Unit.professor_ucs).joinedload(Professor_UC.professor))
        .where(Course_Unit.ID_UC == item.ID_UC)
    )
    return to_course_unit_response(created)


@router.patch("/course-units/{id_uc}", response_model=CourseUnitResponse)
async def update_course_unit(
    id_uc: int,
    payload: CourseUnitUpdateRequest,
    db: AsyncSession = Depends(get_db),
    current_admin: Base_User = Depends(require_roles(UserRole.ADMIN)),
):
    item = await db.scalar(select(Course_Unit).where(Course_Unit.ID_UC == id_uc))
    if not item:
        raise HTTPException(status_code=status.HTTP_404_NOT_FOUND, detail="Unidade curricular não encontrada")

    if payload.name is None and payload.semester is None and payload.curricular_year is None and payload.professor_ids is None:
        raise HTTPException(status_code=status.HTTP_400_BAD_REQUEST, detail="Nenhuma alteração a efetuar")

    if payload.name is not None:
        item.Name = payload.name
    if payload.semester is not None:
        item.Semester = payload.semester
    if payload.curricular_year is not None:
        item.Curricular_Year = payload.curricular_year
    if payload.professor_ids is not None:
        await _sync_course_unit_professors(db=db, id_uc=id_uc, professor_ids=payload.professor_ids)

    db.add(
        Admin_Audit_Log(
            ID_Admin=current_admin.ID_User,
            Action="UPDATE_COURSE_UNIT",
            Target_ID=str(id_uc),
            Target_Type="Course_Unit",
        )
    )
    await db.flush()

    updated = await db.scalar(
        select(Course_Unit)
        .options(joinedload(Course_Unit.professor_ucs).joinedload(Professor_UC.professor))
        .where(Course_Unit.ID_UC == id_uc)
    )
    return to_course_unit_response(updated)


@router.delete("/course-units/{id_uc}", response_model=MessageResponse)
async def delete_course_unit(
    id_uc: int,
    db: AsyncSession = Depends(get_db),
    current_admin: Base_User = Depends(require_roles(UserRole.ADMIN)),
):
    item = await db.scalar(select(Course_Unit).where(Course_Unit.ID_UC == id_uc))
    if not item:
        raise HTTPException(status_code=status.HTTP_404_NOT_FOUND, detail="Unidade curricular não encontrada")

    db.add(
        Admin_Audit_Log(
            ID_Admin=current_admin.ID_User,
            Action="DELETE_COURSE_UNIT",
            Target_ID=str(id_uc),
            Target_Type="Course_Unit",
        )
    )

    # Apagar pela ordem correta para respeitar as FK constraints:
    # 1. Exercícios (referenciam Topic e Teaching_Material)
    await db.execute(delete(Exercise).where(Exercise.ID_UC == id_uc))
    # 2. Tópicos (PK composta com ID_UC — não pode ficar a NULL)
    await db.execute(delete(Topic).where(Topic.ID_UC == id_uc))
    # 3. Materiais de ensino
    await db.execute(delete(Teaching_Material).where(Teaching_Material.ID_UC == id_uc))
    # 4. Associações professor-UC e aluno-UC
    await db.execute(delete(Professor_UC).where(Professor_UC.ID_UC == id_uc))
    await db.execute(delete(Student_UC).where(Student_UC.ID_UC == id_uc))
    # 5. Finalmente a UC
    await db.delete(item)

    return MessageResponse(message="Course unit deleted")


@router.get("/requests", response_model=list[AdminRequestResponse])
async def list_requests(
    status_filter: RequestStatus | None = Query(default=None, alias="status"),
    db: AsyncSession = Depends(get_db),
    current_admin: Base_User = Depends(require_roles(UserRole.ADMIN)),
):
    stmt = (
        select(Request)
        .options(
            joinedload(Request.professor),
            joinedload(Request.admin)
        )
        .order_by(Request.Creation_Date.desc())
    )

    if status_filter:
        stmt = stmt.where(Request.Status == status_filter)

    items = (await db.scalars(stmt)).all()

    return [to_admin_request_response(item) for item in items]


@router.patch("/requests/{request_id}/decision", response_model=AdminRequestResponse)
async def decide_request(
    request_id: int,
    payload: AdminDecisionRequest,
    db: AsyncSession = Depends(get_db),
    current_admin: Base_User = Depends(require_roles(UserRole.ADMIN)),
):
    stmt = (
        select(Request)
        .options(joinedload(Request.professor), joinedload(Request.admin))
        .where(Request.ID_Request == request_id)
    )
    item = await db.scalar(stmt)

    if not item:
        raise HTTPException(status_code=status.HTTP_404_NOT_FOUND, detail="Pedido não encontrado")

    if item.Status != RequestStatus.PENDING:
        raise HTTPException(status_code=status.HTTP_400_BAD_REQUEST, detail="Este pedido já foi decidido")

    item.Status = payload.status
    item.AdminComment = payload.admin_comment
    item.ID_Admin = current_admin.ID_User
    item.Resolution_Date = datetime.now()

    if item.Request_Type == RequestType.ACCESS and item.professor:
        if payload.status == RequestStatus.APPROVED:
            item.professor.Status = UserStatus.ACTIVE
        elif payload.status == RequestStatus.REJECTED:
            item.professor.Status = UserStatus.DEACTIVATED

    db.add(
        Admin_Audit_Log(
            ID_Admin=current_admin.ID_User,
            Action="DECIDE_REQUEST",
            Target_ID=str(request_id),
            Target_Type="Request",
        )
    )
    await db.flush()
    await db.refresh(item, attribute_names=['admin'])

    return to_admin_request_response(item)