import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../core/theme/app_colors.dart';

/// Emoji + value + label tile used on game-over and result screens.
/// Expands to share the row evenly with its siblings.
class EmojiStatTile extends StatelessWidget {
  final String emoji;
  final String label;
  final String value;
  final bool dark;

  const EmojiStatTile({
    super.key,
    required this.emoji,
    required this.label,
    required this.value,
    this.dark = false,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: dark ? Colors.white.withValues(alpha: 0.05) : Colors.white,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: dark ? Colors.white12 : Colors.grey.shade200,
          ),
        ),
        child: Column(
          children: [
            Text(emoji, style: const TextStyle(fontSize: 22)),
            const SizedBox(height: 4),
            Text(
              value,
              style: GoogleFonts.fredoka(
                fontSize: 22,
                fontWeight: FontWeight.w600,
                color: dark ? Colors.white : AppColors.textPrimary,
              ),
            ),
            Text(
              label,
              style: GoogleFonts.nunito(
                fontSize: 12,
                color: dark ? Colors.white54 : AppColors.textSecondary,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Icon + value + label column used in live stats bars while typing.
/// [compact] uses the slightly smaller sizes for dense layouts.
class LiveStatItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final Color color;
  final bool compact;

  const LiveStatItem({
    super.key,
    required this.icon,
    required this.label,
    required this.value,
    required this.color,
    this.compact = false,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Icon(icon, color: color, size: compact ? 18 : 20),
        const SizedBox(height: 2),
        Text(
          value,
          style: GoogleFonts.fredoka(
            fontSize: compact ? 16 : 18,
            fontWeight: FontWeight.w600,
            color: color,
          ),
        ),
        Text(
          label,
          style: GoogleFonts.nunito(
            fontSize: compact ? 10 : 11,
            color: AppColors.textSecondary,
          ),
        ),
      ],
    );
  }
}
