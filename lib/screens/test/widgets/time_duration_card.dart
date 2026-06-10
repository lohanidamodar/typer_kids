import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../core/theme/app_colors.dart';

// ─────────────────────────────────────────────────────────────────────────────
// Time durations offered in setup
// ─────────────────────────────────────────────────────────────────────────────

enum TestDuration {
  seconds30(30, '30 s', '⚡'),
  minute1(60, '1 min', '⏱️'),
  minutes2(120, '2 min', '🕐'),
  minutes5(300, '5 min', '🕔');

  const TestDuration(this.seconds, this.label, this.emoji);
  final int seconds;
  final String label;
  final String emoji;
}

/// Selectable test-duration option shown on the typing-test setup screen,
/// with its letter-key shortcut badge underneath.
class TimeDurationCard extends StatelessWidget {
  final TestDuration duration;
  final String shortcut;
  final bool selected;
  final VoidCallback onTap;

  const TimeDurationCard({
    super.key,
    required this.duration,
    required this.shortcut,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 160),
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 6),
        decoration: BoxDecoration(
          color: selected
              ? AppColors.accent.withValues(alpha: 0.12)
              : Colors.white,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: selected ? AppColors.accent : Colors.grey.shade300,
            width: selected ? 2.5 : 1,
          ),
          boxShadow: selected
              ? [
                  BoxShadow(
                    color: AppColors.accent.withValues(alpha: 0.15),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ]
              : null,
        ),
        child: Column(
          children: [
            Text(duration.emoji, style: const TextStyle(fontSize: 22)),
            const SizedBox(height: 3),
            Text(
              duration.label,
              style: GoogleFonts.fredoka(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: selected ? AppColors.accent : AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: 5),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
              decoration: BoxDecoration(
                color: AppColors.accent.withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(4),
                border: Border.all(
                  color: AppColors.accent.withValues(alpha: 0.2),
                ),
              ),
              child: Text(
                shortcut,
                style: GoogleFonts.robotoMono(
                  fontSize: 10,
                  fontWeight: FontWeight.w600,
                  color: AppColors.accent,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
