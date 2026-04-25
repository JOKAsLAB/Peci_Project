from fastapi import APIRouter, Depends, HTTPException, Query, Request, status, UploadFile, File
from langgraph import func
from sqlalchemy import and_, select, delete
from sqlalchemy.ext.asyncio import AsyncSession
from uuid import UUID
import glob
import uuid
import os
from typing import Optional
from app.database import get_db
from app.models import (
    Base_User,
    Course_Unit,
    Exercise,
    Exercise_Report,
    Professor_UC,
    Request as RequestModel,
    Teaching_Material,
    Topic,
)
from app.models.enums import RequestStatus
from app.routers.deps import require_roles
from app.schemas.academic import (
    CourseUnitResponse,
    ExerciseCreateRequest,
    ExerciseUpdateRequest,
    ExerciseResponse,
    GenerateQuestionsRequest,
    GeneratedQuestionsResponse,
    IndexMaterialRequest,
    IndexMaterialResponse,
    MaterialCreateRequest,
    MaterialResponse,
    ExerciseReportedResponse,
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
        published=item.Published,
    )


def to_material_response(item: Teaching_Material, professor: Base_User, current_user_id: UUID) -> MaterialResponse:
    return MaterialResponse(
        id_material=item.ID_Material,
        id_uc=item.ID_UC,
        id_professor=item.ID_Professor,
        status=item.Status,
        title=item.Title,
        upload_date=item.Upload_Date,
        uploaded_by_name=f"{professor.Name}",
        is_mine=item.ID_Professor == current_user_id,
    )


def to_request_response(item: RequestModel) -> AdminRequestResponse:
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
    limit: Optional[int] = Query(default=None, ge=1),
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


@router.patch("/exercises/{exercise_id}", response_model=ExerciseResponse)
async def update_exercise(
    exercise_id: str,
    payload: ExerciseUpdateRequest,
    db: AsyncSession = Depends(get_db),
    current_professor: Base_User = Depends(require_roles("Professor")),
):
    try:
        ex_uuid = UUID(exercise_id)
    except ValueError:
        raise HTTPException(status_code=status.HTTP_400_BAD_REQUEST, detail="Invalid UUID format")

    exercise = await db.scalar(select(Exercise).where(Exercise.ID_Exercise == ex_uuid))
    if not exercise:
        raise HTTPException(status_code=status.HTTP_404_NOT_FOUND, detail="Exercise not found")

    has_access = await db.scalar(
        select(Professor_UC).where(
            and_(
                Professor_UC.ID_Professor == current_professor.ID_User,
                Professor_UC.ID_UC == exercise.ID_UC,
            )
        )
    )
    if not has_access:
        raise HTTPException(status_code=status.HTTP_403_FORBIDDEN, detail="You are not assigned to this course unit")

    if payload.published is not None:
        exercise.Published = payload.published
    if payload.question is not None:
        exercise.Question = payload.question
    if payload.topic_name is not None:
        topic_exists = await db.scalar(
            select(Topic).where(and_(Topic.ID_UC == exercise.ID_UC, Topic.Name == payload.topic_name))
        )
        if not topic_exists:
            raise HTTPException(status_code=status.HTTP_404_NOT_FOUND, detail="Topic not found for this course unit")
        exercise.Topic_Name = payload.topic_name
    if payload.type is not None:
        exercise.Type = payload.type
    if payload.difficulty is not None:
        exercise.Difficulty = payload.difficulty
    if payload.solution is not None:
        exercise.Solution = payload.solution
    if payload.explanation is not None:
        exercise.Explanation = payload.explanation

    await db.flush()
    await db.commit()
    return to_exercise_response(exercise)


@router.delete("/exercises/{exercise_id}", status_code=status.HTTP_204_NO_CONTENT)
async def delete_exercise(
    exercise_id: str,
    db: AsyncSession = Depends(get_db),
    current_professor: Base_User = Depends(require_roles("Professor")),
):
    try:
        ex_uuid = UUID(exercise_id)
    except ValueError:
        raise HTTPException(status_code=status.HTTP_400_BAD_REQUEST, detail="Invalid exercise ID format")

    exercise = await db.scalar(select(Exercise).where(Exercise.ID_Exercise == ex_uuid))
    if not exercise:
        raise HTTPException(status_code=status.HTTP_404_NOT_FOUND, detail="Exercise not found")

    has_access = await db.scalar(
        select(Professor_UC).where(
            and_(
                Professor_UC.ID_Professor == current_professor.ID_User,
                Professor_UC.ID_UC == exercise.ID_UC,
            )
        )
    )
    if not has_access:
        raise HTTPException(status_code=status.HTTP_403_FORBIDDEN, detail="You are not assigned to this course unit")

    await db.execute(delete(Exercise).where(Exercise.ID_Exercise == ex_uuid))
    await db.commit()

@router.get("/exercises/reported", response_model=list[ExerciseReportedResponse])
async def list_reported_exercises(
    threshold: int = Query(default=3, ge=1),
    db: AsyncSession = Depends(get_db),
    current_professor: Base_User = Depends(require_roles("Professor")),
):
    allowed_ucs = select(Professor_UC.ID_UC).where(
        Professor_UC.ID_Professor == current_professor.ID_User
    )

    stmt = (
        select(Exercise, func.count(Exercise_Report.ID_Student).label("report_count"))
        .join(Exercise_Report, Exercise_Report.ID_Exercise == Exercise.ID_Exercise)
        .where(Exercise.ID_UC.in_(allowed_ucs))
        .group_by(Exercise.ID_Exercise)
        .having(func.count(Exercise_Report.ID_Student) >= threshold)
        .order_by(func.count(Exercise_Report.ID_Student).desc())  # mais reportados primeiro
    )

    rows = (await db.execute(stmt)).all()

    return [
        ExerciseReportedResponse(
            id_exercise=ex.ID_Exercise,
            id_uc=ex.ID_UC,
            topic_name=ex.Topic_Name,
            material_ref=ex.Material_Ref,
            type=ex.Type,
            question=ex.Question,
            solution=ex.Solution,
            difficulty=ex.Difficulty,
            explanation=ex.Explanation,
            published=ex.Published,
            report_count=count,
        )
        for ex, count in rows
    ]


@router.get("/materials", response_model=list[MaterialResponse])
async def list_my_materials(
    id_uc: int | None = Query(default=None),
    db: AsyncSession = Depends(get_db),
    current_professor: Base_User = Depends(require_roles("Professor")),
):
    allowed_ucs = select(Professor_UC.ID_UC).where(
        Professor_UC.ID_Professor == current_professor.ID_User
    )
    stmt = (
        select(Teaching_Material, Base_User)
        .join(Base_User, Base_User.ID_User == Teaching_Material.ID_Professor)
        .where(Teaching_Material.ID_UC.in_(allowed_ucs))
    )
    if id_uc is not None:
        stmt = stmt.where(Teaching_Material.ID_UC == id_uc)
    stmt = stmt.order_by(Teaching_Material.Upload_Date.desc())
    rows = (await db.execute(stmt)).all()
    return [
        to_material_response(material, professor, current_professor.ID_User)
        for material, professor in rows
    ]


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
    )
    db.add(item)
    await db.flush()
    return to_material_response(item)


@router.delete("/materials/{material_id}", status_code=status.HTTP_204_NO_CONTENT)
async def delete_material(
    material_id: uuid.UUID,
    request: Request,
    db: AsyncSession = Depends(get_db),
    current_professor: Base_User = Depends(require_roles("Professor")),
):
    material = await db.scalar(
        select(Teaching_Material).where(
            and_(
                Teaching_Material.ID_Material == material_id,
                Teaching_Material.ID_Professor == current_professor.ID_User,
            )
        )
    )
    if not material:
        raise HTTPException(status_code=404, detail="Material não encontrado")

    indexer = request.app.state.pdf_indexer
    if indexer is not None:
        try:
            indexer.remover_ficheiro(str(material_id))
        except Exception as e:
            print(f"⚠️ Erro ao remover do ChromaDB: {e}")

    await db.execute(delete(Teaching_Material).where(Teaching_Material.ID_Material == material_id))
    await db.commit()


@router.post("/materials/{material_id}/reindex", response_model=IndexMaterialResponse)
async def reindex_material(
    material_id: uuid.UUID,
    request: Request,
    db: AsyncSession = Depends(get_db),
    current_professor: Base_User = Depends(require_roles("Professor")),
):
    material = await db.scalar(
        select(Teaching_Material).where(
            and_(
                Teaching_Material.ID_Material == material_id,
                Teaching_Material.ID_Professor == current_professor.ID_User,
            )
        )
    )
    if not material:
        raise HTTPException(status_code=404, detail="Material não encontrado")

    indexer = request.app.state.pdf_indexer
    if indexer is None:
        raise HTTPException(status_code=503, detail="AI Engine não disponível")

    ficheiro_id = str(material_id)
    uploads_dir = os.path.join(request.app.state.ai_engine_path, "uploads")

    matches = glob.glob(os.path.join(uploads_dir, f"{ficheiro_id}.*"))
    if not matches:
        raise HTTPException(status_code=404, detail="Ficheiro físico não encontrado")

    file_path = matches[0]

    try:
        indexer.remover_ficheiro(ficheiro_id)

        resultado = indexer.indexar_total(
            pdf_path=file_path,
            uc_id=material.ID_UC,
            ficheiro_id=ficheiro_id,
            original_filename=material.Title,
        )

        material.Status = "Indexed"
        await db.flush()
        await db.commit()

        return IndexMaterialResponse(
            status="success",
            id=ficheiro_id,
            file=material.Title,
            message="Material re-indexado com sucesso",
        )
    except HTTPException:
        raise
    except Exception as e:
        raise HTTPException(status_code=500, detail=f"Erro ao re-indexar: {str(e)}")


@router.get("/requests", response_model=list[AdminRequestResponse])
async def list_my_admin_requests(
    db: AsyncSession = Depends(get_db),
    current_professor: Base_User = Depends(require_roles("Professor")),
):
    stmt = (
        select(RequestModel)
        .where(RequestModel.ID_Professor == current_professor.ID_User)
        .order_by(RequestModel.Creation_Date.desc())
    )
    items = (await db.scalars(stmt)).all()
    return [to_request_response(item) for item in items]


@router.post("/requests", response_model=AdminRequestResponse, status_code=status.HTTP_201_CREATED)
async def create_admin_request(
    payload: ProfessorRequestCreateRequest,
    db: AsyncSession = Depends(get_db),
    current_professor: Base_User = Depends(require_roles("Professor")),
):
    item = RequestModel(
        ID_Professor=current_professor.ID_User,
        Request_Type=payload.request_type,
        Title=payload.title,
        Description=payload.description,
        Status=RequestStatus.PENDING,
    )
    db.add(item)
    await db.flush()
    return to_request_response(item)


@router.post("/generate-questions", response_model=GeneratedQuestionsResponse, status_code=status.HTTP_201_CREATED)
async def generate_questions(
    payload: GenerateQuestionsRequest,
    request: Request,
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

    gerador = request.app.state.question_generator
    if gerador is None:
        raise HTTPException(status_code=503, detail="AI Engine não disponível")

    try:
        print(f"📊 A chamar gerador com:\n  - filename: {payload.filename}\n  - topic: {payload.topic}\n  - n_perguntas: {payload.n_perguntas}\n  - difficulty: {payload.difficulty}\n  - question_type: {payload.question_type}")

        perguntas = gerador.generate_questions_by_topic(
            ficheiro_id=payload.filename,
            topic=payload.topic,
            n_perguntas=payload.n_perguntas,
            difficulty=payload.difficulty,
            question_type=payload.question_type,
        )

        print(f"Gerador retornou {len(perguntas)} perguntas")

        if not perguntas:
            raise HTTPException(status_code=400, detail="Não existe conteúdo que seja sobre os tópicos da UC!")

        type_map = {
            "Escolha Múltipla": "Multiple Choice",
            "True/False": "True/False",
        }
        difficulty_map = {
            "easy": "Easy",
            "medium": "Medium",
            "hard": "Hard",
            "variada": "Medium",
        }

        exercicios_criados = []
        for p in perguntas:
            item = Exercise(
                ID_UC=payload.id_uc,
                Topic_Name=p.get("topic", "Sem tópico"),
                Type=type_map.get(p.get("type"), "Multiple Choice"),
                Question=p.get("question", ""),
                Solution={
                    "options": p.get("options", []),
                    "correct": p.get("correct", "")
                },
                Difficulty=difficulty_map.get(p.get("difficulty", "").lower(), "Medium"),
                Explanation=p.get("explanation", ""),
                Published=False,
            )
            db.add(item)
            await db.flush()
            exercicios_criados.append(to_exercise_response(item))

        await db.commit()

        return GeneratedQuestionsResponse(
            count=len(exercicios_criados),
            questions=exercicios_criados,
            message=f"{len(exercicios_criados)} perguntas geradas com sucesso",
        )

    except HTTPException:
        raise
    except Exception as e:
        print(f"❌ Erro na rota generate-questions: {str(e)}")
        import traceback
        traceback.print_exc()
        raise HTTPException(status_code=500, detail=f"Erro ao gerar perguntas: {str(e)}")


@router.post("/index-material", response_model=IndexMaterialResponse, status_code=status.HTTP_201_CREATED)
async def index_material(
    request: Request,
    id_uc: int = Query(..., description="ID da Unidade Curricular"),
    file: UploadFile = File(...),
    db: AsyncSession = Depends(get_db),
    current_professor: Base_User = Depends(require_roles("Professor")),
):
    has_access = await db.scalar(
        select(Professor_UC).where(
            and_(
                Professor_UC.ID_Professor == current_professor.ID_User,
                Professor_UC.ID_UC == id_uc,
            )
        )
    )
    if not has_access:
        raise HTTPException(status_code=status.HTTP_403_FORBIDDEN, detail="You are not assigned to this course unit")

    allowed_types = [
        'application/pdf',
        'application/vnd.openxmlformats-officedocument.presentationml.presentation',
        'application/msword',
    ]
    if file.content_type not in allowed_types:
        raise HTTPException(status_code=400, detail="Apenas PDFs, PPTXs e DOCXs são permitidos")

    indexer = request.app.state.pdf_indexer
    if indexer is None:
        raise HTTPException(status_code=503, detail="AI Engine não disponível")

    try:
        file_content = await file.read()
        print(f"📥 Ficheiro recebido: {file.filename} ({len(file_content)} bytes)")

        ficheiro_id = uuid.uuid4()

        print("🔄 A indexar ficheiro...")
        resultado = indexer.indexar_com_upload(
            file_content=file_content,
            original_filename=file.filename,
            uc_id=id_uc,
            ficheiro_id=str(ficheiro_id),
        )

        material = Teaching_Material(
            ID_Material=ficheiro_id,
            ID_UC=id_uc,
            ID_Professor=current_professor.ID_User,
            Status="Indexed",
            Title=file.filename,
        )
        db.add(material)
        await db.flush()
        await db.commit()

        return IndexMaterialResponse(
            status="success",
            id=str(ficheiro_id),
            file=file.filename,
            message=f"Ficheiro {file.filename} enviado e indexado com sucesso",
        )

    except HTTPException:
        raise
    except Exception as e:
        import traceback
        traceback.print_exc()
        raise HTTPException(status_code=500, detail=f"Erro ao indexar ficheiro: {str(e)}")