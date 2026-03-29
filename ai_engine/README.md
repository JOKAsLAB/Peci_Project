# Peci_Project

Motor IA local do projeto PECI (RAG + chatbot).

## Stack

- Streamlit
- LangChain
- ChromaDB
- HuggingFace embeddings
- Groq (LLM)

## Pré-requisitos

- Python 3.11+
- Ambiente virtual ativo
- ChromaDB acessível (via `infrastructure/docker-compose.yml` ou instância equivalente)
- Chaves válidas em `keys.env`

## Instalação

1. Criar e ativar ambiente virtual:

```powershell
python -m venv .venv
.\.venv\Scripts\Activate.ps1
```

2. Instalar dependências:

```powershell
pip install -r requirements.txt
```

3. Configurar chaves no ficheiro `keys.env`:

```env
TOKEN_GEMMA=...
GROQ_API_KEY=...
```

4. Garantir bibliografia disponível em `ai_engine/biblio/` para indexação.

## Como correr

### 1) Indexar PDFs

```powershell
python ImportFiles.py
```

O script realiza:

- leitura de documentos de `biblio/`
- chunking textual
- geração de embeddings
- persistência vetorial em Chroma

### 2) Iniciar o chatbot (Streamlit)

```powershell
python3 -m streamlit run chatbot.py
```

## Fluxo de dados IA

1. Documentos são ingeridos em `ImportFiles.py` e indexados no Chroma com metadados.
2. `chatbot.py` recupera contexto relevante por similaridade vetorial.
3. O prompt enriquecido é enviado ao modelo LLM (Groq).
4. A resposta é devolvida com fundamentação contextual.

## Estado de integração com backend

- O backend FastAPI mantém `POST /api/v1/ai-tutor/query` como stub (`501`) nesta branch.
- O fluxo operacional de IA continua local (Streamlit) até conclusão da bridge backend<->RAG.
