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
  int get _wordCount => switch (_difficulty) {
    ContentDifficulty.easy => 15,
    ContentDifficulty.medium => 20,
    ContentDifficulty.hard => 25,
  };

  int get _gameDuration => switch (_difficulty) {
    ContentDifficulty.easy => 60,
    ContentDifficulty.medium => 90,
    ContentDifficulty.hard => 120,
  };

  double get _ghostSpeed => switch (_difficulty) {
    ContentDifficulty.easy => 0.010,
    ContentDifficulty.medium => 0.013,
    ContentDifficulty.hard => 0.015,
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
      builder: (ctx) => _QuitDialog(
        onResume: () => Navigator.of(ctx).pop(),
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

  void _handleSetupKey(KeyEvent event) {
    if (event is! KeyDownEvent) return;
    final key = event.logicalKey;
    if (key == LogicalKeyboardKey.escape) {
      context.pop();
    } else if (key == LogicalKeyboardKey.enter ||
        key == LogicalKeyboardKey.space) {
      _startGame();
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
          child: LayoutBuilder(
            builder: (context, constraints) {
              final screenW = constraints.maxWidth;
              final screenH = constraints.maxHeight;
              final isWide = screenW > 600;
              final isTall = screenH > 650;
              final hPad = isWide ? 40.0 : 20.0;
              final vPad = isTall ? 32.0 : 16.0;
              final maxW = isWide ? 520.0 : screenW;

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
                                _keyBadge('Esc', AppColors.textSecondary),
                              ],
                            ),
                            style: TextButton.styleFrom(
                              foregroundColor: AppColors.textSecondary,
                            ),
                          ),
                        ),
                        SizedBox(height: isTall ? 16 : 8),
                        Text(
                          '🏎️',
                          style: TextStyle(fontSize: isTall ? 56 : 36),
                        ),
                        SizedBox(height: isTall ? 8 : 4),
                        Text(
                          'Speed Chase',
                          style: GoogleFonts.fredoka(
                            fontSize: isWide ? 34 : 26,
                            fontWeight: FontWeight.w700,
                            color: const Color(0xFFE53935),
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Type words faster than the ghost racer!',
                          style: GoogleFonts.nunito(
                            fontSize: isWide ? 16 : 14,
                            color: AppColors.textSecondary,
                          ),
                          textAlign: TextAlign.center,
                        ),
                        SizedBox(height: isTall ? 32 : 16),
                        Text(
                          'Choose Difficulty',
                          style: GoogleFonts.fredoka(
                            fontSize: isWide ? 20 : 18,
                            fontWeight: FontWeight.w600,
                            color: AppColors.textPrimary,
                          ),
                        ),
                        SizedBox(height: isTall ? 14 : 10),
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
                                  compact: !isTall,
                                  accentColor: const Color(0xFFE53935),
                                  onTap: () => setState(() => _difficulty = d),
                                ),
                              ),
                            );
                          }).toList(),
                        ),
                        SizedBox(height: isTall ? 32 : 16),
                        SizedBox(
                          width: isWide ? 280 : 220,
                          height: 56,
                          child: ElevatedButton(
                            onPressed: _startGame,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFFE53935),
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
                                    'Start Race',
                                    style: GoogleFonts.fredoka(
                                      fontSize: isWide ? 22 : 18,
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
              );
            },
          ),
        ),
      ),
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

  void _handleOverKey(KeyEvent event) {
    if (event is! KeyDownEvent) return;
    final key = event.logicalKey;
    if (key == LogicalKeyboardKey.enter || key == LogicalKeyboardKey.space) {
      _playAgain();
    } else if (key == LogicalKeyboardKey.escape) {
      context.pop();
    }
  }

  Widget _buildGameOver() {
    final won = _playerProgress > _ghostProgress;
    final elapsed = _totalSeconds - _remainingSeconds;
    final wpm = elapsed > 0
        ? ((_currentIndex / (elapsed / 60)).round())
        : _currentIndex;

    return Scaffold(
      backgroundColor: AppColors.background,
      body: KeyboardListener(
        focusNode: _overFocusNode,
        autofocus: true,
        onKeyEvent: _handleOverKey,
        child: SafeArea(
          child: LayoutBuilder(
            builder: (context, constraints) {
              final screenW = constraints.maxWidth;
              final screenH = constraints.maxHeight;
              final isWide = screenW > 600;
              final isTall = screenH > 650;
              final hPad = isWide ? 40.0 : 20.0;
              final vPad = isTall ? 32.0 : 16.0;
              final maxW = isWide ? 460.0 : screenW;
              final scoreFontSize = isTall ? 52.0 : 36.0;
              final sectionGap = isTall ? 24.0 : 12.0;

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
                        Text(
                          won ? '🏆' : '🏁',
                          style: TextStyle(fontSize: isTall ? 56 : 36),
                        ),
                        SizedBox(height: isTall ? 8 : 4),
                        Text(
                          won ? 'You Won!' : 'Race Over!',
                          style: GoogleFonts.fredoka(
                            fontSize: isWide ? 36 : 28,
                            fontWeight: FontWeight.w700,
                            color: won
                                ? AppColors.correct
                                : const Color(0xFFE53935),
                          ),
                        ),
                        SizedBox(height: sectionGap),
                        // Score
                        Container(
                          width: double.infinity,
                          padding: EdgeInsets.all(isTall ? 20 : 14),
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              colors: [
                                AppColors.starFilled.withValues(alpha: 0.15),
                                const Color(0xFFE53935).withValues(alpha: 0.15),
                              ],
                            ),
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(
                              color: AppColors.starFilled.withValues(
                                alpha: 0.4,
                              ),
                            ),
                          ),
                          child: Column(
                            children: [
                              if (_isNewHighScore)
                                Padding(
                                  padding: const EdgeInsets.only(bottom: 4),
                                  child: Text(
                                    '⭐ New High Score! ⭐',
                                    style: GoogleFonts.fredoka(
                                      fontSize: 16,
                                      fontWeight: FontWeight.w600,
                                      color: AppColors.accent,
                                    ),
                                  ),
                                ),
                              Text(
                                '$_score',
                                style: GoogleFonts.fredoka(
                                  fontSize: scoreFontSize,
                                  fontWeight: FontWeight.w700,
                                  color: AppColors.starFilled,
                                ),
                              ),
                              Text(
                                'points',
                                style: GoogleFonts.nunito(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w600,
                                  color: AppColors.textSecondary,
                                ),
                              ),
                              if (!_isNewHighScore && _highScore > 0)
                                Padding(
                                  padding: const EdgeInsets.only(top: 4),
                                  child: Text(
                                    'Best: $_highScore',
                                    style: GoogleFonts.nunito(
                                      fontSize: 13,
                                      fontWeight: FontWeight.w600,
                                      color: AppColors.textSecondary,
                                    ),
                                  ),
                                ),
                            ],
                          ),
                        ),
                        SizedBox(height: sectionGap),
                        Row(
                          children: [
                            _OverStat(
                              emoji: '📝',
                              label: 'Words Typed',
                              value: '$_currentIndex/${_words.length}',
                            ),
                            const SizedBox(width: 12),
                            _OverStat(emoji: '⚡', label: 'WPM', value: '$wpm'),
                          ],
                        ),
                        SizedBox(height: isTall ? 12 : 8),
                        Row(
                          children: [
                            _OverStat(
                              emoji: '❌',
                              label: 'Errors',
                              value: '$_errors',
                            ),
                            const SizedBox(width: 12),
                            _OverStat(
                              emoji: '⏱️',
                              label: 'Time',
                              value: '${elapsed}s',
                            ),
                          ],
                        ),
                        SizedBox(height: sectionGap + 8),
                        SizedBox(
                          width: double.infinity,
                          height: 56,
                          child: ElevatedButton(
                            onPressed: _playAgain,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFFE53935),
                              foregroundColor: Colors.white,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(16),
                              ),
                            ),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                const Icon(Icons.replay_rounded, size: 24),
                                const SizedBox(width: 8),
                                Text(
                                  'Race Again',
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
                                'Back to Games',
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
              );
            },
          ),
        ),
      ),
    );
  }

  // ── Helpers ───────────────────────────────────────────────────────────────

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
  final bool compact;
  final Color accentColor;
  final VoidCallback onTap;

  const _DifficultyCard({
    required this.difficulty,
    required this.index,
    required this.selected,
    this.compact = false,
    required this.accentColor,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final vPad = compact ? 8.0 : 14.0;
    final emojiSize = compact ? 22.0 : 28.0;
    final labelSize = compact ? 14.0 : 16.0;

    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 160),
        padding: EdgeInsets.symmetric(vertical: vPad, horizontal: 8),
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
            Text(difficulty.emoji, style: TextStyle(fontSize: emojiSize)),
            SizedBox(height: compact ? 2 : 4),
            Text(
              difficulty.label,
              style: GoogleFonts.fredoka(
                fontSize: labelSize,
                fontWeight: FontWeight.w600,
                color: selected ? accentColor : AppColors.textPrimary,
              ),
            ),
            if (!compact) ...[
              const SizedBox(height: 2),
              Text(
                difficulty.description,
                style: GoogleFonts.nunito(
                  fontSize: 11,
                  color: AppColors.textSecondary,
                ),
                textAlign: TextAlign.center,
              ),
            ],
            SizedBox(height: compact ? 3 : 6),
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

class _OverStat extends StatelessWidget {
  final String emoji;
  final String label;
  final String value;

  const _OverStat({
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

class _QuitDialog extends StatefulWidget {
  final VoidCallback onResume;
  final VoidCallback onQuit;

  const _QuitDialog({required this.onResume, required this.onQuit});

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
    if (key == LogicalKeyboardKey.escape || key == LogicalKeyboardKey.keyR) {
      widget.onResume();
    } else if (key == LogicalKeyboardKey.enter ||
        key == LogicalKeyboardKey.keyQ) {
      widget.onQuit();
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
          'Quit Race?',
          style: GoogleFonts.fredoka(
            fontSize: 24,
            color: AppColors.textPrimary,
          ),
        ),
        content: Text(
          'Your current score will be lost.',
          style: GoogleFonts.nunito(fontSize: 16),
        ),
        actions: [
          TextButton(
            onPressed: widget.onResume,
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  'Resume',
                  style: GoogleFonts.fredoka(color: AppColors.primary),
                ),
                _badge('Esc', AppColors.primary),
              ],
            ),
          ),
          TextButton(
            onPressed: widget.onQuit,
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  'Quit',
                  style: GoogleFonts.fredoka(color: AppColors.incorrect),
                ),
                _badge('Q', AppColors.incorrect),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
