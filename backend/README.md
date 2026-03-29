# PECI — Database & Backend

Repositório responsável pela base de dados e ligação ao backend (FastAPI) do projeto PECI — Plataforma de Apoio à Aprendizagem de Sistemas Digitais.

---

## Estrutura de Pastas

```
Peci_Project/
├── database/
│   ├── deletes/
│   │   ├── drop_indexes.sql
│   │   └── drop_tables.sql
│   ├── indexes.sql
│   └── schema.sql
├── script/
│   └── test/
│       └── sql/
│           ├── test_inserts.sql
│           ├── test_admin_professor_integrity.sql
│           ├── test_truncate.sql
│           └── useful_selects.sql
├── backend/
│   └── app/
│       ├── .env
│       ├── .env.example
│       ├── requirements.txt
│       ├── main.py
│       ├── database.py
│       ├── security.py
│       ├── models/
│       ├── schemas/
│       └── routers/
├── aluno/                       # Frontend Flutter (gitignore)
├── professor/                   # Frontend Vue.js (gitignore)
├── admin/                       # Frontend Vue.js (gitignore)
├── .vscode/
└── README.md
```

### Zoom in Backend

```
backend/
└── app/
	├── .env                     # Credenciais (nunca vai para o Git)
	├── .env.example             # Exemplo do .env (este vai para o Git)
	├── requirements.txt         # Dependências Python
	├── main.py                  # Ponto de entrada do FastAPI (+ / e /health)
	├── database.py              # Ligação à BD (engine, sessão)
	├── security.py              # JWT + hashing de passwords
	├── models/                  # Models SQLAlchemy (espelho das tabelas)
│   │   ├── __init__.py
│   │   ├── user.py              # Base_User, Student, Professor, Admin
│   │   ├── academic.py          # Course_Unit, Topic, Teaching_Material, Exercise
│   │   ├── gamification.py      # Progress, Streak
│   │   └── admin.py             # Request, Admin_Audit_Log
	├── schemas/                 # Schemas Pydantic (validação de dados da API)
│   │   ├── __init__.py
│   │   ├── user.py
│   │   ├── academic.py
│   │   ├── gamification.py
│   │   └── admin.py
	└── routers/                 # Endpoints FastAPI
		├── __init__.py
		├── deps.py              # Dependências de autenticação/autorização
		├── auth.py              # /api/v1/auth
		├── academic.py          # /api/v1/academic
		├── students.py          # /api/v1/students
		├── professors.py        # /api/v1/professors
		├── admin.py             # /api/v1/admin
		└── ai_tutor.py          # /api/v1/ai-tutor (stub 501 nesta branch)
```

---

## Pré-requisitos

- PostgreSQL 18
- VS Code com extensões **SQLTools** e **SQLTools PostgreSQL Driver**
- `psql` disponível no terminal (PATH configurado)

---

## Configuração Inicial

### 1. Criar o utilizador e a base de dados

Aceder ao PostgreSQL como superuser e correr:

```sql
CREATE USER peci_user WITH PASSWORD 'password_aqui';
CREATE DATABASE peci_db OWNER peci_user;
GRANT ALL PRIVILEGES ON DATABASE peci_db TO peci_user;
```

### 2. Criar as tabelas

```bash
psql -U peci_user -d peci_db -h localhost -f database/schema.sql
```

### 3. Criar os indexes

```bash
psql -U peci_user -d peci_db -h localhost -f database/indexes.sql
```

### 4. Verificar as tabelas criadas

```bash
psql -U peci_user -d peci_db -h localhost
```

```sql
\dt
```

---

## Comandos Úteis

Nota: Em vez dos comandos podes simplesmente correr o ficheiro correspondente "Run on active connection" ou usar o ficheiro rascunho "peci_local.session.sql"

### Testar os INSERTs

```bash
psql -U peci_user -d peci_db -h localhost -f script/test/sql/test_inserts.sql
```

### Esvaziar as tabelas (mantém estrutura)

```bash
psql -U peci_user -d peci_db -h localhost -f script/test/sql/test_truncate.sql
```

### Apagar todas as tabelas

```bash
psql -U peci_user -d peci_db -h localhost -f database/deletes/drop_tables.sql
```

### Apagar todos os indexes

```bash
psql -U peci_user -d peci_db -h localhost -f database/deletes/drop_indexes.sql
```

### Recriar tudo do zero

```bash
psql -U peci_user -d peci_db -h localhost -f database/deletes/drop_tables.sql
psql -U peci_user -d peci_db -h localhost -f database/schema.sql
psql -U peci_user -d peci_db -h localhost -f database/indexes.sql
```

### "Print" do estado das tabelas

```bash
psql -U peci_user -d peci_db -h localhost -f script/test/sql/useful_selects.sql
```

---

## Estrutura da Base de Dados

### Bloco 1 — Utilizadores

| Tabela           | Descrição                                                           |
| ---------------- | --------------------------------------------------------------------- |
| `Base_User`    | Tabela central com credenciais e dados comuns a todos os utilizadores |
| `Student`      | Dados de gamificação do estudante (XP, nível, streak)              |
| `Professor`    | Dados profissionais do professor                                      |
| `Admin`        | Dados de gestão do sistema                                           |
| `Professor_UC` | Tabela de junção — quais professores gerem quais UCs               |

### Bloco 2 — Conteúdo Académico

| Tabela                | Descrição                                                      |
| --------------------- | ---------------------------------------------------------------- |
| `Course_Unit`       | Unidade Curricular (ex: Sistemas Digitais, PECI)                 |
| `Topic`             | Tópico dentro de uma UC (ex: Portas Lógicas)                   |
| `Teaching_Material` | PDF uploaded pelo professor para alimentar o pipeline RAG        |
| `Exercise`          | Exercício ligado a um tópico — pode ser gerado por IA ou fixo |

### Bloco 3 — Gamificação

| Tabela       | Descrição                                                       |
| ------------ | ----------------------------------------------------------------- |
| `Progress` | Regista cada tentativa de um estudante num exercício             |
| `Streak`   | Log diário de estudo — valida dias consecutivos (tipo Duolingo) |

### Bloco 4 — Administração

| Tabela              | Descrição                                              |
| ------------------- | -------------------------------------------------------- |
| `Request`         | Pedidos enviados por professores a admins                |
| `Admin_Audit_Log` | Log imutável de todas as ações de admins (segurança) |

---

## Plano de Trabalho

### ✅ Fase 1 — Base de Dados

- [X] Schema desenhado e criado (`schema.sql`)
- [X] Indexes criados (`indexes.sql`)
- [X] INSERTs de teste validados (`test_inserts.sql`)
- [X] TRUNCATE de teste validado (`test_truncate.sql`)

### 🔲 Fase 2 — Ligação ao FastAPI

- [X] Configurar estrutura do projeto FastAPI
- [X] Instalar dependências (`fastapi`, `uvicorn`, `asyncpg`/`psycopg2`)
- [X] Configurar SQLAlchemy (ORM) — models por tabela
- [X] Implementar endpoints `/auth` — registo, login, JWT
- [X] Implementar endpoints `/students` — progresso, streak, XP
- [X] Implementar endpoints `/professors` — UCs, materiais, exercícios
- [X] Implementar endpoints `/admin` — utilizadores, requests, audit log
- [ ] Integrar bridge do tutor IA no backend (`/api/v1/ai-tutor/query` ainda responde 501)

---

## Backend FastAPI — Ligação à Base de Dados

Esta secção explica passo a passo como configurar o backend FastAPI para se ligar à base de dados PostgreSQL do projeto PECI.

### 1- Pré-requisitos:

Antes de começar, assegura-te de que tens:

- Python 3.11+ instalado e um ambiente virtual ativo (venv)
- PostgreSQL 18 em funcionamento
- .env configurado com as credenciais da base de dados
- Dependências Python instaladas (requirements.txt)

```bash
python -m venv venv
# Ativar venv:
# Windows:
venv\Scripts\activate
# Linux / Mac:
source venv/bin/activate

# Instalar dependências
pip install -r requirements.txt
```

Se estiveres em `backend/backend`, instala as dependências com:

```bash
pip install -r app/requirements.txt
```

### 2- Configurar o .env

Cria o ficheiro .env com o seguinte formato (podes copiar de .env.example):

```
DB_USER=peci_user
DB_PASSWORD=password_aqui
DB_HOST=localhost
DB_PORT=5432
DB_NAME=peci_db

SECRET_KEY=uma_chave_secreta_aqui
ALGORITHM=HS256
ACCESS_TOKEN_EXPIRE_MINUTES=60
```

### Testar a ligação à base de dados

No main.py, podes testar se a ligação funciona no startup:

```bash
python -m uvicorn app.main:app --reload
```

A API estará disponível em http://127.0.0.1:8000

Health checks rápidos:

```bash
curl http://127.0.0.1:8000/
curl http://127.0.0.1:8000/health
```

---

## Testes de Smoke da API

Foi adicionada uma suíte de smoke tests em:

```
backend/backend/tests/smoke/
```

Cobertura da suíte:

- `/api/v1/auth` (register, login, me)
- `/api/v1/academic` (course-units, exercises)
- `/api/v1/students` (me, exercises, streak, progress)
- `/api/v1/professors` (course-units, exercises, materials, requests)
- `/api/v1/admin` (users, requests, course-units) com conta admin temporária auto-criada quando não existem credenciais fornecidas
- `/api/v1/ai-tutor/query` (valida resposta 501 esperada nesta branch)

### Como correr

No diretório `backend/backend`:

```bash
pip install -r app/requirements.txt
pip install -r requirements-dev.txt
pytest tests/smoke -q
```

Execução automatizada (arranca API local, espera healthcheck, corre smoke tests e termina servidor):

```powershell
.\script\test\run_backend_smoke.ps1
```

Variáveis opcionais para cobrir endpoints admin:

```bash
SMOKE_ADMIN_EMAIL=admin@dominio.pt
SMOKE_ADMIN_PASSWORD=password
```

Sem estas variáveis, a suíte cria automaticamente uma conta admin local temporária para validar os endpoints de administração.

### Validação transversal recomendada (escopo web + backend + SQL)

Na raiz do monorepo:

```powershell
.\script\test\run_all_tests.ps1 -SkipAluno -SqlPass <password>
```

Este fluxo valida backend smoke, stores web (admin + professor) e SQL, excluindo apenas os widget tests Flutter quando a iteração não inclui a app aluno.

### Bootstrap local recomendado para smoke tests

Quando há mismatch entre scripts SQL base e naming esperado pelo ORM, usa o bootstrap local compatível antes de correr a suíte:

```bash
cd backend/backend
set PGPASSWORD=password_aqui
"C:/Program Files/PostgreSQL/18/bin/psql.exe" -h 127.0.0.1 -U peci_user -d peci_db -w -f ../../script/backend/local_schema_orm_compatible.sql
```
