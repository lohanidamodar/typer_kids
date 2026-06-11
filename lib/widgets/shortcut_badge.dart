import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../core/theme/app_colors.dart';

/// Small rounded badge showing a keyboard shortcut (e.g. "Enter", "Esc").
///
/// Use [light] on colored/filled buttons, and [small] for the tighter
/// variant used inside dialogs.
class ShortcutBadge extends StatelessWidget {
  final String label;
  final bool light;
  final bool small;
  final Color? color;

  const ShortcutBadge(
    this.label, {
    super.key,
    this.light = false,
    this.small = false,
    this.color,
  });

  @override
  Widget build(BuildContext context) {
    final accent = color ?? AppColors.primary;

    return Container(
      padding: small
          ? const EdgeInsets.symmetric(horizontal: 5, vertical: 1)
          : const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: light
            ? Colors.white.withValues(alpha: 0.25)
            : accent.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(small ? 4 : 6),
        border: Border.all(
          color: light
              ? Colors.white.withValues(alpha: 0.4)
              : accent.withValues(alpha: 0.3),
        ),
      ),
      child: Text(
        label,
        style: GoogleFonts.robotoMono(
          fontSize: small ? 10 : 11,
          fontWeight: FontWeight.w600,
          color: light ? Colors.white : accent,
        ),
      ),
    );
  }
}
