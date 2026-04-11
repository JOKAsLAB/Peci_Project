#!/usr/bin/env python3
# =============================================================
# PECI PROJECT — Import Questions from JSON to Database
#
# Esta script lê perguntas_uc.json e insere na BD:
#   1. Cria tópicos automaticamente se não existem
#   2. Normaliza tipos e dificuldades
#   3. Constrói Solution JSONB
#   4. Insere Exercises com validação
#
# Uso:
#   python import_questions.py
#
# Requer:
#   - Backend BD rodando (PostgreSQL)
#   - Variáveis de ambiente em backend/app/.env
# =============================================================

import asyncio
import json
import sys
from pathlib import Path
from typing import Optional

# Adicionar backend ao path
sys.path.insert(0, str(Path(__file__).parent.parent / "backend"))

from sqlalchemy.ext.asyncio import AsyncSession
from app.models import Topic, Exercise, Course_Unit
from app.models.enums import ExerciseType, DifficultyLevel
from app.database import AsyncSessionLocal, engine, Base
import uuid


# =============================================================
# CONFIGURAÇÃO
# =============================================================

# Caminho para o ficheiro JSON
JSON_FILE = Path(__file__).parent / "tests" / "perguntas_uc.json"

# UC padrão (Sistemas Digitais - Universidade de Aveiro)
DEFAULT_UC_ID = 40332


# =============================================================
# FUNÇÕES AUXILIARES
# =============================================================

def normalize_difficulty(raw: str) -> str:
    """
    Converte dificuldade de lowercase para PascalCase.
    "easy" → "Easy"
    "medium" → "Medium"
    "hard" → "Hard"
    """
    mapping = {
        "easy": DifficultyLevel.EASY,
        "medium": DifficultyLevel.MEDIUM,
        "hard": DifficultyLevel.HARD,
    }
    return mapping.get(raw.lower(), DifficultyLevel.EASY)


def normalize_exercise_type(raw: str) -> str:
    """
    Converte tipo de exercício para ENUM.
    "Multiple Choice" → ExerciseType.MULTIPLE_CHOICE
    "True/False" → ExerciseType.TRUE_FALSE
    """
    mapping = {
        "multiple choice": ExerciseType.MULTIPLE_CHOICE,
        "true/false": ExerciseType.TRUE_FALSE,
    }
    return mapping.get(raw.lower(), ExerciseType.MULTIPLE_CHOICE)


def build_solution_json(question_data: dict) -> dict:
    """
    Constrói JSONB Solution a partir dos dados raw do JSON.
    
    Retorna:
    {
        "options": ["A) ...", "B) ...", ...],
        "correct": "B",
        "explanation": "..."
    }
    """
    return {
        "options": question_data.get("options", []),
        "correct": question_data.get("correct", ""),
        "explanation": question_data.get("explanation", ""),
    }


async def ensure_topics_exist(
    session: AsyncSession,
    uc_id: int,
    topics: set[str],
) -> None:
    """
    Garante que todos os tópicos existem na BD.
    Cria novos tópicos se necessário, com N_Order sequencial.
    """
    # Buscar tópicos existentes
    from sqlalchemy import select
    
    result = await session.execute(
        select(Topic).where(Topic.ID_UC == uc_id)
    )
    existing_topics = {row.Name for row in result.scalars().all()}
    
    # Identificar tópicos novos
    new_topics = topics - existing_topics
    
    if not new_topics:
        print(f"  ✓ Todos os {len(topics)} tópicos já existem")
        return
    
    # Obter próximo N_Order
    if existing_topics:
        result = await session.execute(
            select(Topic).where(Topic.ID_UC == uc_id).order_by(Topic.N_Order.desc())
        )
        max_order = result.scalars().first()
        next_order = (max_order.N_Order or 0) + 1 if max_order else 1
    else:
        next_order = 1
    
    # Criar novos tópicos
    created = 0
    for topic_name in sorted(new_topics):
        topic = Topic(
            ID_UC=uc_id,
            Name=topic_name,
            N_Order=next_order,
        )
        session.add(topic)
        created += 1
        next_order += 1
    
    await session.flush()
    print(f"  ✓ Criados {created} novos tópicos")


async def insert_exercises(
    session: AsyncSession,
    uc_id: int,
    exercises_data: list[dict],
) -> tuple[int, int]:
    """
    Insere exercícios na BD.
    
    Retorna (total_inseridas, total_puladas).
    """
    from sqlalchemy import select
    
    inserted = 0
    skipped = 0
    
    print(f"\n  Inserindo exercícios...")
    
    for idx, question_data in enumerate(exercises_data, 1):
        try:
            topic_name = question_data.get("topic", "Unknown Topic")
            question_text = question_data.get("question", "")
            
            # Validação básica
            if not question_text or not topic_name:
                print(f"    ⚠ Exercício #{idx}: falta pergunta ou tópico, pulando")
                skipped += 1
                continue
            
            # Garantir que the tópico existe
            result = await session.execute(
                select(Topic).where(
                    (Topic.ID_UC == uc_id) & (Topic.Name == topic_name)
                )
            )
            topic = result.scalars().first()
            
            if not topic:
                print(f"    ⚠ Exercício #{idx}: tópico '{topic_name}' não encontrado, pulando")
                skipped += 1
                continue
            
            # Normalizar dados
            exercise_type = normalize_exercise_type(question_data.get("type", ""))
            difficulty = normalize_difficulty(question_data.get("difficulty", "easy"))
            solution_json = build_solution_json(question_data)
            explanation = question_data.get("explanation", "")
            
            # Criar exercício
            exercise = Exercise(
                ID_Exercise=uuid.uuid4(),
                ID_UC=uc_id,
                Topic_Name=topic_name,
                Type=exercise_type,
                Question=question_text,
                Solution=solution_json,
                Difficulty=difficulty,
                Explanation=explanation,
                Material_Ref=None,  # Exercícios importados não vêm de teaching material
            )
            
            session.add(exercise)
            inserted += 1
            
            # Progress indicator
            if idx % 50 == 0:
                print(f"    → {idx} processadas...")
        
        except Exception as e:
            print(f"    ✗ Exercício #{idx}: erro {e}")
            skipped += 1
            continue
    
    await session.flush()
    await session.commit()
    
    return inserted, skipped


async def load_questions_from_json() -> list[dict]:
    """Carrega perguntas do ficheiro JSON."""
    if not JSON_FILE.exists():
        raise FileNotFoundError(f"Ficheiro não encontrado: {JSON_FILE}")
    
    with open(JSON_FILE, "r", encoding="utf-8") as f:
        return json.load(f)


async def ensure_course_unit_exists(session: AsyncSession, uc_id: int) -> bool:
    """Verifica se a UC existe. Cria se necessário."""
    from sqlalchemy import select
    
    result = await session.execute(
        select(Course_Unit).where(Course_Unit.ID_UC == uc_id)
    )
    uc = result.scalars().first()
    
    if not uc:
        print(f"  ! UC {uc_id} não existe. Criando...")
        uc = Course_Unit(
            ID_UC=uc_id,
            Name=f"UC {uc_id}",
            Semester="1st",
            Curricular_Year=1,
        )
        session.add(uc)
        await session.flush()
        print(f"  ✓ UC {uc_id} criada")
    else:
        print(f"  ✓ UC encontrada: {uc.Name}")
    
    return True


async def main():
    """Função principal de import."""
    print("\n" + "=" * 70)
    print("PECI PROJECT - Import Questions from JSON")
    print("=" * 70 + "\n")
    
    try:
        # 1. Carregar JSON
        print("1️⃣  Carregando perguntas do JSON...")
        questions = await load_questions_from_json()
        print(f"   ✓ Carregadas {len(questions)} perguntas\n")
        
        # 2. Conectar à BD
        print("2️⃣  Conectando à base de dados...")
        async with AsyncSessionLocal() as session:
            # Garantir que a UC existe
            await ensure_course_unit_exists(session, DEFAULT_UC_ID)
            
            # 3. Extrair tópicos únicos
            print("\n3️⃣  Processando tópicos...")
            topics = {q.get("topic", "Unknown") for q in questions if q.get("topic")}
            print(f"   Encontrados {len(topics)} tópicos únicos:")
            for t in sorted(topics):
                print(f"     - {t}")
            
            # Garantir que todos os tópicos existem
            print("\n4️⃣  Garantindo que tópicos existem...")
            await ensure_topics_exist(session, DEFAULT_UC_ID, topics)
            
            # 5. Inserir exercícios
            print("\n5️⃣  Inserindo exercícios...")
            inserted, skipped = await insert_exercises(
                session,
                DEFAULT_UC_ID,
                questions,
            )
            
            # 6. Resumo final
            print("\n" + "=" * 70)
            print("RESUMO DA IMPORTAÇÃO")
            print("=" * 70)
            print(f"✓ Exercícios inseridas: {inserted}")
            print(f"⚠ Exercícios puladas (erro/validação): {skipped}")
            print(f"📊 Total processado: {inserted + skipped}")
            print(f"📍 UC: {DEFAULT_UC_ID}")
            print(f"📋 Tópicos criados/ativos: {len(topics)}")
            print("=" * 70 + "\n")
            
            if inserted > 0:
                print("✅ IMPORT CONCLUÍDO COM SUCESSO!")
            else:
                print("⚠️  Nenhum exercício foi inserido. Verifique os logs acima.")
    
    except FileNotFoundError as e:
        print(f"\n❌ ERRO: {e}")
        print(f"   Certifique-se que o ficheiro existe: {JSON_FILE}")
        sys.exit(1)
    
    except Exception as e:
        print(f"\n❌ ERRO CRÍTICO: {e}")
        import traceback
        traceback.print_exc()
        sys.exit(1)


if __name__ == "__main__":
    asyncio.run(main())
