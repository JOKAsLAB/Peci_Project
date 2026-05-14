from collections import defaultdict
from datetime import date, timedelta
import uuid

from fastapi import APIRouter, Depends, HTTPException, Query, status
from sqlalchemy import and_, case, select, text
from sqlalchemy.ext.asyncio import AsyncSession

from app.database import get_db
from app.models import Base_User, Course_Unit, Exercise, Progress, Streak, Student, Exercise_Report, Student_UC, Topic
from app.routers.deps import require_roles
from app.schemas.academic import CourseUnitBasicInfo, CourseUnitResponse, ExerciseResponse
from app.schemas.gamification import (
	ProgressCreateRequest,
	ProgressResponse,
	StreakResponse,
	StudentProfileResponse,
)

router = APIRouter(prefix="/api/v1/students", tags=["students"])

DAILY_LIMIT = 5


# =============================================================
# HELPERS
# =============================================================

async def _student_uc_table_exists(db: AsyncSession) -> bool:
	"""Compatibility gate: environments without migrations should still serve students endpoints."""
	result = await db.scalar(text("SELECT to_regclass('public.student_uc')"))
	return result is not None


async def _get_daily_done_count(student_id, db: AsyncSession, id_uc: int | None = None) -> int:
	"""Count distinct exercises attempted today (any result), optionally filtered by UC."""
	from sqlalchemy import text as raw_text
	if id_uc is not None:
		result = await db.scalar(
			raw_text(
				"SELECT COUNT(DISTINCT p.id_exercise) FROM progress p "
				"JOIN exercise e ON e.id_exercise = p.id_exercise "
				"WHERE p.id_student = :uid AND DATE(p.date) = CURRENT_DATE "
				"AND e.id_uc = :id_uc"
			),
			{"uid": str(student_id), "id_uc": id_uc},
		)
	else:
		result = await db.scalar(
			raw_text(
				"SELECT COUNT(DISTINCT id_exercise) FROM progress "
				"WHERE id_student = :uid AND DATE(date) = CURRENT_DATE"
			),
			{"uid": str(student_id)},
		)
	return int(result or 0)


async def _get_topic_completion(id_uc: int, student_id, db: AsyncSession) -> dict[str, dict]:
	"""
	Returns per-topic completion info for a UC and student.
	{topic_name: {correct_count, total_count, is_completed}}
	A topic with 0 published exercises is treated as auto-completed.
	"""
	from sqlalchemy import text as raw_text
	rows = (
		await db.execute(
			raw_text("""
				SELECT
					e.topic_name,
					COUNT(DISTINCT e.id_exercise)                                          AS total_count,
					COUNT(DISTINCT p.id_exercise) FILTER (WHERE p.status = 'Correct')     AS correct_count,
					COUNT(DISTINCT p.id_exercise)                                          AS attempted_count
				FROM exercise e
				LEFT JOIN progress p ON p.id_exercise = e.id_exercise AND p.id_student = :uid
				WHERE e.id_uc = :id_uc AND e.published = TRUE
				GROUP BY e.topic_name
			"""),
			{"uid": str(student_id), "id_uc": id_uc},
		)
	).all()
	result = {}
	for row in rows:
		total    = int(row.total_count    or 0)
		correct  = int(row.correct_count  or 0)
		attempted = int(row.attempted_count or 0)
		# Tópico completo quando TODOS os exercícios foram tentados (acerto ou erro)
		result[row.topic_name] = {
			"correct_count": correct,
			"attempted_count": attempted,
			"total_count": total,
			"is_completed": total == 0 or attempted >= total,
		}
	return result


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


async def _build_checkpoints(id_uc: int, db: AsyncSession, student_id=None) -> list[dict]:
	"""
	Busca tópicos e exercícios publicados de uma UC num único JOIN,
	ordenados por N_Order do tópico e depois por dificuldade.
	Se student_id for fornecido, inclui informação de lock/completion por tópico.
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

	completion: dict[str, dict] = {}
	if student_id is not None:
		completion = await _get_topic_completion(id_uc, student_id, db)

	sorted_names = sorted(topic_order_map, key=lambda n: topic_order_map[n])
	checkpoints = []
	prev_completed = True  # first topic is always unlocked

	for name in sorted_names:
		n_exercises = len(topic_exercises[name])
		comp = completion.get(
			name,
			{"correct_count": 0, "attempted_count": 0, "total_count": n_exercises, "is_completed": n_exercises == 0},
		)
		is_locked = not prev_completed
		is_completed = comp["is_completed"] if student_id is not None else False

		checkpoints.append({
			"topic_name": name,
			"topic_order": topic_order_map[name],
			"exercises": [ex.model_dump() for ex in topic_exercises[name]],
			"is_locked": is_locked,
			"is_completed": is_completed,
			"correct_count": comp["correct_count"],
			"attempted_count": comp.get("attempted_count", 0),
			"total_count": comp["total_count"],
		})

		prev_completed = is_completed

	return checkpoints


# =============================================================
# ENDPOINTS
# =============================================================

@router.get("/me", response_model=StudentProfileResponse)
async def my_profile(
	db: AsyncSession = Depends(get_db),
	current_student: Base_User = Depends(require_roles("Student", "Professor", "Admin")),
):
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

	# Streak only counts if the student exercised today or yesterday
	yesterday = date.today() - timedelta(days=1)
	has_recent = await db.scalar(
		raw_text("SELECT 1 FROM streak WHERE id_student = :uid AND log_date >= :d"),
		{"uid": current_student.ID_User, "d": yesterday},
	)
	live_streak = (data.streak_days or 0) if has_recent else 0

	total_xp = data.total_xp or 0
	return StudentProfileResponse(
		id_student=current_student.ID_User,
		name=current_student.Name,
		current_level=_level_for_xp(total_xp),
		total_xp=total_xp,
		streak_days=live_streak,
		last_access=data.last_access,
		xp_for_next_level=XP_PER_LEVEL,
		xp_in_current_level=_xp_in_level(total_xp),
	)


@router.get("/course-units", response_model=list[CourseUnitResponse])
async def list_course_units(
	db: AsyncSession = Depends(get_db),
	current_student: Base_User = Depends(require_roles("Student", "Professor", "Admin")),
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
	limit: int = Query(default=20, ge=1, le=50),
	offset: int = Query(default=0, ge=0),
	db: AsyncSession = Depends(get_db),
	current_student: Base_User = Depends(require_roles("Student", "Professor", "Admin")),
):
	# Contexto de exploração livre — sem limite diário, sem offset automático.
	# O limite diário aplica-se apenas ao contexto dos Cursos (practice_session).
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


# O endpoint do botão report num exercício: tenta inserir um registro na tabela Exercise_Report.
@router.post("/exercises/{exercise_id}/report", status_code=status.HTTP_201_CREATED)
async def report_exercise(
    exercise_id: str,
    db: AsyncSession = Depends(get_db),
    current_student: Base_User = Depends(require_roles("Student")),
):
    try:
        ex_uuid = uuid.UUID(exercise_id)
    except ValueError:
        raise HTTPException(status_code=400, detail="Invalid UUID format")
	
    # Verifica se o exercício existe
    exercise = await db.scalar(select(Exercise).where(Exercise.ID_Exercise == ex_uuid))
    if not exercise:
        raise HTTPException(status_code=404, detail="Exercise not found")

    # Tenta inserir — se já existir (mesmo aluno, mesmo exercício), ignora
    existing = await db.scalar(
        select(Exercise_Report).where(
            and_(
                Exercise_Report.ID_Exercise == ex_uuid,
                Exercise_Report.ID_Student == current_student.ID_User,
            )
        )
    )
    if existing:
        raise HTTPException(status_code=409, detail="Already reported")

    report = Exercise_Report(
        ID_Exercise=ex_uuid,
        ID_Student=current_student.ID_User,
    )
    db.add(report)
    await db.flush()
    await db.commit()
    return {"detail": "Report submitted"}


@router.post("/progress", response_model=ProgressResponse, status_code=status.HTTP_201_CREATED)
async def create_progress(
	payload: ProgressCreateRequest,
	db: AsyncSession = Depends(get_db),
	current_student: Base_User = Depends(require_roles("Student", "Professor", "Admin")),
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
	current_student: Base_User = Depends(require_roles("Student", "Professor", "Admin")),
):
	stmt = (
		select(Streak)
		.where(Streak.ID_Student == current_student.ID_User)
		.order_by(Streak.Log_Date.desc())
		.limit(limit)
	)
	items = (await db.scalars(stmt)).all()
	return [to_streak_response(item) for item in items]


@router.get("/daily-status")
async def daily_status(
	id_uc: int | None = Query(default=None),
	db: AsyncSession = Depends(get_db),
	current_student: Base_User = Depends(require_roles("Student", "Professor", "Admin")),
):
	"""
	Devolve o estado diário de prática do aluno.
	Se id_uc for fornecido, o limite é calculado para essa UC específica (5/dia por UC).
	"""
	done = await _get_daily_done_count(current_student.ID_User, db, id_uc=id_uc)
	remaining = max(0, DAILY_LIMIT - done)
	return {
		"done_today": done,
		"daily_limit": DAILY_LIMIT,
		"can_practice": remaining > 0,
		"remaining_today": remaining,
	}


@router.get("/practice-session")
async def practice_session(
	id_uc: int,
	db: AsyncSession = Depends(get_db),
	current_student: Base_User = Depends(require_roles("Student", "Professor", "Admin")),
):
	"""
	Devolve os próximos exercícios para o aluno praticar numa UC.
	- Encontra o tópico ativo (primeiro incompleto e desbloqueado)
	- Ordena: nunca tentados → incorretos → corretos (todos aleatórios dentro do grupo)
	- Respeita o limite de 5 exercícios por dia
	"""
	from sqlalchemy import text as raw_text

	uid = current_student.ID_User
	done_today = await _get_daily_done_count(uid, db, id_uc=id_uc)
	remaining = max(0, DAILY_LIMIT - done_today)
	streak_met = done_today >= DAILY_LIMIT

	base_resp = {"done_today": done_today, "daily_limit": DAILY_LIMIT, "remaining_today": remaining, "streak_met": streak_met}

	# Tópicos da UC por ordem
	topics = (
		await db.scalars(select(Topic).where(Topic.ID_UC == id_uc).order_by(Topic.N_Order.asc()))
	).all()

	if not topics:
		return {**base_resp, "can_practice": False, "all_completed": False, "current_topic": None, "exercises": [], "streak_met": streak_met}

	completion = await _get_topic_completion(id_uc, uid, db)

	# Encontra o tópico ativo: primeiro desbloqueado e incompleto
	current_topic = None
	prev_completed = True
	for topic in topics:
		if not prev_completed:
			break  # tópico bloqueado — não há mais tópicos acessíveis
		comp = completion.get(topic.Name, {"total_count": 0, "is_completed": True})
		if not comp["is_completed"]:
			current_topic = topic
			break
		prev_completed = comp["is_completed"]

	if current_topic is None:
		return {**base_resp, "can_practice": True, "all_completed": True, "current_topic": None, "exercises": []}

	# Exercícios do tópico ativo com ordering inteligente
	# Exercícios ainda não tentados: acerto ou erro conta como feito e não volta a aparecer.
	rows = (
		await db.execute(
			raw_text("""
				WITH attempted AS (
					SELECT DISTINCT id_exercise
					FROM progress
					WHERE id_student = :uid
				)
				SELECT
					e.id_exercise, e.id_uc, e.topic_name, e.material_ref,
					e.type, e.question, e.solution, e.difficulty, e.explanation, e.published
				FROM exercise e
				WHERE e.id_uc = :id_uc
				  AND e.topic_name = :topic_name
				  AND e.published = TRUE
				  AND e.id_exercise NOT IN (SELECT id_exercise FROM attempted)
				ORDER BY
					CASE e.difficulty WHEN 'Easy' THEN 1 WHEN 'Medium' THEN 2 WHEN 'Hard' THEN 3 ELSE 4 END ASC,
					RANDOM()
			"""),
			{"uid": str(uid), "id_uc": id_uc, "topic_name": current_topic.Name},
		)
	).all()

	exercises = [
		{
			"id_exercise": str(row.id_exercise),
			"id_uc": row.id_uc,
			"topic_name": row.topic_name,
			"material_ref": str(row.material_ref) if row.material_ref else None,
			"type": row.type,
			"question": row.question,
			"solution": row.solution,
			"difficulty": row.difficulty,
			"explanation": row.explanation,
			"published": row.published,
			"course_unit_info": None,
		}
		for row in rows
	]

	comp_info = completion.get(current_topic.Name, {"correct_count": 0, "total_count": 0})
	return {
		**base_resp,
		"can_practice": True,
		"all_completed": False,
		"current_topic": {
			"name": current_topic.Name,
			"order": current_topic.N_Order,
			"correct_count": comp_info["correct_count"],
			"total_count": comp_info.get("total_count", 0),
		},
		"exercises": exercises,
	}


@router.get("/learning-paths", response_model=list[dict])
async def get_learning_paths(
	db: AsyncSession = Depends(get_db),
	current_student: Base_User = Depends(require_roles("Student", "Professor", "Admin")),
):
	"""
	Devolve todas as UCs disponíveis para o aluno poder escolher.
	Cada UC inclui os seus tópicos e exercícios publicados, ordenados
	por N_Order do tópico e depois por dificuldade (Easy → Medium → Hard).
	Inclui informação de lock/completion por tópico para o aluno logado.
	"""
	courses = (
		await db.scalars(select(Course_Unit).order_by(Course_Unit.Name.asc()))
	).all()

	if not courses:
		return []

	paths = []
	for course in courses:
		checkpoints = await _build_checkpoints(course.ID_UC, db, student_id=current_student.ID_User)
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
	current_student: Base_User = Depends(require_roles("Student", "Professor", "Admin")),
):
	"""
	Devolve o learning path de uma UC específica escolhida pelo aluno.
	Inclui informação de lock/completion por tópico para o aluno logado.
	"""
	course = await db.scalar(select(Course_Unit).where(Course_Unit.ID_UC == id_uc))
	if not course:
		raise HTTPException(status_code=status.HTTP_404_NOT_FOUND, detail="Course unit not found")

	checkpoints = await _build_checkpoints(id_uc, db, student_id=current_student.ID_User)

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
	current_student: Base_User = Depends(require_roles("Student", "Professor", "Admin")),
):
	stmt = (
		select(Topic)
		.where(Topic.ID_UC == id_uc)
		.order_by(Topic.N_Order.asc())
	)
	topics = (await db.scalars(stmt)).all()
	return [{"name": t.Name, "order": t.N_Order} for t in topics]


@router.get("/stats/topics", response_model=list[dict])
async def topic_stats(
	id_uc: int | None = Query(default=None),
	db: AsyncSession = Depends(get_db),
	current_student: Base_User = Depends(require_roles("Student", "Professor", "Admin")),
):
	"""
	Estatísticas por tópico para o aluno — aparece no perfil.
	Usa o último resultado de cada exercício (DISTINCT ON) para não penalizar
	tentativas repetidas: se o aluno errou 3x e acertou 1x conta como Correto.
	Ordenado do melhor para o pior tópico (accuracy descrescente).
	Aceita filtro opcional por UC (id_uc).
	"""
	from sqlalchemy import text as raw_text

	uid = current_student.ID_User
	params: dict = {"uid": str(uid)}
	uc_filter = ""
	if id_uc is not None:
		uc_filter = "AND e.id_uc = :id_uc"
		params["id_uc"] = id_uc

	rows = (
		await db.execute(
			raw_text(f"""
				WITH latest AS (
					SELECT DISTINCT ON (id_exercise) id_exercise, status
					FROM progress
					WHERE id_student = :uid
					ORDER BY id_exercise, date DESC
				)
				SELECT
					e.topic_name,
					e.id_uc,
					cu.name                                                              AS course_unit_name,
					COUNT(DISTINCT l.id_exercise)                                        AS total_answered,
					COUNT(DISTINCT l.id_exercise) FILTER (WHERE l.status = 'Correct')   AS correct_count,
					COUNT(DISTINCT l.id_exercise) FILTER (WHERE l.status = 'Incorrect') AS incorrect_count
				FROM latest l
				JOIN exercise e    ON e.id_exercise = l.id_exercise
				JOIN course_unit cu ON cu.id_uc     = e.id_uc
				WHERE TRUE {uc_filter}
				GROUP BY e.topic_name, e.id_uc, cu.name
				ORDER BY
					COUNT(DISTINCT l.id_exercise) FILTER (WHERE l.status = 'Correct')::float
					/ NULLIF(COUNT(DISTINCT l.id_exercise), 0) DESC NULLS LAST,
					total_answered DESC
			"""),
			params,
		)
	).all()

	stats = []
	for row in rows:
		total   = int(row.total_answered  or 0)
		correct = int(row.correct_count   or 0)
		stats.append({
			"topic_name":        row.topic_name,
			"id_uc":             row.id_uc,
			"course_unit_name":  row.course_unit_name,
			"total_answered":    total,
			"correct_count":     correct,
			"incorrect_count":   int(row.incorrect_count or 0),
			"accuracy":          round(correct / total * 100, 1) if total > 0 else 0.0,
		})

	return stats