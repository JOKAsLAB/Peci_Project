import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'api_client.dart';
import 'auth_storage.dart';

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

  Future<List<dynamic>> getExercises({int? idUc, String? topicName, String? difficulty}) async {
    final r = await _dio.get('/students/exercises', options: _auth, queryParameters: {
      if (idUc != null) 'id_uc': idUc,
      if (topicName != null) 'topic_name': topicName,
      if (difficulty != null) 'difficulty': difficulty,
    });
    return r.data;
  }

  Future<List<dynamic>> getStreak() async {
    final r = await _dio.get('/students/streak', options: _auth);
    return r.data;
  }
}

final studentRepositoryProvider = Provider<StudentRepository>((ref) {
  return StudentRepository(ref.watch(dioProvider), ref.watch(authTokenProvider));
});