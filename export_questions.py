"""
PECI -- Export de Perguntas para JSON

Uso:
  python export_questions.py                  -- um ficheiro JSON por UC (pasta ./exports/)
  python export_questions.py --merged         -- todas as UCs num so ficheiro
  python export_questions.py --uc 41953       -- so a UC com esse ID
  python export_questions.py --uc "Introducao a Sistemas Digitais"  -- por nome (parcial)

Variaveis de ambiente (lidas do .env por defeito):
  DB_HOST, DB_PORT, DB_USER, DB_PASSWORD, DB_NAME
"""

import asyncio
import json
import os
import re
import sys
import argparse
from datetime import datetime
from pathlib import Path

import asyncpg
from dotenv import load_dotenv

# ── Configuração ──────────────────────────────────────────────────────────────

ENV_PATH = Path(__file__).parent / "backend" / "backend" / "app" / ".env"
load_dotenv(dotenv_path=ENV_PATH)

DB_CONFIG = {
    "host":     os.getenv("DB_HOST",     "localhost"),
    "port":     int(os.getenv("DB_PORT", "5432")),
    "user":     os.getenv("DB_USER",     "PECI_USER"),
    "password": os.getenv("DB_PASSWORD", "12345678"),
    "database": os.getenv("DB_NAME",     "PECI_LOCAL"),
}

OUTPUT_DIR = Path("exports")

# ── Queries ───────────────────────────────────────────────────────────────────

QUERY_ALL = """
SELECT
    e.id_exercise::text   AS id,
    cu.id_uc              AS uc_id,
    cu.name               AS uc_name,
    cu.semester           AS uc_semester,
    cu.curricular_year    AS uc_year,
    t.name                AS topic,
    t.n_order             AS topic_order,
    e.type                AS type,
    e.difficulty          AS difficulty,
    e.question            AS question,
    e.solution            AS solution,
    e.explanation         AS explanation,
    e.published           AS published
FROM exercise e
JOIN course_unit cu ON cu.id_uc = e.id_uc
JOIN topic t        ON t.id_uc = e.id_uc AND t.name = e.topic_name
ORDER BY cu.name, t.n_order, e.type, e.difficulty
"""

QUERY_BY_UC_ID = QUERY_ALL.replace(
    "ORDER BY",
    "WHERE cu.id_uc = $1\nORDER BY"
)

QUERY_BY_UC_NAME = QUERY_ALL.replace(
    "ORDER BY",
    "WHERE cu.name ILIKE $1\nORDER BY"
)

# ── Helpers ───────────────────────────────────────────────────────────────────

def safe_filename(name: str) -> str:
    return re.sub(r'[\\/:*?"<>|]', "_", name).strip()


def row_to_dict(row: asyncpg.Record) -> dict:
    solution = row["solution"]
    if isinstance(solution, str):
        solution = json.loads(solution)
    return {
        "id":          row["id"],
        "type":        row["type"],
        "difficulty":  row["difficulty"],
        "topic":       row["topic"],
        "question":    row["question"],
        "solution":    solution,
        "explanation": row["explanation"],
        "published":   row["published"],
    }


def group_by_uc(rows) -> dict:
    ucs: dict = {}
    for row in rows:
        key = row["uc_id"]
        if key not in ucs:
            ucs[key] = {
                "uc_id":       row["uc_id"],
                "uc_name":     row["uc_name"],
                "semester":    row["uc_semester"],
                "year":        row["uc_year"],
                "exercises":   [],
            }
        ucs[key]["exercises"].append(row_to_dict(row))
    return ucs


def write_json(path: Path, data: object) -> None:
    path.parent.mkdir(parents=True, exist_ok=True)
    with open(path, "w", encoding="utf-8") as f:
        json.dump(data, f, ensure_ascii=False, indent=2, default=str)
    print(f"  OK  {path}  ({_count(data)} perguntas)")


def _count(data) -> int:
    if isinstance(data, list):
        return sum(len(uc["exercises"]) for uc in data)
    if isinstance(data, dict) and "exercises" in data:
        return len(data["exercises"])
    return 0


# ── Lógica principal ──────────────────────────────────────────────────────────

async def export(args: argparse.Namespace) -> None:
    conn = await asyncpg.connect(**DB_CONFIG)
    try:
        # ── Filtragem por UC ────────────────────────────────────────────────
        if args.uc:
            # Tenta como int (ID) primeiro, depois como nome
            try:
                uc_id = int(args.uc)
                rows = await conn.fetch(QUERY_BY_UC_ID, uc_id)
            except ValueError:
                rows = await conn.fetch(QUERY_BY_UC_NAME, f"%{args.uc}%")

            if not rows:
                print(f"Nenhuma pergunta encontrada para UC: {args.uc!r}")
                return

            ucs = group_by_uc(rows)
            if len(ucs) > 1:
                print(f"Encontradas {len(ucs)} UCs que correspondem ao filtro.")

            for uc_data in ucs.values():
                fname = safe_filename(uc_data["uc_name"])
                write_json(OUTPUT_DIR / f"{fname}.json", uc_data)

        # ── Todas as UCs, num só ficheiro ───────────────────────────────────
        elif args.merged:
            rows = await conn.fetch(QUERY_ALL)
            ucs = group_by_uc(rows)
            payload = list(ucs.values())
            ts = datetime.now().strftime("%Y%m%d_%H%M%S")
            write_json(OUTPUT_DIR / f"all_questions_{ts}.json", payload)

        # ── Uma ficheiro por UC (default) ───────────────────────────────────
        else:
            rows = await conn.fetch(QUERY_ALL)
            ucs = group_by_uc(rows)
            print(f"Exportando {len(ucs)} UC(s)…")
            for uc_data in ucs.values():
                fname = safe_filename(uc_data["uc_name"])
                write_json(OUTPUT_DIR / f"{fname}.json", uc_data)

    finally:
        await conn.close()


# ── Entry point ───────────────────────────────────────────────────────────────

def main() -> None:
    parser = argparse.ArgumentParser(description="Export perguntas PECI para JSON")
    parser.add_argument("--uc",     metavar="ID_OU_NOME",
                        help="Exporta só a UC com esse ID ou nome (parcial)")
    parser.add_argument("--merged", action="store_true",
                        help="Junta todas as UCs num único ficheiro")
    args = parser.parse_args()

    asyncio.run(export(args))


if __name__ == "__main__":
    main()
