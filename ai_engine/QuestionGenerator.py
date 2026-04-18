import os
import re
import json
import time
from typing import List, Dict, Tuple
from dotenv import load_dotenv
from langchain_chroma import Chroma
from langchain_huggingface import HuggingFaceEmbeddings
import torch
from IAEduAPI import IAEduAPI
import uuid


UC_INFO = {
    40332: {
        "nome": "Introdução aos Sistemas Digitais",
        "objetivos": [
            "Apresentar conceitos essenciais sobre representação digital da informação: sistemas de numeração e codificação.",
            "Apresentar formalmente a álgebra de Boole no contexto dos sistemas digitais binários e demonstrar a sua importância prática como instrumento de especificação e descrição de sistemas digitais.",
            "Apresentar os blocos lógicos combinatórios fundamentais.",
            "Estudar as estruturas elementares de armazenamento de informação mais relevantes e introduzir o conceito de estado.",
            "Apresentar blocos lógicos sequenciais fundamentais.",
            "Exercitar as técnicas de análise e síntese de sistemas digitais de baixa complexidade.",
        ],
        "resultados_aprendizagem": [
            "Aprender conceitos essenciais sobre representação digital da informação: sistemas de numeração e codificação.",
            "Aprender usar a álgebra de Boole no contexto dos sistemas digitais binários, como instrumento de especificação e descrição de sistemas digitais.",
            "Aprender construir e usar blocos lógicos combinatórios fundamentais.",
            "Aprender construir e usar as estruturas elementares de armazenamento de informação mais relevantes.",
            "Aprender construir e usar blocos lógicos sequenciais fundamentais.",
            "Exercitar as técnicas de análise e síntese de sistemas digitais de baixa complexidade.",
        ],
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
        "objetivos": [],
        "resultados_aprendizagem": [],
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
        "objetivos": [
            "Compreender a organização dos computadores digitais.",
            "Adquirir familiaridade com a arquitectura de microprocessadores através da programação em assembly.",
            "Compreender a estrutura interna dos processadores.",
            "Conhecer as formas de representação da informação nos computadores digitais, com relevo para a representação da informação numérica (inteiros e vírgula flutuante) e as operações aritméticas básicas.",
        ],
        "resultados_aprendizagem": [
            "Definir genericamente a organização dos computadores digitais.",
            "Capacidade de programar computadores digitais em linguagem Assembly.",
            "Analisar e interpretar funcionalmente a estrutura interna dos processadores.",
        ],
        "topicos": [
            "Organização funcional e programação em assembly",
            "Tradução de linguagens de alto nível e assemblagem",
            "Aritmética de vírgula fixa e flutuante",
            "Estrutura interna do processador e etapas de execução",
            "Arquitecturas de processadores com pipeline",
        ],
    },
    42548: {
        "nome": "",
        "objetivos": [],
        "resultados_aprendizagem": [],
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


class QuestionGenerator:

    BATCH_CHARS = 6000
    PERGUNTAS_POR_BATCH = 20

    def __init__(self, db_path="./chroma_db", device="cuda"):
        load_dotenv("keys.env")
        model_kwargs = {"device": device, "trust_remote_code": True, "model_kwargs": {"torch_dtype": torch.float32}}

        self.embeddings = HuggingFaceEmbeddings(
            model_name='google/embeddinggemma-300m',
            model_kwargs=model_kwargs,
            encode_kwargs={'normalize_embeddings': True}
        )

        self.db = Chroma(
            persist_directory=db_path,
            embedding_function=self.embeddings,
            collection_name="conhecimento_geral",
            relevance_score_fn=lambda distance: max(0.0, min(1.0, 1 - distance))
        )

        self.llm = IAEduAPI(
            api_key=os.getenv("GPT_API_KEY"),
            endpoint=os.getenv("ENDPOINT_GPT"),
            channel_id=os.getenv("CANAL_ID")
        )

        self.hash_cache = set()

    def _invoke_llm(self, prompt: str) -> str:
        self.llm.thread_id = str(uuid.uuid4())
        raw = None
        attempt = 0
        while raw is None:
            try:
                raw = self.llm.invoke(prompt).content
            except Exception as e:
                wait = min(10 * (attempt + 1), 300)
                print(f"Erro: {e}. A aguardar {wait}s... (tentativa {attempt + 1})")
                time.sleep(wait)
                attempt += 1
                self.llm.thread_id = str(uuid.uuid4())
        return raw

    def get_chunks_by_subcap(self, filename: str) -> Dict:
        resultado = {}

        all_docs = self.db.get(
            where={"nome_ficheiro": filename},
            include=["documents", "metadatas"]
        )

        sem_estrutura = []
        for doc, meta in zip(all_docs["documents"], all_docs["metadatas"]):
            sub = meta.get("subcapitulo", "").strip()
            cap = meta.get("capitulo", "").strip()
            chave = sub if sub else cap
            if not chave:
                sem_estrutura.append(doc)
                continue
            if chave not in resultado:
                resultado[chave] = {"docs": [], "capitulo": cap}
            resultado[chave]["docs"].append(doc)

        if sem_estrutura:
            if resultado:
                resultado["__sem_estrutura__"] = {"docs": sem_estrutura, "capitulo": ""}
            else:
                for i, doc in enumerate(sem_estrutura):
                    chave = f"__chunk_{i}__"
                    resultado[chave] = {"docs": [doc], "capitulo": ""}

        print(f"Subcapitulos encontrados: {len(resultado)}" if resultado else "Nenhum subcapitulo encontrado.")
        return resultado

    def process_chunks(self, batch: List[str], subcap: str, cap: str, topicos_str: str, n_perguntas: int, id_uc: str, topicos_permitidos: List[str]) -> List[Dict]:
        context = "\n\n".join(batch)

        prompt = f"""És um professor de engenharia a criar exercícios de avaliação.

    Com base no conteúdo técnico abaixo, gera {n_perguntas} perguntas de escolha múltipla.
    Se o conteúdo der para criar perguntas mas não {n_perguntas}, gera as que conseguires. Se o conteúdo não estiver relacionado com nenhum dos tópicos disponíveis, responde apenas com: []

    CONTEUDO:
    {context}

    TOPICOS DISPONIVEIS:
    {topicos_str}

    REGRAS:
    1. Cada pergunta deve estar diretamente baseada no conteúdo fornecido mas não deve referenciar o conteúdo (Figuras, Circuitos, imagens,etc.).
    2. Cada pergunta deve pertencer a um dos tópicos disponíveis.
    3. Se o conteúdo tiver algum tipo de cálculos podes fazer várias perguntas mas com versões.
    4. Opções incorretas plausíveis mas claramente erradas para quem estudou.
    5. Cada pergunta tem uma dificuldade associada : 'Easy', 'Medium', 'Hard'.
    6. Responde APENAS com os JSONs, sem texto adicional.
    7. O Tipo questão True/False é permitido e tem apenas duas opções: "A) Verdadeiro" e "B) Falso" ESTAS PERGUNTAS SÃO EXCLUSIVAMENTE AFIRMAÇÕES VERDADEIRAS OU FALSAS!.

    FORMATO:
    {{"question": "...", "type": "Multiple Choice | True/False", "options": ["A) ...", "B) ...", "C) ...", "D) ..."], "correct": "A", "difficulty": "easy|medium|hard", "explanation": "...", "topic": "..."}}"""

        raw = self._invoke_llm(prompt)
        perguntas = []
        for block in re.findall(r'\{[^{}]+\}', raw, re.DOTALL):
            try:
                ex = json.loads(block)
                question = ex.get("question", "").strip()
                if not question or len(question) < 20:
                    continue

                topic = ex.get("topic", "").strip()
                if topic not in topicos_permitidos:
                    topic = next(
                        (t for t in topicos_permitidos if any(p in t.lower() for p in topic.lower().split())),
                        None
                    )
                    if topic is None:
                        continue

                perguntas.append({
                    "question": question,
                    "type": ex.get("type", "Multiple Choice | True/False"),
                    "options": ex.get("options", []),
                    "correct": ex.get("correct", ""),
                    "difficulty": ex.get("difficulty", "medium"),
                    "explanation": ex.get("explanation", ""),
                    "topic": topic,
                    "id_uc": id_uc
                })
            except:
                continue

        return perguntas

    def _build_validation_prompt(self, pergunta: Dict, contexto_chunk: str, id_uc: int) -> str:
        uc = UC_INFO.get(id_uc, {})
        outras_ucs_str = "\n".join(
            f"- [{info.get('nome', str(uid))}] (ID: {uid}) {t}"
            for uid, info in UC_INFO.items()
            if uid != id_uc
            for t in info.get("topicos", [])
        )
        objetivos_str = "\n".join(f"- {o}" for o in uc.get("objetivos", []))
        resultados_str = "\n".join(f"- {r}" for r in uc.get("resultados_aprendizagem", []))
        topicos_str = "\n".join(f"- {t}" for t in uc.get("topicos", []))

        return f"""És um especialista em avaliação pedagógica no âmbito de sistemas digitais e arquitetura de computadores.

        UNIDADE CURRICULAR ATUAL: {uc.get("nome", "")} (ID: {id_uc})

        OBJETIVOS DA UC:
        {objetivos_str}

        RESULTADOS DE APRENDIZAGEM:
        {resultados_str}

        TÓPICOS DA UC:
        {topicos_str} 

        TÓPICOS DAS OUTRAS UCS:
        {outras_ucs_str}
        
        PERGUNTA A VALIDAR:
        {json.dumps(pergunta, ensure_ascii=False)}

        Avalia esta pergunta. Responde APENAS com JSON, sem texto adicional:
        {{
        "no_ambito": true/false,
        "factualmente_correta": true/false,
        "avalia_competencia_certa": true/false,
        "uc_correta_id": null,
        "justificacao": "..."
        }}

        CRITÉRIOS:
        - no_ambito: a pergunta pertence EXCLUSIVAMENTE aos tópicos desta UC e NÃO pertence aos tópicos das outras UCs?
        - Se não pertencer a esta UC mas pertencer a outra, coloca o ID dessa UC em "uc_correta_id" (ex: 40332, 40333, 42545, 42548). Caso contrário deixa null.
        - avalia_competencia_certa: a pergunta avalia compreensão, aplicação ou análise?
        - factualmente_correta: a pergunta e as opções estão corretas e não induzem em erro?
        Rejeita as perguntas que mencionem o conteúdo por exemplo "Na figura acima, o que representa o bloco X?" ou "De acordo com o texto, qual é a função do componente Y?", OU SEJA TUDO O QUE POSSA CONFUNDIR O ALUNO POIS ELE NÃO ACESSO AO CONTEXTO!
        Rejeita perguntas que mencionem tópicos mais relacionados a Física ou seja Volts Amperes e coisas do género pois as UCs são focadas em sistemas digitais e arquitetura de computadores.
        """

    def _verify_answer_correctness(self, pergunta: Dict) -> Tuple[bool, str]:
        """
        Passo independente: pede ao LLM para resolver a pergunta sem ver a resposta marcada.
        Compara a resposta independente com a resposta marcada.
        Retorna (resposta_correta, justificacao).
        """
        options_str = "\n".join(pergunta.get("options", []))
        correct_marked = pergunta.get("correct", "").strip().upper()

        prompt = f"""Resolve esta pergunta de engenharia como se fosses um estudante experiente.
            NÃO tens acesso à resposta correta — tens de raciocinar a partir do teu conhecimento.

            PERGUNTA:
            {pergunta.get("question", "")}

            OPÇÕES:
            {options_str}

            Responde APENAS com JSON, sem texto adicional:
            {{"resposta": "A", "confianca": "alta|media|baixa", "raciocinio": "..."}}

            A resposta deve ser apenas a letra da opção correta (A, B, C ou D, ou "Verdadeiro"/"Falso" para True/False)."""

        raw = self._invoke_llm(prompt)
        try:
            match = re.search(r'\{[^{}]+\}', raw, re.DOTALL)
            result = json.loads(match.group()) if match else {}
        except:
            return True, "parse_error — mantida por omissão"

        resposta_llm = result.get("resposta", "").strip().upper()
        confianca = result.get("confianca", "baixa").lower()
        raciocinio = result.get("raciocinio", "")

        correct_norm = correct_marked.upper()
        resposta_norm = resposta_llm.upper()

        # Se o LLM não tem confiança, não rejeitar com base nisto
        if confianca == "baixa":
            return True, f"confiança baixa — mantida ({raciocinio[:60]})"

        if correct_norm == resposta_norm:
            return True, f"resposta verificada: {resposta_llm} == {correct_marked}"
        else:
            return False, f"RESPOSTA ERRADA: LLM escolheu {resposta_llm}, marcada é {correct_marked}. {raciocinio[:80]}"

    def _reclassify_topic(self, pergunta: Dict, novo_uc_id: int) -> str:
        """
        Dado um swap de UC, pede ao LLM para atribuir o tópico correto
        da UC de destino à pergunta.
        Retorna o tópico mais adequado (texto exato de UC_INFO).
        """
        uc_info = UC_INFO.get(novo_uc_id, {})
        topicos_destino = uc_info.get("topicos", [])
        if not topicos_destino:
            return ""

        topicos_str = "\n".join(f"- {t}" for t in topicos_destino)

        prompt = f"""Tens esta pergunta de engenharia:
{json.dumps(pergunta, ensure_ascii=False)}

Pertence à unidade curricular "{uc_info.get('nome', '')}" (ID: {novo_uc_id}).
Os tópicos disponíveis dessa UC são:
{topicos_str}

Indica qual dos tópicos acima melhor classifica esta pergunta.
Responde APENAS com o texto exato do tópico, sem mais nada."""

        raw = self._invoke_llm(prompt).strip()

        # Validar que a resposta é mesmo um dos tópicos disponíveis
        if raw in topicos_destino:
            return raw

        # Fallback: correspondência parcial por palavras
        best = next(
            (t for t in topicos_destino if any(p in t.lower() for p in raw.lower().split())),
            topicos_destino[0]  # último recurso: primeiro tópico da UC
        )
        return best

    def validate_question(self, pergunta: Dict, contexto_chunk: str) -> Tuple[Dict, bool, str]:
        id_uc = int(pergunta.get("id_uc", 0))
        prompt = self._build_validation_prompt(pergunta, contexto_chunk, id_uc)

        raw = self._invoke_llm(prompt)

        try:
            match = re.search(r'\{[^{}]+\}', raw, re.DOTALL)
            result = json.loads(match.group()) if match else {}
        except:
            result = {}

        # Swap de UC se o LLM identificar uma UC mais correta
        uc_correta_id = result.get("uc_correta_id")
        if uc_correta_id and str(uc_correta_id) != str(id_uc) and int(uc_correta_id) in UC_INFO:
            print(f"    🔄 Swap: UC {id_uc} → {uc_correta_id}")
            novo_topico = self._reclassify_topic(pergunta, int(uc_correta_id))
            pergunta = {**pergunta, "id_uc": str(uc_correta_id), "topic": novo_topico}
            return pergunta, True, f"Transferida para UC {uc_correta_id} (tópico: {novo_topico}): {result.get('justificacao', '')}"

        aprovada_validacao = (
            result.get("no_ambito", True)
            and result.get("factualmente_correta", True)
            and result.get("avalia_competencia_certa", True)
        )
        justificacao = result.get("justificacao", "sem justificação")

        if not aprovada_validacao:
            return pergunta, False, justificacao

        # Segundo passo: verificação independente da resposta correta
        resposta_ok, motivo_resposta = self._verify_answer_correctness(pergunta)
        if not resposta_ok:
            return pergunta, False, f"Verificação de resposta falhou: {motivo_resposta}"

        return pergunta, True, f"{justificacao} | {motivo_resposta}"

    def validate_batch(self, perguntas: List[Dict], contexto_chunk: str) -> Tuple[List[Dict], List[Dict]]:
        aprovadas, rejeitadas = [], []
        for i, p in enumerate(perguntas):
            p, aprovada, justificacao = self.validate_question(p, contexto_chunk)
            if aprovada:
                aprovadas.append(p)
            else:
                rejeitadas.append(p)
            print(f"    Validação {i+1}/{len(perguntas)}: {'✓' if aprovada else '✗'} — {justificacao[:80]}")
        return aprovadas, rejeitadas

    def generate_questions(self, filename: str, validar: bool = True) -> Tuple[List[Dict], List[Dict]]:
        """Gera e opcionalmente valida perguntas para todos os chunks do ficheiro.

        Retorna (aprovadas, rejeitadas). Se validar=False, todas ficam em aprovadas
        e rejeitadas fica vazio.
        """
        sample = self.db.get(where={"nome_ficheiro": filename}, limit=1)
        if not sample["metadatas"]:
            print(f"Ficheiro {filename} não encontrado.")
            return [], []

        id_uc = sample["metadatas"][0].get("uc_id")
        uc_info = UC_INFO.get(int(id_uc) if id_uc else 0, {})
        topicos_permitidos = uc_info.get("topicos", [])
        topicos_str = "\n".join(f"- {t}" for t in topicos_permitidos)

        subcapitulos = self.get_chunks_by_subcap(filename)
        if not subcapitulos:
            print("Nenhum subcapitulo encontrado.")
            return [], []

        todas_aprovadas: List[Dict] = []
        todas_rejeitadas: List[Dict] = []
        total_batches = 0

        for dados in subcapitulos.values():
            docs = dados["docs"]
            batch_chars = 0
            for doc in docs:
                if batch_chars + len(doc) > self.BATCH_CHARS and batch_chars > 0:
                    total_batches += 1
                    batch_chars = 0
                batch_chars += len(doc)
            if batch_chars > 0:
                total_batches += 1

        batch_atual = 0

        for subcap, dados in subcapitulos.items():
            docs = dados["docs"]
            cap = dados["capitulo"]
            batch, batch_chars = [], 0

            for doc in docs:
                if batch_chars + len(doc) > self.BATCH_CHARS and batch:
                    batch_atual += 1
                    contexto_chunk = "\n\n".join(batch)
                    novas = self.process_chunks(batch, subcap, cap, topicos_str, self.PERGUNTAS_POR_BATCH, id_uc, topicos_permitidos)

                    if validar:
                        aprov, rejeit = self.validate_batch(novas, contexto_chunk)
                    else:
                        aprov, rejeit = novas, []

                    todas_aprovadas.extend(aprov)
                    todas_rejeitadas.extend(rejeit)
                    print(f"  Batch {batch_atual}/{total_batches} - '{subcap[:40]}': +{len(aprov)} aprovadas, {len(rejeit)} rejeitadas. Total aprovadas: {len(todas_aprovadas)}")
                    batch, batch_chars = [], 0

                batch.append(doc)
                batch_chars += len(doc)

            if batch:
                batch_atual += 1
                contexto_chunk = "\n\n".join(batch)
                novas = self.process_chunks(batch, subcap, cap, topicos_str, self.PERGUNTAS_POR_BATCH, id_uc, topicos_permitidos)

                if validar:
                    aprov, rejeit = self.validate_batch(novas, contexto_chunk)
                else:
                    aprov, rejeit = novas, []

                todas_aprovadas.extend(aprov)
                todas_rejeitadas.extend(rejeit)
                print(f"  Batch {batch_atual}/{total_batches} - '{subcap[:40]}': +{len(aprov)} aprovadas, {len(rejeit)} rejeitadas. Total aprovadas: {len(todas_aprovadas)}")

        print(f"\nConcluído: {len(todas_aprovadas)} aprovadas, {len(todas_rejeitadas)} rejeitadas — {batch_atual} batches processados.")
        return todas_aprovadas, todas_rejeitadas

    def export_json(self, perguntas: List[Dict], nome_arquivo: str):
        with open(nome_arquivo, 'w', encoding='utf-8') as f:
            json.dump(perguntas, f, indent=2, ensure_ascii=False)
        print(f"Guardado: {nome_arquivo}")


if __name__ == "__main__":
    gerador = QuestionGenerator()
    aprovadas, rejeitadas = gerador.generate_questions(
        "book.pdf",
        validar=True
    )
    gerador.export_json(aprovadas, "book_aprovadas.json")
    gerador.export_json(rejeitadas, "book_rejeitadas.json")