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
        id: 'sd_m1',
        courseId: 'sd',
        title: 'Sistemas de Numeracao e Codigos',
        description:
            'Conversao entre bases numericas, codigo BCD, Gray e complementos.',
        status: ChapterStatus.completed,
        totalExercises: 4,
        completedExercises: 4,
        xpReward: 50,
      ),
      Chapter(
        id: 'sd_m2',
        courseId: 'sd',
        title: 'Algebra de Boole e Simplificacao',
        description:
            'Teoremas de De Morgan, mapas de Karnaugh e simplificacao de expressoes.',
        status: ChapterStatus.completed,
        totalExercises: 3,
        completedExercises: 3,
        xpReward: 75,
      ),
      Chapter(
        id: 'sd_m3',
        courseId: 'sd',
        title: 'Circuitos Combinatorios',
        description:
            'Multiplexadores, descodificadores, somadores e comparadores.',
        status: ChapterStatus.inProgress,
        totalExercises: 2,
        completedExercises: 1,
        xpReward: 100,
      ),
      Chapter(
        id: 'sd_m4',
        courseId: 'sd',
        title: 'Circuitos Sequenciais',
        description:
            'Flip-flops (SR, JK, D, T), registos de deslocamento e contadores.',
        status: ChapterStatus.available,
        totalExercises: 2,
        completedExercises: 0,
        xpReward: 100,
      ),
      Chapter(
        id: 'sd_m5',
        courseId: 'sd',
        title: 'Maquinas de Estado',
        description:
            'Modelos de Moore e Mealy, diagramas de transicao e implementacao.',
        status: ChapterStatus.locked,
        totalExercises: 1,
        completedExercises: 0,
        xpReward: 125,
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
        id: 'ac_m1',
        courseId: 'ac',
        title: 'Datapaths MIPS',
        description: 'Componentes do datapath, ALU, registos e memoria.',
        status: ChapterStatus.available,
        totalExercises: 2,
        completedExercises: 0,
        xpReward: 75,
      ),
      Chapter(
        id: 'ac_m2',
        courseId: 'ac',
        title: 'Conjunto de Instrucoes',
        description:
            'Tipos de instrucao (R, I, J), enderecamento e codificacao.',
        status: ChapterStatus.locked,
        totalExercises: 1,
        completedExercises: 0,
        xpReward: 75,
      ),
      Chapter(
        id: 'ac_m3',
        courseId: 'ac',
        title: 'Pipeline',
        description: 'Pipeline de 5 estagios, hazards e forwarding.',
        status: ChapterStatus.locked,
        totalExercises: 2,
        completedExercises: 0,
        xpReward: 100,
      ),
      Chapter(
        id: 'ac_m4',
        courseId: 'ac',
        title: 'Hierarquia de Memoria',
        description:
            'Cache (mapeamento direto, associativo), miss/hit, write policies.',
        status: ChapterStatus.locked,
        totalExercises: 1,
        completedExercises: 0,
        xpReward: 100,
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
        id: 'se_m1',
        courseId: 'se',
        title: 'Perifericos e Temporizadores',
        description: 'Configuracao de timers, prescalers e modos de operacao.',
        status: ChapterStatus.locked,
        totalExercises: 3,
        completedExercises: 0,
        xpReward: 75,
      ),
      Chapter(
        id: 'se_m2',
        courseId: 'se',
        title: 'Interrupcoes',
        description: 'Vetor de interrupcoes, prioridade e rotinas ISR.',
        status: ChapterStatus.locked,
        totalExercises: 3,
        completedExercises: 0,
        xpReward: 75,
      ),
      Chapter(
        id: 'se_m3',
        courseId: 'se',
        title: 'Comunicacao Serie',
        description: 'UART, SPI e I2C -- configuracao e protocolos.',
        status: ChapterStatus.locked,
        totalExercises: 3,
        completedExercises: 0,
        xpReward: 100,
      ),
    ],
  ),
];
