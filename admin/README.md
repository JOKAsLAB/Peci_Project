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
- decisão de pedidos administrativos
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

### Unidades curriculares

- `GET /api/v1/admin/course-units`
- `POST /api/v1/admin/course-units`
- `PATCH /api/v1/admin/course-units/{id_uc}`
- `DELETE /api/v1/admin/course-units/{id_uc}`

### Pedidos administrativos

- `GET /api/v1/admin/requests`
- `PATCH /api/v1/admin/requests/{request_id}/decision`

Pedido de conta docente (tipo funcional `access`) é filtrado no frontend a partir do prefixo técnico no título: `[access]`.

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
