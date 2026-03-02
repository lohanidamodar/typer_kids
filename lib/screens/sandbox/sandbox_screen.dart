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
// Screen
// ─────────────────────────────────────────────────────────────────────────────

/// Free typing sandbox — practice at your own pace with story passages.
class SandboxScreen extends StatefulWidget {
  const SandboxScreen({super.key});

  @override
  State<SandboxScreen> createState() => _SandboxScreenState();
}

class _SandboxScreenState extends State<SandboxScreen> {
  // ── State ──
  _Phase _phase = _Phase.setup;
  ContentDifficulty _difficulty = ContentDifficulty.easy;

  // Passage
  StoryPassage? _passage;
  String _text = '';

  // Typing state
  int _cursor = 0;
  List<CharState> _charStates = [];
  int _correctCount = 0;
  int _incorrectCount = 0;
  int _totalTyped = 0;

  // Timer
  DateTime? _startTime;
  Timer? _timer;
  Duration _elapsed = Duration.zero;

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
    if (_elapsed.inSeconds == 0) return 0;
    return (_correctCount / 5.0) / (_elapsed.inSeconds / 60.0);
  }

  // ── Actions ──
  void _start() {
    _passage = StoryContent.randomPassage(_difficulty);
    _text = _passage!.text;
    _cursor = 0;
    _charStates = List.filled(_text.length, CharState.pending);
    if (_charStates.isNotEmpty) _charStates[0] = CharState.current;
    _correctCount = 0;
    _incorrectCount = 0;
    _totalTyped = 0;
    _startTime = null;
    _timer?.cancel();
    _elapsed = Duration.zero;
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

    // Start timer on first real keypress
    _startTime ??= DateTime.now();
    _timer ??= Timer.periodic(const Duration(seconds: 1), (_) {
      if (_startTime != null && mounted) {
        setState(() => _elapsed = DateTime.now().difference(_startTime!));
      }
    });

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

    // Finished
    if (_cursor >= _text.length) {
      _timer?.cancel();
      _elapsed = DateTime.now().difference(_startTime!);
      _phase = _Phase.done;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _doneFocusNode.requestFocus();
      });
    }

    setState(() {});
  }

  void _tryAnother() {
    _phase = _Phase.setup;
    setState(() {});
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _setupFocusNode.requestFocus();
    });
  }

  void _showQuitDialog() {
    _timer?.cancel();
    final timerWasRunning = _startTime != null;
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
      if (_phase == _Phase.typing && mounted && timerWasRunning) {
        _timer = Timer.periodic(const Duration(seconds: 1), (_) {
          if (_startTime != null && mounted) {
            setState(() => _elapsed = DateTime.now().difference(_startTime!));
          }
        });
        _typingFocusNode.requestFocus();
      } else if (_phase == _Phase.typing && mounted) {
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
                    Align(
                      alignment: Alignment.centerLeft,
                      child: TextButton.icon(
                        onPressed: () => context.pop(),
                        icon: const Icon(Icons.arrow_back_rounded, size: 18),
                        label: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text('Back',
                                style: GoogleFonts.fredoka(fontSize: 16)),
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
                              onTap: () =>
                                  setState(() => _difficulty = d),
                            ),
                          ),
                        );
                      }).toList(),
                    ),
                    const SizedBox(height: 32),
                    SizedBox(
                      width: 240,
                      height: 56,
                      child: ElevatedButton(
                        onPressed: _start,
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

  // ── Typing ────────────────────────────────────────────────────────────────

  Widget _buildTyping() {
    final minutes =
        _elapsed.inMinutes.remainder(60).toString().padLeft(2, '0');
    final seconds =
        _elapsed.inSeconds.remainder(60).toString().padLeft(2, '0');

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text(_passage?.title ?? 'Practice'),
        leading: IconButton(
          icon: const Icon(Icons.close_rounded),
          onPressed: _showQuitDialog,
        ),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 16),
            child: Center(
              child: Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
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
                // Live stats
                Container(
                  margin:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  padding:
                      const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
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
                      _LiveStat(
                        icon: Icons.timer_outlined,
                        label: 'Time',
                        value: '$minutes:$seconds',
                        color: AppColors.primary,
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
                        label: 'Progress',
                        value:
                            '${(_cursor / _text.length * 100).toStringAsFixed(0)}%',
                        color: AppColors.accent,
                      ),
                    ],
                  ),
                ),
                // Source
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 4),
                  child: Text(
                    '— ${_passage?.source ?? ''}',
                    style: GoogleFonts.nunito(
                      fontSize: 13,
                      fontStyle: FontStyle.italic,
                      color: AppColors.textSecondary,
                    ),
                  ),
                ),
                // Typing area
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 24),
                    child: Center(
                      child: _buildTypingDisplay(),
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
                        color: AppColors.secondary.withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(
                          color: AppColors.secondary.withValues(alpha: 0.3),
                        ),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(Icons.mouse_rounded,
                              color: AppColors.secondary, size: 18),
                          const SizedBox(width: 6),
                          Text(
                            'Click here and start typing!',
                            style: GoogleFonts.fredoka(
                              fontSize: 14,
                              color: AppColors.secondary,
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
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.secondaryLight, width: 2),
        boxShadow: [
          BoxShadow(
            color: AppColors.secondary.withValues(alpha: 0.1),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: SingleChildScrollView(
        child: Wrap(
          alignment: WrapAlignment.center,
          runAlignment: WrapAlignment.center,
          children: List.generate(_text.length, (i) {
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
                bgColor = AppColors.secondary.withValues(alpha: 0.3);
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
                        bottom:
                            BorderSide(color: AppColors.secondary, width: 3),
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
      _tryAnother();
    } else if (event.logicalKey == LogicalKeyboardKey.escape) {
      context.pop();
    }
  }

  Widget _buildDone() {
    final minutes =
        _elapsed.inMinutes.remainder(60).toString().padLeft(2, '0');
    final seconds =
        _elapsed.inSeconds.remainder(60).toString().padLeft(2, '0');

    int stars;
    if (_accuracy >= 98) {
      stars = 5;
    } else if (_accuracy >= 95) {
      stars = 4;
    } else if (_accuracy >= 90) {
      stars = 3;
    } else if (_accuracy >= 80) {
      stars = 2;
    } else {
      stars = 1;
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
                      '"${_passage?.title}" — ${_passage?.source}',
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
                        _ResultStat(
                          emoji: '⏱️',
                          label: 'Time',
                          value: '$minutes:$seconds',
                        ),
                        const SizedBox(width: 12),
                        _ResultStat(
                          emoji: '⚡',
                          label: 'WPM',
                          value: _wpm.toStringAsFixed(0),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        _ResultStat(
                          emoji: '🎯',
                          label: 'Accuracy',
                          value: '${_accuracy.toStringAsFixed(1)}%',
                        ),
                        const SizedBox(width: 12),
                        _ResultStat(
                          emoji: '✅',
                          label: 'Correct',
                          value: '$_correctCount',
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        _ResultStat(
                          emoji: '❌',
                          label: 'Errors',
                          value: '$_incorrectCount',
                        ),
                        const SizedBox(width: 12),
                        _ResultStat(
                          emoji: '🔤',
                          label: 'Total',
                          value: '$_totalTyped',
                        ),
                      ],
                    ),
                    const SizedBox(height: 32),
                    // Try another
                    SizedBox(
                      width: double.infinity,
                      height: 56,
                      child: ElevatedButton(
                        onPressed: _tryAnother,
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
                      onPressed: () => context.pop(),
                      icon: const Icon(Icons.arrow_back_rounded, size: 18),
                      label: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text('Back',
                              style: GoogleFonts.fredoka(fontSize: 16)),
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

  // ── Shared ────────────────────────────────────────────────────────────────

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

  const _DifficultyCard({
    required this.difficulty,
    required this.index,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 160),
        padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 8),
        decoration: BoxDecoration(
          color: selected
              ? AppColors.secondary.withValues(alpha: 0.12)
              : Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: selected ? AppColors.secondary : Colors.grey.shade300,
            width: selected ? 2.5 : 1,
          ),
          boxShadow: selected
              ? [
                  BoxShadow(
                    color: AppColors.secondary.withValues(alpha: 0.15),
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
                color:
                    selected ? AppColors.secondary : AppColors.textPrimary,
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
                color: AppColors.secondary.withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(4),
                border: Border.all(
                  color: AppColors.secondary.withValues(alpha: 0.2),
                ),
              ),
              child: Text(
                '$index',
                style: GoogleFonts.robotoMono(
                  fontSize: 10,
                  fontWeight: FontWeight.w600,
                  color: AppColors.secondary,
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
          'Leave Practice?',
          style:
              GoogleFonts.fredoka(fontSize: 24, color: AppColors.textPrimary),
        ),
        content: Text(
          'Your progress won\'t be saved.',
          style: GoogleFonts.nunito(fontSize: 16),
        ),
        actions: [
          TextButton(
            onPressed: widget.onStay,
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text('Stay',
                    style: GoogleFonts.fredoka(color: AppColors.primary)),
                _badge('Esc', AppColors.primary),
              ],
            ),
          ),
          TextButton(
            onPressed: widget.onLeave,
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text('Leave',
                    style: GoogleFonts.fredoka(color: AppColors.incorrect)),
                _badge('L', AppColors.incorrect),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
