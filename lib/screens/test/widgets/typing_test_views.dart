import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../core/theme/app_colors.dart';
import '../../../data/word_lists.dart';
import '../../../widgets/difficulty_card.dart';
import '../../../widgets/stat_tiles.dart';
import 'time_duration_card.dart';

// ─────────────────────────────────────────────────────────────────────────────
// Setup view — difficulty + duration selection
// ─────────────────────────────────────────────────────────────────────────────

/// The typing-test setup/menu view: pick a difficulty and duration, then start.
class TypingTestSetup extends StatelessWidget {
  final FocusNode focusNode;
  final ContentDifficulty difficulty;
  final TestDuration duration;
  final ValueChanged<ContentDifficulty> onDifficultyChanged;
  final ValueChanged<TestDuration> onDurationChanged;
  final VoidCallback onStart;

  const TypingTestSetup({
    super.key,
    required this.focusNode,
    required this.difficulty,
    required this.duration,
    required this.onDifficultyChanged,
    required this.onDurationChanged,
    required this.onStart,
  });

  void _handleKey(BuildContext context, KeyEvent event) {
    if (event is! KeyDownEvent) return;
    final key = event.logicalKey;
    if (key == LogicalKeyboardKey.escape) {
      context.pop();
    } else if (key == LogicalKeyboardKey.enter ||
        key == LogicalKeyboardKey.space) {
      onStart();
    } else if (key == LogicalKeyboardKey.digit1) {
      onDifficultyChanged(ContentDifficulty.easy);
    } else if (key == LogicalKeyboardKey.digit2) {
      onDifficultyChanged(ContentDifficulty.medium);
    } else if (key == LogicalKeyboardKey.digit3) {
      onDifficultyChanged(ContentDifficulty.hard);
    } else if (key == LogicalKeyboardKey.keyA) {
      onDurationChanged(TestDuration.seconds30);
    } else if (key == LogicalKeyboardKey.keyB) {
      onDurationChanged(TestDuration.minute1);
    } else if (key == LogicalKeyboardKey.keyC) {
      onDurationChanged(TestDuration.minutes2);
    } else if (key == LogicalKeyboardKey.keyD) {
      onDurationChanged(TestDuration.minutes5);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: KeyboardListener(
        focusNode: focusNode,
        autofocus: true,
        onKeyEvent: (event) => _handleKey(context, event),
        child: SafeArea(
          child: Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(32),
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 480),
                child: Column(
                  children: [
                    // Back
                    Align(
                      alignment: Alignment.centerLeft,
                      child: TextButton.icon(
                        onPressed: () => context.pop(),
                        icon: const Icon(Icons.arrow_back_rounded, size: 18),
                        label: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              'Back',
                              style: GoogleFonts.fredoka(fontSize: 16),
                            ),
                            const SizedBox(width: 6),
                            _keyBadge('Esc', AppColors.textSecondary),
                          ],
                        ),
                        style: TextButton.styleFrom(
                          foregroundColor: AppColors.textSecondary,
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    const Text('⏱️', style: TextStyle(fontSize: 56)),
                    const SizedBox(height: 8),
                    Text(
                      'Typing Test',
                      style: GoogleFonts.fredoka(
                        fontSize: 34,
                        fontWeight: FontWeight.w700,
                        color: AppColors.accent,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Test your typing speed and accuracy!',
                      style: GoogleFonts.nunito(
                        fontSize: 16,
                        color: AppColors.textSecondary,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 28),

                    // ── Difficulty selector ──
                    Text(
                      'Difficulty',
                      style: GoogleFonts.fredoka(
                        fontSize: 20,
                        fontWeight: FontWeight.w600,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: ContentDifficulty.values.map((d) {
                        final selected = d == difficulty;
                        return Expanded(
                          child: Padding(
                            padding: EdgeInsets.only(
                              left: d.index == 0 ? 0 : 6,
                              right: d.index == 2 ? 0 : 6,
                            ),
                            child: DifficultyCard(
                              difficulty: d,
                              index: d.index + 1,
                              selected: selected,
                              onTap: () => onDifficultyChanged(d),
                              accentColor: AppColors.accent,
                            ),
                          ),
                        );
                      }).toList(),
                    ),
                    const SizedBox(height: 24),

                    // ── Duration selector ──
                    Text(
                      'Duration',
                      style: GoogleFonts.fredoka(
                        fontSize: 20,
                        fontWeight: FontWeight.w600,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: TestDuration.values.map((d) {
                        final selected = d == duration;
                        final shortcut = String.fromCharCode(
                          65 + d.index, // A, B, C, D
                        );
                        return Expanded(
                          child: Padding(
                            padding: EdgeInsets.only(
                              left: d.index == 0 ? 0 : 4,
                              right: d.index == TestDuration.values.length - 1
                                  ? 0
                                  : 4,
                            ),
                            child: TimeDurationCard(
                              duration: d,
                              shortcut: shortcut,
                              selected: selected,
                              onTap: () => onDurationChanged(d),
                            ),
                          ),
                        );
                      }).toList(),
                    ),
                    const SizedBox(height: 32),

                    // ── Start button ──
                    SizedBox(
                      width: 240,
                      height: 56,
                      child: ElevatedButton(
                        onPressed: onStart,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.accent,
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                          ),
                          elevation: 4,
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Icon(Icons.play_arrow_rounded, size: 28),
                            const SizedBox(width: 6),
                            Flexible(
                              child: Text(
                                'Start Test',
                                style: GoogleFonts.fredoka(
                                  fontSize: 22,
                                  fontWeight: FontWeight.w600,
                                ),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                            const SizedBox(width: 6),
                            _keyBadge('Enter', Colors.white),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Results view
// ─────────────────────────────────────────────────────────────────────────────

/// The typing-test results view: speed rating, stars, WPM, and stats.
class TypingTestResults extends StatelessWidget {
  final FocusNode focusNode;
  final ContentDifficulty difficulty;
  final TestDuration duration;
  final int elapsedSeconds;
  final double accuracy;
  final int correctCount;
  final int incorrectCount;
  final int totalTyped;
  final int passageCount;
  final VoidCallback onTryAgain;

  const TypingTestResults({
    super.key,
    required this.focusNode,
    required this.difficulty,
    required this.duration,
    required this.elapsedSeconds,
    required this.accuracy,
    required this.correctCount,
    required this.incorrectCount,
    required this.totalTyped,
    required this.passageCount,
    required this.onTryAgain,
  });

  void _handleKey(BuildContext context, KeyEvent event) {
    if (event is! KeyDownEvent) return;
    if (event.logicalKey == LogicalKeyboardKey.enter ||
        event.logicalKey == LogicalKeyboardKey.space) {
      onTryAgain();
    } else if (event.logicalKey == LogicalKeyboardKey.escape) {
      context.pop();
    }
  }

  @override
  Widget build(BuildContext context) {
    final mins = (elapsedSeconds ~/ 60).toString().padLeft(2, '0');
    final secs = (elapsedSeconds % 60).toString().padLeft(2, '0');

    // Final WPM based on actual elapsed time
    final finalWpm = elapsedSeconds > 0
        ? (correctCount / 5.0) / (elapsedSeconds / 60.0)
        : 0.0;

    // Star rating based on WPM + accuracy
    int stars;
    if (finalWpm >= 60 && accuracy >= 95) {
      stars = 5;
    } else if (finalWpm >= 40 && accuracy >= 90) {
      stars = 4;
    } else if (finalWpm >= 25 && accuracy >= 85) {
      stars = 3;
    } else if (finalWpm >= 15 && accuracy >= 75) {
      stars = 2;
    } else {
      stars = 1;
    }

    // Speed rating label
    String speedLabel;
    String speedEmoji;
    if (finalWpm >= 60) {
      speedLabel = 'Lightning Fast!';
      speedEmoji = '⚡';
    } else if (finalWpm >= 40) {
      speedLabel = 'Super Speedy!';
      speedEmoji = '🚀';
    } else if (finalWpm >= 25) {
      speedLabel = 'Great Job!';
      speedEmoji = '🎉';
    } else if (finalWpm >= 15) {
      speedLabel = 'Good Work!';
      speedEmoji = '👍';
    } else {
      speedLabel = 'Keep Practicing!';
      speedEmoji = '💪';
    }

    return Scaffold(
      backgroundColor: AppColors.background,
      body: KeyboardListener(
        focusNode: focusNode,
        autofocus: true,
        onKeyEvent: (event) => _handleKey(context, event),
        child: SafeArea(
          child: Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(32),
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 440),
                child: Column(
                  children: [
                    Text(speedEmoji, style: const TextStyle(fontSize: 56)),
                    const SizedBox(height: 8),
                    Text(
                      speedLabel,
                      style: GoogleFonts.fredoka(
                        fontSize: 34,
                        fontWeight: FontWeight.w700,
                        color: AppColors.accent,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '${difficulty.emoji} ${difficulty.label} · ${duration.label} test',
                      style: GoogleFonts.nunito(
                        fontSize: 14,
                        color: AppColors.textSecondary,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 20),

                    // Stars
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: List.generate(
                        5,
                        (i) => Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 2),
                          child: Icon(
                            i < stars
                                ? Icons.star_rounded
                                : Icons.star_border_rounded,
                            color: i < stars
                                ? AppColors.starFilled
                                : AppColors.starEmpty,
                            size: 36,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 20),

                    // ── Big WPM display ──
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.symmetric(vertical: 20),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [
                            AppColors.accent.withValues(alpha: 0.08),
                            AppColors.accentLight.withValues(alpha: 0.12),
                          ],
                        ),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                          color: AppColors.accent.withValues(alpha: 0.25),
                        ),
                      ),
                      child: Column(
                        children: [
                          Text(
                            finalWpm.toStringAsFixed(1),
                            style: GoogleFonts.fredoka(
                              fontSize: 52,
                              fontWeight: FontWeight.w700,
                              color: AppColors.accent,
                            ),
                          ),
                          Text(
                            'Words Per Minute',
                            style: GoogleFonts.nunito(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                              color: AppColors.textSecondary,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),

                    // Stats
                    Row(
                      children: [
                        EmojiStatTile(
                          emoji: '⏱️',
                          label: 'Time',
                          value: '$mins:$secs',
                        ),
                        const SizedBox(width: 12),
                        EmojiStatTile(
                          emoji: '🎯',
                          label: 'Accuracy',
                          value: '${accuracy.toStringAsFixed(1)}%',
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        EmojiStatTile(
                          emoji: '✅',
                          label: 'Correct',
                          value: '$correctCount',
                        ),
                        const SizedBox(width: 12),
                        EmojiStatTile(
                          emoji: '❌',
                          label: 'Errors',
                          value: '$incorrectCount',
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        EmojiStatTile(
                          emoji: '🔤',
                          label: 'Total Chars',
                          value: '$totalTyped',
                        ),
                        const SizedBox(width: 12),
                        EmojiStatTile(
                          emoji: '📝',
                          label: 'Passages',
                          value: '$passageCount',
                        ),
                      ],
                    ),
                    const SizedBox(height: 32),

                    // Try again
                    SizedBox(
                      width: double.infinity,
                      height: 56,
                      child: ElevatedButton(
                        onPressed: onTryAgain,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.accent,
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                          ),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Icon(Icons.refresh_rounded, size: 24),
                            const SizedBox(width: 8),
                            Text(
                              'Test Again',
                              style: GoogleFonts.fredoka(fontSize: 20),
                            ),
                            const SizedBox(width: 8),
                            _keyBadge('Enter', Colors.white),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),
                    TextButton.icon(
                      onPressed: () => context.pop(),
                      icon: const Icon(Icons.arrow_back_rounded, size: 18),
                      label: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            'Back',
                            style: GoogleFonts.fredoka(fontSize: 16),
                          ),
                          const SizedBox(width: 6),
                          _keyBadge('Esc', AppColors.textSecondary),
                        ],
                      ),
                      style: TextButton.styleFrom(
                        foregroundColor: AppColors.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Shared helpers
// ─────────────────────────────────────────────────────────────────────────────

Widget _keyBadge(String label, Color color) {
  return Container(
    padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
    decoration: BoxDecoration(
      color: color.withValues(alpha: 0.18),
      borderRadius: BorderRadius.circular(5),
      border: Border.all(color: color.withValues(alpha: 0.3)),
    ),
    child: Text(
      label,
      style: GoogleFonts.robotoMono(
        fontSize: 10,
        fontWeight: FontWeight.w600,
        color: color,
      ),
    ),
  );
}
