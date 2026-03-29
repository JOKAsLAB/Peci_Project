# PECI — Database & Backend

Repositório responsável pela base de dados e backend (FastAPI) do projeto PECI — Plataforma de Apoio à Aprendizagem de Sistemas Digitais.

Este documento foca-se no backend: arquitetura, setup local, execução, autenticação, endpoints, testes e troubleshooting.

---

## Estrutura de Pastas

```text
Peci_Project/
├── backend/
│   ├── README.md
│   └── backend/
│       ├── app/
│       │   ├── .env.example
│       │   ├── database.py
│       │   ├── main.py
│       │   ├── security.py
│       │   ├── models/
│       │   ├── routers/
│       │   └── schemas/
│       ├── requirements-dev.txt
│       └── tests/smoke/
├── database/
│   ├── schema.sql
│   ├── indexes.sql
│   └── deletes/
├── infrastructure/
│   └── docker-compose.yml
└── script/
		├── backend/
		├── run/
		└── test/
```

### Zoom in Backend App

```text
backend/backend/app/
├── .env.example              # Template de variáveis de ambiente
├── database.py               # Config da ligação DB, session factory e dependency get_db
├── main.py                   # FastAPI app, CORS, startup check, health routes, include routers
├── security.py               # Hash de passwords + criação/validação JWT
├── models/                   # SQLAlchemy models
│   ├── enum.py               # Enums partilhados (roles, status, request types, etc.)
│   ├── user.py
│   ├── academic.py
│   ├── gamification.py
│   └── admin.py
├── schemas/                  # Pydantic request/response schemas
│   ├── user.py
│   ├── academic.py
│   ├── gamification.py
│   └── admin.py
└── routers/                  # Endpoints por domínio
		├── auth.py
		├── academic.py
		├── students.py
		├── professors.py
		├── admin.py
		├── ai_tutor.py
		└── deps.py
```

---

## Arquitetura Backend (Visão Prática)

### Stack

- FastAPI (API HTTP)
- SQLAlchemy 2.x assíncrono
- asyncpg (driver PostgreSQL)
- Pydantic v2 + pydantic-settings
- JWT com `python-jose`
- Hash de password com `passlib[bcrypt]`
- Enums tipados para contratos de domínio (`UserRole`, `UserStatus`, `RequestStatus`, `RequestType`)
- Campos académicos e de gamificação tipados por ENUM (`MaterialStatus`, `ExerciseType`, `DifficultyLevel`, `ProgressStatus`, `SyncStatus`)

### Fluxo de request

1. Pedido entra no router (`app/routers/*.py`).
2. Se necessário, valida token via `app/routers/deps.py`.
3. FastAPI injeta sessão DB via `get_db()` (`app/database.py`).
4. Router usa models SQLAlchemy e devolve schemas Pydantic.
5. `get_db()` faz `commit` automático no final da request e `rollback` em exceção.

### Startup e saúde da API

- O backend usa `lifespan` (em vez de `@app.on_event("startup")`).
- Na inicialização, tenta ligação à BD com retry exponencial para reduzir falhas de arranque quando a infraestrutura ainda está a subir.
- No shutdown, chama `engine.dispose()` para libertar recursos de forma determinística.
- Endpoints de saúde:
	- `GET /` -> `{ "message": "API is running" }`
	- `GET /health` -> `{ "status": "ok" }`

### Sessões e Pooling da BD

- A engine assíncrona está configurada com pooling explícito (`pool_size`, `max_overflow`, `pool_timeout`, `pool_pre_ping`).
- A `AsyncSessionLocal` usa `async_sessionmaker` (`autocommit=False`, `autoflush=False`, `expire_on_commit=False`).
- O ciclo de `get_db()` mantém commit automático no sucesso e rollback em exceção.

### CORS atualmente permitido

- `http://localhost:5173`
- `http://127.0.0.1:5173`
- `http://localhost:5174`
- `http://127.0.0.1:5174`

Isto cobre os frontends `professor` e `admin` em dev local.

---

## Pré-requisitos

- Python 3.11+
- PostgreSQL (testado em 16/18)
- `psql` disponível no terminal
- (Opcional) Docker para levantar infraestrutura via compose

---

## Configuração Inicial

### 1) Criar utilizador e base de dados

Como superuser no PostgreSQL:

```sql
CREATE USER peci_user WITH PASSWORD 'password_aqui';
CREATE DATABASE peci_db OWNER peci_user;
GRANT ALL PRIVILEGES ON DATABASE peci_db TO peci_user;
```

### 2) Preparar ambiente Python

Na raiz do monorepo:

```bash
python -m venv .venv
# Windows
.venv\Scripts\activate
# Linux/macOS
source .venv/bin/activate
```

Instalar deps do backend:

```bash
cd backend/backend
pip install -r app/requirements.txt
pip install -r requirements-dev.txt
```

### 3) Criar ficheiro `.env`

Copiar `backend/backend/app/.env.example` para `backend/backend/app/.env` e preencher:

```env
DB_USER=peci_user
DB_PASSWORD=password_aqui
DB_HOST=localhost
DB_PORT=5432
DB_NAME=peci_db

SECRET_KEY=chave_secreta_longa_e_aleatoria_aqui
ALGORITHM=HS256
ACCESS_TOKEN_EXPIRE_MINUTES=60
```

### 4) Inicializar schema (duas opções)

#### Opção A: SQL explícito (controlo total)

```bash
psql -U peci_user -d peci_db -h localhost -f database/schema.sql
psql -U peci_user -d peci_db -h localhost -f database/indexes.sql
```

#### Opção B: Bootstrap ORM local (rápido para dev/smoke)

```bash
python script/backend/bootstrap_local_stack.py
```

Este script:

- executa `Base.metadata.create_all`
- garante conta admin local
- ativa/normaliza role/status admin

Variáveis opcionais do bootstrap:

- `PECI_ADMIN_EMAIL`
- `PECI_ADMIN_PASSWORD`
- `PECI_ADMIN_NAME`
- `PECI_ADMIN_RESET_PASSWORD` (`true/false`)

---

## Execução do Backend

### Modo manual

```bash
cd backend/backend
python -m uvicorn app.main:app --host 127.0.0.1 --port 8000 --reload
```

### Modo automatizado (recomendado no monorepo)

```powershell
.\script\run\ensure_web_backend.ps1
# opcional: instância isolada para E2E web
.\script\run\ensure_web_backend.ps1 -BaseUrl http://127.0.0.1:8010 -RestartHealthyBackend
```

Este script pode:

- subir `postgres` e `chromadb` via `infrastructure/docker-compose.yml`
- criar `.env` do backend automaticamente
- instalar dependências Python se necessário
- correr bootstrap de schema/admin
- iniciar FastAPI em background e validar healthcheck

Logs de arranque automáticos:

- `%TEMP%\peci_backend.out.log`
- `%TEMP%\peci_backend.err.log`

### Endpoints de verificação rápida

```bash
curl http://127.0.0.1:8000/
curl http://127.0.0.1:8000/health
```

OpenAPI:

- `http://127.0.0.1:8000/docs`
- `http://127.0.0.1:8000/redoc`

---

## Segurança e Autenticação

### JWT

- `create_access_token()` inclui:
	- `sub` (ID user)
	- `role`
	- `exp`
- Algoritmo e chave vêm de `.env` (`ALGORITHM`, `SECRET_KEY`).

### Passwords

- Hash com bcrypt (`passlib` + `bcrypt`)
- Nunca guardar password em claro

### Dependency de autenticação

`get_current_user()` valida:

1. token bearer
2. `sub` parseável como UUID
3. user existente
4. user com `Status == "Active"`

### Autorização por role

`require_roles(*roles)` bloqueia acesso por role com HTTP 403.

---

## Endpoints (Foco Backend)

## `auth` (`/api/v1/auth`)

- `POST /register`
	- Regista `Student` ou `Professor`
	- Cria row em `base_user` + tabela derivada correspondente
	- Para `Professor`: cria conta em `Suspended` e abre pedido `access` pendente para aprovação administrativa
	- Devolve token + user
- `POST /login`
	- Valida email/password
	- Requer user ativo
	- Professor pendente devolve `403` com `Account pending admin approval`
- `GET /me`
	- Perfil do user autenticado

## `academic` (`/api/v1/academic`)

Requer autenticação (qualquer role ativa):

- `GET /course-units`
- `GET /exercises` com filtros:
	- `id_uc`
	- `topic_name`
	- `difficulty` (`Easy`, `Medium`, `Hard`)
	- `type` (`Multiple Choice`, `True/False`)
	- `limit`/`offset`

Resposta de exercícios:

- `type` e `difficulty` usam enums do domínio.
- `course_unit_info` pode vir preenchido quando a query é enriquecida com eager loading.

## `students` (`/api/v1/students`)

Requer role `Student`:

- `GET /me` (perfil gamificação)
- `GET /exercises` (filtros idênticos ao academic)
- `POST /progress` (regista tentativa e soma XP no student)
	- `status`: `Correct`, `Incorrect`, `Partial`
	- `sync_status`: `Pending`, `Synced`, `Failed`
- `GET /streak` (histórico por limite)

## `professors` (`/api/v1/professors`)

Requer role `Professor`:

- `GET /course-units` (apenas UCs atribuídas)
- `GET /exercises`
- `POST /exercises` (valida associação professor-UC + tópico)
- `GET /materials`
- `POST /materials`
	- `status` do material é controlado por enum (`Pending`, `Indexed`, `Error`)
- `GET /requests`
- `POST /requests`
	- payload inclui `request_type` (enum) + `title` + `description`
	- `request_type` esperado: `access`, `platform`, `operations`, `other`

## `admin` (`/api/v1/admin`)

Requer role `Admin`:

- `GET /users`
- `PATCH /users/{user_id}`
- `DELETE /users/{user_id}`
- `GET /course-units`
- `POST /course-units`
- `PATCH /course-units/{id_uc}`
- `DELETE /course-units/{id_uc}`
- `GET /requests`
	- suporta filtro `status` por enum (`pending`, `approved`, `rejected`)
	- devolve `request_type` e, quando aplicável, `professor_info` / `admin_info`
- `PATCH /requests/{request_id}/decision`
	- status de decisão tipado por enum (`pending`, `approved`, `rejected`)
	- regra de negócio recomendada: decisões admin devem usar `approved` ou `rejected`

Cada operação crítica escreve em `admin_audit_log`.

## `ai-tutor` (`/api/v1/ai-tutor`)

- `POST /query` atualmente devolve `501 Not Implemented` nesta branch.

### Contratos de Enum (Resumo)

- User roles: `Student`, `Professor`, `Admin`
- User status: `Active`, `Suspended`, `Deactivated`
- Request status: `pending`, `approved`, `rejected`
- Request type: `access`, `platform`, `operations`, `other`
- Material status: `Pending`, `Indexed`, `Error`
- Exercise type: `Multiple Choice`, `True/False`
- Difficulty level: `Easy`, `Medium`, `Hard`
- Progress status: `Correct`, `Incorrect`, `Partial`
- Sync status: `Pending`, `Synced`, `Failed`

---

## Estrutura da Base de Dados (Resumo de Domínio)

### Bloco 1 — Utilizadores

| Tabela | Finalidade |
| --- | --- |
| `base_user` | credenciais e metadados comuns |
| `student` | progresso gamificação agregado |
| `professor` | perfil docente |
| `admin` | perfil administrativo |
| `professor_uc` | associação N:N professor-UC |

### Bloco 2 — Conteúdo Académico

| Tabela | Finalidade |
| --- | --- |
| `course_unit` | unidade curricular |
| `topic` | tópico por UC (PK composta) |
| `teaching_material` | material submetido por professor (com status por enum) |
| `exercise` | exercício (type/difficulty em enum + `solution` em JSONB) |

### Bloco 3 — Gamificação

| Tabela | Finalidade |
| --- | --- |
| `progress` | tentativas por exercício |
| `streak` | registo diário de continuidade |

### Bloco 4 — Administração

| Tabela | Finalidade |
| --- | --- |
| `request` | pedidos professor -> admin |
| `admin_audit_log` | trilho de auditoria das ações admin |

---

## Scripts SQL Úteis

```bash
# Test inserts
psql -U peci_user -d peci_db -h localhost -f script/test/sql/test_inserts.sql

# Truncate mantendo estrutura
psql -U peci_user -d peci_db -h localhost -f script/test/sql/test_truncate.sql

# Drop tabelas
psql -U peci_user -d peci_db -h localhost -f database/deletes/drop_tables.sql

# Drop indexes
psql -U peci_user -d peci_db -h localhost -f database/deletes/drop_indexes.sql

# Snapshot de conteúdo
psql -U peci_user -d peci_db -h localhost -f script/test/sql/useful_selects.sql
```

---

## Testes de Smoke da API

Suíte em `backend/backend/tests/smoke` com cobertura para:

- auth
- academic
- students
- professors
- admin
- ai-tutor (verificação explícita de `501`)

### Execução direta

```bash
cd backend/backend
pytest tests/smoke -q
```

### Execução automatizada (arranca API + testa + termina)

```powershell
.\script\test\run_backend_smoke.ps1
```

Parâmetros úteis do script:

- `-InstallDeps`
- `-BaseUrl http://127.0.0.1:8000`
- `-AdminEmail ... -AdminPassword ...`

Variáveis de ambiente de smoke suportadas:

- `SMOKE_BASE_URL`
- `SMOKE_TIMEOUT`
- `SMOKE_ADMIN_EMAIL`
- `SMOKE_ADMIN_PASSWORD`

Sem credenciais admin explícitas, a suíte tenta criar conta admin temporária local.

## Testes Web E2E (Admin + Professor)

Fluxos browser críticos (Playwright) estão em `script/test/e2e/tests/admin-professor-flows.spec.js`.

Execução recomendada:

```powershell
.\script\test\run_web_e2e_tests.ps1
```

Comportamento do runner E2E:

- garante backend dedicado para E2E (`-BackendBaseUrl`, default `http://127.0.0.1:8010`)
- arranca/reinicia frontends admin (`5174`) e professor (`5173`) de forma determinística
- injeta `VITE_API_BASE_URL` para alinhar ambos os painéis com o backend E2E
- instala Chromium Playwright e executa a suíte browser
- os fluxos cobrem: registo docente pendente, aprovação admin, desbloqueio de login, pedido administrativo e CRUD de UC com atribuição persistida de docente

### Validação transversal recomendada (web + backend + SQL)

```powershell
.\script\test\run_all_tests.ps1 -SkipAluno -SqlPass <password> -WebE2EBackendBaseUrl http://127.0.0.1:8012
```

O runner agregado inclui as etapas: backend smoke + web store tests + web E2E + SQL (+ widget Flutter quando `-SkipAluno` não está ativo).

---

## Reset e Bootstrap de Desenvolvimento

### Bootstrap local rápido

```bash
python script/backend/bootstrap_local_stack.py
```

### Reset completo de schema a partir dos models (destrutivo)

```bash
python script/backend/reset_db_from_models.py
```

Este script faz `DROP SCHEMA public CASCADE` e recria estrutura ORM.
Usar apenas em ambiente local de desenvolvimento/teste.

### Script de compatibilidade ORM (quando necessário)

Se houver mismatch entre SQL base e naming esperado pela ORM nos smoke tests:

```bash
cd backend/backend
set PGPASSWORD=password_aqui
"C:/Program Files/PostgreSQL/18/bin/psql.exe" -h 127.0.0.1 -U peci_user -d peci_db -w -f ../../script/backend/local_schema_orm_compatible.sql
```

---

## Troubleshooting

### `401 Could not validate credentials`

- token ausente/expirado/inválido
- header deve ser `Authorization: Bearer <token>`

### `403 User is not active`

- user existe, mas `Status` != `Active`
- reativar via admin endpoint ou diretamente na BD

### `403 Insufficient permissions`

- token válido, mas role não autorizada para o endpoint

### `500` no startup ou requests DB

- verificar `.env` (`DB_*`)
- confirmar PostgreSQL ativo
- validar schema/indexes aplicados

### CORS no frontend

- confirmar porta (`5173` professor, `5174` admin)
- atualizar lista de `allow_origins` em `app/main.py` se necessário

### `501` em `/api/v1/ai-tutor/query`

- comportamento esperado nesta branch (stub)

---

## Plano de Trabalho

### Fase 1 — Base de Dados

- [X] Schema e indexes base
- [X] Scripts de teste SQL
- [X] Operações de reset/limpeza

### Fase 2 — Backend FastAPI

- [X] Estrutura de app, models, schemas e routers
- [X] Auth com JWT e hashing
- [X] Domínios students/professors/admin/academic
- [X] Smoke tests automatizados
- [ ] Bridge efetiva do tutor IA (`/api/v1/ai-tutor/query`)
