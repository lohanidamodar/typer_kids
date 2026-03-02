import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../core/theme/app_colors.dart';
import '../../data/word_lists.dart';

// ─────────────────────────────────────────────────────────────────────────────
// Data types
// ─────────────────────────────────────────────────────────────────────────────

enum _Phase { setup, playing, gameOver }

class _FallingWord {
  final String word;
  double x; // 0.0 – 1.0 (fraction of available width)
  double y; // 0.0 – 1.0 (fraction of available height, 0 = top)
  final double speed; // fraction of height per second
  final int colorIndex;

  _FallingWord({
    required this.word,
    required this.x,
    required this.y,
    required this.speed,
    required this.colorIndex,
  });
}

// ─────────────────────────────────────────────────────────────────────────────
// Screen
// ─────────────────────────────────────────────────────────────────────────────

/// Falling words typing game — type words before they hit the ground!
class FallingWordsScreen extends StatefulWidget {
  const FallingWordsScreen({super.key});

  @override
  State<FallingWordsScreen> createState() => _FallingWordsScreenState();
}

class _FallingWordsScreenState extends State<FallingWordsScreen>
    with SingleTickerProviderStateMixin {
  // ── Visual ──
  static const _bubbleColors = [
    Color(0xFF4CAF50), // green
    Color(0xFF2196F3), // blue
    Color(0xFFFF9800), // orange
    Color(0xFF9C27B0), // purple
    Color(0xFFE91E63), // pink
    Color(0xFF00BCD4), // teal
    Color(0xFFFF5722), // deep orange
    Color(0xFF3F51B5), // indigo
  ];

  // ── State ──
  _Phase _phase = _Phase.setup;
  ContentDifficulty _difficulty = ContentDifficulty.easy;

  final List<_FallingWord> _words = [];
  String _input = '';
  _FallingWord? _target;
  int _score = 0;
  int _lives = 5;
  int _wordsDestroyed = 0;
  int _wordsMissed = 0;
  int _streak = 0;
  int _bestStreak = 0;
  DateTime? _gameStart;
  Duration _gameDuration = Duration.zero;

  // ── Animation ──
  late final Ticker _ticker;
  Duration _lastTick = Duration.zero;
  double _spawnTimer = 0;
  final _random = Random();

  // ── Focus ──
  final _setupFocusNode = FocusNode();
  final _gameFocusNode = FocusNode();
  final _overFocusNode = FocusNode();

  // ── Difficulty config ──
  double get _spawnInterval => switch (_difficulty) {
    ContentDifficulty.easy => 2.8,
    ContentDifficulty.medium => 2.0,
    ContentDifficulty.hard => 1.3,
  };

  double get _minSpeed => switch (_difficulty) {
    ContentDifficulty.easy => 0.06,
    ContentDifficulty.medium => 0.10,
    ContentDifficulty.hard => 0.14,
  };

  double get _maxSpeed => switch (_difficulty) {
    ContentDifficulty.easy => 0.10,
    ContentDifficulty.medium => 0.16,
    ContentDifficulty.hard => 0.22,
  };

  int get _maxWords => switch (_difficulty) {
    ContentDifficulty.easy => 5,
    ContentDifficulty.medium => 7,
    ContentDifficulty.hard => 10,
  };

  int get _startLives => switch (_difficulty) {
    ContentDifficulty.easy => 5,
    ContentDifficulty.medium => 4,
    ContentDifficulty.hard => 3,
  };

  // ── Lifecycle ──
  @override
  void initState() {
    super.initState();
    _ticker = createTicker(_onTick);
  }

  @override
  void dispose() {
    _ticker.dispose();
    _setupFocusNode.dispose();
    _gameFocusNode.dispose();
    _overFocusNode.dispose();
    super.dispose();
  }

  // ── Game logic ──
  void _startGame() {
    _words.clear();
    _input = '';
    _target = null;
    _score = 0;
    _lives = _startLives;
    _wordsDestroyed = 0;
    _wordsMissed = 0;
    _streak = 0;
    _bestStreak = 0;
    _spawnTimer = _spawnInterval - 0.5; // spawn first word quickly
    _lastTick = Duration.zero;
    _gameStart = DateTime.now();
    _phase = _Phase.playing;
    _ticker.start();
    setState(() {});
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _gameFocusNode.requestFocus();
    });
  }

  void _onTick(Duration elapsed) {
    if (_phase != _Phase.playing) return;

    final dt = ((elapsed - _lastTick).inMicroseconds / 1e6).clamp(0.0, 0.1);
    _lastTick = elapsed;

    // Spawn
    _spawnTimer += dt;
    if (_spawnTimer >= _spawnInterval && _words.length < _maxWords) {
      _spawnWord();
      _spawnTimer = 0;
    }

    // Move
    for (final w in _words) {
      w.y += w.speed * dt;
    }

    // Missed words
    final missed = _words.where((w) => w.y >= 1.0).toList();
    for (final w in missed) {
      _words.remove(w);
      _wordsMissed++;
      _streak = 0;
      _lives--;
      if (_target == w) {
        _target = null;
        _input = '';
      }
      if (_lives <= 0) {
        _endGame();
        return;
      }
    }

    setState(() {});
  }

  void _spawnWord() {
    String word;
    int tries = 0;
    do {
      word = WordLists.randomWord(_difficulty);
      tries++;
    } while (_words.any((w) => w.word == word) && tries < 10);

    _words.add(
      _FallingWord(
        word: word,
        x: _random.nextDouble() * 0.70 + 0.05,
        y: -0.02,
        speed: _minSpeed + _random.nextDouble() * (_maxSpeed - _minSpeed),
        colorIndex: _random.nextInt(_bubbleColors.length),
      ),
    );
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

    // Exact match → destroy
    if (_target != null && _input == _target!.word) {
      _destroyWord(_target!);
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
        _words.contains(_target) &&
        _target!.word.startsWith(_input)) {
      return;
    }
    // Pick lowest matching word
    _target = null;
    for (final w in _words) {
      if (w.word.startsWith(_input)) {
        if (_target == null || w.y > _target!.y) {
          _target = w;
        }
      }
    }
  }

  void _destroyWord(_FallingWord word) {
    _words.remove(word);
    _score += word.word.length * 10;
    _wordsDestroyed++;
    _streak++;
    if (_streak > _bestStreak) _bestStreak = _streak;
    _input = '';
    _target = null;
  }

  void _endGame() {
    _ticker.stop();
    _gameDuration = DateTime.now().difference(_gameStart ?? DateTime.now());
    _phase = _Phase.gameOver;
    setState(() {});
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _overFocusNode.requestFocus();
    });
  }

  void _showQuitDialog() {
    _ticker.stop();
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
        _lastTick = Duration.zero;
        _ticker.start();
        _gameFocusNode.requestFocus();
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
                    const Text('⬇️', style: TextStyle(fontSize: 56)),
                    const SizedBox(height: 8),
                    Text(
                      'Falling Words',
                      style: GoogleFonts.fredoka(
                        fontSize: 34,
                        fontWeight: FontWeight.w700,
                        color: AppColors.primary,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Type the words before they reach the bottom!',
                      style: GoogleFonts.nunito(
                        fontSize: 16,
                        color: AppColors.textSecondary,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 32),
                    // Difficulty selector
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
                              onTap: () => setState(() => _difficulty = d),
                            ),
                          ),
                        );
                      }).toList(),
                    ),
                    const SizedBox(height: 32),
                    // Start button
                    SizedBox(
                      width: 240,
                      height: 56,
                      child: ElevatedButton(
                        onPressed: _startGame,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.primary,
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
                              'Start Game',
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

  // ── Playing ───────────────────────────────────────────────────────────────

  Widget _buildGame() {
    return Scaffold(
      backgroundColor: const Color(0xFFF0F4F8),
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
                _buildTopBar(),
                // Game area
                Expanded(child: _buildGameArea()),
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

  Widget _buildTopBar() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
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
          // Score
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
          // Lives
          Row(
            mainAxisSize: MainAxisSize.min,
            children: List.generate(_startLives, (i) {
              final alive = i < _lives;
              return Padding(
                padding: const EdgeInsets.symmetric(horizontal: 1),
                child: Icon(
                  alive
                      ? Icons.favorite_rounded
                      : Icons.favorite_border_rounded,
                  color: alive ? AppColors.incorrect : Colors.grey.shade300,
                  size: 22,
                ),
              );
            }),
          ),
          const Spacer(),
          // Streak
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
          // Difficulty label
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
            decoration: BoxDecoration(
              color: AppColors.primary.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(
              '${_difficulty.emoji} ${_difficulty.label}',
              style: GoogleFonts.nunito(
                fontSize: 12,
                fontWeight: FontWeight.w700,
                color: AppColors.primary,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildGameArea() {
    return LayoutBuilder(
      builder: (context, constraints) {
        final areaW = constraints.maxWidth;
        final areaH = constraints.maxHeight;

        return Stack(
          clipBehavior: Clip.hardEdge,
          children: [
            // Ground line
            Positioned(
              left: 0,
              right: 0,
              bottom: 0,
              child: Container(
                height: 3,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      AppColors.incorrect.withValues(alpha: 0.0),
                      AppColors.incorrect.withValues(alpha: 0.5),
                      AppColors.incorrect.withValues(alpha: 0.0),
                    ],
                  ),
                ),
              ),
            ),
            // Falling words
            for (final w in _words) _buildWordBubble(w, areaW, areaH),
            // Empty state hint
            if (_words.isEmpty)
              Center(
                child: Text(
                  'Get ready...',
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

  Widget _buildWordBubble(_FallingWord word, double areaW, double areaH) {
    final isTarget = word == _target;
    final color = _bubbleColors[word.colorIndex];

    // Estimate width to clamp x
    final estWidth = word.word.length * 14.0 + 32;
    final maxLeft = (areaW - estWidth).clamp(0.0, double.infinity);
    final left = (word.x * areaW).clamp(0.0, maxLeft);
    final top = word.y * areaH;

    return Positioned(
      left: left,
      top: top,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 120),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color: isTarget ? color : color.withValues(alpha: 0.85),
          borderRadius: BorderRadius.circular(14),
          border: isTarget
              ? Border.all(color: AppColors.starFilled, width: 2.5)
              : null,
          boxShadow: isTarget
              ? [
                  BoxShadow(
                    color: AppColors.starFilled.withValues(alpha: 0.4),
                    blurRadius: 12,
                    spreadRadius: 1,
                  ),
                ]
              : [
                  BoxShadow(
                    color: color.withValues(alpha: 0.3),
                    blurRadius: 6,
                    offset: const Offset(0, 2),
                  ),
                ],
        ),
        child: isTarget && _input.isNotEmpty
            ? _buildPartialMatch(word.word, _input)
            : Text(
                word.word,
                style: GoogleFonts.fredoka(
                  fontSize: 20,
                  fontWeight: FontWeight.w600,
                  color: Colors.white,
                ),
              ),
      ),
    );
  }

  Widget _buildPartialMatch(String word, String typed) {
    final matchLen = typed.length.clamp(0, word.length);
    return Text.rich(
      TextSpan(
        children: [
          TextSpan(
            text: word.substring(0, matchLen),
            style: GoogleFonts.fredoka(
              fontSize: 20,
              fontWeight: FontWeight.w700,
              color: const Color(0xFFB9F6CA), // light green
            ),
          ),
          TextSpan(
            text: word.substring(matchLen),
            style: GoogleFonts.fredoka(
              fontSize: 20,
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

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 32),
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: noMatch
              ? AppColors.incorrect.withValues(alpha: 0.6)
              : hasMatch
              ? AppColors.primary.withValues(alpha: 0.6)
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
            color: hasInput ? AppColors.primary : Colors.grey.shade400,
            size: 22,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              hasInput ? _input : 'Start typing...',
              style: GoogleFonts.fredoka(
                fontSize: 22,
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
              style: TextStyle(fontSize: 18, color: Colors.grey.shade400),
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

  void _playAgain() {
    _phase = _Phase.setup;
    setState(() {});
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _setupFocusNode.requestFocus();
    });
  }

  Widget _buildGameOver() {
    final minutes = _gameDuration.inMinutes
        .remainder(60)
        .toString()
        .padLeft(2, '0');
    final seconds = _gameDuration.inSeconds
        .remainder(60)
        .toString()
        .padLeft(2, '0');

    return Scaffold(
      backgroundColor: AppColors.background,
      body: KeyboardListener(
        focusNode: _overFocusNode,
        autofocus: true,
        onKeyEvent: _handleOverKey,
        child: SafeArea(
          child: Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(32),
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 420),
                child: Column(
                  children: [
                    const Text('🎮', style: TextStyle(fontSize: 56)),
                    const SizedBox(height: 8),
                    Text(
                      'Game Over!',
                      style: GoogleFonts.fredoka(
                        fontSize: 36,
                        fontWeight: FontWeight.w700,
                        color: AppColors.accent,
                      ),
                    ),
                    const SizedBox(height: 24),
                    // Score
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [
                            AppColors.starFilled.withValues(alpha: 0.15),
                            AppColors.secondary.withValues(alpha: 0.15),
                          ],
                        ),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                          color: AppColors.starFilled.withValues(alpha: 0.4),
                        ),
                      ),
                      child: Column(
                        children: [
                          Text(
                            '$_score',
                            style: GoogleFonts.fredoka(
                              fontSize: 52,
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
                        ],
                      ),
                    ),
                    const SizedBox(height: 20),
                    // Stats grid
                    Row(
                      children: [
                        _OverStat(
                          emoji: '✅',
                          label: 'Words',
                          value: '$_wordsDestroyed',
                        ),
                        const SizedBox(width: 12),
                        _OverStat(
                          emoji: '❌',
                          label: 'Missed',
                          value: '$_wordsMissed',
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
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
                          label: 'Time',
                          value: '$minutes:$seconds',
                        ),
                      ],
                    ),
                    const SizedBox(height: 32),
                    // Play again
                    SizedBox(
                      width: double.infinity,
                      height: 56,
                      child: ElevatedButton(
                        onPressed: _playAgain,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.primary,
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
              ? AppColors.primary.withValues(alpha: 0.12)
              : Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: selected ? AppColors.primary : Colors.grey.shade300,
            width: selected ? 2.5 : 1,
          ),
          boxShadow: selected
              ? [
                  BoxShadow(
                    color: AppColors.primary.withValues(alpha: 0.15),
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
                color: selected ? AppColors.primary : AppColors.textPrimary,
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
                color: AppColors.primary.withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(4),
                border: Border.all(
                  color: AppColors.primary.withValues(alpha: 0.2),
                ),
              ),
              child: Text(
                '$index',
                style: GoogleFonts.robotoMono(
                  fontSize: 10,
                  fontWeight: FontWeight.w600,
                  color: AppColors.primary,
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

/// Quit-game confirmation dialog with keyboard shortcuts.
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

  Widget _badge(String label, Color color) {
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
