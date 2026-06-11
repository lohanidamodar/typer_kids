import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../core/theme/app_colors.dart';
import '../data/word_lists.dart';

/// Selectable difficulty option shown on game/test/sandbox menu screens,
/// with the number-key shortcut badge underneath.
///
/// [accentColor] matches the screen's theme. [compact] tightens spacing and
/// hides the description on short screens; [dark] adapts the unselected
/// colors for dark-themed games.
class DifficultyCard extends StatelessWidget {
  final ContentDifficulty difficulty;
  final int index;
  final bool selected;
  final bool compact;
  final bool dark;
  final Color accentColor;
  final VoidCallback onTap;

  const DifficultyCard({
    super.key,
    required this.difficulty,
    required this.index,
    required this.selected,
    this.compact = false,
    this.dark = false,
    required this.accentColor,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final vPad = compact ? 8.0 : 14.0;
    final emojiSize = compact ? 22.0 : 28.0;
    final labelSize = compact ? 14.0 : 16.0;
    final descSize = compact ? 10.0 : 11.0;

    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 160),
        padding: EdgeInsets.symmetric(vertical: vPad, horizontal: 8),
        decoration: BoxDecoration(
          color: selected
              ? accentColor.withValues(alpha: dark ? 0.2 : 0.12)
              : dark
              ? Colors.white.withValues(alpha: 0.05)
              : Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: selected
                ? accentColor
                : dark
                ? Colors.white24
                : Colors.grey.shade300,
            width: selected ? 2.5 : 1,
          ),
          boxShadow: selected
              ? [
                  BoxShadow(
                    color: accentColor.withValues(alpha: dark ? 0.25 : 0.15),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ]
              : null,
        ),
        child: Column(
          children: [
            Text(difficulty.emoji, style: TextStyle(fontSize: emojiSize)),
            SizedBox(height: compact ? 2 : 4),
            Text(
              difficulty.label,
              style: GoogleFonts.fredoka(
                fontSize: labelSize,
                fontWeight: FontWeight.w600,
                color: selected
                    ? accentColor
                    : dark
                    ? Colors.white70
                    : AppColors.textPrimary,
              ),
            ),
            if (!compact) ...[
              const SizedBox(height: 2),
              Text(
                difficulty.description,
                style: GoogleFonts.nunito(
                  fontSize: descSize,
                  color: dark ? Colors.white38 : AppColors.textSecondary,
                ),
                textAlign: TextAlign.center,
              ),
            ],
            SizedBox(height: compact ? 3 : 6),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
              decoration: BoxDecoration(
                color: accentColor.withValues(alpha: dark ? 0.12 : 0.08),
                borderRadius: BorderRadius.circular(4),
                border: Border.all(
                  color: accentColor.withValues(alpha: dark ? 0.3 : 0.2),
                ),
              ),
              child: Text(
                '$index',
                style: GoogleFonts.robotoMono(
                  fontSize: 10,
                  fontWeight: FontWeight.w600,
                  color: accentColor,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
