import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'auth_storage.dart';

// Em emulador Android usa 10.0.2.2 em vez de localhost
//const _baseUrl = 'http://10.0.2.2:8000/api/v1';
//const _baseUrl = 'http://192.168.1.140:8000/api/v1';

const apiBaseUrl = 'http://193.136.92.69/api/v1';
const _baseUrl = apiBaseUrl;


final dioProvider = Provider<Dio>((ref) {
  final token = ref.watch(authTokenProvider); 
  
  final dio = Dio(BaseOptions(
    baseUrl: _baseUrl,
    connectTimeout: const Duration(seconds: 10),
    receiveTimeout: const Duration(seconds: 10),
    headers: {
      'Content-Type': 'application/json',
      'ngrok-skip-browser-warning': 'true',
      if (token != null && token.isNotEmpty)
        'Authorization': 'Bearer $token',
    },
  ));

  return dio;
});