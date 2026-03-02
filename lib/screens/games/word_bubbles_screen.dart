import 'dart:async';
import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';

import '../../core/theme/app_colors.dart';
import '../../data/word_lists.dart';
import '../../providers/progress_provider.dart';

// ─────────────────────────────────────────────────────────────────────────────
// Data
// ─────────────────────────────────────────────────────────────────────────────

enum _Phase { setup, playing, gameOver }

class _Bubble {
  final String word;
  double x; // fraction 0..1
  double y; // fraction 0..1
  final int colorIndex;
  double life; // seconds remaining before it fades
  final double maxLife;

  _Bubble({
    required this.word,
    required this.x,
    required this.y,
    required this.colorIndex,
    required this.life,
  }) : maxLife = life;

  double get opacity => (life / maxLife).clamp(0.3, 1.0);
}

// ─────────────────────────────────────────────────────────────────────────────
// Screen
// ─────────────────────────────────────────────────────────────────────────────

class WordBubblesScreen extends StatefulWidget {
  const WordBubblesScreen({super.key});

  @override
  State<WordBubblesScreen> createState() => _WordBubblesScreenState();
}

class _WordBubblesScreenState extends State<WordBubblesScreen> {
  static const _bubbleColors = [
    Color(0xFF26C6DA), // cyan
    Color(0xFFAB47BC), // purple
    Color(0xFF66BB6A), // green
    Color(0xFFFF7043), // deep orange
    Color(0xFF42A5F5), // blue
    Color(0xFFEC407A), // pink
    Color(0xFFFFA726), // orange
    Color(0xFF5C6BC0), // indigo
  ];

  // ── State ──
  _Phase _phase = _Phase.setup;
  ContentDifficulty _difficulty = ContentDifficulty.easy;

  final List<_Bubble> _bubbles = [];
  String _input = '';
  _Bubble? _target;
  int _score = 0;
  int _popped = 0;
  int _missed = 0;
  int _streak = 0;
  int _bestStreak = 0;
  bool _isNewHighScore = false;
  int _highScore = 0;

  // Timer
  Timer? _gameTimer;
  Timer? _spawnTimer;
  Timer? _tickTimer;
  int _remainingSeconds = 60;
  final _random = Random();

  // Focus
  final _setupFocusNode = FocusNode();
  final _gameFocusNode = FocusNode();
  final _overFocusNode = FocusNode();

  // ── Difficulty config ──
  int get _gameDuration => switch (_difficulty) {
    ContentDifficulty.easy => 60,
    ContentDifficulty.medium => 75,
    ContentDifficulty.hard => 90,
  };

  double get _spawnInterval => switch (_difficulty) {
    ContentDifficulty.easy => 2.5,
    ContentDifficulty.medium => 1.8,
    ContentDifficulty.hard => 1.2,
  };

  double get _bubbleLife => switch (_difficulty) {
    ContentDifficulty.easy => 6.0,
    ContentDifficulty.medium => 4.5,
    ContentDifficulty.hard => 3.5,
  };

  int get _maxBubbles => switch (_difficulty) {
    ContentDifficulty.easy => 4,
    ContentDifficulty.medium => 6,
    ContentDifficulty.hard => 8,
  };

  @override
  void dispose() {
    _gameTimer?.cancel();
    _spawnTimer?.cancel();
    _tickTimer?.cancel();
    _setupFocusNode.dispose();
    _gameFocusNode.dispose();
    _overFocusNode.dispose();
    super.dispose();
  }

  // ── Game logic ──

  void _startGame() {
    _bubbles.clear();
    _input = '';
    _target = null;
    _score = 0;
    _popped = 0;
    _missed = 0;
    _streak = 0;
    _bestStreak = 0;
    _isNewHighScore = false;
    _highScore = 0;
    _remainingSeconds = _gameDuration;
    _phase = _Phase.playing;
    setState(() {});

    // Countdown timer
    _gameTimer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (!mounted) return;
      setState(() {
        _remainingSeconds--;
        if (_remainingSeconds <= 0) {
          _endGame();
        }
      });
    });

    // Spawn timer
    _spawnTimer = Timer.periodic(
      Duration(milliseconds: (_spawnInterval * 1000).round()),
      (_) {
        if (!mounted || _phase != _Phase.playing) return;
        _spawnBubble();
      },
    );

    // Tick timer to fade bubbles
    _tickTimer = Timer.periodic(const Duration(milliseconds: 100), (_) {
      if (!mounted || _phase != _Phase.playing) return;
      _tick();
    });

    // Spawn first bubble immediately
    _spawnBubble();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      _gameFocusNode.requestFocus();
    });
  }

  void _spawnBubble() {
    if (_bubbles.length >= _maxBubbles) return;
    String word;
    int tries = 0;
    do {
      word = WordLists.randomWord(_difficulty);
      tries++;
    } while (_bubbles.any((b) => b.word == word) && tries < 10);

    _bubbles.add(
      _Bubble(
        word: word,
        x: _random.nextDouble() * 0.7 + 0.05,
        y: _random.nextDouble() * 0.7 + 0.05,
        colorIndex: _random.nextInt(_bubbleColors.length),
        life: _bubbleLife,
      ),
    );
    setState(() {});
  }

  void _tick() {
    // Fade bubbles
    final expired = <_Bubble>[];
    for (final b in _bubbles) {
      b.life -= 0.1;
      if (b.life <= 0) expired.add(b);
    }
    for (final b in expired) {
      _bubbles.remove(b);
      _missed++;
      _streak = 0;
      if (_target == b) {
        _target = null;
        _input = '';
      }
    }
    if (expired.isNotEmpty || _bubbles.isNotEmpty) {
      setState(() {});
    }
  }

  void _handleGameKey(KeyEvent event) {
    if (event is! KeyDownEvent && event is! KeyRepeatEvent) return;

    if (event.logicalKey == LogicalKeyboardKey.escape) {
      _showQuitDialog();
      return;
    }

    if (event.logicalKey == LogicalKeyboardKey.backspace) {
      if (_input.isNotEmpty) {
        _input = _input.substring(0, _input.length - 1);
        _updateTarget();
        setState(() {});
      }
      return;
    }

    final char = event.character;
    if (char == null || char.isEmpty) return;
    if (!RegExp(r'[a-zA-Z]').hasMatch(char)) return;

    _input += char.toLowerCase();
    _updateTarget();

    // Exact match → pop
    if (_target != null && _input == _target!.word) {
      _popBubble(_target!);
    }

    setState(() {});
  }

  void _updateTarget() {
    if (_input.isEmpty) {
      _target = null;
      return;
    }
    // Keep existing target if still valid
    if (_target != null &&
        _bubbles.contains(_target) &&
        _target!.word.startsWith(_input)) {
      return;
    }
    // Pick bubble with most remaining life that matches
    _target = null;
    for (final b in _bubbles) {
      if (b.word.startsWith(_input)) {
        if (_target == null || b.life < _target!.life) {
          _target = b;
        }
      }
    }
  }

  void _popBubble(_Bubble bubble) {
    _bubbles.remove(bubble);
    _score += bubble.word.length * 10 + (bubble.life * 5).round();
    _popped++;
    _streak++;
    if (_streak > _bestStreak) _bestStreak = _streak;
    _input = '';
    _target = null;
  }

  void _endGame() {
    _gameTimer?.cancel();
    _spawnTimer?.cancel();
    _tickTimer?.cancel();
    final progress = Provider.of<ProgressProvider>(context, listen: false);
    _highScore = progress.getHighScore('word_bubbles');
    progress.recordScore('word_bubbles', _score).then((isNew) {
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
    _spawnTimer?.cancel();
    _tickTimer?.cancel();
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
        // Resume timers
        _gameTimer = Timer.periodic(const Duration(seconds: 1), (_) {
          if (!mounted) return;
          setState(() {
            _remainingSeconds--;
            if (_remainingSeconds <= 0) _endGame();
          });
        });
        _spawnTimer = Timer.periodic(
          Duration(milliseconds: (_spawnInterval * 1000).round()),
          (_) {
            if (!mounted || _phase != _Phase.playing) return;
            _spawnBubble();
          },
        );
        _tickTimer = Timer.periodic(const Duration(milliseconds: 100), (_) {
          if (!mounted || _phase != _Phase.playing) return;
          _tick();
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
                          '🫧',
                          style: TextStyle(fontSize: isTall ? 56 : 36),
                        ),
                        SizedBox(height: isTall ? 8 : 4),
                        Text(
                          'Word Bubbles',
                          style: GoogleFonts.fredoka(
                            fontSize: isWide ? 34 : 26,
                            fontWeight: FontWeight.w700,
                            color: const Color(0xFF26C6DA),
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Pop the bubbles by typing the words!',
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
                                  accentColor: const Color(0xFF26C6DA),
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
                              backgroundColor: const Color(0xFF26C6DA),
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
                                    'Start Game',
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
      backgroundColor: const Color(0xFFF0F8FF),
      body: KeyboardListener(
        focusNode: _gameFocusNode,
        autofocus: true,
        onKeyEvent: _handleGameKey,
        child: GestureDetector(
          onTap: () => _gameFocusNode.requestFocus(),
          child: SafeArea(
            child: Column(
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
                      Icon(Icons.timer_outlined, color: timerColor, size: 20),
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
                      if (_streak > 1) ...[
                        Text('🔥', style: const TextStyle(fontSize: 18)),
                        const SizedBox(width: 2),
                        Text(
                          '$_streak',
                          style: GoogleFonts.fredoka(
                            fontSize: 18,
                            fontWeight: FontWeight.w600,
                            color: AppColors.secondary,
                          ),
                        ),
                        const SizedBox(width: 12),
                      ],
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 3,
                        ),
                        decoration: BoxDecoration(
                          color: const Color(
                            0xFF26C6DA,
                          ).withValues(alpha: 0.12),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          '${_difficulty.emoji} ${_difficulty.label}',
                          style: GoogleFonts.nunito(
                            fontSize: 12,
                            fontWeight: FontWeight.w700,
                            color: const Color(0xFF26C6DA),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

                // Bubble area
                Expanded(child: _buildBubbleArea()),

                // Input area
                _buildInputArea(),
                const SizedBox(height: 12),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildBubbleArea() {
    return LayoutBuilder(
      builder: (context, constraints) {
        final areaW = constraints.maxWidth;
        final areaH = constraints.maxHeight;
        final fontSize = areaW > 800
            ? 24.0
            : areaW > 500
            ? 20.0
            : 16.0;

        return Stack(
          clipBehavior: Clip.hardEdge,
          children: [
            for (final b in _bubbles) _buildBubble(b, areaW, areaH, fontSize),
            if (_bubbles.isEmpty)
              Center(
                child: Text(
                  'Pop the bubbles! 🫧',
                  style: GoogleFonts.fredoka(
                    fontSize: 24,
                    color: AppColors.textSecondary.withValues(alpha: 0.4),
                  ),
                ),
              ),
          ],
        );
      },
    );
  }

  Widget _buildBubble(
    _Bubble bubble,
    double areaW,
    double areaH,
    double fontSize,
  ) {
    final isTarget = bubble == _target;
    final color = _bubbleColors[bubble.colorIndex];
    final size = bubble.word.length * (fontSize * 0.7) + 52;

    final left = (bubble.x * (areaW - size)).clamp(0.0, areaW - size);
    final top = (bubble.y * (areaH - size)).clamp(0.0, areaH - size);

    return Positioned(
      left: left,
      top: top,
      child: AnimatedOpacity(
        duration: const Duration(milliseconds: 200),
        opacity: bubble.opacity,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 120),
          padding: EdgeInsets.symmetric(
            horizontal: fontSize * 0.8,
            vertical: fontSize * 0.5,
          ),
          decoration: BoxDecoration(
            color: isTarget ? color : color.withValues(alpha: 0.8),
            borderRadius: BorderRadius.circular(size / 2),
            border: isTarget
                ? Border.all(color: AppColors.starFilled, width: 3)
                : Border.all(
                    color: Colors.white.withValues(alpha: 0.5),
                    width: 2,
                  ),
            boxShadow: isTarget
                ? [
                    BoxShadow(
                      color: AppColors.starFilled.withValues(alpha: 0.4),
                      blurRadius: 16,
                      spreadRadius: 2,
                    ),
                  ]
                : [
                    BoxShadow(
                      color: color.withValues(alpha: 0.3),
                      blurRadius: 8,
                      offset: const Offset(0, 3),
                    ),
                  ],
          ),
          child: isTarget && _input.isNotEmpty
              ? _buildPartialMatch(bubble.word, _input, fontSize)
              : Text(
                  bubble.word,
                  style: GoogleFonts.fredoka(
                    fontSize: fontSize,
                    fontWeight: FontWeight.w600,
                    color: Colors.white,
                  ),
                ),
        ),
      ),
    );
  }

  Widget _buildPartialMatch(String word, String typed, double fontSize) {
    final matchLen = typed.length.clamp(0, word.length);
    return Text.rich(
      TextSpan(
        children: [
          TextSpan(
            text: word.substring(0, matchLen),
            style: GoogleFonts.fredoka(
              fontSize: fontSize,
              fontWeight: FontWeight.w700,
              color: const Color(0xFFB9F6CA),
            ),
          ),
          TextSpan(
            text: word.substring(matchLen),
            style: GoogleFonts.fredoka(
              fontSize: fontSize,
              fontWeight: FontWeight.w600,
              color: Colors.white,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInputArea() {
    final hasMatch = _target != null;
    final hasInput = _input.isNotEmpty;
    final noMatch = hasInput && !hasMatch;
    final screenW = MediaQuery.of(context).size.width;
    final fontSize = screenW > 800
        ? 28.0
        : screenW > 500
        ? 24.0
        : 20.0;

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
              : hasMatch
              ? const Color(0xFF26C6DA).withValues(alpha: 0.6)
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
            color: hasInput ? const Color(0xFF26C6DA) : Colors.grey.shade400,
            size: fontSize,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              hasInput ? _input : 'Type a word...',
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
                          '🫧',
                          style: TextStyle(fontSize: isTall ? 56 : 36),
                        ),
                        SizedBox(height: isTall ? 8 : 4),
                        Text(
                          'Time\'s Up!',
                          style: GoogleFonts.fredoka(
                            fontSize: isWide ? 36 : 28,
                            fontWeight: FontWeight.w700,
                            color: const Color(0xFF26C6DA),
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
                                const Color(0xFF26C6DA).withValues(alpha: 0.15),
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
                              emoji: '🫧',
                              label: 'Popped',
                              value: '$_popped',
                            ),
                            const SizedBox(width: 12),
                            _OverStat(
                              emoji: '💨',
                              label: 'Missed',
                              value: '$_missed',
                            ),
                          ],
                        ),
                        SizedBox(height: isTall ? 12 : 8),
                        Row(
                          children: [
                            _OverStat(
                              emoji: '🔥',
                              label: 'Best Streak',
                              value: '$_bestStreak',
                            ),
                            const SizedBox(width: 12),
                            _OverStat(
                              emoji: '⏱️',
                              label: 'Duration',
                              value: '${_gameDuration}s',
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
                              backgroundColor: const Color(0xFF26C6DA),
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
                                  'Play Again',
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
          'Quit Game?',
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
