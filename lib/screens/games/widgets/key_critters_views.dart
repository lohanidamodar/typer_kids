import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../core/theme/app_colors.dart';
import '../../../data/word_lists.dart';
import '../../../widgets/difficulty_card.dart';
import '../../../widgets/stat_tiles.dart';

const _accent = Color(0xFF43A047);

/// Difficulty-selection menu shown before a Key Critters round starts.
class KeyCrittersMenu extends StatelessWidget {
  final ContentDifficulty difficulty;
  final List<String> trickyKeys;
  final FocusNode focusNode;
  final ValueChanged<ContentDifficulty> onDifficultySelected;
  final VoidCallback onStart;
  final VoidCallback onBack;

  const KeyCrittersMenu({
    super.key,
    required this.difficulty,
    required this.trickyKeys,
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
                          '🐹',
                          style: TextStyle(fontSize: isTall ? 56 : 36),
                        ),
                        SizedBox(height: isTall ? 8 : 4),
                        Text(
                          'Key Critters',
                          style: GoogleFonts.fredoka(
                            fontSize: isWide ? 34 : 26,
                            fontWeight: FontWeight.w700,
                            color: _accent,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Critters pop out holding a key — press it to bonk them before they hide!',
                          style: GoogleFonts.nunito(
                            fontSize: isWide ? 16 : 14,
                            color: AppColors.textSecondary,
                          ),
                          textAlign: TextAlign.center,
                        ),
                        if (trickyKeys.isNotEmpty) ...[
                          SizedBox(height: isTall ? 16 : 8),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 14,
                              vertical: 8,
                            ),
                            decoration: BoxDecoration(
                              color: AppColors.accent.withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(
                                color: AppColors.accent.withValues(alpha: 0.3),
                              ),
                            ),
                            child: Text(
                              '🔧 Watch out — your tricky keys '
                              '${trickyKeys.map((k) => k.toUpperCase()).join(' ')} '
                              'will show up extra often!',
                              style: GoogleFonts.nunito(
                                fontSize: 13,
                                fontWeight: FontWeight.w700,
                                color: AppColors.textPrimary,
                              ),
                              textAlign: TextAlign.center,
                            ),
                          ),
                        ],
                        SizedBox(height: isTall ? 28 : 14),
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
                                  accentColor: _accent,
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
                              backgroundColor: _accent,
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
                                    'Start Bonking',
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

/// Results screen shown when a Key Critters round ends.
class KeyCrittersGameOver extends StatelessWidget {
  final int score;
  final bool isNewHighScore;
  final int highScore;
  final int bonked;
  final int escaped;
  final int accuracy;
  final int bestStreak;
  final FocusNode focusNode;
  final VoidCallback onPlayAgain;
  final VoidCallback onBack;

  const KeyCrittersGameOver({
    super.key,
    required this.score,
    required this.isNewHighScore,
    required this.highScore,
    required this.bonked,
    required this.escaped,
    required this.accuracy,
    required this.bestStreak,
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
                          bonked > escaped ? '🏆' : '🐹',
                          style: TextStyle(fontSize: isTall ? 56 : 36),
                        ),
                        SizedBox(height: isTall ? 8 : 4),
                        Text(
                          'Garden Closed!',
                          style: GoogleFonts.fredoka(
                            fontSize: isWide ? 36 : 28,
                            fontWeight: FontWeight.w700,
                            color: _accent,
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
                                _accent.withValues(alpha: 0.15),
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
                              emoji: '🔨',
                              label: 'Bonked',
                              value: '$bonked',
                            ),
                            const SizedBox(width: 12),
                            EmojiStatTile(
                              emoji: '💨',
                              label: 'Escaped',
                              value: '$escaped',
                            ),
                          ],
                        ),
                        SizedBox(height: isTall ? 12 : 8),
                        Row(
                          children: [
                            EmojiStatTile(
                              emoji: '🎯',
                              label: 'Accuracy',
                              value: '$accuracy%',
                            ),
                            const SizedBox(width: 12),
                            EmojiStatTile(
                              emoji: '🔥',
                              label: 'Best Streak',
                              value: '$bestStreak',
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
                              backgroundColor: _accent,
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

/// Small shortcut badge used on the menu and game-over buttons,
/// matching the style used by the other games' views.
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
