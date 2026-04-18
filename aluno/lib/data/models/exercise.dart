import 'dart:convert';

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
    // ── Tipo ──────────────────────────────────────────────────────────────────
    final rawType = (json['type'] as String? ?? '').toLowerCase();
    final type = rawType.contains('true') || rawType.contains('false') || rawType == 'truefalse'
        ? ExerciseType.trueFalse
        : ExerciseType.multipleChoice;

    // ── Dificuldade ───────────────────────────────────────────────────────────
    final rawDiff = (json['difficulty'] as String? ?? '').toLowerCase();
    final difficulty = switch (rawDiff) {
      'easy'   => ExerciseDifficulty.easy,
      'hard'   => ExerciseDifficulty.hard,
      _        => ExerciseDifficulty.medium,
    };

    // ── Solution (dict com opções e resposta correta) ─────────────────────────
    // A API devolve: "solution": {"correct_index": 0, "options": ["A", "B", ...]}
    // Ou pode vir como string JSON que precisa de parsing
    List<String> options = const [];
    int correctIndex = 0;

    var sol = json['solution'];
    
    // 🔧 Se é string, tenta fazer parse como JSON
    if (sol is String && sol.isNotEmpty) {
      try {
        sol = jsonDecode(sol);
      } catch (_) {
        // Falha no parse - deixa como está
      }
    }
    
    // Agora extrai as opções do Map
    if (sol is Map<String, dynamic>) {
      // Opções (tenta variações)
      final rawOptions = sol['options'] ?? sol['opcoes'] ?? sol['choices'] ?? [];
      if (rawOptions is List) {
        options = rawOptions.map((o) {
          final str = o.toString();
          // Strip "A) ", "B) " etc. prefix added by the question generator
          if (str.length >= 3 && str[1] == ')' && str[2] == ' ') {
            return str.substring(3);
          }
          return str;
        }).toList();
      }
      // Índice correto (tenta variações)
      final rawCorrect = sol['correct_index'] ?? sol['correctIndex'] ?? sol['resposta_correta'] ?? sol['correct'] ?? 0;
      if (rawCorrect is int) {
        correctIndex = rawCorrect;
      } else if (rawCorrect is num) {
        correctIndex = rawCorrect.toInt();
      } else if (rawCorrect is bool) {
        // true  → Verdadeiro (index 0)
        // false → Falso      (index 1)
        correctIndex = rawCorrect ? 0 : 1;
      } else if (rawCorrect is String) {
        final lower = rawCorrect.toLowerCase();
        if (lower == 'true') {
          correctIndex = 0; // Verdadeiro
        } else if (lower == 'false') {
          correctIndex = 1; // Falso
        } else if (lower.length == 1 && lower.codeUnitAt(0) >= 97 && lower.codeUnitAt(0) <= 122) {
          // Letra: 'a' → 0, 'b' → 1, 'c' → 2, 'd' → 3, ...
          correctIndex = lower.codeUnitAt(0) - 97;
        } else {
          correctIndex = int.tryParse(rawCorrect) ?? 0;
        }
      }
    }

    // Fallback para True/False sem opções guardadas
    if (type == ExerciseType.trueFalse && options.isEmpty) {
      options = ['Verdadeiro', 'Falso'];
    }

    // ── Nomes de curso e tópico ───────────────────────────────────────────────
    final rawCourseInfo = json['course_unit_info'];
    final String courseName;
    if (rawCourseInfo is Map<String, dynamic>) {
      courseName = (rawCourseInfo['name'] ?? '').toString();
    } else {
      courseName = (json['course_name'] ?? json['nome_uc'] ?? '').toString();
    }
    final chapterName = (json['topic_name'] ?? json['nome_capitulo'] ?? '').toString();

    return Exercise(
      id:           (json['id_exercise'] ?? json['Id'] ?? '').toString(),
      courseId:     (json['id_uc']       ?? json['Id_Uc'] ?? '').toString(),
      chapterId:    chapterName,
      courseName:   courseName,
      chapterName:  chapterName,
      question:     (json['question']    ?? json['Pergunta'] ?? '').toString(),
      type:         type,
      difficulty:   difficulty,
      options:      options,
      correctIndex: correctIndex,
      solution:     sol is Map ? (sol['correct_index'] ?? 0).toString() : sol?.toString() ?? '',
      explanation:  (json['explanation'] ?? json['Explicacao'] ?? '').toString(),
    );
  }
}