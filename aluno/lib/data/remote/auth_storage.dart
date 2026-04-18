import 'package:flutter_riverpod/flutter_riverpod.dart';

// Guarda o token JWT em memória
// (pode migrar para flutter_secure_storage mais tarde)
class AuthTokenNotifier extends Notifier<String?> {
  @override
  String? build() => null;

  void setToken(String? token) => state = token;
}

final authTokenProvider = NotifierProvider<AuthTokenNotifier, String?>(AuthTokenNotifier.new);
