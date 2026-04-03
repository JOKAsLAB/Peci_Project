# AI Engine (RAG Local)

Motor IA local para indexacao de documentos e chatbot com contexto.

## Navegacao rapida

- [Index da documentacao](index.md)
- [Master end-to-end](master.md)
- [Projeto (visao geral)](project.md)
- [Estrutura do repositorio](repo_estrutura.md)
- [Scripts (run e testes)](scripts.md)
- [Backend](backend.md)
- [Admin_Docente](admin_docente.md)
- [Aluno](aluno.md)
- [AI Engine](ai_engine.md)
- [Infrastructure](infrastructure.md)
- [Build](build.md)
- [Website promocional](website_promocional.md)

## Stack

- Python
- LangChain
- ChromaDB
- Streamlit
- Groq (LLM)

## Objetivo funcional

Este modulo suporta o fluxo IA local em duas fases:

1. ingestao/indexacao de bibliografia,
2. retrieval + resposta contextual no chatbot.

## Estrutura principal

```text
ai_engine/
├── ImportFiles.py
├── chatbot.py
├── biblio/
├── chroma_db_gemma/
├── requirements.txt
└── keys.env
```

## Ficheiros chave

- `ImportFiles.py`: leitura de PDFs, chunking e indexacao no Chroma.
- `chatbot.py`: prompt + retrieval + resposta via LLM.
- `biblio/`: documentos de base para indexacao.
- `chroma_db_gemma/`: persistencia vetorial local.

## Para que serve

- Indexar bibliografia tecnica em vetor store (Chroma).
- Permitir perguntas e respostas com contexto documental.
- Apoiar o ciclo de geracao/explicacao de conteudo em fase local.

## Quando e necessario

- Necessario quando a equipa precisa de IA local ativa.
- Opcional em tarefas exclusivas de frontend/backend sem RAG.

## Pre-requisitos

- Python 3.11+
- ChromaDB acessivel (local por Docker ou instancia equivalente)
- chaves validas em `keys.env`

## Execucao local

```powershell
cd ai_engine
python -m venv .venv
.\.venv\Scripts\Activate.ps1
pip install -r requirements.txt
python ImportFiles.py
python -m streamlit run chatbot.py
```

## Fluxo operacional

1. Colocar/validar bibliografia em `ai_engine/biblio`.
2. Executar `ImportFiles.py` para indexar embeddings.
3. Executar `chatbot.py` via Streamlit.
4. Validar respostas e fontes recuperadas.

## Observacoes

- O endpoint backend de bridge IA pode estar em fase de stub dependendo da branch.
- `keys.env` deve conter tokens locais e nao deve ser publicado com segredos reais.

## Troubleshooting rapido

- erro de token: validar variaveis em `keys.env`.
- respostas vazias: validar se a indexacao foi executada com sucesso.
- falhas de pacote: reinstalar deps em ambiente virtual isolado.
