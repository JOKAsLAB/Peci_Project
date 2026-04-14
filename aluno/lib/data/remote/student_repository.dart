import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'api_client.dart';
import 'auth_storage.dart';
import '../models/topic.dart';
import '../models/exercise.dart';

class StudentRepository {
  final Dio _dio;
  final String? _token;

  StudentRepository(this._dio, this._token);

  Options get _auth => Options(headers: {'Authorization': 'Bearer $_token'});

  Future<Map<String, dynamic>> getProfile() async {
    final r = await _dio.get('/students/me', options: _auth);
    return r.data;
  }

  Future<List<dynamic>> getCourseUnits() async {
    final r = await _dio.get('/students/course-units', options: _auth);
    return r.data;
  }

  Future<List<Exercise>> getExercises(
      {int? idUc, String? topicName, String? difficulty}) async {
    final r =
        await _dio.get('/students/exercises', options: _auth, queryParameters: {
      if (idUc != null) 'id_uc': idUc,
      if (topicName != null) 'topic_name': topicName,
      if (difficulty != null) 'difficulty': difficulty,
    });
    return (r.data as List).map((e) => Exercise.fromJson(e)).toList();
  }

  Future<List<Topic>> getTopics(int courseId) async {
    final response = await _dio.get(
      '/students/topics',
      options: _auth,
      queryParameters: {'id_uc': courseId},
    );

    return (response.data as List).map((e) => Topic.fromJson(e)).toList();
  }

  Future<List<dynamic>> getStreak() async {
    final r = await _dio.get('/students/streak', options: _auth);
    return r.data;
  }
}

final studentRepositoryProvider = Provider<StudentRepository>((ref) {
  return StudentRepository(
      ref.watch(dioProvider), ref.watch(authTokenProvider));
});

final courseListProvider =
    FutureProvider<List<Map<String, dynamic>>>((ref) async {
  final units = await ref.watch(studentRepositoryProvider).getCourseUnits();
  return units.cast<Map<String, dynamic>>();
});
