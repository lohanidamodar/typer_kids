import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../core/theme/app_colors.dart';
import '../../data/story_content.dart';
import '../../data/word_lists.dart';
import '../../providers/typing_provider.dart';

// ─────────────────────────────────────────────────────────────────────────────
// Phases
// ─────────────────────────────────────────────────────────────────────────────

enum _Phase { setup, typing, done }

// ─────────────────────────────────────────────────────────────────────────────
// Time durations offered in setup
// ─────────────────────────────────────────────────────────────────────────────

enum _TestDuration {
  seconds30(30, '30 s', '⚡'),
  minute1(60, '1 min', '⏱️'),
  minutes2(120, '2 min', '🕐'),
  minutes5(300, '5 min', '🕔');

  const _TestDuration(this.seconds, this.label, this.emoji);
  final int seconds;
  final String label;
  final String emoji;
}

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
  _TestDuration _duration = _TestDuration.minute1;

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
      builder: (ctx) => _QuitDialog(
        onStay: () => Navigator.of(ctx).pop(),
        onLeave: () {
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
      _Phase.setup => _buildSetup(),
      _Phase.typing => _buildTyping(),
      _Phase.done => _buildDone(),
    };
  }

  // ── Setup ─────────────────────────────────────────────────────────────────

  void _handleSetupKey(KeyEvent event) {
    if (event is! KeyDownEvent) return;
    final key = event.logicalKey;
    if (key == LogicalKeyboardKey.escape) {
      context.pop();
    } else if (key == LogicalKeyboardKey.enter ||
        key == LogicalKeyboardKey.space) {
      _start();
    } else if (key == LogicalKeyboardKey.digit1) {
      setState(() => _difficulty = ContentDifficulty.easy);
    } else if (key == LogicalKeyboardKey.digit2) {
      setState(() => _difficulty = ContentDifficulty.medium);
    } else if (key == LogicalKeyboardKey.digit3) {
      setState(() => _difficulty = ContentDifficulty.hard);
    } else if (key == LogicalKeyboardKey.keyA) {
      setState(() => _duration = _TestDuration.seconds30);
    } else if (key == LogicalKeyboardKey.keyB) {
      setState(() => _duration = _TestDuration.minute1);
    } else if (key == LogicalKeyboardKey.keyC) {
      setState(() => _duration = _TestDuration.minutes2);
    } else if (key == LogicalKeyboardKey.keyD) {
      setState(() => _duration = _TestDuration.minutes5);
    }
  }

  Widget _buildSetup() {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: KeyboardListener(
        focusNode: _setupFocusNode,
        autofocus: true,
        onKeyEvent: _handleSetupKey,
        child: SafeArea(
          child: Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(32),
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 480),
                child: Column(
                  children: [
                    // Back
                    Align(
                      alignment: Alignment.centerLeft,
                      child: TextButton.icon(
                        onPressed: () => context.pop(),
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
                    const Text('⏱️', style: TextStyle(fontSize: 56)),
                    const SizedBox(height: 8),
                    Text(
                      'Typing Test',
                      style: GoogleFonts.fredoka(
                        fontSize: 34,
                        fontWeight: FontWeight.w700,
                        color: AppColors.accent,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Test your typing speed and accuracy!',
                      style: GoogleFonts.nunito(
                        fontSize: 16,
                        color: AppColors.textSecondary,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 28),

                    // ── Difficulty selector ──
                    Text(
                      'Difficulty',
                      style: GoogleFonts.fredoka(
                        fontSize: 20,
                        fontWeight: FontWeight.w600,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: ContentDifficulty.values.map((d) {
                        final selected = d == _difficulty;
                        return Expanded(
                          child: Padding(
                            padding: EdgeInsets.only(
                              left: d.index == 0 ? 0 : 6,
                              right: d.index == 2 ? 0 : 6,
                            ),
                            child: _DifficultyCard(
                              difficulty: d,
                              index: d.index + 1,
                              selected: selected,
                              onTap: () => setState(() => _difficulty = d),
                              accentColor: AppColors.accent,
                            ),
                          ),
                        );
                      }).toList(),
                    ),
                    const SizedBox(height: 24),

                    // ── Duration selector ──
                    Text(
                      'Duration',
                      style: GoogleFonts.fredoka(
                        fontSize: 20,
                        fontWeight: FontWeight.w600,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: _TestDuration.values.map((d) {
                        final selected = d == _duration;
                        final shortcut = String.fromCharCode(
                          65 + d.index, // A, B, C, D
                        );
                        return Expanded(
                          child: Padding(
                            padding: EdgeInsets.only(
                              left: d.index == 0 ? 0 : 4,
                              right: d.index == _TestDuration.values.length - 1
                                  ? 0
                                  : 4,
                            ),
                            child: _TimeDurationCard(
                              duration: d,
                              shortcut: shortcut,
                              selected: selected,
                              onTap: () => setState(() => _duration = d),
                            ),
                          ),
                        );
                      }).toList(),
                    ),
                    const SizedBox(height: 32),

                    // ── Start button ──
                    SizedBox(
                      width: 240,
                      height: 56,
                      child: ElevatedButton(
                        onPressed: _start,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.accent,
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
                            const SizedBox(width: 6),
                            Flexible(
                              child: Text(
                                'Start Test',
                                style: GoogleFonts.fredoka(
                                  fontSize: 22,
                                  fontWeight: FontWeight.w600,
                                ),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                            const SizedBox(width: 6),
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
                          _LiveStat(
                            icon: Icons.timer_outlined,
                            label: 'Remaining',
                            value: '$mins:$secs',
                            color: timerColor,
                          ),
                          _LiveStat(
                            icon: Icons.speed_rounded,
                            label: 'WPM',
                            value: _wpm.toStringAsFixed(0),
                            color: AppColors.secondary,
                          ),
                          _LiveStat(
                            icon: Icons.gps_fixed_rounded,
                            label: 'Accuracy',
                            value: '${_accuracy.toStringAsFixed(0)}%',
                            color: _accuracy >= 90
                                ? AppColors.correct
                                : _accuracy >= 70
                                ? AppColors.warning
                                : AppColors.incorrect,
                          ),
                          _LiveStat(
                            icon: Icons.text_fields_rounded,
                            label: 'Chars',
                            value: '$_correctCount',
                            color: AppColors.accent,
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
                    padding: const EdgeInsets.symmetric(horizontal: 24),
                    child: Center(child: _buildTypingDisplay()),
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

  Widget _buildTypingDisplay() {
    // Show a window of text around the cursor for readability.
    // We display up to 200 chars behind and 300 chars ahead of cursor.
    final windowStart = (_cursor - 200).clamp(0, _text.length);
    final windowEnd = (_cursor + 300).clamp(0, _text.length);

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.accentLight, width: 2),
        boxShadow: [
          BoxShadow(
            color: AppColors.accent.withValues(alpha: 0.1),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: SingleChildScrollView(
        child: Wrap(
          alignment: WrapAlignment.center,
          runAlignment: WrapAlignment.center,
          children: List.generate(windowEnd - windowStart, (offset) {
            final i = windowStart + offset;
            final char = _text[i];
            final state = _charStates[i];

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
                bgColor = AppColors.accent.withValues(alpha: 0.3);
                textColor = AppColors.textPrimary;
              case CharState.pending:
                bgColor = Colors.transparent;
                textColor = Colors.grey.shade500;
            }

            return Container(
              padding: const EdgeInsets.symmetric(horizontal: 1, vertical: 2),
              decoration: BoxDecoration(
                color: bgColor,
                borderRadius: BorderRadius.circular(3),
                border: state == CharState.current
                    ? const Border(
                        bottom: BorderSide(color: AppColors.accent, width: 3),
                      )
                    : null,
              ),
              child: Text(
                char == ' ' ? '␣' : char,
                style: GoogleFonts.sourceCodePro(
                  fontSize: 22,
                  fontWeight: state == CharState.current
                      ? FontWeight.w700
                      : FontWeight.w500,
                  color: textColor,
                  letterSpacing: 1,
                  decoration: state == CharState.incorrect
                      ? TextDecoration.lineThrough
                      : null,
                ),
              ),
            );
          }),
        ),
      ),
    );
  }

  // ── Done ──────────────────────────────────────────────────────────────────

  void _handleDoneKey(KeyEvent event) {
    if (event is! KeyDownEvent) return;
    if (event.logicalKey == LogicalKeyboardKey.enter ||
        event.logicalKey == LogicalKeyboardKey.space) {
      _tryAgain();
    } else if (event.logicalKey == LogicalKeyboardKey.escape) {
      context.pop();
    }
  }

  Widget _buildDone() {
    final elapsedSecs = _duration.seconds - _remainingSeconds;
    final mins = (elapsedSecs ~/ 60).toString().padLeft(2, '0');
    final secs = (elapsedSecs % 60).toString().padLeft(2, '0');

    // Final WPM based on actual elapsed time
    final finalWpm = elapsedSecs > 0
        ? (_correctCount / 5.0) / (elapsedSecs / 60.0)
        : 0.0;

    // Star rating based on WPM + accuracy
    int stars;
    if (finalWpm >= 60 && _accuracy >= 95) {
      stars = 5;
    } else if (finalWpm >= 40 && _accuracy >= 90) {
      stars = 4;
    } else if (finalWpm >= 25 && _accuracy >= 85) {
      stars = 3;
    } else if (finalWpm >= 15 && _accuracy >= 75) {
      stars = 2;
    } else {
      stars = 1;
    }

    // Speed rating label
    String speedLabel;
    String speedEmoji;
    if (finalWpm >= 60) {
      speedLabel = 'Lightning Fast!';
      speedEmoji = '⚡';
    } else if (finalWpm >= 40) {
      speedLabel = 'Super Speedy!';
      speedEmoji = '🚀';
    } else if (finalWpm >= 25) {
      speedLabel = 'Great Job!';
      speedEmoji = '🎉';
    } else if (finalWpm >= 15) {
      speedLabel = 'Good Work!';
      speedEmoji = '👍';
    } else {
      speedLabel = 'Keep Practicing!';
      speedEmoji = '💪';
    }

    return Scaffold(
      backgroundColor: AppColors.background,
      body: KeyboardListener(
        focusNode: _doneFocusNode,
        autofocus: true,
        onKeyEvent: _handleDoneKey,
        child: SafeArea(
          child: Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(32),
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 440),
                child: Column(
                  children: [
                    Text(speedEmoji, style: const TextStyle(fontSize: 56)),
                    const SizedBox(height: 8),
                    Text(
                      speedLabel,
                      style: GoogleFonts.fredoka(
                        fontSize: 34,
                        fontWeight: FontWeight.w700,
                        color: AppColors.accent,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '${_difficulty.emoji} ${_difficulty.label} · ${_duration.label} test',
                      style: GoogleFonts.nunito(
                        fontSize: 14,
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

                    // ── Big WPM display ──
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.symmetric(vertical: 20),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [
                            AppColors.accent.withValues(alpha: 0.08),
                            AppColors.accentLight.withValues(alpha: 0.12),
                          ],
                        ),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                          color: AppColors.accent.withValues(alpha: 0.25),
                        ),
                      ),
                      child: Column(
                        children: [
                          Text(
                            finalWpm.toStringAsFixed(1),
                            style: GoogleFonts.fredoka(
                              fontSize: 52,
                              fontWeight: FontWeight.w700,
                              color: AppColors.accent,
                            ),
                          ),
                          Text(
                            'Words Per Minute',
                            style: GoogleFonts.nunito(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                              color: AppColors.textSecondary,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),

                    // Stats
                    Row(
                      children: [
                        _ResultStat(
                          emoji: '⏱️',
                          label: 'Time',
                          value: '$mins:$secs',
                        ),
                        const SizedBox(width: 12),
                        _ResultStat(
                          emoji: '🎯',
                          label: 'Accuracy',
                          value: '${_accuracy.toStringAsFixed(1)}%',
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        _ResultStat(
                          emoji: '✅',
                          label: 'Correct',
                          value: '$_correctCount',
                        ),
                        const SizedBox(width: 12),
                        _ResultStat(
                          emoji: '❌',
                          label: 'Errors',
                          value: '$_incorrectCount',
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        _ResultStat(
                          emoji: '🔤',
                          label: 'Total Chars',
                          value: '$_totalTyped',
                        ),
                        const SizedBox(width: 12),
                        _ResultStat(
                          emoji: '📝',
                          label: 'Passages',
                          value: '${_passageTitles.length}',
                        ),
                      ],
                    ),
                    const SizedBox(height: 32),

                    // Try again
                    SizedBox(
                      width: double.infinity,
                      height: 56,
                      child: ElevatedButton(
                        onPressed: _tryAgain,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.accent,
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
                              'Test Again',
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
                      onPressed: () => context.pop(),
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

  // ── Shared helpers ────────────────────────────────────────────────────────

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
}

// ─────────────────────────────────────────────────────────────────────────────
// Extracted widgets
// ─────────────────────────────────────────────────────────────────────────────

class _DifficultyCard extends StatelessWidget {
  final ContentDifficulty difficulty;
  final int index;
  final bool selected;
  final VoidCallback onTap;
  final Color accentColor;

  const _DifficultyCard({
    required this.difficulty,
    required this.index,
    required this.selected,
    required this.onTap,
    required this.accentColor,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 160),
        padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 8),
        decoration: BoxDecoration(
          color: selected ? accentColor.withValues(alpha: 0.12) : Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: selected ? accentColor : Colors.grey.shade300,
            width: selected ? 2.5 : 1,
          ),
          boxShadow: selected
              ? [
                  BoxShadow(
                    color: accentColor.withValues(alpha: 0.15),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ]
              : null,
        ),
        child: Column(
          children: [
            Text(difficulty.emoji, style: const TextStyle(fontSize: 28)),
            const SizedBox(height: 4),
            Text(
              difficulty.label,
              style: GoogleFonts.fredoka(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: selected ? accentColor : AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              difficulty.description,
              style: GoogleFonts.nunito(
                fontSize: 11,
                color: AppColors.textSecondary,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 6),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
              decoration: BoxDecoration(
                color: accentColor.withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(4),
                border: Border.all(color: accentColor.withValues(alpha: 0.2)),
              ),
              child: Text(
                '$index',
                style: GoogleFonts.robotoMono(
                  fontSize: 10,
                  fontWeight: FontWeight.w600,
                  color: accentColor,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _TimeDurationCard extends StatelessWidget {
  final _TestDuration duration;
  final String shortcut;
  final bool selected;
  final VoidCallback onTap;

  const _TimeDurationCard({
    required this.duration,
    required this.shortcut,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 160),
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 6),
        decoration: BoxDecoration(
          color: selected
              ? AppColors.accent.withValues(alpha: 0.12)
              : Colors.white,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: selected ? AppColors.accent : Colors.grey.shade300,
            width: selected ? 2.5 : 1,
          ),
          boxShadow: selected
              ? [
                  BoxShadow(
                    color: AppColors.accent.withValues(alpha: 0.15),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ]
              : null,
        ),
        child: Column(
          children: [
            Text(duration.emoji, style: const TextStyle(fontSize: 22)),
            const SizedBox(height: 3),
            Text(
              duration.label,
              style: GoogleFonts.fredoka(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: selected ? AppColors.accent : AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: 5),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
              decoration: BoxDecoration(
                color: AppColors.accent.withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(4),
                border: Border.all(
                  color: AppColors.accent.withValues(alpha: 0.2),
                ),
              ),
              child: Text(
                shortcut,
                style: GoogleFonts.robotoMono(
                  fontSize: 10,
                  fontWeight: FontWeight.w600,
                  color: AppColors.accent,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _LiveStat extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final Color color;

  const _LiveStat({
    required this.icon,
    required this.label,
    required this.value,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Icon(icon, color: color, size: 18),
        const SizedBox(height: 2),
        Text(
          value,
          style: GoogleFonts.fredoka(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color: color,
          ),
        ),
        Text(
          label,
          style: GoogleFonts.nunito(
            fontSize: 10,
            color: AppColors.textSecondary,
          ),
        ),
      ],
    );
  }
}

class _ResultStat extends StatelessWidget {
  final String emoji;
  final String label;
  final String value;

  const _ResultStat({
    required this.emoji,
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: Colors.grey.shade200),
        ),
        child: Column(
          children: [
            Text(emoji, style: const TextStyle(fontSize: 22)),
            const SizedBox(height: 4),
            Text(
              value,
              style: GoogleFonts.fredoka(
                fontSize: 22,
                fontWeight: FontWeight.w600,
                color: AppColors.textPrimary,
              ),
            ),
            Text(
              label,
              style: GoogleFonts.nunito(
                fontSize: 12,
                color: AppColors.textSecondary,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Quit confirmation dialog with keyboard shortcuts.
class _QuitDialog extends StatefulWidget {
  final VoidCallback onStay;
  final VoidCallback onLeave;

  const _QuitDialog({required this.onStay, required this.onLeave});

  @override
  State<_QuitDialog> createState() => _QuitDialogState();
}

class _QuitDialogState extends State<_QuitDialog> {
  final _focusNode = FocusNode();

  @override
  void dispose() {
    _focusNode.dispose();
    super.dispose();
  }

  void _handleKey(KeyEvent event) {
    if (event is! KeyDownEvent) return;
    final key = event.logicalKey;
    if (key == LogicalKeyboardKey.escape || key == LogicalKeyboardKey.keyS) {
      widget.onStay();
    } else if (key == LogicalKeyboardKey.enter ||
        key == LogicalKeyboardKey.keyL) {
      widget.onLeave();
    }
  }

  Widget _badge(String label, Color color) => Container(
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

  @override
  Widget build(BuildContext context) {
    return KeyboardListener(
      focusNode: _focusNode,
      autofocus: true,
      onKeyEvent: _handleKey,
      child: AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text(
          'End Test?',
          style: GoogleFonts.fredoka(
            fontSize: 24,
            color: AppColors.textPrimary,
          ),
        ),
        content: Text(
          'Your test results won\'t be saved.',
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
                _badge('Esc', AppColors.primary),
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
                _badge('L', AppColors.incorrect),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
