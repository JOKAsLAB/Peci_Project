-- 1. Limpeza total (Cuidado: isto apaga exercícios e progresso associados!)
TRUNCATE TABLE Topic CASCADE;

-- 2. Inserção dos Tópicos por UC
INSERT INTO Topic (ID_UC, Name, N_Order) VALUES
-- UC 40332: Introdução aos Sistemas Digitais
(40332, 'Introdução aos sistemas digitais', 1),
(40332, 'Representação e codificação de informação', 2),
(40332, 'Álgebra de Boole', 3),
(40332, 'Lógica combinatória elementar', 4),
(40332, 'Blocos combinatórios', 5),
(40332, 'Circuitos aritméticos', 6),
(40332, 'Sistemas sequenciais', 7),
(40332, 'Estratégias de análise de circuitos sequenciais', 8),
(40332, 'Blocos sequenciais fundamentais', 9),
(40332, 'Síntese de máquinas de estado', 10),

-- UC 40333: Laboratório de Sistemas Digitais
(40333, 'Introdução às FPGAs, ferramentas e kits de desenvolvimento', 1),
(40333, 'Modelação em VHDL: Componentes combinatórios e aritméticos', 2),
(40333, 'Modelação em VHDL: Circuitos sequenciais, registos e memórias', 3),
(40333, 'Máquinas de Estados Finitos (FSM) em VHDL', 4),
(40333, 'Testbenches e estratégias de depuração de circuitos', 5),
(40333, 'Precauções de projeto: Reset, sincronização e restrições temporais', 6),

-- UC 42545: Arquitetura de Computadores
(42545, 'Organização funcional e programação em assembly', 1),
(42545, 'Tradução de linguagens de alto nível e assemblagem', 2),
(42545, 'Aritmética de vírgula fixa e flutuante', 3),
(42545, 'Estrutura interna do processador e etapas de execução', 4),
(42545, 'Arquitecturas de processadores com pipeline', 5),

-- UC 42548: (Sistema de E/S e Memória)
(42548, 'Organização básica do sistema de entradas/saídas', 1),
(42548, 'Dispositivos periféricos', 2),
(42548, 'Organização de barramentos de dados', 3),
(42548, 'Interfaces e barramentos paralelos e série', 4),
(42548, 'Software para gestão de dispositivos de E/S', 5),
(42548, 'Sistema de memória e análise de memória cache', 6);