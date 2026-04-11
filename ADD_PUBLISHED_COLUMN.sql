-- ============================================
-- SCRIPT: Adicionar coluna 'published' à tabela 'exercise'
-- ============================================
-- 
-- Esta coluna é necessária para suportar a funcionalidade de 
-- publicar/despublicar exercícios no Path Builder.
--
-- EXECUÇÃO:
-- 1. Abrir DBeaver/pgAdmin como admin (utilisador 'postgres')
-- 2. Copiar este conteúdo
-- 3. Executar na DB 'peci_db'
--
-- ============================================

-- Passo 1: Transferir propriedade da tabela (se necessário)
-- ALTER TABLE exercise OWNER TO peci;

-- Passo 2: Adicionar coluna
ALTER TABLE exercise
ADD COLUMN published BOOLEAN NOT NULL DEFAULT false;

-- Passo 3: Verificação
-- SELECT column_name, data_type FROM information_schema.columns 
-- WHERE table_name = 'exercise' ORDER BY ordinal_position;

-- ============================================
-- FIM DO SCRIPT
-- ============================================
