import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'auth_storage.dart';

// Em emulador Android usa 10.0.2.2 em vez de localhost
const _baseUrl = 'http://10.0.2.2:8000/api/v1';

// Este provider recria o Dio quando o token muda
final dioProvider = Provider<Dio>((ref) {
  final token = ref.watch(authTokenProvider); // Observa mudanças no token
  
  final dio = Dio(BaseOptions(
    baseUrl: _baseUrl,
    connectTimeout: const Duration(seconds: 10),
    receiveTimeout: const Duration(seconds: 10),
    headers: {
      'Content-Type': 'application/json',
      // Adiciona o token aos headers se existir
      if (token != null && token.isNotEmpty)
        'Authorization': 'Bearer $token',
    },
  ));

  return dio;
});