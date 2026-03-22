import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../data/lesson_curriculum_selector.dart';
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
  Future<void> recordAttempt(String lessonId, TypingStats stats) async {
    final current = getProgress(lessonId);
    final updated = current.withNewAttempt(stats);
    _progressMap[lessonId] = updated;
    await _saveProgress(updated);
    await setLastLesson(lessonId);
    notifyListeners();
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
    await _prefs?.remove(_letterStatsKey);
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
    final current = getHighScore(gameId);
    if (score > current) {
      await _prefs?.setInt('${_prefix}highscore_$gameId', score);
      notifyListeners();
      return true;
    }
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

  // ─────────────────────────────────────────────────────────────────────────
  // Per-letter accuracy stats
  // ─────────────────────────────────────────────────────────────────────────

  String get _letterStatsKey => '${_prefix}letter_stats';

  /// Accumulated per-letter stats: char -> {correct: int, errors: int}
  Map<String, Map<String, int>> get letterStats {
    final raw = _prefs?.getString(_letterStatsKey);
    if (raw == null) return {};
    try {
      final decoded = jsonDecode(raw) as Map<String, dynamic>;
      return decoded.map((k, v) => MapEntry(
        k,
        (v as Map<String, dynamic>).map(
          (k2, v2) => MapEntry(k2, v2 as int),
        ),
      ));
    } catch (_) {
      return {};
    }
  }

  /// Record per-letter stats from a typing session.
  Future<void> recordLetterStats({
    required Map<String, int> correct,
    required Map<String, int> errors,
  }) async {
    final current = letterStats;

    for (final entry in correct.entries) {
      final ch = entry.key;
      current.putIfAbsent(ch, () => {'correct': 0, 'errors': 0});
      current[ch]!['correct'] = (current[ch]!['correct'] ?? 0) + entry.value;
    }
    for (final entry in errors.entries) {
      final ch = entry.key;
      current.putIfAbsent(ch, () => {'correct': 0, 'errors': 0});
      current[ch]!['errors'] = (current[ch]!['errors'] ?? 0) + entry.value;
    }

    await _prefs?.setString(_letterStatsKey, jsonEncode(current));
    notifyListeners();
  }

  /// Get the most error-prone letters sorted by error rate (descending).
  List<MapEntry<String, double>> get errorProneLetters {
    final stats = letterStats;
    final rates = <MapEntry<String, double>>[];
    for (final entry in stats.entries) {
      final c = entry.value['correct'] ?? 0;
      final e = entry.value['errors'] ?? 0;
      final total = c + e;
      if (total < 3) continue; // need enough data
      rates.add(MapEntry(entry.key, e / total * 100));
    }
    rates.sort((a, b) => b.value.compareTo(a.value));
    return rates;
  }

  /// Total typing sessions recorded (across all lessons)
  int get totalSessions {
    return _progressMap.values.fold(0, (sum, p) => sum + p.attempts);
  }

  /// WPM history across all lessons (from attempt history), most recent first.
  List<double> get wpmHistory {
    final all = <({DateTime time, double wpm})>[];
    for (final p in _progressMap.values) {
      for (final s in p.history) {
        if (s.wpm > 0) all.add((time: s.completedAt, wpm: s.wpm));
      }
    }
    all.sort((a, b) => a.time.compareTo(b.time));
    return all.map((e) => e.wpm).toList();
  }

  /// Accuracy history across all lessons, chronological.
  List<double> get accuracyHistory {
    final all = <({DateTime time, double accuracy})>[];
    for (final p in _progressMap.values) {
      for (final s in p.history) {
        all.add((time: s.completedAt, accuracy: s.accuracy));
      }
    }
    all.sort((a, b) => a.time.compareTo(b.time));
    return all.map((e) => e.accuracy).toList();
  }

  /// Total time spent typing (sum of all session durations).
  Duration get totalTypingTime {
    var ms = 0;
    for (final p in _progressMap.values) {
      for (final s in p.history) {
        ms += s.elapsed.inMilliseconds;
      }
    }
    return Duration(milliseconds: ms);
  }
}
