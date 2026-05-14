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
    -r /tmp/backend-requirements.txt \
    -r /tmp/ai-requirements.txt

# Copiar código — mantém a estrutura de paths que o main.py espera:
#   /app/ai_engine/  ← ai_engine/
#   /app/backend/    ← backend/backend/
COPY ai_engine/  ./ai_engine/
COPY backend/backend/ ./backend/

WORKDIR /app/backend

EXPOSE 8000

CMD ["uvicorn", "app.main:app", "--host", "0.0.0.0", "--port", "8000"]
