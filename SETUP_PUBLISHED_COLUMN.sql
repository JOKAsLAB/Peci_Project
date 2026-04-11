-- ============================================================
-- IMPORTANTE: Correr este script no pgAdmin ou psql como SUPER-USER (postgres)
-- Para resolver o erro: "must be owner of table exercise"
-- ============================================================

-- 1. Transferir propriedade da tabela para o utilizador peci
ALTER TABLE exercise OWNER TO peci;

-- 2. Adicionar a coluna published
ALTER TABLE exercise
ADD COLUMN IF NOT EXISTS published BOOLEAN NOT NULL DEFAULT false;

-- 3. Verificar se funcionou
SELECT column_name, data_type 
FROM information_schema.columns 
WHERE table_name='exercise' AND column_name='published';

-- Se a query acima retornar uma linha com (published, boolean), está pronto!
-- Agora podes fazer reload da aplicação e o botão de publicar vai funcionar.
