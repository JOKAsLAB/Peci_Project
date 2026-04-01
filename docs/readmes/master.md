# Master Guide (End-to-End)

Guia unico para arrancar, compreender e validar o `New_Peci_Project` de ponta a ponta.

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

## 1) Objetivo do repositorio

O projeto integra tres frentes funcionais:

- operacao academica web (`admin_docente`),
- experiencia mobile do aluno (`aluno`),
- servicos e dados (`backend`, `infrastructure`, `ai_engine`).

Toda a documentacao detalhada por modulo fica centralizada em `docs/readmes`.

## 2) Mapa rapido dos modulos

- `admin_docente`: frontend Vue 3 para Admin e Professor.
- `aluno`: app Flutter para estudantes.
- `backend`: API FastAPI (auth, admin, professors, students).
- `ai_engine`: indexacao RAG + chatbot local.
- `infrastructure`: PostgreSQL + ChromaDB com Docker Compose.
- `scripts`: automacao de execucao e testes.
- `website promocional`: pagina estatica institucional.

## 3) Pre-requisitos

- Windows + PowerShell
- Python 3.11+
- Node.js 18+ e npm 9+
- Flutter SDK + Android SDK + `adb`
- Docker Desktop + Docker Compose v2

## 4) Bootstrap recomendado (ambiente local)

Da raiz do repositorio (`New_Peci_Project`):

```powershell
cd .\New_Peci_Project
```

### 4.1) Garantir backend local

```powershell
.\scripts\run\ensure_admin_docente_backend.ps1 -CookieMode local
```

### 4.2) Arrancar frontend web

```powershell
.\scripts\run\run_admin_docente.ps1
```

### 4.3) Arrancar app aluno (quando necessario)

```powershell
.\scripts\run\run_aluno.ps1
```

### 4.4) Subir servicos locais por Docker (quando necessario)

```powershell
cd .\infrastructure
copy .env.example .env
docker compose up -d
cd ..
```

## 5) Validacao recomendada

### Suite web + backend

```powershell
.\scripts\test\run_all_admin_docente_tests.ps1
```

### Suite completa (web + backend + aluno)

```powershell
.\scripts\test\run_all_tests.ps1
```

### Apenas aluno (widget tests)

```powershell
.\scripts\test\run_aluno_widget_tests.ps1
```

### Limpeza de artefactos

```powershell
.\scripts\test\clean_test_artifacts.ps1
```

Com limpeza incluindo mobile:

```powershell
.\scripts\test\clean_test_artifacts.ps1 -IncludeAlunoArtifacts
```

## 6) Fluxos por perfil tecnico

### Frontend web

1. Correr `run_admin_docente.ps1`.
2. Validar com `run_frontend_admin_docente_tests.ps1`.
3. Fechar com `run_all_admin_docente_tests.ps1`.

### Backend

1. Garantir API com `ensure_admin_docente_backend.ps1`.
2. Executar smoke tests (`run_backend_smoke.ps1`).
3. Executar validacao auth por cookie (`run_cookie_auth_check.ps1`).

### Mobile (Aluno)

1. Correr `run_aluno.ps1`.
2. Executar `run_aluno_widget_tests.ps1`.
3. Integrar na suite completa (`run_all_tests.ps1`).

### IA local

1. Preparar ambiente Python em `ai_engine`.
2. Executar `ImportFiles.py` para indexacao.
3. Executar `chatbot.py` via Streamlit.

## 7) Ordem de leitura da documentacao

1. `project.md`
2. `repo_estrutura.md`
3. `scripts.md`
4. `backend.md`
5. `admin_docente.md`
6. `aluno.md`
7. `ai_engine.md`
8. `infrastructure.md`
9. `build.md`
10. `website_promocional.md`

## 8) Convencoes de manutencao

- manter todos os READMEs em `docs/readmes`,
- nao versionar artefactos de `build`, `dist`, caches e ambientes locais,
- usar scripts da pasta `scripts` como entrada principal de execucao,
- atualizar primeiro `master.md` e `index.md` quando houver alteracoes estruturais.

## 9) Referencia cruzada rapida

- Visao global: `project.md`
- Mapa de diretorios: `repo_estrutura.md`
- Automacao de run/test: `scripts.md`
- Web admin/professor: `admin_docente.md`
- API e dados: `backend.md`
- App aluno: `aluno.md`
- IA local: `ai_engine.md`
- Infra Docker: `infrastructure.md`
- Artefactos gerados: `build.md`
- Landing institucional: `website_promocional.md`