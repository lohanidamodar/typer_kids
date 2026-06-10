import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../core/theme/app_colors.dart';
import '../../../data/word_lists.dart';
import '../../../widgets/difficulty_card.dart';
import '../../../widgets/stat_tiles.dart';

/// Difficulty-selection menu shown before a Speed Chase race starts.
class SpeedChaseMenu extends StatelessWidget {
  final ContentDifficulty difficulty;
  final FocusNode focusNode;
  final ValueChanged<ContentDifficulty> onDifficultySelected;
  final VoidCallback onStart;
  final VoidCallback onBack;

  const SpeedChaseMenu({
    super.key,
    required this.difficulty,
    required this.focusNode,
    required this.onDifficultySelected,
    required this.onStart,
    required this.onBack,
  });

  void _handleKey(KeyEvent event) {
    if (event is! KeyDownEvent) return;
    final key = event.logicalKey;
    if (key == LogicalKeyboardKey.escape) {
      onBack();
    } else if (key == LogicalKeyboardKey.enter ||
        key == LogicalKeyboardKey.space) {
      onStart();
    } else if (key == LogicalKeyboardKey.digit1) {
      onDifficultySelected(ContentDifficulty.easy);
    } else if (key == LogicalKeyboardKey.digit2) {
      onDifficultySelected(ContentDifficulty.medium);
    } else if (key == LogicalKeyboardKey.digit3) {
      onDifficultySelected(ContentDifficulty.hard);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: KeyboardListener(
        focusNode: focusNode,
        autofocus: true,
        onKeyEvent: _handleKey,
        child: SafeArea(
          child: LayoutBuilder(
            builder: (context, constraints) {
              final screenW = constraints.maxWidth;
              final screenH = constraints.maxHeight;
              final isWide = screenW > 600;
              final isTall = screenH > 650;
              final hPad = isWide ? 40.0 : 20.0;
              final vPad = isTall ? 32.0 : 16.0;
              final maxW = isWide ? 520.0 : screenW;

              return Center(
                child: SingleChildScrollView(
                  padding: EdgeInsets.symmetric(
                    horizontal: hPad,
                    vertical: vPad,
                  ),
                  child: ConstrainedBox(
                    constraints: BoxConstraints(maxWidth: maxW),
                    child: Column(
                      children: [
                        Align(
                          alignment: Alignment.centerLeft,
                          child: TextButton.icon(
                            onPressed: onBack,
                            icon: const Icon(
                              Icons.arrow_back_rounded,
                              size: 18,
                            ),
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
                        SizedBox(height: isTall ? 16 : 8),
                        Text(
                          '🏎️',
                          style: TextStyle(fontSize: isTall ? 56 : 36),
                        ),
                        SizedBox(height: isTall ? 8 : 4),
                        Text(
                          'Speed Chase',
                          style: GoogleFonts.fredoka(
                            fontSize: isWide ? 34 : 26,
                            fontWeight: FontWeight.w700,
                            color: const Color(0xFFE53935),
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Type words faster than the ghost racer!',
                          style: GoogleFonts.nunito(
                            fontSize: isWide ? 16 : 14,
                            color: AppColors.textSecondary,
                          ),
                          textAlign: TextAlign.center,
                        ),
                        SizedBox(height: isTall ? 32 : 16),
                        Text(
                          'Choose Difficulty',
                          style: GoogleFonts.fredoka(
                            fontSize: isWide ? 20 : 18,
                            fontWeight: FontWeight.w600,
                            color: AppColors.textPrimary,
                          ),
                        ),
                        SizedBox(height: isTall ? 14 : 10),
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
                                  compact: !isTall,
                                  accentColor: const Color(0xFFE53935),
                                  onTap: () => onDifficultySelected(d),
                                ),
                              ),
                            );
                          }).toList(),
                        ),
                        SizedBox(height: isTall ? 32 : 16),
                        SizedBox(
                          width: isWide ? 280 : 220,
                          height: 56,
                          child: ElevatedButton(
                            onPressed: onStart,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFFE53935),
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
                                    'Start Race',
                                    style: GoogleFonts.fredoka(
                                      fontSize: isWide ? 22 : 18,
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
              );
            },
          ),
        ),
      ),
    );
  }
}

/// Results screen shown when a Speed Chase race ends.
class SpeedChaseGameOver extends StatelessWidget {
  final bool won;
  final int score;
  final bool isNewHighScore;
  final int highScore;
  final int wordsTyped;
  final int totalWords;
  final int wpm;
  final int errors;
  final int elapsed;
  final FocusNode focusNode;
  final VoidCallback onPlayAgain;
  final VoidCallback onBack;

  const SpeedChaseGameOver({
    super.key,
    required this.won,
    required this.score,
    required this.isNewHighScore,
    required this.highScore,
    required this.wordsTyped,
    required this.totalWords,
    required this.wpm,
    required this.errors,
    required this.elapsed,
    required this.focusNode,
    required this.onPlayAgain,
    required this.onBack,
  });

  void _handleKey(KeyEvent event) {
    if (event is! KeyDownEvent) return;
    final key = event.logicalKey;
    if (key == LogicalKeyboardKey.enter || key == LogicalKeyboardKey.space) {
      onPlayAgain();
    } else if (key == LogicalKeyboardKey.escape) {
      onBack();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: KeyboardListener(
        focusNode: focusNode,
        autofocus: true,
        onKeyEvent: _handleKey,
        child: SafeArea(
          child: LayoutBuilder(
            builder: (context, constraints) {
              final screenW = constraints.maxWidth;
              final screenH = constraints.maxHeight;
              final isWide = screenW > 600;
              final isTall = screenH > 650;
              final hPad = isWide ? 40.0 : 20.0;
              final vPad = isTall ? 32.0 : 16.0;
              final maxW = isWide ? 460.0 : screenW;
              final scoreFontSize = isTall ? 52.0 : 36.0;
              final sectionGap = isTall ? 24.0 : 12.0;

              return Center(
                child: SingleChildScrollView(
                  padding: EdgeInsets.symmetric(
                    horizontal: hPad,
                    vertical: vPad,
                  ),
                  child: ConstrainedBox(
                    constraints: BoxConstraints(maxWidth: maxW),
                    child: Column(
                      children: [
                        Text(
                          won ? '🏆' : '🏁',
                          style: TextStyle(fontSize: isTall ? 56 : 36),
                        ),
                        SizedBox(height: isTall ? 8 : 4),
                        Text(
                          won ? 'You Won!' : 'Race Over!',
                          style: GoogleFonts.fredoka(
                            fontSize: isWide ? 36 : 28,
                            fontWeight: FontWeight.w700,
                            color: won
                                ? AppColors.correct
                                : const Color(0xFFE53935),
                          ),
                        ),
                        SizedBox(height: sectionGap),
                        // Score
                        Container(
                          width: double.infinity,
                          padding: EdgeInsets.all(isTall ? 20 : 14),
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              colors: [
                                AppColors.starFilled.withValues(alpha: 0.15),
                                const Color(0xFFE53935).withValues(alpha: 0.15),
                              ],
                            ),
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(
                              color: AppColors.starFilled.withValues(
                                alpha: 0.4,
                              ),
                            ),
                          ),
                          child: Column(
                            children: [
                              if (isNewHighScore)
                                Padding(
                                  padding: const EdgeInsets.only(bottom: 4),
                                  child: Text(
                                    '⭐ New High Score! ⭐',
                                    style: GoogleFonts.fredoka(
                                      fontSize: 16,
                                      fontWeight: FontWeight.w600,
                                      color: AppColors.accent,
                                    ),
                                  ),
                                ),
                              Text(
                                '$score',
                                style: GoogleFonts.fredoka(
                                  fontSize: scoreFontSize,
                                  fontWeight: FontWeight.w700,
                                  color: AppColors.starFilled,
                                ),
                              ),
                              Text(
                                'points',
                                style: GoogleFonts.nunito(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w600,
                                  color: AppColors.textSecondary,
                                ),
                              ),
                              if (!isNewHighScore && highScore > 0)
                                Padding(
                                  padding: const EdgeInsets.only(top: 4),
                                  child: Text(
                                    'Best: $highScore',
                                    style: GoogleFonts.nunito(
                                      fontSize: 13,
                                      fontWeight: FontWeight.w600,
                                      color: AppColors.textSecondary,
                                    ),
                                  ),
                                ),
                            ],
                          ),
                        ),
                        SizedBox(height: sectionGap),
                        Row(
                          children: [
                            EmojiStatTile(
                              emoji: '📝',
                              label: 'Words Typed',
                              value: '$wordsTyped/$totalWords',
                            ),
                            const SizedBox(width: 12),
                            EmojiStatTile(
                              emoji: '⚡',
                              label: 'WPM',
                              value: '$wpm',
                            ),
                          ],
                        ),
                        SizedBox(height: isTall ? 12 : 8),
                        Row(
                          children: [
                            EmojiStatTile(
                              emoji: '❌',
                              label: 'Errors',
                              value: '$errors',
                            ),
                            const SizedBox(width: 12),
                            EmojiStatTile(
                              emoji: '⏱️',
                              label: 'Time',
                              value: '${elapsed}s',
                            ),
                          ],
                        ),
                        SizedBox(height: sectionGap + 8),
                        SizedBox(
                          width: double.infinity,
                          height: 56,
                          child: ElevatedButton(
                            onPressed: onPlayAgain,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFFE53935),
                              foregroundColor: Colors.white,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(16),
                              ),
                            ),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                const Icon(Icons.replay_rounded, size: 24),
                                const SizedBox(width: 8),
                                Text(
                                  'Race Again',
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
                          onPressed: onBack,
                          icon: const Icon(Icons.arrow_back_rounded, size: 18),
                          label: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(
                                'Back to Games',
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
              );
            },
          ),
        ),
      ),
    );
  }
}

/// Small shortcut badge used on the menu and game-over buttons.
///
/// Kept local: its alpha (0.18) and radius (5) differ from `ShortcutBadge`.
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
