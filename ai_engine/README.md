# Peci_Project

## Instalação

1. Criar e ativar ambiente virtual:

```powershell
python -m venv .venv
.\.venv\Scripts\Activate.ps1
```

2. Instalar dependências:

```powershell
pip install -r requirements.txt
```

3. Configurar chaves no ficheiro `keys.env`:

```env
TOKEN_GEMMA=...
GROQ_API_KEY=...
```

## Como correr

### 1) Indexar PDFs

```powershell
python ImportFiles.py
```

### 2) Iniciar o chatbot (Streamlit)

```powershell
python3 -m streamlit run chatbot.py
```
