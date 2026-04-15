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
    // Para True/False, mapeia "A"/"true" → "Verdadeiro" e "B"/"false" → "Falso"
    // para que a comparação com as opções em português funcione correctamente.
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
      correct = solution['correct']?.toString() ?? '';
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

  const Checkpoint({
    required this.topicName,
    required this.topicOrder,
    required this.exercises,
  });

  factory Checkpoint.fromJson(Map<String, dynamic> json) {
    return Checkpoint(
      topicName: json['topic_name'] as String,
      topicOrder: json['topic_order'] as int,
      exercises: (json['exercises'] as List<dynamic>? ?? [])
          .map((e) => LearningExercise.fromJson(e as Map<String, dynamic>))
          .toList(),
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