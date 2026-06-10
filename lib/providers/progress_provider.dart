import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../data/lesson_curriculum_selector.dart';
import '../data/practice_generator.dart';
import '../models/lesson.dart';
import '../models/lesson_progress.dart';
import '../models/typing_stats.dart';

/// Manages overall progress across all lessons, scoped per profile.
///
/// All SharedPreferences keys are prefixed with `profile_{profileId}_` so that
/// each profile's data is stored separately.
class ProgressProvider extends ChangeNotifier {
  final Map<String, LessonProgress> _progressMap = {};
  SharedPreferences? _prefs;
  bool _isLoaded = false;
  String? _lastLessonId;
  String _profileId = '';

  bool get isLoaded => _isLoaded;

  /// Key prefix for the current profile
  String get _prefix => 'profile_${_profileId}_';

  /// The lesson the user should practice next (recommended flow)
  Lesson get recommendedLesson {
    // If there's a last lesson that isn't completed, resume it
    if (_lastLessonId != null) {
      final lastProgress = getProgress(_lastLessonId!);
      if (!lastProgress.completed) {
        final lesson = LessonCurriculum.byId(_lastLessonId!);
        if (lesson != null) return lesson;
      }
      // If last lesson is completed, recommend the next one
      final next = LessonCurriculum.nextLesson(_lastLessonId!);
      if (next != null) return next;
    }

    // Otherwise find the first incomplete lesson in order
    for (final lesson in LessonCurriculum.allLessons) {
      final progress = getProgress(lesson.id);
      if (!progress.completed) return lesson;
    }

    // All done — return first lesson for replay
    return LessonCurriculum.allLessons.first;
  }

  /// Whether the user has started any lessons
  bool get hasStarted => _progressMap.values.any((p) => p.attempts > 0);

  /// Whether every lesson is completed
  bool get allCompleted =>
      completedLessons >= LessonCurriculum.allLessons.length;

  /// Save which lesson the user last practiced
  Future<void> setLastLesson(String lessonId) async {
    _lastLessonId = lessonId;
    await _prefs?.setString('${_prefix}last_lesson_id', lessonId);
  }

  /// Initialize and load saved progress for the given profile
  Future<void> init({String profileId = ''}) async {
    _prefs = await SharedPreferences.getInstance();
    _profileId = profileId;
    _progressMap.clear();
    _lastLessonId = null;
    _loadProgress();
    _lastLessonId = _prefs?.getString('${_prefix}last_lesson_id');
    _isLoaded = true;
    notifyListeners();
  }

  /// Switch to a different profile's data (reloads progress from prefs)
  Future<void> switchProfile(String profileId) async {
    _profileId = profileId;
    _progressMap.clear();
    _lastLessonId = null;
    _loadProgress();
    _lastLessonId = _prefs?.getString('${_prefix}last_lesson_id');
    notifyListeners();
  }

  void _loadProgress() {
    final keys =
        _prefs?.getKeys().where((k) => k.startsWith('${_prefix}progress_')) ??
        [];
    for (final key in keys) {
      final json = _prefs?.getString(key);
      if (json != null) {
        try {
          final progress = LessonProgress.decode(json);
          _progressMap[progress.lessonId] = progress;
        } catch (_) {
          // Ignore corrupted data
        }
      }
    }
  }

  Future<void> _saveProgress(LessonProgress progress) async {
    await _prefs?.setString(
      '${_prefix}progress_${progress.lessonId}',
      progress.encode(),
    );
  }

  /// Get progress for a specific lesson
  LessonProgress getProgress(String lessonId) {
    return _progressMap[lessonId] ?? LessonProgress(lessonId: lessonId);
  }

  /// Record a completed exercise attempt
  Future<void> recordAttempt(Lesson lesson, TypingStats stats) async {
    await _recordKeyErrors(stats.errorsByKey);
    await _recordPracticeDay();

    if (lesson.id == PracticeGenerator.trickyKeysLessonId) {
      // Dynamic practice lesson — not part of the curriculum, so don't store
      // lesson progress. A solid run clears the practiced keys instead.
      if (stats.accuracy >= 90) {
        await _clearKeyErrors(lesson.focusKeys);
      }
      notifyListeners();
      return;
    }

    final passed = stats.accuracy >= lesson.passingAccuracy;
    final current = getProgress(lesson.id);
    final updated = current.withNewAttempt(stats, passed: passed);
    _progressMap[lesson.id] = updated;
    await _saveProgress(updated);
    await setLastLesson(lesson.id);
    notifyListeners();
  }

  // ─────────────────────────────────────────────────────────────────────────
  // Daily practice streak
  // ─────────────────────────────────────────────────────────────────────────

  static String _dayKey(DateTime day) =>
      '${day.year.toString().padLeft(4, '0')}-'
      '${day.month.toString().padLeft(2, '0')}-'
      '${day.day.toString().padLeft(2, '0')}';

  List<String> get _practiceDays =>
      _prefs?.getStringList('${_prefix}practice_days') ?? const [];

  Future<void> _recordPracticeDay() async {
    final today = _dayKey(DateTime.now());
    final days = List<String>.from(_practiceDays);
    if (!days.contains(today)) {
      days.add(today);
      // Keep the list bounded — only recent days matter for the streak.
      if (days.length > 400) days.removeRange(0, days.length - 400);
      await _prefs?.setStringList('${_prefix}practice_days', days);
    }
  }

  /// Consecutive days practiced, ending today (or yesterday if the kid
  /// hasn't practiced yet today, so the streak isn't shown as broken).
  int get currentStreak =>
      computeStreak(_practiceDays.toSet(), DateTime.now());

  @visibleForTesting
  static int computeStreak(Set<String> practicedDays, DateTime today) {
    if (practicedDays.isEmpty) return 0;
    var day = DateTime(today.year, today.month, today.day);
    // A streak may end yesterday and still count — today isn't over yet.
    if (!practicedDays.contains(_dayKey(day))) {
      day = day.subtract(const Duration(days: 1));
    }
    var streak = 0;
    while (practicedDays.contains(_dayKey(day))) {
      streak++;
      day = day.subtract(const Duration(days: 1));
    }
    return streak;
  }

  // ─────────────────────────────────────────────────────────────────────────
  // Tricky keys — cumulative per-key error counts
  // ─────────────────────────────────────────────────────────────────────────

  /// Cumulative miss counts per expected key for the current profile.
  Map<String, int> get keyErrorCounts {
    final json = _prefs?.getString('${_prefix}key_errors');
    if (json == null) return const {};
    try {
      return (jsonDecode(json) as Map<String, dynamic>).map(
        (k, v) => MapEntry(k, v as int),
      );
    } catch (_) {
      return const {};
    }
  }

  Future<void> _recordKeyErrors(Map<String, int> errors) async {
    if (errors.isEmpty) return;
    final counts = Map<String, int>.from(keyErrorCounts);
    errors.forEach((key, count) {
      counts[key] = (counts[key] ?? 0) + count;
    });
    await _prefs?.setString('${_prefix}key_errors', jsonEncode(counts));
  }

  Future<void> _clearKeyErrors(List<String> keys) async {
    final counts = Map<String, int>.from(keyErrorCounts);
    counts.removeWhere((key, _) => keys.contains(key));
    await _prefs?.setString('${_prefix}key_errors', jsonEncode(counts));
  }

  /// The keys this kid misses most (most-missed first), for extra practice.
  /// Only keys with a few misses qualify — one slip isn't a pattern.
  List<String> get trickyKeys {
    final entries = keyErrorCounts.entries
        .where((e) => e.value >= PracticeGenerator.minErrorsToQualify)
        .toList()
      ..sort((a, b) => b.value.compareTo(a.value));
    return entries
        .take(PracticeGenerator.maxFocusKeys)
        .map((e) => e.key)
        .toList();
  }

  /// A dynamically generated lesson targeting the current tricky keys,
  /// or null if there aren't any yet.
  Lesson? get trickyKeysLesson {
    final keys = trickyKeys;
    if (keys.isEmpty) return null;
    return PracticeGenerator.buildTrickyKeysLesson(keys);
  }

  /// Check if a lesson is unlocked (previous lesson completed or first lesson)
  bool isLessonUnlocked(String lessonId) {
    final lesson = LessonCurriculum.byId(lessonId);
    if (lesson == null) return false;

    // First lesson in any category is always unlocked
    final categoryLessons = LessonCurriculum.byCategory(lesson.category);
    if (categoryLessons.isEmpty) return false;
    if (categoryLessons.first.id == lessonId) return true;

    // Otherwise, the previous lesson in the category must be completed
    final index = categoryLessons.indexWhere((l) => l.id == lessonId);
    if (index <= 0) return true;
    final prevLesson = categoryLessons[index - 1];
    return getProgress(prevLesson.id).completed;
  }

  /// Total stars earned
  int get totalStars {
    return _progressMap.values.fold(0, (sum, p) => sum + p.bestStarRating);
  }

  /// Maximum possible stars
  int get maxStars => LessonCurriculum.allLessons.length * 5;

  /// Total lessons completed
  int get completedLessons {
    return _progressMap.values.where((p) => p.completed).length;
  }

  /// Total lessons available
  int get totalLessons => LessonCurriculum.allLessons.length;

  /// Overall completion percentage
  double get completionPercentage {
    if (totalLessons == 0) return 0;
    return (completedLessons / totalLessons) * 100;
  }

  /// Average accuracy across all attempted lessons
  double get averageAccuracy {
    final attempted = _progressMap.values.where((p) => p.attempts > 0);
    if (attempted.isEmpty) return 0;
    return attempted.fold(0.0, (sum, p) => sum + p.bestAccuracy) /
        attempted.length;
  }

  /// Average WPM across all attempted lessons
  double get averageWpm {
    final attempted = _progressMap.values.where((p) => p.attempts > 0);
    if (attempted.isEmpty) return 0;
    return attempted.fold(0.0, (sum, p) => sum + p.bestWpm) / attempted.length;
  }

  /// Reset all progress for the current profile
  Future<void> resetAll() async {
    _progressMap.clear();
    _lastLessonId = null;
    final keys =
        _prefs
            ?.getKeys()
            .where(
              (k) =>
                  k.startsWith('${_prefix}progress_') ||
                  k.startsWith('${_prefix}highscore_'),
            )
            .toList() ??
        [];
    for (final key in keys) {
      await _prefs?.remove(key);
    }
    await _prefs?.remove('${_prefix}last_lesson_id');
    await _prefs?.remove('${_prefix}practice_days');
    await _prefs?.remove('${_prefix}key_errors');
    notifyListeners();
  }

  // ─────────────────────────────────────────────────────────────────────────
  // High scores — per-game, per-profile
  // ─────────────────────────────────────────────────────────────────────────

  /// Get the high score for a specific game.
  int getHighScore(String gameId) {
    return _prefs?.getInt('${_prefix}highscore_$gameId') ?? 0;
  }

  /// Record a score for a game. Returns true if it's a new high score.
  Future<bool> recordScore(String gameId, int score) async {
    await _recordPracticeDay();
    final current = getHighScore(gameId);
    if (score > current) {
      await _prefs?.setInt('${_prefix}highscore_$gameId', score);
      notifyListeners();
      return true;
    }
    // Still notify — the practice streak may have changed.
    notifyListeners();
    return false;
  }

  /// Get all high scores as a map of gameId → score.
  Map<String, int> get allHighScores {
    final result = <String, int>{};
    final prefix = '${_prefix}highscore_';
    final keys = _prefs?.getKeys().where((k) => k.startsWith(prefix)) ?? [];
    for (final key in keys) {
      final gameId = key.substring(prefix.length);
      result[gameId] = _prefs?.getInt(key) ?? 0;
    }
    return result;
  }
}
