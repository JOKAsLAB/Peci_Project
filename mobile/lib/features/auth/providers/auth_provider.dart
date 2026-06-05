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
      error: clearError ? null : (error ?? this.error),
      user: user ?? this.user,
      registrationSuccess: registrationSuccess ?? this.registrationSuccess,
    );
  }
}

class AuthNotifier extends Notifier<AuthState> {
  late final AuthRepository _repo;

  @override
  AuthState build() {
    _repo = ref.read(authRepositoryProvider);
    return const AuthState();
  }

  Future<void> login(String email, String password) async {
    print('[AUTH] Starting login for $email');
    state = state.copyWith(isLoading: true, clearError: true);

    try {
      final data = await _repo.login(email, password);

      if (data.containsKey('access_token')) {
        final token = data['access_token'] as String;
        print('[AUTH] Token received: ${token.substring(0, 20)}...');

        ref.read(authTokenProvider.notifier).setToken(token);
        print('[AUTH] Token stored, updating auth state');

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
    state = state.copyWith(isLoading: true, clearError: true, registrationSuccess: false);

    try {
      await _repo.register(name: name, email: email, password: password, role: role);
      // Ignore any token returned — account is SUSPENDED until email is verified.
      // User must verify email first, then log in normally.
      state = const AuthState(isLoading: false, registrationSuccess: true);
    } catch (e) {
      state = AuthState(
        isLoading: false,
        error: e.toString().replaceAll('Exception: ', ''),
      );
    }
  }

  void logout() {
    ref.read(authTokenProvider.notifier).setToken(null);
    state = const AuthState();
  }
}

final authProvider = NotifierProvider<AuthNotifier, AuthState>(AuthNotifier.new);
