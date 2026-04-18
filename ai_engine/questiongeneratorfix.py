"""
Fixes the 'topic' field for questions that were swapped to a different UC.

When QuestionGenerator detects a question belongs to another UC, it updates
id_uc but leaves the original topic string unchanged — which may not match any
topic in the new UC.  This script uses the LLM to pick the best topic from the
new UC for each affected question.

Usage:
    python questiongeneratorfix.py <input.json> <base_uc_id> [output.json]

    input.json   – JSON file produced by QuestionGenerator
    base_uc_id   – The UC the questions were originally generated for.
                   Questions with this id_uc are left untouched.
    output.json  – Optional output path (default: <input>_fixed.json)
"""

import json
import os
import sys
import time
import uuid
from pathlib import Path

from dotenv import load_dotenv
from IAEduAPI import IAEduAPI

UC_INFO = {
    40332: {
        "nome": "Introdução aos Sistemas Digitais",
        "topicos": [
            "Introdução aos sistemas digitais",
            "Representação e codificação de informação",
            "Álgebra de Boole",
            "Lógica combinatória elementar",
            "Blocos combinatórios",
            "Circuitos aritméticos",
            "Sistemas sequenciais",
            "Estratégias de análise de circuitos sequenciais",
            "Blocos sequenciais fundamentais",
            "Síntese de máquinas de estado",
        ],
    },
    40333: {
        "nome": "Laboratório de Sistemas Digitais",
        "topicos": [
            "Introdução às FPGAs, ferramentas e kits de desenvolvimento",
            "Modelação em VHDL: Componentes combinatórios e aritméticos",
            "Modelação em VHDL: Circuitos sequenciais, registos e memórias",
            "Máquinas de Estados Finitos (FSM) em VHDL",
            "Testbenches e estratégias de depuração de circuitos",
            "Precauções de projeto: Reset, sincronização e restrições temporais",
        ],
    },
    42545: {
        "nome": "Arquitetura de Computadores",
        "topicos": [
            "Organização funcional e programação em assembly",
            "Tradução de linguagens de alto nível e assemblagem",
            "Aritmética de vírgula fixa e flutuante",
            "Estrutura interna do processador e etapas de execução",
            "Arquitecturas de processadores com pipeline",
        ],
    },
    42548: {
        "nome": "Organização de Sistemas de Computadores",
        "topicos": [
            "Organização básica do sistema de entradas/saídas",
            "Dispositivos periféricos",
            "Organização de barramentos de dados",
            "Interfaces e barramentos paralelos e série",
            "Software para gestão de dispositivos de E/S",
            "Sistema de memória e análise de memória cache",
        ],
    },
}


def _invoke_llm(llm: IAEduAPI, prompt: str) -> str:
    llm.thread_id = str(uuid.uuid4())
    raw = None
    attempt = 0
    while raw is None:
        try:
            raw = llm.invoke(prompt).content
        except Exception as e:
            wait = min(10 * (attempt + 1), 300)
            print(f"  Erro LLM: {e}. A aguardar {wait}s... (tentativa {attempt + 1})")
            time.sleep(wait)
            attempt += 1
            llm.thread_id = str(uuid.uuid4())
    return raw


def classify_topic(llm: IAEduAPI, question: dict, uc_id: int) -> str:
    uc = UC_INFO[uc_id]
    topicos_str = "\n".join(f"- {t}" for t in uc["topicos"])

    prompt = f"""És um especialista em avaliação pedagógica de engenharia.

Classifica a seguinte pergunta de escolha múltipla no tópico mais adequado da unidade curricular "{uc['nome']}".

PERGUNTA:
{question.get('question', '')}

OPÇÕES:
{chr(10).join(question.get('options', []))}

TÓPICOS DISPONÍVEIS:
{topicos_str}

Responde APENAS com o nome exato de um dos tópicos listados acima, sem texto adicional."""

    raw = _invoke_llm(llm, prompt).strip()

    # Validate the response is one of the allowed topics
    allowed = uc["topicos"]
    if raw in allowed:
        return raw

    # Fallback: find the closest match by substring
    raw_lower = raw.lower()
    for t in allowed:
        if t.lower() in raw_lower or raw_lower in t.lower():
            return t

    # Last resort: return the first topic
    print(f"    Aviso: resposta LLM '{raw}' não reconhecida, usando primeiro tópico")
    return allowed[0]


def fix_questions(questions: list[dict], base_uc_id: int, llm: IAEduAPI) -> tuple[list[dict], int]:
    fixed_count = 0
    result = []

    to_fix = [
        (i, q) for i, q in enumerate(questions)
        if int(q.get("id_uc", 0)) != base_uc_id
        and q.get("topic", "") not in UC_INFO.get(int(q.get("id_uc", 0)), {}).get("topicos", [])
    ]

    print(f"Perguntas a corrigir: {len(to_fix)} / {len(questions)}\n")

    fixed_map: dict[int, str] = {}
    for idx, (i, q) in enumerate(to_fix):
        uc_id = int(q.get("id_uc", 0))
        if uc_id not in UC_INFO:
            print(f"  [{idx+1}/{len(to_fix)}] UC {uc_id} desconhecida — ignorada")
            continue
        old_topic = q.get("topic", "")
        new_topic = classify_topic(llm, q, uc_id)
        print(f"  [{idx+1}/{len(to_fix)}] UC {uc_id} | '{old_topic}' → '{new_topic}'")
        fixed_map[i] = new_topic
        fixed_count += 1

    for i, q in enumerate(questions):
        q = dict(q)
        if i in fixed_map:
            q["topic"] = fixed_map[i]
        result.append(q)

    return result, fixed_count


def main():
    if len(sys.argv) < 3:
        print(__doc__)
        sys.exit(1)

    input_path = Path(sys.argv[1])
    base_uc_id = int(sys.argv[2])
    output_path = (
        Path(sys.argv[3]) if len(sys.argv) >= 4
        else input_path.with_stem(input_path.stem + "_fixed")
    )

    if not input_path.exists():
        print(f"Ficheiro não encontrado: {input_path}")
        sys.exit(1)

    load_dotenv("keys.env")
    llm = IAEduAPI(
        api_key=os.getenv("GPT_API_KEY"),
        endpoint=os.getenv("ENDPOINT_GPT"),
        channel_id=os.getenv("CANAL_ID"),
    )

    with open(input_path, encoding="utf-8") as f:
        questions = json.load(f)

    print(f"Carregadas {len(questions)} perguntas de '{input_path}'")
    print(f"UC base (não alterar): {base_uc_id} — {UC_INFO.get(base_uc_id, {}).get('nome', '?')}\n")

    fixed, count = fix_questions(questions, base_uc_id, llm)

    with open(output_path, "w", encoding="utf-8") as f:
        json.dump(fixed, f, indent=2, ensure_ascii=False)

    print(f"\nConcluído: {count} tópicos corrigidos → '{output_path}'")


if __name__ == "__main__":
    main()
