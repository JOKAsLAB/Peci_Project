import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../features/auth/providers/auth_provider.dart';

import '../../presentation/shell/main_shell.dart';
import '../../presentation/courses/courses_screen.dart';
import '../../presentation/gamification/exercise_feed_screen.dart';
import '../../presentation/profile/profile_screen.dart';
import '../../presentation/profile/settings_screen.dart';
import '../../presentation/auth/login_screen.dart';
import '../../presentation/auth/register_screen.dart';

final _rootNavigatorKey = GlobalKey<NavigatorState>(debugLabel: 'root');
final _shellNavigatorCoursesKey = GlobalKey<NavigatorState>(debugLabel: 'shell_courses');
final _shellNavigatorFeedKey = GlobalKey<NavigatorState>(debugLabel: 'shell_feed');
final _shellNavigatorProfileKey = GlobalKey<NavigatorState>(debugLabel: 'shell_profile');

final routerProvider = Provider<GoRouter>((ref) {
  // A magia está aqui: o router "ouve" o authProvider
  final authState = ref.watch(authProvider);
  print('[ROUTER] Auth state changed: isAuthenticated=${authState.isAuthenticated}, error=${authState.error}');

  return GoRouter(
    navigatorKey: _rootNavigatorKey,
    initialLocation: '/courses',
    // O redirect corre sempre que o authState mudar
    redirect: (context, state) {
      final isAuthenticated = authState.isAuthenticated;
      final isGoingToAuth = state.matchedLocation == '/login' || state.matchedLocation == '/register';
      
      print('[ROUTER REDIRECT] location=${state.matchedLocation}, authenticated=$isAuthenticated, goingToAuth=$isGoingToAuth');

      // Se não está logado e tenta aceder a algo que não seja login/register -> vai para login
      if (!isAuthenticated && !isGoingToAuth) {
        print('[ROUTER REDIRECT] -> Redirecting to /login (not authenticated)');
        return '/login';
      }

      // Se já está logado e tenta ir ao login -> vai para a home (courses)
      if (isAuthenticated && isGoingToAuth) {
        print('[ROUTER REDIRECT] -> Redirecting to /courses (already authenticated)');
        return '/courses';
      }

      print('[ROUTER REDIRECT] -> No redirect needed');
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