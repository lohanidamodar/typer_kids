import 'dart:async';
import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';

import '../../core/sound_manager.dart';
import '../../core/theme/app_colors.dart';
import '../../data/word_lists.dart';
import '../../providers/progress_provider.dart';
import '../../widgets/quit_dialog.dart';
import 'widgets/key_critters_views.dart';

// ─────────────────────────────────────────────────────────────────────────────
// Data
// ─────────────────────────────────────────────────────────────────────────────

enum _Phase { setup, playing, gameOver }

/// A critter currently peeking out of a hole, waiting to be bonked.
class _Critter {
  final String letter;
  final String emoji;

  /// Seconds until the critter hides again.
  double secondsLeft;

  _Critter({required this.letter, required this.emoji, required this.secondsLeft});
}

const _accent = Color(0xFF43A047);

// ─────────────────────────────────────────────────────────────────────────────
// Screen
// ─────────────────────────────────────────────────────────────────────────────

/// Whack-a-mole with letters: critters pop out of holes holding a key,
/// press that key to bonk them before they hide. The letter pool is biased
/// toward the profile's tricky keys so weak keys get extra reps.
class KeyCrittersScreen extends StatefulWidget {
  const KeyCrittersScreen({super.key});

  @override
  State<KeyCrittersScreen> createState() => _KeyCrittersScreenState();
}

class _KeyCrittersScreenState extends State<KeyCrittersScreen> {
  static const _slotCount = 9;
  static const _critterEmojis = ['🐹', '🐰', '🦊', '🐸', '🐭', '🐿️'];
  static const _gameDuration = 60;
  static const _trickyBias = 0.35;

  // ── State ──
  _Phase _phase = _Phase.setup;
  ContentDifficulty _difficulty = ContentDifficulty.easy;

  final List<_Critter?> _slots = List.filled(_slotCount, null);
  List<String> _trickyKeys = [];
  int _score = 0;
  int _bonked = 0;
  int _escaped = 0;
  int _wrongKeys = 0;
  int _streak = 0;
  int _bestStreak = 0;
  int _remainingSeconds = 0;
  double _spawnCooldown = 0;
  bool _isNewHighScore = false;
  int _highScore = 0;

  Timer? _tickTimer;
  final _random = Random();

  // Focus
  final _setupFocusNode = FocusNode();
  final _gameFocusNode = FocusNode();
  final _overFocusNode = FocusNode();

  final _sfx = SoundManager();

  // ── Difficulty Config ──

  String get _letterPool => switch (_difficulty) {
    ContentDifficulty.easy => 'asdfghjkl',
    ContentDifficulty.medium => 'abcdefghijklmnopqrstuvwxyz',
    ContentDifficulty.hard => 'abcdefghijklmnopqrstuvwxyz0123456789',
  };

  /// How long a critter stays visible before escaping.
  double get _visibleSeconds => switch (_difficulty) {
    ContentDifficulty.easy => 3.0,
    ContentDifficulty.medium => 2.2,
    ContentDifficulty.hard => 1.6,
  };

  /// Time between critter spawns.
  double get _spawnInterval => switch (_difficulty) {
    ContentDifficulty.easy => 1.8,
    ContentDifficulty.medium => 1.2,
    ContentDifficulty.hard => 0.85,
  };

  @override
  void dispose() {
    _tickTimer?.cancel();
    _setupFocusNode.dispose();
    _gameFocusNode.dispose();
    _overFocusNode.dispose();
    super.dispose();
  }

  // ── Game Logic ──

  void _startGame() {
    final progress = Provider.of<ProgressProvider>(context, listen: false);
    // Bias spawns toward the profile's tricky keys that fit this pool
    _trickyKeys = progress.trickyKeys
        .where((k) => _letterPool.contains(k))
        .toList();

    for (var i = 0; i < _slotCount; i++) {
      _slots[i] = null;
    }
    _score = 0;
    _bonked = 0;
    _escaped = 0;
    _wrongKeys = 0;
    _streak = 0;
    _bestStreak = 0;
    _remainingSeconds = _gameDuration;
    _spawnCooldown = 0.5;
    _isNewHighScore = false;
    _highScore = 0;
    _phase = _Phase.playing;
    _sfx.playGameStart();
    setState(() {});

    _startTimers();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _gameFocusNode.requestFocus();
    });
  }

  void _startTimers() {
    var subTicks = 0;
    _tickTimer = Timer.periodic(const Duration(milliseconds: 100), (_) {
      if (!mounted || _phase != _Phase.playing) return;
      setState(() {
        // Countdown clock (10 sub-ticks = 1 second; pause-safe)
        subTicks++;
        if (subTicks >= 10) {
          subTicks = 0;
          _remainingSeconds--;
          if (_remainingSeconds <= 0) {
            _endGame();
            return;
          }
        }

        // Critters escape when their time runs out
        for (var i = 0; i < _slotCount; i++) {
          final critter = _slots[i];
          if (critter == null) continue;
          critter.secondsLeft -= 0.1;
          if (critter.secondsLeft <= 0) {
            _slots[i] = null;
            _escaped++;
            _streak = 0;
            _sfx.playMiss();
          }
        }

        // Spawn new critters
        _spawnCooldown -= 0.1;
        if (_spawnCooldown <= 0) {
          _spawnCritter();
          _spawnCooldown = _spawnInterval;
        }
      });
    });
  }

  void _spawnCritter() {
    final freeSlots = [
      for (var i = 0; i < _slotCount; i++)
        if (_slots[i] == null) i,
    ];
    if (freeSlots.isEmpty) return;

    final visibleLetters = {
      for (final critter in _slots)
        if (critter != null) critter.letter,
    };

    // Pick a letter not already on screen, favoring tricky keys
    String letter;
    var tries = 0;
    do {
      if (_trickyKeys.isNotEmpty && _random.nextDouble() < _trickyBias) {
        letter = _trickyKeys[_random.nextInt(_trickyKeys.length)];
      } else {
        letter = _letterPool[_random.nextInt(_letterPool.length)];
      }
      tries++;
    } while (visibleLetters.contains(letter) && tries < 20);
    if (visibleLetters.contains(letter)) return;

    final slot = freeSlots[_random.nextInt(freeSlots.length)];
    _slots[slot] = _Critter(
      letter: letter,
      emoji: _critterEmojis[_random.nextInt(_critterEmojis.length)],
      secondsLeft: _visibleSeconds,
    );
  }

  void _handleGameKey(KeyEvent event) {
    if (event is! KeyDownEvent) return;

    if (event.logicalKey == LogicalKeyboardKey.escape) {
      _showQuitDialog();
      return;
    }

    final char = event.character?.toLowerCase();
    if (char == null || char.isEmpty) return;
    if (!RegExp(r'^[a-z0-9]$').hasMatch(char)) return;

    final slot = _slots.indexWhere((c) => c != null && c.letter == char);
    setState(() {
      if (slot >= 0) {
        _slots[slot] = null;
        _bonked++;
        _streak++;
        if (_streak > _bestStreak) _bestStreak = _streak;
        _score += 10 + min(_streak, 10);
        if (_streak > 0 && _streak % 10 == 0) {
          _score += 25;
          _sfx.playStreak();
        } else {
          _sfx.playPop();
        }
      } else {
        _wrongKeys++;
        _streak = 0;
        _sfx.playIncorrect();
      }
    });
  }

  void _endGame() {
    _tickTimer?.cancel();
    _sfx.playGameOver();
    final progress = Provider.of<ProgressProvider>(context, listen: false);
    _highScore = progress.getHighScore('key_critters');
    progress.recordScore('key_critters', _score).then((isNew) {
      if (mounted) setState(() => _isNewHighScore = isNew);
    });
    _phase = _Phase.gameOver;
    setState(() {});
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _overFocusNode.requestFocus();
    });
  }

  void _showQuitDialog() {
    _tickTimer?.cancel();
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => QuitDialog(
        title: 'Leave the Garden?',
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
        _startTimers();
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

  Widget _buildSetup() {
    final progress = context.watch<ProgressProvider>();
    return KeyCrittersMenu(
      difficulty: _difficulty,
      trickyKeys: progress.trickyKeys,
      focusNode: _setupFocusNode,
      onDifficultySelected: (d) => setState(() => _difficulty = d),
      onStart: _startGame,
      onBack: () => context.pop(),
    );
  }

  Widget _buildGameOver() {
    final attempts = _bonked + _wrongKeys;
    final accuracy = attempts > 0 ? (_bonked / attempts * 100).round() : 100;
    return KeyCrittersGameOver(
      score: _score,
      isNewHighScore: _isNewHighScore,
      highScore: _highScore,
      bonked: _bonked,
      escaped: _escaped,
      accuracy: accuracy,
      bestStreak: _bestStreak,
      focusNode: _overFocusNode,
      onPlayAgain: _playAgain,
      onBack: () => context.pop(),
    );
  }

  // ── Playing ───────────────────────────────────────────────────────────────

  Widget _buildGame() {
    final timerColor = _remainingSeconds <= 10
        ? AppColors.incorrect
        : _accent;

    return Scaffold(
      backgroundColor: const Color(0xFFE8F5E9),
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
                      InkWell(
                        onTap: _showQuitDialog,
                        borderRadius: BorderRadius.circular(8),
                        child: const Padding(
                          padding: EdgeInsets.all(4),
                          child: Icon(
                            Icons.close_rounded,
                            size: 22,
                            color: AppColors.textSecondary,
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      const Text('⭐', style: TextStyle(fontSize: 20)),
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
                        '0:${_remainingSeconds.toString().padLeft(2, '0')}',
                        style: GoogleFonts.fredoka(
                          fontSize: 20,
                          fontWeight: FontWeight.w600,
                          color: timerColor,
                        ),
                      ),
                      const Spacer(),
                      if (_streak >= 3) ...[
                        Text(
                          '🔥 $_streak',
                          style: GoogleFonts.fredoka(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                            color: AppColors.accent,
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
                          color: _accent.withValues(alpha: 0.12),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          '${_difficulty.emoji} ${_difficulty.label}',
                          style: GoogleFonts.nunito(
                            fontSize: 12,
                            fontWeight: FontWeight.w700,
                            color: _accent,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                // Garden grid
                Expanded(
                  child: Center(
                    child: LayoutBuilder(
                      builder: (context, constraints) {
                        final side = min(
                          constraints.maxWidth - 32,
                          constraints.maxHeight - 16,
                        ).clamp(240.0, 560.0);
                        return SizedBox(
                          width: side,
                          height: side,
                          child: GridView.count(
                            crossAxisCount: 3,
                            mainAxisSpacing: 12,
                            crossAxisSpacing: 12,
                            physics: const NeverScrollableScrollPhysics(),
                            children: [
                              for (var i = 0; i < _slotCount; i++)
                                _buildHole(_slots[i]),
                            ],
                          ),
                        );
                      },
                    ),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.only(bottom: 10),
                  child: Text(
                    'Press the key on each critter before it hides!',
                    style: GoogleFonts.nunito(
                      fontSize: 13,
                      color: AppColors.textSecondary,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildHole(_Critter? critter) {
    final urgent = critter != null && critter.secondsLeft < 0.8;

    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFFC8E6C9),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFFA5D6A7), width: 2),
      ),
      child: Stack(
        alignment: Alignment.center,
        children: [
          // The hole
          Align(
            alignment: const Alignment(0, 0.75),
            child: FractionallySizedBox(
              widthFactor: 0.62,
              child: AspectRatio(
                aspectRatio: 2.6,
                child: Container(
                  decoration: BoxDecoration(
                    color: const Color(0xFF6D4C41),
                    borderRadius: BorderRadius.circular(100),
                  ),
                ),
              ),
            ),
          ),
          // The critter + its key
          if (critter != null)
            AnimatedScale(
              scale: 1,
              duration: const Duration(milliseconds: 120),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 2,
                    ),
                    decoration: BoxDecoration(
                      color: urgent ? AppColors.incorrect : Colors.white,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(
                        color: urgent ? AppColors.incorrect : _accent,
                        width: 2,
                      ),
                    ),
                    child: Text(
                      critter.letter.toUpperCase(),
                      style: GoogleFonts.robotoMono(
                        fontSize: 22,
                        fontWeight: FontWeight.w700,
                        color: urgent ? Colors.white : _accent,
                      ),
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(critter.emoji, style: const TextStyle(fontSize: 36)),
                ],
              ),
            ),
        ],
      ),
    );
  }
}
