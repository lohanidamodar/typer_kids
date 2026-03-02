import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';

import '../core/theme/app_colors.dart';
import '../providers/progress_provider.dart';
import 'lesson_list_screen.dart';
import 'settings_screen.dart';

/// The main home screen with fun kid-friendly design
class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final progress = context.watch<ProgressProvider>();

    return Scaffold(
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            children: [
              const SizedBox(height: 20),
              // App title with fun design
              _buildHeader(context),
              const SizedBox(height: 32),
              // Mascot
              _buildMascotGreeting(progress),
              const SizedBox(height: 32),
              // Stats summary
              _buildStatsCards(context, progress),
              const SizedBox(height: 32),
              // Start button
              _buildStartButton(context),
              const SizedBox(height: 16),
              // Settings
              _buildSettingsButton(context),
              const SizedBox(height: 32),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    return Column(
      children: [
        Text('🐵', style: const TextStyle(fontSize: 64)),
        const SizedBox(height: 8),
        Text(
          'Typer Kids',
          style: GoogleFonts.fredoka(
            fontSize: 48,
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
        const SizedBox(height: 4),
        Text(
          'Learn to Type with Fun! 🎮',
          style: GoogleFonts.fredoka(
            fontSize: 20,
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
      padding: const EdgeInsets.all(20),
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
          Text(emoji, style: const TextStyle(fontSize: 40)),
          const SizedBox(width: 16),
          Expanded(
            child: Text(
              greeting,
              style: GoogleFonts.fredoka(
                fontSize: 22,
                fontWeight: FontWeight.w500,
                color: AppColors.textPrimary,
              ),
            ),
          ),
        ],
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

  Widget _buildStartButton(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      height: 64,
      child: ElevatedButton(
        onPressed: () {
          Navigator.of(
            context,
          ).push(MaterialPageRoute(builder: (_) => const LessonListScreen()));
        },
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
            const Icon(Icons.play_arrow_rounded, size: 32),
            const SizedBox(width: 8),
            Text(
              'Start Typing!',
              style: GoogleFonts.fredoka(
                fontSize: 24,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSettingsButton(BuildContext context) {
    return TextButton.icon(
      onPressed: () {
        Navigator.of(
          context,
        ).push(MaterialPageRoute(builder: (_) => const SettingsScreen()));
      },
      icon: const Icon(Icons.settings_rounded, color: AppColors.textSecondary),
      label: Text(
        'Settings',
        style: GoogleFonts.fredoka(
          fontSize: 16,
          color: AppColors.textSecondary,
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
      padding: const EdgeInsets.all(16),
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
          Text(emoji, style: const TextStyle(fontSize: 28)),
          const SizedBox(height: 4),
          Text(
            value,
            style: GoogleFonts.fredoka(
              fontSize: 22,
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
