import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../core/theme/app_colors.dart';
import '../../../data/word_lists.dart';
import '../../../widgets/difficulty_card.dart';
import '../../../widgets/stat_tiles.dart';

/// Difficulty-selection menu shown before a Falling Words game starts.
class FallingWordsMenu extends StatelessWidget {
  final FocusNode focusNode;
  final ValueChanged<KeyEvent> onKeyEvent;
  final ContentDifficulty difficulty;
  final ValueChanged<ContentDifficulty> onDifficultyChanged;
  final VoidCallback onStart;
  final VoidCallback onBack;

  const FallingWordsMenu({
    super.key,
    required this.focusNode,
    required this.onKeyEvent,
    required this.difficulty,
    required this.onDifficultyChanged,
    required this.onStart,
    required this.onBack,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: KeyboardListener(
        focusNode: focusNode,
        autofocus: true,
        onKeyEvent: onKeyEvent,
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
              final headerFontSize = isWide ? 34.0 : 26.0;
              final emojiSize = isTall ? 56.0 : 36.0;
              final sectionGap = isTall ? 32.0 : 16.0;

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
                        // Back
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
                        Text('⬇️', style: TextStyle(fontSize: emojiSize)),
                        SizedBox(height: isTall ? 8 : 4),
                        Text(
                          'Falling Words',
                          style: GoogleFonts.fredoka(
                            fontSize: headerFontSize,
                            fontWeight: FontWeight.w700,
                            color: AppColors.primary,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Type the words before they reach the bottom!',
                          style: GoogleFonts.nunito(
                            fontSize: isWide ? 16.0 : 14.0,
                            color: AppColors.textSecondary,
                          ),
                          textAlign: TextAlign.center,
                        ),
                        SizedBox(height: sectionGap),
                        // Difficulty selector
                        Text(
                          'Choose Difficulty',
                          style: GoogleFonts.fredoka(
                            fontSize: isWide ? 20.0 : 18.0,
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
                                  accentColor: AppColors.primary,
                                  onTap: () => onDifficultyChanged(d),
                                ),
                              ),
                            );
                          }).toList(),
                        ),
                        SizedBox(height: sectionGap),
                        // Start button
                        SizedBox(
                          width: isWide ? 280 : 220,
                          height: 56,
                          child: ElevatedButton(
                            onPressed: onStart,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppColors.primary,
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
                                    'Start Game',
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

/// Results screen shown when a Falling Words game ends.
class FallingWordsGameOver extends StatelessWidget {
  final FocusNode focusNode;
  final ValueChanged<KeyEvent> onKeyEvent;
  final int score;
  final bool isNewHighScore;
  final int highScore;
  final int wordsDestroyed;
  final int wordsMissed;
  final int bestStreak;
  final Duration gameDuration;
  final VoidCallback onPlayAgain;
  final VoidCallback onBack;

  const FallingWordsGameOver({
    super.key,
    required this.focusNode,
    required this.onKeyEvent,
    required this.score,
    required this.isNewHighScore,
    required this.highScore,
    required this.wordsDestroyed,
    required this.wordsMissed,
    required this.bestStreak,
    required this.gameDuration,
    required this.onPlayAgain,
    required this.onBack,
  });

  @override
  Widget build(BuildContext context) {
    final minutes = gameDuration.inMinutes
        .remainder(60)
        .toString()
        .padLeft(2, '0');
    final seconds = gameDuration.inSeconds
        .remainder(60)
        .toString()
        .padLeft(2, '0');

    return Scaffold(
      backgroundColor: AppColors.background,
      body: KeyboardListener(
        focusNode: focusNode,
        autofocus: true,
        onKeyEvent: onKeyEvent,
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
              final headerFontSize = isWide ? 36.0 : 28.0;
              final emojiSize = isTall ? 56.0 : 36.0;
              final scoreFontSize = isTall ? 52.0 : 36.0;
              final sectionGap = isTall ? 24.0 : 12.0;
              final statGap = isTall ? 12.0 : 8.0;

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
                        Text('🎮', style: TextStyle(fontSize: emojiSize)),
                        SizedBox(height: isTall ? 8 : 4),
                        Text(
                          'Game Over!',
                          style: GoogleFonts.fredoka(
                            fontSize: headerFontSize,
                            fontWeight: FontWeight.w700,
                            color: AppColors.accent,
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
                                AppColors.secondary.withValues(alpha: 0.15),
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
                        // Stats grid
                        Row(
                          children: [
                            EmojiStatTile(
                              emoji: '✅',
                              label: 'Words',
                              value: '$wordsDestroyed',
                            ),
                            const SizedBox(width: 12),
                            EmojiStatTile(
                              emoji: '❌',
                              label: 'Missed',
                              value: '$wordsMissed',
                            ),
                          ],
                        ),
                        SizedBox(height: statGap),
                        Row(
                          children: [
                            EmojiStatTile(
                              emoji: '🔥',
                              label: 'Best Streak',
                              value: '$bestStreak',
                            ),
                            const SizedBox(width: 12),
                            EmojiStatTile(
                              emoji: '⏱️',
                              label: 'Time',
                              value: '$minutes:$seconds',
                            ),
                          ],
                        ),
                        SizedBox(height: sectionGap + 8),
                        // Play again
                        SizedBox(
                          width: double.infinity,
                          height: 56,
                          child: ElevatedButton(
                            onPressed: onPlayAgain,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppColors.primary,
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
                                  'Play Again',
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

/// Key-shortcut badge used by the menu and game-over views.
///
/// Kept local (instead of [ShortcutBadge]) because this game's variant uses a
/// stronger fill (alpha 0.18) and a 5 px corner radius.
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
