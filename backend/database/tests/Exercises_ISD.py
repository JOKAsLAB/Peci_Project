# scripts/seed_exercises.py
# ─────────────────────────────────────────────────────────────────────────────
# Popula Course_Unit, Topic e Exercise a partir de perguntas_uc.json.
# Reutiliza AsyncSessionLocal do database.py — não recria ligação.
# ─────────────────────────────────────────────────────────────────────────────

import asyncio
import json
import sys
from pathlib import Path
from sqlalchemy import text

# ── Paths ─────────────────────────────────────────────────────────────────────
ROOT    = Path(__file__).resolve().parents[3]
BACKEND = ROOT / "backend" / "backend" / "app"
sys.path.insert(0, str(BACKEND))

from dotenv import load_dotenv
load_dotenv(BACKEND / ".env")

from database import AsyncSessionLocal

JSON_FILE      = Path(__file__).parent / "perguntas_uc.json"
DIFFICULTY_MAP = {"easy": "Easy", "medium": "Medium", "hard": "Hard"}

# ─────────────────────────────────────────────────────────────────────────────

async def seed():
    with open(JSON_FILE, encoding="utf-8") as f:
        questions = json.load(f)

    # ── Pré-validação: rejeita logo linhas mal formadas ───────────────────────
    valid = []
    for q in questions:
        diff = DIFFICULTY_MAP.get((q.get("difficulty") or "").lower())
        qtype = q.get("type")

        if not diff:
            print(f"[SKIP] Dificuldade inválida '{q.get('difficulty')}' → {q['question'][:50]}")
            continue
        if qtype not in ("Multiple Choice", "True/False"):
            print(f"[SKIP] Tipo inválido '{qtype}' → {q['question'][:50]}")
            continue
        if not q.get("topic"):
            print(f"[SKIP] Campo 'topic' em falta → {q['question'][:50]}")
            continue

        valid.append({**q, "_difficulty": diff})

    if not valid:
        print("Nenhuma pergunta válida encontrada. A sair.")
        return

    # Valores únicos necessários
    id_uc  = int(valid[0]["id_uc"])          # todas são 40332
    topics = sorted({q["topic"] for q in valid})

    async with AsyncSessionLocal() as session:

        # ── PASSO 1: Course_Unit ──────────────────────────────────────────────
        # Se a UC não existir, insere com dados mínimos para não bloquear.
        # Ajusta Name/Semester/Curricular_Year conforme o teu registo real.
        await session.execute(text("""
            INSERT INTO Course_Unit (ID_UC, Name, Semester, Curricular_Year)
            VALUES (:id, 'Introdução aos Sistemas Digitais', '1S', 1)
            ON CONFLICT (ID_UC) DO NOTHING
        """), {"id": id_uc})

        print(f"[UC] Course_Unit {id_uc} garantida.")

        # ── PASSO 2: Topics ───────────────────────────────────────────────────
        # N_Order começa em 1 e incrementa por tópico novo.
        # Se o tópico já existir, não faz nada (ON CONFLICT DO NOTHING).
        # A UNIQUE (ID_UC, N_Order) é DEFERRABLE, por isso é seguro inserir
        # com ordens calculadas na mesma transação.

        # Descobre qual é o próximo N_Order disponível para esta UC
        result = await session.execute(text("""
            SELECT COALESCE(MAX(N_Order), 0)
            FROM Topic
            WHERE ID_UC = :id_uc
        """), {"id_uc": id_uc})
        max_order = result.scalar()

        new_order = max_order
        topics_inserted = 0
        for topic_name in topics:
            # Verifica se já existe
            exists = await session.execute(text("""
                SELECT 1 FROM Topic
                WHERE ID_UC = :id_uc AND Name = :name
            """), {"id_uc": id_uc, "name": topic_name})

            if exists.scalar() is None:
                new_order += 1
                await session.execute(text("""
                    INSERT INTO Topic (ID_UC, Name, N_Order)
                    VALUES (:id_uc, :name, :order)
                """), {"id_uc": id_uc, "name": topic_name, "order": new_order})
                print(f"[TOPIC] Inserido '{topic_name}' (order={new_order})")
                topics_inserted += 1
            else:
                print(f"[TOPIC] Já existe '{topic_name}' — ignorado.")

        # ── PASSO 3: Exercises ────────────────────────────────────────────────
        ex_inserted = 0
        ex_skipped  = 0

        for q in valid:
            if q["type"] == "Multiple Choice":
                solution = {"options": q.get("options", []), "correct": q["correct"]}
            else:
                solution = {"correct": q["correct"]}

            try:
                await session.execute(text("""
                    INSERT INTO Exercise (
                        ID_UC, Topic_Name, Material_Ref,
                        Type, Question, Solution, Difficulty, Explanation, Published
                    ) VALUES (
                        :id_uc, :topic, NULL,
                        :type, :question, CAST(:solution AS jsonb),
                        :difficulty, :explanation, TRUE
                    )
                """), {
                    "id_uc":       int(q["id_uc"]),
                    "topic":       q["topic"],
                    "type":        q["type"],
                    "question":    q["question"],
                    "solution":    json.dumps(solution),
                    "difficulty":  q["_difficulty"],
                    "explanation": q.get("explanation"),
                })
                ex_inserted += 1

            except Exception as e:
                await session.rollback()
                print(f"[ERRO] {type(e).__name__}: {e}")
                print(f"       → '{q['question'][:60]}'")
                ex_skipped += 1

        await session.commit()

    print(f"""
─────────────────────────────
  UC         : {id_uc}
  Tópicos    : {topics_inserted} inseridos ({len(topics)} únicos no JSON)
  Exercícios : {ex_inserted} inseridos, {ex_skipped} erros
─────────────────────────────""")


if __name__ == "__main__":
    asyncio.run(seed())