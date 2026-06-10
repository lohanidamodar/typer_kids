import '../providers/progress_provider.dart';

/// An achievement badge a kid can earn through practice.
class AchievementBadge {
  final String id;
  final String emoji;
  final String title;
  final String description;

  const AchievementBadge({
    required this.id,
    required this.emoji,
    required this.title,
    required this.description,
  });
}

/// All badges and the rules for earning them. Badges are computed from
/// existing progress data, so nothing extra needs to be stored.
class Badges {
  Badges._();

  static const List<AchievementBadge> all = [
    AchievementBadge(
      id: 'first_lesson',
      emoji: '🐣',
      title: 'First Steps',
      description: 'Complete your first lesson',
    ),
    AchievementBadge(
      id: 'lessons_10',
      emoji: '📚',
      title: 'Bookworm',
      description: 'Complete 10 lessons',
    ),
    AchievementBadge(
      id: 'lessons_50',
      emoji: '🚀',
      title: 'Blast Off',
      description: 'Complete 50 lessons',
    ),
    AchievementBadge(
      id: 'lessons_100',
      emoji: '🏆',
      title: 'Champion',
      description: 'Complete 100 lessons',
    ),
    AchievementBadge(
      id: 'stars_50',
      emoji: '⭐',
      title: 'Star Catcher',
      description: 'Earn 50 stars',
    ),
    AchievementBadge(
      id: 'stars_200',
      emoji: '🌟',
      title: 'Superstar',
      description: 'Earn 200 stars',
    ),
    AchievementBadge(
      id: 'streak_3',
      emoji: '🔥',
      title: 'On Fire',
      description: 'Practice 3 days in a row',
    ),
    AchievementBadge(
      id: 'streak_7',
      emoji: '⚡',
      title: 'Unstoppable',
      description: 'Practice 7 days in a row',
    ),
    AchievementBadge(
      id: 'gamer',
      emoji: '🎮',
      title: 'Game On',
      description: 'Score points in any game',
    ),
    AchievementBadge(
      id: 'arcade_master',
      emoji: '🕹️',
      title: 'Arcade Master',
      description: 'Score points in all 4 games',
    ),
    AchievementBadge(
      id: 'accuracy_ace',
      emoji: '🎯',
      title: 'Sharp Shooter',
      description: '95%+ average accuracy over 10+ lessons',
    ),
  ];

  static const List<String> _gameIds = [
    'falling_words',
    'word_bubbles',
    'speed_chase',
    'defend_temple',
  ];

  /// Which badges the current profile has earned.
  static List<AchievementBadge> earned(ProgressProvider progress) {
    final highScores = progress.allHighScores;
    final gamesPlayed = _gameIds
        .where((id) => (highScores[id] ?? 0) > 0)
        .length;

    bool isEarned(String id) => switch (id) {
      'first_lesson' => progress.completedLessons >= 1,
      'lessons_10' => progress.completedLessons >= 10,
      'lessons_50' => progress.completedLessons >= 50,
      'lessons_100' => progress.completedLessons >= 100,
      'stars_50' => progress.totalStars >= 50,
      'stars_200' => progress.totalStars >= 200,
      'streak_3' => progress.currentStreak >= 3,
      'streak_7' => progress.currentStreak >= 7,
      'gamer' => gamesPlayed >= 1,
      'arcade_master' => gamesPlayed >= _gameIds.length,
      'accuracy_ace' =>
        progress.completedLessons >= 10 && progress.averageAccuracy >= 95,
      _ => false,
    };

    return all.where((b) => isEarned(b.id)).toList();
  }
}
