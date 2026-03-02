import 'dart:convert';

import 'typing_stats.dart';

/// Tracks a user's progress on a specific lesson
class LessonProgress {
  final String lessonId;
  final bool completed;
  final int bestStarRating;
  final double bestAccuracy;
  final double bestWpm;
  final int attempts;
  final List<TypingStats> history;

  const LessonProgress({
    required this.lessonId,
    this.completed = false,
    this.bestStarRating = 0,
    this.bestAccuracy = 0,
    this.bestWpm = 0,
    this.attempts = 0,
    this.history = const [],
  });

  /// Creates an updated progress after a new attempt
  LessonProgress withNewAttempt(TypingStats stats) {
    final newHistory = [...history, stats];
    return LessonProgress(
      lessonId: lessonId,
      completed: completed || stats.starRating >= 1,
      bestStarRating: stats.starRating > bestStarRating
          ? stats.starRating
          : bestStarRating,
      bestAccuracy: stats.accuracy > bestAccuracy
          ? stats.accuracy
          : bestAccuracy,
      bestWpm: stats.wpm > bestWpm ? stats.wpm : bestWpm,
      attempts: attempts + 1,
      history: newHistory,
    );
  }

  Map<String, dynamic> toJson() => {
    'lessonId': lessonId,
    'completed': completed,
    'bestStarRating': bestStarRating,
    'bestAccuracy': bestAccuracy,
    'bestWpm': bestWpm,
    'attempts': attempts,
    'history': history.map((s) => s.toJson()).toList(),
  };

  factory LessonProgress.fromJson(Map<String, dynamic> json) => LessonProgress(
    lessonId: json['lessonId'] as String,
    completed: json['completed'] as bool? ?? false,
    bestStarRating: json['bestStarRating'] as int? ?? 0,
    bestAccuracy: (json['bestAccuracy'] as num?)?.toDouble() ?? 0,
    bestWpm: (json['bestWpm'] as num?)?.toDouble() ?? 0,
    attempts: json['attempts'] as int? ?? 0,
    history:
        (json['history'] as List<dynamic>?)
            ?.map((e) => TypingStats.fromJson(e as Map<String, dynamic>))
            .toList() ??
        [],
  );

  String encode() => jsonEncode(toJson());

  factory LessonProgress.decode(String source) =>
      LessonProgress.fromJson(jsonDecode(source) as Map<String, dynamic>);
}
