/// Statistics for a single typing session/exercise
class TypingStats {
  final int totalCharacters;
  final int correctCharacters;
  final int incorrectCharacters;
  final Duration elapsed;
  final DateTime completedAt;

  const TypingStats({
    required this.totalCharacters,
    required this.correctCharacters,
    required this.incorrectCharacters,
    required this.elapsed,
    required this.completedAt,
  });

  /// Accuracy as a percentage (0-100)
  double get accuracy {
    if (totalCharacters == 0) return 0;
    return (correctCharacters / totalCharacters) * 100;
  }

  /// Words per minute (1 word = 5 characters)
  double get wpm {
    if (elapsed.inSeconds == 0) return 0;
    final minutes = elapsed.inSeconds / 60.0;
    final words = correctCharacters / 5.0;
    return words / minutes;
  }

  /// Star rating (1-5) based on accuracy
  int get starRating {
    if (accuracy >= 98) return 5;
    if (accuracy >= 95) return 4;
    if (accuracy >= 90) return 3;
    if (accuracy >= 80) return 2;
    return 1;
  }

  /// A fun message based on performance
  String get encouragementMessage {
    if (starRating == 5) return 'AMAZING! You\'re a typing superstar! 🌟';
    if (starRating == 4) return 'Great job! Almost perfect! 🎉';
    if (starRating == 3) return 'Good work! Keep practicing! 💪';
    if (starRating == 2) return 'Nice try! You\'re getting better! 🌱';
    return 'Keep going! Practice makes perfect! 🐢';
  }

  Map<String, dynamic> toJson() => {
    'totalCharacters': totalCharacters,
    'correctCharacters': correctCharacters,
    'incorrectCharacters': incorrectCharacters,
    'elapsedMs': elapsed.inMilliseconds,
    'completedAt': completedAt.toIso8601String(),
  };

  factory TypingStats.fromJson(Map<String, dynamic> json) => TypingStats(
    totalCharacters: json['totalCharacters'] as int,
    correctCharacters: json['correctCharacters'] as int,
    incorrectCharacters: json['incorrectCharacters'] as int,
    elapsed: Duration(milliseconds: json['elapsedMs'] as int),
    completedAt: DateTime.parse(json['completedAt'] as String),
  );
}
