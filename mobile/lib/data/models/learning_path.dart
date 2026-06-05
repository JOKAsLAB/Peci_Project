// ─── Practice Session ────────────────────────────────────────────────────────

class PracticeTopicInfo {
  final String name;
  final int order;
  final int correctCount;
  final int totalCount;

  const PracticeTopicInfo({
    required this.name,
    required this.order,
    required this.correctCount,
    required this.totalCount,
  });

  factory PracticeTopicInfo.fromJson(Map<String, dynamic> json) {
    return PracticeTopicInfo(
      name: json['name'] as String? ?? '',
      order: json['order'] as int? ?? 0,
      correctCount: json['correct_count'] as int? ?? 0,
      totalCount: json['total_count'] as int? ?? 0,
    );
  }
}

class PracticeSession {
  final int doneToday;
  final int dailyLimit;
  final int remainingToday;
  final bool canPractice;
  final bool allCompleted;
  final bool streakMet;
  final PracticeTopicInfo? currentTopic;
  final List<Map<String, dynamic>> exercisesRaw;

  const PracticeSession({
    required this.doneToday,
    required this.dailyLimit,
    required this.remainingToday,
    required this.canPractice,
    required this.allCompleted,
    this.streakMet = false,
    this.currentTopic,
    this.exercisesRaw = const [],
  });

  factory PracticeSession.fromJson(Map<String, dynamic> json) {
    final topicJson = json['current_topic'] as Map<String, dynamic>?;
    return PracticeSession(
      doneToday: json['done_today'] as int? ?? 0,
      dailyLimit: json['daily_limit'] as int? ?? 5,
      remainingToday: json['remaining_today'] as int? ?? 0,
      canPractice: json['can_practice'] as bool? ?? false,
      allCompleted: json['all_completed'] as bool? ?? false,
      streakMet: json['streak_met'] as bool? ?? false,
      currentTopic: topicJson != null ? PracticeTopicInfo.fromJson(topicJson) : null,
      exercisesRaw: (json['exercises'] as List<dynamic>? ?? [])
          .map((e) => e as Map<String, dynamic>)
          .toList(),
    );
  }
}

// ─── Models ──────────────────────────────────────────────────────────────────

class LearningExercise {
  final String id;
  final String question;
  final String type; // "Multiple Choice" | "True/False"
  final String difficulty; // "Easy" | "Medium" | "Hard"
  final List<String> options;
  final String correct; // "A", "B", "C", "D" ou "Verdadeiro"/"Falso"
  final String explanation;

  const LearningExercise({
    required this.id,
    required this.question,
    required this.type,
    required this.difficulty,
    required this.options,
    required this.correct,
    required this.explanation,
  });

  factory LearningExercise.fromJson(Map<String, dynamic> json) {
    final solution = json['solution'] as Map<String, dynamic>? ?? {};

    final exerciseType = (json['type'] as String? ?? '').toLowerCase();
    final isTrueFalse = exerciseType.contains('true') || exerciseType.contains('false');

    // ─ Extrai as opções ──────────────────────────────────────────────────
    List<String> options = [];

    if (isTrueFalse) {
      // Para True/False, força as opções padrão em português
      options = ['Verdadeiro', 'Falso'];
    } else {
      // Para Multiple Choice, tenta extrair do JSON
      final rawOptions = solution['options'] as List<dynamic>? ?? [];
      options = rawOptions.map((e) => e.toString()).toList();
    }
    
    // ─ Extrai a resposta correta ─────────────────────────────────────────
    // Normaliza: número inteiro → letra ("0"→"A", 2→"C"), letra mantém-se.
    // Para True/False, mapeia "A"/"true"/"0" → "Verdadeiro".
    final String correct;
    if (isTrueFalse) {
      final raw = (solution['correct']?.toString() ?? '').toLowerCase();
      if (raw == 'a' || raw == 'true' || raw == '0') {
        correct = 'Verdadeiro';
      } else if (raw == 'b' || raw == 'false' || raw == '1') {
        correct = 'Falso';
      } else {
        correct = solution['correct']?.toString() ?? '';
      }
    } else {
      final rawCorrect = solution['correct'];
      String correctStr;
      if (rawCorrect is int) {
        // Editor do professor guardou índice 0-based (0→A, 1→B, 2→C, 3→D)
        correctStr = rawCorrect >= 0 && rawCorrect < 26
            ? String.fromCharCode(65 + rawCorrect)
            : '';
      } else {
        correctStr = rawCorrect?.toString() ?? '';
        // Se for string numérica ("0", "1", ...) converte também para letra
        final asInt = int.tryParse(correctStr);
        if (asInt != null && asInt >= 0 && asInt < 26) {
          correctStr = String.fromCharCode(65 + asInt);
        }
      }
      correct = correctStr;
    }

    return LearningExercise(
      id: json['id_exercise'] as String,
      question: json['question'] as String? ?? '',
      type: json['type'] as String? ?? 'Multiple Choice',
      difficulty: json['difficulty'] as String? ?? 'Medium',
      options: options,
      correct: correct,
      explanation: json['explanation'] as String? ?? '',
    );
  }

  bool get isTrueFalse => type.toLowerCase().contains('true') || type.toLowerCase().contains('false');
}


class Checkpoint {
  final String topicName;
  final int topicOrder;
  final List<LearningExercise> exercises;
  final bool isLocked;
  final bool isCompleted;
  final int correctCount;
  final int attemptedCount;
  final int totalCount;

  const Checkpoint({
    required this.topicName,
    required this.topicOrder,
    required this.exercises,
    this.isLocked = false,
    this.isCompleted = false,
    this.correctCount = 0,
    this.attemptedCount = 0,
    this.totalCount = 0,
  });

  factory Checkpoint.fromJson(Map<String, dynamic> json) {
    return Checkpoint(
      topicName: json['topic_name'] as String,
      topicOrder: json['topic_order'] as int,
      exercises: (json['exercises'] as List<dynamic>? ?? [])
          .map((e) => LearningExercise.fromJson(e as Map<String, dynamic>))
          .toList(),
      isLocked: json['is_locked'] as bool? ?? false,
      isCompleted: json['is_completed'] as bool? ?? false,
      correctCount: json['correct_count'] as int? ?? 0,
      attemptedCount: json['attempted_count'] as int? ?? 0,
      totalCount: json['total_count'] as int? ?? 0,
    );
  }
}


class LearningPath {
  final int idUc;
  final String name;
  final int totalTopics;
  final int totalExercises;
  final List<Checkpoint> checkpoints;

  const LearningPath({
    required this.idUc,
    required this.name,
    required this.totalTopics,
    required this.totalExercises,
    required this.checkpoints,
  });

  factory LearningPath.fromJson(Map<String, dynamic> json) {
    return LearningPath(
      idUc: json['id_uc'] as int,
      name: json['name'] as String,
      totalTopics: json['total_topics'] as int,
      totalExercises: json['total_exercises'] as int,
      checkpoints: (json['checkpoints'] as List<dynamic>? ?? [])
          .map((e) => Checkpoint.fromJson(e as Map<String, dynamic>))
          .toList(),
    );
  }
}