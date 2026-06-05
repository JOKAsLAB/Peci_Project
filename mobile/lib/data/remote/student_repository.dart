import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:logging/logging.dart';
import 'package:peci_project/data/models/exercise.dart';
import 'package:peci_project/data/models/topic.dart';

import '../models/learning_path.dart' show LearningPath, PracticeSession;
import '../models/student_profile.dart';
import 'api_client.dart';

final studentRepositoryProvider = Provider((ref) {
  final dio = ref.watch(dioProvider);
  return StudentRepository(dio);
});

class StudentRepository {
  final Dio _dio;
  final _log = Logger('StudentRepository');

  StudentRepository(this._dio);

  Future<StudentProfile> getProfile() async {
    final r = await _dio.get('/students/me');
    return StudentProfile.fromJson(r.data as Map<String, dynamic>);
  }

  /// Regista uma resposta. Devolve XP ganho, nível atual e se houve level-up.
  /// [bonus] — true nos 5 exercícios diários dos Cursos (1.5× XP).
  Future<ProgressResult> postProgress({
    required String exerciseId,
    required bool isCorrect,
    required String difficulty, // 'Easy' | 'Medium' | 'Hard'
    bool bonus = false,
  }) async {
    final xp = isCorrect ? _xpForDifficulty(difficulty, bonus: bonus) : 0;
    final body = {
      'id_exercise': exerciseId,
      'status': isCorrect ? 'Correct' : 'Incorrect',
      'xp_earned': xp,
      'attempts': 1,
    };
    try {
      final r = await _dio.post('/students/progress', data: body);
      debugPrint('[postProgress] ✅ status=${r.statusCode} data=${r.data}');
      return ProgressResult.fromJson(r.data as Map<String, dynamic>);
    } on DioException catch (e) {
      debugPrint('[postProgress] ❌ tipo=${e.type} status=${e.response?.statusCode} '
          'body=${e.response?.data} msg=${e.message}');
      _log.severe('Falha ao registar progresso', e.response?.data);
      // Falha silenciosa — não bloqueia a UX do exercício
      return ProgressResult(xpEarned: xp, newTotalXp: 0, newLevel: 1, levelUp: false, streakDays: 0);
    } catch (e) {
      debugPrint('[postProgress] ❌ erro inesperado: $e');
      return ProgressResult(xpEarned: xp, newTotalXp: 0, newLevel: 1, levelUp: false, streakDays: 0);
    }
  }

  static int _xpForDifficulty(String difficulty, {bool bonus = false}) {
    final base = switch (difficulty.toLowerCase()) {
      'easy' => 10,
      'hard' => 35,
      _      => 20, // medium
    };
    return bonus ? (base * 1.5).round() : base;
  }

  Future<List<LearningPath>> getLearningPaths() async {
    final r = await _dio.get('/students/learning-paths');
    return (r.data as List<dynamic>)
        .map((e) => LearningPath.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  // Adiciona um novo método para ir buscar as UCs (course units)
  Future<List<Map<String, dynamic>>> getCourseUnits() async {
    try {
      final response = await _dio.get('/students/course-units');
      if (response.statusCode == 200 && response.data is List) {
        // A API retorna uma lista de objetos, cada um com 'id_uc' e 'name'
        return List<Map<String, dynamic>>.from(response.data);
      }
      return [];
    } on DioException catch (e) {
      _log.severe('Falha ao obter UCs', e.response?.data);
      return [];
    }
  }

  Future<List<Topic>> getTopics(int courseId) async {
    try {
      final response = await _dio.get('/students/topics', queryParameters: {'id_uc': courseId});
      if (response.statusCode == 200 && response.data is List) {
        return (response.data as List)
            .map((json) => Topic.fromJson(json))
            .toList();
      }
      return [];
    } on DioException catch (e) {
      _log.severe('Falha ao obter tópicos para UC $courseId', e.response?.data);
      return [];
    }
  }

  Future<List<Exercise>> getExercises({
    int? courseId,
    String? topicName,
    ExerciseDifficulty? difficulty,
    ExerciseType? type,
  }) async {
    final params = <String, dynamic>{};
    if (courseId != null) params['id_uc'] = courseId;
    if (topicName != null) params['topic_name'] = topicName;

    // Com filtros activos, pede mais resultados (sem limite diário)
    final hasFilters = courseId != null || topicName != null || difficulty != null || type != null;
    if (hasFilters) params['limit'] = 50;

    // Mapeia a dificuldade para o formato da API
    if (difficulty != null) {
      final diffMap = {
        ExerciseDifficulty.easy: 'Easy',
        ExerciseDifficulty.medium: 'Medium',
        ExerciseDifficulty.hard: 'Hard',
      };
      params['difficulty'] = diffMap[difficulty];
    }

    // Mapeia o tipo para o formato da API
    if (type != null) {
      final typeMap = {
        ExerciseType.multipleChoice: 'Multiple Choice',
        ExerciseType.trueFalse: 'True/False',
      };
      params['type'] = typeMap[type];
    }

    try {
      final r = await _dio.get('/students/exercises', queryParameters: params);
      if (r.statusCode == 200 && r.data is List) {
        return (r.data as List)
            .map((e) => Exercise.fromJson(e as Map<String, dynamic>))
            .toList();
      }
      return [];
    } on DioException catch (e) {
      _log.severe('Falha ao obter exercícios', e.response?.data);
      return [];
    }
  }

  Future<PracticeSession> getPracticeSession(int idUc) async {
    try {
      final r = await _dio.get('/students/practice-session', queryParameters: {'id_uc': idUc});
      return PracticeSession.fromJson(r.data as Map<String, dynamic>);
    } on DioException catch (e) {
      _log.severe('Falha ao obter sessão de prática', e.response?.data);
      return const PracticeSession(
        doneToday: 0, dailyLimit: 5, remainingToday: 5,
        canPractice: true, allCompleted: false,
      );
    }
  }

  Future<Map<String, dynamic>> getDailyStatus() async {
    try {
      final r = await _dio.get('/students/daily-status');
      return r.data as Map<String, dynamic>;
    } on DioException catch (e) {
      _log.severe('Falha ao obter estado diário', e.response?.data);
      return {'done_today': 0, 'daily_limit': 5, 'can_practice': true, 'remaining_today': 5};
    }
  }

  Future<List<Map<String, dynamic>>> getTopicStats({int? idUc}) async {
    try {
      final params = idUc != null ? {'id_uc': idUc} : null;
      final r = await _dio.get('/students/stats/topics', queryParameters: params);
      if (r.statusCode == 200 && r.data is List) {
        return List<Map<String, dynamic>>.from(r.data);
      }
      return [];
    } on DioException catch (e) {
      _log.severe('Falha ao obter estatísticas por tópico', e.response?.data);
      return [];
    }
  }

  Future<List<Map<String, dynamic>>> getStreak() async {
    final r = await _dio.get('/students/streak');
    return (r.data as List<dynamic>)
        .map((e) => e as Map<String, dynamic>)
        .toList();
  }

  /// Reportar um exercício
  /// True se o report foi enviado, false se já tinha sido reportado antes.
  Future<bool> reportExercise(String exerciseId) async {
    try {
      await _dio.post('/students/exercises/$exerciseId/report');
      debugPrint('[reportExercise] ✅ Exercise $exerciseId reported');
      return true;
    } on DioException catch (e) {
      if (e.response?.statusCode == 409) {
        // 409 Conflict → já tinha reportado antes
        debugPrint('[reportExercise] ⚠️ Already reported');
        return false;
      }
      debugPrint('[reportExercise] ❌ erro=${e.response?.statusCode} msg=${e.message}');
      _log.severe('Falha ao reportar exercício', e.response?.data);
      rethrow;
    }
  }

  Future<Map<String, dynamic>> chatQuery(
    String question, {
    int? courseUnitId,
    String? exerciseId,
  }) async {
    final body = <String, dynamic>{'question': question};
    if (courseUnitId != null) body['course_unit_id'] = courseUnitId;
    if (exerciseId != null) body['exercise_id'] = exerciseId;

    debugPrint('[chatQuery] → POST /ai-tutor/query body=$body');
    try {
      // O LLM pode demorar mais de 10 s — timeout alargado para 90 s
      final r = await _dio.post(
        '/ai-tutor/query',
        data: body,
        options: Options(receiveTimeout: const Duration(seconds: 90)),
      );
      debugPrint('[chatQuery] ✅ status=${r.statusCode} keys=${(r.data as Map?)?.keys.toList()}');
      return r.data as Map<String, dynamic>;
    } on DioException catch (e) {
      debugPrint('[chatQuery] ❌ tipo=${e.type} status=${e.response?.statusCode} '
          'body=${e.response?.data} msg=${e.message}');
      _log.severe('Falha no chat IA', e.response?.data);
      rethrow;
    } catch (e) {
      debugPrint('[chatQuery] ❌ erro inesperado: $e');
      rethrow;
    }
  }
}