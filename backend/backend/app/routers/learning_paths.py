# =============================================================
# PECI PROJECT — Learning Paths Router
#
# Endpoints para gestão de caminhos de aprendizagem
# criados por professores via Path Builder.
#
# Rotas:
#   GET    /api/v1/professors/learning-paths       → Listar caminhos do professor
#   POST   /api/v1/professors/learning-paths       → Criar novo caminho
#   GET    /api/v1/professors/learning-paths/{id}  → Obter caminho com exercícios
#   PUT    /api/v1/professors/learning-paths/{id}  → Atualizar caminho
#   DELETE /api/v1/professors/learning-paths/{id}  → Apagar caminho
#   POST   /api/v1/professors/learning-paths/{id}/exercises → Adicionar exercício
#   DELETE /api/v1/professors/learning-paths/{id}/exercises/{ex_id} → Remover exercício
# =============================================================

from fastapi import APIRouter, Depends, HTTPException, status
from sqlalchemy import and_, select, desc
from sqlalchemy.ext.asyncio import AsyncSession
import uuid

from app.database import get_db
from app.models import (
    Base_User,
    LearningPath,
    LearningPathExercise,
    Professor_UC,
    Exercise,
)
from app.routers.deps import require_roles
from app.schemas.learning_path import (
    LearningPathCreate,
    LearningPathUpdate,
    LearningPathResponse,
    LearningPathDetailResponse,
    LearningPathExerciseCreate,
    LearningPathExerciseResponse,
)


router = APIRouter(prefix="/api/v1/professors/learning-paths", tags=["learning-paths"])


# =============================================================
# HELPERS
# =============================================================

def to_learning_path_response(path: LearningPath) -> LearningPathResponse:
    """Converte modelo para schema de resposta simples."""
    return LearningPathResponse(
        ID_Path=path.ID_Path,
        ID_UC=path.ID_UC,
        ID_Professor=path.ID_Professor,
        Name=path.Name,
        Description=path.Description,
        Published=path.Published,
        Created_At=path.Created_At,
        Updated_At=path.Updated_At,
    )


def to_learning_path_detail_response(path: LearningPath) -> LearningPathDetailResponse:
    """Converte modelo para schema de resposta com detalhes."""
    exercises = [
        LearningPathExerciseResponse(
            ID=ex.ID,
            ID_Exercise=ex.ID_Exercise,
            Order_Num=ex.Order_Num,
        )
        for ex in (path.path_exercises or [])
    ]
    return LearningPathDetailResponse(
        ID_Path=path.ID_Path,
        ID_UC=path.ID_UC,
        ID_Professor=path.ID_Professor,
        Name=path.Name,
        Description=path.Description,
        Published=path.Published,
        Created_At=path.Created_At,
        Updated_At=path.Updated_At,
        path_exercises=exercises,
    )


# =============================================================
# ENDPOINTS
# =============================================================

@router.get("", response_model=list[LearningPathResponse])
async def list_learning_paths(
    db: AsyncSession = Depends(get_db),
    current_professor: Base_User = Depends(require_roles("Professor")),
):
    """
    Listar todos os caminhos de aprendizagem do professor.
    
    Retorna:
    - Caminhos criados pelo professor logado
    - Ordenados por data de atualização (mais recentes primeiro)
    """
    stmt = (
        select(LearningPath)
        .where(LearningPath.ID_Professor == current_professor.ID_User)
        .order_by(desc(LearningPath.Updated_At))
    )
    paths = (await db.scalars(stmt)).all()
    return [to_learning_path_response(path) for path in paths]


@router.post("", response_model=LearningPathResponse, status_code=status.HTTP_201_CREATED)
async def create_learning_path(
    id_uc: int,
    payload: LearningPathCreate,
    db: AsyncSession = Depends(get_db),
    current_professor: Base_User = Depends(require_roles("Professor")),
):
    """
    Criar um novo caminho de aprendizagem.
    
    Requer:
    - id_uc: ID da Unidade Curricular
    - payload.Name: Nome do caminho
    - payload.Description: Descrição opcional
    - payload.Published: Se está publicado (default: False)
    
    Validação:
    - Professor deve ter acesso à UC
    """
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
        raise HTTPException(
            status_code=status.HTTP_403_FORBIDDEN,
            detail="Não tem acesso a esta unidade curricular",
        )

    # Criar novo caminho
    path = LearningPath(
        ID_Path=uuid.uuid4(),
        ID_UC=id_uc,
        ID_Professor=current_professor.ID_User,
        Name=payload.Name,
        Description=payload.Description,
        Published=payload.Published,
    )
    db.add(path)
    await db.flush()

    return to_learning_path_response(path)


@router.get("/{path_id}", response_model=LearningPathDetailResponse)
async def get_learning_path(
    path_id: uuid.UUID,
    db: AsyncSession = Depends(get_db),
    current_professor: Base_User = Depends(require_roles("Professor")),
):
    """
    Obter um caminho de aprendizagem com todos os exercícios.
    
    Retorna:
    - Caminho com lista de exercícios ordenados
    
    Validação:
    - Caminho deve pertencer ao professor
    """
    path = await db.scalar(
        select(LearningPath).where(
            and_(
                LearningPath.ID_Path == path_id,
                LearningPath.ID_Professor == current_professor.ID_User,
            )
        )
    )
    if not path:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail="Caminho não encontrado",
        )

    return to_learning_path_detail_response(path)


@router.put("/{path_id}", response_model=LearningPathResponse)
async def update_learning_path(
    path_id: uuid.UUID,
    payload: LearningPathUpdate,
    db: AsyncSession = Depends(get_db),
    current_professor: Base_User = Depends(require_roles("Professor")),
):
    """
    Atualizar um caminho de aprendizagem.
    
    Campos atualizáveis:
    - Name
    - Description
    - Published
    
    Validação:
    - Caminho deve pertencer ao professor
    """
    path = await db.scalar(
        select(LearningPath).where(
            and_(
                LearningPath.ID_Path == path_id,
                LearningPath.ID_Professor == current_professor.ID_User,
            )
        )
    )
    if not path:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail="Caminho não encontrado",
        )

    # Atualizar campos fornecidos
    if payload.Name is not None:
        path.Name = payload.Name
    if payload.Description is not None:
        path.Description = payload.Description
    if payload.Published is not None:
        path.Published = payload.Published

    await db.flush()
    return to_learning_path_response(path)


@router.delete("/{path_id}", status_code=status.HTTP_204_NO_CONTENT)
async def delete_learning_path(
    path_id: uuid.UUID,
    db: AsyncSession = Depends(get_db),
    current_professor: Base_User = Depends(require_roles("Professor")),
):
    """
    Apagar um caminho de aprendizagem.
    
    Efeito cascata:
    - Remove todos os exercícios do caminho
    
    Validação:
    - Caminho deve pertencer ao professor
    """
    path = await db.scalar(
        select(LearningPath).where(
            and_(
                LearningPath.ID_Path == path_id,
                LearningPath.ID_Professor == current_professor.ID_User,
            )
        )
    )
    if not path:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail="Caminho não encontrado",
        )

    await db.delete(path)
    await db.commit()


@router.post("/{path_id}/exercises", response_model=LearningPathExerciseResponse, status_code=status.HTTP_201_CREATED)
async def add_exercise_to_path(
    path_id: uuid.UUID,
    payload: LearningPathExerciseCreate,
    db: AsyncSession = Depends(get_db),
    current_professor: Base_User = Depends(require_roles("Professor")),
):
    """
    Adicionar um exercício a um caminho.
    
    Requer:
    - ID_Exercise: UUID do exercício
    - Order_Num: Posição no caminho (>=1)
    
    Validação:
    - Caminho deve pertencer ao professor
    - Exercício deve existir e pertencer à mesma UC
    """
    # Validar que o caminho existe e pertence ao professor
    path = await db.scalar(
        select(LearningPath).where(
            and_(
                LearningPath.ID_Path == path_id,
                LearningPath.ID_Professor == current_professor.ID_User,
            )
        )
    )
    if not path:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail="Caminho não encontrado",
        )

    # Validar que o exercício existe e pertence à mesma UC
    exercise = await db.scalar(
        select(Exercise).where(
            and_(
                Exercise.ID_Exercise == payload.ID_Exercise,
                Exercise.ID_UC == path.ID_UC,
            )
        )
    )
    if not exercise:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail="Exercício não encontrado ou não pertence a esta UC",
        )

    # Validar que a ordem não já existe
    existing = await db.scalar(
        select(LearningPathExercise).where(
            and_(
                LearningPathExercise.ID_Path == path_id,
                LearningPathExercise.Order_Num == payload.Order_Num,
            )
        )
    )
    if existing:
        raise HTTPException(
            status_code=status.HTTP_409_CONFLICT,
            detail=f"Já existe um exercício na posição {payload.Order_Num}",
        )

    # Criar relação
    path_exercise = LearningPathExercise(
        ID=uuid.uuid4(),
        ID_Path=path_id,
        ID_Exercise=payload.ID_Exercise,
        Order_Num=payload.Order_Num,
    )
    db.add(path_exercise)
    await db.flush()

    return LearningPathExerciseResponse(
        ID=path_exercise.ID,
        ID_Exercise=path_exercise.ID_Exercise,
        Order_Num=path_exercise.Order_Num,
    )


@router.delete("/{path_id}/exercises/{exercise_id}", status_code=status.HTTP_204_NO_CONTENT)
async def remove_exercise_from_path(
    path_id: uuid.UUID,
    exercise_id: uuid.UUID,
    db: AsyncSession = Depends(get_db),
    current_professor: Base_User = Depends(require_roles("Professor")),
):
    """
    Remover um exercício de um caminho.
    
    Validação:
    - Caminho deve pertencer ao professor
    - Exercício deve estar no caminho
    """
    # Validar que o caminho existe e pertence ao professor
    path = await db.scalar(
        select(LearningPath).where(
            and_(
                LearningPath.ID_Path == path_id,
                LearningPath.ID_Professor == current_professor.ID_User,
            )
        )
    )
    if not path:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail="Caminho não encontrado",
        )

    # Buscar a relação
    path_exercise = await db.scalar(
        select(LearningPathExercise).where(
            and_(
                LearningPathExercise.ID_Path == path_id,
                LearningPathExercise.ID_Exercise == exercise_id,
            )
        )
    )
    if not path_exercise:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail="Exercício não encontrado neste caminho",
        )

    await db.delete(path_exercise)
    await db.commit()
