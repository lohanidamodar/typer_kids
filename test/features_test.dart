import 'package:flutter_test/flutter_test.dart';
import 'package:typer_kids/data/badges.dart';
import 'package:typer_kids/data/lesson_curriculum_comprehensive.dart';
import 'package:typer_kids/data/practice_generator.dart';
import 'package:typer_kids/data/sentence_lists.dart';
import 'package:typer_kids/data/story_content.dart';
import 'package:typer_kids/data/word_lists.dart';
import 'package:typer_kids/models/lesson.dart';
import 'package:typer_kids/models/typing_stats.dart';
import 'package:typer_kids/providers/progress_provider.dart';
import 'package:typer_kids/providers/typing_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  group('ComprehensiveLessonCurriculum', () {
    test('all lessons have unique IDs and non-empty exercises', () {
      final lessons = ComprehensiveLessonCurriculum.allLessons;
      final ids = lessons.map((l) => l.id).toSet();
      expect(ids.length, lessons.length);
      for (final lesson in lessons) {
        expect(lesson.exercises, isNotEmpty, reason: lesson.title);
        for (final exercise in lesson.exercises) {
          expect(exercise.trim(), isNotEmpty, reason: lesson.title);
        }
      }
    });

    test('includes the new punctuation, fun theme, and story lessons', () {
      final titles =
          ComprehensiveLessonCurriculum.allLessons.map((l) => l.title).toSet();
      expect(titles, contains('Question Marks'));
      expect(titles, contains('Excited Lines'));
      expect(titles, contains('Apostrophes'));
      expect(titles, contains('Punctuation Mix'));
      expect(titles, contains('Fun: Dinosaurs'));
      expect(titles, contains('Fun: Robots'));
      expect(titles, contains('Story: The Lost Kite'));
      expect(titles, contains('Story: The Moon Trip'));
    });

    test('no exercise repeats the same word back to back', () {
      for (final lesson in ComprehensiveLessonCurriculum.allLessons) {
        // Drills intentionally repeat short tokens and 6-letter alphabet
        // runs; only flag repeated long words, which indicate copy/paste
        // mistakes (e.g. "encyclopedia encyclopedia").
        for (final exercise in lesson.exercises) {
          final words = exercise.split(' ');
          for (var i = 1; i < words.length; i++) {
            if (words[i].length >= 8) {
              expect(
                words[i] == words[i - 1],
                isFalse,
                reason: '"${lesson.title}" repeats "${words[i]}"',
              );
            }
          }
        }
      }
    });
  });

  group('TypingProvider', () {
    Lesson makeLesson(List<String> exercises) => Lesson(
      id: 'test',
      title: 'Test',
      description: '',
      category: LessonCategory.homeRow,
      difficulty: LessonDifficulty.beginner,
      orderIndex: 1,
      focusKeys: const [],
      exercises: exercises,
    );

    test('tracks errors per expected key', () {
      final provider = TypingProvider();
      provider.startLesson(makeLesson(['ab a']));

      expect(provider.onKeyPressed('a'), true);
      expect(provider.onKeyPressed('x'), false); // expected 'b'
      expect(provider.onKeyPressed('x'), false); // expected ' ' (not counted)
      expect(provider.onKeyPressed('b'), false); // expected 'a'

      final stats = provider.stats;
      expect(stats.errorsByKey, {'b': 1, 'a': 1});
      expect(stats.correctCharacters, 1);
      expect(stats.incorrectCharacters, 3);
      provider.dispose();
    });

    test('ignores input while paused', () {
      final provider = TypingProvider();
      provider.startLesson(makeLesson(['abc']));
      provider.pause();
      expect(provider.onKeyPressed('a'), isNull);
      provider.resume();
      expect(provider.onKeyPressed('a'), true);
      provider.dispose();
    });
  });

  group('TypingStats errorsByKey serialization', () {
    test('round-trips through JSON', () {
      final stats = TypingStats(
        totalCharacters: 10,
        correctCharacters: 8,
        incorrectCharacters: 2,
        elapsed: const Duration(seconds: 20),
        completedAt: DateTime(2026, 1, 1),
        errorsByKey: const {'r': 2, 'q': 1},
      );
      final decoded = TypingStats.fromJson(stats.toJson());
      expect(decoded.errorsByKey, {'r': 2, 'q': 1});
    });

    test('handles missing errorsByKey for old saved data', () {
      final decoded = TypingStats.fromJson({
        'totalCharacters': 5,
        'correctCharacters': 5,
        'incorrectCharacters': 0,
        'elapsedMs': 1000,
        'completedAt': '2026-01-01T00:00:00.000',
      });
      expect(decoded.errorsByKey, isEmpty);
    });
  });

  group('PracticeGenerator', () {
    test('builds a tricky keys lesson with drills and real words', () {
      final lesson = PracticeGenerator.buildTrickyKeysLesson(['r', 'u', 'b']);
      expect(lesson.id, PracticeGenerator.trickyKeysLessonId);
      expect(lesson.focusKeys, ['r', 'u', 'b']);
      expect(lesson.exercises, isNotEmpty);
      // Every exercise should involve at least one of the tricky keys
      for (final exercise in lesson.exercises) {
        expect(
          exercise.contains('r') ||
              exercise.contains('u') ||
              exercise.contains('b'),
          isTrue,
          reason: exercise,
        );
      }
    });

    test('caps the focus keys at the maximum', () {
      final lesson = PracticeGenerator.buildTrickyKeysLesson(
        ['a', 'b', 'c', 'd', 'e', 'f', 'g'],
      );
      expect(lesson.focusKeys.length, PracticeGenerator.maxFocusKeys);
    });

    test('handles punctuation-only tricky keys', () {
      final lesson = PracticeGenerator.buildTrickyKeysLesson([';', '.']);
      expect(lesson.exercises, isNotEmpty);
      for (final exercise in lesson.exercises) {
        expect(exercise.trim(), isNotEmpty);
      }
    });
  });

  group('Streak computation', () {
    String day(int y, int m, int d) =>
        '${y.toString().padLeft(4, '0')}-'
        '${m.toString().padLeft(2, '0')}-'
        '${d.toString().padLeft(2, '0')}';

    test('counts consecutive days ending today', () {
      final days = {day(2026, 6, 8), day(2026, 6, 9), day(2026, 6, 10)};
      expect(ProgressProvider.computeStreak(days, DateTime(2026, 6, 10)), 3);
    });

    test('streak ending yesterday still counts', () {
      final days = {day(2026, 6, 8), day(2026, 6, 9)};
      expect(ProgressProvider.computeStreak(days, DateTime(2026, 6, 10)), 2);
    });

    test('gap of more than one day breaks the streak', () {
      final days = {day(2026, 6, 5), day(2026, 6, 6), day(2026, 6, 10)};
      expect(ProgressProvider.computeStreak(days, DateTime(2026, 6, 10)), 1);
    });

    test('no practice days means no streak', () {
      expect(ProgressProvider.computeStreak({}, DateTime(2026, 6, 10)), 0);
    });

    test('spans month boundaries', () {
      final days = {day(2026, 5, 30), day(2026, 5, 31), day(2026, 6, 1)};
      expect(ProgressProvider.computeStreak(days, DateTime(2026, 6, 1)), 3);
    });
  });

  group('ProgressProvider', () {
    TypingStats statsWith({
      required int correct,
      required int total,
      Map<String, int> errors = const {},
    }) => TypingStats(
      totalCharacters: total,
      correctCharacters: correct,
      incorrectCharacters: total - correct,
      elapsed: const Duration(seconds: 30),
      completedAt: DateTime.now(),
      errorsByKey: errors,
    );

    test('only passing attempts complete a lesson', () async {
      SharedPreferences.setMockInitialValues({});
      final provider = ProgressProvider();
      await provider.init();

      final lesson = ComprehensiveLessonCurriculum.allLessons.first;
      expect(lesson.difficulty, LessonDifficulty.beginner);

      // 50% accuracy — below the 70% beginner threshold
      await provider.recordAttempt(lesson, statsWith(correct: 10, total: 20));
      expect(provider.getProgress(lesson.id).completed, false);
      expect(provider.getProgress(lesson.id).attempts, 1);

      // 90% accuracy — passes
      await provider.recordAttempt(lesson, statsWith(correct: 18, total: 20));
      expect(provider.getProgress(lesson.id).completed, true);
    });

    test('aggregates tricky keys across attempts', () async {
      SharedPreferences.setMockInitialValues({});
      final provider = ProgressProvider();
      await provider.init();

      final lesson = ComprehensiveLessonCurriculum.allLessons.first;
      await provider.recordAttempt(
        lesson,
        statsWith(correct: 15, total: 20, errors: {'r': 2, 'q': 1}),
      );
      await provider.recordAttempt(
        lesson,
        statsWith(correct: 15, total: 20, errors: {'r': 1, 'b': 4}),
      );

      expect(provider.keyErrorCounts, {'r': 3, 'q': 1, 'b': 4});
      // Only keys with >= minErrorsToQualify misses, most-missed first
      expect(provider.trickyKeys, ['b', 'r']);
      expect(provider.trickyKeysLesson, isNotNull);
      expect(provider.trickyKeysLesson!.focusKeys, ['b', 'r']);
    });

    test('passing the tricky keys lesson clears practiced keys', () async {
      SharedPreferences.setMockInitialValues({});
      final provider = ProgressProvider();
      await provider.init();

      final lesson = ComprehensiveLessonCurriculum.allLessons.first;
      await provider.recordAttempt(
        lesson,
        statsWith(correct: 15, total: 20, errors: {'r': 5}),
      );
      expect(provider.trickyKeys, ['r']);

      final tricky = provider.trickyKeysLesson!;
      await provider.recordAttempt(
        tricky,
        statsWith(correct: 19, total: 20), // 95% — clears the keys
      );
      expect(provider.trickyKeys, isEmpty);
      // The dynamic lesson never appears in lesson progress
      expect(provider.getProgress(tricky.id).attempts, 0);
    });

    test('records practice days and computes a streak', () async {
      SharedPreferences.setMockInitialValues({});
      final provider = ProgressProvider();
      await provider.init();
      expect(provider.currentStreak, 0);

      final lesson = ComprehensiveLessonCurriculum.allLessons.first;
      await provider.recordAttempt(lesson, statsWith(correct: 18, total: 20));
      expect(provider.currentStreak, 1);
    });

    test('resetAll clears streak and tricky keys', () async {
      SharedPreferences.setMockInitialValues({});
      final provider = ProgressProvider();
      await provider.init();

      final lesson = ComprehensiveLessonCurriculum.allLessons.first;
      await provider.recordAttempt(
        lesson,
        statsWith(correct: 15, total: 20, errors: {'z': 9}),
      );
      expect(provider.currentStreak, 1);
      expect(provider.trickyKeys, isNotEmpty);

      await provider.resetAll();
      expect(provider.currentStreak, 0);
      expect(provider.trickyKeys, isEmpty);
      expect(provider.completedLessons, 0);
    });
  });

  group('Badges', () {
    test('no badges on a fresh profile', () async {
      SharedPreferences.setMockInitialValues({});
      final provider = ProgressProvider();
      await provider.init();
      expect(Badges.earned(provider), isEmpty);
    });

    test('earns first lesson and gamer badges', () async {
      SharedPreferences.setMockInitialValues({});
      final provider = ProgressProvider();
      await provider.init();

      final lesson = ComprehensiveLessonCurriculum.allLessons.first;
      await provider.recordAttempt(
        lesson,
        TypingStats(
          totalCharacters: 20,
          correctCharacters: 20,
          incorrectCharacters: 0,
          elapsed: const Duration(seconds: 30),
          completedAt: DateTime.now(),
        ),
      );
      await provider.recordScore('falling_words', 150);

      final earned = Badges.earned(provider).map((b) => b.id).toList();
      expect(earned, contains('first_lesson'));
      expect(earned, contains('gamer'));
      expect(earned, isNot(contains('arcade_master')));
    });

    test('arcade master requires a score in every game', () async {
      SharedPreferences.setMockInitialValues({});
      final provider = ProgressProvider();
      await provider.init();

      for (final gameId in Badges.gameIds) {
        expect(
          Badges.earned(provider).map((b) => b.id),
          isNot(contains('arcade_master')),
        );
        await provider.recordScore(gameId, 100);
      }
      expect(
        Badges.earned(provider).map((b) => b.id),
        contains('arcade_master'),
      );
    });
  });

  group('SentenceLists', () {
    test('every pool has plenty of non-empty sentences', () {
      for (final d in ContentDifficulty.values) {
        final pool = SentenceLists.forDifficulty(d);
        expect(pool.length, greaterThanOrEqualTo(15), reason: d.label);
        for (final sentence in pool) {
          expect(sentence.trim(), isNotEmpty);
          // No double spaces — they'd be invisible but block progress
          expect(sentence.contains('  '), isFalse, reason: sentence);
        }
      }
    });

    test('easy sentences avoid shifted characters', () {
      for (final sentence in SentenceLists.easy) {
        expect(
          RegExp(r'^[a-z0-9 .,]+$').hasMatch(sentence),
          isTrue,
          reason: sentence,
        );
      }
    });

    test('shuffledFor returns the whole pool', () {
      final shuffled = SentenceLists.shuffledFor(ContentDifficulty.medium);
      expect(shuffled.toSet(), SentenceLists.medium.toSet());
    });
  });

  group('StoryContent', () {
    test('every passage is well-formed', () {
      for (final d in ContentDifficulty.values) {
        final pool = StoryContent.forDifficulty(d);
        expect(pool.length, greaterThanOrEqualTo(10), reason: d.label);
        for (final passage in pool) {
          expect(passage.title.trim(), isNotEmpty);
          expect(passage.source.trim(), isNotEmpty);
          expect(passage.text.trim(), isNotEmpty, reason: passage.title);
          // Double spaces are invisible on screen but block typing progress
          expect(
            passage.text.contains('  '),
            isFalse,
            reason: '${passage.title} contains a double space',
          );
          // Only characters a kid can actually type on a US keyboard
          // (curly quotes or em-dashes would block progress forever)
          expect(
            RegExp(r'''^[a-zA-Z0-9 .,;:!?'"\-()]+$''').hasMatch(passage.text),
            isTrue,
            reason: '${passage.title} contains untypable characters',
          );
        }
      }
    });
  });
}
