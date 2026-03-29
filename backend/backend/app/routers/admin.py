from datetime import datetime
from uuid import UUID

from fastapi import APIRouter, Depends, HTTPException, Query, status
from sqlalchemy import delete, func, or_, select
from sqlalchemy.orm import joinedload
from sqlalchemy.ext.asyncio import AsyncSession

from app.database import get_db
from app.models import Admin_Audit_Log, Base_User, Course_Unit, Professor_UC, Request
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
                detail=f"Invalid professor IDs: {', '.join(missing_ids)}",
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
        raise HTTPException(status_code=status.HTTP_404_NOT_FOUND, detail="User not found")

    if payload.name is None and payload.status is None:
        raise HTTPException(status_code=status.HTTP_400_BAD_REQUEST, detail="Nothing to update")

    if payload.name is not None:
        user.Name = payload.name
    if payload.status is not None:
        user.Status = payload.status

    db.add(
        Admin_Audit_Log(
            ID_Admin=current_admin.ID_User,
            Action="UPDATE_USER",
            Target_ID=str(user.ID_User),
            Target_Type="Base_User",
        )
    )
    await db.flush()
    return to_user_response(user)


@router.delete("/users/{user_id}", response_model=MessageResponse)
async def delete_user(
    user_id: UUID,
    db: AsyncSession = Depends(get_db),
    current_admin: Base_User = Depends(require_roles(UserRole.ADMIN)),
):
    user = await db.scalar(select(Base_User).where(Base_User.ID_User == user_id))
    if not user:
        raise HTTPException(status_code=status.HTTP_404_NOT_FOUND, detail="User not found")

    if user.ID_User == current_admin.ID_User:
        raise HTTPException(status_code=status.HTTP_400_BAD_REQUEST, detail="Cannot delete your own admin account")

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
        .options(joinedload(Course_Unit.professor_ucs).joinedload(Professor_UC.professor))
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
        raise HTTPException(status_code=status.HTTP_409_CONFLICT, detail="Course unit already exists")

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
        raise HTTPException(status_code=status.HTTP_404_NOT_FOUND, detail="Course unit not found")

    if payload.name is None and payload.semester is None and payload.curricular_year is None and payload.professor_ids is None:
        raise HTTPException(status_code=status.HTTP_400_BAD_REQUEST, detail="Nothing to update")

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
        raise HTTPException(status_code=status.HTTP_404_NOT_FOUND, detail="Course unit not found")

    db.add(
        Admin_Audit_Log(
            ID_Admin=current_admin.ID_User,
            Action="DELETE_COURSE_UNIT",
            Target_ID=str(id_uc),
            Target_Type="Course_Unit",
        )
    )
    await db.execute(delete(Professor_UC).where(Professor_UC.ID_UC == id_uc))
    await db.delete(item)
    return MessageResponse(message="Course unit deleted")


@router.get("/requests", response_model=list[AdminRequestResponse])
async def list_requests(
    status_filter: RequestStatus | None = Query(default=None, alias="status"),
    db: AsyncSession = Depends(get_db),
    current_admin: Base_User = Depends(require_roles(UserRole.ADMIN)),
):
    # Otimização: Eager loading das relações professor e admin para preencher o DTO sem queries iterativas
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
        raise HTTPException(status_code=status.HTTP_404_NOT_FOUND, detail="Request not found")

    if item.Status != RequestStatus.PENDING:
        raise HTTPException(status_code=status.HTTP_400_BAD_REQUEST, detail="Request already decided")

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
    # Refresca a entidade para carregar os dados do admin que acabou de decidir o pedido
    await db.refresh(item, attribute_names=['admin'])
    
    return to_admin_request_response(item)