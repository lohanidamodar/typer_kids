/// Represents a category/group of typing lessons
enum LessonCategory {
  homeRow('Home Row', '🏠'),
  topRow('Top Row', '⬆️'),
  bottomRow('Bottom Row', '⬇️'),
  numbers('Numbers', '🔢'),
  commonWords('Words', '📝'),
  sentences('Sentences', '📖');

  const LessonCategory(this.displayName, this.emoji);
  final String displayName;
  final String emoji;
}

/// Difficulty level for a lesson
enum LessonDifficulty {
  beginner('Beginner', '🌱'),
  intermediate('Intermediate', '🌿'),
  advanced('Advanced', '🌳');

  const LessonDifficulty(this.displayName, this.emoji);
  final String displayName;
  final String emoji;
}

/// A single typing lesson
class Lesson {
  final String id;
  final String title;
  final String description;
  final LessonCategory category;
  final LessonDifficulty difficulty;
  final int orderIndex;

  /// The characters/keys this lesson focuses on
  final List<String> focusKeys;

  /// The content to type - each string is one exercise line
  final List<String> exercises;

  /// Fun fact or tip shown before a lesson starts
  final String funTip;

  /// Emoji/icon for this lesson
  final String emoji;

  const Lesson({
    required this.id,
    required this.title,
    required this.description,
    required this.category,
    required this.difficulty,
    required this.orderIndex,
    required this.focusKeys,
    required this.exercises,
    this.funTip = '',
    this.emoji = '⌨️',
  });

  /// The minimum accuracy percentage to pass this lesson
  int get passingAccuracy => switch (difficulty) {
    LessonDifficulty.beginner => 70,
    LessonDifficulty.intermediate => 80,
    LessonDifficulty.advanced => 90,
  };
}
