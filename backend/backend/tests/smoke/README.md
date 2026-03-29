# Smoke Tests API (PECI Backend)

Suíte de validação rápida para os domínios principais da API:

- auth
- academic
- students
- professors
- admin (opcional)
- ai-tutor (stub esperado nesta branch)

## Pré-requisitos

1. API a correr em `http://127.0.0.1:8000` (ou definir `SMOKE_BASE_URL`)
2. PostgreSQL acessível para o backend iniciar
3. Dependências instaladas

```bash
cd backend/backend
pip install -r app/requirements.txt
pip install -r requirements-dev.txt
```

## Execução

```bash
cd backend/backend
pytest tests/smoke -q
```

Execução recomendada a partir da raiz do monorepo (arranca API, espera healthcheck, executa testes e fecha servidor):

```powershell
.\script\test\run_backend_smoke.ps1
```

## Bootstrap local da BD (quando necessário)

Se o backend devolver 500 no registo devido a mismatch entre schema SQL e mapeamento ORM,
recria localmente o schema compatível com ORM antes dos smoke tests:

```bash
cd backend/backend
set PGPASSWORD=password_aqui
"C:/Program Files/PostgreSQL/18/bin/psql.exe" -h 127.0.0.1 -U peci_user -d peci_db -w -f ../../script/backend/local_schema_orm_compatible.sql
```

## Variáveis de ambiente

- `SMOKE_BASE_URL` (default: `http://127.0.0.1:8000`)
- `SMOKE_TIMEOUT` (default: `10` segundos)
- `SMOKE_ADMIN_EMAIL` (opcional)
- `SMOKE_ADMIN_PASSWORD` (opcional)

Sem `SMOKE_ADMIN_EMAIL` e `SMOKE_ADMIN_PASSWORD`, a suíte cria automaticamente uma conta admin local temporária para validar os endpoints de admin.
