import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../core/theme/app_colors.dart';

/// Menu screen listing available typing games.
class GameMenuScreen extends StatefulWidget {
  const GameMenuScreen({super.key});

  @override
  State<GameMenuScreen> createState() => _GameMenuScreenState();
}

class _GameMenuScreenState extends State<GameMenuScreen> {
  final FocusNode _focusNode = FocusNode();

  @override
  void dispose() {
    _focusNode.dispose();
    super.dispose();
  }

  void _handleKeyEvent(KeyEvent event) {
    if (event is! KeyDownEvent) return;
    final key = event.logicalKey;
    if (key == LogicalKeyboardKey.escape) {
      context.pop();
    } else if (key == LogicalKeyboardKey.digit1) {
      context.push('/games/falling-words');
    } else if (key == LogicalKeyboardKey.digit2) {
      context.push('/games/word-bubbles');
    } else if (key == LogicalKeyboardKey.digit3) {
      context.push('/games/speed-chase');
    } else if (key == LogicalKeyboardKey.digit4) {
      context.push('/games/defend-temple');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: KeyboardListener(
        focusNode: _focusNode,
        autofocus: true,
        onKeyEvent: _handleKeyEvent,
        child: SafeArea(
          child: LayoutBuilder(
            builder: (context, constraints) {
              final screenW = constraints.maxWidth;
              final screenH = constraints.maxHeight;
              final isWide = screenW > 600;
              final isTall = screenH > 700;

              final hPad = isWide ? 40.0 : 20.0;
              final vPad = isTall ? 32.0 : 16.0;
              final maxW = isWide ? 620.0 : screenW;
              final headerFontSize = isWide ? 36.0 : 28.0;
              final emojiSize = isTall ? 56.0 : 40.0;
              final sectionGap = isTall ? 32.0 : 18.0;
              final cardGap = isTall ? 14.0 : 10.0;

              return Center(
                child: SingleChildScrollView(
                  padding: EdgeInsets.symmetric(
                    horizontal: hPad,
                    vertical: vPad,
                  ),
                  child: ConstrainedBox(
                    constraints: BoxConstraints(maxWidth: maxW),
                    child: Column(
                      children: [
                        // Back button
                        Align(
                          alignment: Alignment.centerLeft,
                          child: TextButton.icon(
                            onPressed: () => context.pop(),
                            icon: const Icon(
                              Icons.arrow_back_rounded,
                              size: 18,
                            ),
                            label: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Text(
                                  'Back',
                                  style: GoogleFonts.fredoka(fontSize: 16),
                                ),
                                const SizedBox(width: 6),
                                _KeyBadge('Esc'),
                              ],
                            ),
                            style: TextButton.styleFrom(
                              foregroundColor: AppColors.textSecondary,
                            ),
                          ),
                        ),
                        SizedBox(height: isTall ? 12 : 6),
                        // Header
                        Text('🎮', style: TextStyle(fontSize: emojiSize)),
                        SizedBox(height: isTall ? 8 : 4),
                        Text(
                          'Typing Games',
                          style: GoogleFonts.fredoka(
                            fontSize: headerFontSize,
                            fontWeight: FontWeight.w700,
                            color: AppColors.primary,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Have fun while you practice!',
                          style: GoogleFonts.nunito(
                            fontSize: isWide ? 16.0 : 14.0,
                            color: AppColors.textSecondary,
                          ),
                        ),
                        SizedBox(height: sectionGap),
                        // ── Game cards ──
                        _GameCard(
                          emoji: '⬇️',
                          title: 'Falling Words',
                          description:
                              'Type the words before they reach the bottom!',
                          shortcut: '1',
                          color: AppColors.primary,
                          compact: !isTall,
                          onTap: () => context.push('/games/falling-words'),
                        ),
                        SizedBox(height: cardGap),
                        _GameCard(
                          emoji: '🫧',
                          title: 'Word Bubbles',
                          description:
                              'Pop the floating bubbles by typing the words!',
                          shortcut: '2',
                          color: const Color(0xFF26C6DA),
                          compact: !isTall,
                          onTap: () => context.push('/games/word-bubbles'),
                        ),
                        SizedBox(height: cardGap),
                        _GameCard(
                          emoji: '🏎️',
                          title: 'Speed Chase',
                          description:
                              'Type words faster than the ghost racer!',
                          shortcut: '3',
                          color: const Color(0xFFE53935),
                          compact: !isTall,
                          onTap: () => context.push('/games/speed-chase'),
                        ),
                        SizedBox(height: cardGap),
                        _GameCard(
                          emoji: '🏯',
                          title: 'Defend the Temple',
                          description:
                              'Stop the demons before they reach your temple!',
                          shortcut: '4',
                          color: const Color(0xFF8B0000),
                          compact: !isTall,
                          onTap: () => context.push('/games/defend-temple'),
                        ),
                      ],
                    ),
                  ),
                ),
              );
            },
          ),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Helper widgets
// ─────────────────────────────────────────────────────────────────────────────

class _GameCard extends StatelessWidget {
  final String emoji;
  final String title;
  final String description;
  final String shortcut;
  final Color color;
  final bool compact;
  final VoidCallback onTap;

  const _GameCard({
    required this.emoji,
    required this.title,
    required this.description,
    required this.shortcut,
    required this.color,
    this.compact = false,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final pad = compact ? 14.0 : 20.0;
    final emojiSize = compact ? 32.0 : 40.0;
    final titleSize = compact ? 18.0 : 22.0;
    final descSize = compact ? 12.0 : 14.0;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(20),
        child: Container(
          width: double.infinity,
          padding: EdgeInsets.all(pad),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: color.withValues(alpha: 0.4), width: 2),
            boxShadow: [
              BoxShadow(
                color: color.withValues(alpha: 0.12),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Row(
            children: [
              Text(emoji, style: TextStyle(fontSize: emojiSize)),
              SizedBox(width: compact ? 10 : 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: GoogleFonts.fredoka(
                        fontSize: titleSize,
                        fontWeight: FontWeight.w600,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      description,
                      style: GoogleFonts.nunito(
                        fontSize: descSize,
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              _KeyBadge(shortcut),
              const SizedBox(width: 4),
              Icon(Icons.arrow_forward_ios_rounded, size: 18, color: color),
            ],
          ),
        ),
      ),
    );
  }
}

class _KeyBadge extends StatelessWidget {
  final String label;
  const _KeyBadge(this.label);

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: AppColors.primary.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: AppColors.primary.withValues(alpha: 0.3)),
      ),
      child: Text(
        label,
        style: GoogleFonts.robotoMono(
          fontSize: 11,
          fontWeight: FontWeight.w600,
          color: AppColors.primary,
        ),
      ),
    );
  }
}
