# Admin_Docente (Frontend)

Aplicacao web unificada para perfis Admin e Professor.

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

- Vue 3
- TypeScript
- Pinia
- Vue Router
- Axios (withCredentials=true)
- Vite

## Objetivo funcional

Este modulo cobre os fluxos operacionais web da plataforma:

- autenticacao com controlo de role,
- area administrativa (`Admin`),
- area docente (`Professor`),
- navegacao e estado centralizados numa unica app.

## Arquitetura do modulo

- `src/router/index.ts` define rotas por role (`/admin/*` e `/professor/*`).
- `src/stores/authStore.ts` centraliza login, restore de sessao e logout.
- `src/services/http.ts` encapsula cliente axios e parsing de erros API.
- `src/modules/admin/*` concentra stores/views administrativas.
- `src/modules/professor/*` concentra stores/views docentes.

## Estrutura

```text
admin_docente/
├── src/
│   ├── modules/
│   ├── router/
│   ├── stores/
│   └── services/http.ts
├── package.json
├── vite.config.js
└── tsconfig.json
```

## Rotas principais

Admin:

- `/admin`
- `/admin/disciplines`
- `/admin/users`
- `/admin/approvals`
- `/admin/requests`

Professor:

- `/professor`
- `/professor/path-builder`
- `/professor/exercises`
- `/professor/documents`
- `/professor/question`
- `/professor/requests`

## Fluxo de autenticacao

1. Login por `POST /api/v1/auth/login`.
2. Validacao de role no cliente (`Admin` ou `Professor`).
3. Sessao persistida (local/session) conforme politica do store.
4. Restore de sessao com `GET /api/v1/auth/me` no arranque.
5. Logout por `POST /api/v1/auth/logout`.

Regra de negocio relevante:

- registo de professor pode entrar em pendente de aprovacao administrativa e bloquear login ate decisao do admin.

## Configuracao

Definir URL da API por ambiente:

```env
VITE_API_BASE_URL=https://api.sua-universidade.pt
```

Se nao for definido, em dev usa `http://127.0.0.1:8000`.

## Pre-requisitos

- Node.js 18+
- npm 9+
- Backend FastAPI acessivel

## Execucao local

```powershell
.\scripts\run\run_admin_docente.ps1
```

Alternativa manual:

```powershell
cd admin_docente
npm install
npm run dev -- --host 127.0.0.1 --port 5173
```

## Build para servidor

```powershell
cd admin_docente
npm run check
npm run build
```

Output de producao: `admin_docente/dist`.

## Testes

Validacao do modulo web:

```powershell
.\scripts\test\run_frontend_admin_docente_tests.ps1
```

Validacao agregada web + backend:

```powershell
.\scripts\test\run_all_admin_docente_tests.ps1
```

Validacao completa (inclui opcionalmente aluno):

```powershell
.\scripts\test\run_all_tests.ps1
```

## Politica de testes e entrega

- Testes nao ficam misturados com `src`.
- Testes de frontend estao centralizados em `scripts/test/frontend`.
- Test runners estao em `scripts/test`.
- Para entrega a professores/clientes, usar apenas artefactos de runtime (frontend build + backend app) e excluir scripts internos de teste.

## Troubleshooting rapido

- Se a app nao autenticar, validar `VITE_API_BASE_URL` e backend em `/health`.
- Se houver erro de CORS, validar `CORS_ALLOW_ORIGINS` no backend.
- Se uma role entrar na area errada, validar guards no router e `authStore`.
- Em conflito de sessao local, executar logout e limpar storage do browser.

## Validacao operacional recomendada

Suite web principal:

```powershell
.\scripts\test\run_all_admin_docente_tests.ps1
```
