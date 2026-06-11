import 'dart:async';
import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';

import '../../core/theme/app_colors.dart';
import '../../core/sound_manager.dart';
import '../../data/word_lists.dart';
import '../../providers/progress_provider.dart';
import '../../widgets/quit_dialog.dart';
import 'widgets/speed_chase_views.dart';

// ─────────────────────────────────────────────────────────────────────────────
// Data
// ─────────────────────────────────────────────────────────────────────────────

enum _Phase { setup, playing, gameOver }

// ─────────────────────────────────────────────────────────────────────────────
// Screen
// ─────────────────────────────────────────────────────────────────────────────

class SpeedChaseScreen extends StatefulWidget {
  const SpeedChaseScreen({super.key});

  @override
  State<SpeedChaseScreen> createState() => _SpeedChaseScreenState();
}

class _SpeedChaseScreenState extends State<SpeedChaseScreen> {
  // ── State ──
  _Phase _phase = _Phase.setup;
  ContentDifficulty _difficulty = ContentDifficulty.easy;

  List<String> _words = [];
  int _currentIndex = 0;
  String _input = '';
  int _score = 0;
  int _errors = 0;
  bool _isNewHighScore = false;
  int _highScore = 0;

  // Timer
  Timer? _gameTimer;
  int _remainingSeconds = 0;
  int _totalSeconds = 0;
  double _ghostProgress = 0;
  Timer? _ghostTimer;

  // Focus
  final _setupFocusNode = FocusNode();
  final _gameFocusNode = FocusNode();
  final _overFocusNode = FocusNode();

  final _sfx = SoundManager();

  // ── Difficulty Config ──

  /// Adaptive ghost speed: starts gentle, ramps on correct, dips on error.
  double _adaptiveSpeed = 0.55;

  void _onCorrectAdaptive() {
    _adaptiveSpeed = (_adaptiveSpeed + 0.05).clamp(0.4, 1.4);
  }

  void _onErrorAdaptive() {
    _adaptiveSpeed = (_adaptiveSpeed - 0.07).clamp(0.4, 1.4);
  }

  int get _wordCount => switch (_difficulty) {
    ContentDifficulty.easy => 15,
    ContentDifficulty.medium => 18,
    ContentDifficulty.hard => 22,
  };

  int get _gameDuration => switch (_difficulty) {
    ContentDifficulty.easy => 60,
    ContentDifficulty.medium => 100,
    ContentDifficulty.hard => 140,
  };

  double get _ghostSpeed => _adaptiveSpeed * switch (_difficulty) {
    ContentDifficulty.easy => 0.010,
    ContentDifficulty.medium => 0.010,
    ContentDifficulty.hard => 0.010,
  };

  @override
  void dispose() {
    _gameTimer?.cancel();
    _ghostTimer?.cancel();
    _setupFocusNode.dispose();
    _gameFocusNode.dispose();
    _overFocusNode.dispose();
    super.dispose();
  }

  // ── Game Logic ──

  void _startGame() {
    // Generate word list
    final used = <String>{};
    _words = List.generate(_wordCount, (_) {
      String word;
      int tries = 0;
      do {
        word = WordLists.randomWord(_difficulty);
        tries++;
      } while (used.contains(word) && tries < 20);
      used.add(word);
      return word;
    });
    _currentIndex = 0;
    _input = '';
    _score = 0;
    _errors = 0;
    _isNewHighScore = false;
    _highScore = 0;
    _remainingSeconds = _gameDuration;
    _totalSeconds = _gameDuration;
    _ghostProgress = 0;
    _adaptiveSpeed = 0.55;
    _phase = _Phase.playing;
    _sfx.playGameStart();
    setState(() {});

    _gameTimer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (!mounted) return;
      setState(() {
        _remainingSeconds--;
        if (_remainingSeconds <= 0) _endGame();
      });
    });

    _ghostTimer = Timer.periodic(const Duration(milliseconds: 100), (_) {
      if (!mounted || _phase != _Phase.playing) return;
      setState(() {
        _ghostProgress = (_ghostProgress + _ghostSpeed / 10).clamp(0.0, 1.0);
      });
    });

    WidgetsBinding.instance.addPostFrameCallback((_) {
      _gameFocusNode.requestFocus();
    });
  }

  void _handleGameKey(KeyEvent event) {
    if (event is! KeyDownEvent && event is! KeyRepeatEvent) return;

    if (event.logicalKey == LogicalKeyboardKey.escape) {
      _showQuitDialog();
      return;
    }

    if (event.logicalKey == LogicalKeyboardKey.backspace) {
      if (_input.isNotEmpty) {
        setState(() => _input = _input.substring(0, _input.length - 1));
      }
      return;
    }

    if (event.logicalKey == LogicalKeyboardKey.space ||
        event.logicalKey == LogicalKeyboardKey.enter) {
      _submitWord();
      return;
    }

    final char = event.character;
    if (char == null || char.isEmpty) return;
    if (!RegExp(r'[a-zA-Z]').hasMatch(char)) return;

    _sfx.playKeystroke();
    setState(() => _input += char.toLowerCase());
  }

  void _submitWord() {
    if (_input.isEmpty || _currentIndex >= _words.length) return;

    final target = _words[_currentIndex];
    if (_input == target) {
      // Correct
      _score += target.length * 10 + (_remainingSeconds * 2);
      _currentIndex++;
      _input = '';
      _onCorrectAdaptive();
      _sfx.playPop();
      if (_currentIndex >= _words.length) {
        // Finished all words!
        _score += _remainingSeconds * 50; // Time bonus
        _endGame();
        return;
      }
    } else {
      _errors++;
      _input = '';
      _onErrorAdaptive();
      _sfx.playIncorrect();
    }
    setState(() {});
  }

  void _endGame() {
    _gameTimer?.cancel();
    _ghostTimer?.cancel();
    _sfx.playGameOver();
    final progress = Provider.of<ProgressProvider>(context, listen: false);
    _highScore = progress.getHighScore('speed_chase');
    progress.recordScore('speed_chase', _score).then((isNew) {
      if (mounted) setState(() => _isNewHighScore = isNew);
    });
    _phase = _Phase.gameOver;
    setState(() {});
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _overFocusNode.requestFocus();
    });
  }

  void _showQuitDialog() {
    _gameTimer?.cancel();
    _ghostTimer?.cancel();
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => QuitDialog(
        title: 'Quit Race?',
        message: 'Your current score will be lost.',
        stayLabel: 'Resume',
        quitLabel: 'Quit',
        stayBadge: 'Esc',
        quitBadge: 'Q',
        stayKey: LogicalKeyboardKey.keyR,
        quitKey: LogicalKeyboardKey.keyQ,
        onStay: () => Navigator.of(ctx).pop(),
        onQuit: () {
          Navigator.of(ctx).pop();
          if (mounted) context.pop();
        },
      ),
    ).then((_) {
      if (_phase == _Phase.playing && mounted) {
        _gameTimer = Timer.periodic(const Duration(seconds: 1), (_) {
          if (!mounted) return;
          setState(() {
            _remainingSeconds--;
            if (_remainingSeconds <= 0) _endGame();
          });
        });
        _ghostTimer = Timer.periodic(const Duration(milliseconds: 100), (_) {
          if (!mounted || _phase != _Phase.playing) return;
          setState(() {
            _ghostProgress = (_ghostProgress + _ghostSpeed / 10).clamp(
              0.0,
              1.0,
            );
          });
        });
        _gameFocusNode.requestFocus();
      }
    });
  }

  void _playAgain() {
    _phase = _Phase.setup;
    setState(() {});
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _setupFocusNode.requestFocus();
    });
  }

  double get _playerProgress =>
      _words.isEmpty ? 0 : _currentIndex / _words.length;

  // ──────────────────────────────────────────────────────────────────────────
  // BUILD
  // ──────────────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    return switch (_phase) {
      _Phase.setup => _buildSetup(),
      _Phase.playing => _buildGame(),
      _Phase.gameOver => _buildGameOver(),
    };
  }

  // ── Setup ─────────────────────────────────────────────────────────────────

  Widget _buildSetup() {
    return SpeedChaseMenu(
      difficulty: _difficulty,
      focusNode: _setupFocusNode,
      onDifficultySelected: (d) => setState(() => _difficulty = d),
      onStart: _startGame,
      onBack: () => context.pop(),
    );
  }

  // ── Playing ───────────────────────────────────────────────────────────────

  Widget _buildGame() {
    final mins = (_remainingSeconds ~/ 60).toString().padLeft(2, '0');
    final secs = (_remainingSeconds % 60).toString().padLeft(2, '0');
    final timerColor = _remainingSeconds <= 10
        ? AppColors.incorrect
        : AppColors.primary;

    return Scaffold(
      backgroundColor: AppColors.background,
      body: KeyboardListener(
        focusNode: _gameFocusNode,
        autofocus: true,
        onKeyEvent: _handleGameKey,
        child: GestureDetector(
          onTap: () => _gameFocusNode.requestFocus(),
          child: SafeArea(
            child: LayoutBuilder(
              builder: (context, constraints) {
                final screenW = constraints.maxWidth;
                final isWide = screenW > 600;
                final isLarge = screenW > 1000;
                final wordFontSize = isLarge
                    ? 28.0
                    : isWide
                    ? 22.0
                    : 18.0;
                final inputFontSize = isLarge
                    ? 30.0
                    : isWide
                    ? 24.0
                    : 20.0;

                return Column(
                  children: [
                    // Top bar
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
                        borderRadius: BorderRadius.circular(14),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.06),
                            blurRadius: 6,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: Row(
                        children: [
                          // Close button
                          InkWell(
                            onTap: _showQuitDialog,
                            borderRadius: BorderRadius.circular(8),
                            child: const Padding(
                              padding: EdgeInsets.all(4),
                              child: Icon(Icons.close_rounded, size: 22, color: AppColors.textSecondary),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Text('⭐', style: const TextStyle(fontSize: 20)),
                          const SizedBox(width: 4),
                          Text(
                            '$_score',
                            style: GoogleFonts.fredoka(
                              fontSize: 20,
                              fontWeight: FontWeight.w600,
                              color: AppColors.starFilled,
                            ),
                          ),
                          const Spacer(),
                          Icon(
                            Icons.timer_outlined,
                            color: timerColor,
                            size: 20,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            '$mins:$secs',
                            style: GoogleFonts.fredoka(
                              fontSize: 20,
                              fontWeight: FontWeight.w600,
                              color: timerColor,
                            ),
                          ),
                          const Spacer(),
                          Text(
                            '$_currentIndex/${_words.length}',
                            style: GoogleFonts.fredoka(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                              color: AppColors.textSecondary,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 3,
                            ),
                            decoration: BoxDecoration(
                              color: const Color(
                                0xFFE53935,
                              ).withValues(alpha: 0.12),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Text(
                              '${_difficulty.emoji} ${_difficulty.label}',
                              style: GoogleFonts.nunito(
                                fontSize: 12,
                                fontWeight: FontWeight.w700,
                                color: const Color(0xFFE53935),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),

                    // Race track
                    const SizedBox(height: 12),
                    _buildRaceTrack(screenW),
                    const SizedBox(height: 16),

                    // Input area (top for visibility during touch typing)
                    _buildInputArea(inputFontSize),
                    const SizedBox(height: 4),
                    Text(
                      'Press Space or Enter to submit',
                      style: GoogleFonts.nunito(
                        fontSize: 12,
                        color: AppColors.textSecondary,
                      ),
                    ),

                    // Word list area
                    Expanded(child: _buildWordArea(wordFontSize)),
                    const SizedBox(height: 4),
                  ],
                );
              },
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildRaceTrack(double screenW) {
    final trackPad = screenW > 600 ? 32.0 : 16.0;
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: trackPad),
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: Colors.grey.shade200),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Player track
            _buildTrackLane(
              '🏎️',
              'You',
              _playerProgress,
              const Color(0xFF42A5F5),
            ),
            const SizedBox(height: 8),
            // Ghost track
            _buildTrackLane(
              '👻',
              'Ghost',
              _ghostProgress,
              Colors.grey.shade400,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTrackLane(
    String emoji,
    String label,
    double progress,
    Color color,
  ) {
    return Row(
      children: [
        SizedBox(
          width: 50,
          child: Text(
            label,
            style: GoogleFonts.nunito(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: AppColors.textSecondary,
            ),
          ),
        ),
        Expanded(
          child: LayoutBuilder(
            builder: (context, constraints) {
              final trackW = constraints.maxWidth;
              final pos = (progress * (trackW - 24)).clamp(0.0, trackW - 24);

              return SizedBox(
                height: 30,
                child: Stack(
                  children: [
                    // Track
                    Positioned(
                      left: 0,
                      right: 0,
                      top: 12,
                      child: Container(
                        height: 6,
                        decoration: BoxDecoration(
                          color: Colors.grey.shade200,
                          borderRadius: BorderRadius.circular(3),
                        ),
                      ),
                    ),
                    // Progress fill
                    Positioned(
                      left: 0,
                      top: 12,
                      child: Container(
                        width: pos + 12,
                        height: 6,
                        decoration: BoxDecoration(
                          color: color.withValues(alpha: 0.4),
                          borderRadius: BorderRadius.circular(3),
                        ),
                      ),
                    ),
                    // Racer
                    Positioned(
                      left: pos,
                      top: 0,
                      child: Text(emoji, style: const TextStyle(fontSize: 22)),
                    ),
                    // Finish flag
                    Positioned(
                      right: 0,
                      top: 0,
                      child: Text('🏁', style: const TextStyle(fontSize: 18)),
                    ),
                  ],
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildWordArea(double fontSize) {
    if (_currentIndex >= _words.length) {
      return Center(
        child: Text(
          '🏁 All words completed!',
          style: GoogleFonts.fredoka(fontSize: 24, color: AppColors.correct),
        ),
      );
    }

    return Center(
      child: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Current word (highlighted)
              Container(
                padding: EdgeInsets.symmetric(
                  horizontal: fontSize * 1.2,
                  vertical: fontSize * 0.7,
                ),
                decoration: BoxDecoration(
                  color: const Color(0xFFE53935).withValues(alpha: 0.08),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: const Color(0xFFE53935).withValues(alpha: 0.3),
                    width: 2,
                  ),
                ),
                child: _buildPartialMatch(
                  _words[_currentIndex],
                  _input,
                  fontSize + 4,
                ),
              ),
              const SizedBox(height: 20),
              // Upcoming words
              Wrap(
                spacing: 12,
                runSpacing: 8,
                alignment: WrapAlignment.center,
                children: [
                  for (
                    var i = _currentIndex + 1;
                    i < min(_currentIndex + 6, _words.length);
                    i++
                  )
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: Colors.grey.shade300),
                      ),
                      child: Text(
                        _words[i],
                        style: GoogleFonts.fredoka(
                          fontSize: fontSize * 0.8,
                          color: AppColors.textSecondary,
                        ),
                      ),
                    ),
                ],
              ),
              if (_errors > 0) ...[
                const SizedBox(height: 16),
                Text(
                  'Errors: $_errors',
                  style: GoogleFonts.nunito(
                    fontSize: 14,
                    color: AppColors.incorrect,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildPartialMatch(String word, String typed, double fontSize) {
    final matchLen = typed.length.clamp(0, word.length);
    final matches = word.startsWith(typed);
    return Text.rich(
      TextSpan(
        children: [
          TextSpan(
            text: word.substring(0, matchLen),
            style: GoogleFonts.fredoka(
              fontSize: fontSize,
              fontWeight: FontWeight.w700,
              color: matches ? AppColors.correct : AppColors.incorrect,
            ),
          ),
          TextSpan(
            text: word.substring(matchLen),
            style: GoogleFonts.fredoka(
              fontSize: fontSize,
              fontWeight: FontWeight.w600,
              color: AppColors.textPrimary,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInputArea(double fontSize) {
    final hasInput = _input.isNotEmpty;
    final currentWord = _currentIndex < _words.length
        ? _words[_currentIndex]
        : '';
    final matches = hasInput && currentWord.startsWith(_input);
    final noMatch = hasInput && !matches;

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 32),
      padding: EdgeInsets.symmetric(
        horizontal: fontSize * 0.9,
        vertical: fontSize * 0.6,
      ),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: noMatch
              ? AppColors.incorrect.withValues(alpha: 0.6)
              : hasInput
              ? const Color(0xFFE53935).withValues(alpha: 0.6)
              : Colors.grey.shade300,
          width: 2,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          Icon(
            Icons.keyboard_rounded,
            color: hasInput ? const Color(0xFFE53935) : Colors.grey.shade400,
            size: fontSize,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              hasInput ? _input : 'Type the word...',
              style: GoogleFonts.fredoka(
                fontSize: fontSize,
                fontWeight: FontWeight.w500,
                color: noMatch
                    ? AppColors.incorrect
                    : hasInput
                    ? AppColors.textPrimary
                    : Colors.grey.shade400,
              ),
            ),
          ),
          if (hasInput)
            Text(
              '⌫',
              style: TextStyle(
                fontSize: fontSize * 0.8,
                color: Colors.grey.shade400,
              ),
            ),
        ],
      ),
    );
  }

  // ── Game Over ─────────────────────────────────────────────────────────────

  Widget _buildGameOver() {
    final elapsed = _totalSeconds - _remainingSeconds;
    final wpm = elapsed > 0 ? ((_currentIndex / (elapsed / 60)).round()) : 0;

    return SpeedChaseGameOver(
      won: _playerProgress > _ghostProgress,
      score: _score,
      isNewHighScore: _isNewHighScore,
      highScore: _highScore,
      wordsTyped: _currentIndex,
      totalWords: _words.length,
      wpm: wpm,
      errors: _errors,
      elapsed: elapsed,
      focusNode: _overFocusNode,
      onPlayAgain: _playAgain,
      onBack: () => context.pop(),
    );
  }
}
