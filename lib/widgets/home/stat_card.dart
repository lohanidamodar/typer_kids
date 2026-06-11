import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../core/theme/app_colors.dart';

/// Compact emoji + value + label card for the home screen stats row.
class StatCard extends StatelessWidget {
  final String emoji;
  final String label;
  final String value;
  final Color color;

  const StatCard({
    super.key,
    required this.emoji,
    required this.label,
    required this.value,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color.withValues(alpha: 0.3)),
        boxShadow: [
          BoxShadow(
            color: color.withValues(alpha: 0.1),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          Text(emoji, style: const TextStyle(fontSize: 26)),
          const SizedBox(height: 4),
          Text(
            value,
            style: GoogleFonts.fredoka(
              fontSize: 20,
              fontWeight: FontWeight.w600,
              color: color,
            ),
          ),
          Text(
            label,
            style: GoogleFonts.nunito(
              fontSize: 13,
              color: AppColors.textSecondary,
            ),
          ),
        ],
      ),
    );
  }
}
