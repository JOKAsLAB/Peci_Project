from collections import defaultdict
from datetime import date, datetime

from fastapi import APIRouter, Depends, HTTPException, Query, status
from sqlalchemy import and_, case, select, text, func
from sqlalchemy.ext.asyncio import AsyncSession

from app.database import get_db
from app.models import Base_User, Course_Unit, Exercise, Progress, Streak, Student, Student_UC, Topic
from app.routers.deps import require_roles
from app.schemas.academic import CourseUnitBasicInfo, CourseUnitResponse, ExerciseResponse
from app.schemas.gamification import (
	ProgressCreateRequest,
	ProgressResponse,
	StreakResponse,
	StudentProfileResponse,
)

router = APIRouter(prefix="/api/v1/students", tags=["students"])


# =============================================================
# HELPERS
# =============================================================

async def _student_uc_table_exists(db: AsyncSession) -> bool:
	"""Compatibility gate: environments without migrations should still serve students endpoints."""
	result = await db.scalar(text("SELECT to_regclass('public.student_uc')"))
	return result is not None


DIFFICULTY_ORDER = case(
	(Exercise.Difficulty == "Easy", 1),
	(Exercise.Difficulty == "Medium", 2),
	(Exercise.Difficulty == "Hard", 3),
	else_=4,
)


def to_course_response(course: Course_Unit) -> CourseUnitResponse:
	return CourseUnitResponse(
		id_uc=course.ID_UC,
		name=course.Name,
		semester=course.Semester,
		curricular_year=course.Curricular_Year,
	)


def to_exercise_response(item: Exercise, course_unit: Course_Unit | None = None) -> ExerciseResponse:
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
		published=item.Published,
		course_unit_info=CourseUnitBasicInfo(id_uc=course_unit.ID_UC, name=course_unit.Name) if course_unit else None,
	)


XP_PER_LEVEL = 100

def _level_for_xp(total_xp: int) -> int:
	return (total_xp // XP_PER_LEVEL) + 1

def _xp_in_level(total_xp: int) -> int:
	return total_xp % XP_PER_LEVEL

def to_progress_response(item: Progress, student: Student | None = None, level_up: bool = False) -> ProgressResponse:
	new_total = student.Total_XP if student else 0
	new_level = _level_for_xp(new_total) if student else 1
	return ProgressResponse(
		id_progress=item.ID_Progress,
		id_student=item.ID_Student,
		id_exercise=item.ID_Exercise,
		attempts=item.Attempts,
		status=item.Status,
		xp_earned=item.XP_Earned,
		sync_status=item.Sync_Status,
		recorded_at=item.Record_Date,
		new_total_xp=new_total,
		new_level=new_level,
		level_up=level_up,
		streak_days=student.Streak_Days if student else 0,
	)


def to_streak_response(item: Streak) -> StreakResponse:
	return StreakResponse(
		id_streak=item.ID_Streak,
		id_student=item.ID_Student,
		log_date=item.Log_Date,
		sync_status=item.Sync_Status,
	)


async def _build_checkpoints(id_uc: int, db: AsyncSession) -> list[dict]:
	"""
	Busca tópicos e exercícios publicados de uma UC num único JOIN,
	ordenados por N_Order do tópico e depois por dificuldade.
	Espelha a lógica do router de professores.
	"""
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
	topic_exercises: dict[str, list] = defaultdict(list)

	for topic, exercise in rows:
		if topic.Name not in topic_order_map:
			topic_order_map[topic.Name] = topic.N_Order
			topic_exercises[topic.Name]  # garante que a chave existe mesmo sem exercícios

		if exercise is not None:
			topic_exercises[topic.Name].append(to_exercise_response(exercise))

	return [
		{
			"topic_name": name,
			"topic_order": topic_order_map[name],
			"exercises": [ex.model_dump() for ex in topic_exercises[name]],
		}
		for name in sorted(topic_order_map, key=lambda n: topic_order_map[n])
	]


# =============================================================
# ENDPOINTS
# =============================================================

@router.get("/me", response_model=StudentProfileResponse)
async def my_profile(
	db: AsyncSession = Depends(get_db),
	current_student: Base_User = Depends(require_roles("Student")),
):
	# with_polymorphic: "*" means current_student is already a Student instance.
	# But we do a direct query to guarantee fresh data from the current session.
	from sqlalchemy import text as raw_text
	row = await db.execute(
		raw_text(
			"SELECT current_level, total_xp, streak_days, last_access "
			"FROM student WHERE id_student = :uid"
		),
		{"uid": current_student.ID_User},
	)
	data = row.fetchone()
	if not data:
		raise HTTPException(status_code=status.HTTP_404_NOT_FOUND, detail="Student profile not found")

	total_xp = data.total_xp or 0
	return StudentProfileResponse(
		id_student=current_student.ID_User,
		name=current_student.Name,
		current_level=_level_for_xp(total_xp),
		total_xp=total_xp,
		streak_days=data.streak_days or 0,
		last_access=data.last_access,
		xp_for_next_level=XP_PER_LEVEL,
		xp_in_current_level=_xp_in_level(total_xp),
	)


@router.get("/course-units", response_model=list[CourseUnitResponse])
async def list_course_units(
	db: AsyncSession = Depends(get_db),
	current_student: Base_User = Depends(require_roles("Student")),
):
	if await _student_uc_table_exists(db):
		has_enrollment = await db.scalar(
			select(Student_UC.ID_UC)
			.where(Student_UC.ID_Student == current_student.ID_User)
			.limit(1)
		)
		if has_enrollment is not None:
			allowed_ucs = select(Student_UC.ID_UC).where(Student_UC.ID_Student == current_student.ID_User)
			items = (
				await db.scalars(
					select(Course_Unit)
					.where(Course_Unit.ID_UC.in_(allowed_ucs))
					.order_by(Course_Unit.Name.asc())
				)
			).all()
		else:
			items = (await db.scalars(select(Course_Unit).order_by(Course_Unit.Name.asc()))).all()
	else:
		items = (await db.scalars(select(Course_Unit).order_by(Course_Unit.Name.asc()))).all()
	return [to_course_response(item) for item in items]


@router.get("/exercises", response_model=list[ExerciseResponse])
async def list_exercises(
	id_uc: int | None = Query(default=None),
	topic_name: str | None = Query(default=None),
	difficulty: str | None = Query(default=None),
	type_filter: str | None = Query(default=None, alias="type"),
	limit: int = Query(default=5, ge=1, le=50),  # 50 max para queries com filtros
	offset: int = Query(default=None, ge=0),
	db: AsyncSession = Depends(get_db),
	current_student: Base_User = Depends(require_roles("Student")),
):
	# ─ Calcula o offset automaticamente apenas no modo prática sem filtros ─
	# Com filtros activos o aluno está a explorar exercícios específicos,
	# por isso o offset deve ser 0 para mostrar todos os resultados.
	if offset is None:
		has_filters = any([id_uc, topic_name, difficulty, type_filter])
		if has_filters:
			offset = 0
		else:
			today = date.today()
			stmt_count = (
				select(func.count(Progress.ID_Progress))
				.where(
					and_(
						Progress.ID_Student == current_student.ID_User,
						func.date(Progress.Record_Date) == today,
						Progress.Status == 'Correct'
					)
				)
			)
			exercises_today = await db.scalar(stmt_count)
			offset = exercises_today or 0
	
	stmt = (
		select(Exercise, Course_Unit)
		.join(Course_Unit, Exercise.ID_UC == Course_Unit.ID_UC)
		.where(Exercise.Published == True)
	)

	if await _student_uc_table_exists(db):
		has_enrollment = await db.scalar(
			select(Student_UC.ID_UC)
			.where(Student_UC.ID_Student == current_student.ID_User)
			.limit(1)
		)
		if has_enrollment is not None:
			allowed_ucs = select(Student_UC.ID_UC).where(Student_UC.ID_Student == current_student.ID_User)
			stmt = stmt.where(Exercise.ID_UC.in_(allowed_ucs))

	if id_uc is not None:
		stmt = stmt.where(Exercise.ID_UC == id_uc)
	if topic_name is not None:
		stmt = stmt.where(Exercise.Topic_Name == topic_name)
	if difficulty is not None:
		stmt = stmt.where(Exercise.Difficulty == difficulty.capitalize())
	if type_filter is not None:
		stmt = stmt.where(Exercise.Type == type_filter)

	stmt = stmt.order_by(Exercise.ID_Exercise.desc()).offset(offset).limit(limit)
	rows = (await db.execute(stmt)).all()
	return [to_exercise_response(exercise, course_unit) for exercise, course_unit in rows]


@router.post("/progress", response_model=ProgressResponse, status_code=status.HTTP_201_CREATED)
async def create_progress(
	payload: ProgressCreateRequest,
	db: AsyncSession = Depends(get_db),
	current_student: Base_User = Depends(require_roles("Student")),
):
	exercise = await db.scalar(select(Exercise).where(Exercise.ID_Exercise == payload.id_exercise))
	if not exercise:
		raise HTTPException(status_code=status.HTTP_404_NOT_FOUND, detail="Exercise not found")

	# Same enrollment pattern as list_exercises: only restrict if student has enrollments
	if await _student_uc_table_exists(db):
		has_enrollment = await db.scalar(
			select(Student_UC.ID_UC)
			.where(Student_UC.ID_Student == current_student.ID_User)
			.limit(1)
		)
		if has_enrollment is not None:
			has_access = await db.scalar(
				select(Student_UC.ID_UC).where(
					Student_UC.ID_Student == current_student.ID_User,
					Student_UC.ID_UC == exercise.ID_UC,
				)
			)
			if not has_access:
				raise HTTPException(status_code=status.HTTP_403_FORBIDDEN, detail="Exercise is not available for this student")

	item = Progress(
		ID_Student=current_student.ID_User,
		ID_Exercise=payload.id_exercise,
		Attempts=payload.attempts,
		Status=payload.status,
		XP_Earned=payload.xp_earned,
		Sync_Status=payload.sync_status,
	)
	db.add(item)

	# Raw SQL para garantir que o UPDATE chega à BD independentemente do ORM
	from sqlalchemy import text as raw_text
	from datetime import timedelta

	xp = payload.xp_earned
	uid = current_student.ID_User
	today = date.today()
	yesterday = today - timedelta(days=1)

	# Lê estado actual directo da BD (mesma transacção, dados frescos)
	row = await db.execute(
		raw_text("SELECT total_xp, streak_days FROM student WHERE id_student = :uid"),
		{"uid": uid},
	)
	current = row.fetchone()
	new_xp      = (current.total_xp or 0) + xp if current else xp
	new_level   = _level_for_xp(new_xp)
	level_up    = new_level > _level_for_xp((current.total_xp or 0) if current else 0)

	# Streak
	has_today     = await db.scalar(raw_text("SELECT 1 FROM streak WHERE id_student = :uid AND log_date = :d"), {"uid": uid, "d": today})
	has_yesterday = await db.scalar(raw_text("SELECT 1 FROM streak WHERE id_student = :uid AND log_date = :d"), {"uid": uid, "d": yesterday})
	new_streak = (current.streak_days or 0) if current else 0
	if not has_today:
		new_streak = ((current.streak_days or 0) + 1) if has_yesterday else 1

	# UPDATE atómico
	await db.execute(
		raw_text(
			"UPDATE student SET total_xp = :xp, current_level = :lvl, "
			"streak_days = :streak, last_access = NOW() "
			"WHERE id_student = :uid"
		),
		{"xp": new_xp, "lvl": new_level, "streak": new_streak, "uid": uid},
	)
	if not has_today:
		await db.execute(
			raw_text("INSERT INTO streak (id_streak, id_student, log_date) VALUES (gen_random_uuid(), :uid, :d)"),
			{"uid": uid, "d": today},
		)

	await db.flush()
	return ProgressResponse(
		id_progress=item.ID_Progress,
		id_student=item.ID_Student,
		id_exercise=item.ID_Exercise,
		attempts=item.Attempts,
		status=item.Status,
		xp_earned=xp,
		sync_status=item.Sync_Status,
		recorded_at=None,
		new_total_xp=new_xp,
		new_level=new_level,
		level_up=level_up,
		streak_days=new_streak,
	)


@router.get("/streak", response_model=list[StreakResponse])
async def get_streak(
	limit: int = Query(default=30, ge=1, le=365),
	db: AsyncSession = Depends(get_db),
	current_student: Base_User = Depends(require_roles("Student")),
):
	stmt = (
		select(Streak)
		.where(Streak.ID_Student == current_student.ID_User)
		.order_by(Streak.Log_Date.desc())
		.limit(limit)
	)
	items = (await db.scalars(stmt)).all()
	return [to_streak_response(item) for item in items]


@router.get("/learning-paths", response_model=list[dict])
async def get_learning_paths(
	db: AsyncSession = Depends(get_db),
	current_student: Base_User = Depends(require_roles("Student")),
):
	"""
	Devolve todas as UCs disponíveis para o aluno poder escolher.
	Cada UC inclui os seus tópicos e exercícios publicados, ordenados
	por N_Order do tópico e depois por dificuldade (Easy → Medium → Hard).
	Não filtra por Student_UC — o aluno vê tudo e escolhe.
	"""
	courses = (
		await db.scalars(select(Course_Unit).order_by(Course_Unit.Name.asc()))
	).all()

	if not courses:
		return []

	paths = []
	for course in courses:
		checkpoints = await _build_checkpoints(course.ID_UC, db)
		paths.append({
			"id_uc": course.ID_UC,
			"name": course.Name,
			"total_topics": len(checkpoints),
			"total_exercises": sum(len(c["exercises"]) for c in checkpoints),
			"checkpoints": checkpoints,
		})

	return paths


@router.get("/learning-paths/{id_uc}", response_model=dict)
async def get_learning_path(
	id_uc: int,
	db: AsyncSession = Depends(get_db),
	current_student: Base_User = Depends(require_roles("Student")),
):
	"""
	Devolve o learning path de uma UC específica escolhida pelo aluno.
	Útil para o frontend carregar só a UC selecionada sem ter de pedir todas.
	"""
	course = await db.scalar(select(Course_Unit).where(Course_Unit.ID_UC == id_uc))
	if not course:
		raise HTTPException(status_code=status.HTTP_404_NOT_FOUND, detail="Course unit not found")

	checkpoints = await _build_checkpoints(id_uc, db)

	return {
		"id_uc": course.ID_UC,
		"name": course.Name,
		"total_topics": len(checkpoints),
		"total_exercises": sum(len(c["exercises"]) for c in checkpoints),
		"checkpoints": checkpoints,
	}


@router.get("/topics", response_model=list[dict])
async def list_topics(
	id_uc: int,
	db: AsyncSession = Depends(get_db),
	current_student: Base_User = Depends(require_roles("Student")),
):
	stmt = (
		select(Topic)
		.where(Topic.ID_UC == id_uc)
		.order_by(Topic.N_Order.asc())
	)
	topics = (await db.scalars(stmt)).all()
	return [{"name": t.Name, "order": t.N_Order} for t in topics]