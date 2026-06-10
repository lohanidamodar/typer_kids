import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../core/theme/app_colors.dart';
import '../../../data/word_lists.dart';
import '../../../widgets/difficulty_card.dart';
import '../../../widgets/stat_tiles.dart';

const _bgTop = Color(0xFF05031A);

// ─────────────────────────────────────────────────────────────────────────────
// Setup / difficulty menu
// ─────────────────────────────────────────────────────────────────────────────

class DefendTempleMenu extends StatelessWidget {
  final FocusNode focusNode;
  final ContentDifficulty difficulty;
  final ValueChanged<ContentDifficulty> onDifficultyChanged;
  final VoidCallback onStart;
  final VoidCallback onBack;

  const DefendTempleMenu({
    super.key,
    required this.focusNode,
    required this.difficulty,
    required this.onDifficultyChanged,
    required this.onStart,
    required this.onBack,
  });

  void _handleSetupKey(KeyEvent event) {
    if (event is! KeyDownEvent) return;
    final key = event.logicalKey;
    if (key == LogicalKeyboardKey.escape) {
      onBack();
    } else if (key == LogicalKeyboardKey.enter ||
        key == LogicalKeyboardKey.space) {
      onStart();
    } else if (key == LogicalKeyboardKey.digit1) {
      onDifficultyChanged(ContentDifficulty.easy);
    } else if (key == LogicalKeyboardKey.digit2) {
      onDifficultyChanged(ContentDifficulty.medium);
    } else if (key == LogicalKeyboardKey.digit3) {
      onDifficultyChanged(ContentDifficulty.hard);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _bgTop,
      body: KeyboardListener(
        focusNode: focusNode,
        autofocus: true,
        onKeyEvent: _handleSetupKey,
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
                                _keyBadge('Esc', Colors.white70),
                              ],
                            ),
                            style: TextButton.styleFrom(
                              foregroundColor: Colors.white70,
                            ),
                          ),
                        ),
                        SizedBox(height: isTall ? 12 : 6),
                        // Header
                        Text('🏯', style: TextStyle(fontSize: emojiSize)),
                        SizedBox(height: isTall ? 8 : 4),
                        Text(
                          'Defend the Temple',
                          style: GoogleFonts.fredoka(
                            fontSize: headerFontSize,
                            fontWeight: FontWeight.w700,
                            color: const Color(0xFFFF6B6B),
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Demons are attacking! Type to destroy them\nbefore they reach your temple!',
                          style: GoogleFonts.nunito(
                            fontSize: isWide ? 16.0 : 14.0,
                            color: Colors.white60,
                          ),
                          textAlign: TextAlign.center,
                        ),
                        SizedBox(height: sectionGap),
                        // Difficulty
                        Text(
                          'Choose Difficulty',
                          style: GoogleFonts.fredoka(
                            fontSize: 18,
                            fontWeight: FontWeight.w600,
                            color: Colors.white70,
                          ),
                        ),
                        SizedBox(height: isTall ? 12 : 8),
                        Row(
                          children: ContentDifficulty.values
                              .asMap()
                              .entries
                              .map((e) {
                            return Expanded(
                              child: Padding(
                                padding: EdgeInsets.symmetric(
                                  horizontal: isWide ? 6 : 4,
                                ),
                                child: DifficultyCard(
                                  difficulty: e.value,
                                  index: e.key + 1,
                                  selected: difficulty == e.value,
                                  compact: !isTall,
                                  dark: true,
                                  accentColor: const Color(0xFFB22222),
                                  onTap: () => onDifficultyChanged(e.value),
                                ),
                              ),
                            );
                          }).toList(),
                        ),
                        SizedBox(height: sectionGap),
                        // Start
                        SizedBox(
                          width: double.infinity,
                          height: 56,
                          child: ElevatedButton(
                            onPressed: onStart,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFFB22222),
                              foregroundColor: Colors.white,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(16),
                              ),
                            ),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                const Text('⚔️',
                                    style: TextStyle(fontSize: 22)),
                                const SizedBox(width: 8),
                                Text(
                                  'Defend!',
                                  style: GoogleFonts.fredoka(fontSize: 22),
                                ),
                                const SizedBox(width: 8),
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

// ─────────────────────────────────────────────────────────────────────────────
// Game over
// ─────────────────────────────────────────────────────────────────────────────

class DefendTempleGameOver extends StatelessWidget {
  final FocusNode focusNode;
  final int score;
  final bool isNewHighScore;
  final int highScore;
  final int demonsSlain;
  final int demonsReached;
  final int bestStreak;
  final Duration gameDuration;
  final VoidCallback onPlayAgain;
  final VoidCallback onBack;

  const DefendTempleGameOver({
    super.key,
    required this.focusNode,
    required this.score,
    required this.isNewHighScore,
    required this.highScore,
    required this.demonsSlain,
    required this.demonsReached,
    required this.bestStreak,
    required this.gameDuration,
    required this.onPlayAgain,
    required this.onBack,
  });

  void _handleOverKey(KeyEvent event) {
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
    final minutes = gameDuration.inMinutes
        .remainder(60)
        .toString()
        .padLeft(2, '0');
    final seconds = gameDuration.inSeconds
        .remainder(60)
        .toString()
        .padLeft(2, '0');

    return Scaffold(
      backgroundColor: _bgTop,
      body: KeyboardListener(
        focusNode: focusNode,
        autofocus: true,
        onKeyEvent: _handleOverKey,
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
                        Text('💀', style: TextStyle(fontSize: emojiSize)),
                        SizedBox(height: isTall ? 8 : 4),
                        Text(
                          'Temple Fallen!',
                          style: GoogleFonts.fredoka(
                            fontSize: headerFontSize,
                            fontWeight: FontWeight.w700,
                            color: const Color(0xFFFF6B6B),
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
                                const Color(0xFFB22222).withValues(alpha: 0.15),
                              ],
                            ),
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(
                              color: AppColors.starFilled.withValues(alpha: 0.4),
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
                                      color: const Color(0xFFFFD700),
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
                                  color: Colors.white60,
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
                                      color: Colors.white54,
                                    ),
                                  ),
                                ),
                            ],
                          ),
                        ),
                        SizedBox(height: sectionGap),
                        // Stats
                        Row(
                          children: [
                            EmojiStatTile(
                              emoji: '💥',
                              label: 'Slain',
                              value: '$demonsSlain',
                              dark: true,
                            ),
                            const SizedBox(width: 12),
                            EmojiStatTile(
                              emoji: '💀',
                              label: 'Reached',
                              value: '$demonsReached',
                              dark: true,
                            ),
                          ],
                        ),
                        SizedBox(height: statGap),
                        Row(
                          children: [
                            EmojiStatTile(
                              emoji: '⚔️',
                              label: 'Best Streak',
                              value: '$bestStreak',
                              dark: true,
                            ),
                            const SizedBox(width: 12),
                            EmojiStatTile(
                              emoji: '⏱️',
                              label: 'Time',
                              value: '$minutes:$seconds',
                              dark: true,
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
                              backgroundColor: const Color(0xFFB22222),
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
                                  'Defend Again',
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
                              _keyBadge('Esc', Colors.white70),
                            ],
                          ),
                          style: TextButton.styleFrom(
                            foregroundColor: Colors.white70,
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

// ── Shared helpers ────────────────────────────────────────────────────────────

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
