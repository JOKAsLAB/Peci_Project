from datetime import datetime
from uuid import UUID

from fastapi import APIRouter, Depends, HTTPException, Query, status
from sqlalchemy import func, or_, select
from sqlalchemy.ext.asyncio import AsyncSession

from app.database import get_db
from app.models import Admin_Audit_Log, Base_User, Course_Unit, Request
from app.routers.deps import require_roles
from app.schemas.academic import (
	CourseUnitCreateRequest,
	CourseUnitResponse,
	CourseUnitUpdateRequest,
)
from app.schemas.admin import AdminDecisionRequest, AdminRequestResponse
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


def to_course_response(course: Course_Unit) -> CourseUnitResponse:
	return CourseUnitResponse(
		id_uc=course.ID_UC,
		name=course.Name,
		semester=course.Semester,
		curricular_year=course.Curricular_Year,
	)


def to_admin_request_response(item: Request) -> AdminRequestResponse:
	return AdminRequestResponse(
		id_request=item.ID_Request,
		id_professor=item.ID_Professor,
		id_admin=item.ID_Admin,
		title=item.Title,
		description=item.Description,
		status=item.Status,
		admin_comment=item.AdminComment,
		creation_date=item.Creation_Date,
		resolution_date=item.Resolution_Date,
	)


@router.get("/users", response_model=list[UserResponse])
async def list_users(
	role: str | None = Query(default=None),
	status_filter: str | None = Query(default=None, alias="status"),
	q: str | None = Query(default=None),
	db: AsyncSession = Depends(get_db),
	current_admin: Base_User = Depends(require_roles("Admin")),
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
	current_admin: Base_User = Depends(require_roles("Admin")),
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
	current_admin: Base_User = Depends(require_roles("Admin")),
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
	current_admin: Base_User = Depends(require_roles("Admin")),
):
	items = (await db.scalars(select(Course_Unit).order_by(Course_Unit.Name.asc()))).all()
	return [to_course_response(item) for item in items]


@router.post("/course-units", response_model=CourseUnitResponse, status_code=status.HTTP_201_CREATED)
async def create_course_unit(
	payload: CourseUnitCreateRequest,
	db: AsyncSession = Depends(get_db),
	current_admin: Base_User = Depends(require_roles("Admin")),
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
	return to_course_response(item)


@router.patch("/course-units/{id_uc}", response_model=CourseUnitResponse)
async def update_course_unit(
	id_uc: int,
	payload: CourseUnitUpdateRequest,
	db: AsyncSession = Depends(get_db),
	current_admin: Base_User = Depends(require_roles("Admin")),
):
	item = await db.scalar(select(Course_Unit).where(Course_Unit.ID_UC == id_uc))
	if not item:
		raise HTTPException(status_code=status.HTTP_404_NOT_FOUND, detail="Course unit not found")

	if payload.name is None and payload.semester is None and payload.curricular_year is None:
		raise HTTPException(status_code=status.HTTP_400_BAD_REQUEST, detail="Nothing to update")

	if payload.name is not None:
		item.Name = payload.name
	if payload.semester is not None:
		item.Semester = payload.semester
	if payload.curricular_year is not None:
		item.Curricular_Year = payload.curricular_year

	db.add(
		Admin_Audit_Log(
			ID_Admin=current_admin.ID_User,
			Action="UPDATE_COURSE_UNIT",
			Target_ID=str(id_uc),
			Target_Type="Course_Unit",
		)
	)
	await db.flush()
	return to_course_response(item)


@router.delete("/course-units/{id_uc}", response_model=MessageResponse)
async def delete_course_unit(
	id_uc: int,
	db: AsyncSession = Depends(get_db),
	current_admin: Base_User = Depends(require_roles("Admin")),
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
	await db.delete(item)
	return MessageResponse(message="Course unit deleted")


@router.get("/requests", response_model=list[AdminRequestResponse])
async def list_requests(
	status_filter: str | None = Query(default=None, alias="status"),
	db: AsyncSession = Depends(get_db),
	current_admin: Base_User = Depends(require_roles("Admin")),
):
	stmt = select(Request).order_by(Request.Creation_Date.desc())
	if status_filter:
		stmt = stmt.where(Request.Status == status_filter)
	items = (await db.scalars(stmt)).all()
	return [to_admin_request_response(item) for item in items]


@router.patch("/requests/{request_id}/decision", response_model=AdminRequestResponse)
async def decide_request(
	request_id: int,
	payload: AdminDecisionRequest,
	db: AsyncSession = Depends(get_db),
	current_admin: Base_User = Depends(require_roles("Admin")),
):
	item = await db.scalar(select(Request).where(Request.ID_Request == request_id))
	if not item:
		raise HTTPException(status_code=status.HTTP_404_NOT_FOUND, detail="Request not found")

	if item.Status != "pending":
		raise HTTPException(status_code=status.HTTP_400_BAD_REQUEST, detail="Request already decided")

	item.Status = payload.status
	item.AdminComment = payload.admin_comment
	item.ID_Admin = current_admin.ID_User
	item.Resolution_Date = datetime.now()

	db.add(
		Admin_Audit_Log(
			ID_Admin=current_admin.ID_User,
			Action="DECIDE_REQUEST",
			Target_ID=str(request_id),
			Target_Type="Request",
		)
	)
	await db.flush()
	return to_admin_request_response(item)