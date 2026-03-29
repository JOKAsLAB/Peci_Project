# Professor Web (PECI)

Painel web docente da plataforma PECI.

## Stack

- Vue 3
- Vite
- Pinia
- Vue Router
- Tailwind CSS
- Vitest

## Objetivo funcional

O painel Professor cobre operações docentes e administrativas não curriculares:

- autenticação com role `Professor`
- gestão do banco de exercícios
- gestão de percursos de aprendizagem
- gestão documental da UC
- submissão e acompanhamento de pedidos ao Admin
- registo docente com gate de aprovação administrativa antes do primeiro login

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
npm run dev -- --host --port 5173 --strictPort
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
- `POST /api/v1/auth/register` (registo docente)
- `GET /api/v1/auth/me`

Regras de negócio atuais:

- registo docente cria conta em `Suspended` e pedido de acesso pendente (`request_type=access`)
- login devolve `403` com `Account pending admin approval` enquanto não existir aprovação admin
- só após decisão `approved` no admin é que o login no painel docente fica desbloqueado

### Pedidos ao admin

- `GET /api/v1/professors/requests`
- `POST /api/v1/professors/requests`

Contrato atual:

- o tipo funcional é enviado em `request_type` (`access|platform|operations|other`)
- o frontend mantém fallback de leitura para prefixos legados no `title` apenas por retrocompatibilidade
- submissão de pedido usa confirmação explícita no UI antes do `POST`

### Estado local e simulação

Os módulos abaixo operam em estado local nesta fase:

- `exerciseStore.js`
- `pathStore.js`
- `questionLabStore.js`

Persistência backend está ativa no domínio de autenticação e pedidos administrativos.

## Estrutura relevante

```text
professor/
├── src/
│   ├── stores/
│   │   ├── authStore.js
│   │   ├── adminRequestStore.js
│   │   ├── exerciseStore.js
│   │   ├── pathStore.js
│   │   └── questionLabStore.js
│   ├── views/
│   └── router/index.js
├── vitest.config.js
└── package.json
```

## Estado atual

- testes de stores: estáveis
- build de produção: estável
- integração backend ativa em auth e pedidos ao admin
- fluxo pendente->aprovado de conta docente validado em E2E browser
