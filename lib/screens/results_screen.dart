import 'package:confetti/confetti.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../core/theme/app_colors.dart';
import '../data/lesson_curriculum.dart';
import '../models/lesson.dart';
import '../models/typing_stats.dart';
import '../widgets/star_rating.dart';
import 'typing_screen.dart';

/// Celebration screen shown after completing a lesson
class ResultsScreen extends StatefulWidget {
  final Lesson lesson;
  final TypingStats stats;

  const ResultsScreen({super.key, required this.lesson, required this.stats});

  @override
  State<ResultsScreen> createState() => _ResultsScreenState();
}

class _ResultsScreenState extends State<ResultsScreen>
    with TickerProviderStateMixin {
  late ConfettiController _confettiController;
  late AnimationController _slideController;
  late Animation<Offset> _slideAnimation;

  @override
  void initState() {
    super.initState();
    _confettiController = ConfettiController(
      duration: const Duration(seconds: 3),
    );
    _slideController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );
    _slideAnimation =
        Tween<Offset>(begin: const Offset(0, 0.5), end: Offset.zero).animate(
          CurvedAnimation(parent: _slideController, curve: Curves.easeOutCubic),
        );

    // Start animations
    Future.delayed(const Duration(milliseconds: 200), () {
      _slideController.forward();
      if (widget.stats.starRating >= 3) {
        _confettiController.play();
      }
    });
  }

  @override
  void dispose() {
    _confettiController.dispose();
    _slideController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: Stack(
        children: [
          SafeArea(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: SlideTransition(
                position: _slideAnimation,
                child: FadeTransition(
                  opacity: _slideController,
                  child: Column(
                    children: [
                      const SizedBox(height: 20),
                      _buildEmoji(),
                      const SizedBox(height: 16),
                      _buildTitle(),
                      const SizedBox(height: 8),
                      _buildEncouragement(),
                      const SizedBox(height: 24),
                      _buildStars(),
                      const SizedBox(height: 32),
                      _buildStatsGrid(),
                      const SizedBox(height: 32),
                      _buildActionButtons(context),
                      const SizedBox(height: 20),
                    ],
                  ),
                ),
              ),
            ),
          ),
          // Confetti
          Align(
            alignment: Alignment.topCenter,
            child: ConfettiWidget(
              confettiController: _confettiController,
              blastDirectionality: BlastDirectionality.explosive,
              shouldLoop: false,
              colors: [
                AppColors.primary,
                AppColors.secondary,
                AppColors.accent,
                AppColors.starFilled,
                AppColors.primaryLight,
                AppColors.accentLight,
              ],
              numberOfParticles: 30,
              gravity: 0.2,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmoji() {
    final emoji = switch (widget.stats.starRating) {
      5 => '🏆',
      4 => '🌟',
      3 => '🎉',
      2 => '👏',
      _ => '💪',
    };

    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0, end: 1),
      duration: const Duration(milliseconds: 600),
      curve: Curves.elasticOut,
      builder: (context, value, child) {
        return Transform.scale(
          scale: value,
          child: Text(emoji, style: const TextStyle(fontSize: 80)),
        );
      },
    );
  }

  Widget _buildTitle() {
    final title = switch (widget.stats.starRating) {
      5 => 'PERFECT!',
      4 => 'AWESOME!',
      3 => 'GREAT JOB!',
      2 => 'GOOD TRY!',
      _ => 'KEEP GOING!',
    };

    return Text(
      title,
      style: GoogleFonts.fredoka(
        fontSize: 40,
        fontWeight: FontWeight.w700,
        color: AppColors.primary,
      ),
    );
  }

  Widget _buildEncouragement() {
    return Text(
      widget.stats.encouragementMessage,
      style: GoogleFonts.nunito(fontSize: 18, color: AppColors.textSecondary),
      textAlign: TextAlign.center,
    );
  }

  Widget _buildStars() {
    return StarRating(rating: widget.stats.starRating, size: 48, animate: true);
  }

  Widget _buildStatsGrid() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          Text(
            widget.lesson.title,
            style: GoogleFonts.fredoka(
              fontSize: 20,
              fontWeight: FontWeight.w500,
              color: AppColors.textPrimary,
            ),
          ),
          const Divider(height: 24),
          Row(
            children: [
              Expanded(
                child: _ResultStat(
                  emoji: '🎯',
                  label: 'Accuracy',
                  value: '${widget.stats.accuracy.toStringAsFixed(1)}%',
                  color: widget.stats.accuracy >= 90
                      ? AppColors.correct
                      : widget.stats.accuracy >= 70
                      ? AppColors.warning
                      : AppColors.incorrect,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: _ResultStat(
                  emoji: '⚡',
                  label: 'Speed',
                  value: '${widget.stats.wpm.toStringAsFixed(0)} WPM',
                  color: AppColors.secondary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: _ResultStat(
                  emoji: '⏱️',
                  label: 'Time',
                  value: _formatDuration(widget.stats.elapsed),
                  color: AppColors.primary,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: _ResultStat(
                  emoji: '✅',
                  label: 'Correct',
                  value:
                      '${widget.stats.correctCharacters}/${widget.stats.totalCharacters}',
                  color: AppColors.correct,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildActionButtons(BuildContext context) {
    final nextLesson = LessonCurriculum.nextLesson(widget.lesson.id);

    return Column(
      children: [
        // Next lesson (primary action)
        if (nextLesson != null)
          Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: SizedBox(
              width: double.infinity,
              height: 56,
              child: ElevatedButton.icon(
                onPressed: () {
                  Navigator.of(context).pushReplacement(
                    MaterialPageRoute(
                      builder: (_) => TypingScreen(lesson: nextLesson),
                    ),
                  );
                },
                icon: const Icon(
                  Icons.arrow_forward_rounded,
                  color: Colors.white,
                ),
                label: Text(
                  'Next Lesson: ${nextLesson.emoji} ${nextLesson.title}',
                  style: GoogleFonts.fredoka(fontSize: 18, color: Colors.white),
                  overflow: TextOverflow.ellipsis,
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                  elevation: 4,
                  shadowColor: AppColors.primary.withValues(alpha: 0.4),
                ),
              ),
            ),
          ),
        // Try again
        SizedBox(
          width: double.infinity,
          height: 56,
          child: ElevatedButton.icon(
            onPressed: () {
              Navigator.of(context).pushReplacement(
                MaterialPageRoute(
                  builder: (_) => TypingScreen(lesson: widget.lesson),
                ),
              );
            },
            icon: const Icon(Icons.replay_rounded, color: Colors.white),
            label: Text(
              'Try Again',
              style: GoogleFonts.fredoka(fontSize: 20, color: Colors.white),
            ),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.secondary,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
            ),
          ),
        ),
        const SizedBox(height: 12),
        // Back to lessons
        SizedBox(
          width: double.infinity,
          height: 56,
          child: OutlinedButton.icon(
            onPressed: () {
              // Pop back to whatever screen launched the lesson (Home or LessonList)
              Navigator.of(context).pop();
            },
            icon: const Icon(Icons.home_rounded),
            label: Text('Back', style: GoogleFonts.fredoka(fontSize: 20)),
            style: OutlinedButton.styleFrom(
              foregroundColor: AppColors.primary,
              side: const BorderSide(color: AppColors.primary, width: 2),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
            ),
          ),
        ),
      ],
    );
  }

  String _formatDuration(Duration d) {
    final minutes = d.inMinutes.remainder(60).toString().padLeft(2, '0');
    final seconds = d.inSeconds.remainder(60).toString().padLeft(2, '0');
    return '$minutes:$seconds';
  }
}

class _ResultStat extends StatelessWidget {
  final String emoji;
  final String label;
  final String value;
  final Color color;

  const _ResultStat({
    required this.emoji,
    required this.label,
    required this.value,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        children: [
          Text(emoji, style: const TextStyle(fontSize: 24)),
          const SizedBox(height: 4),
          Text(
            value,
            style: GoogleFonts.fredoka(
              fontSize: 20,
              fontWeight: FontWeight.w600,
              color: color,
            ),
          ),
          Text(
            label,
            style: GoogleFonts.nunito(
              fontSize: 12,
              color: AppColors.textSecondary,
            ),
          ),
        ],
      ),
    );
  }
}
