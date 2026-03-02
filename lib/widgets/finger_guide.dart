import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../core/theme/app_colors.dart';
import '../data/keyboard_data.dart';

/// Shows which finger to use for the current key, with a visual hand diagram
class FingerGuide extends StatelessWidget {
  final String? currentKey;

  const FingerGuide({super.key, this.currentKey});

  @override
  Widget build(BuildContext context) {
    if (currentKey == null) return const SizedBox.shrink();

    final finger = KeyboardData.keyToFinger[currentKey!.toLowerCase()];
    if (finger == null) return const SizedBox.shrink();

    final fingerName = KeyboardData.fingerNameForKey(currentKey!);
    final fingerColor = KeyboardData.fingerColor(finger);
    final isLeft = finger.startsWith('left');
    final hand = isLeft ? '🤚' : '✋';

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: fingerColor.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: fingerColor.withValues(alpha: 0.5)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(hand, style: const TextStyle(fontSize: 24)),
          const SizedBox(width: 8),
          Text(
            fingerName,
            style: GoogleFonts.fredoka(
              fontSize: 16,
              fontWeight: FontWeight.w500,
              color: AppColors.textPrimary,
            ),
          ),
        ],
      ),
    );
  }
}
