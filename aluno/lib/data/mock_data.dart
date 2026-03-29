// Modelos de dados mock para o MVP.

class Course {
  final String id;
  final String name;
  final String shortName;
  final int totalChapters;
  final int completedChapters;
  final List<Chapter> chapters;
  final bool enrolled;

  const Course({
    required this.id,
    required this.name,
    required this.shortName,
    required this.totalChapters,
    required this.completedChapters,
    required this.chapters,
    this.enrolled = false,
  });

  double get progress =>
      totalChapters > 0 ? completedChapters / totalChapters : 0;
}

class Chapter {
  final String id;
  final String courseId;
  final String title;
  final String description;
  final ChapterStatus status;
  final int totalExercises;
  final int completedExercises;
  final int xpReward;

  const Chapter({
    required this.id,
    required this.courseId,
    required this.title,
    required this.description,
    required this.status,
    required this.totalExercises,
    required this.completedExercises,
    required this.xpReward,
  });
}

enum ChapterStatus { locked, available, inProgress, completed }

enum ExerciseType { multipleChoice, trueFalse }

enum ExerciseDifficulty { facil, medio, dificil }

class MockExercise {
  final String id;
  final String courseId;
  final String chapterId;
  final String courseName;
  final String chapterName;
  final String question;
  final ExerciseType type;
  final ExerciseDifficulty difficulty;
  final List<String> options;
  final int correctIndex;
  final String solution;
  final String explanation;

  const MockExercise({
    required this.id,
    required this.courseId,
    required this.chapterId,
    required this.courseName,
    required this.chapterName,
    required this.question,
    this.type = ExerciseType.multipleChoice,
    this.difficulty = ExerciseDifficulty.medio,
    this.options = const [],
    this.correctIndex = 0,
    this.solution = '',
    this.explanation = '',
  });
}

// --- Dados Mock ---------------------------------------------------------------
// Alinhados com o pathStore.js do painel do professor (percurso base)

const List<Course> mockCourses = [
  Course(
    id: 'sd',
    name: 'Sistemas Digitais',
    shortName: 'SD',
    totalChapters: 5,
    completedChapters: 2,
    enrolled: true,
    chapters: [
      Chapter(
        id: 'sd_m1', courseId: 'sd',
        title: 'Sistemas de Numeracao e Codigos',
        description: 'Conversao entre bases numericas, codigo BCD, Gray e complementos.',
        status: ChapterStatus.completed, totalExercises: 4, completedExercises: 4, xpReward: 50,
      ),
      Chapter(
        id: 'sd_m2', courseId: 'sd',
        title: 'Algebra de Boole e Simplificacao',
        description: 'Teoremas de De Morgan, mapas de Karnaugh e simplificacao de expressoes.',
        status: ChapterStatus.completed, totalExercises: 3, completedExercises: 3, xpReward: 75,
      ),
      Chapter(
        id: 'sd_m3', courseId: 'sd',
        title: 'Circuitos Combinatorios',
        description: 'Multiplexadores, descodificadores, somadores e comparadores.',
        status: ChapterStatus.inProgress, totalExercises: 2, completedExercises: 1, xpReward: 100,
      ),
      Chapter(
        id: 'sd_m4', courseId: 'sd',
        title: 'Circuitos Sequenciais',
        description: 'Flip-flops (SR, JK, D, T), registos de deslocamento e contadores.',
        status: ChapterStatus.available, totalExercises: 2, completedExercises: 0, xpReward: 100,
      ),
      Chapter(
        id: 'sd_m5', courseId: 'sd',
        title: 'Maquinas de Estado',
        description: 'Modelos de Moore e Mealy, diagramas de transicao e implementacao.',
        status: ChapterStatus.locked, totalExercises: 1, completedExercises: 0, xpReward: 125,
      ),
    ],
  ),
  Course(
    id: 'ac',
    name: 'Arquitetura de Computadores',
    shortName: 'AC',
    totalChapters: 4,
    completedChapters: 0,
    enrolled: true,
    chapters: [
      Chapter(
        id: 'ac_m1', courseId: 'ac',
        title: 'Datapaths MIPS',
        description: 'Componentes do datapath, ALU, registos e memoria.',
        status: ChapterStatus.available, totalExercises: 2, completedExercises: 0, xpReward: 75,
      ),
      Chapter(
        id: 'ac_m2', courseId: 'ac',
        title: 'Conjunto de Instrucoes',
        description: 'Tipos de instrucao (R, I, J), enderecamento e codificacao.',
        status: ChapterStatus.locked, totalExercises: 1, completedExercises: 0, xpReward: 75,
      ),
      Chapter(
        id: 'ac_m3', courseId: 'ac',
        title: 'Pipeline',
        description: 'Pipeline de 5 estagios, hazards e forwarding.',
        status: ChapterStatus.locked, totalExercises: 2, completedExercises: 0, xpReward: 100,
      ),
      Chapter(
        id: 'ac_m4', courseId: 'ac',
        title: 'Hierarquia de Memoria',
        description: 'Cache (mapeamento direto, associativo), miss/hit, write policies.',
        status: ChapterStatus.locked, totalExercises: 1, completedExercises: 0, xpReward: 100,
      ),
    ],
  ),
  Course(
    id: 'se',
    name: 'Sistemas Embutidos',
    shortName: 'SE',
    totalChapters: 3,
    completedChapters: 0,
    enrolled: false,
    chapters: [
      Chapter(
        id: 'se_m1', courseId: 'se',
        title: 'Perifericos e Temporizadores',
        description: 'Configuracao de timers, prescalers e modos de operacao.',
        status: ChapterStatus.locked, totalExercises: 3, completedExercises: 0, xpReward: 75,
      ),
      Chapter(
        id: 'se_m2', courseId: 'se',
        title: 'Interrupcoes',
        description: 'Vetor de interrupcoes, prioridade e rotinas ISR.',
        status: ChapterStatus.locked, totalExercises: 3, completedExercises: 0, xpReward: 75,
      ),
      Chapter(
        id: 'se_m3', courseId: 'se',
        title: 'Comunicacao Serie',
        description: 'UART, SPI e I2C -- configuracao e protocolos.',
        status: ChapterStatus.locked, totalExercises: 3, completedExercises: 0, xpReward: 100,
      ),
    ],
  ),
];

// Exercicios alinhados com pathStore -- mesmas perguntas e opcoes do percurso base
final List<MockExercise> mockExercises = [
  // -- Sistemas Digitais ------------------------------------------------------
  // M1 -- Sistemas de Numeracao e Codigos
  const MockExercise(
    id: 'sd-m1-e1', courseId: 'sd', chapterId: 'sd_m1',
    courseName: 'Sistemas Digitais', chapterName: 'Sistemas de Numeracao e Codigos',
    question: 'Converte 1101 (base 2) para decimal.',
    type: ExerciseType.multipleChoice,
    difficulty: ExerciseDifficulty.facil,
    options: ['11', '13', '15', '12'],
    correctIndex: 1,
    solution: '13',
    explanation: '1101 em base 2 = 1x2^3 + 1x2^2 + 0x2^1 + 1x2^0 = 8 + 4 + 0 + 1 = 13.',
  ),
  const MockExercise(
    id: 'sd-m1-e2', courseId: 'sd', chapterId: 'sd_m1',
    courseName: 'Sistemas Digitais', chapterName: 'Sistemas de Numeracao e Codigos',
    question: 'Qual e a representacao em BCD do numero 47?',
    type: ExerciseType.multipleChoice,
    difficulty: ExerciseDifficulty.medio,
    options: ['0100 0111', '0100 1001', '0011 0111', '0110 0111'],
    correctIndex: 0,
    solution: '0100 0111',
    explanation: 'Em BCD, cada digito decimal e representado por 4 bits: 4 = 0100, 7 = 0111, logo 0100 0111.',
  ),
  const MockExercise(
    id: 'sd-m1-e3', courseId: 'sd', chapterId: 'sd_m1',
    courseName: 'Sistemas Digitais', chapterName: 'Sistemas de Numeracao e Codigos',
    question: 'O complemento para 2 de 0110 (4 bits) e:',
    type: ExerciseType.multipleChoice,
    difficulty: ExerciseDifficulty.medio,
    options: ['1001', '1010', '0101', '1110'],
    correctIndex: 1,
    solution: '1010',
    explanation: 'Complemento para 1 de 0110 e 1001, somando 1 obtemos 1010.',
  ),
  const MockExercise(
    id: 'sd-m1-e4', courseId: 'sd', chapterId: 'sd_m1',
    courseName: 'Sistemas Digitais', chapterName: 'Sistemas de Numeracao e Codigos',
    question: 'O codigo Gray garante que valores consecutivos diferem apenas em 1 bit.',
    type: ExerciseType.trueFalse,
    difficulty: ExerciseDifficulty.facil,
    options: ['Verdadeiro', 'Falso'],
    correctIndex: 0,
    solution: 'Verdadeiro',
    explanation: 'O codigo Gray e projetado exatamente com essa propriedade -- os valores adjacentes diferem em apenas 1 bit, reduzindo erros de transicao.',
  ),
  // M2 -- Algebra de Boole e Simplificacao
  const MockExercise(
    id: 'sd-m2-e1', courseId: 'sd', chapterId: 'sd_m2',
    courseName: 'Sistemas Digitais', chapterName: 'Algebra de Boole e Simplificacao',
    question: 'Segundo o teorema de De Morgan, NOT(A.B) e igual a:',
    type: ExerciseType.multipleChoice,
    difficulty: ExerciseDifficulty.medio,
    options: ['NOT(A) . NOT(B)', 'NOT(A) + NOT(B)', 'A + B', 'A . B'],
    correctIndex: 1,
    solution: 'NOT(A) + NOT(B)',
    explanation: 'O teorema de De Morgan afirma que NOT(A.B) = NOT(A) + NOT(B). A negacao de um AND transforma-se num OR das negacoes.',
  ),
  const MockExercise(
    id: 'sd-m2-e2', courseId: 'sd', chapterId: 'sd_m2',
    courseName: 'Sistemas Digitais', chapterName: 'Algebra de Boole e Simplificacao',
    question: 'A expressao AB + AB\' simplifica para A.',
    type: ExerciseType.trueFalse,
    difficulty: ExerciseDifficulty.medio,
    options: ['Verdadeiro', 'Falso'],
    correctIndex: 0,
    solution: 'Verdadeiro',
    explanation: 'AB + AB\' = A(B + B\') = A.1 = A. Fatoriza-se A e B + B\' e sempre 1.',
  ),
  const MockExercise(
    id: 'sd-m2-e3', courseId: 'sd', chapterId: 'sd_m2',
    courseName: 'Sistemas Digitais', chapterName: 'Algebra de Boole e Simplificacao',
    question: 'Qual e o resultado de simplificar F = A\'BC + ABC usando o mapa de Karnaugh?',
    type: ExerciseType.multipleChoice,
    difficulty: ExerciseDifficulty.dificil,
    options: ['BC', 'AB', 'AC', 'A\'B'],
    correctIndex: 0,
    solution: 'BC',
    explanation: 'A\'BC + ABC = BC(A\' + A) = BC.1 = BC. Colocando BC em evidencia, A\' + A = 1.',
  ),
  // M3 -- Circuitos Combinatorios
  const MockExercise(
    id: 'sd-m3-e1', courseId: 'sd', chapterId: 'sd_m3',
    courseName: 'Sistemas Digitais', chapterName: 'Circuitos Combinatorios',
    question: 'Um MUX 4:1 precisa de quantas linhas de selecao?',
    type: ExerciseType.multipleChoice,
    difficulty: ExerciseDifficulty.facil,
    options: ['1', '2', '3', '4'],
    correctIndex: 1,
    solution: '2',
    explanation: 'Um MUX 4:1 tem 4 entradas, logo precisa de log2(4) = 2 linhas de selecao para escolher entre elas.',
  ),
  const MockExercise(
    id: 'sd-m3-e2', courseId: 'sd', chapterId: 'sd_m3',
    courseName: 'Sistemas Digitais', chapterName: 'Circuitos Combinatorios',
    question: 'Um descodificador converte um codigo binario para ativar uma de N saidas.',
    type: ExerciseType.trueFalse,
    difficulty: ExerciseDifficulty.facil,
    options: ['Verdadeiro', 'Falso'],
    correctIndex: 0,
    solution: 'Verdadeiro',
    explanation: 'Um descodificador (decoder) converte uma entrada binaria de n bits numa unica saida ativa de entre 2^n possiveis.',
  ),
  // M4 -- Circuitos Sequenciais
  const MockExercise(
    id: 'sd-m4-e1', courseId: 'sd', chapterId: 'sd_m4',
    courseName: 'Sistemas Digitais', chapterName: 'Circuitos Sequenciais',
    question: 'Identifica a tabela de verdade do Flip-Flop JK quando J=1 e K=1.',
    type: ExerciseType.multipleChoice,
    difficulty: ExerciseDifficulty.medio,
    options: ['Mantem estado', 'Reset (0)', 'Set (1)', 'Toggle (Inverte)'],
    correctIndex: 3,
    solution: 'Toggle (Inverte)',
    explanation: 'Quando J=1 e K=1, o FF-JK faz toggle, ou seja, inverte o estado atual da saida Q.',
  ),
  const MockExercise(
    id: 'sd-m4-e2', courseId: 'sd', chapterId: 'sd_m4',
    courseName: 'Sistemas Digitais', chapterName: 'Circuitos Sequenciais',
    question: 'Um flip-flop D armazena o valor da entrada na transicao do clock.',
    type: ExerciseType.trueFalse,
    difficulty: ExerciseDifficulty.facil,
    options: ['Verdadeiro', 'Falso'],
    correctIndex: 0,
    solution: 'Verdadeiro',
    explanation: 'O flip-flop D captura o valor da entrada D na transicao (edge) do sinal de clock e mantem esse valor ate a proxima transicao.',
  ),
  // M5 -- Maquinas de Estado
  const MockExercise(
    id: 'sd-m5-e1', courseId: 'sd', chapterId: 'sd_m5',
    courseName: 'Sistemas Digitais', chapterName: 'Maquinas de Estado',
    question: 'Num modelo de Moore, a saida depende de:',
    type: ExerciseType.multipleChoice,
    difficulty: ExerciseDifficulty.medio,
    options: ['Entradas e estado atual', 'Apenas do estado atual', 'Apenas das entradas', 'Estado seguinte'],
    correctIndex: 1,
    solution: 'Apenas do estado atual',
    explanation: 'No modelo de Moore, a saida e funcao apenas do estado atual, ao contrario do modelo de Mealy onde depende tambem das entradas.',
  ),

  // -- Arquitetura de Computadores ---------------------------------------------
  // M1 -- Datapaths MIPS
  const MockExercise(
    id: 'ac-m1-e1', courseId: 'ac', chapterId: 'ac_m1',
    courseName: 'Arquitetura de Computadores', chapterName: 'Datapaths MIPS',
    question: 'Qual o registo em MIPS que contem sempre o valor zero?',
    type: ExerciseType.multipleChoice,
    difficulty: ExerciseDifficulty.facil,
    options: ['\$t0', '\$zero (\$0)', '\$ra', '\$sp'],
    correctIndex: 1,
    solution: '\$zero (\$0)',
    explanation: 'O registo \$0 (ou \$zero) esta hardwired a zero em MIPS -- qualquer escrita nele e ignorada.',
  ),
  const MockExercise(
    id: 'ac-m1-e2', courseId: 'ac', chapterId: 'ac_m1',
    courseName: 'Arquitetura de Computadores', chapterName: 'Datapaths MIPS',
    question: 'Na fase de Write-Back, o resultado da ALU e escrito no registo destino.',
    type: ExerciseType.trueFalse,
    difficulty: ExerciseDifficulty.facil,
    options: ['Verdadeiro', 'Falso'],
    correctIndex: 0,
    solution: 'Verdadeiro',
    explanation: 'A fase de Write-Back e onde o resultado da ALU (ou o dado lido da memoria) e escrito de volta no banco de registos.',
  ),
  // M2 -- Conjunto de Instrucoes
  const MockExercise(
    id: 'ac-m2-e1', courseId: 'ac', chapterId: 'ac_m2',
    courseName: 'Arquitetura de Computadores', chapterName: 'Conjunto de Instrucoes',
    question: 'A instrucao "addi \$t0, \$t1, 5" e do tipo:',
    type: ExerciseType.multipleChoice,
    difficulty: ExerciseDifficulty.medio,
    options: ['R', 'I', 'J', 'Pseudo'],
    correctIndex: 1,
    solution: 'I',
    explanation: 'A instrucao addi usa um valor imediato (5), logo e do tipo I (Immediate). Instrucoes tipo I tem formato: opcode rs rt immediate.',
  ),
  // M3 -- Pipeline
  const MockExercise(
    id: 'ac-m3-e1', courseId: 'ac', chapterId: 'ac_m3',
    courseName: 'Arquitetura de Computadores', chapterName: 'Pipeline',
    question: 'O pipeline classico MIPS tem 5 estagios.',
    type: ExerciseType.trueFalse,
    difficulty: ExerciseDifficulty.facil,
    options: ['Verdadeiro', 'Falso'],
    correctIndex: 0,
    solution: 'Verdadeiro',
    explanation: 'O pipeline classico MIPS tem 5 estagios: IF (Instruction Fetch), ID (Instruction Decode), EX (Execute), MEM (Memory Access) e WB (Write Back).',
  ),
  const MockExercise(
    id: 'ac-m3-e2', courseId: 'ac', chapterId: 'ac_m3',
    courseName: 'Arquitetura de Computadores', chapterName: 'Pipeline',
    question: 'Um data hazard pode ser resolvido por:',
    type: ExerciseType.multipleChoice,
    difficulty: ExerciseDifficulty.dificil,
    options: ['Forwarding', 'Branch prediction', 'Reordenacao do programa', 'Todas as anteriores'],
    correctIndex: 0,
    solution: 'Forwarding',
    explanation: 'Data hazards sao resolvidos principalmente por forwarding (bypassing), que encaminha o resultado da ALU diretamente para a entrada.',
  ),
  // M4 -- Hierarquia de Memoria
  const MockExercise(
    id: 'ac-m4-e1', courseId: 'ac', chapterId: 'ac_m4',
    courseName: 'Arquitetura de Computadores', chapterName: 'Hierarquia de Memoria',
    question: 'Em cache de mapeamento direto, cada bloco de memoria pode ir para:',
    type: ExerciseType.multipleChoice,
    difficulty: ExerciseDifficulty.medio,
    options: ['Qualquer posicao', 'Apenas uma posicao', 'Um conjunto limitado', 'Depende do tamanho'],
    correctIndex: 1,
    solution: 'Apenas uma posicao',
    explanation: 'No mapeamento direto, cada bloco de memoria e mapeado para exatamente uma linha de cache, determinada por (endereco mod num. de linhas).',
  ),

  // -- Sistemas Embutidos ------------------------------------------------------
  // M1 -- Perifericos e Temporizadores
  const MockExercise(
    id: 'se-m1-e1', courseId: 'se', chapterId: 'se_m1',
    courseName: 'Sistemas Embutidos', chapterName: 'Perifericos e Temporizadores',
    question: 'Um prescaler de 64 com clock de 16MHz produz frequencia de:',
    type: ExerciseType.multipleChoice,
    difficulty: ExerciseDifficulty.medio,
    options: ['250kHz', '1MHz', '4MHz', '64MHz'],
    correctIndex: 0,
    solution: '250kHz',
    explanation: '16MHz / 64 = 250kHz. O prescaler divide a frequencia do clock pelo fator configurado.',
  ),
  const MockExercise(
    id: 'se-m1-e2', courseId: 'se', chapterId: 'se_m1',
    courseName: 'Sistemas Embutidos', chapterName: 'Perifericos e Temporizadores',
    question: 'Um watchdog timer serve para reiniciar o sistema em caso de falha.',
    type: ExerciseType.trueFalse,
    difficulty: ExerciseDifficulty.facil,
    options: ['Verdadeiro', 'Falso'],
    correctIndex: 0,
    solution: 'Verdadeiro',
    explanation: 'O watchdog timer e um temporizador que, se nao for "alimentado" periodicamente pelo software, assume que houve uma falha e efetua um reset do sistema.',
  ),
  const MockExercise(
    id: 'se-m1-e3', courseId: 'se', chapterId: 'se_m1',
    courseName: 'Sistemas Embutidos', chapterName: 'Perifericos e Temporizadores',
    question: 'O modo CTC de um timer permite gerar interrupcoes em intervalos regulares.',
    type: ExerciseType.trueFalse,
    difficulty: ExerciseDifficulty.medio,
    options: ['Verdadeiro', 'Falso'],
    correctIndex: 0,
    solution: 'Verdadeiro',
    explanation: 'No modo CTC (Clear Timer on Compare Match), o timer conta ate um valor de comparacao e reinicia, gerando uma interrupcao.',
  ),
  // M2 -- Interrupcoes
  const MockExercise(
    id: 'se-m2-e1', courseId: 'se', chapterId: 'se_m2',
    courseName: 'Sistemas Embutidos', chapterName: 'Interrupcoes',
    question: 'Uma ISR (Interrupt Service Routine) deve ser tao curta quanto possivel.',
    type: ExerciseType.trueFalse,
    difficulty: ExerciseDifficulty.facil,
    options: ['Verdadeiro', 'Falso'],
    correctIndex: 0,
    solution: 'Verdadeiro',
    explanation: 'ISRs devem ser curtas para minimizar o tempo em que outras interrupcoes ficam bloqueadas.',
  ),
  const MockExercise(
    id: 'se-m2-e2', courseId: 'se', chapterId: 'se_m2',
    courseName: 'Sistemas Embutidos', chapterName: 'Interrupcoes',
    question: 'Qual e a funcao da flag de habilitacao global de interrupcoes (GIE)?',
    type: ExerciseType.multipleChoice,
    difficulty: ExerciseDifficulty.medio,
    options: ['Ativar uma interrupcao especifica', 'Habilitar/desabilitar todas as interrupcoes', 'Definir a prioridade das interrupcoes', 'Limpar o vetor de interrupcoes'],
    correctIndex: 1,
    solution: 'Habilitar/desabilitar todas as interrupcoes',
    explanation: 'A GIE (Global Interrupt Enable) e um bit que habilita ou desabilita todas as interrupcoes de uma vez.',
  ),
  const MockExercise(
    id: 'se-m2-e3', courseId: 'se', chapterId: 'se_m2',
    courseName: 'Sistemas Embutidos', chapterName: 'Interrupcoes',
    question: 'Num sistema com interrupcoes aninhadas, uma ISR pode ser interrompida por outra de maior prioridade.',
    type: ExerciseType.trueFalse,
    difficulty: ExerciseDifficulty.dificil,
    options: ['Verdadeiro', 'Falso'],
    correctIndex: 0,
    solution: 'Verdadeiro',
    explanation: 'Em sistemas com interrupcoes aninhadas (nested interrupts), uma ISR de menor prioridade pode ser interrompida por outra de maior prioridade.',
  ),
  // M3 -- Comunicacao Serie
  const MockExercise(
    id: 'se-m3-e1', courseId: 'se', chapterId: 'se_m3',
    courseName: 'Sistemas Embutidos', chapterName: 'Comunicacao Serie',
    question: 'O protocolo SPI usa quantas linhas de sinal (sem contar CS)?',
    type: ExerciseType.multipleChoice,
    difficulty: ExerciseDifficulty.medio,
    options: ['1', '2', '3', '4'],
    correctIndex: 2,
    solution: '3',
    explanation: 'SPI usa 3 linhas principais: MOSI (Master Out Slave In), MISO (Master In Slave Out) e SCLK (clock). CS e adicional por dispositivo.',
  ),
  const MockExercise(
    id: 'se-m3-e2', courseId: 'se', chapterId: 'se_m3',
    courseName: 'Sistemas Embutidos', chapterName: 'Comunicacao Serie',
    question: 'O I2C usa apenas 2 fios: SDA (dados) e SCL (clock).',
    type: ExerciseType.trueFalse,
    difficulty: ExerciseDifficulty.facil,
    options: ['Verdadeiro', 'Falso'],
    correctIndex: 0,
    solution: 'Verdadeiro',
    explanation: 'O barramento I2C utiliza apenas duas linhas: SDA (Serial Data) e SCL (Serial Clock), ambas com pull-ups.',
  ),
  const MockExercise(
    id: 'se-m3-e3', courseId: 'se', chapterId: 'se_m3',
    courseName: 'Sistemas Embutidos', chapterName: 'Comunicacao Serie',
    question: 'Na comunicacao UART, a taxa de transmissao e definida pelo baud rate.',
    type: ExerciseType.trueFalse,
    difficulty: ExerciseDifficulty.facil,
    options: ['Verdadeiro', 'Falso'],
    correctIndex: 0,
    solution: 'Verdadeiro',
    explanation: 'O baud rate define o numero de simbolos por segundo na comunicacao UART, determinando a velocidade de transmissao.',
  ),
];

