import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../core/theme/app_colors.dart';
import '../providers/typing_provider.dart';

/// Displays the text to type with color-coded feedback for each character
class TypingDisplay extends StatelessWidget {
  final String text;
  final List<CharState> charStates;
  final int cursorPosition;

  const TypingDisplay({
    super.key,
    required this.text,
    required this.charStates,
    required this.cursorPosition,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.primaryLight, width: 2),
        boxShadow: [
          BoxShadow(
            color: AppColors.primary.withValues(alpha: 0.1),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Wrap(
        children: List.generate(text.length, (index) {
          final char = text[index];
          final state = index < charStates.length
              ? charStates[index]
              : CharState.pending;

          Color bgColor;
          Color textColor;
          switch (state) {
            case CharState.correct:
              bgColor = AppColors.correct.withValues(alpha: 0.2);
              textColor = AppColors.primaryDark;
            case CharState.incorrect:
              bgColor = AppColors.incorrect.withValues(alpha: 0.3);
              textColor = AppColors.incorrect;
            case CharState.current:
              bgColor = AppColors.secondary.withValues(alpha: 0.3);
              textColor = AppColors.textPrimary;
            case CharState.pending:
              bgColor = Colors.transparent;
              textColor = Colors.grey.shade500;
          }

          return Container(
            padding: const EdgeInsets.symmetric(horizontal: 2, vertical: 4),
            decoration: BoxDecoration(
              color: bgColor,
              borderRadius: BorderRadius.circular(4),
              border: state == CharState.current
                  ? Border(
                      bottom: BorderSide(color: AppColors.secondary, width: 3),
                    )
                  : null,
            ),
            child: Text(
              char == ' ' ? '␣' : char,
              style: GoogleFonts.robotoMono(
                fontSize: 28,
                fontWeight: state == CharState.current
                    ? FontWeight.bold
                    : FontWeight.w400,
                color: textColor,
                decoration: state == CharState.incorrect
                    ? TextDecoration.lineThrough
                    : null,
              ),
            ),
          );
        }),
      ),
    );
  }
}
