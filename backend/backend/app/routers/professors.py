from fastapi import APIRouter, Depends, HTTPException, Query, status
from sqlalchemy import and_, select
from sqlalchemy.ext.asyncio import AsyncSession

from app.database import get_db
from app.models import (
	Base_User,
	Course_Unit,
	Exercise,
	Professor_UC,
	Request,
	Teaching_Material,
	Topic,
)
from app.models.enums import RequestStatus
from app.routers.deps import require_roles
from app.schemas.academic import (
	CourseUnitResponse,
	ExerciseCreateRequest,
	ExerciseResponse,
	MaterialCreateRequest,
	MaterialResponse,
)
from app.schemas.admin import AdminRequestResponse, ProfessorRequestCreateRequest

router = APIRouter(prefix="/api/v1/professors", tags=["professors"])


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


def to_material_response(item: Teaching_Material) -> MaterialResponse:
	return MaterialResponse(
		id_material=item.ID_Material,
		id_uc=item.ID_UC,
		id_professor=item.ID_Professor,
		status=item.Status,
		title=item.Title,
		file_path=item.File_Path,
		extracted_text=item.Extracted_Text,
		upload_date=item.Upload_Date,
	)


def to_request_response(item: Request) -> AdminRequestResponse:
	return AdminRequestResponse(
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


@router.get("/course-units", response_model=list[CourseUnitResponse])
async def list_my_course_units(
	db: AsyncSession = Depends(get_db),
	current_professor: Base_User = Depends(require_roles("Professor")),
):
	stmt = (
		select(Course_Unit)
		.join(Professor_UC, Professor_UC.ID_UC == Course_Unit.ID_UC)
		.where(Professor_UC.ID_Professor == current_professor.ID_User)
		.order_by(Course_Unit.Name.asc())
	)
	items = (await db.scalars(stmt)).all()
	return [to_course_response(item) for item in items]


@router.get("/exercises", response_model=list[ExerciseResponse])
async def list_my_exercises(
	id_uc: int | None = Query(default=None),
	topic_name: str | None = Query(default=None),
	difficulty: str | None = Query(default=None),
	type_filter: str | None = Query(default=None, alias="type"),
	limit: int = Query(default=100, ge=1, le=500),
	offset: int = Query(default=0, ge=0),
	db: AsyncSession = Depends(get_db),
	current_professor: Base_User = Depends(require_roles("Professor")),
):
	allowed_ucs = select(Professor_UC.ID_UC).where(Professor_UC.ID_Professor == current_professor.ID_User)

	stmt = select(Exercise).where(Exercise.ID_UC.in_(allowed_ucs))
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


@router.post("/exercises", response_model=ExerciseResponse, status_code=status.HTTP_201_CREATED)
async def create_exercise(
	payload: ExerciseCreateRequest,
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
		raise HTTPException(status_code=status.HTTP_403_FORBIDDEN, detail="You are not assigned to this course unit")

	topic_exists = await db.scalar(
		select(Topic).where(and_(Topic.ID_UC == payload.id_uc, Topic.Name == payload.topic_name))
	)
	if not topic_exists:
		raise HTTPException(status_code=status.HTTP_404_NOT_FOUND, detail="Topic not found for this course unit")

	item = Exercise(
		ID_UC=payload.id_uc,
		Topic_Name=payload.topic_name,
		Material_Ref=payload.material_ref,
		Type=payload.type,
		Question=payload.question,
		Solution=payload.solution,
		Difficulty=payload.difficulty,
		Explanation=payload.explanation,
	)
	db.add(item)
	await db.flush()
	return to_exercise_response(item)


@router.get("/materials", response_model=list[MaterialResponse])
async def list_my_materials(
	id_uc: int | None = Query(default=None),
	db: AsyncSession = Depends(get_db),
	current_professor: Base_User = Depends(require_roles("Professor")),
):
	stmt = select(Teaching_Material).where(Teaching_Material.ID_Professor == current_professor.ID_User)
	if id_uc is not None:
		stmt = stmt.where(Teaching_Material.ID_UC == id_uc)
	stmt = stmt.order_by(Teaching_Material.Upload_Date.desc())
	items = (await db.scalars(stmt)).all()
	return [to_material_response(item) for item in items]


@router.post("/materials", response_model=MaterialResponse, status_code=status.HTTP_201_CREATED)
async def create_material(
	payload: MaterialCreateRequest,
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
		raise HTTPException(status_code=status.HTTP_403_FORBIDDEN, detail="You are not assigned to this course unit")

	item = Teaching_Material(
		ID_UC=payload.id_uc,
		ID_Professor=current_professor.ID_User,
		Status="Pending",
		Title=payload.title,
		File_Path=payload.file_path,
		Extracted_Text=payload.extracted_text,
	)
	db.add(item)
	await db.flush()
	return to_material_response(item)


@router.get("/requests", response_model=list[AdminRequestResponse])
async def list_my_admin_requests(
	db: AsyncSession = Depends(get_db),
	current_professor: Base_User = Depends(require_roles("Professor")),
):
	stmt = (
		select(Request)
		.where(Request.ID_Professor == current_professor.ID_User)
		.order_by(Request.Creation_Date.desc())
	)
	items = (await db.scalars(stmt)).all()
	return [to_request_response(item) for item in items]


@router.post("/requests", response_model=AdminRequestResponse, status_code=status.HTTP_201_CREATED)
async def create_admin_request(
	payload: ProfessorRequestCreateRequest,
	db: AsyncSession = Depends(get_db),
	current_professor: Base_User = Depends(require_roles("Professor")),
):
	item = Request(
		ID_Professor=current_professor.ID_User,
		Request_Type=payload.request_type,
		Title=payload.title,
		Description=payload.description,
		Status=RequestStatus.PENDING,
	)
	db.add(item)
	await db.flush()
	return to_request_response(item)