FROM python:3.11-slim

# Dependências de sistema (asyncpg, chromadb, torch CPU)
RUN apt-get update && apt-get install -y --no-install-recommends \
    gcc \
    g++ \
    libpq-dev \
    libgomp1 \
    && rm -rf /var/lib/apt/lists/*

WORKDIR /app

# Instalar dependências Python antes de copiar código (cache de layers)
COPY backend/backend/app/requirements.txt /tmp/backend-requirements.txt
COPY ai_engine/requirements.txt           /tmp/ai-requirements.txt

RUN pip install --no-cache-dir \
    torch --index-url https://download.pytorch.org/whl/cpu && \
    pip install --no-cache-dir \
    -r /tmp/backend-requirements.txt \
    -r /tmp/ai-requirements.txt

# Descarrega o modelo durante o build para não precisar de o fazer em runtime
ARG HF_TOKEN=""
RUN HF_TOKEN=${HF_TOKEN} python -c \
    "from langchain_huggingface import HuggingFaceEmbeddings; import torch; \
    HuggingFaceEmbeddings(model_name='google/embeddinggemma-300m', \
    model_kwargs={'device': 'cpu', 'trust_remote_code': True, 'model_kwargs': {'torch_dtype': torch.float32}}, \
    encode_kwargs={'normalize_embeddings': True})"

COPY ai_engine/  ./ai_engine/
COPY backend/backend/ ./backend/backend/

WORKDIR /app/backend/backend

ENV PYTHONUNBUFFERED=1

EXPOSE 8000

CMD ["uvicorn", "app.main:app", "--host", "0.0.0.0", "--port", "8000"]
