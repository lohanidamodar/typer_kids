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
            .where((k) => k.startsWith('${_prefix}progress_'))
            .toList() ??
        [];
    for (final key in keys) {
      await _prefs?.remove(key);
    }
    await _prefs?.remove('${_prefix}last_lesson_id');
    notifyListeners();
  }
}
