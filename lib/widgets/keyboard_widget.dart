import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../core/theme/app_colors.dart';
import '../data/keyboard_data.dart';

/// A visual on-screen keyboard that highlights active keys and shows
/// color-coded finger zones to help kids learn proper finger placement.
class KeyboardWidget extends StatelessWidget {
  /// The key that should currently be pressed (highlighted)
  final String? activeKey;

  /// Keys that were pressed correctly (shown green)
  final Set<String> correctKeys;

  /// Keys that were pressed incorrectly (shown red)
  final Set<String> incorrectKeys;

  /// Whether to show finger color zones
  final bool showFingerColors;

  const KeyboardWidget({
    super.key,
    this.activeKey,
    this.correctKeys = const {},
    this.incorrectKeys = const {},
    this.showFingerColors = true,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.grey.shade200,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.1),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Number row
          _buildRow(KeyboardData.keyboardRows[0]),
          const SizedBox(height: 4),
          // Top row (QWERTY)
          Padding(
            padding: const EdgeInsets.only(left: 20),
            child: _buildRow(KeyboardData.keyboardRows[1]),
          ),
          const SizedBox(height: 4),
          // Home row (ASDF)
          Padding(
            padding: const EdgeInsets.only(left: 32),
            child: _buildRow(KeyboardData.keyboardRows[2]),
          ),
          const SizedBox(height: 4),
          // Bottom row (ZXCV)
          Padding(
            padding: const EdgeInsets.only(left: 50),
            child: _buildRow(KeyboardData.keyboardRows[3]),
          ),
          const SizedBox(height: 4),
          // Space bar
          _buildSpaceBar(),
        ],
      ),
    );
  }

  Widget _buildRow(List<String> keys) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: keys.map((key) => _buildKey(key)).toList(),
    );
  }

  Widget _buildKey(String key) {
    final isActive = activeKey?.toLowerCase() == key.toLowerCase();
    final isCorrect = correctKeys.contains(key.toLowerCase());
    final isIncorrect = incorrectKeys.contains(key.toLowerCase());
    final isHomeRow = KeyboardData.homeRowKeys.contains(key.toLowerCase());

    Color bgColor;
    if (isActive) {
      bgColor = AppColors.secondary;
    } else if (isCorrect) {
      bgColor = AppColors.correct.withValues(alpha: 0.7);
    } else if (isIncorrect) {
      bgColor = AppColors.incorrect.withValues(alpha: 0.7);
    } else if (showFingerColors) {
      bgColor = KeyboardData.colorForKey(key).withValues(alpha: 0.4);
    } else {
      bgColor = Colors.white;
    }

    return AnimatedContainer(
      duration: const Duration(milliseconds: 150),
      width: 40,
      height: 40,
      margin: const EdgeInsets.all(2),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: isActive
              ? AppColors.secondary
              : isHomeRow
              ? AppColors.primaryDark.withValues(alpha: 0.5)
              : Colors.grey.shade400,
          width: isActive
              ? 2.5
              : isHomeRow
              ? 2
              : 1,
        ),
        boxShadow: isActive
            ? [
                BoxShadow(
                  color: AppColors.secondary.withValues(alpha: 0.4),
                  blurRadius: 8,
                  spreadRadius: 1,
                ),
              ]
            : null,
      ),
      child: Center(
        child: Text(
          KeyboardData.displayLabel(key),
          style: GoogleFonts.robotoMono(
            fontSize: 14,
            fontWeight: isActive ? FontWeight.bold : FontWeight.w500,
            color: isActive ? Colors.white : AppColors.textPrimary,
          ),
        ),
      ),
    );
  }

  Widget _buildSpaceBar() {
    final isActive = activeKey == ' ';
    return AnimatedContainer(
      duration: const Duration(milliseconds: 150),
      width: 260,
      height: 40,
      margin: const EdgeInsets.all(2),
      decoration: BoxDecoration(
        color: isActive
            ? AppColors.secondary
            : showFingerColors
            ? AppColors.fingerThumb.withValues(alpha: 0.3)
            : Colors.white,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: isActive ? AppColors.secondary : Colors.grey.shade400,
          width: isActive ? 2.5 : 1,
        ),
        boxShadow: isActive
            ? [
                BoxShadow(
                  color: AppColors.secondary.withValues(alpha: 0.4),
                  blurRadius: 8,
                  spreadRadius: 1,
                ),
              ]
            : null,
      ),
      child: Center(
        child: Text(
          'SPACE',
          style: GoogleFonts.robotoMono(
            fontSize: 12,
            fontWeight: FontWeight.w500,
            color: isActive ? Colors.white : Colors.grey.shade600,
          ),
        ),
      ),
    );
  }
}
