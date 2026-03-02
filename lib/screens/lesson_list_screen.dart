import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';

import '../core/theme/app_colors.dart';
import '../data/lesson_curriculum.dart';
import '../models/lesson.dart';
import '../providers/progress_provider.dart';
import '../widgets/star_rating.dart';
import 'typing_screen.dart';

/// Screen showing all available lessons grouped by category
class LessonListScreen extends StatelessWidget {
  const LessonListScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Choose a Lesson'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: LessonCurriculum.categoryOrder.map((category) {
          return _CategorySection(category: category);
        }).toList(),
      ),
    );
  }
}

class _CategorySection extends StatelessWidget {
  final LessonCategory category;

  const _CategorySection({required this.category});

  Color get _categoryColor => switch (category) {
    LessonCategory.homeRow => AppColors.categoryHomeRow,
    LessonCategory.topRow => AppColors.categoryTopRow,
    LessonCategory.bottomRow => AppColors.categoryBottomRow,
    LessonCategory.numbers => AppColors.categoryNumbers,
    LessonCategory.commonWords => AppColors.categoryWords,
    LessonCategory.sentences => AppColors.categorySentences,
  };

  @override
  Widget build(BuildContext context) {
    final lessons = LessonCurriculum.byCategory(category);
    if (lessons.isEmpty) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 8),
        // Category header
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                _categoryColor.withValues(alpha: 0.8),
                _categoryColor.withValues(alpha: 0.5),
              ],
            ),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Row(
            children: [
              Text(category.emoji, style: const TextStyle(fontSize: 24)),
              const SizedBox(width: 8),
              Text(
                category.displayName,
                style: GoogleFonts.fredoka(
                  fontSize: 22,
                  fontWeight: FontWeight.w600,
                  color: Colors.white,
                ),
              ),
              const Spacer(),
              _CategoryProgress(category: category),
            ],
          ),
        ),
        const SizedBox(height: 8),
        // Lesson cards in a grid
        ...lessons.map(
          (lesson) =>
              _LessonCard(lesson: lesson, categoryColor: _categoryColor),
        ),
        const SizedBox(height: 16),
      ],
    );
  }
}

class _CategoryProgress extends StatelessWidget {
  final LessonCategory category;

  const _CategoryProgress({required this.category});

  @override
  Widget build(BuildContext context) {
    final progress = context.watch<ProgressProvider>();
    final lessons = LessonCurriculum.byCategory(category);
    final completed = lessons
        .where((l) => progress.getProgress(l.id).completed)
        .length;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.3),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        '$completed/${lessons.length}',
        style: GoogleFonts.fredoka(
          fontSize: 14,
          fontWeight: FontWeight.w600,
          color: Colors.white,
        ),
      ),
    );
  }
}

class _LessonCard extends StatelessWidget {
  final Lesson lesson;
  final Color categoryColor;

  const _LessonCard({required this.lesson, required this.categoryColor});

  @override
  Widget build(BuildContext context) {
    final progress = context.watch<ProgressProvider>();
    final lessonProgress = progress.getProgress(lesson.id);
    final isUnlocked = progress.isLessonUnlocked(lesson.id);

    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: isUnlocked
              ? () {
                  Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (_) => TypingScreen(lesson: lesson),
                    ),
                  );
                }
              : null,
          borderRadius: BorderRadius.circular(14),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: isUnlocked ? Colors.white : Colors.grey.shade100,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(
                color: lessonProgress.completed
                    ? categoryColor.withValues(alpha: 0.5)
                    : isUnlocked
                    ? Colors.grey.shade300
                    : Colors.grey.shade200,
                width: lessonProgress.completed ? 2 : 1,
              ),
              boxShadow: isUnlocked
                  ? [
                      BoxShadow(
                        color: categoryColor.withValues(alpha: 0.1),
                        blurRadius: 8,
                        offset: const Offset(0, 2),
                      ),
                    ]
                  : null,
            ),
            child: Row(
              children: [
                // Lesson emoji / lock icon
                Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    color: isUnlocked
                        ? categoryColor.withValues(alpha: 0.15)
                        : Colors.grey.shade200,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Center(
                    child: isUnlocked
                        ? Text(
                            lesson.emoji,
                            style: const TextStyle(fontSize: 24),
                          )
                        : Icon(
                            Icons.lock_rounded,
                            color: Colors.grey.shade400,
                            size: 24,
                          ),
                  ),
                ),
                const SizedBox(width: 12),
                // Lesson info
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        lesson.title,
                        style: GoogleFonts.fredoka(
                          fontSize: 17,
                          fontWeight: FontWeight.w500,
                          color: isUnlocked
                              ? AppColors.textPrimary
                              : Colors.grey.shade500,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        lesson.description,
                        style: GoogleFonts.nunito(
                          fontSize: 13,
                          color: isUnlocked
                              ? AppColors.textSecondary
                              : Colors.grey.shade400,
                        ),
                      ),
                      if (lessonProgress.completed) ...[
                        const SizedBox(height: 4),
                        Row(
                          children: [
                            StarRating(
                              rating: lessonProgress.bestStarRating,
                              size: 18,
                            ),
                            const SizedBox(width: 8),
                            Text(
                              '${lessonProgress.bestAccuracy.toStringAsFixed(0)}%',
                              style: GoogleFonts.nunito(
                                fontSize: 12,
                                fontWeight: FontWeight.w700,
                                color: AppColors.primary,
                              ),
                            ),
                            const SizedBox(width: 6),
                            Text(
                              '${lessonProgress.bestWpm.toStringAsFixed(0)} WPM',
                              style: GoogleFonts.nunito(
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                                color: AppColors.textSecondary,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ],
                  ),
                ),
                // Right arrow or check
                if (isUnlocked)
                  lessonProgress.completed
                      ? Icon(
                          Icons.check_circle_rounded,
                          color: categoryColor,
                          size: 28,
                        )
                      : Icon(
                          Icons.arrow_forward_ios_rounded,
                          color: Colors.grey.shade400,
                          size: 20,
                        ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
