import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../data/remote/auth_repository.dart';
import '../../../data/remote/auth_storage.dart';

class AuthState {
  final bool isAuthenticated;
  final bool isLoading;
  final String? error;
  final Map<String, dynamic>? user;
  final bool registrationSuccess;

  const AuthState({
    this.isAuthenticated = false,
    this.isLoading = false,
    this.error,
    this.user,
    this.registrationSuccess = false,
  });

  AuthState copyWith({
    bool? isAuthenticated,
    bool? isLoading,
    String? error,
    bool clearError = false,
    Map<String, dynamic>? user,
    bool? registrationSuccess,
  }) {
    return AuthState(
      isAuthenticated: isAuthenticated ?? this.isAuthenticated,
      isLoading: isLoading ?? this.isLoading,
      // Só limpa o erro se clearError=true ou se foi passado um erro novo
      error: clearError ? null : (error ?? this.error),
      user: user ?? this.user,
      registrationSuccess: registrationSuccess ?? this.registrationSuccess,
    );
  }
}

class AuthNotifier extends StateNotifier<AuthState> {
  final AuthRepository _repo;
  final Ref _ref;

  AuthNotifier(this._repo, this._ref) : super(const AuthState());

  Future<void> login(String email, String password) async {
    print('[AUTH] Starting login for $email');
    state = state.copyWith(isLoading: true, clearError: true);

    try {
      final data = await _repo.login(email, password);

      if (data.containsKey('access_token')) {
        final token = data['access_token'] as String;
        print('[AUTH] Token received: ${token.substring(0, 20)}...');

        // Guarda o token ANTES de atualizar o state
        // Usa _ref.read para não criar dependência reativa
        _ref.read(authTokenProvider.notifier).state = token;
        print('[AUTH] Token stored, updating auth state');

        // Atualiza o state num único passo atómico
        state = AuthState(
          isAuthenticated: true,
          isLoading: false,
          user: data['user'] as Map<String, dynamic>?,
        );
        print('[AUTH] Auth state updated: authenticated=true');
      } else {
        throw Exception("Resposta da API inválida: falta 'access_token'");
      }
    } catch (e) {
      print('[AUTH] Exception during login: $e');
      state = AuthState(
        isLoading: false,
        error: e.toString().replaceAll('Exception: ', ''),
      );
    }
  }

  Future<void> register({
    required String name,
    required String email,
    required String password,
    required String role,
  }) async {
    print('[AUTH] Starting register for $email as $role');
    state = state.copyWith(isLoading: true, clearError: true, registrationSuccess: false);

    try {
      final data = await _repo.register(
        name: name,
        email: email,
        password: password,
        role: role,
      );
      print('[AUTH] Register response received');

      final token = data['access_token'] as String?;

      if (token != null) {
        print('[AUTH] Token received, storing');
        _ref.read(authTokenProvider.notifier).state = token;
        print('[AUTH] Token stored, updating auth state');

        state = AuthState(
          isAuthenticated: true,
          isLoading: false,
          user: data['user'] as Map<String, dynamic>?,
        );
        print('[AUTH] Auth state updated: authenticated=true');
      } else {
        // Sem token — conta criada mas requer aprovação
        print('[AUTH] No token - registration requires approval');
        state = AuthState(
          isLoading: false,
          registrationSuccess: true,
        );
      }
    } catch (e) {
      print('[AUTH] Exception during register: $e');
      state = AuthState(
        isLoading: false,
        error: e.toString().replaceAll('Exception: ', ''),
      );
    }
  }

  void logout() {
    _ref.read(authTokenProvider.notifier).state = null;
    state = const AuthState();
  }
}

final authProvider = StateNotifierProvider<AuthNotifier, AuthState>((ref) {
  return AuthNotifier(
    ref.read(authRepositoryProvider), // ref.read evita que mudanças no token invalide este provider
    ref,
  );
});