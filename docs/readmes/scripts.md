# Scripts (Run e Testes)

Este modulo centraliza automacao de desenvolvimento e validacao.

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

## Estrutura

```text
scripts/
├── run/
│   ├── ensure_admin_docente_backend.ps1
│   ├── run_admin_docente.ps1
│   └── run_aluno.ps1
└── test/
    ├── clean_test_artifacts.ps1
    ├── run_backend_smoke.ps1
    ├── run_cookie_auth_check.ps1
    ├── run_frontend_admin_docente_tests.ps1
    ├── run_all_admin_docente_tests.ps1
    ├── run_aluno_widget_tests.ps1
    ├── run_all_tests.ps1
    └── frontend/
        └── admin_docente/
            └── http.test.js
```

## Objetivo

- padronizar comandos de run/test para toda a equipa,
- reduzir setup manual por modulo,
- concentrar validacao operacional fora de `src`.

## Pre-requisitos gerais

- PowerShell (Windows).
- Python 3.11+ para backend.
- Node.js 18+ e npm para `admin_docente`.
- Flutter SDK + Android Platform-Tools (`adb`) para scripts do aluno.

## Scripts de run

### 1) `scripts/run/ensure_admin_docente_backend.ps1`

O que faz:

1. Verifica se o backend ja esta saudavel (`GET /health`).
2. Opcionalmente reinstala dependencias Python.
3. Arranca `uvicorn` em background no `backend/backend`.
4. Ajusta modo de cookies (`local` ou `production`) no contexto de arranque.

Comando base:

```powershell
.\scripts\run\ensure_admin_docente_backend.ps1 -CookieMode local
```

Parametros uteis:

- `-BaseUrl` (default `http://127.0.0.1:8000`)
- `-StartupTimeoutSeconds`
- `-RestartIfHealthy`
- `-InstallDeps`
- `-CookieMode local|production`

### 2) `scripts/run/run_admin_docente.ps1`

O que faz:

1. (Por defeito) garante backend local com `ensure_admin_docente_backend.ps1`.
2. Define `VITE_API_BASE_URL` para o frontend.
3. Arranca Vite no `admin_docente`.

Comando base:

```powershell
.\scripts\run\run_admin_docente.ps1
```

Parametros uteis:

- `-SkipBackendBootstrap`
- `-InstallFrontendDeps`
- `-InstallBackendDeps`
- `-BackendBaseUrl`
- `-FrontendPort`

### 3) `scripts/run/run_aluno.ps1`

O que faz:

1. Verifica `flutter` e `adb` no PATH.
2. Reutiliza emulador Android ativo ou tenta iniciar o configurado.
3. Executa `flutter pub get` em `aluno/`.
4. Executa `flutter run` no dispositivo Android detetado.

Comando base:

```powershell
.\scripts\run\run_aluno.ps1
```

Parametros uteis:

- `-EmulatorName` (default `Pixel_7`)
- `-BootWaitSeconds`
- `-MaxDeviceChecks`

## Scripts de teste

### 1) `scripts/test/run_backend_smoke.ps1`

Executa a suite smoke do backend (`pytest tests/smoke`).

Comando base:

```powershell
.\scripts\test\run_backend_smoke.ps1
```

### 2) `scripts/test/run_cookie_auth_check.ps1`

Valida login por cookie HTTP, `GET /auth/me` e logout.

Comando base:

```powershell
.\scripts\test\run_cookie_auth_check.ps1
```

### 3) `scripts/test/run_frontend_admin_docente_tests.ps1`

Corre no `admin_docente`:

- `npm run check`
- `npm run test:run` (opcional)
- `npm run build`

Comando base:

```powershell
.\scripts\test\run_frontend_admin_docente_tests.ps1
```

### 4) `scripts/test/run_all_admin_docente_tests.ps1`

Suite agregada de backend + cookie auth + frontend web.

Comando base:

```powershell
.\scripts\test\run_all_admin_docente_tests.ps1
```

### 5) `scripts/test/run_aluno_widget_tests.ps1`

Executa widget tests do modulo Flutter aluno.

Comando base:

```powershell
.\scripts\test\run_aluno_widget_tests.ps1
```

Parametro util:

- `-PubGet` (executa `flutter pub get` antes dos testes)

### 6) `scripts/test/run_all_tests.ps1`

Suite agregada principal:

1. Corre `run_all_admin_docente_tests.ps1`.
2. Opcionalmente corre `run_aluno_widget_tests.ps1`.

Comando base (inclui aluno):

```powershell
.\scripts\test\run_all_tests.ps1
```

Comando focado em web/backend:

```powershell
.\scripts\test\run_all_tests.ps1 -SkipAluno
```

### 7) `scripts/test/clean_test_artifacts.ps1`

Limpa caches e artefactos gerados (python/web) e, opcionalmente, AI/aluno.

Comando base:

```powershell
.\scripts\test\clean_test_artifacts.ps1
```

Parametros uteis:

- `-IncludeAiArtifacts`
- `-IncludeAlunoArtifacts`
- `-KeepTempLogs`

## Fluxos recomendados

### Fluxo web rapido

```powershell
.\scripts\run\run_admin_docente.ps1
.\scripts\test\run_all_admin_docente_tests.ps1
```

### Fluxo mobile (aluno)

```powershell
.\scripts\run\run_aluno.ps1
.\scripts\test\run_aluno_widget_tests.ps1
```

### Fluxo completo do projeto

```powershell
.\scripts\test\run_all_tests.ps1
```

## Politica de organizacao

- Nao colocar suites de teste dentro de `admin_docente/src`.
- Nao tratar artefactos de `build`/`dist` como codigo-fonte.
- Preferir os scripts deste modulo para execucao repetivel em equipa e CI.
