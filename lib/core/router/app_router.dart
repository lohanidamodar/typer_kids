import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../data/lesson_curriculum_selector.dart';
import '../../models/typing_stats.dart';
import '../../providers/profile_provider.dart';
import '../../screens/games/falling_words_screen.dart';
import '../../screens/games/game_menu_screen.dart';
import '../../screens/home_screen.dart';
import '../../screens/lesson_list_screen.dart';
import '../../screens/profile_screen.dart';
import '../../screens/results_screen.dart';
import '../../screens/sandbox/sandbox_screen.dart';
import '../../screens/settings_screen.dart';
import '../../screens/typing_screen.dart';

/// Centralized router configuration using go_router.
///
/// Routes:
///   /profiles                  → Profile picker / manager
///   /                          → Home
///   /lessons                   → Lesson list
///   /lesson/:lessonId          → Typing screen (intro + practice)
///   /lesson/:lessonId/results  → Results / celebration screen
///   /games                   → Game menu
///   /games/falling-words      → Falling words game
///   /sandbox                  → Free practice sandbox
///   /settings                  → Settings
class AppRouter {
  AppRouter._();

  static final _rootNavigatorKey = GlobalKey<NavigatorState>();

  static GoRouter router(ProfileProvider profileProvider) => GoRouter(
    navigatorKey: _rootNavigatorKey,
    initialLocation: '/',
    refreshListenable: profileProvider,
    redirect: (context, state) {
      final profileProv = Provider.of<ProfileProvider>(context, listen: false);
      final hasActive = profileProv.hasActiveProfile;
      final onProfilePage = state.matchedLocation == '/profiles';

      // If no active profile and not already on profile page, redirect there
      if (!hasActive && !onProfilePage) return '/profiles';
      // If has active profile and on profile page, go home
      // (only on initial nav, not user-initiated)
      return null;
    },
    routes: [
      GoRoute(
        path: '/profiles',
        name: 'profiles',
        builder: (context, state) => const ProfileScreen(),
      ),
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
              if (lessonId == null || LessonCurriculum.byId(lessonId) == null) {
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
      GoRoute(
        path: '/games',
        name: 'games',
        builder: (context, state) => const GameMenuScreen(),
        routes: [
          GoRoute(
            path: 'falling-words',
            name: 'falling-words',
            parentNavigatorKey: _rootNavigatorKey,
            builder: (context, state) => const FallingWordsScreen(),
          ),
        ],
      ),
      GoRoute(
        path: '/sandbox',
        name: 'sandbox',
        builder: (context, state) => const SandboxScreen(),
      ),
    ],
    errorBuilder: (context, state) => const HomeScreen(),
  );
}
