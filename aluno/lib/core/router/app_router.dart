import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../presentation/shell/main_shell.dart';
import '../../presentation/courses/courses_screen.dart';
import '../../presentation/gamification/exercise_feed_screen.dart';
import '../../presentation/profile/profile_screen.dart';
import '../../presentation/profile/settings_screen.dart';
import '../../presentation/auth/login_screen.dart';
import '../../presentation/auth/register_screen.dart';

// Chaves de navegação expostas de forma privada e robusta
final _rootNavigatorKey = GlobalKey<NavigatorState>(debugLabel: 'root');
final _shellNavigatorCoursesKey = GlobalKey<NavigatorState>(debugLabel: 'shell_courses');
final _shellNavigatorFeedKey = GlobalKey<NavigatorState>(debugLabel: 'shell_feed');
final _shellNavigatorProfileKey = GlobalKey<NavigatorState>(debugLabel: 'shell_profile');

/// Mock de estado de autenticação para a fase atual.
/// A ser substituído pelo AuthController real futuramente.
final mockAuthProvider = StateProvider<bool>((ref) => false);

/// Injeção do Router via Riverpod para garantir reatividade baseada em estado.
final routerProvider = Provider<GoRouter>((ref) {
  final isAuthenticated = ref.watch(mockAuthProvider);

  return GoRouter(
    navigatorKey: _rootNavigatorKey,
    initialLocation: '/courses',
    // Navigation Guard Centralizado
    redirect: (context, state) {
      final isGoingToAuth = state.matchedLocation == '/login' || state.matchedLocation == '/register';

      if (!isAuthenticated && !isGoingToAuth) {
        return '/login'; // Bloqueia acesso a ecrãs protegidos
      }
      if (isAuthenticated && isGoingToAuth) {
        return '/courses'; // Impede acesso ao login se já autenticado
      }
      return null;
    },
    routes: [
      GoRoute(
        path: '/login',
        parentNavigatorKey: _rootNavigatorKey,
        builder: (context, state) => const LoginScreen(),
      ),
      GoRoute(
        path: '/register',
        parentNavigatorKey: _rootNavigatorKey,
        builder: (context, state) => const RegisterScreen(),
      ),
      StatefulShellRoute.indexedStack(
        builder: (context, state, navigationShell) {
          return MainShell(navigationShell: navigationShell);
        },
        branches: [
          StatefulShellBranch(
            navigatorKey: _shellNavigatorCoursesKey,
            routes: [
              GoRoute(
                path: '/courses',
                builder: (context, state) => const CoursesScreen(),
              ),
            ],
          ),
          StatefulShellBranch(
            navigatorKey: _shellNavigatorFeedKey,
            routes: [
              GoRoute(
                path: '/feed',
                builder: (context, state) => const ExerciseFeedScreen(),
              ),
            ],
          ),
          StatefulShellBranch(
            navigatorKey: _shellNavigatorProfileKey,
            routes: [
              GoRoute(
                path: '/profile',
                builder: (context, state) => const ProfileScreen(),
              ),
            ],
          ),
        ],
      ),
      GoRoute(
        path: '/settings',
        parentNavigatorKey: _rootNavigatorKey,
        builder: (context, state) => const SettingsScreen(),
      ),
    ],
  );
});