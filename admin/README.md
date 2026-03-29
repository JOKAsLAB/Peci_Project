# Admin Web (PECI)

Painel web de administração da plataforma PECI.

## Stack

- Vue 3
- Vite
- Pinia
- Vue Router
- Tailwind CSS
- Vitest

## Objetivo funcional

O painel Admin cobre operações administrativas e de governação:

- autenticação com role `Admin`
- gestão de utilizadores
- gestão de unidades curriculares
- aprovação/rejeição de contas docentes com transição de estado da conta
- decisão de pedidos administrativos
- confirmações explícitas em ações críticas (aprovar/rejeitar/remover/alterar estado)
- dashboard operacional

Não cobre edição curricular de conteúdo pedagógico.

## Pré-requisitos

- Node.js 18+
- npm 9+
- Backend FastAPI ativo em `http://127.0.0.1:8000` (default)

## Configuração

1. Instalar dependências:

```bash
npm install
```

2. (Opcional) configurar URL da API:

```bash
# .env.local
VITE_API_BASE_URL=http://127.0.0.1:8000
```

## Execução

```bash
npm run dev -- --host --port 5174 --strictPort
```

Build de produção:

```bash
npm run build
```

Preview local do build:

```bash
npm run preview
```

## Testes

Executar testes locais do módulo:

```bash
npm run test:run
```

Executar testes agregados do monorepo (escopo web/backend/sql):

```powershell
.\script\test\run_all_tests.ps1 -SkipAluno -SqlPass <password>
```

## Fluxos de dados (API)

### Autenticação

- `POST /api/v1/auth/login`
- `GET /api/v1/auth/me`

Persistência de sessão:

- `localStorage` quando "Lembrar-me" está ativo
- `sessionStorage` quando "Lembrar-me" está inativo

### Utilizadores

- `GET /api/v1/admin/users`
- `PATCH /api/v1/admin/users/{user_id}`
- `DELETE /api/v1/admin/users/{user_id}`
- criação via `POST /api/v1/auth/register`

Notas de negócio:

- registo de `Professor` via `POST /api/v1/auth/register` cria conta com `status=Suspended`
- no mesmo registo é criado pedido `access` pendente para decisão do admin

### Unidades curriculares

- `GET /api/v1/admin/course-units`
- `POST /api/v1/admin/course-units`
- `PATCH /api/v1/admin/course-units/{id_uc}`
- `DELETE /api/v1/admin/course-units/{id_uc}`

Contrato atual de payload:

- `POST/PATCH` aceitam `professor_ids: UUID[]`
- `GET/POST/PATCH` devolvem `professors[]` com `{ id, name, email }`

### Pedidos administrativos

- `GET /api/v1/admin/requests`
- `PATCH /api/v1/admin/requests/{request_id}/decision`

Contrato atual de pedidos:

- `request_type` é a fonte primária de tipagem (`access|platform|operations|other`)
- `professor_info` e `admin_info` são devolvidos quando relações estão disponíveis
- decisão de pedido `access` sincroniza o estado da conta docente (`approved` -> `Active`, `rejected` -> `Deactivated`)

## Estrutura relevante

```text
admin/
├── src/
│   ├── stores/
│   │   ├── authStore.js
│   │   ├── userStore.js
│   │   ├── disciplineStore.js
│   │   └── adminRequestStore.js
│   ├── views/
│   └── router/index.js
├── vitest.config.js
└── package.json
```

## Estado atual

- testes de stores: estáveis
- build de produção: estável
- integração com backend para `users`, `course-units` e `requests`: ativa
- fluxo de aprovação de docente e bloqueio de login até decisão admin: ativo
