import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../core/theme/app_colors.dart';
import '../../data/badges.dart';
import '../../providers/progress_provider.dart';

/// "My Badges" panel on the home screen showing earned achievement badges.
/// Renders nothing until the first badge is earned.
class BadgesPanel extends StatelessWidget {
  final ProgressProvider progress;

  const BadgesPanel({super.key, required this.progress});

  @override
  Widget build(BuildContext context) {
    final earned = Badges.earned(progress);
    if (earned.isEmpty) return const SizedBox.shrink();

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.starFilled.withValues(alpha: 0.4)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(
                'My Badges',
                style: GoogleFonts.fredoka(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: AppColors.textPrimary,
                ),
              ),
              const Spacer(),
              Text(
                '${earned.length}/${Badges.all.length}',
                style: GoogleFonts.nunito(
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  color: AppColors.textSecondary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: earned.map((badge) => _BadgeChip(badge)).toList(),
          ),
        ],
      ),
    );
  }
}

class _BadgeChip extends StatelessWidget {
  final AchievementBadge badge;

  const _BadgeChip(this.badge);

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: '${badge.title} — ${badge.description}',
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(
          color: AppColors.starFilled.withValues(alpha: 0.12),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(badge.emoji, style: const TextStyle(fontSize: 18)),
            const SizedBox(width: 6),
            Text(
              badge.title,
              style: GoogleFonts.nunito(
                fontSize: 13,
                fontWeight: FontWeight.w700,
                color: AppColors.textPrimary,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
