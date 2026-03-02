import '../models/lesson.dart';
import 'lesson_curriculum.dart' as classic;
import 'lesson_curriculum_comprehensive.dart' as comprehensive;

/// Switch this enum value to choose which curriculum the app uses.
enum CurriculumVariant { classic, comprehensive }

class CurriculumConfig {
  CurriculumConfig._();

  // Toggle here:
  static const CurriculumVariant activeVariant =
      CurriculumVariant.comprehensive;
}

/// Facade used by the app.
///
/// This keeps the rest of the code unchanged while allowing easy switching
/// between curriculum datasets.
class LessonCurriculum {
  LessonCurriculum._();

  static List<Lesson> get allLessons =>
      switch (CurriculumConfig.activeVariant) {
        CurriculumVariant.classic => classic.LessonCurriculum.allLessons,
        CurriculumVariant.comprehensive =>
          comprehensive.ComprehensiveLessonCurriculum.allLessons,
      };

  static List<LessonCategory> get categoryOrder =>
      switch (CurriculumConfig.activeVariant) {
        CurriculumVariant.classic => classic.LessonCurriculum.categoryOrder,
        CurriculumVariant.comprehensive =>
          comprehensive.ComprehensiveLessonCurriculum.categoryOrder,
      };

  static List<Lesson> byCategory(LessonCategory category) =>
      switch (CurriculumConfig.activeVariant) {
        CurriculumVariant.classic => classic.LessonCurriculum.byCategory(
          category,
        ),
        CurriculumVariant.comprehensive =>
          comprehensive.ComprehensiveLessonCurriculum.byCategory(category),
      };

  static List<Lesson> byDifficulty(LessonDifficulty difficulty) =>
      allLessons.where((lesson) => lesson.difficulty == difficulty).toList();

  static Lesson? byId(String id) => switch (CurriculumConfig.activeVariant) {
    CurriculumVariant.classic => classic.LessonCurriculum.byId(id),
    CurriculumVariant.comprehensive =>
      comprehensive.ComprehensiveLessonCurriculum.byId(id),
  };

  static Lesson? nextLesson(String currentLessonId) =>
      switch (CurriculumConfig.activeVariant) {
        CurriculumVariant.classic => classic.LessonCurriculum.nextLesson(
          currentLessonId,
        ),
        CurriculumVariant.comprehensive =>
          comprehensive.ComprehensiveLessonCurriculum.nextLesson(
            currentLessonId,
          ),
      };
}
