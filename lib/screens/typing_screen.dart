import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';

import '../core/theme/app_colors.dart';
import '../models/lesson.dart';
import '../providers/progress_provider.dart';
import '../providers/typing_provider.dart';
import '../widgets/finger_guide.dart';
import '../widgets/keyboard_widget.dart';
import '../widgets/typing_display.dart';
import 'results_screen.dart';

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
  bool _showIntro = true;

  @override
  void initState() {
    super.initState();
    _typingProvider = TypingProvider();
    _typingProvider.startLesson(widget.lesson);
  }

  @override
  void dispose() {
    _focusNode.dispose();
    _typingProvider.dispose();
    super.dispose();
  }

  void _handleKeyEvent(KeyEvent event) {
    if (event is! KeyDownEvent) return;
    if (_typingProvider.isFinished) return;
    if (_typingProvider.isPaused) return;

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
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(
            builder: (_) => ResultsScreen(lesson: widget.lesson, stats: stats),
          ),
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
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(32),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(widget.lesson.emoji, style: const TextStyle(fontSize: 72)),
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
                        color: AppColors.secondaryLight.withValues(alpha: 0.5),
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
                    onPressed: () {
                      setState(() => _showIntro = false);
                      // Auto-focus for keyboard input after intro
                      WidgetsBinding.instance.addPostFrameCallback((_) {
                        _focusNode.requestFocus();
                      });
                    },
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
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                TextButton(
                  onPressed: () => Navigator.of(context).pop(),
                  child: Text(
                    'Go Back',
                    style: GoogleFonts.nunito(color: AppColors.textSecondary),
                  ),
                ),
              ],
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
                return SingleChildScrollView(
                  padding: const EdgeInsets.all(16),
                  child: ConstrainedBox(
                    constraints: BoxConstraints(
                      minHeight: constraints.maxHeight - 32,
                    ),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        // Live stats bar
                        _buildLiveStats(),
                        const SizedBox(height: 16),
                        // Finger guide
                        FingerGuide(currentKey: _typingProvider.currentChar),
                        const SizedBox(height: 12),
                        // Text to type
                        TypingDisplay(
                          text: _typingProvider.currentText,
                          charStates: _typingProvider.charStates,
                          cursorPosition: _typingProvider.cursorPosition,
                        ),
                        const SizedBox(height: 8),
                        // "Click here to type" prompt
                        if (!_focusNode.hasFocus)
                          _buildFocusPrompt()
                        else
                          const SizedBox(height: 32),
                        const SizedBox(height: 12),
                        // Virtual keyboard
                        FittedBox(
                          child: KeyboardWidget(
                            activeKey: _typingProvider.currentChar,
                            showFingerColors: true,
                          ),
                        ),
                      ],
                    ),
                  ),
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
      builder: (context) => AlertDialog(
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
            onPressed: () => Navigator.of(context).pop(),
            child: Text(
              'Stay',
              style: GoogleFonts.fredoka(color: AppColors.primary),
            ),
          ),
          TextButton(
            onPressed: () {
              Navigator.of(context).pop(); // Close dialog
              Navigator.of(context).pop(); // Close typing screen
            },
            child: Text(
              'Leave',
              style: GoogleFonts.fredoka(color: AppColors.incorrect),
            ),
          ),
        ],
      ),
    );
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
