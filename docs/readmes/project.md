# Projeto (Visao Geral)

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

## Modulos ativos

- `admin_docente`: frontend unico para Admin e Professor.
- `aluno`: app Flutter do aluno.
- `backend`: API FastAPI e acesso a base de dados PostgreSQL.
- `ai_engine`: scripts locais de indexacao RAG e chatbot.
- `infrastructure`: servicos locais (PostgreSQL e ChromaDB) via Docker.
- `website promocional`: landing page estatica de apresentacao.
- `scripts`: automacao de run/test para desenvolvimento e CI.
- `build`: artefactos gerados por compilacao e testes.
- `docs/readmes`: documentacao consolidada.

## O que e obrigatorio para correr o projeto

- Obrigatorio no runtime web: `admin_docente` + `backend`.
- Obrigatorio no runtime mobile: `aluno`.
- Obrigatorio para ambiente local completo: `infrastructure`.
- Opcional por fase: `ai_engine` (necessario para fluxo IA local).
- Nao e codigo-fonte: `build` (saida gerada por ferramentas).

## Objetivo funcional do repositorio

Este repositorio concentra a plataforma PECI com tres eixos principais:

- experiencia do aluno (mobile Flutter),
- operacao academica/admin (frontend web unificado),
- servicos e dados (backend + SQL + infraestrutura local).

O design atual privilegia entregas incrementais: backend e web ja estao ligados em fluxos criticos, enquanto algumas integracoes avancadas (ex.: bridge IA backend) evoluem por fases.

## Decisoes de organizacao

- Frontend duplicado foi removido para evitar manutencao paralela.
- Testes nao ficam misturados com codigo de interface.
- Documentacao fica centralizada em `docs/readmes`.

## Arquitetura funcional (resumo rapido)

1. `admin_docente` consome `backend` por HTTP (auth, admin, professor, estudantes).
2. `backend` persiste no PostgreSQL (schema em `backend/database`).
3. `ai_engine` usa ChromaDB local para indexacao e retrieval de documentos.
4. `infrastructure` sobe PostgreSQL + ChromaDB para ambiente local reproduzivel.
5. `scripts` coordena run/test para reduzir setup manual por modulo.

## Responsabilidades por modulo

### `admin_docente`

- Painel unificado para papeis `Admin` e `Professor`.
- Router por role com guardas de autenticacao.
- Estado com Pinia e cliente HTTP central (`services/http.ts`).

### `aluno`

- App mobile para pratica, progresso e perfil.
- Navegacao e estado orientados a Flutter/Riverpod.
- Inclui base local Drift para persistencia de suporte.

### `backend`

- API FastAPI com routers por dominio.
- Modelos SQLAlchemy async e autenticacao JWT/cookie.
- Testes smoke para validacao de contratos operacionais.

### `ai_engine`

- Indexacao de bibliografia para vetor store.
- Chatbot local com retrieval contextual.

### `infrastructure`

- `docker-compose.yml` para PostgreSQL e ChromaDB locais.
- Base de paridade entre ambientes da equipa.

### `scripts`

- Scripts de execucao local (web, backend, aluno).
- Scripts de validacao agregada (backend/web/aluno).
- Limpeza de artefactos para manter workspace e commits limpos.

## Fluxo recomendado de desenvolvimento

1. Subir/validar backend local com `scripts/run/ensure_admin_docente_backend.ps1`.
2. Correr frontend web com `scripts/run/run_admin_docente.ps1`.
3. Se houver trabalho mobile, correr `scripts/run/run_aluno.ps1`.
4. Validar stack web com `scripts/test/run_all_admin_docente_tests.ps1`.
5. Validar stack completa com `scripts/test/run_all_tests.ps1`.

## Preparacao para servidor

- Base de dados em servidor dedicado.
- Backend com `.env` de producao.
- `CORS_ALLOW_ORIGINS` configurado para dominios reais.
- Frontend buildado e servido em ambiente de deploy.

## O que nao deve ir para entrega final

- Artefactos de `build/`, `dist/`, caches e `.venv`.
- Dados temporarios de teste e logs locais.
- Segredos locais (`.env` reais, tokens em ficheiros locais).

## Leitura sugerida da documentacao

1. `master.md` para guia end-to-end de arranque e validacao.
2. `repo_estrutura.md` para mapa rapido do monorepo.
3. `scripts.md` para comandos operacionais.
4. `backend.md` e `admin_docente.md` para fluxos web end-to-end.
5. `aluno.md` para fluxo mobile.
6. `ai_engine.md` e `infrastructure.md` para stack IA + servicos locais.
