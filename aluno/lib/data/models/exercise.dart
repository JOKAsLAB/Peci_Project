enum ExerciseType { multipleChoice, trueFalse }

enum ExerciseDifficulty { easy, medium, hard }

class Exercise {
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

  const Exercise({
    required this.id,
    required this.courseId,
    required this.chapterId,
    required this.courseName,
    required this.chapterName,
    required this.question,
    this.type = ExerciseType.multipleChoice,
    this.difficulty = ExerciseDifficulty.medium,
    this.options = const [],
    this.correctIndex = 0,
    this.solution = '',
    this.explanation = '',
  });

  factory Exercise.fromJson(Map<String, dynamic> json) {
    return Exercise(
      id: json['Id'],
      courseId: json['Id_Uc'],
      chapterId: json['Id_Capitulo'],
      courseName: json['Nome_Uc'],
      chapterName: json['Nome_Capitulo'],
      question: json['Pergunta'],
      type: ExerciseType.values[json['Tipo']],
      difficulty: ExerciseDifficulty.values[json['Dificuldade']],
      options: List<String>.from(json['Opcoes']),
      correctIndex: json['Resposta_Correta'],
      solution: json['Solucao'],
      explanation: json['Explicacao'],
    );
  }

}

// Exercicios alinhados com pathStore -- mesmas perguntas e opcoes do percurso base
final List<Exercise> mockExercises = [
  // -- Sistemas Digitais ------------------------------------------------------
  // M1 -- Sistemas de Numeracao e Codigos
  const Exercise(
    id: 'sd-m1-e1',
    courseId: 'sd',
    chapterId: 'sd_m1',
    courseName: 'Sistemas Digitais',
    chapterName: 'Sistemas de Numeracao e Codigos',
    question: 'Converte 1101 (base 2) para decimal.',
    type: ExerciseType.multipleChoice,
    difficulty: ExerciseDifficulty.easy,
    options: ['11', '13', '15', '12'],
    correctIndex: 1,
    solution: '13',
    explanation:
        '1101 em base 2 = 1x2^3 + 1x2^2 + 0x2^1 + 1x2^0 = 8 + 4 + 0 + 1 = 13.',
  )
];