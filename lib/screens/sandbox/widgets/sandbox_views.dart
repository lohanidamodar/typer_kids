import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../core/theme/app_colors.dart';
import '../../../data/story_content.dart';
import '../../../data/word_lists.dart';
import '../../../widgets/difficulty_card.dart';
import '../../../widgets/stat_tiles.dart';

/// Setup/menu view for the sandbox — difficulty + story selection.
class SandboxSetupView extends StatelessWidget {
  final FocusNode focusNode;
  final ContentDifficulty difficulty;
  final List<StoryPassage> passages;

  /// The chosen story, or null for "surprise me" (random each round).
  final StoryPassage? selectedPassage;
  final ValueChanged<ContentDifficulty> onDifficultyChanged;
  final ValueChanged<StoryPassage?> onPassageChanged;
  final VoidCallback onStart;
  final VoidCallback onBack;

  const SandboxSetupView({
    super.key,
    required this.focusNode,
    required this.difficulty,
    required this.passages,
    required this.selectedPassage,
    required this.onDifficultyChanged,
    required this.onPassageChanged,
    required this.onStart,
    required this.onBack,
  });

  void _handleKey(KeyEvent event) {
    if (event is! KeyDownEvent) return;
    final key = event.logicalKey;
    if (key == LogicalKeyboardKey.escape) {
      onBack();
    } else if (key == LogicalKeyboardKey.enter ||
        key == LogicalKeyboardKey.space) {
      onStart();
    } else if (key == LogicalKeyboardKey.digit1) {
      onDifficultyChanged(ContentDifficulty.easy);
    } else if (key == LogicalKeyboardKey.digit2) {
      onDifficultyChanged(ContentDifficulty.medium);
    } else if (key == LogicalKeyboardKey.digit3) {
      onDifficultyChanged(ContentDifficulty.hard);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: KeyboardListener(
        focusNode: focusNode,
        autofocus: true,
        onKeyEvent: _handleKey,
        child: SafeArea(
          child: Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(32),
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 480),
                child: Column(
                  children: [
                    Align(
                      alignment: Alignment.centerLeft,
                      child: TextButton.icon(
                        onPressed: onBack,
                        icon: const Icon(Icons.arrow_back_rounded, size: 18),
                        label: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              'Back',
                              style: GoogleFonts.fredoka(fontSize: 16),
                            ),
                            const SizedBox(width: 6),
                            _keyBadge('Esc', AppColors.textSecondary),
                          ],
                        ),
                        style: TextButton.styleFrom(
                          foregroundColor: AppColors.textSecondary,
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    const Text('📖', style: TextStyle(fontSize: 56)),
                    const SizedBox(height: 8),
                    Text(
                      'Free Practice',
                      style: GoogleFonts.fredoka(
                        fontSize: 34,
                        fontWeight: FontWeight.w700,
                        color: AppColors.secondary,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Type passages from classic stories at your own pace',
                      style: GoogleFonts.nunito(
                        fontSize: 16,
                        color: AppColors.textSecondary,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 32),
                    Text(
                      'Choose Difficulty',
                      style: GoogleFonts.fredoka(
                        fontSize: 20,
                        fontWeight: FontWeight.w600,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 14),
                    Row(
                      children: ContentDifficulty.values.map((d) {
                        final selected = d == difficulty;
                        return Expanded(
                          child: Padding(
                            padding: EdgeInsets.only(
                              left: d.index == 0 ? 0 : 6,
                              right: d.index == 2 ? 0 : 6,
                            ),
                            child: DifficultyCard(
                              difficulty: d,
                              index: d.index + 1,
                              selected: selected,
                              accentColor: AppColors.secondary,
                              onTap: () => onDifficultyChanged(d),
                            ),
                          ),
                        );
                      }).toList(),
                    ),
                    const SizedBox(height: 24),
                    Text(
                      'Pick a Story',
                      style: GoogleFonts.fredoka(
                        fontSize: 20,
                        fontWeight: FontWeight.w600,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 12),
                    _buildStoryPicker(),
                    const SizedBox(height: 32),
                    SizedBox(
                      width: 240,
                      height: 56,
                      child: ElevatedButton(
                        onPressed: onStart,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.secondary,
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                          ),
                          elevation: 4,
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Icon(Icons.play_arrow_rounded, size: 28),
                            const SizedBox(width: 8),
                            Text(
                              'Start',
                              style: GoogleFonts.fredoka(
                                fontSize: 22,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            const SizedBox(width: 8),
                            _keyBadge('Enter', Colors.white),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  /// Dropdown of stories for the chosen difficulty, with a "surprise me"
  /// option (null) that picks a random passage each round.
  Widget _buildStoryPicker() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: AppColors.secondary.withValues(alpha: 0.4),
          width: 2,
        ),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<StoryPassage?>(
          value: selectedPassage,
          isExpanded: true,
          borderRadius: BorderRadius.circular(14),
          icon: const Icon(
            Icons.expand_more_rounded,
            color: AppColors.secondary,
          ),
          style: GoogleFonts.nunito(
            fontSize: 16,
            fontWeight: FontWeight.w700,
            color: AppColors.textPrimary,
          ),
          items: [
            DropdownMenuItem<StoryPassage?>(
              value: null,
              child: Text(
                '🎲 Surprise me!',
                style: GoogleFonts.nunito(
                  fontSize: 16,
                  fontWeight: FontWeight.w800,
                  color: AppColors.secondary,
                ),
              ),
            ),
            for (final passage in passages)
              DropdownMenuItem<StoryPassage?>(
                value: passage,
                child: Text(
                  '📖 ${passage.title} — ${passage.source}',
                  overflow: TextOverflow.ellipsis,
                ),
              ),
          ],
          onChanged: onPassageChanged,
        ),
      ),
    );
  }
}
/// Completion/results view for the sandbox — stars, stats, and actions.
class SandboxDoneView extends StatelessWidget {
  final FocusNode focusNode;
  final StoryPassage? passage;
  final Duration elapsed;
  final double wpm;
  final double accuracy;
  final int correctCount;
  final int incorrectCount;
  final int totalTyped;
  final VoidCallback onTryAnother;
  final VoidCallback onBack;

  const SandboxDoneView({
    super.key,
    required this.focusNode,
    required this.passage,
    required this.elapsed,
    required this.wpm,
    required this.accuracy,
    required this.correctCount,
    required this.incorrectCount,
    required this.totalTyped,
    required this.onTryAnother,
    required this.onBack,
  });

  void _handleKey(KeyEvent event) {
    if (event is! KeyDownEvent) return;
    if (event.logicalKey == LogicalKeyboardKey.enter ||
        event.logicalKey == LogicalKeyboardKey.space) {
      onTryAnother();
    } else if (event.logicalKey == LogicalKeyboardKey.escape) {
      onBack();
    }
  }

  @override
  Widget build(BuildContext context) {
    final minutes = elapsed.inMinutes.remainder(60).toString().padLeft(2, '0');
    final seconds = elapsed.inSeconds.remainder(60).toString().padLeft(2, '0');

    int stars;
    if (accuracy >= 98) {
      stars = 5;
    } else if (accuracy >= 95) {
      stars = 4;
    } else if (accuracy >= 90) {
      stars = 3;
    } else if (accuracy >= 80) {
      stars = 2;
    } else {
      stars = 1;
    }

    return Scaffold(
      backgroundColor: AppColors.background,
      body: KeyboardListener(
        focusNode: focusNode,
        autofocus: true,
        onKeyEvent: _handleKey,
        child: SafeArea(
          child: Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(32),
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 440),
                child: Column(
                  children: [
                    const Text('🎉', style: TextStyle(fontSize: 56)),
                    const SizedBox(height: 8),
                    Text(
                      'Well Done!',
                      style: GoogleFonts.fredoka(
                        fontSize: 34,
                        fontWeight: FontWeight.w700,
                        color: AppColors.primary,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '"${passage?.title}" — ${passage?.source}',
                      style: GoogleFonts.nunito(
                        fontSize: 14,
                        fontStyle: FontStyle.italic,
                        color: AppColors.textSecondary,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 20),
                    // Stars
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: List.generate(
                        5,
                        (i) => Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 2),
                          child: Icon(
                            i < stars
                                ? Icons.star_rounded
                                : Icons.star_border_rounded,
                            color: i < stars
                                ? AppColors.starFilled
                                : AppColors.starEmpty,
                            size: 36,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 20),
                    // Stats
                    Row(
                      children: [
                        EmojiStatTile(
                          emoji: '⏱️',
                          label: 'Time',
                          value: '$minutes:$seconds',
                        ),
                        const SizedBox(width: 12),
                        EmojiStatTile(
                          emoji: '⚡',
                          label: 'WPM',
                          value: wpm.toStringAsFixed(0),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        EmojiStatTile(
                          emoji: '🎯',
                          label: 'Accuracy',
                          value: '${accuracy.toStringAsFixed(1)}%',
                        ),
                        const SizedBox(width: 12),
                        EmojiStatTile(
                          emoji: '✅',
                          label: 'Correct',
                          value: '$correctCount',
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        EmojiStatTile(
                          emoji: '❌',
                          label: 'Errors',
                          value: '$incorrectCount',
                        ),
                        const SizedBox(width: 12),
                        EmojiStatTile(
                          emoji: '🔤',
                          label: 'Total',
                          value: '$totalTyped',
                        ),
                      ],
                    ),
                    const SizedBox(height: 32),
                    // Try another
                    SizedBox(
                      width: double.infinity,
                      height: 56,
                      child: ElevatedButton(
                        onPressed: onTryAnother,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.secondary,
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                          ),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Icon(Icons.refresh_rounded, size: 24),
                            const SizedBox(width: 8),
                            Text(
                              'Try Another',
                              style: GoogleFonts.fredoka(fontSize: 20),
                            ),
                            const SizedBox(width: 8),
                            _keyBadge('Enter', Colors.white),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),
                    TextButton.icon(
                      onPressed: onBack,
                      icon: const Icon(Icons.arrow_back_rounded, size: 18),
                      label: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            'Back',
                            style: GoogleFonts.fredoka(fontSize: 16),
                          ),
                          const SizedBox(width: 6),
                          _keyBadge('Esc', AppColors.textSecondary),
                        ],
                      ),
                      style: TextButton.styleFrom(
                        foregroundColor: AppColors.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// Keycap-style badge used on the sandbox setup/done buttons.
/// (Intentionally kept local: alpha 0.18 / radius 5 differs from
/// the shared ShortcutBadge variants.)
Widget _keyBadge(String label, Color color) {
  return Container(
    padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
    decoration: BoxDecoration(
      color: color.withValues(alpha: 0.18),
      borderRadius: BorderRadius.circular(5),
      border: Border.all(color: color.withValues(alpha: 0.3)),
    ),
    child: Text(
      label,
      style: GoogleFonts.robotoMono(
        fontSize: 10,
        fontWeight: FontWeight.w600,
        color: color,
      ),
    ),
  );
}
