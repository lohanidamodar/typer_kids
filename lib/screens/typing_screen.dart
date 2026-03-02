import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';

import '../core/theme/app_colors.dart';
import '../models/lesson.dart';
import '../providers/progress_provider.dart';
import '../providers/typing_provider.dart';
import '../widgets/finger_guide.dart';
import '../widgets/keyboard_widget.dart';
import '../widgets/typing_display.dart';

/// The main typing practice screen where kids do the actual typing exercises
class TypingScreen extends StatefulWidget {
  final Lesson lesson;

  const TypingScreen({super.key, required this.lesson});

  @override
  State<TypingScreen> createState() => _TypingScreenState();
}

class _TypingScreenState extends State<TypingScreen> {
  late TypingProvider _typingProvider;
  final FocusNode _focusNode = FocusNode();
  final FocusNode _introFocusNode = FocusNode();
  bool _showIntro = true;

  @override
  void initState() {
    super.initState();
    _typingProvider = TypingProvider();
    _typingProvider.startLesson(widget.lesson);

    // Track that user started this lesson
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        Provider.of<ProgressProvider>(
          context,
          listen: false,
        ).setLastLesson(widget.lesson.id);
      }
    });
  }

  @override
  void dispose() {
    _focusNode.dispose();
    _introFocusNode.dispose();
    _typingProvider.dispose();
    super.dispose();
  }

  void _startLesson() {
    setState(() => _showIntro = false);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _focusNode.requestFocus();
    });
  }

  void _handleIntroKeyEvent(KeyEvent event) {
    if (event is! KeyDownEvent) return;
    final key = event.logicalKey;
    if (key == LogicalKeyboardKey.enter || key == LogicalKeyboardKey.space) {
      _startLesson();
    } else if (key == LogicalKeyboardKey.escape) {
      context.pop();
    }
  }

  void _handleKeyEvent(KeyEvent event) {
    if (event is! KeyDownEvent) return;
    if (_typingProvider.isFinished) return;
    if (_typingProvider.isPaused) return;

    if (event.logicalKey == LogicalKeyboardKey.escape) {
      _showQuitDialog();
      return;
    }

    final key = event.character;
    if (key != null && key.isNotEmpty) {
      _typingProvider.onKeyPressed(key);

      // If exercise complete but not last, auto advance after a brief moment
      if (_typingProvider.isExerciseComplete && !_typingProvider.isFinished) {
        Future.delayed(const Duration(milliseconds: 500), () {
          if (mounted) {
            _typingProvider.nextExercise();
          }
        });
      }

      // If lesson finished, navigate to results
      if (_typingProvider.isFinished) {
        _navigateToResults();
      }
    }
  }

  void _navigateToResults() {
    final stats = _typingProvider.stats;
    final progressProvider = Provider.of<ProgressProvider>(
      context,
      listen: false,
    );
    progressProvider.recordAttempt(widget.lesson.id, stats);

    Future.delayed(const Duration(milliseconds: 300), () {
      if (mounted) {
        context.pushReplacement(
          '/lesson/${widget.lesson.id}/results',
          extra: stats,
        );
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    if (_showIntro) {
      return _buildIntroScreen();
    }

    return ListenableBuilder(
      listenable: _typingProvider,
      builder: (context, _) => _buildTypingScreen(),
    );
  }

  Widget _buildIntroScreen() {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: KeyboardListener(
        focusNode: _introFocusNode,
        autofocus: true,
        onKeyEvent: _handleIntroKeyEvent,
        child: SafeArea(
          child: Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(32),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    widget.lesson.emoji,
                    style: const TextStyle(fontSize: 72),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    widget.lesson.title,
                    style: GoogleFonts.fredoka(
                      fontSize: 36,
                      fontWeight: FontWeight.w700,
                      color: AppColors.textPrimary,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    widget.lesson.description,
                    style: GoogleFonts.nunito(
                      fontSize: 18,
                      color: AppColors.textSecondary,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  if (widget.lesson.funTip.isNotEmpty) ...[
                    const SizedBox(height: 24),
                    Container(
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        color: AppColors.secondaryLight.withValues(alpha: 0.2),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                          color: AppColors.secondaryLight.withValues(
                            alpha: 0.5,
                          ),
                        ),
                      ),
                      child: Row(
                        children: [
                          const Text('💡', style: TextStyle(fontSize: 28)),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              widget.lesson.funTip,
                              style: GoogleFonts.nunito(
                                fontSize: 16,
                                color: AppColors.textPrimary,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                  if (widget.lesson.focusKeys.isNotEmpty) ...[
                    const SizedBox(height: 20),
                    _buildFocusKeysPreview(),
                  ],
                  const SizedBox(height: 32),
                  Text(
                    '${widget.lesson.exercises.length} exercises',
                    style: GoogleFonts.nunito(
                      fontSize: 14,
                      color: AppColors.textSecondary,
                    ),
                  ),
                  const SizedBox(height: 16),
                  SizedBox(
                    width: 240,
                    height: 56,
                    child: ElevatedButton(
                      onPressed: () => _startLesson(),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primary,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(
                            Icons.play_arrow_rounded,
                            size: 28,
                            color: Colors.white,
                          ),
                          const SizedBox(width: 8),
                          Text(
                            "Let's Go!",
                            style: GoogleFonts.fredoka(
                              fontSize: 22,
                              fontWeight: FontWeight.w600,
                              color: Colors.white,
                            ),
                          ),
                          const SizedBox(width: 6),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 5,
                              vertical: 1,
                            ),
                            decoration: BoxDecoration(
                              color: Colors.white.withValues(alpha: 0.25),
                              borderRadius: BorderRadius.circular(5),
                            ),
                            child: Text(
                              'Enter',
                              style: GoogleFonts.robotoMono(
                                fontSize: 10,
                                fontWeight: FontWeight.w600,
                                color: Colors.white,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  TextButton(
                    onPressed: () => context.pop(),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          'Go Back',
                          style: GoogleFonts.nunito(
                            color: AppColors.textSecondary,
                          ),
                        ),
                        const SizedBox(width: 6),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 5,
                            vertical: 1,
                          ),
                          decoration: BoxDecoration(
                            color: AppColors.textSecondary.withValues(
                              alpha: 0.1,
                            ),
                            borderRadius: BorderRadius.circular(5),
                            border: Border.all(
                              color: AppColors.textSecondary.withValues(
                                alpha: 0.3,
                              ),
                            ),
                          ),
                          child: Text(
                            'Esc',
                            style: GoogleFonts.robotoMono(
                              fontSize: 10,
                              fontWeight: FontWeight.w600,
                              color: AppColors.textSecondary,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildFocusKeysPreview() {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      alignment: WrapAlignment.center,
      children: widget.lesson.focusKeys.map((key) {
        return Container(
          width: 48,
          height: 48,
          decoration: BoxDecoration(
            color: AppColors.primary.withValues(alpha: 0.15),
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: AppColors.primary, width: 2),
          ),
          child: Center(
            child: Text(
              key.toUpperCase(),
              style: GoogleFonts.robotoMono(
                fontSize: 22,
                fontWeight: FontWeight.w700,
                color: AppColors.primary,
              ),
            ),
          ),
        );
      }).toList(),
    );
  }

  Widget _buildTypingScreen() {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text(widget.lesson.title),
        leading: IconButton(
          icon: const Icon(Icons.close_rounded),
          onPressed: () => _showQuitDialog(),
        ),
        actions: [
          // Exercise progress
          Padding(
            padding: const EdgeInsets.only(right: 16),
            child: Center(
              child: Text(
                '${_typingProvider.currentExerciseIndex + 1}/${_typingProvider.totalExercises}',
                style: GoogleFonts.fredoka(fontSize: 18, color: Colors.white),
              ),
            ),
          ),
        ],
      ),
      body: KeyboardListener(
        focusNode: _focusNode,
        autofocus: true,
        onKeyEvent: _handleKeyEvent,
        child: GestureDetector(
          onTap: () => _focusNode.requestFocus(),
          child: SafeArea(
            child: LayoutBuilder(
              builder: (context, constraints) {
                // Compute responsive sizes based on available space
                final maxW = constraints.maxWidth;
                final maxH = constraints.maxHeight;

                // The keyboard is ~14.5 keys wide (13 keys + padding + offsets)
                // Calculate key size to fill available width with some margin
                final keyboardWidthKeys = 15.0; // effective key-width-units
                final horizontalPad = maxW > 800 ? 32.0 : 16.0;
                final availableWidth = maxW - horizontalPad * 2;
                final keySizeFromWidth = (availableWidth / keyboardWidthKeys)
                    .clamp(28.0, 64.0);

                // Also constrain by height: keyboard ~6 keys tall, plus stats + display + guides
                final keySizeFromHeight = ((maxH * 0.38) / 6).clamp(28.0, 64.0);

                final keySize = keySizeFromWidth < keySizeFromHeight
                    ? keySizeFromWidth
                    : keySizeFromHeight;

                // Text size scales with key size — generous for readability
                final textFontSize = (keySize * 0.9).clamp(22.0, 48.0);

                return Column(
                  children: [
                    // Live stats bar
                    Padding(
                      padding: EdgeInsets.symmetric(
                        horizontal: horizontalPad,
                        vertical: 8,
                      ),
                      child: _buildLiveStats(),
                    ),
                    // Finger guide
                    FingerGuide(currentKey: _typingProvider.currentChar),
                    const SizedBox(height: 8),
                    // Text to type — takes available remaining space
                    Expanded(
                      child: Padding(
                        padding: EdgeInsets.symmetric(
                          horizontal: horizontalPad,
                        ),
                        child: Center(
                          child: TypingDisplay(
                            text: _typingProvider.currentText,
                            charStates: _typingProvider.charStates,
                            cursorPosition: _typingProvider.cursorPosition,
                            fontSize: textFontSize,
                          ),
                        ),
                      ),
                    ),
                    // "Click here to type" prompt
                    if (!_focusNode.hasFocus)
                      Padding(
                        padding: const EdgeInsets.only(bottom: 6),
                        child: _buildFocusPrompt(),
                      ),
                    // Virtual keyboard — pinned to bottom
                    Padding(
                      padding: EdgeInsets.only(
                        left: horizontalPad,
                        right: horizontalPad,
                        bottom: 12,
                      ),
                      child: Center(
                        child: KeyboardWidget(
                          activeKey: _typingProvider.currentChar,
                          showFingerColors: true,
                          keySize: keySize,
                        ),
                      ),
                    ),
                  ],
                );
              },
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildLiveStats() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _StatItem(
            icon: Icons.timer_outlined,
            label: 'Time',
            value: _formatDuration(_typingProvider.elapsed),
            color: AppColors.primary,
          ),
          _StatItem(
            icon: Icons.speed_rounded,
            label: 'WPM',
            value: _typingProvider.liveWpm.toStringAsFixed(0),
            color: AppColors.secondary,
          ),
          _StatItem(
            icon: Icons.gps_fixed_rounded,
            label: 'Accuracy',
            value: '${_typingProvider.liveAccuracy.toStringAsFixed(0)}%',
            color: _typingProvider.liveAccuracy >= 90
                ? AppColors.correct
                : _typingProvider.liveAccuracy >= 70
                ? AppColors.warning
                : AppColors.incorrect,
          ),
        ],
      ),
    );
  }

  Widget _buildFocusPrompt() {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.secondary.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.secondary.withValues(alpha: 0.3)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.mouse_rounded, color: AppColors.secondary, size: 20),
          const SizedBox(width: 8),
          Text(
            'Click here and start typing!',
            style: GoogleFonts.fredoka(
              fontSize: 16,
              color: AppColors.secondary,
            ),
          ),
        ],
      ),
    );
  }

  String _formatDuration(Duration d) {
    final minutes = d.inMinutes.remainder(60).toString().padLeft(2, '0');
    final seconds = d.inSeconds.remainder(60).toString().padLeft(2, '0');
    return '$minutes:$seconds';
  }

  void _showQuitDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) => _QuitConfirmDialog(
        onStay: () => Navigator.of(dialogContext).pop(),
        onLeave: () {
          Navigator.of(dialogContext).pop();
          context.pop();
        },
      ),
    ).then((_) {
      // Restore focus to typing area after dialog closes
      if (mounted && !_showIntro) {
        _focusNode.requestFocus();
      }
    });
  }
}

class _StatItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final Color color;

  const _StatItem({
    required this.icon,
    required this.label,
    required this.value,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Icon(icon, color: color, size: 20),
        const SizedBox(height: 2),
        Text(
          value,
          style: GoogleFonts.fredoka(
            fontSize: 18,
            fontWeight: FontWeight.w600,
            color: color,
          ),
        ),
        Text(
          label,
          style: GoogleFonts.nunito(
            fontSize: 11,
            color: AppColors.textSecondary,
          ),
        ),
      ],
    );
  }
}

/// Quit confirmation dialog with keyboard shortcuts:
/// Esc / S = Stay, Enter / L = Leave
class _QuitConfirmDialog extends StatefulWidget {
  final VoidCallback onStay;
  final VoidCallback onLeave;

  const _QuitConfirmDialog({required this.onStay, required this.onLeave});

  @override
  State<_QuitConfirmDialog> createState() => _QuitConfirmDialogState();
}

class _QuitConfirmDialogState extends State<_QuitConfirmDialog> {
  final FocusNode _dialogFocusNode = FocusNode();

  @override
  void dispose() {
    _dialogFocusNode.dispose();
    super.dispose();
  }

  void _handleDialogKey(KeyEvent event) {
    if (event is! KeyDownEvent) return;
    final key = event.logicalKey;
    if (key == LogicalKeyboardKey.escape || key == LogicalKeyboardKey.keyS) {
      widget.onStay();
    } else if (key == LogicalKeyboardKey.enter ||
        key == LogicalKeyboardKey.keyL) {
      widget.onLeave();
    }
  }

  Widget _shortcutBadge(String label, Color color) {
    return Container(
      margin: const EdgeInsets.only(left: 6),
      padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(4),
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

  @override
  Widget build(BuildContext context) {
    return KeyboardListener(
      focusNode: _dialogFocusNode,
      autofocus: true,
      onKeyEvent: _handleDialogKey,
      child: AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text(
          'Leave Lesson?',
          style: GoogleFonts.fredoka(
            fontSize: 24,
            color: AppColors.textPrimary,
          ),
        ),
        content: Text(
          'Your progress on this exercise will not be saved.',
          style: GoogleFonts.nunito(fontSize: 16),
        ),
        actions: [
          TextButton(
            onPressed: widget.onStay,
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  'Stay',
                  style: GoogleFonts.fredoka(color: AppColors.primary),
                ),
                _shortcutBadge('Esc', AppColors.primary),
              ],
            ),
          ),
          TextButton(
            onPressed: widget.onLeave,
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  'Leave',
                  style: GoogleFonts.fredoka(color: AppColors.incorrect),
                ),
                _shortcutBadge('L', AppColors.incorrect),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
