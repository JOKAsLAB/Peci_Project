# LogicStreak

**LogicStreak** is an interactive learning platform built for university students of Digital Systems and Computer Architecture. It combines gamified micro-learning with AI-generated exercises and an intelligent tutor that answers questions based on the actual course materials uploaded by professors.

---

## What it does

Students practice through short daily sessions on their phone or browser. Each session presents exercises generated on-demand by an AI pipeline grounded in professor-uploaded PDFs — so the content is always aligned with the real curriculum. After every answer, the system explains what was right or wrong in natural language.

Progress is tracked through XP, levels, and daily streaks, following the same engagement mechanics proven by platforms like Duolingo — but applied to engineering content.

Professors manage everything from a web dashboard: they upload course materials, review and publish AI-generated exercises, build ordered learning paths, and run live Kahoot-style quiz sessions with students. Administrators manage users, approve professor accounts, and configure course units.

---

## Features

### Student (mobile + web)
- Gamified practice sessions with XP, levels, and streaks
- Multiple Choice and True/False exercises generated from course materials
- Immediate AI-generated feedback explaining each answer
- Structured learning paths with topic unlock progression
- AI tutor chatbot (Andy) grounded in course bibliography
- Live quiz participation with real-time leaderboard
- Progress statistics and per-topic accuracy tracking

### Professor (web dashboard)
- Upload PDF course materials (automatically indexed for AI)
- Generate exercise batches via the Question Lab (AI-assisted)
- Review, edit, approve, or discard generated exercises before publishing
- Build ordered learning paths from published exercises
- Monitor student-reported questions and resolve them
- Create and host live quiz sessions with a room code

### Administrator (web dashboard)
- Approve or reject professor registrations
- Manage users, roles, and account status
- Create and configure course units, assign professors
- Respond to professor support requests
- Immutable audit log of all administrative actions

---

## Tech Stack

| Component | Technology |
|---|---|
| Mobile app | Flutter 3 (Android, iOS, Web) |
| Web dashboard | Vue.js 3 + Tailwind CSS |
| Backend API | FastAPI (Python, async) |
| Database | PostgreSQL 16 |
| AI pipeline | LangChain + ChromaDB + HuggingFace Embeddings |
| LLM generation | IAEduAPI (internal) |
| LLM decomposition | Groq (llama-3.3-70b) |
| Deployment | Docker + Docker Compose + nginx |

---

## Repository Structure

```
.
├── mobile/                   # Flutter app (Android, iOS, Web)
├── web/                      # Vue.js 3 web dashboard
├── backend/                  # FastAPI backend + AI engine
│   ├── backend/app/          # Routers, models, schemas, auth
│   └── database/             # Migrations and seed scripts
├── ai_engine/                # RAG pipeline, question generator, chatbot
├── PECI_TECHINCAL_REPORT/    # LaTeX technical report + user manuals
├── website_promocional/      # Promotional landing page
├── logo/                     # Project logos
├── docker-compose.yml
├── export_questions.py       # Post-deployment question import (see below)
└── DEPLOY.md                 # Full deployment guide
```

---

## Getting Started

### Prerequisites

- [Docker](https://docs.docker.com/get-docker/) + Docker Compose
- On Windows: Docker Desktop with WSL 2 enabled

### 1. Clone the repository

```bash
git clone https://github.com/JOKAsLAB/Peci_Project.git
cd Peci_Project
```

### 2. Configure the environment

Edit `backend/backend/app/.env` with your settings:

```env
DB_PASSWORD=your_secure_password
SECRET_KEY=your_random_32byte_hex_key
CORS_ALLOW_ORIGINS=http://YOUR_SERVER_IP,http://localhost
SMTP_HOST=smtp.gmail.com
SMTP_PORT=587
SMTP_USER=your@email.com
SMTP_PASSWORD=your_app_password
ADMIN_EMAIL=admin@peci.pt
ADMIN_PASSWORD=your_admin_password
```

Generate a secure `SECRET_KEY`:
```bash
python3 -c "import secrets; print(secrets.token_hex(32))"
```

Edit `ai_engine/keys.env` with your API keys (Groq and IAEduAPI).

### 3. Build and run

```bash
docker compose up -d --build
```

The first build downloads the embedding model (~300 MB) and may take 10–20 minutes.

```bash
docker compose ps   # all 3 services should show as healthy/running
```

Open `http://localhost` (local) or `http://YOUR_SERVER_IP` (remote).

The default admin account is created automatically on first startup using the `ADMIN_EMAIL` and `ADMIN_PASSWORD` values from `.env`.

---

## Importing Questions (Post-Deployment)

`export_questions.py` is a standalone script used **after the platform is live** to bulk-import pre-generated exercises into the database. Run it once after deployment to pre-populate the exercise bank before professors start using the platform.

```bash
# Import a single JSON file
python export_questions.py path/to/questions.json

# Import all JSON files in a folder
python export_questions.py path/to/folder/
```

---

## Local Development

### Backend

```bash
cd backend
pip install -r backend/requirements.txt
uvicorn app.main:app --reload --port 8000
```

### Web dashboard

```bash
cd web
npm install
npm run dev
```

### Mobile app

```bash
cd mobile
flutter pub get
flutter run
```

To point the app at a local backend, edit `mobile/lib/data/remote/api_client.dart` and set `apiBaseUrl` to `http://10.0.2.2:8000/api/v1` (Android emulator) or `http://localhost:8000/api/v1` (web/desktop).

---

## Useful Commands

```bash
# View live logs
docker compose logs -f backend
docker compose logs -f frontend

# Restart a service after config changes
docker compose restart backend

# Stop everything (data is preserved)
docker compose down

# Rebuild after code changes
docker compose up -d --build

# Wipe everything including the database
docker compose down -v
```

For a detailed deployment guide including CORS setup, SMTP configuration, and manual database operations, see [DEPLOY.md](DEPLOY.md).
