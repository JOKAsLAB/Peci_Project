# scripts/seed_exercises.py
# ─────────────────────────────────────────────────────────────────────────────
# Insere exercícios associando a tópicos já existentes (por ID_UC + nome).
# Não cria UCs nem tópicos novos — apenas valida que existem.
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

    # ── Pré-validação: rejeita linhas mal formadas ────────────────────────────
    valid = []
    for q in questions:
        diff  = DIFFICULTY_MAP.get((q.get("difficulty") or "").lower())
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
        if not q.get("id_uc"):
            print(f"[SKIP] Campo 'id_uc' em falta → {q['question'][:50]}")
            continue

        valid.append({**q, "_difficulty": diff})

    if not valid:
        print("Nenhuma pergunta válida encontrada. A sair.")
        return

    async with AsyncSessionLocal() as session:
        ucs_para_verificar = {int(q["id_uc"]) for q in valid}
        for uc in ucs_para_verificar:
                result = await session.execute(text("""
                    SELECT Name FROM Topic WHERE ID_UC = :id_uc ORDER BY Name
                """), {"id_uc": uc})
                rows = result.fetchall()
                print(f"\n[BD] Tópicos na UC {uc}:")
                for r in rows:
                    print(f"     '{r[0]}'")
        # ── PASSO 1: Validar tópicos existentes na BD (ID_UC + Nome) ──────────
        topics_missing = set()
        valid_with_topics = []

        for q in valid:
            id_uc      = int(q["id_uc"])
            topic_name = q["topic"]

            exists = await session.execute(text("""
                SELECT 1 FROM Topic
                WHERE ID_UC = :id_uc AND Name = :name
            """), {"id_uc": id_uc, "name": topic_name})

            if exists.scalar() is None:
                key = (id_uc, topic_name)
                if key not in topics_missing:
                    print(f"[SKIP] Tópico '{topic_name}' não existe na UC {id_uc} — exercícios ignorados")
                    topics_missing.add(key)
            else:
                valid_with_topics.append(q)

        valid = valid_with_topics

        if not valid:
            print("Nenhum exercício com tópico válido na BD. A sair.")
            return

        # ── PASSO 2: Inserir Exercícios ───────────────────────────────────────
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
                await session.commit()
                ex_inserted += 1

            except Exception as e:
                await session.rollback()
                print(f"[ERRO] UC {q['id_uc']} - Tópico '{q['topic']}':")
                print(f"       → '{q['question'][:60]}'")
                print(f"       → {e}")
                ex_skipped += 1

    print(f"""
─────────────────────────────
  Tópicos não encontrados : {len(topics_missing)}
  Exercícios inseridos    : {ex_inserted}
  Exercícios com erro     : {ex_skipped}
─────────────────────────────""")

if __name__ == "__main__":
    asyncio.run(seed())