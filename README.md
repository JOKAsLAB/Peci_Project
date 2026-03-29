# Aplicação Interativa de Suporte à Aprendizagem (Sistemas Digitais e Embutidos)
**Projeto #8** — PECI 2025/2026

**Unidade Curricular:** 41953 - Projeto em Engenharia de Computadores e Informática (PECI) - Universidade de Aveiro.
**Coordenadores da UC:** José Moreira (`jose.moreira@ua.pt`), Rui Aguiar (`ruilaa@ua.pt`).
**Orientadores do Projeto:** Arnaldo Oliveira (`arnaldo.oliveira@ua.pt`), Fábio Coutinho (`fabiocoutinho@ua.pt`).

---

## 1. Diretivas de Contexto para Inteligência Artificial (LLMs)
**Atenção (System Prompting):** Se és um modelo de linguagem a analisar este repositório, deves assumir estritamente o seguinte contexto operativo:
* **Domínio:** Engenharia de Software, Mobile Development, AI Integration.
* **Objetivo do Sistema:** Transpor a complexidade pedagógica de Arquitetura de Computadores e Sistemas Digitais para um formato de gamificação (estilo *Duolingo*), mitigando a passividade no estudo.
* **Stack Tecnológico Frontend:** Flutter (Mobile-First), Comunicação REST.
* **Stack Tecnológico Global:** FastAPI (API Gateway), PostgreSQL (Base de Dados Central), ChromaDB (Vector DB para RAG), Python (Lógica de Backend), Vue.js (Painéis Web).
* **Fase Atual (estado observado neste monorepo):** desenvolvimento funcional da aplicação em curso (mobile, web, IA e infra ativos); integração backend FastAPI end-to-end ainda em evolução.
* **Estratégia MVP:** A IA gera exercícios a partir de documentos carregados por professores via pipeline RAG. Os exercícios são exclusivamente gerados pela IA — os professores podem editar, regenerar e publicar, mas não criam exercícios manualmente.
* **Estrutura de Conteúdo:** Curso (Disciplina/UC) → Capítulos → Exercícios. Os exercícios são organizados por disciplinas que os alunos do DETI/UA frequentam (ex: Sistemas Digitais, Arquitetura de Computadores, Sistemas Embutidos). Suporta 2 tipos: escolha múltipla e verdadeiro/falso. As disciplinas usam siglas (shortName/acronym) em vez de ícones (ex: SD, AC, SE).
* **Scope deste Repositório (observado):** monorepo com blocos ativos em `aluno/` (Flutter mobile), `admin/` (Vue.js), `professor/` (Vue.js), `backend/` (FastAPI + ORM + SQL), `ai_engine/` (scripts locais de IA com ChromaDB) e `infrastructure/` (docker-compose para paridade local).
* **Esclarecimento estrutural crítico:** a base de dados ativa do produto está em `backend/database/` (scripts SQL). Neste snapshot do branch não existe diretoria `archive/` na raiz.

## 2. Equipa e Responsabilidades Técnicas
| Membro | N.º Mec. | Área | Papel |
|---|---|---|---|
| Joaquim Martins | 115931 | Frontend (Monorepo do Projeto) | Lead |
| Duarte Lourenço | 114421 | Frontend (Monorepo do Projeto) | Colaborador |
| Carlos Verenzuela | 114597 | Backend & API | Lead |
| Francisco Matos | 113726 | Backend & API | Colaborador |
| João Pinho | 113602 | Motor IA (LLM & RAG) | Lead |
| Guilherme Gabino | 114947 | Motor IA (LLM & RAG) | Colaborador |

## 3. Contextualização e Motivação
* O ensino de Sistemas Digitais e Arquitetura de Computadores é complexo e exige dedicação prolongada.
* Existe uma necessidade crescente de métodos interativos para combater a passividade no estudo e a perda de concentração.
* Os conteúdos destas UCs têm grande dispersão no tempo — é importante validar e auto-avaliar conhecimentos ao longo do percurso académico.
* **Inspiração:** O Duolingo demonstrou que a gamificação pode tornar o estudo acessível, flexível e divertido, usando lições curtas adaptadas ao ritmo do utilizador.
* **Solução proposta:** Um ecossistema gamificado que usa LLMs para gerar exercícios dinâmicos, tirar dúvidas em tempo real, com feedback imediato e suporte mobile.

### 3.1. Trabalho Relacionado
| Plataforma | Interatividade | Domínio Técnico | IA / Feedback |
|---|---|---|---|
| Duolingo | Alta | Idiomas | Adaptativo |
| NotebookLM | Alta | Amplo (superficial) | Adaptativo |
| Khan Academy | Média | Matemática & Ciências | Dicas pré-definidas |
| **A nossa solução** | **Alta + Gamificação** | **Sist. Digitais → Embutidos (profundo)** | **Adaptativo (RAG)** |

## 4. Arquitetura do Sistema
O sistema opera numa arquitetura distribuída com quatro blocos principais:

### 4.1. Frontends (Neste Monorepo)
* **Flutter Mobile (Aluno):** Aplicação principal — exercícios gamificados com 2 tipos de questão (escolha múltipla e V/F), Tutor IA contextual (bottom sheet com explicações passo a passo, exemplos e dicas), sistema de inscrição em disciplinas, sistema de XP e níveis dinâmico (N1–N6), bloqueio de orientação em retrato. Catálogo inicial com 31 exercícios distribuídos por 12 módulos para arranque controlado da integração real.
* **Vue 3 + Vite + Pinia + Tailwind (Professor):** Painel docente completo — banco de exercícios central (58 exercícios) com filtros avançados (disciplina, módulo, dificuldade, tipo), upload de documentos da UC, laboratório de perguntas com LLM (mantido no código, oculto da navegação por decisão de fase), percursos de aprendizagem e pedidos administrativos ao admin. O registo de docente entra em estado pendente até aprovação administrativa.
* **Vue 3 + Vite + Pinia + Tailwind (Admin):** Painel de administração — login com email e password, gestão de disciplinas com autocomplete de professores (seleção por tags), gestão de utilizadores (passwords ocultas na tabela), dashboard com métricas, aprovação/rejeição de pedidos de criação de conta de professor com nota administrativa, gestão de pedidos administrativos dos docentes e confirmações explícitas em ações críticas. O admin fica focado em fluxos administrativos, não em gestão de matéria.

### 4.2. Backend & API
* **FastAPI (API Gateway):** App funcional em `backend/backend/app/main.py`, com `GET /`, `GET /health` e routers incluídos por domínio.
* **Camada de Dados Assíncrona:** Implementada em `backend/backend/app/database.py` (SQLAlchemy async engine + sessão + leitura de `.env`).
* **ORM de Domínio:** Modelos SQLAlchemy implementados em `backend/backend/app/models/` (utilizadores, académico, gamificação e administração).
* **Routers/Schemas:** Endpoints e DTOs Pydantic implementados em `backend/backend/app/routers/` e `backend/backend/app/schemas/` para auth, académico, admin, professor e aluno; bridge `ai-tutor` mantém resposta `501` neste branch.
* **PostgreSQL:** Base relacional modelada e operacionalizada por scripts SQL em `backend/database/` (`schema.sql`, `indexes.sql`, `tests/`, `deletes/`).

### 4.3. Sistema de IA
* **IA 1 — Chatbot (Tutor Inteligente):** Implementado localmente em `ai_engine/chatbot.py` com Streamlit + LangChain + Chroma + Groq.
* **IA 2 — Indexação documental:** Implementada em `ai_engine/ImportFiles.py` para ingestão de PDFs locais e criação de embeddings na coleção Chroma.
* **ChromaDB (Vector DB):** Configurado em `infrastructure/docker-compose.yml` e consumido pelos scripts da pasta `ai_engine/`.
* **Estado da integração RAG com backend:** Em aberto neste branch (não existe módulo `ai_engine/rag/` nem bridge funcional backend↔IA implementada no código atual).

### 4.4. Infraestrutura Local (Paridade de Ambiente)
* **Docker Compose (`infrastructure/`):** Orquestra PostgreSQL e ChromaDB localmente para desenvolvimento reproduzível na equipa.
* **Seeds/Inicialização SQL (`infrastructure/postgres/init/`):** Inicialização de extensões e bootstrap relacional.
* **Isolamento de responsabilidades:** O ciclo de vida dos serviços (BD vetorial e relacional) fica desacoplado das apps frontend.

### 4.5. Decisão Arquitetural: MVP vs. Evolução
A equipa adotou uma estratégia de **"Arquitetura Pronta para o Docente"**:

| Fase | Designação | Foco | Descrição |
|---|---|---|---|
| **Fase 1 (MVP)** | Conteúdo Curado | Estabilidade e Qualidade da IA | A equipa carrega os documentos oficiais da UC diretamente no servidor. |
| **Fase 2 (Atual)** | Plataforma Aberta | Escalabilidade | Painel docente para upload de documentos da UC, edição/publicação de exercícios, gestão de percursos e coordenação administrativa com o painel admin. |

**Fundamentação da decisão:**
1. **Garantia de Qualidade Pedagógica:** Documentos carregados pelos professores garantem que a IA é alimentada com bibliografia verificada, evitando alucinações.
2. **Segurança e Privacidade:** Upload controlado via painel docente com validação de formato e indexação automática.
3. **Foco na Gamificação:** A interface mobile foca-se exclusivamente na experiência do aluno com feedback imediato, soluções detalhadas e explicações por IA.

## 5. User Stories e Requisitos

### 5.1. Persona Principal
> **Tiago Martins** — 20 anos, 2.º ano LECI na UA. Inscrito em Sistemas Digitais e Arquitetura de Computadores. Tem dificuldade em digerir PDFs densos sobre CPU Datapaths e Assembly. Perde motivação sem feedback imediato.

### 5.2. Aluno
| ID | User Story | Critérios de Aceitação |
|---|---|---|
| US01 | **Prática Interativa:** Como aluno, quero resolver exercícios de 2 tipos (escolha múltipla, V/F) para progredir. | Feedback imediato com solução e explicação detalhada (FR). 2 tipos de questão suportados (FR). Interface visual com badges de tipo coloridos (NFR). Filtros por disciplina, capítulo, dificuldade e tipo (FR). |
| US02 | **Tutor IA 24/7:** Como aluno, quero pedir explicações adicionais ao Tutor IA sobre um exercício para compreender o conceito. | Botão "Pedir explicação ao Tutor IA" em cada exercício após resposta (FR). Explicação contextualizada com solução completa (FR). Resposta da LLM em < 5 segundos (NFR). |
| US03 | **Estudo Online:** Como aluno, quero aceder a exercícios e pedir explicações à IA sempre que tiver ligação à internet. | Acesso a exercícios gerados por IA via API (FR). Chatbot de exploração com explicações contextualizadas (FR). |
| US04 | **Autenticação:** Como aluno, quero fazer login ou criar conta com email @ua.pt para aceder à plataforma. | Validação de email institucional (FR). Password com mínimo 6 caracteres (FR). Opção de criar conta com seleção de papel (Aluno/Docente) (FR). |
| US05 | **Filtro por Disciplina:** Como aluno, quero filtrar exercícios por disciplina e capítulo na prática. | Chips de filtro por curso e capítulo no feed de exercícios (FR). Filtros cumulativos e reactivos (FR). |
| US05b | **Exploração Autónoma (Chatbot IA):** Como aluno, quero interagir com um chatbot IA que gera exercícios, explica matéria e responde a dúvidas sobre qualquer tópico da disciplina. | Ecrã "Explorar" com interface de chat (FR). Seleção de disciplina como contexto (FR). Geração de exercícios inline respondíveis dentro do chat (FR). Explicações de matéria por IA (FR). Sugestões rápidas de ações (FR). |

### 5.3. Professor
| ID | User Story | Critérios de Aceitação |
|---|---|---|
| US07 | **Upload de Documentos da UC:** Como professor, quero carregar documentos (PDF, PPTX, DOCX) da UC. | Upload com métricas de documentos disponíveis por disciplina (FR). Remover documentos (FR). |
| US07b | **Prompting de Perguntas com LLM:** Como professor, quero criar lotes de perguntas com base em documentação da UC e instruções de prompt. | Seleção de documentos indexados por disciplina (FR). Prompt pedagógico e parâmetros (tipo, dificuldade, quantidade) (FR). Pré-visualização de payload para backend LLM (FR). |
| US10b | **Banco de Exercícios:** Como professor, quero consultar e filtrar todo o banco de exercícios por disciplina, módulo, dificuldade e tipo. | Filtros avançados (disciplina, módulo dependente, dificuldade, tipo) (FR). Paginação de 15 exercícios por página (FR). Modal de detalhe com opções e explicação (FR). Publicar/despublicar exercícios (FR). |
| US10c | **Autonomia de Conteúdo Curricular:** Como professor, quero criar e atualizar conteúdo de matéria (questões/tópicos/correções) diretamente no meu painel, sem pedir aprovação administrativa para isso. | Gestão direta no banco de exercícios e percursos (FR). Sem workflow de pedido ao admin para conteúdo curricular (NFR). |

### 5.4. Administrador
| ID | User Story | Critérios de Aceitação |
|---|---|---|
| US10 | **Gestão de Disciplinas:** Como admin, quero gerir disciplinas com múltiplos professores por UC. | CRUD de disciplinas com autocomplete de professores (seleção por tags removíveis) (FR). Atribuições de docentes persistidas no backend e visíveis após reload (FR). Toggle ativo/inativo por disciplina (FR). |
| US11 | **Gestão de Utilizadores:** Como admin, quero gerir professores e alunos na plataforma. | Lista com filtros (todos/professores/alunos/ativos/inativos) (FR). Edição e remoção de utilizadores (FR). |
| US11b | **Aprovação de Contas de Docente:** Como admin, quero aprovar ou rejeitar pedidos de registo de professores antes de ativar o acesso. | Lista de pedidos pendentes com dados reais do docente (FR). Aprovar/rejeitar com nota de revisão (FR). Ao aprovar, a conta passa de `Suspended` para `Active`; ao rejeitar, fica `Deactivated` (FR). |
| US12 | **Dashboard:** Como admin, quero ter uma visão geral da plataforma com métricas. | Contadores de utilizadores e disciplinas (FR). Últimos logins e disciplinas ativas (FR). |
| US13 | **Pedidos Administrativos dos Docentes:** Como admin, quero rever pedidos administrativos submetidos pelos docentes (acessos, suporte de plataforma e operações) sem intervir em matéria curricular. | Lista de pedidos administrativos com filtros por estado (FR). Aprovar/rejeitar com nota (FR). Sem gestão de exercícios/tópicos curriculares no admin (NFR). |

## 6. UI/UX e Design System
A interface exige o cumprimento de métricas de legibilidade modernas e performance de renderização de 60 FPS.

* **Tema Base:** *High-Contrast Dark Mode* obrigatório (Otimização OLED).
* **Identidade Visual (Universidade de Aveiro):**
  * `Primary Background`: `#121212` (Preto Absoluto)
  * `Surface/Cards`: `#1E1E1E` (Cinzento Escuro)
  * `Brand Accent`: `#00B140` (Verde Institucional)
  * `Success State`: `#00E676` (Validação de Exercício)
  * `Error State`: `#CF6679` (Erro em Exercício)
  * `Warning`: `#FFB300` (Alerta / Pedidos Pendentes)
* **Tipografia:** Vetores geométricos de alta legibilidade (*Inter*) — consistente entre Flutter (Google Fonts) e Vue (Tailwind).
* **Animações:** Transições não-bloqueantes. A thread de UI (Isolate principal do Flutter) não pode ser bloqueada por operações de I/O da SQLite.
* **Otimização para Telemóveis Lentos (Flutter):** Fluxos de prática e perfil ajustados para reduzir churn de renderização (controller reuse, decks pré-gerados por ciclo, isolamento de repaint em cartões e animações curtas de navegação).
* **Consistência Web (Admin + Professor):** Tokens visuais harmonizados (`background`, `surface`, `brand`, `warning`, `info`), atmosfera com gradientes subtis e shell com superfícies translúcidas para identidade visual unificada.
* **Scroll UX Global (Flutter):** Comportamento de scroll clamp sem efeito de overscroll/stretch para evitar deformações no limite das listas e páginas.
* **Orientação:** Aplicação mobile bloqueada em retrato (portrait lock) a nível de Flutter, Android e iOS.

## 7. Topologia de Comunicação (API Gateway)
Estado observado no branch atual:
* **Topologia alvo:** Flutter/Vue como *thin clients* a consumir FastAPI Gateway com JWT e endpoints versionados.
* **Topologia efetiva neste snapshot:** frontends ainda operam maioritariamente com estado local de bootstrap (Pinia no web e Riverpod no mobile); backend FastAPI já expõe endpoints versionados (`/api/v1/auth`, `/api/v1/academic`, `/api/v1/admin`, `/api/v1/professors`, `/api/v1/students`), com adoção progressiva pelos clientes.
* **Autenticação web (estado atual):** Painéis admin/professor já autenticam contra FastAPI (`POST /api/v1/auth/login`, `GET /api/v1/auth/me`) com validação de role no cliente e persistência de sessão conforme escolha do utilizador no login (localStorage quando "Lembrar-me" ativo, sessionStorage quando desativado). Registo de professor via `POST /api/v1/auth/register` entra em estado pendente (`Suspended`) até decisão do admin.
* **Dados de domínio web (estado atual):** Admin já consome FastAPI para utilizadores (`GET/PATCH/DELETE /api/v1/admin/users` + criação via `POST /api/v1/auth/register`), UCs (`GET/POST/PATCH/DELETE /api/v1/admin/course-units` com `professor_ids` e retorno de metadados dos docentes) e decisões administrativas (`GET/PATCH /api/v1/admin/requests`); painel professor já consome `GET/POST /api/v1/professors/requests`.
* **Autenticação mobile (estado atual):** Fluxo local de transição com `mockAuthProvider` no router do Flutter; integração ao backend ficará na próxima etapa incremental.
* **RAG/Chatbot:** Disponível por execução local de `ai_engine/chatbot.py` (Streamlit), fora da malha API Gateway.

## 8. Metodologia e Calendarização (OpenUP)
O projeto segue a metodologia **OpenUP** (Open Unified Process), com 4 fases:

### 8.1. Fases do Projeto
| Fase | Período | Objetivo Principal |
|---|---|---|
| **Inception** | Fev 2026 | Definição de âmbito, casos de uso e viabilidade. |
| **Elaboration** | Mar 2026 | Desenho da arquitetura híbrida (Cloud/Local), requisitos, UI/UX. Prova de conceito. |
| **Construction** | Abr - Mai 2026 | Desenvolvimento do motor de exercícios IA, gamificação e app móvel. Protótipo funcional. |
| **Transition** | Mai - Jun 2026 | Beta testing, fine-tuning da LLM e apresentação final. |

### 8.2. Entregas e Datas Críticas
| Data | Entrega |
|---|---|
| 20/03/2026 | Submissão da 1.ª parte do relatório técnico (max. 15 páginas) |
| Jun 2026 | Students@DETI — demonstração, poster e vídeo |
| 08/06/2026 | Submissão do relatório técnico final |

### 8.3. Estado Atual
> **Fase ativa (observada):** Construction com frontends utilizáveis e base de dados modelada; integração backend/API e integração RAG via gateway ainda em construção.

**Conquistas observadas neste branch:**
* Frontends admin/professor em Vue 3 + Pinia + Vite operacionais com portas dedicadas e login real via backend FastAPI.
* Frontend aluno em Flutter com práticas, filtros, Tutor IA em UI e autenticação local de transição.
* Backend FastAPI com estrutura `app/` funcional (`main.py`, `database.py`, `.env.example`, `requirements.txt`) e modelos ORM implementados.
* Base de dados relacional definida em SQL (`backend/database/schema.sql`, `indexes.sql`, testes e scripts de reset).
* Infraestrutura local versionada em `infrastructure/docker-compose.yml` com PostgreSQL + ChromaDB.
* Motor IA disponível em modo local via scripts (`ai_engine/ImportFiles.py`, `ai_engine/chatbot.py`).

**Lacunas técnicas observadas neste branch:**
* Frontends ainda não consomem end-to-end todos os domínios FastAPI em todas as vistas (auth web + gestão admin/professor de pedidos/utilizadores/UCs já integrada; restantes módulos web e mobile ainda em transição).
* `POST /api/v1/ai-tutor/query` existe, mas permanece como stub com `501 Not Implemented`.
* Arranque da API depende de PostgreSQL disponível no startup (`SELECT 1`), sem modo degradado offline.
* `backend/alembic.ini` e diretoria de migrações Alembic continuam ausentes.
* `ai_engine/rag/` ausente (arquitetura RAG modular ainda não materializada neste snapshot).

## 9. Comunicação e Ferramentas
| Ferramenta | Utilização |
|---|---|
| **GitHub** | Controlo de versões, code reviews (Pull Requests), issues e CI. |
| **Microsoft Teams** | Controlo de tarefas (Trello-style), ficheiros partilhados, comunicação interna diária. |
| **Reuniões semanais** | Sincronização de equipa e planeamento de sprint. |
| **Reuniões com orientadores** | Validação de progresso e alinhamento. |

## 10. Riscos Identificados
| Risco | Impacto | Mitigação |
|---|---|---|
| **Alucinações da LLM** | Exercícios incorretos, perda de confiança do utilizador. | IA geradora de perguntas ancorada em RAG com ChromaDB e revisão docente antes de publicar. |
| **Falta de privacidade de dados** | Exposição de dados pessoais dos alunos. | Camada de anonimização de PII antes de envio a APIs externas. Autenticação JWT. |
| **Fraca experiência de rede** | Experiência degradada com ligação lenta. | Otimização de payloads, caching local. |
| **Scope creep** | Atrasos na entrega, funcionalidades incompletas. | Estratégia MVP com conteúdo curado. Fases claramente delimitadas. |
| **Latência da IA** | Tempos de resposta > 5s no chatbot. | Otimização de prompts, caching de respostas frequentes. |

## 11. Estrutura do Repositório

### 11.1. Raiz do Monorepo
```
Peci_Project/
├── README.md                          # Este ficheiro
├── admin/                             # Painel de administração (Vue 3 + Vite + Pinia + Tailwind)
├── aluno/                             # Aplicação Flutter Mobile (Aluno)
├── backend/                           # Scaffold FastAPI + SQL relacional
├── ai_engine/                         # Scripts locais de IA (indexação + chatbot)
├── infrastructure/                    # Docker Compose para PostgreSQL e ChromaDB
├── professor/                         # Painel docente (Vue 3 + Vite + Pinia + Tailwind)
├── script/                            # Hub de scripts (run/test/backend) + documentação operacional
├── website promocional/               # Página promocional estática
└── build/                             # Artefactos de build
```

**Nota de interpretação da árvore:**
* `backend/database/` = scripts SQL ativos do modelo relacional (schema/indexes/testes).
* `backend/backend/app/` = bootstrap FastAPI + camada ORM (routers e schemas ainda em evolução).
* `README_BACKEND.md` não existe; a documentação local do backend está em `backend/README.md`.

### 11.2. Projeto Flutter (`aluno/`)
```
aluno/
├── lib/
│   ├── main.dart                      # Ponto de entrada (ProviderScope + GoRouter + AppTheme + Portrait Lock)
│   ├── app/                           # Lógica aplicacional (em desenvolvimento)
│   ├── core/
│   │   ├── database/                  # Abstração de BD (em desenvolvimento)
│   │   ├── network/                   # Camada de rede Dio (em desenvolvimento)
│   │   ├── router/
│   │   │   └── app_router.dart        # Rotas GoRouter (/login, /register, shell: Cursos/Prática/Perfil)
│   │   └── theme/
│   │       └── app_theme.dart         # Tema dark institucional (cores UA, tipografia Inter)
│   ├── data/
│   │   ├── mock_data.dart             # Modelos e dados de bootstrap local (3 cursos, 12 capítulos, 31 exercícios)
│   │   └── local/
│   │       ├── database.dart          # Schema Drift (Exercises + TelemetryQueue) e DAOs
│   │       └── database.g.dart        # Código gerado pelo Drift (build_runner)
│   ├── features/                      # Feature layers (em desenvolvimento)
│   │   ├── auth/
│   │   ├── gamification/
│   │   │   └── providers/
│   │   │       └── feed_provider.dart # Estado do feed (filtros, deck aleatório por ciclos)
│   │   ├── learning/
│   │   ├── profile/
│   │   │   └── providers/
│   │   │       └── profile_provider.dart # Cálculo de métricas de perfil (XP, nível, streak)
│   │   └── tutor_ai/
│   │       └── providers/
│   │           └── chat_provider.dart # Sessão de chat contextual por exercício com streaming local de transição
│   └── presentation/
│       ├── auth/
│       │   ├── login_screen.dart      # Ecrã de login (email @ua.pt + password, auth local de transição + atualização de estado global de auth)
│       │   └── register_screen.dart   # Ecrã de registo (seleção Aluno/Docente, validação completa)
│       ├── courses/
│       │   └── courses_screen.dart    # Lista de cursos com inscrição, Duolingo-style path, exercícios por capítulo
│       ├── explore/
│       │   └── explore_screen.dart     # Chatbot IA — interface de conversação com respostas contextuais por disciplina
│       ├── gamification/
│       │   ├── exercise_feed_screen.dart  # Feed vertical — 2 tipos (MC, V/F), filtros seccionados, seletor de exercício livre, explicação sempre visível após resposta, Tutor IA contextual
│       │   └── skill_tree_screen.dart     # Ecrã placeholder (legado)
│       ├── profile/
│       │   ├── profile_screen.dart    # Perfil com XP dinâmico (N1–N6), fontes de XP, barra de progresso de nível
│       │   └── settings_screen.dart   # Definições da aplicação
│       ├── shared/
│       │   └── tutor_chat_dialog.dart  # Tutor IA reutilizável — bottom sheet contextual com explicações, exemplos e dicas
│       └── shell/
│           └── main_shell.dart        # Shell com NavigationBar + swipe horizontal entre abas (Cursos, Prática, Perfil)
├── test/
│   └── widget_test.dart               # 4 testes de widget
├── android/                           # Config nativa Android (portrait lock no manifest)
├── ios/                               # Config nativa iOS (portrait lock no Info.plist)
├── windows/                           # Config nativa Windows
└── pubspec.yaml                       # Dependências e metadata
```

### 11.3. Painel Docente (`professor/`)
```
professor/
├── index.html                         # Entry point Vite
├── package.json                       # Dependências npm
├── vite.config.js                     # Config Vite (porta 5173)
├── tailwind.config.js                 # Tema dark (cores UA)
├── src/
│   ├── main.js                        # Bootstrap (createApp + Pinia + Router)
│   ├── App.vue                        # Layout com login gate, sidebar e header
│   ├── style.css                      # Estilos globais Tailwind
│   ├── router/
│   │   └── index.js                   # 6 rotas (Dashboard, Exercícios, Percursos, Documentos da UC, Perguntas com LLM, Pedidos ao Admin)
│   ├── stores/
│   │   ├── authStore.js              # Estado global de autenticação docente (login/logout + persistência local)
│   │   ├── exerciseStore.js           # 58 exercícios — banco central (3 disciplinas, 11 módulos, filtros por disciplina/módulo/dificuldade/tipo)
│   │   ├── pathStore.js               # 3 percursos de aprendizagem (SD, AC, SE) com módulos e exercícios (MC, V/F)
│   │   ├── questionLabStore.js        # Documentos disponíveis para prompting e rascunhos gerados para revisão
│   │   └── adminRequestStore.js       # Pedidos administrativos do docente para o admin (acesso/plataforma/operações)
│   └── views/
│       ├── LoginView.vue              # Login/registo para professores
│       ├── DashboardView.vue          # Métricas de conteúdo e suporte académico
│       ├── ExercisesView.vue          # Banco de exercícios com filtros avançados (disciplina, módulo, dificuldade, tipo), paginação, modal de detalhe
│       ├── GeneratorView.vue          # Geração de exercícios por IA (oculto da navegação)
│       ├── QuestionLabView.vue        # Criação de perguntas com LLM (documentos + prompt + payload preview)
│       ├── PathBuilderView.vue        # Editor de percursos com módulos e exercícios (MC, V/F)
│       ├── DocumentsView.vue          # Upload e gestão de documentos da UC (PDF, PPTX, DOCX)
│       └── RequestsView.vue           # Pedidos administrativos ao admin (não curricular)
└── public/
    └── vite.svg
```

### 11.4. Painel de Administração (`admin/`)
```
admin/
├── index.html                         # Entry point Vite
├── package.json                       # Dependências npm
├── vite.config.js                     # Config Vite (porta 5174)
├── tailwind.config.js                 # Tema dark (cores UA)
├── postcss.config.js                  # PostCSS
├── src/
│   ├── main.js                        # Bootstrap (createApp + Pinia + Router)
│   ├── App.vue                        # Layout com login gate (isAdmin), sidebar e header
│   ├── style.css                      # Estilos globais Tailwind
│   ├── router/
│   │   └── index.js                   # 5 rotas (Dashboard, Disciplinas, Utilizadores, Aprovações de Contas, Pedidos Administrativos)
│   ├── stores/
│   │   ├── authStore.js              # Estado global de autenticação admin (login/logout + persistência local)
│   │   ├── disciplineStore.js         # 4 disciplinas (SD, AC, SE, PECI) com múltiplos professores
│   │   ├── userStore.js               # 22 utilizadores + pedidos pendentes de conta docente (aprovar/rejeitar)
│   │   └── adminRequestStore.js       # Pedidos administrativos submetidos por docentes (acesso/plataforma/operações)
│   └── views/
│       ├── LoginView.vue              # Login admin com email e password
│       ├── DashboardView.vue          # Dashboard com métricas globais da plataforma
│       ├── DisciplinesView.vue        # CRUD de UCs com autocomplete e seleção de professores por tags
│       ├── UsersView.vue              # Gestão de utilizadores (passwords ocultas na tabela, filtros, CRUD, toggle ativo/inativo)
│       ├── AccountApprovalsView.vue   # Aprovação/rejeição de pedidos de criação de conta de professor
│       └── RequestsView.vue           # Gestão de pedidos administrativos dos docentes (aprovar/rejeitar com nota)
└── public/
    └── vite.svg
```

### 11.5. Backend (`backend/`)
```
backend/
├── README.md                           # README local backend/database
├── backend/
│   ├── requirements-dev.txt            # Dependências de testes (pytest + requests)
│   ├── tests/
│   │   └── smoke/
│   │       ├── test_api_smoke.py       # Suíte smoke de endpoints /api/v1/*
│   │       └── README.md               # Guia local de execução da suíte
│   └── app/
│       ├── main.py                     # Ponto de entrada FastAPI + / e /health + include dos routers
│       ├── database.py                 # Configuração SQLAlchemy async + settings (.env)
│       ├── .env.example                # Template de variáveis de ambiente
│       ├── requirements.txt            # Dependências Python runtime do backend
│       ├── models/                     # Modelos SQLAlchemy do domínio
│       ├── schemas/                    # Schemas Pydantic implementados por domínio
│       └── routers/                    # Routers FastAPI implementados por domínio
└── database/
    ├── schema.sql                      # Modelo relacional principal
    ├── indexes.sql                     # Índices de performance
    └── deletes/
        ├── drop_tables.sql             # Drop de tabelas
        └── drop_indexes.sql            # Drop de índices
```

### 11.6. Scripts Operacionais (`script/`)
```
script/
├── README.md                           # Documentação detalhada de runs/testes/bootstrap
├── run/
│   ├── run_admin.ps1                   # Arranque do painel admin + bootstrap backend local
│   ├── run_professor.ps1               # Arranque do painel professor + bootstrap backend local
│   ├── run_aluno.ps1                   # Arranque Flutter mobile no emulador Android
│   └── ensure_web_backend.ps1          # Bootstrap de infraestrutura/backend para painéis web
├── test/
│   ├── run_backend_smoke.ps1           # Execução automatizada da suíte smoke da API
│   ├── run_web_store_tests.ps1          # Execução de testes Vitest (stores admin + professor)
│   ├── run_web_e2e_tests.ps1            # Execução E2E browser (Playwright) para fluxos críticos Admin + Professor
│   ├── run_admin_auth_check.ps1        # Validação e2e de login admin (login + /me)
│   ├── run_database_sql_tests.ps1      # Runner dos testes SQL (insert/select/truncate opcional)
│   ├── run_aluno_widget_tests.ps1      # Runner de widget tests Flutter
│   ├── run_all_tests.ps1               # Runner agregado de todos os testes
│   ├── clean_test_artifacts.ps1        # Limpeza de artefactos gerados por testes/build
│   ├── run_release_validation.ps1      # Runner de release (valida e limpa)
│   ├── e2e/
│   │   ├── package.json                 # Dependências Playwright da suite browser
│   │   ├── playwright.config.js         # Configuração de execução E2E
│   │   └── tests/
│   │       └── admin-professor-flows.spec.js # Fluxos críticos Admin + Professor
│   └── sql/
│       ├── test_inserts.sql            # Massa de teste e validação SQL
│       ├── test_admin_professor_integrity.sql # Integridade transacional Admin/Professor (sem persistir alterações)
│       ├── test_truncate.sql           # Limpeza de dados SQL
│       └── useful_selects.sql          # Queries utilitárias SQL
└── backend/
    ├── bootstrap_local_stack.py        # Bootstrap idempotente de schema ORM + conta admin local
    ├── local_schema_orm_compatible.sql # Recriação SQL compatível com naming do ORM
    └── reset_db_from_models.py         # Reset local de schema a partir dos models
```

### 11.6. Motor IA (`ai_engine/`)
```
ai_engine/
├── README.md                           # Guia local de execução da IA
├── requirements.txt                    # Dependências Python da IA
├── chatbot.py                          # Tutor IA local (Streamlit + RAG)
├── ImportFiles.py                      # Ingestão/indexação de PDFs para Chroma
└── biblio/                             # Bibliografia PDF de suporte ao RAG
```

### 11.7. Infraestrutura (`infrastructure/`)
```
infrastructure/
├── .env.example                       # Configuração local de portas e credenciais
├── chromadb/
│   └── .gitkeep                       # Placeholder de diretoria de dados vetoriais
├── docker-compose.yml                 # Orquestra PostgreSQL e ChromaDB
├── postgres/
│   └── init/
│       └── 001_extensions.sql         # Bootstrap SQL inicial
```

### 11.8. Índice Curado de Ficheiros Essenciais (Contexto para IA)
Este índice lista apenas os ficheiros de maior valor semântico para evolução do produto, evitando artefactos gerados e diretórios de build.

**Esclarecimento sobre IA legada e bibliografia ativa**
* A branch `origin/01-IA` contém apenas `README.md` (snapshot remoto mínimo).
* A bibliografia técnica ativa da IA (dependências executáveis) está em `ai_engine/requirements.txt`.
* O código IA ativo neste branch está em `ai_engine/chatbot.py` e `ai_engine/ImportFiles.py`.

**App Flutter (Aluno) — Núcleo funcional**
* `aluno/lib/main.dart` — bootstrap da app, lock em retrato e comportamento global de scroll.
* `aluno/lib/core/router/app_router.dart` — shell e rotas principais.
* `aluno/lib/core/theme/app_theme.dart` — tokens visuais e tema.
* `aluno/lib/data/mock_data.dart` — modelos + dataset de bootstrap local para integração progressiva.
* `aluno/lib/presentation/shell/main_shell.dart` — navegação por tabs + swipe horizontal.
* `aluno/lib/presentation/gamification/exercise_feed_screen.dart` — feed de prática (filtros, randomização por ciclo, explicações, tutor IA).
* `aluno/lib/presentation/profile/profile_screen.dart` — perfil, XP, níveis e ênfase de streak.
* `aluno/lib/presentation/shared/tutor_chat_dialog.dart` — componente reutilizável do tutor IA.
* `aluno/lib/features/gamification/providers/feed_provider.dart` — estado do feed de prática.
* `aluno/lib/features/tutor_ai/providers/chat_provider.dart` — estado conversacional do tutor IA.

**Website Professor — Núcleo funcional**
* `professor/src/App.vue` — shell, login gate e navegação.
* `professor/src/router/index.js` — mapa de rotas docentes.
* `professor/src/stores/authStore.js` — estado global de autenticação docente.
* `professor/src/stores/exerciseStore.js` — banco central de exercícios.
* `professor/src/stores/questionLabStore.js` — estado da feature LLM (mantida, oculta no menu).
* `professor/src/views/ExercisesView.vue` — filtros e gestão do banco.
* `professor/src/views/DocumentsView.vue` — upload/gestão documental.
* `professor/src/views/QuestionLabView.vue` — laboratório de prompting LLM.
* `professor/src/views/RequestsView.vue` — submissão de pedidos administrativos para o admin (sem pedidos curriculares).

**Website Admin — Núcleo funcional**
* `admin/src/App.vue` — shell, login gate e navegação.
* `admin/src/router/index.js` — mapa de rotas admin.
* `admin/src/stores/authStore.js` — estado global de autenticação admin.
* `admin/src/stores/userStore.js` — utilizadores + aprovações de conta docente.
* `admin/src/stores/disciplineStore.js` — disciplinas e professores.
* `admin/src/views/AccountApprovalsView.vue` — aprovação/rejeição de registos docentes.
* `admin/src/views/DisciplinesView.vue` — CRUD de disciplinas com autocomplete de professores.
* `admin/src/views/UsersView.vue` — gestão de utilizadores.

**Backend (FastAPI + ORM) — Núcleo funcional**
* `backend/backend/app/main.py` — bootstrap FastAPI + endpoints `GET /` e `GET /health`.
* `backend/backend/app/database.py` — engine/sessão assíncrona e carregamento de settings.
* `backend/backend/app/models/*.py` — modelos SQLAlchemy implementados (user, academic, gamification, admin).
* `backend/backend/app/routers/*.py` — endpoints implementados para auth/admin/professors/students/academic.
* `backend/backend/app/schemas/*.py` — DTOs Pydantic implementados (incluindo auth e payloads de domínio).
* `backend/backend/app/requirements.txt` — manifesto de dependências backend versionado.
* `backend/backend/app/.env.example` — template de ambiente para execução local.
* `backend/database/schema.sql` — modelo relacional operacional.
* `backend/database/indexes.sql` — índices operacionais.

**AI Engine (RAG + ChromaDB) — Núcleo funcional**
* `ai_engine/ImportFiles.py` — ingestão documental e indexação em Chroma.
* `ai_engine/chatbot.py` — recuperação semântica + geração de resposta no Streamlit.

**Infraestrutura (Paridade local)**
* `infrastructure/docker-compose.yml` — serviço local de PostgreSQL + ChromaDB.
* `infrastructure/postgres/init/001_extensions.sql` — inicialização de extensões SQL.

**Infra de Execução e Coordenação**
* `script/run/run_aluno.ps1` — execução rápida Flutter com validação ADB/emulador.
* `script/run/run_professor.ps1` — execução rápida professor em porta fixa 5173, com bootstrap de infraestrutura/backend por defeito.
* `script/run/run_admin.ps1` — execução rápida admin em porta fixa 5174, com bootstrap de infraestrutura/backend por defeito.
* `script/run/ensure_web_backend.ps1` — garante API FastAPI saudável antes dos painéis web, incluindo criação automática de `backend/backend/app/.env`, criação de `.venv`, instalação de dependências em falta e bootstrap idempotente de schema/admin local.
* `script/test/run_backend_smoke.ps1` — arranca API local temporária, corre smoke tests e encerra servidor automaticamente.
* `script/test/run_web_store_tests.ps1` — executa a suíte Vitest dos stores dos painéis admin/professor.
* `script/test/run_web_e2e_tests.ps1` — executa testes browser E2E (Playwright) para fluxos críticos de integração real Admin↔Professor↔Backend.
* `script/test/run_admin_auth_check.ps1` — valida o login admin real e confirmação de role (`/auth/login` + `/auth/me`).
* `script/test/run_database_sql_tests.ps1` — executa testes SQL centralizados em `script/test/sql`.
* `script/test/run_aluno_widget_tests.ps1` — executa widget tests do módulo Flutter `aluno/`.
* `script/test/run_all_tests.ps1` — runner agregado para backend smoke + web stores + web E2E + SQL + widget tests Flutter.
* `script/test/clean_test_artifacts.ps1` — remove artefactos gerados (dist, caches, pyc, pytest cache) antes de commit/push.
* `script/test/run_release_validation.ps1` — executa validação integrada e limpeza automática para publicação.
* `script/README.md` — guia detalhado de execução e testes dos scripts do projeto.
* `README.md` — contrato arquitetural e estado consolidado.
* `backend/README.md` — documentação local de base de dados/backend.

**Lacunas de estrutura observadas**
* `POST /api/v1/ai-tutor/query` ainda devolve `501 Not Implemented` (bridge backend↔RAG pendente).
* `backend/alembic.ini` não existe.
* `ai_engine/rag/` não existe.

**Ficheiros a ignorar para contexto IA (baixa relação sinal/ruído)**
* `aluno/build/`, `build/`, `**/*.g.dart`, `.dart_tool/`, `node_modules/`, `android/app/build/`, `ios/Pods/`.

## 12. Funcionalidades Implementadas

### 12.1. Aplicação Aluno (Flutter)
| Funcionalidade | Estado | Detalhes |
|---|---|---|
| Login / Registo | Implementado | Fluxo de autenticação alinhado ao contrato API, com provider local de transição (`mockAuthProvider`) para evitar loop de redirecionamento |
| Bloqueio em Retrato | Implementado | Portrait lock a 3 níveis (Flutter, Android Manifest, iOS Info.plist) |
| Ecrã de Cursos | Implementado | 3 disciplinas com siglas (SD, AC, SE), path Duolingo-style, sistema de inscrição |
| Exercícios por Capítulo | Implementado | Fluxo de exercícios por capítulo com barra de progresso e resumo final com breakdown de XP |
| Feed de Exercícios | Implementado | 31 exercícios (3 disciplinas, 12 módulos), 2 tipos (MC, V/F), feed vertical com filtros seccionados + randomização por ciclos (sem repetição antes de cobrir todos) + seletor para saltar diretamente para qualquer exercício |
| Filtros Avançados | Implementado | Secções etiquetadas (DISCIPLINA, MATÉRIA, DIFICULDADE & TIPO), botão "Limpar" filtros, chips compactos |
| Soluções e Explicações | Implementado | Solução mostrada após resposta e explicação sempre visível (certo ou errado), Tutor IA contextual (bottom sheet) |
| Tutor IA | Implementado | Bottom sheet reutilizável com ações rápidas (explicar passo a passo, dar exemplo, dicas, análise de opções erradas) |
| Turmas e Quizzes (Legado de Protótipo) | Descontinuado nesta fase | Fluxo removido do router/shell para simplificar a operação ativa em Cursos/Prática/Perfil |
| Sistema de XP e Níveis | Implementado | 6 níveis dinâmicos (N1–N6), fontes de XP (capítulos + exercícios + streak), barra de progresso de nível |
| Perfil | Implementado | Avatar, NMec, stats filtradas por cursos inscritos, breakdown de fontes de XP, cartão de streak com ênfase diária e progresso para próximo marco |
| Base de Dados Local | Implementado | Schema Drift com tabelas Exercises e TelemetryQueue |
| Exploração (Chatbot) | Implementado | Chatbot IA com respostas contextuais por disciplina (12+ tópicos), geração de exercícios inline |
| Navegação por Swipe | Implementado | Troca horizontal entre as 3 abas do shell também por gesto, além dos botões da NavigationBar |
| Scroll & Physics | Implementado | Scroll global clamp sem overscroll/stretch, evitando deformações no fim de listas e páginas |

### 12.2. Painel Docente (Vue.js)
| Funcionalidade | Estado | Detalhes |
|---|---|---|
| Login / Registo | Implementado | Gate de autenticação no App.vue, sincronização com `authStore` e persistência local de sessão; registo docente fica pendente de aprovação admin antes do primeiro login |
| Dashboard | Implementado | Métricas de conteúdo (exercícios publicados/rascunho), percursos publicados, documentos indexados e pedidos administrativos pendentes |
| Banco de Exercícios | Implementado | 58 exercícios (3 disciplinas, 11 módulos), filtros avançados, paginação (15/página), modal de detalhe |
| Upload de Documentos da UC | Implementado | Catálogo inicial de documentos e fluxo de upload pronto para persistência backend/IA |
| Perguntas com LLM | Standby (Oculto) | Funcionalidade mantida no código (rota/view/store), mas oculta da navegação docente para faseamento de roadmap |
| Turmas / Quizzes / Estatísticas de Alunos (Legado de Protótipo) | Descontinuado nesta fase | Rotas, stores e views removidas para manter foco no domínio ativo de conteúdo curricular + pedidos administrativos |
| Percursos de Aprendizagem | Implementado | 3 percursos (SD 5 módulos, AC 4 módulos, SE 3 módulos), exercícios (MC, V/F) |
| Conteúdo Académico | Implementado | Gestão curricular direta no banco de exercícios/percursos, sem workflow de pedido ao admin |
| Pedidos ao Admin | Implementado | Submissão de pedidos administrativos (acesso/plataforma/operações) com confirmação explícita e acompanhamento de estado |

### 12.3. Painel de Administração (Vue.js)
| Funcionalidade | Estado | Detalhes |
|---|---|---|
| Login / Registo | Implementado | Login com email e password, gate de autenticação com prop `isAdmin`, sincronização com `authStore` e persistência local de sessão |
| Dashboard | Implementado | Métricas da plataforma, últimos logins, disciplinas ativas |
| Gestão de Disciplinas | Implementado | 4 UCs, autocomplete de professores com seleção por tags removíveis, persistência de docentes associados no backend e confirmação explícita na remoção |
| Gestão de Utilizadores | Implementado | 22 utilizadores (3 professores, 19 alunos), passwords ocultas na tabela, filtros, CRUD, toggle estado com confirmação em ações críticas |
| Aprovação de Contas Docentes | Implementado | Aba dedicada para rever pedidos de registo de professor (pendente/aprovado/rejeitado), aprovar/rejeitar com confirmação e transição de estado (`Suspended`→`Active` / `Deactivated`) |
| Pedidos Administrativos dos Docentes | Implementado | Inbox administrativo para aprovar/rejeitar pedidos não curriculares (acesso/plataforma/operações), com confirmação explícita de decisão |
| Fluxos Curriculares | Fora de Escopo (Admin) | Gestão de matéria curricular permanece no painel docente |

## 13. Tipos de Exercício Suportados
| Tipo | Código | Descrição | Interface Aluno | Interface Professor |
|---|---|---|---|---|
| Escolha Múltipla | `multipleChoice` | 4 opções, 1 correta | Botões de seleção com feedback colorido | Grid de opções editáveis |
| Verdadeiro/Falso | `trueFalse` | V ou F | Botões "Verdadeiro" / "Falso" | Opções V/F com solução |

Cada exercício inclui obrigatoriamente:
* **Solução** (`solution`): Resposta correta exibida após tentativa.
* **Explicação** (`explanation`): Justificação pedagógica detalhada, acessível via painel colapsável.
* **Tutor IA** (`"Pedir explicação ao Tutor IA"`): Botão que invoca o chatbot para explicações personalizadas.

## 14. Dependências do Projeto

### 14.1. Flutter (`aluno/pubspec.yaml`)
| Pacote | Versão | Finalidade |
|---|---|---|
| `flutter_riverpod` | ^2.5.1 | Gestão de estado reativa |
| `google_fonts` | ^6.2.1 | Tipografia Inter |
| `lottie` | ^3.1.0 | Animações Lottie |
| `go_router` | ^13.2.0 | Navegação declarativa |
| `dio` | ^5.4.1 | Cliente HTTP REST |
| `drift` | ^2.16.0 | ORM SQLite |
| `sqlite3_flutter_libs` | ^0.5.20 | Bibliotecas nativas SQLite |
| `path_provider` | ^2.1.2 | Diretórios do sistema |

### 14.2. Vue.js (`admin/` e `professor/`)
| Pacote | Versão | Finalidade |
|---|---|---|
| `vue` | ^3.5.25 | Framework reativo |
| `vue-router` | ^4.6.4 | Routing SPA |
| `pinia` | ^3.0.4 | Gestão de estado |
| `tailwindcss` | ^4.2.1 | Utility-first CSS |
| `vite` | ^7.3.1 | Bundler e dev server |
| `primeicons` | ^7.0.0 | Biblioteca de ícones |
| `vitest` | ^4.1.2 | Testes unitários/integrados dos stores web |

### 14.3. Backend Python (`backend/backend/app/requirements.txt`)
| Pacote | Versão | Finalidade |
|---|---|---|
| `fastapi` | 0.115.12 | Framework principal da API |
| `uvicorn` | 0.34.0 | Servidor ASGI para execução local |
| `sqlalchemy` | 2.0.40 | ORM para persistência relacional |
| `asyncpg` | 0.30.0 | Driver PostgreSQL assíncrono |
| `pydantic` | 2.11.2 | Validação de dados |
| `pydantic-settings` | 2.9.1 | Gestão de configuração por ambiente |
| `python-jose` | 3.4.0 | JWT para autenticação/autorização |
| `passlib` + `bcrypt` | 1.7.4 / 4.0.1 | Hashing de passwords |
| `python-multipart` | 0.0.20 | Upload multipart (materiais) |
| `email-validator` | 2.2.0 | Suporte a `EmailStr` nos schemas Pydantic |

### 14.3.1. Backend Testes/QA (`backend/backend/requirements-dev.txt`)
| Pacote | Versão | Finalidade |
|---|---|---|
| `pytest` | 8.3.5 | Runner de testes para smoke suite |
| `requests` | 2.32.3 | Cliente HTTP usado pelos smoke tests |

### 14.4. AI Engine (`ai_engine/requirements.txt`)
| Pacote | Versão | Finalidade |
|---|---|---|
| `torch` | Sem pinagem | Runtime local de modelos/embeddings |
| `streamlit` | Sem pinagem | UI local do chatbot |
| `langchain-community` | Sem pinagem | Loaders/utilitários LangChain |
| `langchain-text-splitters` | Sem pinagem | Chunking de documentos |
| `langchain-huggingface` | Sem pinagem | Embeddings HuggingFace |
| `langchain-chroma` | Sem pinagem | Vector store Chroma |
| `langchain-groq` | Sem pinagem | Cliente LLM Groq |
| `python-dotenv` | Sem pinagem | Carregamento de variáveis locais |
| `pymupdf` | Sem pinagem | Parsing de PDF |

**Nota de proveniência (IA):** neste branch, a fonte operacional de IA está na própria pasta `ai_engine/` (scripts `chatbot.py` e `ImportFiles.py`) e respetivo `requirements.txt`.

**Atualização de dependências (estado atual):** backend e IA com manifestos presentes; backend com versões fixadas, IA ainda sem pinagem estrita.

## 15. Operacionalização do Repositório (Setup)

### 15.1. Aplicação Aluno (Flutter)
```bash
cd aluno
flutter pub get
dart run build_runner build --delete-conflicting-outputs
flutter run
```

### 15.2. Painel Docente (Vue.js)
```bash
cd professor
npm install
npm run dev          # Disponível em http://localhost:5173 (strictPort)
```

### 15.3. Painel de Administração (Vue.js)
```bash
cd admin
npm install
npm run dev          # Disponível em http://localhost:5174 (strictPort)
```

### 15.4. Infraestrutura Local (`infrastructure/`)
```bash
cd infrastructure
cp .env.example .env
docker compose up -d
```

### 15.5. Backend FastAPI (`backend/`)
```bash
cd backend/backend
python -m venv .venv
# Windows PowerShell:
.venv\Scripts\Activate.ps1
pip install -r app/requirements.txt
copy app/.env.example app/.env
uvicorn app.main:app --reload --host 0.0.0.0 --port 8000
# Health checks: GET http://localhost:8000/  e  GET http://localhost:8000/health
```

*Nota:* o startup da API faz ping SQL (`SELECT 1`), por isso o PostgreSQL tem de estar ativo e acessível antes do `uvicorn`.

### 15.6. Motor IA (`ai_engine/`)
```bash
cd ai_engine
python -m venv .venv
# Windows PowerShell:
.venv\Scripts\Activate.ps1
pip install -r requirements.txt
# criar ficheiro keys.env com TOKEN_GEMMA e GROQ_API_KEY
python ImportFiles.py
python -m streamlit run chatbot.py
```

### 15.7. Scripts de Execução Rápida (PowerShell)
```powershell
.\script\run\run_aluno.ps1       # Reutiliza/lança emulador, valida ADB e corre flutter run no serial Android ativo
.\script\run\run_professor.ps1   # Inicia o painel docente (5173) com bootstrap local completo por defeito
.\script\run\run_admin.ps1       # Inicia o painel admin (5174) com bootstrap local completo por defeito
.\script\run\ensure_web_backend.ps1 # Garante API e precondicoes locais (env, venv, deps, schema, admin)
.\script\test\run_backend_smoke.ps1 # Arranca API local, aguarda /health, corre smoke tests e encerra o servidor
.\script\test\run_web_store_tests.ps1 # Executa testes Vitest dos stores Admin + Professor
.\script\test\run_web_e2e_tests.ps1 # Executa fluxo browser E2E Admin + Professor (Playwright)
.\script\test\run_admin_auth_check.ps1 # Valida login admin real e role devolvida por /auth/me
.\script\test\run_database_sql_tests.ps1 # Executa scripts SQL de validacao em script/test/sql
.\script\test\run_aluno_widget_tests.ps1 # Executa widget tests Flutter do modulo aluno
.\script\test\run_all_tests.ps1 # Executa suite agregada (backend smoke + web stores + web E2E + SQL + Flutter)
.\script\test\clean_test_artifacts.ps1 # Limpa artefactos de testes/build antes de commit
.\script\test\run_release_validation.ps1 -SqlPass <password> # Valida (admin/professor/backend/sql) e limpa no fim
.\script\test\run_release_validation.ps1 -IncludeAluno -SqlPass <password> # Valida escopo completo (inclui Flutter) e limpa no fim
```

Variáveis de ambiente opcionais para bootstrap local web:
* `PECI_ADMIN_EMAIL` (default: `admin@ua.pt`)
* `PECI_ADMIN_PASSWORD` (default: `admin123`)
* `PECI_ADMIN_NAME` (default: `Admin Local`)
* `PECI_ADMIN_RESET_PASSWORD=1` (força atualização da password da conta admin bootstrap)

Flags úteis nos scripts web:
* `-SkipInfra` (não tenta Docker Compose)
* `-SkipBootstrapData` (não executa bootstrap de schema/admin)
* `-SkipBackendBootstrap` (inicia só o frontend)

### 15.8. Requisitos
* Flutter SDK >= 3.27
* Node.js >= 18
* npm >= 9
* Python >= 3.11
* PostgreSQL >= 14 (local nativo) **ou** Docker com PostgreSQL via Compose
* Android SDK Platform-Tools (`adb`) disponível no PATH
* Docker Desktop com Docker Compose v2 (opcional quando PostgreSQL é local)

## 16. Matriz de Ownership Técnica (Quem Trabalha Onde)

### 16.1. Equipa Frontend Aluno (Flutter)
**Âmbito:** UX mobile, gamificação, fluxo de estudo, autenticação mobile e integração REST com backend.

**Trabalhar em:**
* `aluno/lib/presentation/**`
* `aluno/lib/features/**`
* `aluno/lib/core/router/**`
* `aluno/lib/core/theme/**`
* `aluno/lib/data/**` (incluindo adapters de API)

**Evitar alterar diretamente:**
* `backend/**`
* `ai_engine/**`
* `infrastructure/**`

### 16.2. Equipa Frontend Professor/Admin (Vue)
**Âmbito:** painéis web, UX administrativa, operações docentes e integração com API Gateway.

**Trabalhar em:**
* `professor/src/**`
* `admin/src/**`
* `professor/package.json`, `admin/package.json`
* `professor/vite.config.js`, `admin/vite.config.js`

**Evitar alterar diretamente:**
* `backend/database/**` (esquema/migrações)
* `ai_engine/**` (pipeline RAG)

### 16.3. Equipa Backend API (FastAPI)
**Âmbito:** contrato BFF, endpoints, serialização de payloads e integração backend <-> IA.

**Trabalhar em:**
* `backend/backend/app/main.py`
* `backend/backend/app/routers/**`
* `backend/backend/app/schemas/**`
* `backend/backend/app/models/**`
* `backend/backend/app/database.py`

**Interfaces que esta equipa mantém estáveis:**
* Contratos já expostos no branch: `POST /api/v1/auth/register`, `POST /api/v1/auth/login`, `GET /api/v1/auth/me`, `GET /api/v1/academic/exercises`, `GET /api/v1/academic/course-units`.
* Endpoints de gestão de domínio também disponíveis em `/api/v1/admin`, `/api/v1/professors` e `/api/v1/students`.
* `POST /api/v1/ai-tutor/query` está publicado, mas devolve `501` até à integração backend↔RAG.

### 16.4. Equipa Base de Dados (SQL)
**Âmbito:** modelação relacional, evolução de schema SQL e manutenção de scripts de validação/reset.

**Trabalhar em:**
* `backend/database/schema.sql`
* `backend/database/indexes.sql`
* `script/test/sql/**`
* `backend/database/deletes/**`
* `infrastructure/postgres/init/**`

**Nota de estado:** neste branch os modelos ORM já existem, mas a camada de migrações Alembic ainda não está ativa; a evolução do esquema continua ancorada em scripts SQL versionados.

### 16.5. Equipa IA (RAG + ChromaDB)
**Âmbito:** ingestão documental, chunking, retrieval, geração de respostas e geração de exercícios.

**Trabalhar em:**
* `ai_engine/ImportFiles.py`
* `ai_engine/chatbot.py`
* `ai_engine/requirements.txt`

**Contrato com backend:**
* saída previsível para respostas do tutor (`answer`, `references`)
* geração de exercícios normalizável para DTO do frontend

### 16.6. Equipa Infraestrutura/DevOps Local
**Âmbito:** ambiente local reproduzível, serviços de suporte e healthchecks.

**Trabalhar em:**
* `infrastructure/docker-compose.yml`
* `infrastructure/.env.example`
* `infrastructure/postgres/init/**`
* `infrastructure/chromadb/.gitkeep`

**Objetivo principal:** garantir paridade mínima entre ambientes dos membros da equipa (mesmas portas, credenciais e ordem de bootstrap).

## 17. Fluxos de Dados Detalhados (Backend + IA)

### 17.1. Fluxo de Ingestão Documental
1. O operador executa `ai_engine/ImportFiles.py` localmente.
2. O script lê PDFs da pasta `ai_engine/biblio/` conforme a lista interna `biblioteca`.
3. O texto é fragmentado (`RecursiveCharacterTextSplitter`) e indexado no Chroma.
4. Os metadados (`uc_id`, `ficheiro_id`, página, nome do ficheiro) ficam guardados na coleção.

### 17.2. Fluxo de Geração de Exercícios
1. A API FastAPI arranca via `app.main` e expõe `GET /` e `GET /health`.
2. O catálogo pode ser consumido pelos endpoints académicos (`GET /api/v1/academic/course-units`, `GET /api/v1/academic/exercises`) e pelo domínio estudante (`GET /api/v1/students/exercises`).
3. O frontend móvel ainda mantém consumo principal em dados locais de bootstrap, com transição gradual para API.

### 17.3. Fluxo do Tutor IA
1. O utilizador interage com o chat do Streamlit em `ai_engine/chatbot.py`.
2. O script prepara a pergunta, expande termos técnicos e consulta Chroma com MMR.
3. A resposta é gerada via Groq (`ChatGroq`) com contexto recuperado.
4. A UI exibe resposta e fontes, sem passar pelo API Gateway.

### 17.4. Fluxo de Persistência Relacional e Publicação
1. A persistência relacional está centrada nos scripts SQL em `backend/database/`.
2. Inserção/limpeza/validação são feitas por scripts de teste em `script/test/sql/*.sql` e operações SQL diretas.
3. Para execução local dos smoke tests com ORM, existe bootstrap dedicado em `script/backend/local_schema_orm_compatible.sql`.
4. Os modelos ORM já estão implementados no backend, mas ainda não há fluxo de migrações/publicação automatizada ativo neste snapshot.

### 17.6. Fluxo de Validação Local da API (Smoke E2E)
1. O operador executa `./script/test/run_backend_smoke.ps1` na raiz do monorepo.
2. O script valida o `BaseUrl`; quando a porta local pedida já está ocupada, seleciona automaticamente uma porta livre para arrancar `uvicorn app.main:app` e manter isolamento determinístico.
3. O runner aguarda `GET /health` no endpoint efetivo e injeta `SMOKE_BASE_URL` alinhado com a porta realmente usada.
4. A suíte em `backend/backend/tests/smoke/test_api_smoke.py` valida domínios auth/academic/students/professors/admin e o stub IA.
5. Sem credenciais admin explícitas, a suíte cria automaticamente uma conta admin local temporária para cobrir endpoints administrativos.
6. No final, o processo do servidor é encerrado automaticamente, preservando execução local determinística.

### 17.11. Fluxo de Validação dos Stores Web (Admin/Professor)
1. O operador executa `./script/test/run_web_store_tests.ps1` na raiz do monorepo.
2. O runner entra em `admin/` e `professor/` e executa `npm run test:run` (Vitest) em cada painel.
3. A suíte valida stores API-backed (auth, users, disciplines, requests) e stores locais/simuladas (question lab, exercise/path) com mocks de `fetch`, storage e timers.
4. O fluxo garante que decisões de sessão (`remember`), serialização de pedidos administrativos (`[type]`) e mutações transacionais de estado permanecem consistentes sem dependência da UI.

### 17.12. Fluxo de Validação Browser E2E (Admin/Professor)
1. O operador executa `./script/test/run_web_e2e_tests.ps1` na raiz do monorepo.
2. O runner garante backend local saudável em URL dedicada para E2E (`-BackendBaseUrl`, default `http://127.0.0.1:8010`) via `script/run/ensure_web_backend.ps1`; no runner agregado (`run_all_tests.ps1`) a execução E2E usa por defeito `http://127.0.0.1:8012` para reduzir colisões com instâncias locais pré-existentes.
3. O runner arranca Vite dos painéis admin/professor em modo determinístico (reinicia listeners prévios em `5174` e `5173`) e injeta `VITE_API_BASE_URL` para apontar ao backend E2E.
4. A suíte Playwright (`script/test/e2e/tests/admin-professor-flows.spec.js`) valida fluxos críticos fim-a-fim: registo docente pendente, aprovação admin e desbloqueio de login, pedido administrativo com decisão do admin, e CRUD de UC com atribuição persistida de docente.
5. No fim da execução, os servidores frontend iniciados pelo runner são terminados automaticamente para evitar deriva de estado local.

### 17.7. Fluxo de Autenticação Web via FastAPI (Fase 1 de Integração)
1. No registo de docente (`POST /api/v1/auth/register` com role `Professor`), a conta é criada em `Suspended` e é aberto automaticamente um pedido administrativo de acesso (`request_type=access`, `status=pending`).
2. Enquanto o pedido estiver pendente, tentativas de login do docente devolvem `403` com detalhe `Account pending admin approval`.
3. O admin decide o pedido em `PATCH /api/v1/admin/requests/{id}/decision`; ao aprovar, a conta passa para `Active`; ao rejeitar, para `Deactivated`.
4. Após aprovação, o `authStore` docente invoca `POST /api/v1/auth/login` para obtenção do `access_token` JWT e valida sessão/role com `GET /api/v1/auth/me`.
5. O token e o perfil validado são persistidos no browser sem guardar password: `localStorage` quando "Lembrar-me" está ativo, `sessionStorage` quando desativado.
6. No arranque de cada painel, a sessão persistida é revalidada no backend; em falha, a sessão local é limpa e o utilizador regressa ao login.

### 17.10. Onde Ficam Email e Password (Admin)
1. O email e a password são enviados pelo frontend apenas no pedido `POST /api/v1/auth/login`.
2. A password **não** é guardada no browser (nem em `localStorage` nem em `sessionStorage`).
3. Na base de dados, a password fica guardada como hash em `base_user.Password_Hash` (não em texto simples).
4. O browser guarda apenas sessão (token JWT + perfil), para manter login entre refreshs.
5. Para validação operacional rápida do fluxo, usar `./script/test/run_admin_auth_check.ps1`.

### 17.8. Fluxo de Gestão Web de Domínio via FastAPI (Fase 2 Incremental)
1. No painel admin, as vistas de Utilizadores, UCs e Pedidos carregam estado inicial diretamente do backend com token JWT.
2. Operações de mutação no painel admin deixam de alterar apenas estado local e passam a persistir no backend (`PATCH/DELETE` de utilizadores, `POST/PATCH/DELETE` de UCs, `PATCH` de decisão de pedidos).
3. Criação de contas de aluno/docente no admin passa por `POST /api/v1/auth/register`, seguida de sincronização da lista de utilizadores via `GET /api/v1/admin/users`.
    * Registos de docente por este endpoint entram em fluxo de aprovação (`Suspended` + pedido `access`) antes de login no painel docente.
4. No painel professor, pedidos ao admin são listados e criados por `GET/POST /api/v1/professors/requests`, com estado refletido conforme decisão administrativa.
5. A criação de pedido no professor envia `request_type` explícito no payload (`access`, `platform`, `operations`, `other`), conforme contrato atual do backend; parsing de prefixo no título é mantido apenas para retrocompatibilidade de registos legados.

### 17.9. Fluxo de Bootstrap Local Reproduzível (Admin/Professor)
1. O operador executa `./script/run/run_admin.ps1` ou `./script/run/run_professor.ps1` na raiz.
2. O script delega em `script/run/ensure_web_backend.ps1`, que verifica `/health`; se já estiver saudável, reutiliza backend existente.
3. Se necessário, o bootstrap prepara `infrastructure/.env` (quando ausente), prepara `backend/backend/app/.env` com credenciais locais e cria `.venv` na raiz.
4. Dependências Python do backend são verificadas e instaladas automaticamente se estiverem em falta.
5. O bootstrap idempotente (`script/backend/bootstrap_local_stack.py`) executa `create_all` do ORM e garante uma conta admin local.
6. Só depois do backend saudável é que o Vite arranca em porta fixa (`5173` professor, `5174` admin), reduzindo falhas por dependências não preparadas.

### 17.5. Fluxo de Preservação de Fontes Legadas (Sem Impacto em Runtime)
1. O repositório mantém referência documental a fontes legadas remotas.
2. Neste branch não existe diretoria `archive/` na raiz para preservação local 1:1.
3. O runtime observado usa apenas `aluno/`, `admin/`, `professor/`, `backend/`, `ai_engine/` e `infrastructure/`.

## 18. Transição de Estado das Funcionalidades (Impacto da Integração)

| Domínio | Estado Anterior | Estado Atual | Próxima Etapa |
|---|---|---|---|
| Frontends | Protótipos isolados por aplicação | Frontends funcionais com UI consolidada; web com autenticação real + persistência de domínio em Utilizadores/UCs/Pedidos (admin/professor), com sessão browser controlada por "Lembrar-me"; mobile ainda com bootstrap local | concluir integração de restantes domínios web e iniciar integração auth/dados no Flutter |
| Backend API | Planeado/externo ao monorepo | App FastAPI operacional em `backend/backend/app/`, com ORM + schemas + routers implementados (auth/admin/professors/students/academic), endpoint IA em stub e smoke suite local automatizada | ligar frontends aos endpoints reais e concluir bridge `ai-tutor` |
| Base de Dados | Modelo conceptual | Scripts SQL consolidados em `backend/database/`, bootstrap infra em `infrastructure/` e bootstrap ORM-local em `script/backend/local_schema_orm_compatible.sql` | convergir para migrações/versionamento de schema único |
| Motor IA | Conceito RAG separado | Scripts locais ativos (`ImportFiles.py`, `chatbot.py`) com Chroma | encapsular em serviço integrável com backend |
| Infra local | Dependência manual por membro | `docker-compose.yml` versionado + bootstrap web automatizado por `ensure_web_backend.ps1` (env, venv, deps, schema, admin, healthcheck) | consolidar script único para subir ambos os painéis web em paralelo |
| Turmas/Quizzes (Aluno + Professor) | Fluxos de protótipo ativos com rotas/stores/views dedicadas | Domínio fora da navegação principal; diretórios legados residuais no Flutter | reintroduzir apenas com requisito explícito |
| Arquivo legado | Referências dispersas entre branches e pastas locais | Referência documental mantida, sem pasta `archive/` neste snapshot | decidir política de preservação no próprio repo |
| Proveniência IA legada | Ambiguidade sobre conteúdo da branch | Clarificada no README: `origin/01-IA` mínima e IA ativa em `ai_engine/` local | convergir para módulo de serviço único |

## 19. Validação de Integridade Transversal (Checklist Operacional)

### 19.1. Coerência de Dependências
* IA possui `requirements.txt` explícito (`ai_engine/requirements.txt`).
* Backend possui `requirements.txt` explícito (`backend/backend/app/requirements.txt`).
* Backend possui dependências de QA em `backend/backend/requirements-dev.txt`.
* `infrastructure/.env.example` e `backend/backend/app/.env.example` existem.
* Bootstrap local backend/admin existe em `script/backend/bootstrap_local_stack.py`.
* Infra local centralizada em `infrastructure/docker-compose.yml`.

### 19.2. Consistência de Contratos
* Routers backend implementados em `backend/backend/app/routers/` para auth, admin, professors, students e academic.
* O backend expõe `GET /` e `GET /health` para verificação de saúde.
* Contratos versionados disponíveis sob prefixo `/api/v1/*` com autenticação JWT (`Bearer`) nas rotas protegidas.
* CORS backend configurado para origens web locais dos painéis (`5173` e `5174`) para permitir consumo browser dos endpoints autenticados.
* Fluxos web de domínio já validados contra backend nos painéis: `admin/users`, `admin/course-units`, `admin/requests` e `professors/requests`.
* Registo de docente via `POST /api/v1/auth/register` cria pedido de acesso pendente e bloqueia login até decisão administrativa (`PATCH /api/v1/admin/requests/{id}/decision`).
* `POST /api/v1/professors/requests` requer `request_type` e mantém semântica de domínio (`access|platform|operations|other`) alinhada com os enums do backend.
* A codificação `[type]` no `title` permanece apenas como fallback de leitura para pedidos legados sem `request_type` persistido.
* `POST /api/v1/ai-tutor/query` mantém estado de stub (resposta `501`) até integração com RAG.
* A documentação local do backend está em `backend/README.md`.
* Contratos API documentados nesta raiz representam estado implementado parcial + roadmap de integração frontend.

### 19.3. Verificação Técnica Recomendada por Iteração
1. Verificar presença de ficheiros críticos (manifestos, entrypoints, templates de ambiente).
2. Validar consistência estrutural de paths documentados versus paths reais.
3. Validar `docker compose config` quando o Docker CLI estiver disponível.
4. Executar `.\script\run\ensure_web_backend.ps1` para validar bootstrap local reproduzível antes de abrir os painéis web.
5. Executar testes locais via `script/test` (ex.: `.\script\test\run_backend_smoke.ps1`, `.\script\test\run_web_store_tests.ps1` e `.\script\test\run_all_tests.ps1`) antes de promover mudanças de contrato API.
6. Para preparação de publicação limpa, executar `.\script\test\run_release_validation.ps1 -SqlPass <password>` (validação + limpeza automática de artefactos).
7. Executar build dos frontends alterados (`admin/`, `professor/`) após mudanças de integração cliente↔API.
8. Executar builds/analyzers apenas em pipelines dedicadas para evitar artefactos locais fora de controlo.

### 19.4. Estado Global Atual (Março 2026)
* Estrutura frontend, IA local e infra integrada no monorepo.
* Verificação estática executada neste update confirmou:
    * `backend/backend/app/requirements.txt`: presente
    * `backend/backend/requirements-dev.txt`: presente
    * `backend/backend/app/.env.example`: presente
    * `backend/alembic.ini`: ausente
    * `backend/backend/app/main.py`: presente (bootstrap FastAPI + `GET /` + `GET /health`)
    * `backend/backend/app/models/*.py`: presentes e implementados
    * `backend/backend/app/routers/*.py`: presentes e implementados por domínio
    * `backend/backend/app/schemas/{user,academic,gamification,admin}.py`: presentes e implementados
    * `backend/backend/tests/smoke/test_api_smoke.py`: presente
    * `script/backend/local_schema_orm_compatible.sql`: presente
    * `script/backend/bootstrap_local_stack.py`: presente
    * `ai_engine/requirements.txt`, `ai_engine/chatbot.py`, `ai_engine/ImportFiles.py`: presentes
    * `infrastructure/.env.example`, `infrastructure/docker-compose.yml`: presentes
* `docker compose config` não executado no ambiente atual por ausência de Docker CLI (`docker-cli-missing`).
* Validação funcional local do bootstrap web executada com `.\script\run\ensure_web_backend.ps1`: backend ficou saudável e conta admin local foi garantida.
* Validação funcional local backend/API executada com `pytest tests/smoke -q` em `backend/backend`: `35 passed`.
* Validação funcional local dos stores web executada com `./script/test/run_web_store_tests.ps1`: `25 passed` (Admin `14`, Professor `11`).
* Validação funcional local browser E2E executada com `./script/test/run_web_e2e_tests.ps1`: `2 passed` (fluxos críticos Admin + Professor com backend real).
* Validação funcional local SQL executada com `./script/test/run_database_sql_tests.ps1 -DbPass <password>`: `test_inserts.sql`, `test_admin_professor_integrity.sql` e `useful_selects.sql` concluídos com fixtures alinhados aos enums ativos (`*_enum`, labels em uppercase) e `request_type` obrigatório.
* Validação transversal agregada executada com `./script/test/run_all_tests.ps1 -SqlPass <password>`: backend smoke `35 passed`, web stores `25 passed`, web E2E `2 passed`, SQL concluído e Flutter widget tests `4 passed`.
* Validação de release executada com `./script/test/run_release_validation.ps1 -IncludeAluno -SqlPass <password>`: backend smoke `35 passed`, web stores `25 passed`, web E2E `2 passed`, SQL concluído, Flutter widget tests `4 passed` e limpeza automática de artefactos aplicada no fim.
* Higiene de publicação reforçada com `.gitignore` na raiz + `./script/test/clean_test_artifacts.ps1` para remover `dist`, caches e `__pycache__` antes de commit/push (logs temporários `%TEMP%` preservados por defeito no runner de release).
* Validação de frontends alterados executada com sucesso: `npm run build` em `admin/` e `professor/`.
* Hardening backend aplicado no ciclo atual: migração para `SettingsConfigDict` (Pydantic v2) e anotações `overlaps` nas relações SQLAlchemy sobre `exercise.ID_UC`, eliminando warnings ruidosos no smoke.
* Fase 2 incremental de integração web concluída: gestão de Utilizadores, UCs e Pedidos (admin/professor) ligada ao backend com persistência efetiva.
* A maturidade atual permanece assimétrica: web já integrado em auth + domínios administrativos prioritários; mobile e módulos IA/API ainda em evolução.