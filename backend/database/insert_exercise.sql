-- Criar Tópico (sem ON CONFLICT por causa do DEFERRABLE)
DELETE FROM Topic WHERE ID_UC = 1001 AND Name = 'Portas Logicas';
INSERT INTO Topic (ID_UC, Name, N_Order)
VALUES (1001, 'Portas Logicas', 1);

-- Criar Exercício
INSERT INTO Exercise (ID_UC, Topic_Name, Type, Question, Solution, Difficulty, Explanation)
VALUES (
  1001,
  'Portas Logicas',
  'Multiple Choice',
  'Qual eh a saida de uma porta AND com entradas (1, 0)?',
  '{"correct": "A", "options": {"A": "0", "B": "1", "C": "Indefinido", "D": "1 ou 0"}}',
  'Easy',
  'Uma porta AND retorna 1 apenas quando ambas as entradas sao 1.'
);

-- Verificar dados finais
SELECT '=== DADOS DE TESTE CRIADOS COM SUCESSO ===' as status;
SELECT (SELECT COUNT(*) FROM Course_Unit) as total_disciplinas,
       (SELECT COUNT(*) FROM Professor) as total_professores,
       (SELECT COUNT(*) FROM Student) as total_estudantes,
       (SELECT COUNT(*) FROM Topic) as total_topicos,
       (SELECT COUNT(*) FROM Exercise) as total_exercicios;
