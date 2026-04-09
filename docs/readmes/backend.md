# Backend (FastAPI)

Este modulo serve a API do projeto e esta preparado para execucao local e deploy em servidor.

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

- FastAPI
- SQLAlchemy async + asyncpg
- PostgreSQL
- JWT + cookies httpOnly

## Objetivo funcional

- disponibilizar endpoints de autenticacao, administracao e area docente/estudante,
- centralizar regras de dominio e validacao de acesso por role,
- servir como camada de integracao para os clientes web e mobile.

## Estrutura

```text
backend/
└── backend/
    ├── app/
    │   ├── main.py
    │   ├── database.py
    │   ├── security.py
    │   ├── routers/
    │   ├── models/
    │   └── schemas/
    ├── requirements-dev.txt
    └── tests/smoke/
```

## Arquitetura (resumo pratico)

1. Request entra em `routers/*`.
2. Dependencias de auth validam token/cookie e role.
3. Sessao DB async e injetada por `get_db`.
4. Modelos SQLAlchemy executam persistencia no PostgreSQL.
5. Resposta e serializada por schemas Pydantic.

Routers ativos no estado atual:

- `auth`
- `admin`
- `professors`
- `students`
- `ai_tutor` (endpoint de bridge pode estar em fase de stub)

Health endpoints:

- `GET /`
- `GET /health`

## Configuracao

Copiar `backend/backend/app/.env.example` para `backend/backend/app/.env` e preencher:

- DB_USER
- DB_PASSWORD
- DB_HOST
- DB_PORT
- DB_NAME
- SECRET_KEY
- ALGORITHM
- ACCESS_TOKEN_EXPIRE_MINUTES

### Cookies (producao)

- AUTH_COOKIE_NAME
- AUTH_COOKIE_SECURE=true
- AUTH_COOKIE_SAMESITE=none
- AUTH_COOKIE_DOMAIN
- AUTH_COOKIE_PATH=/

### CORS para servidor

`CORS_ALLOW_ORIGINS` e uma lista separada por virgula.

Exemplo para producao:

```env
CORS_ALLOW_ORIGINS=https://admin-docente.sua-universidade.pt,https://api.sua-universidade.pt
```

## Execucao local (recomendada)

Da raiz `New_Peci_Project`:

```powershell
.\scripts\run\ensure_admin_docente_backend.ps1 -CookieMode local
```

## Execucao manual

```powershell
cd backend\backend
python -m uvicorn app.main:app --host 127.0.0.1 --port 8000 --reload
```

## Contratos de API (visao por dominio)

### Auth

- login
- registo
- leitura de perfil (`/auth/me`)
- logout

### Admin

- gestao de utilizadores
- gestao de unidades curriculares
- decisao de pedidos administrativos

### Professors

- UCs atribuidas ao docente
- materiais, exercicios e pedidos ao admin

### Students

- perfil e progresso
- catalogo de UCs/exercicios para aluno
- streak/progress tracking

## Modelo de dados (onde esta a fonte de verdade)

- SQL operacional em `backend/database/schema.sql` e `backend/database/indexes.sql`.
- scripts de drop em `backend/database/deletes/`.
- modelos ORM em `backend/backend/app/models/`.

## Execucao de testes

Todos os testes operacionais ficam fora dos frontends, centralizados em `scripts/test`:

```powershell
.\scripts\test\run_backend_smoke.ps1
.\scripts\test\run_cookie_auth_check.ps1
```

Suite agregada web + backend:

```powershell
.\scripts\test\run_all_admin_docente_tests.ps1
```

Suite agregada completa (inclui opcionalmente aluno):

```powershell
.\scripts\test\run_all_tests.ps1
```

## Troubleshooting rapido

- `500` em arranque: validar `.env` e conectividade com PostgreSQL.
- `403` em login professor: conta pode estar pendente de aprovacao admin.
- erro de cookie em local: usar `-CookieMode local` no script de bootstrap.
- erro de CORS: rever `CORS_ALLOW_ORIGINS` no backend.

## Observacoes de deploy

- usar variaveis de ambiente reais e segredos fora do repositorio,
- configurar cookies para ambiente HTTPS,
- separar base de dados de desenvolvimento e producao,
- validar smoke tests antes de promover release.

## Deploy (resumo)

- Base de dados em servidor gerido (nao local)
- Backend com variaveis de ambiente de producao
- Frontend a apontar para API publica via `VITE_API_BASE_URL`
- Nao entregar pastas internas de teste para clientes/professores

## (For Devs) Para testar fazer um registo:
Pôr o server a correr e noutro terminal (é um exemplo):
Nota:Se fizeres com a execução manual (ver comandos acima) consegues ver mensagens do servidor.
Depois podes fazer registo desde o terminal:
```
Powershell:
$body = @{
    name = "Carlos"
    email = "carlos@test.com"
    password = "123456"
    role = "Student"
} | ConvertTo-Json

Invoke-RestMethod -Method POST `
  -Uri "http://127.0.0.1:8000/api/v1/auth/register" `
  -Body $body `
  -ContentType "application/json"
```
  Ou:
```
  $body = @{
    name = "Admin"
    email = "admin@test.com" 
    password = "123456"
    role = "Admin"
  } | ConvertTo-Json
 
 Invoke-RestMethod -Method POST `
   -Uri "http://127.0.0.1:8000/api/v1/auth/register" `
   -Body $body `
   -ContentType "application/json"
```
Ou desde a propria interface docente/admin e correr (-InstallFrontendDeps se for a primeira vez):
```powershell
.\scripts\run\run_admin_docente.ps1 -InstallFrontendDeps
```
