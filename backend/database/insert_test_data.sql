-- Criar Estudante 2
INSERT INTO Base_User (Name, Email, Password_Hash, Role, Status) 
VALUES ('Estudante Dois', 'estudante2@ua.pt', '$2b$12$abcdefgh123456', 'Student', 'Active')
ON CONFLICT DO NOTHING;

INSERT INTO Student (ID_Student, Current_Level, Total_XP, Streak_Days)
SELECT ID_User, 1, 0, 0 FROM Base_User WHERE Email = 'estudante2@ua.pt'
ON CONFLICT DO NOTHING;

INSERT INTO Student_UC (ID_Student, ID_UC)
SELECT s.ID_User, 1001 FROM Base_User s WHERE s.Email = 'estudante2@ua.pt'
ON CONFLICT DO NOTHING;

-- Criar Estudante 3
INSERT INTO Base_User (Name, Email, Password_Hash, Role, Status) 
VALUES ('Estudante Tres', 'estudante3@ua.pt', '$2b$12$abcdefgh123456', 'Student', 'Active')
ON CONFLICT DO NOTHING;

INSERT INTO Student (ID_Student, Current_Level, Total_XP, Streak_Days)
SELECT ID_User, 1, 0, 0 FROM Base_User WHERE Email = 'estudante3@ua.pt'
ON CONFLICT DO NOTHING;

INSERT INTO Student_UC (ID_Student, ID_UC)
SELECT s.ID_User, 1001 FROM Base_User s WHERE s.Email = 'estudante3@ua.pt'
ON CONFLICT DO NOTHING;

-- Criar Tópico
INSERT INTO Topic (ID_UC, Name, N_Order)
VALUES (1001, 'Portas Lógicas', 1)
ON CONFLICT DO NOTHING;

-- Criar Exercício
INSERT INTO Exercise (ID_UC, Topic_Name, Type, Question, Solution, Difficulty, Explanation)
VALUES (
  1001,
  'Portas Lógicas',
  'Multiple Choice',
  'Qual é a saída de uma porta AND com entradas (1, 0)?',
  '{"correct": "A", "options": {"A": "0", "B": "1", "C": "Indefinido", "D": "1 ou 0"}}',
  'Easy',
  'Uma porta AND retorna 1 apenas quando ambas as entradas são 1. Como uma entrada é 0, o resultado é 0.'
)
ON CONFLICT DO NOTHING;

-- Verificar dados
SELECT COUNT(*) as "Total Estudantes" FROM Student;
SELECT COUNT(*) as "Total Exercícios" FROM Exercise;
SELECT COUNT(*) as "Total Disciplinas" FROM Course_Unit;
