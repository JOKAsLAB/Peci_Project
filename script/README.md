# Script Hub (Runs + Testes)

Este diretório centraliza todos os scripts operacionais do projeto.

Objetivos desta organização:
- Unificar execução local em qualquer máquina da equipa.
- Separar claramente scripts de run, testes e bootstrap backend.
- Reduzir ambiguidade de paths e comandos entre módulos.

## Estrutura

```text
script/
├── README.md
├── run/
│   ├── run_admin.ps1
│   ├── run_professor.ps1
│   ├── run_aluno.ps1
│   └── ensure_web_backend.ps1
├── test/
│   ├── run_backend_smoke.ps1
│   ├── run_web_store_tests.ps1
│   ├── run_web_e2e_tests.ps1
│   ├── run_admin_auth_check.ps1
│   ├── run_database_sql_tests.ps1
│   ├── run_aluno_widget_tests.ps1
│   ├── run_all_tests.ps1
│   ├── clean_test_artifacts.ps1
│   ├── run_release_validation.ps1
│   └── sql/
│       ├── test_inserts.sql
│       ├── test_admin_professor_integrity.sql
│       ├── test_truncate.sql
│       └── useful_selects.sql
└── backend/
    ├── bootstrap_local_stack.py
    ├── local_schema_orm_compatible.sql
    └── reset_db_from_models.py
```

## Pré-requisitos Gerais

- Windows PowerShell.
- Node.js e npm para `admin/` e `professor/`.
- Python 3.11+ para backend.
- Flutter + Android SDK/ADB para `run_aluno.ps1`.
- PostgreSQL ativo localmente ou Docker Compose disponível para arranque de infra.

## Scripts de Run

### 1) `script/run/run_admin.ps1`

O que faz:
- Garante infraestrutura/backend (via `ensure_web_backend.ps1`) por defeito.
- Abre `http://localhost:5174`.
- Arranca Vite do painel admin com porta fixa `5174`.

Comando:
```powershell
.\script\run\run_admin.ps1
```

Flags úteis:
- `-SkipBackendBootstrap`: não valida/prepara backend, arranca só frontend.
- `-SkipInfra`: no bootstrap, não tenta Docker Compose.
- `-SkipBootstrapData`: no bootstrap, não executa bootstrap de schema/admin.
- `-BackendBaseUrl`: URL base do backend (default: `http://127.0.0.1:8000`).
- `-BackendStartupTimeoutSeconds`: timeout de arranque do backend.
- `-RestartFrontendIfRunning`: se a porta `5174` estiver ocupada, termina o processo atual e arranca um Vite novo.
- `-RestartBackendIfHealthy`: força reinício do backend mesmo quando `GET /health` já responde `200`.

### 2) `script/run/run_professor.ps1`

O que faz:
- Mesmo modelo do admin.
- Abre `http://localhost:5173`.
- Arranca Vite do painel professor com porta fixa `5173`.

Comando:
```powershell
.\script\run\run_professor.ps1
```

Flags úteis:
- `-SkipBackendBootstrap`
- `-SkipInfra`
- `-SkipBootstrapData`
- `-BackendBaseUrl`
- `-BackendStartupTimeoutSeconds`
- `-RestartFrontendIfRunning`: se a porta `5173` estiver ocupada, termina o processo atual e arranca um Vite novo.
- `-RestartBackendIfHealthy`: força reinício do backend mesmo quando `GET /health` já responde `200`.

### 3) `script/run/run_aluno.ps1`

O que faz:
- Verifica emulador Android via ADB.
- Lança emulador `Pixel_7` se necessário.
- Executa `flutter pub get` e `flutter run`.

Comando:
```powershell
.\script\run\run_aluno.ps1
```

### 4) `script/run/ensure_web_backend.ps1`

Script central de preparação backend para os painéis web.

O que faz:
1. Verifica `GET /health` da API.
2. Se necessário, tenta garantir infra (`postgres`, `chromadb`) via Docker Compose.
3. Gera `backend/backend/app/.env` se não existir (baseado no `.env` de infra quando disponível).
4. Gera `.venv` na raiz se não existir.
5. Instala dependências backend se necessário.
6. Executa bootstrap idempotente (`script/backend/bootstrap_local_stack.py`) para schema/admin.
7. Arranca `uvicorn` em background e valida saúde da API.

Comando:
```powershell
.\script\run\ensure_web_backend.ps1
```

Parâmetros:
- `-BaseUrl` (default: `http://127.0.0.1:8000`)
- `-StartupTimeoutSeconds` (default: `45`)
- `-SkipInfra`
- `-SkipBootstrapData`
- `-RestartHealthyBackend` (se a API já estiver saudável, força stop na porta e relança o backend)

## Scripts de Teste

### 1) `script/test/run_backend_smoke.ps1`

O que faz:
- Arranca backend temporariamente.
- Aguarda `GET /health`.
- Executa `pytest tests/smoke -q`.
- Encerra backend no fim.

Comando:
```powershell
.\script\test\run_backend_smoke.ps1
```

Parâmetros:
- `-BaseUrl` (default: `http://127.0.0.1:8000`)
- `-StartupTimeoutSeconds` (default: `35`)
- `-InstallDeps`
- `-AdminEmail`
- `-AdminPassword`

### 2) `script/test/run_web_store_tests.ps1`

O que faz:
- Executa suíte Vitest dos stores do painel admin.
- Executa suíte Vitest dos stores do painel professor.
- Valida fluxos de autenticação, pedidos administrativos e stores locais/simuladas.

Comando:
```powershell
.\script\test\run_web_store_tests.ps1
```

Parâmetros:
- `-InstallDeps` (executa `npm install` antes dos testes em cada painel)

### 3) `script/test/run_web_e2e_tests.ps1`

O que faz:
- Garante backend dedicado para E2E (`-BackendBaseUrl`, default `http://127.0.0.1:8010`).
- Arranca/reinicia frontends admin (`5174`) e professor (`5173`) de forma determinística.
- Injeta `VITE_API_BASE_URL` para alinhar os painéis com o backend E2E.
- Executa Playwright com os fluxos críticos cross-panel.

Comando:
```powershell
.\script\test\run_web_e2e_tests.ps1
```

Parâmetros úteis:
- `-InstallDeps`
- `-Headed`
- `-BackendBaseUrl`
- `-AdminBaseUrl`
- `-ProfessorBaseUrl`
- `-StartupTimeoutSeconds`
- `-AdminEmail` / `-AdminPassword`

### 4) `script/test/run_database_sql_tests.ps1`

O que faz:
- Executa os SQL de validação em `script/test/sql`.
- Corre `test_inserts.sql` e `useful_selects.sql`.
- Opcionalmente corre `test_truncate.sql` (destrutivo) com flag.

Comando:
```powershell
.\script\test\run_database_sql_tests.ps1
```

Parâmetros:
- `-SqlServer` (default: `127.0.0.1`)
- `-User` (default: `peci_user`)
- `-Database` (default: `peci_db`)
- `-DbPass` (opcional, usa `PGPASSWORD` se já existir)
- `-PsqlPath` (opcional, caminho explícito para `psql.exe`)
- `-RunTruncate` (inclui limpeza de tabelas)

Notas:
- A suíte executa `test_inserts.sql`, `test_admin_professor_integrity.sql` e `useful_selects.sql`.
- O runner força `pager=off` no `psql` para evitar bloqueios interativos.

### 5) `script/test/run_admin_auth_check.ps1`

O que faz:
- Garante backend local ativo (via `script/run/ensure_web_backend.ps1`).
- Executa login real no endpoint `POST /api/v1/auth/login`.
- Valida sessão e role com `GET /api/v1/auth/me`.

Comando:
```powershell
.\script\test\run_admin_auth_check.ps1
```

Parâmetros:
- `-Email` (default: `admin@ua.pt`)
- `-AdminSecret` (opcional, `SecureString`; se omitido usa `admin123`)
- `-BaseUrl` (default: `http://127.0.0.1:8000`)
- `-SkipInfra`
- `-SkipBootstrapData`

### 6) `script/test/run_aluno_widget_tests.ps1`

O que faz:
- Executa `flutter test test/widget_test.dart` no módulo `aluno/`.
- Mantém o ficheiro de teste no local padrão do Flutter para não quebrar descoberta de testes.

Comando:
```powershell
.\script\test\run_aluno_widget_tests.ps1
```

Parâmetros:
- `-PubGet` (corre `flutter pub get` antes dos testes)

### 7) `script/test/run_all_tests.ps1`

O que faz:
- Encadeia suite completa: backend smoke, testes web (admin/professor), SQL e widget tests Flutter.
- Permite ignorar blocos específicos por flags.

Comando:
```powershell
.\script\test\run_all_tests.ps1
```

Comando recomendado para iterações focadas em Admin/Professor (sem Flutter aluno):

```powershell
.\script\test\run_all_tests.ps1 -SkipAluno -SqlPass <password> -WebE2EBackendBaseUrl http://127.0.0.1:8012
```

Parâmetros úteis:
- `-SkipWeb`
- `-SkipWebE2E`
- `-SkipSql`
- `-SkipAluno`
- `-InstallBackendDeps`
- `-InstallWebDeps`
- `-RunSqlTruncate`
- `-WebE2EBackendBaseUrl`
- `-SqlServer`, `-SqlUser`, `-SqlDatabase`, `-SqlPass`, `-PsqlPath`

### 8) `script/test/clean_test_artifacts.ps1`

O que faz:
- Remove artefactos gerados por testes/build sem tocar em código-fonte.
- Limpa caches Python (`__pycache__`, `*.pyc`), caches de testes (`.pytest_cache`) e outputs web (`dist`, `.vite`, `coverage`) para admin/professor/backend/script.
- Pode incluir limpeza de artefactos de IA apenas com flag explícita.

Comando:
```powershell
.\script\test\clean_test_artifacts.ps1
```

Parâmetros:
- `-IncludeAiArtifacts` (inclui `ai_engine` na varredura de artefactos gerados)
- `-KeepTempLogs` (preserva logs temporários em `%TEMP%`)

### 9) `script/test/run_release_validation.ps1`

O que faz:
- Executa validação agregada (`run_all_tests.ps1`) no escopo de release.
- Por defeito executa sem Flutter aluno (`-SkipAluno`) para o fluxo Admin/Professor/Backend.
- Se os testes passarem, executa limpeza automática de artefactos (`clean_test_artifacts.ps1`).

Comando recomendado (escopo Admin/Professor):
```powershell
.\script\test\run_release_validation.ps1 -SqlPass <password>
```

Parâmetros úteis:
- `-IncludeAluno` (inclui widget tests Flutter)
- `-KeepArtifacts` (não limpa artefactos após os testes)
- `-IncludeAiArtifacts`
- `-CleanTempLogs` (remove também logs temporários `%TEMP%/peci_backend*.log`; por defeito são preservados)
- `-SkipWeb`, `-SkipSql`, `-InstallBackendDeps`, `-InstallWebDeps`, `-RunSqlTruncate`
- `-SqlServer`, `-SqlUser`, `-SqlDatabase`, `-SqlPass`, `-PsqlPath`

## Scripts Backend Auxiliares

### 1) `script/backend/bootstrap_local_stack.py`

O que faz:
- Executa `Base.metadata.create_all` no backend.
- Garante conta admin local ativa para painel web.
- Compatibilidade com email legado de bootstrap (`admin@peci.local` -> email atual válido).

Variáveis opcionais:
- `PECI_ADMIN_EMAIL` (default: `admin@ua.pt`)
- `PECI_ADMIN_PASSWORD` (default: `admin123`)
- `PECI_ADMIN_NAME` (default: `Admin Local`)
- `PECI_ADMIN_RESET_PASSWORD=1`

Execução manual:
```powershell
.\.venv\Scripts\python.exe .\script\backend\bootstrap_local_stack.py
```

### 2) `script/backend/local_schema_orm_compatible.sql`

O que faz:
- Recria schema local compatível com naming esperado pelo ORM.
- Útil para recuperação de ambiente antes de smoke tests.

Execução manual (exemplo):
```powershell
set PGPASSWORD=password_aqui
"C:/Program Files/PostgreSQL/18/bin/psql.exe" -h 127.0.0.1 -U peci_user -d peci_db -w -f script/backend/local_schema_orm_compatible.sql
```

### 3) `script/backend/reset_db_from_models.py`

O que faz:
- Recria schema público e aplica `create_all` a partir dos models.
- Uso local de manutenção/debug.

Execução manual:
```powershell
.\.venv\Scripts\python.exe .\script\backend\reset_db_from_models.py
```

## Fluxo Recomendado (Web)

1. `./script/run/run_admin.ps1` ou `./script/run/run_professor.ps1`
2. O bootstrap prepara backend automaticamente.
3. Em caso de troubleshooting API: `./script/test/run_backend_smoke.ps1`
4. Para validação de release limpa (testar + limpar artefactos): `./script/test/run_release_validation.ps1 -SqlPass <password>`

## Notas

- O diretório antigo `scripts/` (execução/export/contexto) foi descontinuado.
- Scripts de contexto/export foram removidos por decisão de escopo operacional.
