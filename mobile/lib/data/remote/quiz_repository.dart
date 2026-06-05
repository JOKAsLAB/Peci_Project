import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'api_client.dart';

class QuizRepository {
  final Dio _dio;
  QuizRepository(this._dio);

  Future<Map<String, dynamic>> joinSession(String roomCode) async {
    final res = await _dio.post('/students/quizzes/join/${roomCode.toUpperCase()}');
    return Map<String, dynamic>.from(res.data);
  }

  Future<Map<String, dynamic>> submitAnswer(
    String sessionId,
    dynamic answer,
    int timeTakenMs,
  ) async {
    final res = await _dio.post(
      '/students/quizzes/sessions/$sessionId/answer',
      data: {'answer': answer, 'time_taken_ms': timeTakenMs},
    );
    return Map<String, dynamic>.from(res.data);
  }

  Future<Map<String, dynamic>> getLeaderboard(String sessionId) async {
    final res = await _dio.get('/students/quizzes/sessions/$sessionId/leaderboard');
    return Map<String, dynamic>.from(res.data);
  }
}

final quizRepositoryProvider = Provider<QuizRepository>((ref) {
  final dio = ref.watch(dioProvider);
  return QuizRepository(dio);
});
