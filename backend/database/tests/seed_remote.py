
import asyncio
import json
import sys
from pathlib import Path

from sqlalchemy import text
from sqlalchemy.ext.asyncio import create_async_engine, AsyncSession
from sqlalchemy.orm import sessionmaker


SERVER_IP = "localhost"   
DB_USER   = "PECI_USER"
DB_PASS   = "12345678"
DB_NAME   = "PECI_LOCAL"
DB_PORT   = 5432

DB_URL = f"postgresql+asyncpg://{DB_USER}:{DB_PASS}@{SERVER_IP}:{DB_PORT}/{DB_NAME}"

INPUT = Path(sys.argv[1]) if len(sys.argv) > 1 else Path(__file__).parent / "perguntas_uc.json"

DIFFICULTY_MAP = {"easy": "Easy", "medium": "Medium", "hard": "Hard"}


def _load_questions(path: Path) -> list:
    """Carrega e normaliza um ficheiro JSON para lista plana de perguntas."""
    with open(path, encoding="utf-8") as f:
        data = json.load(f)

    # Formato B — objeto com uc_id + exercises
    if isinstance(data, dict) and "uc_id" in data:
        flat = []
        for ex in data.get("exercises", []):
            sol = ex.get("solution", {})
            flat.append({
                "id_uc":       data["uc_id"],
                "topic":       ex.get("topic"),
                "question":    ex.get("question"),
                "type":        ex.get("type"),
                "options":     sol.get("options", []),
                "correct":     sol.get("correct"),
                "difficulty":  ex.get("difficulty", "").lower(),
                "explanation": ex.get("explanation"),
            })
        return flat

    # Formato A — lista plana
    if isinstance(data, list):
        return data

    return []


def _collect_files(input_path: Path) -> list[Path]:
    if input_path.is_dir():
        return sorted(input_path.glob("*.json"))
    return [input_path]

# ─────────────────────────────────────────────────────────────────────────────

async def seed():
    files = _collect_files(INPUT)
    all_questions = []
    for f in files:
        print(f"[FILE] {f.name}")
        all_questions.extend(_load_questions(f))
    questions = all_questions

    # ── Validação básica ──────────────────────────────────────────────────────
    valid = []
    for q in questions:
        diff  = DIFFICULTY_MAP.get((q.get("difficulty") or "").lower())
        qtype = q.get("type")
        errors = []

        if not diff:
            errors.append(f"difficulty inválida '{q.get('difficulty')}'")
        if qtype not in ("Multiple Choice", "True/False"):
            errors.append(f"type inválido '{qtype}'")
        if not q.get("topic"):
            errors.append("campo 'topic' em falta")
        if not q.get("id_uc"):
            errors.append("campo 'id_uc' em falta")
        if not q.get("question"):
            errors.append("campo 'question' em falta")

        if errors:
            print(f"[SKIP] {', '.join(errors)} → {str(q.get('question','?'))[:50]}")
            continue

        valid.append({**q, "_difficulty": diff})

    if not valid:
        print("Nenhuma pergunta válida no JSON. A sair.")
        return

    engine = create_async_engine(DB_URL, echo=False)
    Session = sessionmaker(engine, class_=AsyncSession, expire_on_commit=False)

    topics_created  = 0
    topics_existing = 0
    ex_inserted     = 0
    ex_skipped      = 0

    async with Session() as session:
        # ── PASSO 1: Garantir que as UCs existem ─────────────────────────────
        ucs = {int(q["id_uc"]) for q in valid}
        for id_uc in ucs:
            row = await session.execute(
                text("SELECT name FROM course_unit WHERE id_uc = :id_uc"),
                {"id_uc": id_uc}
            )
            uc_row = row.fetchone()
            if not uc_row:
                print(f"[ERRO] UC {id_uc} não existe na BD. Cria-a primeiro no painel de admin.")
                valid = [q for q in valid if int(q["id_uc"]) != id_uc]
            else:
                print(f"[UC] {id_uc} — {uc_row[0]}")

        if not valid:
            print("Nenhuma pergunta com UC válida. A sair.")
            await engine.dispose()
            return

        # ── PASSO 2: Criar tópicos se não existirem ───────────────────────────
        seen_topics = set()
        for q in valid:
            key = (int(q["id_uc"]), q["topic"])
            if key in seen_topics:
                continue
            seen_topics.add(key)

            id_uc, topic_name = key

            exists = await session.execute(
                text("SELECT 1 FROM topic WHERE id_uc = :id_uc AND name = :name"),
                {"id_uc": id_uc, "name": topic_name}
            )
            if exists.scalar() is not None:
                print(f"[TOPIC] Já existe: '{topic_name}' (UC {id_uc})")
                topics_existing += 1
                continue

            # Calcular próxima N_Order para esta UC
            max_order = await session.execute(
                text("SELECT COALESCE(MAX(n_order), 0) FROM topic WHERE id_uc = :id_uc"),
                {"id_uc": id_uc}
            )
            n_order = max_order.scalar() + 1

            try:
                await session.execute(
                    text("INSERT INTO topic (id_uc, name, n_order) VALUES (:id_uc, :name, :n_order)"),
                    {"id_uc": id_uc, "name": topic_name, "n_order": n_order}
                )
                await session.commit()
                print(f"[TOPIC] Criado: '{topic_name}' (UC {id_uc}, ordem {n_order})")
                topics_created += 1
            except Exception as e:
                await session.rollback()
                print(f"[ERRO] Falha ao criar tópico '{topic_name}' (UC {id_uc}): {e}")
                valid = [q for q in valid if not (int(q["id_uc"]) == id_uc and q["topic"] == topic_name)]

        # ── PASSO 3: Inserir exercícios ───────────────────────────────────────
        for q in valid:
            if q["type"] == "Multiple Choice":
                solution = {"options": q.get("options", []), "correct": q["correct"]}
            else:
                solution = {"correct": q["correct"]}

            try:
                await session.execute(text("""
                    INSERT INTO exercise (
                        id_uc, topic_name, material_ref,
                        type, question, solution, difficulty, explanation, published
                    ) VALUES (
                        :id_uc, :topic, NULL,
                        :type::exercise_type_enum,
                        :question,
                        CAST(:solution AS jsonb),
                        :difficulty::difficulty_level_enum,
                        :explanation,
                        TRUE
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
                print(f"[ERRO] Exercício '{str(q['question'])[:50]}': {e}")
                ex_skipped += 1

    await engine.dispose()

    print(f"""
─────────────────────────────────────
  Tópicos criados    : {topics_created}
  Tópicos já existiam: {topics_existing}
  Exercícios inseridos: {ex_inserted}
  Exercícios com erro : {ex_skipped}
─────────────────────────────────────""")


if __name__ == "__main__":
    asyncio.run(seed())
