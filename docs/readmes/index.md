# Documentacao Central

Toda a documentacao funcional e tecnica do projeto fica nesta pasta.

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

## Objetivo desta pasta

- concentrar contexto tecnico num unico ponto,
- reduzir dispersao de README por modulo,
- facilitar onboarding da equipa e validacao de entrega.

## Ficheiros

- [master.md](master.md): guia end-to-end (arranque, validacao e navegacao de docs).
- [project.md](project.md): visao geral e organizacao atual do projeto.
- [backend.md](backend.md): backend FastAPI, configuracao e deploy.
- [admin_docente.md](admin_docente.md): frontend unico (Admin e Professor).
- [aluno.md](aluno.md): aplicacao mobile Flutter (Aluno).
- [ai_engine.md](ai_engine.md): motor IA local (RAG + chatbot).
- [infrastructure.md](infrastructure.md): docker compose e servicos locais de suporte.
- [build.md](build.md): artefactos gerados e politica de limpeza.
- [website_promocional.md](website_promocional.md): pagina estatica de apresentacao.
- [repo_estrutura.md](repo_estrutura.md): mapa rapido das pastas de topo do repositorio.
- [scripts.md](scripts.md): automacao de run/test e politica de testes.

## Ordem recomendada de leitura

1. `master.md` (guia principal end-to-end).
2. `project.md` (visao global e fronteiras de cada modulo).
3. `repo_estrutura.md` (mapa de diretorios e ownership tecnico).
4. `scripts.md` (execucao local e validacao).
5. Documentos de modulo (`backend.md`, `admin_docente.md`, `aluno.md`, `ai_engine.md`, `infrastructure.md`).
6. `build.md` e `website_promocional.md` para contexto complementar.

## Nota importante

A pasta `site` foi removida por ser duplicada de `admin_docente`. O frontend oficial em desenvolvimento e `admin_docente`.
