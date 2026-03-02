import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';

import '../core/theme/app_colors.dart';
import '../providers/progress_provider.dart';

/// The main home screen with fun kid-friendly design
class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final FocusNode _focusNode = FocusNode();

  @override
  void dispose() {
    _focusNode.dispose();
    super.dispose();
  }

  void _handleKeyEvent(KeyEvent event) {
    if (event is! KeyDownEvent) return;
    final key = event.logicalKey;
    if (key == LogicalKeyboardKey.enter || key == LogicalKeyboardKey.space) {
      _startRecommendedLesson();
    } else if (key == LogicalKeyboardKey.keyL) {
      _openLessonList();
    } else if (key == LogicalKeyboardKey.keyS) {
      _openSettings();
    }
  }

  void _startRecommendedLesson() {
    final progress = Provider.of<ProgressProvider>(context, listen: false);
    final recommended = progress.recommendedLesson;
    context.push('/lesson/${recommended.id}');
  }

  void _openLessonList() {
    context.push('/lessons');
  }

  void _openSettings() {
    context.push('/settings');
  }

  @override
  Widget build(BuildContext context) {
    final progress = context.watch<ProgressProvider>();

    return Scaffold(
      body: KeyboardListener(
        focusNode: _focusNode,
        autofocus: true,
        onKeyEvent: _handleKeyEvent,
        child: SafeArea(
          child: LayoutBuilder(
            builder: (context, constraints) {
              final isWide = constraints.maxWidth > 700;
              final maxContentWidth = isWide ? 560.0 : constraints.maxWidth;

              return Center(
                child: SingleChildScrollView(
                  padding: EdgeInsets.symmetric(
                    horizontal: isWide ? 32 : 20,
                    vertical: 20,
                  ),
                  child: ConstrainedBox(
                    constraints: BoxConstraints(maxWidth: maxContentWidth),
                    child: Column(
                      children: [
                        const SizedBox(height: 12),
                        _buildHeader(context),
                        const SizedBox(height: 24),
                        _buildMascotGreeting(progress),
                        const SizedBox(height: 28),
                        _buildContinueButton(context, progress),
                        const SizedBox(height: 12),
                        _buildAllLessonsButton(context),
                        const SizedBox(height: 28),
                        _buildStatsCards(context, progress),
                        const SizedBox(height: 20),
                        _buildSettingsButton(context),
                        const SizedBox(height: 20),
                      ],
                    ),
                  ),
                ),
              );
            },
          ),
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    return Column(
      children: [
        const Text('🐵', style: TextStyle(fontSize: 56)),
        const SizedBox(height: 6),
        Text(
          'Typer Kids',
          style: GoogleFonts.fredoka(
            fontSize: 44,
            fontWeight: FontWeight.w700,
            color: AppColors.primary,
            shadows: [
              Shadow(
                color: AppColors.primaryDark.withValues(alpha: 0.3),
                offset: const Offset(2, 2),
                blurRadius: 4,
              ),
            ],
          ),
        ),
        const SizedBox(height: 2),
        Text(
          'Learn to Type with Fun! 🎮',
          style: GoogleFonts.fredoka(
            fontSize: 18,
            fontWeight: FontWeight.w400,
            color: AppColors.textSecondary,
          ),
        ),
      ],
    );
  }

  Widget _buildMascotGreeting(ProgressProvider progress) {
    String greeting;
    String emoji;
    if (progress.completedLessons == 0) {
      greeting = 'Ready for a typing adventure?';
      emoji = '🌟';
    } else if (progress.completionPercentage < 25) {
      greeting = 'Great start! Keep going!';
      emoji = '🚀';
    } else if (progress.completionPercentage < 50) {
      greeting = 'You\'re doing amazing!';
      emoji = '🎉';
    } else if (progress.completionPercentage < 75) {
      greeting = 'More than halfway there!';
      emoji = '💪';
    } else if (progress.completionPercentage < 100) {
      greeting = 'Almost a typing master!';
      emoji = '👑';
    } else {
      greeting = 'You did it! You\'re a pro!';
      emoji = '🏆';
    }

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            AppColors.primaryLight.withValues(alpha: 0.3),
            AppColors.secondaryLight.withValues(alpha: 0.3),
          ],
        ),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: AppColors.primaryLight.withValues(alpha: 0.5),
        ),
      ),
      child: Row(
        children: [
          Text(emoji, style: const TextStyle(fontSize: 36)),
          const SizedBox(width: 14),
          Expanded(
            child: Text(
              greeting,
              style: GoogleFonts.fredoka(
                fontSize: 20,
                fontWeight: FontWeight.w500,
                color: AppColors.textPrimary,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildContinueButton(BuildContext context, ProgressProvider progress) {
    final recommended = progress.recommendedLesson;
    final hasStarted = progress.hasStarted;
    final allDone = progress.allCompleted;

    String label;
    String sublabel;
    IconData icon;
    if (allDone) {
      label = 'Practice Again';
      sublabel = '${recommended.emoji} ${recommended.title}';
      icon = Icons.replay_rounded;
    } else if (hasStarted) {
      label = 'Continue';
      sublabel = '${recommended.emoji} ${recommended.title}';
      icon = Icons.play_arrow_rounded;
    } else {
      label = 'Start Learning!';
      sublabel = '${recommended.emoji} ${recommended.title}';
      icon = Icons.play_arrow_rounded;
    }

    return SizedBox(
      width: double.infinity,
      height: 80,
      child: ElevatedButton(
        onPressed: () => _startRecommendedLesson(),
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.primary,
          foregroundColor: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          elevation: 6,
          shadowColor: AppColors.primary.withValues(alpha: 0.4),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 32),
            const SizedBox(width: 10),
            Flexible(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        label,
                        style: GoogleFonts.fredoka(
                          fontSize: 22,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(width: 8),
                      _ShortcutBadge(label: 'Enter', light: true),
                    ],
                  ),
                  Text(
                    sublabel,
                    style: GoogleFonts.nunito(
                      fontSize: 13,
                      fontWeight: FontWeight.w500,
                      color: Colors.white.withValues(alpha: 0.85),
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAllLessonsButton(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      height: 52,
      child: OutlinedButton.icon(
        onPressed: () => _openLessonList(),
        icon: const Icon(Icons.list_rounded),
        label: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('All Lessons', style: GoogleFonts.fredoka(fontSize: 18)),
            const SizedBox(width: 8),
            _ShortcutBadge(label: 'L'),
          ],
        ),
        style: OutlinedButton.styleFrom(
          foregroundColor: AppColors.primary,
          side: const BorderSide(color: AppColors.primary, width: 2),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
        ),
      ),
    );
  }

  Widget _buildStatsCards(BuildContext context, ProgressProvider progress) {
    return Row(
      children: [
        Expanded(
          child: _StatCard(
            emoji: '⭐',
            label: 'Stars',
            value: '${progress.totalStars}',
            color: AppColors.starFilled,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _StatCard(
            emoji: '📚',
            label: 'Lessons',
            value: '${progress.completedLessons}/${progress.totalLessons}',
            color: AppColors.primary,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _StatCard(
            emoji: '🎯',
            label: 'Accuracy',
            value: progress.averageAccuracy > 0
                ? '${progress.averageAccuracy.toStringAsFixed(0)}%'
                : '--',
            color: AppColors.accent,
          ),
        ),
      ],
    );
  }

  Widget _buildSettingsButton(BuildContext context) {
    return TextButton.icon(
      onPressed: () => _openSettings(),
      icon: const Icon(Icons.settings_rounded, color: AppColors.textSecondary),
      label: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            'Settings',
            style: GoogleFonts.fredoka(
              fontSize: 16,
              color: AppColors.textSecondary,
            ),
          ),
          const SizedBox(width: 6),
          _ShortcutBadge(label: 'S'),
        ],
      ),
    );
  }
}

class _ShortcutBadge extends StatelessWidget {
  final String label;
  final bool light;
  const _ShortcutBadge({required this.label, this.light = false});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: light
            ? Colors.white.withValues(alpha: 0.25)
            : AppColors.primary.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(
          color: light
              ? Colors.white.withValues(alpha: 0.4)
              : AppColors.primary.withValues(alpha: 0.3),
        ),
      ),
      child: Text(
        label,
        style: GoogleFonts.robotoMono(
          fontSize: 11,
          fontWeight: FontWeight.w600,
          color: light ? Colors.white : AppColors.primary,
        ),
      ),
    );
  }
}

class _StatCard extends StatelessWidget {
  final String emoji;
  final String label;
  final String value;
  final Color color;

  const _StatCard({
    required this.emoji,
    required this.label,
    required this.value,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color.withValues(alpha: 0.3)),
        boxShadow: [
          BoxShadow(
            color: color.withValues(alpha: 0.1),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          Text(emoji, style: const TextStyle(fontSize: 26)),
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
              fontSize: 13,
              color: AppColors.textSecondary,
            ),
          ),
        ],
      ),
    );
  }
}
