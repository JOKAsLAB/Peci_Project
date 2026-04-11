-- Script para adicionar coluna Published à tabela Exercise
-- Execute isto na PostgreSQL shell com o utilizador proprietário da tabela

ALTER TABLE exercise
ADD COLUMN published BOOLEAN NOT NULL DEFAULT false;

-- Verificar
SELECT column_name, data_type FROM information_schema.columns 
WHERE table_name='exercise' AND column_name='published';
