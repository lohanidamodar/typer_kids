import 'package:flutter_test/flutter_test.dart';
import 'package:typer_kids/models/typing_stats.dart';
import 'package:typer_kids/models/lesson_progress.dart';
import 'package:typer_kids/data/lesson_curriculum.dart';
import 'package:typer_kids/models/lesson.dart';

void main() {
  group('TypingStats', () {
    test('calculates accuracy correctly', () {
      final stats = TypingStats(
        totalCharacters: 100,
        correctCharacters: 85,
        incorrectCharacters: 15,
        elapsed: Duration(minutes: 1),
        completedAt: DateTime(2025, 1, 1),
      );
      expect(stats.accuracy, 85.0);
    });

    test('calculates WPM correctly', () {
      final stats = TypingStats(
        totalCharacters: 50,
        correctCharacters: 50,
        incorrectCharacters: 0,
        elapsed: const Duration(minutes: 1),
        completedAt: DateTime.now(),
      );
      expect(stats.wpm, 10.0); // 50 chars / 5 = 10 words / 1 min
    });

    test('star rating based on accuracy', () {
      TypingStats makeStats(int correct, int total) => TypingStats(
        totalCharacters: total,
        correctCharacters: correct,
        incorrectCharacters: total - correct,
        elapsed: const Duration(minutes: 1),
        completedAt: DateTime.now(),
      );

      expect(makeStats(100, 100).starRating, 5); // 100%
      expect(makeStats(96, 100).starRating, 4); // 96%
      expect(makeStats(91, 100).starRating, 3); // 91%
      expect(makeStats(82, 100).starRating, 2); // 82%
      expect(makeStats(65, 100).starRating, 1); // 65%
    });
  });

  group('LessonProgress', () {
    test('records new attempt and updates bests', () {
      var progress = const LessonProgress(lessonId: 'test-01');
      expect(progress.completed, false);
      expect(progress.attempts, 0);

      final stats = TypingStats(
        totalCharacters: 50,
        correctCharacters: 48,
        incorrectCharacters: 2,
        elapsed: const Duration(seconds: 30),
        completedAt: DateTime.now(),
      );

      progress = progress.withNewAttempt(stats);
      expect(progress.completed, true);
      expect(progress.attempts, 1);
      expect(progress.bestAccuracy, stats.accuracy);
      expect(progress.bestWpm, stats.wpm);
    });

    test('serializes and deserializes correctly', () {
      final original = LessonProgress(
        lessonId: 'hr-01',
        completed: true,
        bestStarRating: 4,
        bestAccuracy: 95.5,
        bestWpm: 25.0,
        attempts: 3,
      );

      final encoded = original.encode();
      final decoded = LessonProgress.decode(encoded);

      expect(decoded.lessonId, original.lessonId);
      expect(decoded.completed, original.completed);
      expect(decoded.bestStarRating, original.bestStarRating);
      expect(decoded.bestAccuracy, original.bestAccuracy);
      expect(decoded.bestWpm, original.bestWpm);
      expect(decoded.attempts, original.attempts);
    });
  });

  group('LessonCurriculum', () {
    test('has lessons in all categories', () {
      for (final category in LessonCategory.values) {
        final lessons = LessonCurriculum.byCategory(category);
        expect(
          lessons.isNotEmpty,
          true,
          reason: '${category.displayName} should have lessons',
        );
      }
    });

    test('all lessons have unique IDs', () {
      final ids = LessonCurriculum.allLessons.map((l) => l.id).toSet();
      expect(ids.length, LessonCurriculum.allLessons.length);
    });

    test('all lessons have exercises', () {
      for (final lesson in LessonCurriculum.allLessons) {
        expect(
          lesson.exercises.isNotEmpty,
          true,
          reason: '${lesson.title} should have exercises',
        );
      }
    });

    test('finds lesson by ID', () {
      final lesson = LessonCurriculum.byId('hr-01');
      expect(lesson, isNotNull);
      expect(lesson!.title, 'Meet F and J');
    });
  });
}
