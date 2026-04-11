# Setup da Coluna Published para Exercícios

## O que foi feito:

✅ **Backend completamente configurado:**
- ✅ Schema SQL atualizado com coluna `Published`
- ✅ Modelo SQLAlchemy atualizado
- ✅ Schema Pydantic (ExerciseResponse) atualizado com campo `published`
- ✅ Novo endpoint: `PUT /api/v1/professors/exercises/{exercise_id}?published=true|false`

## O que falta:

Para completar a implementação, precisa executar este script SQL na base de dados:

### Opção 1: Via pgAdmin (mais fácil)

1. Abra o pgAdmin (geralmente `http://localhost:5050`)
2. Navegue até: **Servidores > PostgreSQL > Bases de dados > peci_db**
3. Clique em **Query Tool** (ícone SQL)
4. Cole o conteúdo do arquivo: `SETUP_PUBLISHED_COLUMN.sql`
5. Execute o script (Ctrl+Enter ou botão Run)

### Opção 2: Via psql (linha de comando)

```bash
psql -U postgres -h localhost -d peci_db -f SETUP_PUBLISHED_COLUMN.sql
```

### Opção 3: Via DBeaver (se tiver instalado)

1. Conecte-se ao PostgreSQL
2. Abra uma nova SQL Script
3. Cole o conteúdo de `SETUP_PUBLISHED_COLUMN.sql`
4. Execute (Ctrl+Enter)

---

## Após executar o script:

1. ✅ Recarregue o navegador (F5)
2. ✅ Vá para **Exercícios**
3. ✅ Clique em **Publicador** (ou ação correspondente)
4. ✅ Agora funciona sem "Not Found"!

---

## Novo endpoint disponível:

```
PUT /api/v1/professors/exercises/{exercise_id}?published=true
PUT /api/v1/professors/exercises/{exercise_id}?published=false
```

Exemplo com curl:
```bash
curl -X PUT "http://localhost:8000/api/v1/professors/exercises/12345678-1234-1234-1234-123456789012?published=true" \
  -H "Authorization: Bearer <seu_token>"
```

---

**Dúvidas?** Deixa-me saber! 🚀
