import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';

import '../core/theme/app_colors.dart';
import '../data/practice_generator.dart';
import '../providers/profile_provider.dart';
import '../providers/progress_provider.dart';
import '../widgets/home/activity_card.dart';
import '../widgets/home/badges_panel.dart';
import '../widgets/home/stat_card.dart';
import '../widgets/shortcut_badge.dart';

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
    } else if (key == LogicalKeyboardKey.keyP) {
      _switchProfile();
    } else if (key == LogicalKeyboardKey.keyG) {
      _openGames();
    } else if (key == LogicalKeyboardKey.keyF) {
      _openSandbox();
    } else if (key == LogicalKeyboardKey.keyT) {
      _openTypingTest();
    } else if (key == LogicalKeyboardKey.keyK) {
      _openTrickyKeys();
    }
  }

  void _openTrickyKeys() {
    final progress = Provider.of<ProgressProvider>(context, listen: false);
    if (progress.trickyKeys.isEmpty) return;
    context.push('/lesson/${PracticeGenerator.trickyKeysLessonId}');
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

  void _switchProfile() {
    context.push('/profiles');
  }

  void _openGames() {
    context.push('/games');
  }

  void _openSandbox() {
    context.push('/sandbox');
  }

  void _openTypingTest() {
    context.push('/test');
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
              final screenW = constraints.maxWidth;
              final isWide = screenW > 700;
              final useGrid = screenW > 860;
              final maxContentWidth = useGrid ? 900.0 : isWide ? 560.0 : screenW;

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
                        _buildProfileChip(context),
                        const SizedBox(height: 12),
                        _buildHeader(context),
                        const SizedBox(height: 24),
                        _buildMascotGreeting(progress),
                        const SizedBox(height: 28),
                        _buildContinueButton(context, progress),
                        const SizedBox(height: 12),
                        _buildAllLessonsButton(context),
                        const SizedBox(height: 20),
                        _buildActivities(context, progress, useGrid: useGrid),
                        const SizedBox(height: 28),
                        _buildStatsCards(context, progress),
                        const SizedBox(height: 16),
                        BadgesPanel(progress: progress),
                        const SizedBox(height: 20),
                        _buildBottomButtons(context),
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
                      ShortcutBadge('Enter', light: true),
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
            ShortcutBadge('L'),
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

  Widget _buildActivities(
    BuildContext context,
    ProgressProvider progress, {
    bool useGrid = false,
  }) {
    final trickyKeys = progress.trickyKeys;
    final cards = [
      ActivityCard(
        emoji: '🎮',
        title: 'Typing Games',
        subtitle: 'Have fun while you practice!',
        shortcut: 'G',
        color: AppColors.accent,
        onTap: () => _openGames(),
      ),
      ActivityCard(
        emoji: '📖',
        title: 'Free Practice',
        subtitle: 'Type classic stories at your pace',
        shortcut: 'F',
        color: AppColors.secondary,
        onTap: () => _openSandbox(),
      ),
      ActivityCard(
        emoji: '⏱️',
        title: 'Typing Test',
        subtitle: 'Test your speed with a time limit',
        shortcut: 'T',
        color: AppColors.primary,
        onTap: () => _openTypingTest(),
      ),
      if (trickyKeys.isNotEmpty)
        ActivityCard(
          emoji: '🔧',
          title: 'Tricky Keys',
          subtitle:
              'Practice ${trickyKeys.map((k) => k.toUpperCase()).join(' ')} — '
              'the keys you miss most',
          shortcut: 'K',
          color: AppColors.incorrect,
          onTap: () => _openTrickyKeys(),
        ),
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(left: 4, bottom: 10),
          child: Text(
            'More Activities',
            style: GoogleFonts.fredoka(
              fontSize: 20,
              fontWeight: FontWeight.w600,
              color: AppColors.textPrimary,
            ),
          ),
        ),
        if (useGrid)
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              for (var i = 0; i < cards.length; i++) ...[
                Expanded(child: cards[i]),
                if (i < cards.length - 1) const SizedBox(width: 10),
              ],
            ],
          )
        else
          ...[
            for (var i = 0; i < cards.length; i++) ...[
              cards[i],
              if (i < cards.length - 1) const SizedBox(height: 10),
            ],
          ],
      ],
    );
  }

  Widget _buildStatsCards(BuildContext context, ProgressProvider progress) {
    return Row(
      children: [
        Expanded(
          child: StatCard(
            emoji: '⭐',
            label: 'Stars',
            value: '${progress.totalStars}',
            color: AppColors.starFilled,
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: StatCard(
            emoji: '📚',
            label: 'Lessons',
            value: '${progress.completedLessons}/${progress.totalLessons}',
            color: AppColors.primary,
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: StatCard(
            emoji: '🎯',
            label: 'Accuracy',
            value: progress.averageAccuracy > 0
                ? '${progress.averageAccuracy.toStringAsFixed(0)}%'
                : '--',
            color: AppColors.accent,
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: StatCard(
            emoji: '🔥',
            label: 'Streak',
            value: progress.currentStreak > 0
                ? '${progress.currentStreak} day${progress.currentStreak == 1 ? '' : 's'}'
                : '--',
            color: AppColors.secondary,
          ),
        ),
      ],
    );
  }

  Widget _buildProfileChip(BuildContext context) {
    final profileProv = context.watch<ProfileProvider>();
    final profile = profileProv.activeProfile;
    if (profile == null) return const SizedBox.shrink();

    return Align(
      alignment: Alignment.centerRight,
      child: ActionChip(
        onPressed: () => _switchProfile(),
        avatar: Text(profile.emoji, style: const TextStyle(fontSize: 18)),
        label: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              profile.name,
              style: GoogleFonts.fredoka(
                fontSize: 14,
                fontWeight: FontWeight.w500,
                color: AppColors.textPrimary,
              ),
            ),
            const SizedBox(width: 4),
            ShortcutBadge('P'),
          ],
        ),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        backgroundColor: Colors.white,
        side: BorderSide(color: AppColors.primary.withValues(alpha: 0.3)),
      ),
    );
  }

  Widget _buildBottomButtons(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        TextButton.icon(
          onPressed: () => _switchProfile(),
          icon: const Icon(
            Icons.people_rounded,
            color: AppColors.textSecondary,
            size: 20,
          ),
          label: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'Profiles',
                style: GoogleFonts.fredoka(
                  fontSize: 16,
                  color: AppColors.textSecondary,
                ),
              ),
              const SizedBox(width: 6),
              ShortcutBadge('P'),
            ],
          ),
        ),
        const SizedBox(width: 16),
        TextButton.icon(
          onPressed: () => _openSettings(),
          icon: const Icon(
            Icons.settings_rounded,
            color: AppColors.textSecondary,
            size: 20,
          ),
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
              ShortcutBadge('S'),
            ],
          ),
        ),
      ],
    );
  }
}
