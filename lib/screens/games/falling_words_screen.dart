import 'dart:async';
import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';

import '../../core/theme/app_colors.dart';
import '../../core/sound_manager.dart';
import '../../data/word_lists.dart';
import '../../providers/progress_provider.dart';

// ─────────────────────────────────────────────────────────────────────────────
// Data types
// ─────────────────────────────────────────────────────────────────────────────

enum _Phase { setup, playing, gameOver }

enum _FlashType { correct, wrong }

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

/// Brief ghost left behind when a word is destroyed or missed.
class _Ghost {
  final String word;
  final double x;
  final double y;
  final bool success; // true = correct, false = wrong/miss
  final int colorIndex;

  _Ghost({
    required this.word,
    required this.x,
    required this.y,
    required this.success,
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
  bool _isNewHighScore = false;
  int _highScore = 0;

  // Feedback flash
  _FlashType? _flash;
  Timer? _flashTimer;

  // Ghost feedback bubbles (shown at word position on pop/miss)
  final List<_Ghost> _ghosts = [];

  // ── Animation ──
  late final Ticker _ticker;
  Duration _lastTick = Duration.zero;
  double _spawnTimer = 0;
  final _random = Random();

  // ── Focus ──
  final _setupFocusNode = FocusNode();
  final _gameFocusNode = FocusNode();
  final _overFocusNode = FocusNode();

  final _sfx = SoundManager();

  // ── Difficulty config ──
  //
  // Reference height used to calibrate fall speed.  On screens shorter than
  // this the words slow down proportionally so kids have enough reaction time.
  static const _refHeight = 600.0;
  double _gameAreaHeight = _refHeight;

  /// Speed multiplier: 1.0 on a 600 px tall area, smaller on shorter screens.
  double get _heightScale => (_gameAreaHeight / _refHeight).clamp(0.55, 1.0);

  double get _spawnInterval => switch (_difficulty) {
    ContentDifficulty.easy => 3.2,
    ContentDifficulty.medium => 2.4,
    ContentDifficulty.hard => 1.6,
  };

  double get _minSpeed => _heightScale * switch (_difficulty) {
    ContentDifficulty.easy => 0.045,
    ContentDifficulty.medium => 0.07,
    ContentDifficulty.hard => 0.11,
  };

  double get _maxSpeed => _heightScale * switch (_difficulty) {
    ContentDifficulty.easy => 0.075,
    ContentDifficulty.medium => 0.12,
    ContentDifficulty.hard => 0.18,
  };

  int get _maxWords => switch (_difficulty) {
    ContentDifficulty.easy => 4,
    ContentDifficulty.medium => 6,
    ContentDifficulty.hard => 9,
  };

  int get _startLives => switch (_difficulty) {
    ContentDifficulty.easy => 6,
    ContentDifficulty.medium => 5,
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
    _flashTimer?.cancel();
    _setupFocusNode.dispose();
    _gameFocusNode.dispose();
    _overFocusNode.dispose();
    super.dispose();
  }

  // ── Game logic ──
  void _startGame() {
    _words.clear();
    _ghosts.clear();
    _input = '';
    _target = null;
    _score = 0;
    _lives = _startLives;
    _wordsDestroyed = 0;
    _wordsMissed = 0;
    _streak = 0;
    _bestStreak = 0;
    _isNewHighScore = false;
    _highScore = 0;
    _spawnTimer = _spawnInterval - 0.5; // spawn first word quickly
    _lastTick = Duration.zero;
    _gameStart = DateTime.now();
    _phase = _Phase.playing;
    _ticker.start();
    _sfx.playGameStart();
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
      _addGhost(w.word, w.x, w.y.clamp(0.0, 0.92), false, w.colorIndex);
      _words.remove(w);
      _wordsMissed++;
      _streak = 0;
      _lives--;
      _sfx.playMiss();
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

  void _showFlash(_FlashType type) {
    _flashTimer?.cancel();
    _flash = type;
    setState(() {});
    _flashTimer = Timer(const Duration(milliseconds: 400), () {
      if (mounted) setState(() => _flash = null);
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
        _input = _input.substring(0, _input.length - 1);
        _updateTarget();
        setState(() {});
      }
      return;
    }

    // Space/Enter clears input when there's no matching target
    if (event.logicalKey == LogicalKeyboardKey.space ||
        event.logicalKey == LogicalKeyboardKey.enter) {
      if (_input.isNotEmpty && _target == null) {
        _showFlash(_FlashType.wrong);
        _sfx.playIncorrect();
        _input = '';
        _streak = 0;
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
      _showFlash(_FlashType.correct);
      _sfx.playPop();
      if (_streak >= 3) _sfx.playStreak();
    } else {
      _sfx.playKeystroke();
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
    // Add success ghost at word position
    _addGhost(word.word, word.x, word.y, true, word.colorIndex);
    _words.remove(word);
    _score += word.word.length * 10;
    _wordsDestroyed++;
    _streak++;
    if (_streak > _bestStreak) _bestStreak = _streak;
    _input = '';
    _target = null;
  }

  void _addGhost(
    String word,
    double x,
    double y,
    bool success,
    int colorIndex,
  ) {
    final ghost = _Ghost(
      word: word,
      x: x,
      y: y,
      success: success,
      colorIndex: colorIndex,
    );
    _ghosts.add(ghost);
    Timer(const Duration(milliseconds: 600), () {
      if (mounted) {
        _ghosts.remove(ghost);
        setState(() {});
      }
    });
  }

  void _endGame() {
    _ticker.stop();
    _sfx.playGameOver();
    _gameDuration = DateTime.now().difference(_gameStart ?? DateTime.now());
    // Record high score
    final progress = Provider.of<ProgressProvider>(context, listen: false);
    _highScore = progress.getHighScore('falling_words');
    progress.recordScore('falling_words', _score).then((isNew) {
      if (mounted) setState(() => _isNewHighScore = isNew);
    });
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
          child: LayoutBuilder(
            builder: (context, constraints) {
              final screenW = constraints.maxWidth;
              final screenH = constraints.maxHeight;
              final isWide = screenW > 600;
              final isTall = screenH > 650;

              final hPad = isWide ? 40.0 : 20.0;
              final vPad = isTall ? 32.0 : 16.0;
              final maxW = isWide ? 520.0 : screenW;
              final headerFontSize = isWide ? 34.0 : 26.0;
              final emojiSize = isTall ? 56.0 : 36.0;
              final sectionGap = isTall ? 32.0 : 16.0;

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
                        // Back
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
                        Text('⬇️', style: TextStyle(fontSize: emojiSize)),
                        SizedBox(height: isTall ? 8 : 4),
                        Text(
                          'Falling Words',
                          style: GoogleFonts.fredoka(
                            fontSize: headerFontSize,
                            fontWeight: FontWeight.w700,
                            color: AppColors.primary,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Type the words before they reach the bottom!',
                          style: GoogleFonts.nunito(
                            fontSize: isWide ? 16.0 : 14.0,
                            color: AppColors.textSecondary,
                          ),
                          textAlign: TextAlign.center,
                        ),
                        SizedBox(height: sectionGap),
                        // Difficulty selector
                        Text(
                          'Choose Difficulty',
                          style: GoogleFonts.fredoka(
                            fontSize: isWide ? 20.0 : 18.0,
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
                                  onTap: () => setState(() => _difficulty = d),
                                ),
                              ),
                            );
                          }).toList(),
                        ),
                        SizedBox(height: sectionGap),
                        // Start button
                        SizedBox(
                          width: isWide ? 280 : 220,
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
                // Input area (top for visibility during touch typing)
                _buildInputArea(),
                // Game area
                Expanded(child: _buildGameArea()),
                const SizedBox(height: 4),
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
        // Update stored height so speed scales with available space
        _gameAreaHeight = areaH;

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
            // Ghost feedback indicators
            for (final g in _ghosts) _buildGhostIndicator(g, areaW, areaH),
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

  // Responsive font scale for game area
  double get _wordFontSize {
    final w = MediaQuery.of(context).size.width;
    if (w > 1200) return 28;
    if (w > 800) return 24;
    return 20;
  }

  double get _inputFontSize {
    final w = MediaQuery.of(context).size.width;
    if (w > 1200) return 30;
    if (w > 800) return 26;
    return 22;
  }

  Widget _buildWordBubble(_FallingWord word, double areaW, double areaH) {
    final isTarget = word == _target;
    final color = _bubbleColors[word.colorIndex];
    final fontSize = _wordFontSize;

    // Estimate width to clamp x
    final estWidth = word.word.length * (fontSize * 0.7) + 32;
    final maxLeft = (areaW - estWidth).clamp(0.0, double.infinity);
    final left = (word.x * areaW).clamp(0.0, maxLeft);
    final top = word.y * areaH;

    return Positioned(
      left: left,
      top: top,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 120),
        padding: EdgeInsets.symmetric(
          horizontal: fontSize * 0.7,
          vertical: fontSize * 0.4,
        ),
        decoration: BoxDecoration(
          color: isTarget ? color : color.withValues(alpha: 0.85),
          borderRadius: BorderRadius.circular(14),
          border: isTarget
              ? Border.all(
                  color: _input.isEmpty
                      ? AppColors.starFilled
                      : word.word.startsWith(_input)
                      ? const Color(0xFF00E676)
                      : const Color(0xFFFF5252),
                  width: 2.5,
                )
              : (_input.isNotEmpty && _target == null)
              ? Border.all(
                  color: const Color(0xFFFF5252).withValues(alpha: 0.7),
                  width: 2,
                )
              : null,
          boxShadow: isTarget
              ? [
                  BoxShadow(
                    color:
                        (_input.isEmpty
                                ? AppColors.starFilled
                                : word.word.startsWith(_input)
                                ? const Color(0xFF00E676)
                                : const Color(0xFFFF5252))
                            .withValues(alpha: 0.5),
                    blurRadius: 14,
                    spreadRadius: 2,
                  ),
                ]
              : (_input.isNotEmpty && _target == null)
              ? [
                  BoxShadow(
                    color: const Color(0xFFFF5252).withValues(alpha: 0.3),
                    blurRadius: 10,
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
            ? _buildPartialMatch(word.word, _input, fontSize)
            : Text(
                word.word,
                style: GoogleFonts.fredoka(
                  fontSize: fontSize,
                  fontWeight: FontWeight.w600,
                  color: Colors.white,
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
              color: matches
                  ? const Color(0xFF00E676)
                  : const Color(0xFFFF5252),
              shadows: [
                Shadow(
                  color: Colors.black.withValues(alpha: 0.3),
                  blurRadius: 2,
                ),
              ],
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

  Widget _buildGhostIndicator(_Ghost ghost, double areaW, double areaH) {
    final fontSize = _wordFontSize;
    final estWidth = ghost.word.length * (fontSize * 0.7) + 48;
    final maxLeft = (areaW - estWidth).clamp(0.0, double.infinity);
    final left = (ghost.x * areaW).clamp(0.0, maxLeft);
    final top = ghost.y * areaH;

    final color = ghost.success
        ? const Color(0xFF00E676)
        : const Color(0xFFFF5252);
    final icon = ghost.success ? Icons.check_circle : Icons.cancel;

    return Positioned(
      left: left,
      top: top,
      child: TweenAnimationBuilder<double>(
        tween: Tween(begin: 1.0, end: 0.0),
        duration: const Duration(milliseconds: 600),
        builder: (context, opacity, child) {
          return Opacity(
            opacity: opacity,
            child: Transform.translate(
              offset: Offset(0, -30 * (1 - opacity)),
              child: child,
            ),
          );
        },
        child: Container(
          padding: EdgeInsets.symmetric(
            horizontal: fontSize * 0.5,
            vertical: fontSize * 0.3,
          ),
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.25),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: color, width: 2),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, color: color, size: fontSize * 0.9),
              const SizedBox(width: 4),
              Text(
                ghost.word,
                style: GoogleFonts.fredoka(
                  fontSize: fontSize * 0.85,
                  fontWeight: FontWeight.w600,
                  color: color,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildInputArea() {
    final hasMatch = _target != null;
    final hasInput = _input.isNotEmpty;
    final noMatch = hasInput && !hasMatch;
    final fontSize = _inputFontSize;

    // Flash feedback colors
    Color bgColor = Colors.white;
    Color borderColor = noMatch
        ? AppColors.incorrect.withValues(alpha: 0.6)
        : hasMatch
        ? AppColors.primary.withValues(alpha: 0.6)
        : Colors.grey.shade300;

    if (_flash == _FlashType.correct) {
      bgColor = const Color(0xFFE8F5E9); // light green bg
      borderColor = AppColors.correct;
    } else if (_flash == _FlashType.wrong) {
      bgColor = const Color(0xFFFFEBEE); // light red bg
      borderColor = AppColors.incorrect;
    }

    return AnimatedContainer(
      duration: const Duration(milliseconds: 150),
      margin: const EdgeInsets.symmetric(horizontal: 32),
      padding: EdgeInsets.symmetric(
        horizontal: fontSize * 0.9,
        vertical: fontSize * 0.6,
      ),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: borderColor, width: _flash != null ? 3 : 2),
        boxShadow: [
          if (_flash == _FlashType.correct)
            BoxShadow(
              color: AppColors.correct.withValues(alpha: 0.3),
              blurRadius: 12,
              spreadRadius: 2,
            )
          else if (_flash == _FlashType.wrong)
            BoxShadow(
              color: AppColors.incorrect.withValues(alpha: 0.3),
              blurRadius: 12,
              spreadRadius: 2,
            )
          else
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
            _flash == _FlashType.correct
                ? Icons.check_circle_rounded
                : _flash == _FlashType.wrong
                ? Icons.cancel_rounded
                : Icons.keyboard_rounded,
            color: _flash == _FlashType.correct
                ? AppColors.correct
                : _flash == _FlashType.wrong
                ? AppColors.incorrect
                : hasInput
                ? AppColors.primary
                : Colors.grey.shade400,
            size: fontSize,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              _flash == _FlashType.correct
                  ? '✓ Nice!'
                  : _flash == _FlashType.wrong
                  ? '✗ No match'
                  : hasInput
                  ? _input
                  : 'Start typing...',
              style: GoogleFonts.fredoka(
                fontSize: fontSize,
                fontWeight: FontWeight.w500,
                color: _flash == _FlashType.correct
                    ? AppColors.correct
                    : _flash == _FlashType.wrong
                    ? AppColors.incorrect
                    : noMatch
                    ? AppColors.incorrect
                    : hasInput
                    ? AppColors.textPrimary
                    : Colors.grey.shade400,
              ),
            ),
          ),
          if (hasInput && _flash == null) ...[
            if (noMatch)
              Text(
                'Space',
                style: GoogleFonts.robotoMono(
                  fontSize: 10,
                  fontWeight: FontWeight.w600,
                  color: AppColors.incorrect.withValues(alpha: 0.6),
                ),
              ),
            const SizedBox(width: 6),
            Text(
              '⌫',
              style: TextStyle(
                fontSize: fontSize * 0.8,
                color: Colors.grey.shade400,
              ),
            ),
          ],
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
          child: LayoutBuilder(
            builder: (context, constraints) {
              final screenW = constraints.maxWidth;
              final screenH = constraints.maxHeight;
              final isWide = screenW > 600;
              final isTall = screenH > 650;

              final hPad = isWide ? 40.0 : 20.0;
              final vPad = isTall ? 32.0 : 16.0;
              final maxW = isWide ? 460.0 : screenW;
              final headerFontSize = isWide ? 36.0 : 28.0;
              final emojiSize = isTall ? 56.0 : 36.0;
              final scoreFontSize = isTall ? 52.0 : 36.0;
              final sectionGap = isTall ? 24.0 : 12.0;
              final statGap = isTall ? 12.0 : 8.0;

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
                        Text('🎮', style: TextStyle(fontSize: emojiSize)),
                        SizedBox(height: isTall ? 8 : 4),
                        Text(
                          'Game Over!',
                          style: GoogleFonts.fredoka(
                            fontSize: headerFontSize,
                            fontWeight: FontWeight.w700,
                            color: AppColors.accent,
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
                                AppColors.secondary.withValues(alpha: 0.15),
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
                        SizedBox(height: statGap),
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
                        SizedBox(height: sectionGap + 8),
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
              );
            },
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
  final bool compact;
  final VoidCallback onTap;

  const _DifficultyCard({
    required this.difficulty,
    required this.index,
    required this.selected,
    this.compact = false,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final vPad = compact ? 8.0 : 14.0;
    final emojiSize = compact ? 22.0 : 28.0;
    final labelSize = compact ? 14.0 : 16.0;
    final descSize = compact ? 10.0 : 11.0;

    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 160),
        padding: EdgeInsets.symmetric(vertical: vPad, horizontal: 8),
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
            Text(difficulty.emoji, style: TextStyle(fontSize: emojiSize)),
            SizedBox(height: compact ? 2 : 4),
            Text(
              difficulty.label,
              style: GoogleFonts.fredoka(
                fontSize: labelSize,
                fontWeight: FontWeight.w600,
                color: selected ? AppColors.primary : AppColors.textPrimary,
              ),
            ),
            if (!compact) ...[
              const SizedBox(height: 2),
              Text(
                difficulty.description,
                style: GoogleFonts.nunito(
                  fontSize: descSize,
                  color: AppColors.textSecondary,
                ),
                textAlign: TextAlign.center,
              ),
            ],
            SizedBox(height: compact ? 3 : 6),
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
