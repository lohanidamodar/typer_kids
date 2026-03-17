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

class _DemonWord {
  final String word;
  double x; // 0.0 – 1.0 fraction of width
  double y; // 0.0 – 1.0 fraction of height (0 = top)
  final double speed; // fraction of height per second
  final int colorIndex;

  _DemonWord({
    required this.word,
    required this.x,
    required this.y,
    required this.speed,
    required this.colorIndex,
  });
}

class _Ghost {
  final String word;
  final double x;
  final double y;
  final bool success;
  final int colorIndex;

  _Ghost({
    required this.word,
    required this.x,
    required this.y,
    required this.success,
    required this.colorIndex,
  });
}

/// A trishul projectile flying from the temple up to a demon.
class _Trishul {
  final double targetX; // fraction 0..1
  final double targetY; // fraction 0..1
  final DateTime spawnTime;
  static const duration = Duration(milliseconds: 650);

  _Trishul({required this.targetX, required this.targetY})
      : spawnTime = DateTime.now();

  /// 0.0 = just spawned at temple, 1.0 = reached target.
  double get progress =>
      (DateTime.now().difference(spawnTime).inMilliseconds /
          duration.inMilliseconds)
          .clamp(0.0, 1.0);

  bool get done => progress >= 1.0;
}

// ─────────────────────────────────────────────────────────────────────────────
// Screen
// ─────────────────────────────────────────────────────────────────────────────

class DefendTempleScreen extends StatefulWidget {
  const DefendTempleScreen({super.key});

  @override
  State<DefendTempleScreen> createState() => _DefendTempleScreenState();
}

class _DefendTempleScreenState extends State<DefendTempleScreen>
    with SingleTickerProviderStateMixin {
  // ── Theme colors ──
  static const _demonColors = [
    Color(0xFF8B0000), // dark red
    Color(0xFF4A0E4E), // dark purple
    Color(0xFFB22222), // firebrick
    Color(0xFF2C1654), // indigo-dark
    Color(0xFF6B1010), // blood
    Color(0xFF1B4332), // dark green
    Color(0xFF5C1A1A), // maroon
    Color(0xFF3D0C5E), // violet
  ];

  static const _bgTop = Color(0xFF05031A);
  static const _bgMid = Color(0xFF120A3A);
  static const _bgBottom = Color(0xFF1E1250);

  // ── State ──
  _Phase _phase = _Phase.setup;
  ContentDifficulty _difficulty = ContentDifficulty.easy;

  final List<_DemonWord> _demons = [];
  String _input = '';
  _DemonWord? _target;
  int _score = 0;
  double _templeHealth = 1.0; // 0.0 = destroyed, 1.0 = full
  int _demonsSlain = 0;
  int _demonsReached = 0;
  int _streak = 0;
  int _bestStreak = 0;
  DateTime? _gameStart;
  Duration _gameDuration = Duration.zero;
  bool _isNewHighScore = false;
  int _highScore = 0;

  _FlashType? _flash;
  Timer? _flashTimer;
  final List<_Ghost> _ghosts = [];

  // Damage flash on temple
  bool _templeDamageFlash = false;

  // Trishul projectiles in flight
  final List<_Trishul> _trishuls = [];

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
  static const _refHeight = 600.0;
  double _gameAreaHeight = _refHeight;

  double get _heightScale => (_gameAreaHeight / _refHeight).clamp(0.55, 1.0);

  /// Adaptive speed: starts gentle, ramps on correct, dips on miss.
  double _adaptiveSpeed = 0.55;

  void _onCorrectAdaptive() {
    _adaptiveSpeed = (_adaptiveSpeed + 0.06).clamp(0.4, 1.5);
  }

  void _onMissAdaptive() {
    _adaptiveSpeed = (_adaptiveSpeed - 0.08).clamp(0.4, 1.5);
  }

  double get _spawnInterval => switch (_difficulty) {
    ContentDifficulty.easy => 3.4,
    ContentDifficulty.medium => 3.0,
    ContentDifficulty.hard => 2.6,
  } / _adaptiveSpeed;

  double get _minSpeed => _heightScale * _adaptiveSpeed * switch (_difficulty) {
    ContentDifficulty.easy => 0.04,
    ContentDifficulty.medium => 0.04,
    ContentDifficulty.hard => 0.04,
  };

  double get _maxSpeed => _heightScale * _adaptiveSpeed * switch (_difficulty) {
    ContentDifficulty.easy => 0.07,
    ContentDifficulty.medium => 0.07,
    ContentDifficulty.hard => 0.075,
  };

  int get _maxDemons => switch (_difficulty) {
    ContentDifficulty.easy => 4,
    ContentDifficulty.medium => 5,
    ContentDifficulty.hard => 7,
  };

  double get _damagePerHit => switch (_difficulty) {
    ContentDifficulty.easy => 0.10,
    ContentDifficulty.medium => 0.13,
    ContentDifficulty.hard => 0.18,
  };

  // Temple height as fraction of game area
  static const _templeHeightFrac = 0.22;

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
    _demons.clear();
    _ghosts.clear();
    _trishuls.clear();
    _input = '';
    _target = null;
    _score = 0;
    _templeHealth = 1.0;
    _adaptiveSpeed = 0.55;
    _demonsSlain = 0;
    _demonsReached = 0;
    _streak = 0;
    _bestStreak = 0;
    _isNewHighScore = false;
    _highScore = 0;
    _templeDamageFlash = false;
    _spawnTimer = _spawnInterval - 0.5;
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
    if (_spawnTimer >= _spawnInterval && _demons.length < _maxDemons) {
      _spawnDemon();
      _spawnTimer = 0;
    }

    // Move — demons stop at the temple line, not at y=1.0
    final templeY = 1.0 - _templeHeightFrac;
    for (final d in _demons) {
      d.y += d.speed * dt;
    }

    // Demons that reached the temple
    final reached = _demons.where((d) => d.y >= templeY).toList();
    for (final d in reached) {
      _addGhost(d.word, d.x, templeY - 0.02, false, d.colorIndex);
      _demons.remove(d);
      _demonsReached++;
      _streak = 0;
      _onMissAdaptive();
      _templeHealth = (_templeHealth - _damagePerHit).clamp(0.0, 1.0);
      _sfx.playMiss();
      _triggerTempleDamageFlash();
      if (_target == d) {
        _target = null;
        _input = '';
      }
      if (_templeHealth <= 0) {
        _endGame();
        return;
      }
    }

    setState(() {});
  }

  void _spawnDemon() {
    String word;
    int tries = 0;
    do {
      word = WordLists.randomWord(_difficulty);
      tries++;
    } while (_demons.any((d) => d.word == word) && tries < 10);

    _demons.add(
      _DemonWord(
        word: word,
        x: _random.nextDouble() * 0.70 + 0.05,
        y: -0.02,
        speed: _minSpeed + _random.nextDouble() * (_maxSpeed - _minSpeed),
        colorIndex: _random.nextInt(_demonColors.length),
      ),
    );
  }

  void _triggerTempleDamageFlash() {
    _templeDamageFlash = true;
    Future.delayed(const Duration(milliseconds: 350), () {
      if (mounted) setState(() => _templeDamageFlash = false);
    });
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

    if (_target != null && _input == _target!.word) {
      _slayDemon(_target!);
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
    if (_target != null &&
        _demons.contains(_target) &&
        _target!.word.startsWith(_input)) {
      return;
    }
    _target = null;
    double bestY = -1;
    for (final d in _demons) {
      if (d.word.startsWith(_input) && d.y > bestY) {
        bestY = d.y;
        _target = d;
      }
    }
  }

  void _slayDemon(_DemonWord demon) {
    // Launch trishul from temple toward the demon
    final trishul = _Trishul(targetX: demon.x, targetY: demon.y);
    _trishuls.add(trishul);

    // Freeze the demon in place (mark for removal after trishul arrives)
    final word = demon.word;
    final dx = demon.x;
    final dy = demon.y;
    final ci = demon.colorIndex;

    _score += demon.word.length * 10;
    _demonsSlain++;
    _streak++;
    _onCorrectAdaptive();
    if (_streak > _bestStreak) _bestStreak = _streak;
    _input = '';
    _target = null;

    // After trishul reaches target, remove demon and show ghost
    Timer(_Trishul.duration, () {
      if (!mounted) return;
      _demons.remove(demon);
      _trishuls.remove(trishul);
      _addGhost(word, dx, dy, true, ci);
      setState(() {});
    });
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
    _gameDuration =
        _gameStart != null ? DateTime.now().difference(_gameStart!) : Duration.zero;
    _sfx.playGameOver();
    final progress = Provider.of<ProgressProvider>(context, listen: false);
    _highScore = progress.getHighScore('defend_temple');
    progress.recordScore('defend_temple', _score).then((isNew) {
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
        onResume: () {
          Navigator.of(ctx).pop();
          if (_phase == _Phase.playing && mounted) {
            _lastTick = Duration.zero;
            _ticker.start();
          }
        },
        onQuit: () {
          Navigator.of(ctx).pop();
          context.pop();
        },
      ),
    ).then((_) {
      if (_phase == _Phase.playing && mounted) {
        _gameFocusNode.requestFocus();
      }
    });
  }

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
      backgroundColor: _bgTop,
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
                                _keyBadge('Esc', Colors.white70),
                              ],
                            ),
                            style: TextButton.styleFrom(
                              foregroundColor: Colors.white70,
                            ),
                          ),
                        ),
                        SizedBox(height: isTall ? 12 : 6),
                        // Header
                        Text('🏯', style: TextStyle(fontSize: emojiSize)),
                        SizedBox(height: isTall ? 8 : 4),
                        Text(
                          'Defend the Temple',
                          style: GoogleFonts.fredoka(
                            fontSize: headerFontSize,
                            fontWeight: FontWeight.w700,
                            color: const Color(0xFFFF6B6B),
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Demons are attacking! Type to destroy them\nbefore they reach your temple!',
                          style: GoogleFonts.nunito(
                            fontSize: isWide ? 16.0 : 14.0,
                            color: Colors.white60,
                          ),
                          textAlign: TextAlign.center,
                        ),
                        SizedBox(height: sectionGap),
                        // Difficulty
                        Text(
                          'Choose Difficulty',
                          style: GoogleFonts.fredoka(
                            fontSize: 18,
                            fontWeight: FontWeight.w600,
                            color: Colors.white70,
                          ),
                        ),
                        SizedBox(height: isTall ? 12 : 8),
                        Row(
                          children: ContentDifficulty.values
                              .asMap()
                              .entries
                              .map((e) {
                            return Expanded(
                              child: Padding(
                                padding: EdgeInsets.symmetric(
                                  horizontal: isWide ? 6 : 4,
                                ),
                                child: _DifficultyCard(
                                  difficulty: e.value,
                                  index: e.key + 1,
                                  selected: _difficulty == e.value,
                                  compact: !isTall,
                                  dark: true,
                                  onTap: () =>
                                      setState(() => _difficulty = e.value),
                                ),
                              ),
                            );
                          }).toList(),
                        ),
                        SizedBox(height: sectionGap),
                        // Start
                        SizedBox(
                          width: double.infinity,
                          height: 56,
                          child: ElevatedButton(
                            onPressed: _startGame,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFFB22222),
                              foregroundColor: Colors.white,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(16),
                              ),
                            ),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                const Text('⚔️',
                                    style: TextStyle(fontSize: 22)),
                                const SizedBox(width: 8),
                                Text(
                                  'Defend!',
                                  style: GoogleFonts.fredoka(fontSize: 22),
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
      backgroundColor: _bgTop,
      body: KeyboardListener(
        focusNode: _gameFocusNode,
        autofocus: true,
        onKeyEvent: _handleGameKey,
        child: GestureDetector(
          onTap: () => _gameFocusNode.requestFocus(),
          child: SafeArea(
            child: Column(
              children: [
                _buildTopBar(),
                _buildInputArea(),
                Expanded(child: _buildGameArea()),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildTopBar() {
    // Health bar color
    final healthColor = _templeHealth > 0.5
        ? const Color(0xFF66BB6A)
        : _templeHealth > 0.25
        ? const Color(0xFFFFA726)
        : const Color(0xFFEF5350);

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      decoration: BoxDecoration(
        color: Colors.black38,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.white12),
      ),
      child: Row(
        children: [
          // Close
          InkWell(
            onTap: _showQuitDialog,
            borderRadius: BorderRadius.circular(8),
            child: const Padding(
              padding: EdgeInsets.all(4),
              child: Icon(Icons.close_rounded, size: 22, color: Colors.white54),
            ),
          ),
          const SizedBox(width: 8),
          // Score
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
          const SizedBox(width: 16),
          // Temple health bar
          const Text('🏯', style: TextStyle(fontSize: 16)),
          const SizedBox(width: 6),
          Expanded(
            child: Container(
              height: 14,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(7),
                color: Colors.black38,
                border: Border.all(color: Colors.white24),
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(6),
                child: AnimatedFractionallySizedBox(
                  duration: const Duration(milliseconds: 300),
                  alignment: Alignment.centerLeft,
                  widthFactor: _templeHealth,
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 300),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [healthColor, healthColor.withValues(alpha: 0.7)],
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(width: 12),
          // Streak
          if (_streak > 1) ...[
            const Text('⚔️', style: TextStyle(fontSize: 16)),
            const SizedBox(width: 2),
            Text(
              '$_streak',
              style: GoogleFonts.fredoka(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: const Color(0xFFFF6B6B),
              ),
            ),
            const SizedBox(width: 12),
          ],
          // Difficulty
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
            decoration: BoxDecoration(
              color: const Color(0xFFB22222).withValues(alpha: 0.2),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(
              '${_difficulty.emoji} ${_difficulty.label}',
              style: GoogleFonts.nunito(
                fontSize: 12,
                fontWeight: FontWeight.w700,
                color: const Color(0xFFFF6B6B),
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
        _gameAreaHeight = areaH;

        final templeHeight = areaH * _templeHeightFrac;

        return Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [_bgTop, _bgMid, _bgBottom],
              stops: [0.0, 0.5, 1.0],
            ),
          ),
          child: Stack(
            clipBehavior: Clip.hardEdge,
            children: [
              // Sky background elements
              ..._buildSkyBackground(areaW, areaH),
              // Temple at bottom
              Positioned(
                left: 0,
                right: 0,
                bottom: 0,
                height: templeHeight,
                child: _buildTemple(templeHeight),
              ),
              // Demons
              for (final d in _demons)
                _buildDemonWidget(d, areaW, areaH),
              // Trishul projectiles
              for (final t in _trishuls)
                _buildTrishul(t, areaW, areaH),
              // Ghost indicators
              for (final g in _ghosts)
                _buildGhostIndicator(g, areaW, areaH),
              // Empty hint
              if (_demons.isEmpty && _ghosts.isEmpty)
                Center(
                  child: Text(
                    'Demons approaching...',
                    style: GoogleFonts.fredoka(
                      fontSize: 24,
                      color: Colors.white24,
                    ),
                  ),
                ),
            ],
          ),
        );
      },
    );
  }

  List<Widget> _buildSkyBackground(double w, double h) {
    final rng = Random(42);
    final widgets = <Widget>[];

    // ── Distant mountains silhouette ──
    widgets.add(
      Positioned(
        left: 0,
        right: 0,
        bottom: h * _templeHeightFrac - 2,
        height: h * 0.18,
        child: CustomPaint(
          size: Size(w, h * 0.18),
          painter: _MountainPainter(),
        ),
      ),
    );

    // ── Moon ──
    widgets.add(
      Positioned(
        right: w * 0.12,
        top: h * 0.06,
        child: Container(
          width: 32,
          height: 32,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: const Color(0xFFFFF8E1).withValues(alpha: 0.85),
            boxShadow: [
              BoxShadow(
                color: const Color(0xFFFFF8E1).withValues(alpha: 0.2),
                blurRadius: 30,
                spreadRadius: 10,
              ),
              BoxShadow(
                color: const Color(0xFFFFD54F).withValues(alpha: 0.08),
                blurRadius: 60,
                spreadRadius: 25,
              ),
            ],
          ),
        ),
      ),
    );
    // Moon crater shadow (crescent effect)
    widgets.add(
      Positioned(
        right: w * 0.12 + 6,
        top: h * 0.06 - 2,
        child: Container(
          width: 28,
          height: 28,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: _bgTop,
          ),
        ),
      ),
    );

    // ── Stars — lots of them with varying sizes and brightness ──
    for (var i = 0; i < 50; i++) {
      final x = rng.nextDouble() * w;
      final y = rng.nextDouble() * (h * 0.65);
      final size = rng.nextDouble() * 2.5 + 0.5;
      final brightness = rng.nextDouble() * 0.6 + 0.15;
      final isBright = i < 8; // first 8 are brighter "feature" stars

      widgets.add(
        Positioned(
          left: x,
          top: y,
          child: Container(
            width: isBright ? size + 1.5 : size,
            height: isBright ? size + 1.5 : size,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: isBright
                  ? const Color(0xFFFFF8E1).withValues(alpha: brightness + 0.2)
                  : Colors.white.withValues(alpha: brightness),
              boxShadow: isBright
                  ? [
                      BoxShadow(
                        color: const Color(0xFFBBDEFB).withValues(alpha: 0.3),
                        blurRadius: 4,
                        spreadRadius: 1,
                      ),
                    ]
                  : null,
            ),
          ),
        ),
      );
    }

    // ── Fog / mist layer above the temple ──
    widgets.add(
      Positioned(
        left: 0,
        right: 0,
        bottom: h * _templeHeightFrac - 6,
        height: h * 0.08,
        child: IgnorePointer(
          child: Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  Colors.transparent,
                  const Color(0xFF1E1250).withValues(alpha: 0.4),
                  const Color(0xFF2A1860).withValues(alpha: 0.2),
                ],
              ),
            ),
          ),
        ),
      ),
    );

    return widgets;
  }

  Widget _buildTemple(double height) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      decoration: BoxDecoration(
        border: Border(
          top: BorderSide(
            color: _templeDamageFlash
                ? const Color(0xFFFF5252)
                : const Color(0xFFFFD700).withValues(alpha: 0.6),
            width: 2,
          ),
        ),
      ),
      child: CustomPaint(
        size: Size(double.infinity, height),
        painter: _PagodaPainter(damageFlash: _templeDamageFlash),
      ),
    );
  }

  // Responsive font scale
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

  Widget _buildDemonWidget(
      _DemonWord demon, double areaW, double areaH) {
    final isTarget = demon == _target;
    final color = _demonColors[demon.colorIndex];
    final fontSize = _wordFontSize;

    final estWidth = demon.word.length * (fontSize * 0.7) + 60;
    final maxLeft = (areaW - estWidth).clamp(0.0, double.infinity);
    final left = (demon.x * areaW).clamp(0.0, maxLeft);
    final top = demon.y * areaH;

    return Positioned(
      left: left,
      top: top,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Word (above the demon)
          AnimatedContainer(
            duration: const Duration(milliseconds: 120),
            padding: EdgeInsets.symmetric(
              horizontal: fontSize * 0.6,
              vertical: fontSize * 0.3,
            ),
            decoration: BoxDecoration(
              color: isTarget ? color : color.withValues(alpha: 0.8),
              borderRadius: BorderRadius.circular(10),
              border: isTarget
                  ? Border.all(
                      color: _input.isEmpty
                          ? const Color(0xFFFFD700)
                          : demon.word.startsWith(_input)
                          ? const Color(0xFF00E676)
                          : const Color(0xFFFF5252),
                      width: 2.5,
                    )
                  : (_input.isNotEmpty && _target == null)
                  ? Border.all(
                      color: const Color(0xFFFF5252).withValues(alpha: 0.6),
                      width: 2,
                    )
                  : Border.all(
                      color: Colors.white.withValues(alpha: 0.2),
                      width: 1,
                    ),
              boxShadow: [
                BoxShadow(
                  color: isTarget
                      ? (_input.isEmpty
                              ? const Color(0xFFFFD700)
                              : demon.word.startsWith(_input)
                              ? const Color(0xFF00E676)
                              : const Color(0xFFFF5252))
                          .withValues(alpha: 0.5)
                      : color.withValues(alpha: 0.4),
                  blurRadius: isTarget ? 14 : 6,
                  spreadRadius: isTarget ? 2 : 0,
                ),
              ],
            ),
            child: isTarget && _input.isNotEmpty
                ? _buildPartialMatch(demon.word, _input, fontSize)
                : Text(
                    demon.word,
                    style: GoogleFonts.fredoka(
                      fontSize: fontSize,
                      fontWeight: FontWeight.w600,
                      color: Colors.white,
                    ),
                  ),
          ),
          const SizedBox(height: 2),
          // Demon emoji (below the word)
          Text(
            '👹',
            style: TextStyle(
              fontSize: fontSize * 2.5,
              shadows: [
                Shadow(
                  color: color.withValues(alpha: 0.8),
                  blurRadius: 10,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTrishul(_Trishul t, double areaW, double areaH) {
    final startX = areaW / 2;
    final startY = areaH * (1.0 - _templeHeightFrac * 0.3);
    final endX = t.targetX * areaW;
    // Offset down to hit the demon emoji (below the word label)
    final demonOffset = _wordFontSize * 2.2;
    final endY = t.targetY * areaH + demonOffset;

    // Angle from start to end so the trishul points at the demon
    final dx = endX - startX;
    final dy = endY - startY;
    final angle = atan2(dy, dx) + pi / 2; // +90 deg because 🔱 points up

    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0.0, end: 1.0),
      duration: _Trishul.duration,
      builder: (context, p, child) {
        final eased = 1.0 - (1.0 - p) * (1.0 - p);
        final cx = startX + (endX - startX) * eased;
        final cy = startY + (endY - startY) * eased;

        return Positioned(
          left: cx - 18,
          top: cy - 18,
          child: Opacity(
            opacity: p < 0.85 ? 1.0 : ((1.0 - p) / 0.15).clamp(0.0, 1.0),
            child: Transform.rotate(
              angle: angle,
              child: const Text('🔱', style: TextStyle(fontSize: 36)),
            ),
          ),
        );
      },
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
                  color: Colors.black.withValues(alpha: 0.4),
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
    final estWidth = ghost.word.length * (fontSize * 0.7) + 60;
    final maxLeft = (areaW - estWidth).clamp(0.0, double.infinity);
    final left = (ghost.x * areaW).clamp(0.0, maxLeft);
    final top = ghost.y * areaH;

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
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              ghost.success ? '💥' : '💀',
              style: TextStyle(fontSize: fontSize * 0.9),
            ),
            const SizedBox(width: 4),
            Text(
              ghost.word,
              style: GoogleFonts.fredoka(
                fontSize: fontSize * 0.85,
                fontWeight: FontWeight.w600,
                color: ghost.success
                    ? const Color(0xFF00E676)
                    : const Color(0xFFFF5252),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInputArea() {
    final hasMatch = _target != null;
    final hasInput = _input.isNotEmpty;
    final noMatch = hasInput && !hasMatch;
    final fontSize = _inputFontSize;

    Color bgColor = Colors.black38;
    Color borderColor = noMatch
        ? AppColors.incorrect.withValues(alpha: 0.6)
        : hasMatch
        ? const Color(0xFF00E676).withValues(alpha: 0.6)
        : Colors.white24;

    if (_flash == _FlashType.correct) {
      bgColor = const Color(0xFF00E676).withValues(alpha: 0.15);
      borderColor = const Color(0xFF00E676);
    } else if (_flash == _FlashType.wrong) {
      bgColor = const Color(0xFFFF5252).withValues(alpha: 0.15);
      borderColor = const Color(0xFFFF5252);
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
                ? const Color(0xFF00E676)
                : _flash == _FlashType.wrong
                ? const Color(0xFFFF5252)
                : hasInput
                ? const Color(0xFFFFD700)
                : Colors.white38,
            size: fontSize,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              _flash == _FlashType.correct
                  ? '💥 Slain!'
                  : _flash == _FlashType.wrong
                  ? '✗ No match'
                  : hasInput
                  ? _input
                  : 'Type to attack...',
              style: GoogleFonts.fredoka(
                fontSize: fontSize,
                fontWeight: FontWeight.w500,
                color: _flash == _FlashType.correct
                    ? const Color(0xFF00E676)
                    : _flash == _FlashType.wrong
                    ? const Color(0xFFFF5252)
                    : noMatch
                    ? const Color(0xFFFF5252)
                    : hasInput
                    ? Colors.white
                    : Colors.white38,
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
                  color: const Color(0xFFFF5252).withValues(alpha: 0.6),
                ),
              ),
            const SizedBox(width: 6),
            Text(
              '⌫',
              style: TextStyle(fontSize: fontSize * 0.8, color: Colors.white38),
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
      backgroundColor: _bgTop,
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
                        Text('💀', style: TextStyle(fontSize: emojiSize)),
                        SizedBox(height: isTall ? 8 : 4),
                        Text(
                          'Temple Fallen!',
                          style: GoogleFonts.fredoka(
                            fontSize: headerFontSize,
                            fontWeight: FontWeight.w700,
                            color: const Color(0xFFFF6B6B),
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
                                const Color(0xFFB22222).withValues(alpha: 0.15),
                              ],
                            ),
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(
                              color: AppColors.starFilled.withValues(alpha: 0.4),
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
                                      color: const Color(0xFFFFD700),
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
                                  color: Colors.white60,
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
                                      color: Colors.white54,
                                    ),
                                  ),
                                ),
                            ],
                          ),
                        ),
                        SizedBox(height: sectionGap),
                        // Stats
                        Row(
                          children: [
                            _OverStat(
                              emoji: '💥',
                              label: 'Slain',
                              value: '$_demonsSlain',
                            ),
                            const SizedBox(width: 12),
                            _OverStat(
                              emoji: '💀',
                              label: 'Reached',
                              value: '$_demonsReached',
                            ),
                          ],
                        ),
                        SizedBox(height: statGap),
                        Row(
                          children: [
                            _OverStat(
                              emoji: '⚔️',
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
                              backgroundColor: const Color(0xFFB22222),
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
                                  'Defend Again',
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
                              _keyBadge('Esc', Colors.white70),
                            ],
                          ),
                          style: TextButton.styleFrom(
                            foregroundColor: Colors.white70,
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
// Pagoda painter
// ─────────────────────────────────────────────────────────────────────────────

class _MountainPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;

    // Far mountains (lighter, behind)
    final farPaint = Paint()..color = const Color(0xFF0D0825);
    final far = Path()
      ..moveTo(0, h)
      ..lineTo(0, h * 0.7)
      ..lineTo(w * 0.10, h * 0.35)
      ..lineTo(w * 0.22, h * 0.55)
      ..lineTo(w * 0.35, h * 0.20)
      ..lineTo(w * 0.48, h * 0.50)
      ..lineTo(w * 0.55, h * 0.30)
      ..lineTo(w * 0.65, h * 0.15)
      ..lineTo(w * 0.75, h * 0.45)
      ..lineTo(w * 0.85, h * 0.25)
      ..lineTo(w * 0.95, h * 0.50)
      ..lineTo(w, h * 0.60)
      ..lineTo(w, h)
      ..close();
    canvas.drawPath(far, farPaint);

    // Near mountains (darker, in front)
    final nearPaint = Paint()..color = const Color(0xFF0A0620);
    final near = Path()
      ..moveTo(0, h)
      ..lineTo(0, h * 0.65)
      ..lineTo(w * 0.08, h * 0.50)
      ..lineTo(w * 0.18, h * 0.70)
      ..lineTo(w * 0.30, h * 0.40)
      ..lineTo(w * 0.42, h * 0.65)
      ..lineTo(w * 0.52, h * 0.45)
      ..lineTo(w * 0.60, h * 0.60)
      ..lineTo(w * 0.72, h * 0.35)
      ..lineTo(w * 0.82, h * 0.55)
      ..lineTo(w * 0.92, h * 0.40)
      ..lineTo(w, h * 0.55)
      ..lineTo(w, h)
      ..close();
    canvas.drawPath(near, nearPaint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter old) => false;
}

class _PagodaPainter extends CustomPainter {
  final bool damageFlash;

  _PagodaPainter({this.damageFlash = false});

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;
    final cx = w / 2;

    // ── Palette ──
    final wallColor =
        damageFlash ? const Color(0xFF8B2020) : const Color(0xFF5C3A1E);
    final roofColor =
        damageFlash ? const Color(0xFFCC2020) : const Color(0xFF8B1A1A);
    final roofAccent =
        damageFlash ? const Color(0xFFFF4444) : const Color(0xFFD4AF37);
    final grassDark = const Color(0xFF1B4332);
    final grassLight = const Color(0xFF2D6A4F);
    final treeTrunk = const Color(0xFF3E2723);
    final treeLeaf = const Color(0xFF1B5E20);
    final treeLeafLight = const Color(0xFF2E7D32);
    final stoneColor = const Color(0xFF37474F);
    final lanternGlow =
        damageFlash ? const Color(0xFFFF4444) : const Color(0xFFFFAB00);

    // ── Ground ──
    // Dark earth base
    canvas.drawRect(
      Rect.fromLTWH(0, h * 0.78, w, h * 0.22),
      Paint()..color = const Color(0xFF1A0F05),
    );
    // Grass layer
    canvas.drawRect(
      Rect.fromLTWH(0, h * 0.75, w, h * 0.08),
      Paint()..color = grassDark,
    );
    // Grass highlights — small bumps across the width
    final grassPath = Path()..moveTo(0, h * 0.76);
    for (var x = 0.0; x < w; x += 8) {
      grassPath.lineTo(x + 4, h * 0.73);
      grassPath.lineTo(x + 8, h * 0.76);
    }
    grassPath.lineTo(w, h * 0.78);
    grassPath.lineTo(0, h * 0.78);
    grassPath.close();
    canvas.drawPath(grassPath, Paint()..color = grassLight);

    // ── Stone path to temple ──
    final pathW = w * 0.08;
    for (var i = 0; i < 4; i++) {
      final sy = h * 0.80 + i * h * 0.05;
      canvas.drawRRect(
        RRect.fromRectAndRadius(
          Rect.fromLTWH(cx - pathW / 2, sy, pathW, h * 0.03),
          const Radius.circular(3),
        ),
        Paint()..color = stoneColor.withValues(alpha: 0.6 - i * 0.1),
      );
    }

    // ── Trees ── (left and right sides)
    void drawTree(double tx, double scale) {
      final trunkW = 6.0 * scale;
      final trunkH = h * 0.25 * scale;
      final trunkTop = h * 0.75 - trunkH;

      // Trunk
      canvas.drawRRect(
        RRect.fromRectAndRadius(
          Rect.fromLTWH(tx - trunkW / 2, trunkTop, trunkW, trunkH),
          const Radius.circular(2),
        ),
        Paint()..color = treeTrunk,
      );

      // Foliage layers (3 triangles)
      for (var i = 0; i < 3; i++) {
        final layerW = (28.0 - i * 6) * scale;
        final layerH = (18.0 - i * 2) * scale;
        final layerY = trunkTop - i * layerH * 0.6;
        final p = Path()
          ..moveTo(tx - layerW / 2, layerY)
          ..lineTo(tx, layerY - layerH)
          ..lineTo(tx + layerW / 2, layerY)
          ..close();
        canvas.drawPath(p, Paint()..color = i.isEven ? treeLeaf : treeLeafLight);
      }
    }

    // Left trees
    drawTree(w * 0.06, 0.8);
    drawTree(w * 0.15, 1.0);
    drawTree(w * 0.24, 0.7);
    // Right trees
    drawTree(w * 0.76, 0.7);
    drawTree(w * 0.85, 1.0);
    drawTree(w * 0.94, 0.8);

    // ── Side shrines ── (small pagodas on left and right)
    void drawShrine(double sx) {
      final sw = w * 0.08;
      final sh = h * 0.25;
      final sTop = h * 0.75 - sh;

      // Body
      canvas.drawRect(
        Rect.fromLTWH(sx - sw / 2, sTop + sh * 0.4, sw, sh * 0.6),
        Paint()..color = wallColor.withValues(alpha: 0.8),
      );
      // Door
      canvas.drawRRect(
        RRect.fromRectAndCorners(
          Rect.fromLTWH(sx - sw * 0.15, sTop + sh * 0.6, sw * 0.3, sh * 0.4),
          topLeft: const Radius.circular(6),
          topRight: const Radius.circular(6),
        ),
        Paint()..color = const Color(0xFF0A0505),
      );
      // Roof
      final rp = Path()
        ..moveTo(sx - sw * 0.7, sTop + sh * 0.4)
        ..lineTo(sx, sTop + sh * 0.15)
        ..lineTo(sx + sw * 0.7, sTop + sh * 0.4)
        ..close();
      canvas.drawPath(rp, Paint()..color = roofColor);
      canvas.drawPath(
        rp,
        Paint()
          ..color = roofAccent
          ..style = PaintingStyle.stroke
          ..strokeWidth = 1,
      );
    }

    drawShrine(w * 0.30);
    drawShrine(w * 0.70);

    // ── Lanterns ── (stone posts with glowing tops)
    void drawLantern(double lx) {
      final postH = h * 0.12;
      final postTop = h * 0.75 - postH;
      // Post
      canvas.drawRect(
        Rect.fromLTWH(lx - 2, postTop, 4, postH),
        Paint()..color = stoneColor,
      );
      // Glow
      canvas.drawCircle(
        Offset(lx, postTop - 2),
        5,
        Paint()..color = lanternGlow.withValues(alpha: 0.7),
      );
      canvas.drawCircle(
        Offset(lx, postTop - 2),
        10,
        Paint()
          ..color = lanternGlow.withValues(alpha: 0.15)
          ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 6),
      );
    }

    drawLantern(w * 0.38);
    drawLantern(w * 0.62);

    // ── Main Pagoda Temple (center) ──
    final bodyW = w * 0.22;
    final bodyH = h * 0.35;
    final bodyTop = h * 0.75 - bodyH;
    final bodyL = cx - bodyW / 2;

    // Temple body
    canvas.drawRect(
      Rect.fromLTWH(bodyL, bodyTop + bodyH * 0.35, bodyW, bodyH * 0.65),
      Paint()..color = wallColor,
    );

    // Pillars
    final pillarW = bodyW * 0.06;
    for (final px in [bodyL + bodyW * 0.15, bodyL + bodyW * 0.85 - pillarW]) {
      canvas.drawRect(
        Rect.fromLTWH(px, bodyTop + bodyH * 0.38, pillarW, bodyH * 0.6),
        Paint()..color = roofAccent.withValues(alpha: 0.4),
      );
    }

    // Door
    final doorW = bodyW * 0.25;
    final doorH = bodyH * 0.35;
    canvas.drawRRect(
      RRect.fromRectAndCorners(
        Rect.fromLTWH(cx - doorW / 2, bodyTop + bodyH - doorH, doorW, doorH),
        topLeft: const Radius.circular(10),
        topRight: const Radius.circular(10),
      ),
      Paint()..color = const Color(0xFF0A0505),
    );
    // Door glow
    canvas.drawRRect(
      RRect.fromRectAndCorners(
        Rect.fromLTWH(cx - doorW / 2, bodyTop + bodyH - doorH, doorW, doorH),
        topLeft: const Radius.circular(10),
        topRight: const Radius.circular(10),
      ),
      Paint()
        ..color = lanternGlow.withValues(alpha: 0.08)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 4),
    );

    // Roof tiers (3 levels)
    for (var i = 0; i < 3; i++) {
      final tierScale = 1.0 - i * 0.25;
      final tierW = (bodyW + 30) * tierScale;
      final tierH = bodyH * 0.1;
      final tierY = bodyTop + bodyH * 0.32 - i * tierH * 1.4;

      final path = Path()
        ..moveTo(cx - tierW / 2 - 8, tierY + tierH)
        ..quadraticBezierTo(cx - tierW / 2 - 14, tierY + tierH - 4,
            cx - tierW * 0.35, tierY)
        ..lineTo(cx + tierW * 0.35, tierY)
        ..quadraticBezierTo(
            cx + tierW / 2 + 14, tierY + tierH - 4,
            cx + tierW / 2 + 8, tierY + tierH)
        ..close();
      canvas.drawPath(path, Paint()..color = roofColor);
      canvas.drawPath(
        path,
        Paint()
          ..color = roofAccent
          ..style = PaintingStyle.stroke
          ..strokeWidth = 1.2,
      );
    }

    // Spire
    final spireBase = bodyTop + bodyH * 0.32 - 3 * (bodyH * 0.1) * 1.4;
    final spireTop = spireBase - h * 0.06;
    canvas.drawLine(
      Offset(cx, spireTop),
      Offset(cx, spireBase + 4),
      Paint()
        ..color = roofAccent
        ..strokeWidth = 2.5,
    );
    canvas.drawCircle(
      Offset(cx, spireTop),
      4,
      Paint()..color = roofAccent,
    );
    // Spire glow
    canvas.drawCircle(
      Offset(cx, spireTop),
      8,
      Paint()
        ..color = lanternGlow.withValues(alpha: 0.15)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 6),
    );
  }

  @override
  bool shouldRepaint(covariant _PagodaPainter old) =>
      damageFlash != old.damageFlash;
}

// ─────────────────────────────────────────────────────────────────────────────
// Extracted widgets
// ─────────────────────────────────────────────────────────────────────────────

class _DifficultyCard extends StatelessWidget {
  final ContentDifficulty difficulty;
  final int index;
  final bool selected;
  final bool compact;
  final bool dark;
  final VoidCallback onTap;

  const _DifficultyCard({
    required this.difficulty,
    required this.index,
    required this.selected,
    this.compact = false,
    this.dark = false,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final vPad = compact ? 8.0 : 14.0;
    final emojiSize = compact ? 22.0 : 28.0;
    final labelSize = compact ? 14.0 : 16.0;
    final descSize = compact ? 10.0 : 11.0;

    final accentColor = const Color(0xFFB22222);

    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 160),
        padding: EdgeInsets.symmetric(vertical: vPad, horizontal: 8),
        decoration: BoxDecoration(
          color: selected
              ? accentColor.withValues(alpha: 0.2)
              : dark
              ? Colors.white.withValues(alpha: 0.05)
              : Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: selected ? accentColor : Colors.white24,
            width: selected ? 2.5 : 1,
          ),
          boxShadow: selected
              ? [
                  BoxShadow(
                    color: accentColor.withValues(alpha: 0.25),
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
                color: selected ? accentColor : Colors.white70,
              ),
            ),
            if (!compact) ...[
              const SizedBox(height: 2),
              Text(
                difficulty.description,
                style: GoogleFonts.nunito(
                  fontSize: descSize,
                  color: Colors.white38,
                ),
                textAlign: TextAlign.center,
              ),
            ],
            SizedBox(height: compact ? 3 : 6),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
              decoration: BoxDecoration(
                color: accentColor.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(4),
                border: Border.all(color: accentColor.withValues(alpha: 0.3)),
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
          color: Colors.white.withValues(alpha: 0.05),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: Colors.white12),
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
                color: Colors.white,
              ),
            ),
            Text(
              label,
              style: GoogleFonts.nunito(
                fontSize: 12,
                color: Colors.white54,
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
        backgroundColor: const Color(0xFF1A1040),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text(
          'Abandon Temple?',
          style: GoogleFonts.fredoka(fontSize: 24, color: Colors.white),
        ),
        content: Text(
          'The demons will overrun the temple if you leave!',
          style: GoogleFonts.nunito(fontSize: 16, color: Colors.white70),
        ),
        actions: [
          TextButton(
            onPressed: widget.onResume,
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  'Stay & Fight',
                  style: GoogleFonts.fredoka(color: const Color(0xFF66BB6A)),
                ),
                _badge('Esc', const Color(0xFF66BB6A)),
              ],
            ),
          ),
          TextButton(
            onPressed: widget.onQuit,
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  'Retreat',
                  style: GoogleFonts.fredoka(color: const Color(0xFFFF6B6B)),
                ),
                _badge('Q', const Color(0xFFFF6B6B)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
