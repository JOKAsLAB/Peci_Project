# Infrastructure (Servicos Locais)

Este modulo fornece os servicos de suporte para desenvolvimento local reproduzivel.

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

## O que existe aqui

```text
infrastructure/
├── docker-compose.yml
├── .env.example
├── postgres/
│   └── init/
└── chromadb/
```

## Servicos previstos

- PostgreSQL: base relacional para backend.
- ChromaDB: base vetorial para fluxos IA locais.

## Para que serve

- Subir PostgreSQL local para o backend.
- Subir ChromaDB local para fluxos de IA.
- Garantir paridade entre ambientes da equipa (mesmas portas e bootstrap base).

## O infrastructure e preciso?

- Sim, quando queres ambiente local completo e reproduzivel.
- Pode ser opcional se o projeto estiver configurado para servicos remotos geridos.

## Pre-requisitos

- Docker Desktop
- Docker Compose v2
- ficheiro `.env` criado a partir de `.env.example`

## Execucao local

```powershell
cd infrastructure
copy .env.example .env
docker compose up -d
```

Verificar estado:

```powershell
docker compose ps
```

Parar servicos:

```powershell
docker compose down
```

## Quando pode ser ignorado

- Em deploy com servicos geridos externos.
- Em tarefas de frontend puro que nao precisam de backend local ativo.

## Troubleshooting rapido

- container nao sobe: validar portas no `.env` e conflitos locais.
- backend sem DB: confirmar `postgres` saudavel no compose.
- IA sem retrieval: confirmar `chromadb` ativo e acessivel.
