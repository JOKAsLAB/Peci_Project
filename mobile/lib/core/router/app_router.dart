import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../features/auth/providers/auth_provider.dart';

import '../../presentation/shell/main_shell.dart';
import '../../presentation/courses/courses_screen.dart';
import '../../presentation/gamification/exercise_feed_screen.dart';
import '../../presentation/profile/profile_screen.dart';
import '../../presentation/profile/settings_screen.dart';
import '../../presentation/profile/stats_screen.dart';
import '../../presentation/auth/login_screen.dart';
import '../../presentation/auth/register_screen.dart';
import '../../presentation/quiz/quiz_screen.dart';
import '../../presentation/quiz/quiz_game_screen.dart';

final _rootNavigatorKey = GlobalKey<NavigatorState>(debugLabel: 'root');
final _shellNavigatorCoursesKey = GlobalKey<NavigatorState>(debugLabel: 'shell_courses');
final _shellNavigatorFeedKey = GlobalKey<NavigatorState>(debugLabel: 'shell_feed');
final _shellNavigatorProfileKey = GlobalKey<NavigatorState>(debugLabel: 'shell_profile');
final _shellNavigatorQuizKey = GlobalKey<NavigatorState>(debugLabel: 'shell_quiz');

final routerProvider = Provider<GoRouter>((ref) {
  final goRouter = GoRouter(
    navigatorKey: _rootNavigatorKey,
    initialLocation: '/courses',
    redirect: (context, state) {
      final authState = ref.read(authProvider);
      final isAuthenticated = authState.isAuthenticated;
      final isGoingToAuth = state.matchedLocation == '/login' || state.matchedLocation == '/register';

      if (!isAuthenticated && !isGoingToAuth) return '/login';
      if (isAuthenticated && isGoingToAuth) return '/courses';
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
            navigatorKey: _shellNavigatorQuizKey,
            routes: [
              GoRoute(
                path: '/quiz',
                builder: (context, state) => const QuizScreen(),
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
        path: '/quiz/game/:sessionId',
        parentNavigatorKey: _rootNavigatorKey,
        builder: (context, state) {
          final sessionId = state.pathParameters['sessionId']!;
          final sessionData = (state.extra as Map<String, dynamic>?) ?? {};
          return QuizGameScreen(sessionId: sessionId, sessionData: sessionData);
        },
      ),
      GoRoute(
        path: '/settings',
        parentNavigatorKey: _rootNavigatorKey,
        builder: (context, state) => const SettingsScreen(),
      ),
      GoRoute(
        path: '/stats',
        parentNavigatorKey: _rootNavigatorKey,
        builder: (context, state) => const StatsScreen(),
      ),
    ],
  );

  ref.listen<AuthState>(authProvider, (previous, next) {
    goRouter.refresh();
  });

  ref.onDispose(goRouter.dispose);

  return goRouter;
});