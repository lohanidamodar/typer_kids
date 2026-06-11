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
import 'widgets/sandbox_views.dart';

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

  // Passage — null choice means "surprise me" (random per round)
  StoryPassage? _chosenPassage;
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
    _passage = _chosenPassage ?? StoryContent.randomPassage(_difficulty);
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
      builder: (ctx) => QuitDialog(
        title: 'Leave Practice?',
        message: 'Your progress won\'t be saved.',
        onStay: () => Navigator.of(ctx).pop(),
        onQuit: () {
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

  Widget _buildSetup() {
    return SandboxSetupView(
      focusNode: _setupFocusNode,
      difficulty: _difficulty,
      passages: StoryContent.forDifficulty(_difficulty),
      selectedPassage: _chosenPassage,
      onDifficultyChanged: (d) => setState(() {
        _difficulty = d;
        // The chosen story belongs to the old difficulty's pool
        _chosenPassage = null;
      }),
      onPassageChanged: (p) => setState(() => _chosenPassage = p),
      onStart: _start,
      onBack: () => context.pop(),
    );
  }

  // ── Typing ────────────────────────────────────────────────────────────────

  Widget _buildTyping() {
    final minutes = _elapsed.inMinutes.remainder(60).toString().padLeft(2, '0');
    final seconds = _elapsed.inSeconds.remainder(60).toString().padLeft(2, '0');

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
                // Live stats
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
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    children: [
                      LiveStatItem(
                        icon: Icons.timer_outlined,
                        label: 'Time',
                        value: '$minutes:$seconds',
                        color: AppColors.primary,
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
                        label: 'Progress',
                        value:
                            '${(_cursor / _text.length * 100).toStringAsFixed(0)}%',
                        color: AppColors.accent,
                        compact: true,
                      ),
                    ],
                  ),
                ),
                // Passage progress bar
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(4),
                    child: LinearProgressIndicator(
                      value: _text.isEmpty ? 0 : _cursor / _text.length,
                      minHeight: 6,
                      backgroundColor: Colors.grey.shade200,
                      color: AppColors.secondary,
                    ),
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
                    padding: const EdgeInsets.symmetric(
                      horizontal: 24,
                      vertical: 12,
                    ),
                    child: Center(
                      child: PassageTypingDisplay(
                        text: _text,
                        charStates: _charStates,
                        cursorPosition: _cursor,
                        accentColor: AppColors.secondary,
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
                        color: AppColors.secondary.withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(
                          color: AppColors.secondary.withValues(alpha: 0.3),
                        ),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(
                            Icons.mouse_rounded,
                            color: AppColors.secondary,
                            size: 18,
                          ),
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

  // ── Done ──────────────────────────────────────────────────────────────────

  Widget _buildDone() {
    return SandboxDoneView(
      focusNode: _doneFocusNode,
      passage: _passage,
      elapsed: _elapsed,
      wpm: _wpm,
      accuracy: _accuracy,
      correctCount: _correctCount,
      incorrectCount: _incorrectCount,
      totalTyped: _totalTyped,
      onTryAnother: _tryAnother,
      onBack: () => context.pop(),
    );
  }
}
