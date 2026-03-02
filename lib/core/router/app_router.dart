import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../data/lesson_curriculum.dart';
import '../../models/typing_stats.dart';
import '../../screens/home_screen.dart';
import '../../screens/lesson_list_screen.dart';
import '../../screens/results_screen.dart';
import '../../screens/settings_screen.dart';
import '../../screens/typing_screen.dart';

/// Centralized router configuration using go_router.
///
/// Routes:
///   /                          → Home
///   /lessons                   → Lesson list
///   /lesson/:lessonId          → Typing screen (intro + practice)
///   /lesson/:lessonId/results  → Results / celebration screen
///   /settings                  → Settings
class AppRouter {
  AppRouter._();

  static final _rootNavigatorKey = GlobalKey<NavigatorState>();

  static final GoRouter router = GoRouter(
    navigatorKey: _rootNavigatorKey,
    initialLocation: '/',
    routes: [
      GoRoute(
        path: '/',
        name: 'home',
        builder: (context, state) => const HomeScreen(),
      ),
      GoRoute(
        path: '/lessons',
        name: 'lessons',
        builder: (context, state) => const LessonListScreen(),
      ),
      GoRoute(
        path: '/lesson/:lessonId',
        name: 'lesson',
        builder: (context, state) {
          final lessonId = state.pathParameters['lessonId']!;
          final lesson = LessonCurriculum.byId(lessonId);
          if (lesson == null) {
            // Invalid lesson ID — show home
            return const HomeScreen();
          }
          return TypingScreen(lesson: lesson);
        },
        routes: [
          GoRoute(
            path: 'results',
            name: 'results',
            parentNavigatorKey: _rootNavigatorKey,
            redirect: (context, state) {
              final lessonId = state.pathParameters['lessonId'];
              final stats = state.extra as TypingStats?;
              // If there are no stats (e.g. page refresh on web), redirect
              // to the lesson so the user can play it again.
              if (lessonId == null ||
                  LessonCurriculum.byId(lessonId) == null) {
                return '/';
              }
              if (stats == null) {
                return '/lesson/$lessonId';
              }
              return null; // allow
            },
            builder: (context, state) {
              final lessonId = state.pathParameters['lessonId']!;
              final lesson = LessonCurriculum.byId(lessonId)!;
              final stats = state.extra as TypingStats;
              return ResultsScreen(lesson: lesson, stats: stats);
            },
          ),
        ],
      ),
      GoRoute(
        path: '/settings',
        name: 'settings',
        builder: (context, state) => const SettingsScreen(),
      ),
    ],
    errorBuilder: (context, state) => const HomeScreen(),
  );
}
