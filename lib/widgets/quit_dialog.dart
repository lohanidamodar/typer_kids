import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';

import '../core/theme/app_colors.dart';
import 'shortcut_badge.dart';

/// Confirmation dialog shown when leaving a lesson, game, or test.
///
/// Keyboard shortcuts: `Esc` (or [stayKey]) stays, `Enter` (or [quitKey])
/// leaves. Use [dark] for dark-themed games and override the labels, badge
/// texts, and colors to match each screen's wording.
class QuitDialog extends StatefulWidget {
  final String title;
  final String message;
  final String stayLabel;
  final String quitLabel;
  final String stayBadge;
  final String quitBadge;
  final LogicalKeyboardKey stayKey;
  final LogicalKeyboardKey quitKey;
  final bool dark;
  final Color stayColor;
  final Color quitColor;
  final VoidCallback onStay;
  final VoidCallback onQuit;

  const QuitDialog({
    super.key,
    required this.title,
    required this.message,
    this.stayLabel = 'Stay',
    this.quitLabel = 'Leave',
    this.stayBadge = 'Esc',
    this.quitBadge = 'L',
    this.stayKey = LogicalKeyboardKey.keyS,
    this.quitKey = LogicalKeyboardKey.keyL,
    this.dark = false,
    this.stayColor = AppColors.primary,
    this.quitColor = AppColors.incorrect,
    required this.onStay,
    required this.onQuit,
  });

  @override
  State<QuitDialog> createState() => _QuitDialogState();
}

class _QuitDialogState extends State<QuitDialog> {
  final _focusNode = FocusNode();

  @override
  void dispose() {
    _focusNode.dispose();
    super.dispose();
  }

  void _handleKey(KeyEvent event) {
    if (event is! KeyDownEvent) return;
    final key = event.logicalKey;
    if (key == LogicalKeyboardKey.escape || key == widget.stayKey) {
      widget.onStay();
    } else if (key == LogicalKeyboardKey.enter || key == widget.quitKey) {
      widget.onQuit();
    }
  }

  Widget _action({
    required String label,
    required String badge,
    required Color color,
    required VoidCallback onPressed,
  }) {
    return TextButton(
      onPressed: onPressed,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(label, style: GoogleFonts.fredoka(color: color)),
          const SizedBox(width: 6),
          ShortcutBadge(badge, small: true, color: color),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return KeyboardListener(
      focusNode: _focusNode,
      autofocus: true,
      onKeyEvent: _handleKey,
      child: AlertDialog(
        backgroundColor: widget.dark ? const Color(0xFF1A1040) : null,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text(
          widget.title,
          style: GoogleFonts.fredoka(
            fontSize: 24,
            color: widget.dark ? Colors.white : AppColors.textPrimary,
          ),
        ),
        content: Text(
          widget.message,
          style: GoogleFonts.nunito(
            fontSize: 16,
            color: widget.dark ? Colors.white70 : null,
          ),
        ),
        actions: [
          _action(
            label: widget.stayLabel,
            badge: widget.stayBadge,
            color: widget.stayColor,
            onPressed: widget.onStay,
          ),
          _action(
            label: widget.quitLabel,
            badge: widget.quitBadge,
            color: widget.quitColor,
            onPressed: widget.onQuit,
          ),
        ],
      ),
    );
  }
}
