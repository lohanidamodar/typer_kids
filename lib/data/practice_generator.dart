import '../models/lesson.dart';
import 'word_lists.dart';

/// Builds dynamic practice lessons that aren't part of the fixed curriculum,
/// such as the "Tricky Keys" lesson generated from a kid's most-missed keys.
class PracticeGenerator {
  PracticeGenerator._();

  /// Lesson ID used for the dynamically generated tricky-keys lesson.
  static const String trickyKeysLessonId = 'practice-tricky-keys';

  /// A key must be missed at least this many times to count as "tricky".
  static const int minErrorsToQualify = 3;

  /// At most this many keys are practiced in one tricky-keys lesson.
  static const int maxFocusKeys = 5;

  /// Build a short personalized lesson drilling the given keys.
  /// [keys] should be ordered most-missed first and must not be empty.
  static Lesson buildTrickyKeysLesson(List<String> keys) {
    assert(keys.isNotEmpty);
    final focus = keys.take(maxFocusKeys).toList();
    final label = focus.map((k) => k.toUpperCase()).join(' ');

    return Lesson(
      id: trickyKeysLessonId,
      title: 'Tricky Keys: $label',
      description: 'Extra practice for the keys you miss most.',
      category: LessonCategory.commonWords,
      difficulty: LessonDifficulty.beginner,
      orderIndex: 0,
      focusKeys: focus,
      emoji: '🔧',
      funTip: 'These keys trip you up the most — slow down and nail them!',
      exercises: _buildExercises(focus),
    );
  }

  static List<String> _buildExercises(List<String> focus) {
    final a = focus[0];
    final b = focus.length > 1 ? focus[1] : a;
    final c = focus.length > 2 ? focus[2] : b;

    final words = _wordsUsingKeys(focus);

    return [
      // Warm up on each key alone
      focus.map((k) => '$k$k$k').join(' '),
      // Alternate between the trickiest keys
      '$a$b $b$a $a$c $c$a $b$c',
      // Short bursts mixing all of them
      '${focus.join()} ${focus.reversed.join()}',
      // Real words containing the tricky keys
      if (words.isNotEmpty) words.take(5).join(' '),
      if (words.length > 5) words.skip(5).take(5).join(' '),
      // One more round to lock it in
      '$a$b$c $c$b$a ${focus.join(' ')}',
    ];
  }

  /// Find simple real words that contain the tricky keys, preferring words
  /// that contain more than one of them.
  static List<String> _wordsUsingKeys(List<String> keys) {
    final letters = keys.where((k) => RegExp(r'^[a-z]$').hasMatch(k)).toSet();
    if (letters.isEmpty) return const [];

    final pool = [...WordLists.easy, ...WordLists.medium];
    final scored = <(String, int)>[];
    for (final word in pool) {
      final hits = letters.where(word.contains).length;
      if (hits > 0) scored.add((word, hits));
    }
    scored.sort((x, y) => y.$2.compareTo(x.$2));
    return scored.take(10).map((e) => e.$1).toList();
  }
}
