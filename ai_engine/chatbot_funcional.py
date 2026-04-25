import os
import torch
from langchain_chroma import Chroma
from langchain_huggingface import HuggingFaceEmbeddings
from dotenv import load_dotenv
from langchain_groq import ChatGroq
from IAEduAPI import IAEduAPI

_BASE_DIR = os.path.dirname(os.path.abspath(__file__))
_CHROMA_PATH = os.path.join(_BASE_DIR, "chroma_db")

class Chatbot:
    def __init__(self, db_path="./chroma_db", device="cuda", embeddings=None):
        load_dotenv(os.path.join(_BASE_DIR, "keys.env"))

        gemma_token = os.getenv("TOKEN_GEMMA")
        groq_key = os.getenv("GROQ_API_KEY")
        if not gemma_token:
            raise ValueError("TOKEN_GEMMA não definida no ambiente.")

        os.environ["HF_TOKEN"] = gemma_token
        os.environ["GROQ_API_KEY"] = groq_key

        if embeddings is not None:
            self.embeddings = embeddings
        else:
            model_kwargs = {
                "device": device,
                "trust_remote_code": True,
                "model_kwargs": {"torch_dtype": torch.float32}
            }
            self.embeddings = HuggingFaceEmbeddings(
                model_name='google/embeddinggemma-300m',
                model_kwargs=model_kwargs,
                encode_kwargs={'normalize_embeddings': True}
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

    def responder_pergunta(self, query, k=10):
        
        prompt_prep = f"""
        Identifica os termos técnicos desta pergunta em Português e escreve-os em Inglês.
        Pergunta: "{query}"
        Responde apenas com os termos técnicos em Inglês e algo que esteja relacionado.
        Exemplo: Vírgula Flutuante , Floating Point, IEEE 754 single/double precision ou seja decompôes o termo técnico em partes e traduz cada parte.
        DEVOLVE NO FORMATO: "termo1, termo2, termo3"
        """

        try:
            termos_en = self.llm_groq.invoke(prompt_prep).content.strip()
            query_para_busca = f"{query} {termos_en}"
            print(f"DEBUG - Query Original: '{query}' | Termos Técnicos (EN): '{termos_en}'")
        except Exception as e:
            query_para_busca = query
            print(f"DEBUG - Falha no request de tradução técnica: {e}")

        query_formatada = f"task: search result | query: {query_para_busca}"
        print(f"DEBUG - Query Formatada para Busca: '{query_formatada}'")

        resultados_teste = self.vectorstore.similarity_search_with_relevance_scores(query_formatada, k=5)

        if not resultados_teste:
            return "Biblioteca não disponível ou vazia.", []

        best_score = max(resultados_teste, key=lambda x: x[1])[1]
        print(f"DEBUG - '{query}' | Score Gemma: {best_score:.4f}")

        if best_score < 0.40:
            return f"Tema não coberto pelos manuais técnicos. (Relevância: {best_score:.2f})", []

        retriever = self.vectorstore.as_retriever(
            search_type="mmr",
            search_kwargs={"k": k, "fetch_k": 30}
        )
        docs = retriever.invoke(query_formatada)

        contexto_str = ""
        fontes = set()

        for d in docs:
            conteudo = d.page_content
            if " | text: " in conteudo:
                conteudo = conteudo.split(" | text: ", 1)[1]

            livro = d.metadata.get("nome_ficheiro", "Livro")
            pag = d.metadata.get("pagina", "?")
            contexto_str += f"\n--- [{livro} | Pág {pag}] ---\n{conteudo}\n"
            fontes.add(f"📖 {livro} (Pág. {pag})")

        prompt = f"""
                És um Explicador de Engenharia chamado Andy, a responder numa app mobile. Responde APENAS com base no contexto.
                CONTEXTO: {contexto_str}
                PERGUNTA: {query}
                REGRAS OBRIGATÓRIAS:
                1. Baseia-te EXCLUSIVAMENTE no CONTEXTO fornecido. Sem suposições nem conhecimento externo.
                2. Resposta concisa: máximo 300 palavras. Vai direto ao ponto, sem introduções longas.
                3. Fórmulas: usa blocos de código Markdown (``` ```) ou notação ASCII simples (ex: A = B AND C, F = A*B+C'). NÃO uses LaTeX nem $$ $$.
                4. Circuitos: descreve em texto ou tabela Markdown. Evita diagramas complexos.
                5. Explica de forma clara, didática e divertida para um aluno de engenharia.
                6. Analisa e explica o conteúdo — não o copies apenas.
                7. ÉS O COMPANHEIRO DE ESTUDO DO ALUNO SÊ DIVERTIDO E DIDÁTICO, NÃO UM MOTOR DE BUSCA.
                """
        try:
            res = self.llm.invoke(prompt)
            return res.content, sorted(list(fontes))
        except Exception as e:
            return f"Erro API: {str(e)}", []