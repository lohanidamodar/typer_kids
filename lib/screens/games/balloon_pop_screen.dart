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

class _Balloon {
  final String word;
  double x; // 0.0 – 1.0
  double y; // 0.0 = top, 1.0 = bottom (starts near bottom, floats up)
  final double speed; // fraction of height per second (upward)
  final int colorIndex;
  final double wobbleOffset; // random phase for horizontal sway
  final double size; // 0.8 – 1.2 scale factor

  _Balloon({
    required this.word,
    required this.x,
    required this.y,
    required this.speed,
    required this.colorIndex,
    required this.wobbleOffset,
    required this.size,
  });
}

/// Pop effect shown briefly when a balloon is destroyed.
class _PopEffect {
  final double x;
  final double y;
  final int colorIndex;
  double life; // 1.0 -> 0.0

  _PopEffect({
    required this.x,
    required this.y,
    required this.colorIndex,
    this.life = 1.0,
  });
}

// Balloon colors – bright, party-like
const _balloonColors = [
  Color(0xFFE53935), // red
  Color(0xFFFF6F00), // amber
  Color(0xFFFFEB3B), // yellow
  Color(0xFF43A047), // green
  Color(0xFF1E88E5), // blue
  Color(0xFF8E24AA), // purple
  Color(0xFFEC407A), // pink
  Color(0xFF00ACC1), // cyan
];

// ─────────────────────────────────────────────────────────────────────────────
// Screen
// ─────────────────────────────────────────────────────────────────────────────

class BalloonPopScreen extends StatefulWidget {
  const BalloonPopScreen({super.key});

  @override
  State<BalloonPopScreen> createState() => _BalloonPopScreenState();
}

class _BalloonPopScreenState extends State<BalloonPopScreen>
    with SingleTickerProviderStateMixin {
  // ── State ──
  _Phase _phase = _Phase.setup;
  ContentDifficulty _difficulty = ContentDifficulty.easy;

  final List<_Balloon> _balloons = [];
  final List<_PopEffect> _pops = [];
  String _input = '';
  _Balloon? _target;
  int _score = 0;
  int _escaped = 0;
  int _popped = 0;
  int _streak = 0;
  int _bestStreak = 0;
  int _combo = 0;
  DateTime? _lastPopTime;
  bool _isNewHighScore = false;
  int _highScore = 0;

  // Timer
  Timer? _spawnTimer;
  int _remainingSeconds = 0;
  Timer? _countdownTimer;

  // Animation
  Ticker? _ticker;
  Duration _lastTick = Duration.zero;
  double _elapsed = 0; // total game time for wobble

  // Focus
  final _setupFocusNode = FocusNode();
  final _gameFocusNode = FocusNode();
  final _overFocusNode = FocusNode();

  final _sfx = SoundManager();
  final _random = Random();

  // ── Adaptive difficulty ──
  double _adaptiveSpeed = 1.0;

  void _onCorrectAdaptive() {
    _adaptiveSpeed = (_adaptiveSpeed + 0.03).clamp(0.5, 1.6);
  }

  void _onMissAdaptive() {
    _adaptiveSpeed = (_adaptiveSpeed - 0.08).clamp(0.5, 1.6);
  }

  // ── Difficulty Config ──

  int get _gameDuration => switch (_difficulty) {
    ContentDifficulty.easy => 60,
    ContentDifficulty.medium => 75,
    ContentDifficulty.hard => 90,
  };

  double get _baseSpawnInterval => switch (_difficulty) {
    ContentDifficulty.easy => 2.8,
    ContentDifficulty.medium => 2.2,
    ContentDifficulty.hard => 1.8,
  };

  int get _maxBalloons => switch (_difficulty) {
    ContentDifficulty.easy => 4,
    ContentDifficulty.medium => 5,
    ContentDifficulty.hard => 7,
  };

  double get _baseRiseSpeed => switch (_difficulty) {
    ContentDifficulty.easy => 0.06,
    ContentDifficulty.medium => 0.07,
    ContentDifficulty.hard => 0.085,
  };

  // ── Lifecycle ──

  @override
  void dispose() {
    _ticker?.dispose();
    _spawnTimer?.cancel();
    _countdownTimer?.cancel();
    _setupFocusNode.dispose();
    _gameFocusNode.dispose();
    _overFocusNode.dispose();
    super.dispose();
  }

  // ── Game Logic ──

  void _startGame() {
    final progress = context.read<ProgressProvider>();
    _highScore = progress.getHighScore('balloon-pop-${_difficulty.name}');

    setState(() {
      _phase = _Phase.playing;
      _balloons.clear();
      _pops.clear();
      _input = '';
      _target = null;
      _score = 0;
      _escaped = 0;
      _popped = 0;
      _streak = 0;
      _bestStreak = 0;
      _combo = 0;
      _lastPopTime = null;
      _isNewHighScore = false;
      _remainingSeconds = _gameDuration;
      _adaptiveSpeed = switch (_difficulty) {
        ContentDifficulty.easy => 0.7,
        ContentDifficulty.medium => 0.8,
        ContentDifficulty.hard => 0.9,
      };
      _elapsed = 0;
    });

    _startTicker();
    _startSpawning();
    _startCountdown();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      _gameFocusNode.requestFocus();
    });

    _sfx.playGameStart();
  }

  void _startTicker() {
    _ticker?.dispose();
    _lastTick = Duration.zero;
    _ticker = createTicker((elapsed) {
      if (_phase != _Phase.playing) return;
      final dt = (_lastTick == Duration.zero)
          ? 0.016
          : (elapsed - _lastTick).inMicroseconds / 1000000.0;
      _lastTick = elapsed;
      _elapsed += dt;
      _updateBalloons(dt);
    });
    _ticker!.start();
  }

  void _startSpawning() {
    _spawnTimer?.cancel();
    _scheduleNextSpawn();
  }

  void _scheduleNextSpawn() {
    final interval = _baseSpawnInterval / _adaptiveSpeed;
    final jitter = (_random.nextDouble() - 0.5) * 0.6;
    final ms = ((interval + jitter) * 1000).round().clamp(800, 5000);
    _spawnTimer = Timer(Duration(milliseconds: ms), () {
      if (_phase != _Phase.playing) return;
      _spawnBalloon();
      _scheduleNextSpawn();
    });
  }

  void _startCountdown() {
    _countdownTimer?.cancel();
    _countdownTimer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (_phase != _Phase.playing) return;
      setState(() {
        _remainingSeconds--;
        if (_remainingSeconds <= 0) _endGame();
      });
    });
  }

  void _spawnBalloon() {
    if (_balloons.length >= _maxBalloons) return;

    final word = WordLists.randomWord(_difficulty);
    // Avoid duplicates on screen
    if (_balloons.any((b) => b.word == word)) return;

    final speedVariation = 0.8 + _random.nextDouble() * 0.4;

    setState(() {
      _balloons.add(_Balloon(
        word: word,
        x: 0.08 + _random.nextDouble() * 0.84,
        y: 1.05 + _random.nextDouble() * 0.1, // start just below screen
        speed: _baseRiseSpeed * speedVariation * _adaptiveSpeed,
        colorIndex: _random.nextInt(_balloonColors.length),
        wobbleOffset: _random.nextDouble() * pi * 2,
        size: 0.85 + _random.nextDouble() * 0.3,
      ));
    });
  }

  void _updateBalloons(double dt) {
    bool changed = false;

    // Move balloons upward
    for (final b in _balloons) {
      b.y -= b.speed * dt;
      // Gentle horizontal wobble
      b.x += sin(_elapsed * 1.5 + b.wobbleOffset) * 0.0008;
      b.x = b.x.clamp(0.05, 0.95);
    }

    // Check for escaped balloons (past top)
    final escaped = _balloons.where((b) => b.y < -0.08).toList();
    for (final b in escaped) {
      _balloons.remove(b);
      _escaped++;
      _streak = 0;
      _combo = 0;
      _onMissAdaptive();
      _sfx.playMiss();
      // Clear target if it escaped
      if (_target == b) {
        _target = null;
        _input = '';
      }
      changed = true;
    }

    // Update pop effects
    _pops.removeWhere((p) {
      p.life -= dt * 2.5;
      return p.life <= 0;
    });

    if (changed || _pops.isNotEmpty || _balloons.isNotEmpty) {
      setState(() {});
    }
  }

  void _handleGameKey(KeyEvent event) {
    if (event is! KeyDownEvent) return;

    if (event.logicalKey == LogicalKeyboardKey.escape) {
      _ticker?.dispose();
      _spawnTimer?.cancel();
      _countdownTimer?.cancel();
      context.pop();
      return;
    }

    // Backspace
    if (event.logicalKey == LogicalKeyboardKey.backspace) {
      if (_input.isNotEmpty) {
        setState(() {
          _input = _input.substring(0, _input.length - 1);
          if (_input.isEmpty) _target = null;
        });
      }
      return;
    }

    final char = event.character;
    if (char == null || char.length != 1 || !RegExp(r'[a-zA-Z]').hasMatch(char)) {
      return;
    }

    final lower = char.toLowerCase();
    final newInput = _input + lower;

    // If we have a target, check against it
    if (_target != null) {
      if (_target!.word.startsWith(newInput)) {
        setState(() => _input = newInput);
        _sfx.playKeystroke();

        if (newInput == _target!.word) {
          _popBalloon(_target!);
        }
      } else {
        // Wrong key for current target
        _sfx.playIncorrect();
        setState(() {
          _streak = 0;
          _combo = 0;
        });
      }
      return;
    }

    // No target — find a balloon that starts with this letter
    final match = _balloons
        .where((b) => b.word.startsWith(newInput))
        .toList();

    if (match.isNotEmpty) {
      // Pick the lowest one (closest to escaping = highest y... wait,
      // they float up so lowest y is closest to escaping)
      match.sort((a, b) => a.y.compareTo(b.y));
      final picked = match.first;

      setState(() {
        _target = picked;
        _input = newInput;
      });
      _sfx.playKeystroke();

      if (newInput == picked.word) {
        _popBalloon(picked);
      }
    } else {
      _sfx.playIncorrect();
      setState(() {
        _streak = 0;
        _combo = 0;
      });
    }
  }

  void _popBalloon(_Balloon balloon) {
    _sfx.playPop();

    // Combo: if popped within 2 seconds of last pop
    final now = DateTime.now();
    if (_lastPopTime != null &&
        now.difference(_lastPopTime!).inMilliseconds < 2000) {
      _combo++;
    } else {
      _combo = 1;
    }
    _lastPopTime = now;

    final comboBonus = _combo >= 3 ? _combo * 2 : 0;
    final streakBonus = _streak >= 3 ? (_streak ~/ 3) * 5 : 0;
    final basePoints = switch (_difficulty) {
      ContentDifficulty.easy => 10,
      ContentDifficulty.medium => 15,
      ContentDifficulty.hard => 20,
    };

    if (_combo >= 3) _sfx.playStreak();

    setState(() {
      _pops.add(_PopEffect(
        x: balloon.x,
        y: balloon.y,
        colorIndex: balloon.colorIndex,
      ));
      _balloons.remove(balloon);
      _score += basePoints + comboBonus + streakBonus;
      _popped++;
      _streak++;
      if (_streak > _bestStreak) _bestStreak = _streak;
      _target = null;
      _input = '';
    });

    _onCorrectAdaptive();
  }

  void _endGame() {
    _ticker?.dispose();
    _spawnTimer?.cancel();
    _countdownTimer?.cancel();

    _sfx.playGameOver();

    final progress = context.read<ProgressProvider>();
    progress
        .recordScore('balloon-pop-${_difficulty.name}', _score)
        .then((isNew) {
      if (isNew && mounted) setState(() => _isNewHighScore = true);
    });

    setState(() => _phase = _Phase.gameOver);

    WidgetsBinding.instance.addPostFrameCallback((_) {
      _overFocusNode.requestFocus();
    });
  }

  // ── Build ──

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: switch (_phase) {
        _Phase.setup => _buildSetup(),
        _Phase.playing => _buildPlaying(),
        _Phase.gameOver => _buildGameOver(),
      },
    );
  }

  // ── Setup ──

  Widget _buildSetup() {
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [Color(0xFF87CEEB), Color(0xFFE0F7FA)],
        ),
      ),
      child: KeyboardListener(
        focusNode: _setupFocusNode,
        autofocus: true,
        onKeyEvent: (event) {
          if (event is! KeyDownEvent) return;
          final key = event.logicalKey;
          if (key == LogicalKeyboardKey.escape) {
            context.pop();
          } else if (key == LogicalKeyboardKey.digit1) {
            setState(() => _difficulty = ContentDifficulty.easy);
          } else if (key == LogicalKeyboardKey.digit2) {
            setState(() => _difficulty = ContentDifficulty.medium);
          } else if (key == LogicalKeyboardKey.digit3) {
            setState(() => _difficulty = ContentDifficulty.hard);
          } else if (key == LogicalKeyboardKey.enter ||
              key == LogicalKeyboardKey.space) {
            _startGame();
          }
        },
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(32),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 480),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Back
                  Align(
                    alignment: Alignment.centerLeft,
                    child: TextButton.icon(
                      onPressed: () => context.pop(),
                      icon: const Icon(Icons.arrow_back_rounded, size: 18),
                      label: Text('Back',
                          style: GoogleFonts.fredoka(fontSize: 16)),
                      style: TextButton.styleFrom(
                        foregroundColor: Colors.white70,
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  const Text('🎈', style: TextStyle(fontSize: 72)),
                  const SizedBox(height: 8),
                  Text(
                    'Balloon Pop',
                    style: GoogleFonts.fredoka(
                      fontSize: 34,
                      fontWeight: FontWeight.w700,
                      color: const Color(0xFFE53935),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Type the words on the balloons to pop them\nbefore they float away!',
                    textAlign: TextAlign.center,
                    style: GoogleFonts.nunito(
                      fontSize: 15,
                      color: Colors.blueGrey.shade700,
                    ),
                  ),
                  const SizedBox(height: 28),
                  // Difficulty
                  Text(
                    'Choose Difficulty',
                    style: GoogleFonts.fredoka(
                      fontSize: 18,
                      fontWeight: FontWeight.w500,
                      color: Colors.blueGrey.shade800,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: ContentDifficulty.values.map((d) {
                      final isSelected = _difficulty == d;
                      final colors = {
                        ContentDifficulty.easy: AppColors.correct,
                        ContentDifficulty.medium: AppColors.secondary,
                        ContentDifficulty.hard: AppColors.incorrect,
                      };
                      final c = colors[d]!;
                      return Expanded(
                        child: Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 4),
                          child: Material(
                            color: Colors.transparent,
                            child: InkWell(
                              onTap: () => setState(() => _difficulty = d),
                              borderRadius: BorderRadius.circular(12),
                              child: AnimatedContainer(
                                duration: const Duration(milliseconds: 200),
                                padding:
                                    const EdgeInsets.symmetric(vertical: 14),
                                decoration: BoxDecoration(
                                  color: isSelected
                                      ? c.withValues(alpha: 0.2)
                                      : Colors.white.withValues(alpha: 0.7),
                                  borderRadius: BorderRadius.circular(12),
                                  border: Border.all(
                                    color:
                                        isSelected ? c : Colors.grey.shade300,
                                    width: isSelected ? 2 : 1,
                                  ),
                                ),
                                child: Column(
                                  children: [
                                    Text(d.emoji,
                                        style: const TextStyle(fontSize: 22)),
                                    const SizedBox(height: 4),
                                    Text(
                                      d.label,
                                      style: GoogleFonts.fredoka(
                                        fontSize: 14,
                                        fontWeight: FontWeight.w500,
                                        color: isSelected
                                            ? c
                                            : AppColors.textSecondary,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                        ),
                      );
                    }).toList(),
                  ),
                  const SizedBox(height: 28),
                  // Start
                  SizedBox(
                    width: double.infinity,
                    height: 52,
                    child: ElevatedButton(
                      onPressed: _startGame,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFFE53935),
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                        elevation: 3,
                      ),
                      child: Text(
                        'Start Popping!',
                        style: GoogleFonts.fredoka(
                          fontSize: 20,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  // ── Playing ──

  Widget _buildPlaying() {
    return KeyboardListener(
      focusNode: _gameFocusNode,
      autofocus: true,
      onKeyEvent: _handleGameKey,
      child: LayoutBuilder(
        builder: (context, constraints) {
          final w = constraints.maxWidth;
          final h = constraints.maxHeight;
          final isCompact = h < 500;

          return Container(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [Color(0xFF87CEEB), Color(0xFFBBDEFB)],
              ),
            ),
            child: Stack(
              children: [
                // ── Balloons ──
                for (final balloon in _balloons)
                  _buildBalloon(balloon, w, h),

                // ── Pop effects ──
                for (final pop in _pops)
                  _buildPopEffect(pop, w, h),

                // ── Top HUD ──
                Positioned(
                  top: MediaQuery.of(context).padding.top + 8,
                  left: 12,
                  right: 12,
                  child: _buildHUD(isCompact),
                ),

                // ── Input display at bottom ──
                Positioned(
                  bottom: 16,
                  left: 0,
                  right: 0,
                  child: _buildInputBar(),
                ),

                // ── Combo display ──
                if (_combo >= 3)
                  Positioned(
                    top: MediaQuery.of(context).padding.top + 56,
                    left: 0,
                    right: 0,
                    child: Center(
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 6,
                        ),
                        decoration: BoxDecoration(
                          color: AppColors.secondary.withValues(alpha: 0.9),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text(
                          '${_combo}x COMBO!',
                          style: GoogleFonts.fredoka(
                            fontSize: 18,
                            fontWeight: FontWeight.w700,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildBalloon(_Balloon balloon, double screenW, double screenH) {
    final bw = 120.0 * balloon.size;
    final bh = 150.0 * balloon.size;
    final totalH = bh + 40; // balloon + string
    final wordH = 32.0; // estimated word label height
    final fullH = wordH + 4 + totalH;
    final left = balloon.x * screenW - bw / 2;
    final top = balloon.y * screenH - fullH;
    final color = _balloonColors[balloon.colorIndex];
    final isTarget = balloon == _target;

    return Positioned(
      left: left,
      top: top,
      child: SizedBox(
        width: bw + 40, // extra width for word overflow
        height: fullH,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Word label above balloon
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
              decoration: BoxDecoration(
                color: isTarget
                    ? Colors.white
                    : Colors.white.withValues(alpha: 0.9),
                borderRadius: BorderRadius.circular(10),
                border: isTarget
                    ? Border.all(color: color, width: 2.5)
                    : null,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.12),
                    blurRadius: 6,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: RichText(
                text: TextSpan(
                  children: _buildWordSpans(balloon.word, isTarget),
                  style: GoogleFonts.fredoka(
                    fontSize: 18 * balloon.size,
                    fontWeight: FontWeight.w600,
                    color: Colors.grey.shade800,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 4),
            // Balloon shape
            CustomPaint(
              size: Size(bw, bh),
              painter: _BalloonPainter(
                color: color,
                isTarget: isTarget,
              ),
            ),
          ],
        ),
      ),
    );
  }

  List<TextSpan> _buildWordSpans(String word, bool isTarget) {
    if (!isTarget || _input.isEmpty) {
      return [TextSpan(text: word)];
    }
    return [
      TextSpan(
        text: word.substring(0, _input.length),
        style: TextStyle(color: AppColors.correct),
      ),
      TextSpan(
        text: word.substring(_input.length),
      ),
    ];
  }

  Widget _buildPopEffect(_PopEffect pop, double screenW, double screenH) {
    final color = _balloonColors[pop.colorIndex];
    final cx = pop.x * screenW;
    final cy = pop.y * screenH;
    final size = 100.0 * pop.life;

    return Positioned(
      left: cx - size / 2,
      top: cy - size / 2,
      child: IgnorePointer(
        child: Opacity(
          opacity: pop.life.clamp(0, 1),
          child: Container(
            width: size,
            height: size,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: color.withValues(alpha: 0.3),
              border: Border.all(
                color: color.withValues(alpha: 0.5),
                width: 2,
              ),
            ),
            child: Center(
              child: Text(
                'POP!',
                style: GoogleFonts.fredoka(
                  fontSize: 18 * pop.life,
                  fontWeight: FontWeight.w700,
                  color: color,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildHUD(bool isCompact) {
    final timerColor = _remainingSeconds <= 10
        ? AppColors.incorrect
        : _remainingSeconds <= 30
            ? AppColors.secondary
            : Colors.white;

    return Row(
      children: [
        // Score
        _hudChip(
          '🎈 $_score',
          Colors.white.withValues(alpha: 0.85),
          const Color(0xFFE53935),
        ),
        const SizedBox(width: 8),
        // Streak
        if (_streak >= 2)
          _hudChip(
            '🔥 $_streak',
            AppColors.secondary.withValues(alpha: 0.15),
            AppColors.secondary,
          ),
        const Spacer(),
        // Escaped
        _hudChip(
          '💨 $_escaped',
          Colors.white.withValues(alpha: 0.85),
          Colors.blueGrey,
        ),
        const SizedBox(width: 8),
        // Timer
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.85),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Row(
            children: [
              Icon(Icons.timer_outlined, size: 16, color: timerColor),
              const SizedBox(width: 4),
              Text(
                _formatTime(_remainingSeconds),
                style: GoogleFonts.fredoka(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: timerColor,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _hudChip(String text, Color bg, Color fg) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        text,
        style: GoogleFonts.fredoka(
          fontSize: 16,
          fontWeight: FontWeight.w600,
          color: fg,
        ),
      ),
    );
  }

  Widget _buildInputBar() {
    return Center(
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 20),
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
        constraints: const BoxConstraints(maxWidth: 400),
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.92),
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.1),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.keyboard_rounded,
              color: Colors.blueGrey.shade300,
              size: 20,
            ),
            const SizedBox(width: 10),
            Flexible(
              child: Text(
                _input.isEmpty ? 'Type to pop balloons...' : _input,
                style: GoogleFonts.sourceCodePro(
                  fontSize: 20,
                  fontWeight: FontWeight.w600,
                  color: _input.isEmpty
                      ? Colors.blueGrey.shade300
                      : AppColors.textPrimary,
                  letterSpacing: 2,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ── Game Over ──

  Widget _buildGameOver() {
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [Color(0xFF87CEEB), Color(0xFFE0F7FA)],
        ),
      ),
      child: KeyboardListener(
        focusNode: _overFocusNode,
        autofocus: true,
        onKeyEvent: (event) {
          if (event is! KeyDownEvent) return;
          final key = event.logicalKey;
          if (key == LogicalKeyboardKey.enter ||
              key == LogicalKeyboardKey.space) {
            _startGame();
          } else if (key == LogicalKeyboardKey.escape) {
            context.pop();
          }
        },
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(32),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 420),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    _isNewHighScore ? '🏆' : '🎈',
                    style: const TextStyle(fontSize: 64),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    _isNewHighScore ? 'New High Score!' : 'Time\'s Up!',
                    style: GoogleFonts.fredoka(
                      fontSize: 28,
                      fontWeight: FontWeight.w700,
                      color: _isNewHighScore
                          ? AppColors.secondary
                          : const Color(0xFFE53935),
                    ),
                  ),
                  const SizedBox(height: 24),
                  // Stats
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.9),
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.06),
                          blurRadius: 10,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: Column(
                      children: [
                        _statRow('Score', '$_score',
                            const Color(0xFFE53935)),
                        _statRow('Balloons Popped', '$_popped',
                            AppColors.correct),
                        _statRow('Escaped', '$_escaped',
                            Colors.blueGrey),
                        _statRow('Best Streak', '$_bestStreak 🔥',
                            AppColors.secondary),
                        if (_highScore > 0)
                          _statRow('Previous Best', '$_highScore',
                              Colors.grey),
                      ],
                    ),
                  ),
                  const SizedBox(height: 28),
                  SizedBox(
                    width: double.infinity,
                    height: 50,
                    child: ElevatedButton.icon(
                      onPressed: _startGame,
                      icon: const Icon(Icons.refresh_rounded),
                      label: Text(
                        'Pop Again!',
                        style: GoogleFonts.fredoka(fontSize: 18),
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFFE53935),
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 10),
                  TextButton(
                    onPressed: () => context.pop(),
                    child: Text(
                      'Back to Games (Esc)',
                      style: GoogleFonts.fredoka(
                        fontSize: 15,
                        color: Colors.blueGrey,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _statRow(String label, String value, Color color) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: GoogleFonts.nunito(
              fontSize: 16,
              color: AppColors.textSecondary,
            ),
          ),
          Text(
            value,
            style: GoogleFonts.fredoka(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: color,
            ),
          ),
        ],
      ),
    );
  }

  String _formatTime(int seconds) {
    final m = seconds ~/ 60;
    final s = seconds % 60;
    return '${m.toString().padLeft(2, '0')}:${s.toString().padLeft(2, '0')}';
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Balloon painter
// ─────────────────────────────────────────────────────────────────────────────

class _BalloonPainter extends CustomPainter {
  final Color color;
  final bool isTarget;

  _BalloonPainter({required this.color, this.isTarget = false});

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;
    final cx = w / 2;

    // Balloon body (oval)
    final bodyRect = Rect.fromCenter(
      center: Offset(cx, h * 0.4),
      width: w * 0.88,
      height: h * 0.75,
    );

    // Shadow
    canvas.drawOval(
      bodyRect.shift(const Offset(2, 3)),
      Paint()..color = Colors.black.withValues(alpha: 0.08),
    );

    // Main body
    final bodyPaint = Paint()
      ..shader = LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [
          Color.lerp(color, Colors.white, 0.3)!,
          color,
          Color.lerp(color, Colors.black, 0.15)!,
        ],
        stops: const [0.0, 0.5, 1.0],
      ).createShader(bodyRect);

    canvas.drawOval(bodyRect, bodyPaint);

    // Highlight
    canvas.drawOval(
      Rect.fromCenter(
        center: Offset(cx - w * 0.12, h * 0.28),
        width: w * 0.25,
        height: h * 0.2,
      ),
      Paint()..color = Colors.white.withValues(alpha: 0.4),
    );

    // Knot
    final knotY = h * 0.77;
    final knotPath = Path()
      ..moveTo(cx - 4, knotY)
      ..lineTo(cx, knotY + 6)
      ..lineTo(cx + 4, knotY)
      ..close();
    canvas.drawPath(knotPath, Paint()..color = Color.lerp(color, Colors.black, 0.2)!);

    // String
    final stringPaint = Paint()
      ..color = Colors.grey.shade500
      ..strokeWidth = 1
      ..style = PaintingStyle.stroke;
    final stringPath = Path()
      ..moveTo(cx, knotY + 6)
      ..cubicTo(
        cx - 5, knotY + 14,
        cx + 5, knotY + 22,
        cx, h,
      );
    canvas.drawPath(stringPath, stringPaint);

    // Target glow
    if (isTarget) {
      canvas.drawOval(
        bodyRect.inflate(3),
        Paint()
          ..color = Colors.white.withValues(alpha: 0.5)
          ..style = PaintingStyle.stroke
          ..strokeWidth = 3,
      );
    }
  }

  @override
  bool shouldRepaint(covariant _BalloonPainter old) =>
      color != old.color || isTarget != old.isTarget;
}
