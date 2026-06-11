import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../core/theme/app_colors.dart';
import '../../data/story_content.dart';
import '../../data/word_lists.dart';
import '../../providers/typing_provider.dart';
import '../../widgets/passage_typing_display.dart';
import '../../widgets/quit_dialog.dart';
import '../../widgets/stat_tiles.dart';
import 'widgets/time_duration_card.dart';
import 'widgets/typing_test_views.dart';

// ─────────────────────────────────────────────────────────────────────────────
// Phases
// ─────────────────────────────────────────────────────────────────────────────

enum _Phase { setup, typing, done }

// ─────────────────────────────────────────────────────────────────────────────
// Screen
// ─────────────────────────────────────────────────────────────────────────────

/// Timed typing test — type as much as you can before time runs out.
class TypingTestScreen extends StatefulWidget {
  const TypingTestScreen({super.key});

  @override
  State<TypingTestScreen> createState() => _TypingTestScreenState();
}

class _TypingTestScreenState extends State<TypingTestScreen> {
  // ── State ──
  _Phase _phase = _Phase.setup;
  ContentDifficulty _difficulty = ContentDifficulty.easy;
  TestDuration _duration = TestDuration.minute1;

  // Passage — we chain multiple passages to ensure there's enough text for
  // the entire test duration.
  String _text = '';
  List<String> _passageTitles = [];

  // Typing state
  int _cursor = 0;
  List<CharState> _charStates = [];
  int _correctCount = 0;
  int _incorrectCount = 0;
  int _totalTyped = 0;

  // Timer — counts DOWN to zero
  Timer? _timer;
  int _remainingSeconds = 60;
  bool _hasStartedTyping = false;

  // Focus
  final _setupFocusNode = FocusNode();
  final _typingFocusNode = FocusNode();
  final _doneFocusNode = FocusNode();

  @override
  void dispose() {
    _timer?.cancel();
    _setupFocusNode.dispose();
    _typingFocusNode.dispose();
    _doneFocusNode.dispose();
    super.dispose();
  }

  // ── Computed ──
  double get _accuracy =>
      _totalTyped == 0 ? 100 : (_correctCount / _totalTyped) * 100;

  double get _wpm {
    final elapsed = _duration.seconds - _remainingSeconds;
    if (elapsed <= 0) return 0;
    return (_correctCount / 5.0) / (elapsed / 60.0);
  }

  // ── Actions ──
  void _start() {
    // Build a long enough text by chaining random passages
    final buffer = StringBuffer();
    final titles = <String>[];

    // Aim for at least enough characters to keep the fastest typist busy.
    // A very fast typist might do ~120 WPM = ~600 chars/min.
    final targetLength = (_duration.seconds / 60.0 * 700).ceil();
    while (buffer.length < targetLength) {
      final passage = StoryContent.randomPassage(_difficulty);
      if (buffer.isNotEmpty) buffer.write(' ');
      buffer.write(passage.text);
      titles.add(passage.title);
    }

    _text = buffer.toString();
    _passageTitles = titles;
    _cursor = 0;
    _charStates = List.filled(_text.length, CharState.pending);
    if (_charStates.isNotEmpty) _charStates[0] = CharState.current;
    _correctCount = 0;
    _incorrectCount = 0;
    _totalTyped = 0;
    _remainingSeconds = _duration.seconds;
    _hasStartedTyping = false;
    _timer?.cancel();
    _phase = _Phase.typing;
    setState(() {});
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _typingFocusNode.requestFocus();
    });
  }

  void _onKeyEvent(KeyEvent event) {
    if (event is! KeyDownEvent && event is! KeyRepeatEvent) return;
    if (_cursor >= _text.length) return;

    if (event.logicalKey == LogicalKeyboardKey.escape) {
      _showQuitDialog();
      return;
    }

    final char = event.character;
    if (char == null || char.isEmpty) return;

    // Start countdown on first real keypress
    if (!_hasStartedTyping) {
      _hasStartedTyping = true;
      _timer = Timer.periodic(const Duration(seconds: 1), (_) {
        if (!mounted) return;
        setState(() {
          _remainingSeconds--;
          if (_remainingSeconds <= 0) {
            _remainingSeconds = 0;
            _timer?.cancel();
            _finishTest();
          }
        });
      });
    }

    _totalTyped++;
    final expected = _text[_cursor];
    if (char == expected) {
      _charStates[_cursor] = CharState.correct;
      _correctCount++;
    } else {
      _charStates[_cursor] = CharState.incorrect;
      _incorrectCount++;
    }
    _cursor++;
    if (_cursor < _text.length) {
      _charStates[_cursor] = CharState.current;
    }

    // If the user finishes all text before time runs out — rare but possible.
    if (_cursor >= _text.length) {
      _timer?.cancel();
      _finishTest();
      return;
    }

    setState(() {});
  }

  void _finishTest() {
    _timer?.cancel();
    _phase = _Phase.done;
    setState(() {});
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _doneFocusNode.requestFocus();
    });
  }

  void _tryAgain() {
    _phase = _Phase.setup;
    setState(() {});
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _setupFocusNode.requestFocus();
    });
  }

  void _showQuitDialog() {
    _timer?.cancel();
    final hadStarted = _hasStartedTyping;
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => QuitDialog(
        title: 'End Test?',
        message: 'Your test results won\'t be saved.',
        onStay: () => Navigator.of(ctx).pop(),
        onQuit: () {
          Navigator.of(ctx).pop();
          if (mounted) context.pop();
        },
      ),
    ).then((_) {
      if (_phase == _Phase.typing && mounted) {
        if (hadStarted && _remainingSeconds > 0) {
          // Resume countdown
          _timer = Timer.periodic(const Duration(seconds: 1), (_) {
            if (!mounted) return;
            setState(() {
              _remainingSeconds--;
              if (_remainingSeconds <= 0) {
                _remainingSeconds = 0;
                _timer?.cancel();
                _finishTest();
              }
            });
          });
        }
        _typingFocusNode.requestFocus();
      }
    });
  }

  // ──────────────────────────────────────────────────────────────────────────
  // BUILD
  // ──────────────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    return switch (_phase) {
      _Phase.setup => TypingTestSetup(
        focusNode: _setupFocusNode,
        difficulty: _difficulty,
        duration: _duration,
        onDifficultyChanged: (d) => setState(() => _difficulty = d),
        onDurationChanged: (d) => setState(() => _duration = d),
        onStart: _start,
      ),
      _Phase.typing => _buildTyping(),
      _Phase.done => TypingTestResults(
        focusNode: _doneFocusNode,
        difficulty: _difficulty,
        duration: _duration,
        elapsedSeconds: _duration.seconds - _remainingSeconds,
        accuracy: _accuracy,
        correctCount: _correctCount,
        incorrectCount: _incorrectCount,
        totalTyped: _totalTyped,
        passageCount: _passageTitles.length,
        onTryAgain: _tryAgain,
      ),
    };
  }

  // ── Typing ────────────────────────────────────────────────────────────────

  Widget _buildTyping() {
    final totalSeconds = _duration.seconds;
    final elapsed = totalSeconds - _remainingSeconds;
    final progress = totalSeconds > 0 ? elapsed / totalSeconds : 0.0;

    // Format remaining time as M:SS
    final mins = (_remainingSeconds ~/ 60).toString().padLeft(2, '0');
    final secs = (_remainingSeconds % 60).toString().padLeft(2, '0');

    // Timer color — turns red in the last 10 seconds
    final timerColor = _remainingSeconds <= 10
        ? AppColors.incorrect
        : AppColors.primary;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text('Typing Test — ${_duration.label}'),
        leading: IconButton(
          icon: const Icon(Icons.close_rounded),
          onPressed: _showQuitDialog,
        ),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 16),
            child: Center(
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 4,
                ),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  '${_difficulty.emoji} ${_difficulty.label}',
                  style: GoogleFonts.nunito(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: Colors.white,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
      body: KeyboardListener(
        focusNode: _typingFocusNode,
        autofocus: true,
        onKeyEvent: _onKeyEvent,
        child: GestureDetector(
          onTap: () => _typingFocusNode.requestFocus(),
          child: SafeArea(
            child: Column(
              children: [
                // ── Countdown bar ──
                Container(
                  margin: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 8,
                  ),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 20,
                    vertical: 10,
                  ),
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
                  child: Column(
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceAround,
                        children: [
                          LiveStatItem(
                            icon: Icons.timer_outlined,
                            label: 'Remaining',
                            value: '$mins:$secs',
                            color: timerColor,
                            compact: true,
                          ),
                          LiveStatItem(
                            icon: Icons.speed_rounded,
                            label: 'WPM',
                            value: _wpm.toStringAsFixed(0),
                            color: AppColors.secondary,
                            compact: true,
                          ),
                          LiveStatItem(
                            icon: Icons.gps_fixed_rounded,
                            label: 'Accuracy',
                            value: '${_accuracy.toStringAsFixed(0)}%',
                            color: _accuracy >= 90
                                ? AppColors.correct
                                : _accuracy >= 70
                                ? AppColors.warning
                                : AppColors.incorrect,
                            compact: true,
                          ),
                          LiveStatItem(
                            icon: Icons.text_fields_rounded,
                            label: 'Chars',
                            value: '$_correctCount',
                            color: AppColors.accent,
                            compact: true,
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      // Countdown progress bar
                      ClipRRect(
                        borderRadius: BorderRadius.circular(4),
                        child: LinearProgressIndicator(
                          value: progress.clamp(0.0, 1.0),
                          minHeight: 6,
                          backgroundColor: Colors.grey.shade200,
                          color: timerColor,
                        ),
                      ),
                    ],
                  ),
                ),

                // ── "Start typing!" prompt before first keypress ──
                if (!_hasStartedTyping)
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 4),
                    child: Text(
                      'Timer starts when you begin typing!',
                      style: GoogleFonts.nunito(
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                        color: AppColors.accent,
                      ),
                    ),
                  ),

                // Typing area
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 24,
                      vertical: 8,
                    ),
                    child: Center(
                      child: PassageTypingDisplay(
                        text: _text,
                        charStates: _charStates,
                        cursorPosition: _cursor,
                        accentColor: AppColors.accent,
                      ),
                    ),
                  ),
                ),

                // Focus prompt
                if (!_typingFocusNode.hasFocus)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 8),
                    child: Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: AppColors.accent.withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(
                          color: AppColors.accent.withValues(alpha: 0.3),
                        ),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(
                            Icons.mouse_rounded,
                            color: AppColors.accent,
                            size: 18,
                          ),
                          const SizedBox(width: 6),
                          Text(
                            'Click here and start typing!',
                            style: GoogleFonts.fredoka(
                              fontSize: 14,
                              color: AppColors.accent,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                const SizedBox(height: 12),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
