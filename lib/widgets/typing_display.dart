import 'package:flutter/material.dart';

import '../core/theme/app_colors.dart';
import '../core/theme/app_theme.dart';
import '../providers/typing_provider.dart';

/// Displays the lesson text to type with color-coded feedback per character.
///
/// Text wraps at word boundaries (words never split across lines), uses the
/// shared fixed-width typing font, and renders spaces normally — the ␣
/// symbol appears only on the current target or a mistyped space.
class TypingDisplay extends StatelessWidget {
  final String text;
  final List<CharState> charStates;
  final int cursorPosition;
  final double fontSize;

  const TypingDisplay({
    super.key,
    required this.text,
    required this.charStates,
    required this.cursorPosition,
    this.fontSize = 28,
  });

  /// Word chunks (word + trailing spaces) so lines break between words.
  List<(int, int)> _chunkRanges() {
    final ranges = <(int, int)>[];
    var start = 0;
    while (start < text.length) {
      var end = start;
      while (end < text.length && text[end] != ' ') {
        end++;
      }
      while (end < text.length && text[end] == ' ') {
        end++;
      }
      ranges.add((start, end));
      start = end;
    }
    return ranges;
  }

  TextSpan _charSpan(int index) {
    final char = text[index];
    final state = index < charStates.length
        ? charStates[index]
        : CharState.pending;

    final isSpace = char == ' ';
    final display = switch (state) {
      CharState.current when isSpace => '␣',
      CharState.incorrect when isSpace => '␣',
      _ => char,
    };

    return switch (state) {
      CharState.correct => TextSpan(
        text: display,
        style: AppTheme.typingTextStyle(
          fontSize: fontSize,
          color: AppColors.correct,
          height: 1.5,
        ),
      ),
      CharState.incorrect => TextSpan(
        text: display,
        style: AppTheme.typingTextStyle(
          fontSize: fontSize,
          fontWeight: FontWeight.w600,
          color: AppColors.incorrect,
          height: 1.5,
        ).copyWith(
          backgroundColor: AppColors.incorrect.withValues(alpha: 0.15),
        ),
      ),
      CharState.current => TextSpan(
        text: display,
        style: AppTheme.typingTextStyle(
          fontSize: fontSize,
          fontWeight: FontWeight.w700,
          color: AppColors.textPrimary,
          height: 1.5,
          decoration: TextDecoration.underline,
          decorationColor: AppColors.secondary,
        ).copyWith(
          backgroundColor: AppColors.secondary.withValues(alpha: 0.25),
          decorationThickness: 3,
        ),
      ),
      CharState.pending => TextSpan(
        text: display,
        style: AppTheme.typingTextStyle(
          fontSize: fontSize,
          color: Colors.grey.shade600,
          height: 1.5,
        ),
      ),
    };
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.symmetric(
        horizontal: (fontSize * 0.6).clamp(16, 32),
        vertical: (fontSize * 0.5).clamp(14, 28),
      ),
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
        alignment: WrapAlignment.center,
        runAlignment: WrapAlignment.center,
        children: [
          for (final (start, end) in _chunkRanges())
            Text.rich(
              TextSpan(
                children: [for (var i = start; i < end; i++) _charSpan(i)],
              ),
            ),
        ],
      ),
    );
  }
}
