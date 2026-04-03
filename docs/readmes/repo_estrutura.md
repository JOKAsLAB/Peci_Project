# Estrutura do Repositorio (Resumo)

Mapa rapido das pastas de topo em `New_Peci_Project`.

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

## Pastas de produto

- `admin_docente`: frontend web unificado (Admin e Professor).
- `aluno`: aplicacao mobile Flutter.
- `backend`: API FastAPI e schema SQL.
- `ai_engine`: scripts locais de IA (indexacao + chatbot).

## Pastas de suporte operacional

- `scripts`: run/test automation para web/backend/aluno.
- `infrastructure`: servicos locais (PostgreSQL + ChromaDB).
- `docs`: documentacao consolidada por modulo.
- `website promocional`: pagina de apresentacao.

## Pastas geradas/artefactos

- `build`: saida gerada de ferramentas.
- `.venv`: ambiente virtual Python local.
- outputs de modulo (`admin_docente/dist`, `aluno/build`, caches).

## Mapa textual da raiz

```text
New_Peci_Project/
├── admin_docente/
├── aluno/
├── backend/
├── ai_engine/
├── infrastructure/
├── scripts/
├── docs/
├── website promocional/
├── build/
└── .venv/
```

## Ownership tecnico (guia rapido)

- Frontend web: `admin_docente`
- Mobile: `aluno`
- API e SQL: `backend`
- IA local: `ai_engine`
- Ambiente local: `infrastructure`
- Automacao: `scripts`
- Documentacao: `docs/readmes`

## Regra geral

- Codigo-fonte vive nos modulos de produto.
- Artefactos gerados podem ser reconstruidos e limpos.
- Para comandos operacionais, usar primeiro os scripts da pasta `scripts`.
