import os
import re
import json
import time
import uuid
from typing import List, Dict, Tuple
from dotenv import load_dotenv
from langchain_chroma import Chroma
from langchain_huggingface import HuggingFaceEmbeddings
import torch
from langchain_groq import ChatGroq
from IAEduAPI import IAEduAPI
_BASE_DIR = os.path.dirname(os.path.abspath(__file__))

class QuestionGeneratorTeacher:
    TOPICOS_UC = {
        40332: ["Introdução aos sistemas digitais", "Representação e codificação de informação", "Álgebra de Boole", "Lógica combinatória elementar", "Blocos combinatórios", "Circuitos aritméticos", "Sistemas sequenciais", "Estratégias de análise de circuitos sequenciais", "Blocos sequenciais fundamentais", "Síntese de máquinas de estado"],
        40333: ["Introdução às FPGAs, ferramentas e kits de desenvolvimento", "Modelação em VHDL: Componentes combinatórios e aritméticos", "Modelação em VHDL: Circuitos sequenciais, registos e memórias", "Máquinas de Estados Finitos (FSM) em VHDL", "Testbenches e estratégias de depuração de circuitos", "Precauções de projeto: Reset, sincronização e restrições temporais"],
        42545: ["Organização funcional e programação em assembly", "Tradução de linguagens de alto nível e assemblagem", "Aritmética de vírgula fixa e flutuante", "Estrutura interna do processador e etapas de execução", "Arquitecturas de processadores com pipeline"],
        42548: ["Organização básica do sistema de entradas/saídas", "Dispositivos periféricos", "Organização de barramentos de dados", "Interfaces e barramentos paralelos e série", "Software para gestão de dispositivos de E/S", "Sistema de memória e análise de memória cache"],
        42454: ["Clubes do Ronaldo","Vida do Ronaldo", "Idade do Ronaldo" ]
    }
    DEFAULT_DB_PATH = os.path.join(_BASE_DIR, "chroma_db")

    def __init__(self, db_path: str = DEFAULT_DB_PATH, device="cuda", embeddings=None):
        _dir = os.path.dirname(os.path.abspath(__file__))
        load_dotenv(os.path.join(_dir, "keys.env"), override=True)
        
        gemma_token = os.getenv("TOKEN_GEMMA")
        groq_key = os.getenv("GROQ_API_KEY")
        if not gemma_token or not groq_key:
            raise ValueError("TOKEN_GEMMA ou GROQ_API_KEY não definidas no ambiente.")

        os.environ["HF_TOKEN"] = gemma_token
        os.environ["GROQ_API_KEY"] = groq_key

        

        if embeddings is not None:
            self.embeddings = embeddings
        else:
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
            relevance_score_fn=lambda distance: 1 - distance
        )

        self.vectorstore = Chroma(
            persist_directory=db_path,
            embedding_function=self.embeddings,
            collection_name="conhecimento_geral",
            relevance_score_fn=lambda distance: 1 - distance
        )

        self.llm = IAEduAPI(
            api_key=os.getenv("GPT_API_KEY"),
            endpoint=os.getenv("ENDPOINT_GPT"),
            channel_id=os.getenv("CANAL_ID"),
        )
        self.llm_groq = ChatGroq(model_name="openai/gpt-oss-120b", temperature=0.2)
    # Chamar API IAEdu, se falhar, tentar novamente com backoff exponencial
    def _invoke_llm_qg(self, prompt: str) -> str:
        self.llm_qg.thread_id = str(uuid.uuid4())
        raw = None
        attempt = 0
        while raw is None:
            try:
                raw = self.llm_qg.invoke(prompt).content
            except Exception as e:
                wait = min(10 * (attempt + 1), 300)
                print(f"Erro na API de geração: {e}. A aguardar {wait}s... (tentativa {attempt + 1})")
                time.sleep(wait)
                attempt += 1
        return raw

    def _get_context_from_book(self, ficheiro_id: str, topic: str, k: int = 15):
        # 1. Obter metadados do livro (ID da UC)
        print(f"🔍 Procurando ficheiro: '{ficheiro_id}' em ChromaDB...")
        try:
            sample = self.db.get(where={"ficheiro_id": ficheiro_id}, limit=1)
            if not sample["metadatas"] or len(sample["metadatas"]) == 0:
                print(f"⚠️ Ficheiro '{ficheiro_id}' não encontrado com 'ficheiro_id'. A tentar com outras chaves...")
                # Fallback: tentar obter todas as coleções
                all_items = self.db.get(limit=5)
                if all_items["metadatas"]:
                    print(f"📋 Primeiros metadados em ChromaDB: {all_items['metadatas'][0]}")
                raise FileNotFoundError(f"Ficheiro '{ficheiro_id}' não encontrado na base de dados.")
        except Exception as e:
            print(f"❌ Erro ao obter metadados: {str(e)}")
            raise
        
        metadata = sample["metadatas"][0]
        id_uc = metadata.get("uc_id") or metadata.get("id_uc")
        print(f"✅ Ficheiro encontrado com UC_ID: {id_uc}")
        
        topicos_permitidos = self.TOPICOS_UC.get(int(id_uc) if id_uc else 0, [])
        if not topicos_permitidos:
            print(f"⚠️ UC {id_uc} não tem tópicos definidos")
            return None, None, None, None
            
        topicos_str = "\n".join(f"- {t}" for t in topicos_permitidos)

        # 2. Traduzir tópico para termos de busca em inglês
        prompt_prep = f"""Identifica os termos técnicos desta pergunta em Português e escreve-os em Inglês.
    Pergunta: "{topic}"
    Responde apenas com os termos técnicos em Inglês e algo que esteja relacionado.
    Exemplo: Vírgula Flutuante, Floating Point, IEEE 754 single/double precision.
    DEVOLVE NO FORMATO: "termo1, termo2, termo3"
    """
        try:
            termos_en = self.llm_groq.invoke(prompt_prep).content.strip()
            query_para_busca = f"{topic} {termos_en}"
            print(f"🔎 Tópico Original: '{topic}' | Termos para busca: '{query_para_busca}'")
        except Exception as e:
            query_para_busca = topic
            print(f"⚠️ Falha na tradução de termos: {e}")
        query_formatada = f"task: search result | query: {query_para_busca}"
        print(f"DEBUG - Query Formatada para Busca: '{query_formatada}'")

        resultados_teste = self.vectorstore.similarity_search_with_relevance_scores(query_formatada, k=5)
        best_score = max(resultados_teste, key=lambda x: x[1])[1]
        print(f"DEBUG - '{topic}' | Score Gemma: {best_score:.4f}")

        if best_score < 0.40:
            return None, None, None, None
        # 3. Fazer a busca no ChromaDB filtrando pelo livro
        print(f"🔄 A procurar contexto relevante com '{query_para_busca}'...")
        try:
            retriever = self.db.as_retriever(
                search_type="mmr",
                search_kwargs={"k": k, "fetch_k": 30, "filter": {"ficheiro_id": ficheiro_id}}
            )
            docs = retriever.invoke(query_para_busca)
        except Exception as e:
            print(f"⚠️ Erro na busca: {e}. A tentar sem filtro...")
            # Fallback sem filtro
            retriever = self.db.as_retriever(
                search_type="mmr",
                search_kwargs={"k": k, "fetch_k": 30}
            )
            docs = retriever.invoke(query_para_busca)

        if not docs or len(docs) == 0:
            print(f"❌ Nenhum documento encontrado para '{query_para_busca}'")
            return None, None, None, None

        print(f"✅ Encontrados {len(docs)} documentos relevantes")

        # 4. Construir o contexto
        contexto_str = ""
        for i, d in enumerate(docs):
            conteudo = d.page_content
            if " | text: " in conteudo:
                conteudo = conteudo.split(" | text: ", 1)[1]
            pagina = d.metadata.get('pagina') or d.metadata.get('page') or '?'
            contexto_str += f"\n--- [Pág {pagina}] ---\n{conteudo}\n"
        
        print(f"📚 Contexto compilado com {len(contexto_str)} caracteres")
        return contexto_str, topicos_permitidos, topicos_str, id_uc

    def generate_questions(self, context: str, topicos_str: str, n_perguntas: int, id_uc: str, topicos_permitidos: List[str], difficulty: str, question_type: str) -> List[Dict]:
        prompt = f"""És um professor de engenharia a criar exercícios de avaliação.

        Com base no conteúdo técnico abaixo, gera {n_perguntas} perguntas do tipo '{question_type}' com dificuldade '{difficulty}'.
        Se o conteúdo der para criar perguntas mas não {n_perguntas}, gera as que conseguires. Se o conteúdo não estiver relacionado com nenhum dos tópicos disponíveis, responde apenas com: []

        CONTEUDO:
        {context}

        TOPICOS DISPONIVEIS:
        {topicos_str}


        REGRAS:
        1. Cada pergunta deve estar diretamente baseada no conteúdo fornecido MAS NÃO O DEVE MENCIONAR.
        2. Cada pergunta deve pertencer a um dos tópicos disponíveis.
        3. Opções incorretas devem ser plausíveis mas claramente erradas.
        4. A dificuldade deve ser '{difficulty}'. Se a dificuldade for 'variada', podes usar 'easy', 'medium', ou 'hard'.
        5. Responde APENAS com uma lista de JSONs, sem texto adicional.
        6. Perguntas do tipo 'True/False' devem ter apenas as opções "Verdadeiro" e "Falso".

        FORMATO DA LISTA DE JSONs:
        [{{"question": "...", "type": "{question_type}", "options": ["A) ...", "B) ...", "C) ...", "D) ..."], "correct": "A", "difficulty": "{difficulty}", "explanation": "...", "topic": "..."}}]"""

        print(f"📤 A chamar LLM para gerar {n_perguntas} perguntas ({question_type}, {difficulty})...")
        try:
            raw = self.llm_groq.invoke(prompt).content.strip()
            print(f"📥 Resposta do LLM recebida: {len(raw)} caracteres")
        except Exception as e:
            print(f"❌ Erro ao chamar LLM: {str(e)}")
            raise
        
        perguntas = []
        
        try:
            # O LLM deve devolver uma lista de JSONs
            print(f"🔍 A fazer parse JSON da resposta...")
            lista_json = json.loads(raw)
            if not isinstance(lista_json, list):
                # Fallback se não for uma lista
                print(f"⚠️ Resposta não é lista, a extrair JSONs individuais...")
                raw_blocks = re.findall(r'\{[^{}]+\}', raw, re.DOTALL)
                lista_json = [json.loads(b) for b in raw_blocks]

        except json.JSONDecodeError as e:
            # Fallback para extrair JSONs individuais se o parsing da lista falhar
            print(f"⚠️ Parse JSON falhou: {e}. A extrair blocos individuais...")
            raw_blocks = re.findall(r'\{[^{}]+\}', raw, re.DOTALL)
            if not raw_blocks:
                print(f"❌ Nenhum bloco JSON encontrado na resposta: {raw[:200]}")
                return []
            lista_json = []
            for b in raw_blocks:
                try:
                    lista_json.append(json.loads(b))
                except json.JSONDecodeError as je:
                    print(f"⚠️ Erro ao fazer parse de bloco: {je}")
                    continue
        
     
        
        for i, ex in enumerate(lista_json):
            try:
                question = ex.get("question", "").strip()
                if not question or len(question) < 20:
                    print(f"⚠️ Pergunta {i+1} muito curta, ignorada")
                    continue

                topic = ex.get("topic", "").strip()
                if topic not in topicos_permitidos:
                    # Tentar encontrar match aproximado
                    topic = next((t for t in topicos_permitidos if topic.lower() in t.lower() or t.lower() in topic.lower()), None)
                    if topic is None:
                        print(f"⚠️ Pergunta {i+1} tem tópico não permitido: '{ex.get('topic')}'")
                        continue

                perguntas.append({
                    "question": question,
                    "type": ex.get("type", "Multiple Choice"),
                    "options": ex.get("options", []),
                    "correct": ex.get("correct", ""),
                    "difficulty": ex.get("difficulty", "medium"),
                    "explanation": ex.get("explanation", ""),
                    "topic": topic,
                    "id_uc": id_uc
                })
                print(f"✅ Pergunta {i+1} adicionada: '{question[:50]}...'")
            except Exception as e:
                print(f"❌ Erro ao processar pergunta {i+1}: {e}")
                continue

        print(f"📊 Total de perguntas válidas: {len(perguntas)}/{len(lista_json)}")
        return perguntas

    def generate_questions_by_topic(self, ficheiro_id: str, topic: str, n_perguntas: int, difficulty: str = "variada", question_type: str = "Escolha Múltipla"):

        try:
            # Obter contexto relevante do livro
            contexto, topicos_permitidos, topicos_str, id_uc = self._get_context_from_book(ficheiro_id, topic)
            
            if not contexto:
                print(f"❌ Não foi possível encontrar contexto relevante para '{topic}' em '{ficheiro_id}'.")
                return []

            # Gerar perguntas com base no contexto
            perguntas = self.generate_questions(contexto, topicos_str, n_perguntas, id_uc, topicos_permitidos, difficulty, question_type)
            

            return perguntas
        
        except Exception as e:
        
            import traceback
            traceback.print_exc()
            print(f"{'='*70}\n")
            return []

    def export_json(self, perguntas: List[Dict], nome_arquivo: str):
        with open(nome_arquivo, 'w', encoding='utf-8') as f:
            json.dump(perguntas, f, indent=2, ensure_ascii=False)
        print(f"Guardado: {nome_arquivo}")

'''
if __name__ == "__main__":
    gerador = QuestionGeneratorTeacher()
    

    nome_livro = "patterson_book.pdf"
    topico_interesse = "endereçamento de memória e instruções"
    num_perguntas_desejadas = 7
    dificuldade_desejada = "hard"  # easy, medium, hard, variada
    tipo_pergunta_desejado = "True/False" # Escolha Múltipla, True/False
    
    Questions = gerador.generate_questions_by_topic(
        ficheiro_id=nome_livro,
        topic=topico_interesse,
        n_perguntas=num_perguntas_desejadas,
        difficulty=dificuldade_desejada,
        question_type=tipo_pergunta_desejado
    )
    
    if Questions:
        gerador.export_json(Questions, f"perguntas_{topico_interesse.replace(' ', '_')}.json")
'''