# Deploy — PECI LogicStreak

## O que está incluído

| Serviço    | Tecnologia          | Acesso externo |
| ---------- | ------------------- | -------------- |
| Frontend   | Vue 3 + nginx       | porta **80**   |
| Backend    | FastAPI + AI Engine | interno        |
| Base dados | PostgreSQL 16       | interno        |

Só a porta 80 fica exposta. O backend e a BD ficam na rede interna do Docker.

---

## Pré-requisitos

### Linux (servidor Ubuntu/Debian)

```bash
# Docker + Docker Compose (uma linha)
curl -fsSL https://get.docker.com | sh

# Verificar instalação
docker --version
docker compose version
```

### Windows

Instala o **Docker Desktop para Windows**:

1. Descarrega em https://www.docker.com/products/docker-desktop/
2. Instala e reinicia o PC
3. Abre o Docker Desktop e aguarda até o ícone ficar verde ("Engine running")
4. Verifica numa janela PowerShell:

```powershell
docker --version
docker compose version
```

> Se usares WSL 2 (recomendado pelo Docker Desktop), os comandos Linux também funcionam dentro do WSL.

---

## 1. Colocar o projeto no servidor/PC

```powershell
git clone https://github.com/JOKAsLAB/Peci_Project.git
cd Peci_Project
```

---

## 2. Configurar o ambiente

Edita o ficheiro `backend/backend/app/.env`:

### Linux

```bash
nano backend/backend/app/.env
```

### Windows (PowerShell)

```powershell
notepad backend\backend\app\.env
# ou, se tiveres VS Code:
code backend\backend\app\.env
```

---

Muda estas linhas no `.env`:

```env
# Base de dados — usa uma password forte
DB_PASSWORD=uma_password_segura_aqui

# JWT — gera uma chave aleatória (ver comando abaixo)
SECRET_KEY=cola_aqui_a_chave_gerada

# CORS — adiciona o IP ou domínio do servidor
CORS_ALLOW_ORIGINS=http://IP_DO_SERVIDOR,http://localhost

# SMTP — para envio de emails de verificação
SMTP_HOST=smtp.gmail.com
SMTP_PORT=587
SMTP_USER=logicstreaksupport@gmail.com
SMTP_PASSWORD=a_tua_app_password
```

**Gerar uma `SECRET_KEY` segura:**

```bash
# Linux / macOS
python3 -c "import secrets; print(secrets.token_hex(32))"

# Windows (PowerShell)
python -c "import secrets; print(secrets.token_hex(32))"
```

---

## 3. Arrancar

O comando é igual em Linux e Windows:

```bash
docker compose up -d --build
```

- `-d` → corre em background
- `--build` → constrói as imagens (necessário na primeira vez)
- **Primeira vez demora 10–20 min** (descarrega modelos de IA ~300 MB)

Verificar se está tudo a correr:

```bash
docker compose ps
```

Deverá aparecer 3 serviços com estado `healthy` / `running`.

---

## 4. Aceder à aplicação

Abre o browser em `http://IP_DO_SERVIDOR` (Linux) ou `http://localhost` (Windows local).

A primeira conta Admin é criada automaticamente pelo backend ao arrancar (credenciais definidas no `.env` como `ADMIN_EMAIL` e `ADMIN_PASSWORD`).

Se precisares de criar manualmente via BD:

### Linux

```bash
docker compose exec db psql -U PECI_USER -d PECI_LOCAL
```

### Windows (PowerShell)

```powershell
docker compose exec db psql -U PECI_USER -d PECI_LOCAL
```

> O comando `docker compose exec` é igual — só muda como corres o Python abaixo.

```sql
-- Dentro do psql (igual em ambos os sistemas):
INSERT INTO base_user (name, email, password_hash, role, status)
VALUES ('Admin', 'admin@peci.pt', 'HASH_AQUI', 'Admin', 'Active');
```

**Gerar o hash da password:**

```bash
# Linux
docker compose exec backend python3 -c "
from app.security import hash_password
print(hash_password('a_tua_password_aqui'))
"
```

```powershell
# Windows (PowerShell) — aspas têm de ser escapadas
docker compose exec backend python -c "from app.security import hash_password; print(hash_password('a_tua_password_aqui'))"
```

---

## Comandos do dia-a-dia

Iguais em Linux e Windows:

```bash
# Ver logs em tempo real
docker compose logs -f backend
docker compose logs -f frontend

# Reiniciar um serviço (ex: depois de mudar o .env)
docker compose restart backend

# Parar tudo (dados preservados)
docker compose down

# Atualizar o projeto (depois de git pull)
docker compose up -d --build

# Apagar TUDO incluindo a base de dados
docker compose down -v
```

---

## Estrutura de rede (resumo)

```
Eduroam / Rede local
        │
        │  IP da máquina (192.168.1.140)
        │  porta 80
        ▼
┌─────────────────────────────────────────────────┐
│  Servidor físico                                │
│                                                 │
│  bridge: peci_network  172.20.0.0/24            │
│  gateway:              172.20.0.1               │
│                                                 │
│  ┌──────────────────────────────────────────┐  │
│  │ peci_frontend  172.20.0.30               │  │
│  │ nginx : 80                               │  │
│  │   /          → ficheiros Vue (estáticos) │  │
│  │   /api/*     → 172.20.0.20:8000          │  │
│  │   /ws/*      → 172.20.0.20:8000          │  │
│  └──────────────┬───────────────────────────┘  │
│                 │                               │
│  ┌──────────────▼───────────────────────────┐  │
│  │ peci_backend  172.20.0.20                │  │
│  │ FastAPI + AI Engine : 8000               │  │
│  └──────────────┬───────────────────────────┘  │
│                 │                               │
│  ┌──────────────▼───────────────────────────┐  │
│  │ peci_db  172.20.0.10                     │  │
│  │ PostgreSQL : 5432  (nunca exposta)        │  │
│  └──────────────────────────────────────────┘  │
└─────────────────────────────────────────────────┘
```

| Serviço        | IP interno   | Porta interna | Porta externa |
|----------------|-------------|---------------|---------------|
| peci_frontend  | 172.20.0.30 | 80            | **80**        |
| peci_backend   | 172.20.0.20 | 8000          | —             |
| peci_db        | 172.20.0.10 | 5432          | —             |

## Seed de perguntas na base de dados

### `backend/database/tests/seed_remote.py`

Insere perguntas a partir de um ficheiro JSON na base de dados (local ou remota).

Comando base (aponta para o JSON por defeito `perguntas_uc.json`):

```powershell
python backend/database/tests/seed_remote.py
```

Comando com ficheiro especifico:

```powershell
python backend/database/tests/seed_remote.py backend/database/tests/perguntas_uc.json
```

> Edita as variaveis `SERVER_IP`, `DB_PORT`, `DB_USER`, `DB_PASS`, `DB_NAME` no topo do ficheiro para apontar para o servidor certo antes de correr.
