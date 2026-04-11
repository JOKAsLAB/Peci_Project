from fastapi import APIRouter, Depends, HTTPException, Query, status, UploadFile, File
from sqlalchemy import and_, select, delete
from sqlalchemy.ext.asyncio import AsyncSession

from pathlib import Path
import uuid
import sys
import os
from dotenv import load_dotenv



_ai_engine_path = os.path.abspath(
    os.path.join(os.path.dirname(__file__), '..', '..', '..', '..', 'ai_engine')
)
if _ai_engine_path not in sys.path:
    sys.path.insert(0, _ai_engine_path)

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
	GenerateQuestionsRequest,
	GeneratedQuestionsResponse,
	IndexMaterialRequest,
	IndexMaterialResponse,
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
		published=item.Published,
	)


def to_material_response(item: Teaching_Material) -> MaterialResponse:
	return MaterialResponse(
		id_material=item.ID_Material,
		id_uc=item.ID_UC,
		id_professor=item.ID_Professor,
		status=item.Status,
		title=item.Title,
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


@router.patch("/exercises/{exercise_id}", response_model=ExerciseResponse)
async def update_exercise(
	exercise_id: str,
	published: bool = Query(...),
	db: AsyncSession = Depends(get_db),
	current_professor: Base_User = Depends(require_roles("Professor")),
):
	"""
	Atualizar estado de publicação de um exercício (PATCH).
	
	Parâmetro query:
	- published: true/false para publicar/despublicar
	"""
	# Obter exercício
	import uuid
	try:
		ex_uuid = uuid.UUID(exercise_id)
	except:
		raise HTTPException(status_code=status.HTTP_400_BAD_REQUEST, detail="Invalid UUID format")
	
	exercise = await db.scalar(
		select(Exercise).where(Exercise.ID_Exercise == ex_uuid)
	)
	
	if not exercise:
		raise HTTPException(status_code=status.HTTP_404_NOT_FOUND, detail="Exercise not found")
	
	# Verificar se professor tem acesso à UC do exercício
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
	
	# Atualizar
	exercise.Published = published
	await db.flush()
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
	
	exercise = await db.scalar(
		select(Exercise).where(Exercise.ID_Exercise == ex_uuid)
	)
	
	if not exercise:
		raise HTTPException(status_code=status.HTTP_404_NOT_FOUND, detail="Exercise not found")
	
	# Verificar se professor tem acesso à UC do exercício
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
	
	# Delete using the statement
	delete_stmt = delete(Exercise).where(Exercise.ID_Exercise == ex_uuid)
	await db.execute(delete_stmt)
	await db.commit()


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

@router.delete("/materials/{material_id}", status_code=status.HTTP_204_NO_CONTENT)
async def delete_material(
    material_id: uuid.UUID,
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

    try:
        from ImportFiles import PDFIndexer  # type: ignore
        indexer = PDFIndexer(device="cpu")
        indexer.remover_ficheiro(str(material_id))
    except Exception as e:
        print(f"⚠️ Erro ao remover do ChromaDB: {e}")


    await db.delete(material)
@router.post("/materials/{material_id}/reindex", response_model=IndexMaterialResponse)
async def reindex_material(
    material_id: uuid.UUID,
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

    try:
        from ImportFiles import PDFIndexer  # type: ignore

        indexer = PDFIndexer(device="cuda")
        ficheiro_id = str(material_id)

        from ImportFiles import PDFIndexer  # type: ignore
        base_dir = _ai_engine_path
        uploads_dir = os.path.join(base_dir, "uploads")
        
        # Procura o ficheiro com este ID
        import glob
        matches = glob.glob(os.path.join(uploads_dir, f"{ficheiro_id}.*"))
        if not matches:
            raise HTTPException(status_code=404, detail="Ficheiro físico não encontrado")

        file_path = matches[0]
        resultado = indexer.indexar_total(
            pdf_path=file_path,
            uc_id=material.ID_UC,
            ficheiro_id=ficheiro_id,
        )

        material.Status = "Indexed"

        return IndexMaterialResponse(
            status="success",
            id=ficheiro_id,
            file=material.Title,
            message=f"Material re-indexado com sucesso",
        )

    except HTTPException:
        raise
    except Exception as e:
        raise HTTPException(status_code=500, detail=f"Erro ao re-indexar: {str(e)}")
	
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


@router.post("/generate-questions", response_model=GeneratedQuestionsResponse, status_code=status.HTTP_201_CREATED)
async def generate_questions(
	payload: GenerateQuestionsRequest,
	db: AsyncSession = Depends(get_db),
	current_professor: Base_User = Depends(require_roles("Professor")),
):
	# Validar acesso à UC
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

	try:
		# QuestionGeneratorTeacher já foi adicionado ao sys.path no startup
		from QuestionGeneratorTeacher import QuestionGeneratorTeacher  # type: ignore
		print("✅ QuestionGeneratorTeacher importado com sucesso")
		
		gerador = QuestionGeneratorTeacher(device="cuda")  # Use CPU para evitar problemas em servidor
		perguntas = gerador.generate_questions_by_topic(
			filename=payload.filename,
			topic=payload.topic,
			n_perguntas=payload.n_perguntas,
			difficulty=payload.difficulty,
			question_type=payload.question_type,
		)
		
		if not perguntas:
			raise HTTPException(status_code=400, detail="Não foram geradas perguntas para o tópico indicado")
		
		# Guardar as perguntas geradas na BD
		exercicios_criados = []
		for p in perguntas:
			item = Exercise(
				ID_UC=payload.id_uc,
				Topic_Name=p.get("topic", "Sem tópico"),
				Type=p.get("type", "multipleChoice"),
				Question=p.get("question", ""),
				Solution={
					"options": p.get("options", []),
					"correct": p.get("correct", "")
				},
				Difficulty=p.get("difficulty", "medium"),
				Explanation=p.get("explanation", ""),
			)
			db.add(item)
			await db.flush()
			exercicios_criados.append(to_exercise_response(item))
		
		return GeneratedQuestionsResponse(
			count=len(exercicios_criados),
			questions=exercicios_criados,
			message=f"{len(exercicios_criados)} perguntas geradas com sucesso",
		)
	
	except HTTPException:
		raise
	except ModuleNotFoundError as e:
		print(f"❌ Erro ao importar módulo: {str(e)}")
		print(f"📂 sys.path: {sys.path}")
		raise HTTPException(status_code=500, detail=f"Dependências não instaladas: {str(e)}. Verifica ai_engine/requirements.txt")
	except Exception as e:
		print(f"❌ Erro na rota generate-questions: {str(e)}")
		import traceback
		traceback.print_exc()
		raise HTTPException(status_code=500, detail=f"Erro ao gerar perguntas: {str(e)}")


@router.post("/index-material", response_model=IndexMaterialResponse, status_code=status.HTTP_201_CREATED)
async def index_material(
	id_uc: int = Query(..., description="ID da Unidade Curricular"),
	file: UploadFile = File(...),
	db: AsyncSession = Depends(get_db),
	current_professor: Base_User = Depends(require_roles("Professor")),
):
	"""Faz upload e indexa um ficheiro PDF no ChromaDB"""
	# Validar acesso à UC
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

	# Validar tipo de ficheiro
	allowed_types = ['application/pdf', 'application/vnd.openxmlformats-officedocument.presentationml.presentation', 'application/msword']
	if file.content_type not in allowed_types:
		raise HTTPException(status_code=400, detail="Apenas PDFs, PPTXs e DOCXs são permitidos")

	try:

		from ImportFiles import PDFIndexer  # type: ignore
		print("✅ PDFIndexer importado com sucesso")
		
		# Ler conteúdo do ficheiro
		file_content = await file.read()
		
		# Criar indexer com diretório de uploads do servidor
		indexer = PDFIndexer(device="cuda", upload_dir="./uploads")
		
		# Fazer upload + indexação em um passo
		ficheiro_id = uuid.uuid4()
		resultado = indexer.indexar_com_upload(
			file_content=file_content,
			original_filename=file.filename,
			uc_id=id_uc,
			ficheiro_id=str(ficheiro_id),
		)
		
		# Guardar material na BD
		material = Teaching_Material(
			ID_UC=id_uc,
			ID_Professor=current_professor.ID_User,
			Status="Indexed",
			Title=file.filename,
		
		)
		db.add(material)
		await db.flush()
		
		return IndexMaterialResponse(
			status="success",
			id=str(ficheiro_id),
			file=file.filename,
			message=f"Ficheiro {file.filename} enviado e indexado com sucesso",
		)
	
	except HTTPException:
		raise
	except ModuleNotFoundError as e:
		print(f"❌ Erro ao importar módulo: {str(e)}")
		print(f"📂 sys.path: {sys.path}")
		raise HTTPException(status_code=500, detail=f"Dependências não instaladas: {str(e)}. Verifica ai_engine/requirements.txt")
	except Exception as e:
		print(f"❌ Erro na rota index-material: {str(e)}")
		import traceback
		traceback.print_exc()
		raise HTTPException(status_code=500, detail=f"Erro ao indexar ficheiro: {str(e)}")


@router.post("/index-material-from-path", response_model=IndexMaterialResponse, status_code=status.HTTP_201_CREATED)
async def index_material_from_path(
	payload: IndexMaterialRequest,
	db: AsyncSession = Depends(get_db),
	current_professor: Base_User = Depends(require_roles("Professor")),):
	"""Indexa um ficheiro a partir de um caminho existente no servidor"""
	# Validar acesso à UC
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



	try:
		# PDFIndexer já foi adicionado ao sys.path no startup
		from ImportFiles import PDFIndexer  # type: ignore
	
		
		indexer = PDFIndexer(device="cuda", upload_dir="./uploads")  # Use CUDA para aproveitar GPU
		ficheiro_id = uuid.uuid4()
		
		resultado = indexer.indexar_total(
			uc_id=payload.id_uc,
			ficheiro_id=ficheiro_id,
		)
		
		return IndexMaterialResponse(
			status=resultado.get("status", "ok"),
			id=str(resultado.get("id", ficheiro_id)),
			file=resultado.get("file", ""),
			message=f"Ficheiro {resultado.get('file', '')} indexado com sucesso",
		)
	
	except HTTPException:
		raise
	except ModuleNotFoundError as e:
		print(f"❌ Erro ao importar módulo: {str(e)}")
		print(f"📂 sys.path: {sys.path}")
		raise HTTPException(status_code=500, detail=f"Dependências não instaladas: {str(e)}. Verifica ai_engine/requirements.txt")
	except Exception as e:
		print(f"❌ Erro na rota index-material-from-path: {str(e)}")
		import traceback
		traceback.print_exc()
		raise HTTPException(status_code=500, detail=f"Erro ao indexar ficheiro: {str(e)}")

