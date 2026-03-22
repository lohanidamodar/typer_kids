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
import '../../data/word_meanings.dart';
import '../../providers/progress_provider.dart';

// ─────────────────────────────────────────────────────────────────────────────
// Data
// ─────────────────────────────────────────────────────────────────────────────

enum _Phase { setup, playing, gameOver }

/// Represents one scrambled word challenge.
class _WordChallenge {
  final WordMeaning wordMeaning;
  final String scrambled;

  _WordChallenge({required this.wordMeaning, required this.scrambled});
}

// ─────────────────────────────────────────────────────────────────────────────
// Screen
// ─────────────────────────────────────────────────────────────────────────────

class WordBuilderScreen extends StatefulWidget {
  const WordBuilderScreen({super.key});

  @override
  State<WordBuilderScreen> createState() => _WordBuilderScreenState();
}

class _WordBuilderScreenState extends State<WordBuilderScreen>
    with TickerProviderStateMixin {
  // ── State ──
  _Phase _phase = _Phase.setup;
  ContentDifficulty _difficulty = ContentDifficulty.easy;

  _WordChallenge? _currentChallenge;
  String _input = '';
  int _score = 0;
  int _streak = 0;
  int _bestStreak = 0;
  int _errors = 0;
  int _wordsCompleted = 0;
  bool _isNewHighScore = false;
  int _highScore = 0;
  final Set<String> _usedWords = {};

  // Timer
  Timer? _gameTimer;
  int _remainingSeconds = 0;

  // Hint
  bool _hintUsed = false;
  String _hintText = '';

  // Animations
  AnimationController? _shakeController;
  AnimationController? _bounceController;
  Animation<double>? _shakeAnimation;
  Animation<double>? _bounceAnimation;

  // Focus
  final _setupFocusNode = FocusNode();
  final _gameFocusNode = FocusNode();
  final _overFocusNode = FocusNode();

  final _sfx = SoundManager();
  final _random = Random();

  // ── Difficulty Config ──

  int get _gameDuration => switch (_difficulty) {
    ContentDifficulty.easy => 90,
    ContentDifficulty.medium => 120,
    ContentDifficulty.hard => 150,
  };

  int get _hintPenalty => switch (_difficulty) {
    ContentDifficulty.easy => 0,
    ContentDifficulty.medium => 1,
    ContentDifficulty.hard => 2,
  };

  int get _scorePerWord => switch (_difficulty) {
    ContentDifficulty.easy => 10,
    ContentDifficulty.medium => 15,
    ContentDifficulty.hard => 20,
  };

  // ── Lifecycle ──

  @override
  void initState() {
    super.initState();
    _shakeController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 400),
    );
    _shakeAnimation = Tween<double>(begin: 0, end: 8).animate(
      CurvedAnimation(parent: _shakeController!, curve: Curves.elasticIn),
    );

    _bounceController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 500),
    );
    _bounceAnimation = Tween<double>(begin: 1.0, end: 1.15).animate(
      CurvedAnimation(parent: _bounceController!, curve: Curves.elasticOut),
    );
  }

  @override
  void dispose() {
    _gameTimer?.cancel();
    _setupFocusNode.dispose();
    _gameFocusNode.dispose();
    _overFocusNode.dispose();
    _shakeController?.dispose();
    _bounceController?.dispose();
    super.dispose();
  }

  // ── Game Logic ──

  void _startGame() {
    final progress = context.read<ProgressProvider>();
    _highScore = progress.getHighScore('word-builder-${_difficulty.name}');

    setState(() {
      _phase = _Phase.playing;
      _score = 0;
      _streak = 0;
      _bestStreak = 0;
      _errors = 0;
      _wordsCompleted = 0;
      _isNewHighScore = false;
      _input = '';
      _usedWords.clear();
      _remainingSeconds = _gameDuration;
      _hintUsed = false;
      _hintText = '';
    });

    _nextWord();
    _startTimer();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      _gameFocusNode.requestFocus();
    });

    _sfx.playGameStart();
  }

  void _nextWord() {
    final wm = WordMeanings.randomWord(_difficulty, exclude: _usedWords);
    _usedWords.add(wm.word);
    // Keep used words manageable
    if (_usedWords.length > 30) {
      _usedWords.clear();
    }

    setState(() {
      _currentChallenge = _WordChallenge(
        wordMeaning: wm,
        scrambled: _scramble(wm.word),
      );
      _input = '';
      _hintUsed = false;
      _hintText = '';
    });
  }

  String _scramble(String word) {
    final chars = word.split('');
    // Shuffle until it's different from the original
    for (var attempt = 0; attempt < 20; attempt++) {
      chars.shuffle(_random);
      if (chars.join() != word) break;
    }
    return chars.join();
  }

  void _useHint() {
    if (_hintUsed || _currentChallenge == null) return;
    final word = _currentChallenge!.wordMeaning.word;

    // Reveal first letter that hasn't been typed yet
    final revealCount = _input.length + 1;
    if (revealCount <= word.length) {
      setState(() {
        _hintUsed = true;
        _hintText = 'Starts with "${word.substring(0, revealCount).toUpperCase()}"';
        // Apply hint penalty
        _score = (_score - _hintPenalty).clamp(0, 999999);
      });
    }
  }

  void _startTimer() {
    _gameTimer?.cancel();
    _gameTimer = Timer.periodic(const Duration(seconds: 1), (_) {
      setState(() {
        _remainingSeconds--;
        if (_remainingSeconds <= 0) {
          _endGame();
        }
      });
    });
  }

  void _endGame() {
    _gameTimer?.cancel();
    _sfx.playGameOver();

    final progress = context.read<ProgressProvider>();
    progress
        .recordScore('word-builder-${_difficulty.name}', _score)
        .then((isNew) {
      if (isNew && mounted) {
        setState(() => _isNewHighScore = true);
      }
    });

    setState(() {
      _phase = _Phase.gameOver;
    });

    WidgetsBinding.instance.addPostFrameCallback((_) {
      _overFocusNode.requestFocus();
    });
  }

  void _handleGameKey(KeyEvent event) {
    if (event is! KeyDownEvent) return;
    final key = event.logicalKey;

    if (key == LogicalKeyboardKey.escape) {
      _gameTimer?.cancel();
      context.pop();
      return;
    }

    if (key == LogicalKeyboardKey.tab) {
      _useHint();
      return;
    }

    if (_currentChallenge == null) return;
    final word = _currentChallenge!.wordMeaning.word;

    // Handle backspace
    if (key == LogicalKeyboardKey.backspace) {
      if (_input.isNotEmpty) {
        setState(() => _input = _input.substring(0, _input.length - 1));
      }
      return;
    }

    // Handle letter input
    final char = event.character;
    if (char == null || char.length != 1 || !RegExp(r'[a-zA-Z]').hasMatch(char)) {
      return;
    }

    final lower = char.toLowerCase();
    final newInput = _input + lower;

    // Check if this could be a valid prefix
    if (newInput.length <= word.length && word.startsWith(newInput)) {
      setState(() => _input = newInput);
      _sfx.playKeystroke();

      // Check if word is complete
      if (newInput == word) {
        _onWordCorrect();
      }
    } else {
      // Wrong letter
      _sfx.playIncorrect();
      _shakeController?.forward(from: 0);
      setState(() {
        _errors++;
        _streak = 0;
      });
    }
  }

  void _onWordCorrect() {
    _sfx.playCorrect();
    _bounceController?.forward(from: 0);

    final streakBonus = _streak >= 3 ? (_streak ~/ 3) * 5 : 0;
    if (_streak >= 3) _sfx.playStreak();

    setState(() {
      _score += _scorePerWord + streakBonus;
      _streak++;
      if (_streak > _bestStreak) _bestStreak = _streak;
      _wordsCompleted++;
    });

    // Small delay then next word
    Future.delayed(const Duration(milliseconds: 600), () {
      if (mounted && _phase == _Phase.playing) {
        _nextWord();
      }
    });
  }

  // ── Build ──

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF0F4FF),
      body: switch (_phase) {
        _Phase.setup => _buildSetup(),
        _Phase.playing => _buildPlaying(),
        _Phase.gameOver => _buildGameOver(),
      },
    );
  }

  // ── Setup Phase ──

  Widget _buildSetup() {
    return KeyboardListener(
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
                    label: Text('Back', style: GoogleFonts.fredoka(fontSize: 16)),
                    style: TextButton.styleFrom(
                      foregroundColor: AppColors.textSecondary,
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                // Icon
                const Text('🧩', style: TextStyle(fontSize: 64)),
                const SizedBox(height: 12),
                Text(
                  'Word Builder',
                  style: GoogleFonts.fredoka(
                    fontSize: 32,
                    fontWeight: FontWeight.w700,
                    color: const Color(0xFF5C6BC0),
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Unscramble the letters to build the word!\nRead the meaning to figure out the answer.',
                  textAlign: TextAlign.center,
                  style: GoogleFonts.nunito(
                    fontSize: 15,
                    color: AppColors.textSecondary,
                  ),
                ),
                const SizedBox(height: 28),
                // Difficulty
                Text(
                  'Choose Difficulty',
                  style: GoogleFonts.fredoka(
                    fontSize: 18,
                    fontWeight: FontWeight.w500,
                    color: AppColors.textPrimary,
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
                              padding: const EdgeInsets.symmetric(vertical: 14),
                              decoration: BoxDecoration(
                                color: isSelected
                                    ? c.withValues(alpha: 0.15)
                                    : Colors.white,
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(
                                  color: isSelected ? c : Colors.grey.shade300,
                                  width: isSelected ? 2 : 1,
                                ),
                              ),
                              child: Column(
                                children: [
                                  Text(d.emoji, style: const TextStyle(fontSize: 22)),
                                  const SizedBox(height: 4),
                                  Text(
                                    d.label,
                                    style: GoogleFonts.fredoka(
                                      fontSize: 14,
                                      fontWeight: FontWeight.w500,
                                      color: isSelected ? c : AppColors.textSecondary,
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
                      backgroundColor: const Color(0xFF5C6BC0),
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                      elevation: 2,
                    ),
                    child: Text(
                      'Start Game',
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
    );
  }

  // ── Playing Phase ──

  Widget _buildPlaying() {
    final challenge = _currentChallenge;
    if (challenge == null) return const SizedBox.shrink();
    final word = challenge.wordMeaning.word;

    return KeyboardListener(
      focusNode: _gameFocusNode,
      autofocus: true,
      onKeyEvent: _handleGameKey,
      child: LayoutBuilder(
        builder: (context, constraints) {
          final isCompact = constraints.maxHeight < 500;
          final letterSize = isCompact ? 36.0 : 48.0;
          final meaningSize = isCompact ? 14.0 : 16.0;

          return SafeArea(
            child: Padding(
              padding: EdgeInsets.symmetric(
                horizontal: 24,
                vertical: isCompact ? 8 : 16,
              ),
              child: Column(
                children: [
                  // ── Top Bar ──
                  _buildTopBar(isCompact),
                  SizedBox(height: isCompact ? 8 : 20),

                  // ── Main Content ──
                  Expanded(
                    child: Center(
                      child: SingleChildScrollView(
                        child: ConstrainedBox(
                          constraints: const BoxConstraints(maxWidth: 500),
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              // Meaning card
                              Container(
                                width: double.infinity,
                                padding: EdgeInsets.all(isCompact ? 12 : 20),
                                decoration: BoxDecoration(
                                  color: Colors.white,
                                  borderRadius: BorderRadius.circular(16),
                                  boxShadow: [
                                    BoxShadow(
                                      color: const Color(0xFF5C6BC0)
                                          .withValues(alpha: 0.1),
                                      blurRadius: 12,
                                      offset: const Offset(0, 4),
                                    ),
                                  ],
                                ),
                                child: Column(
                                  children: [
                                    Text(
                                      '💡 What am I?',
                                      style: GoogleFonts.fredoka(
                                        fontSize: isCompact ? 14 : 16,
                                        fontWeight: FontWeight.w500,
                                        color: const Color(0xFF5C6BC0),
                                      ),
                                    ),
                                    SizedBox(height: isCompact ? 6 : 10),
                                    Text(
                                      challenge.wordMeaning.meaning,
                                      textAlign: TextAlign.center,
                                      style: GoogleFonts.nunito(
                                        fontSize: meaningSize,
                                        fontWeight: FontWeight.w600,
                                        color: AppColors.textPrimary,
                                        height: 1.4,
                                      ),
                                    ),
                                    if (_hintText.isNotEmpty) ...[
                                      const SizedBox(height: 8),
                                      Text(
                                        _hintText,
                                        style: GoogleFonts.nunito(
                                          fontSize: 13,
                                          color: AppColors.secondary,
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                                    ],
                                  ],
                                ),
                              ),
                              SizedBox(height: isCompact ? 16 : 28),

                              // Scrambled letters
                              AnimatedBuilder(
                                animation: _shakeAnimation!,
                                builder: (context, child) {
                                  return Transform.translate(
                                    offset: Offset(
                                      sin(_shakeAnimation!.value * pi) * 6,
                                      0,
                                    ),
                                    child: child,
                                  );
                                },
                                child: Wrap(
                                  spacing: 8,
                                  runSpacing: 8,
                                  alignment: WrapAlignment.center,
                                  children: challenge.scrambled.split('').map((c) {
                                    // Check if this letter has been "used" in input
                                    final remaining = _remainingLetters(
                                      challenge.scrambled,
                                      _input,
                                    );
                                    final isUsed = !remaining.contains(c) &&
                                        _countInString(remaining, c) <
                                            _countInString(challenge.scrambled, c);

                                    return AnimatedContainer(
                                      duration: const Duration(milliseconds: 200),
                                      width: letterSize,
                                      height: letterSize,
                                      decoration: BoxDecoration(
                                        color: isUsed
                                            ? Colors.grey.shade200
                                            : const Color(0xFF5C6BC0)
                                                .withValues(alpha: 0.12),
                                        borderRadius: BorderRadius.circular(12),
                                        border: Border.all(
                                          color: isUsed
                                              ? Colors.grey.shade300
                                              : const Color(0xFF5C6BC0)
                                                  .withValues(alpha: 0.4),
                                          width: 2,
                                        ),
                                      ),
                                      child: Center(
                                        child: Text(
                                          c.toUpperCase(),
                                          style: GoogleFonts.fredoka(
                                            fontSize: letterSize * 0.5,
                                            fontWeight: FontWeight.w600,
                                            color: isUsed
                                                ? Colors.grey.shade400
                                                : const Color(0xFF5C6BC0),
                                          ),
                                        ),
                                      ),
                                    );
                                  }).toList(),
                                ),
                              ),
                              SizedBox(height: isCompact ? 16 : 28),

                              // Input display
                              ScaleTransition(
                                scale: _bounceAnimation!,
                                child: Container(
                                  width: double.infinity,
                                  padding: EdgeInsets.symmetric(
                                    vertical: isCompact ? 10 : 16,
                                    horizontal: 16,
                                  ),
                                  decoration: BoxDecoration(
                                    color: Colors.white,
                                    borderRadius: BorderRadius.circular(16),
                                    border: Border.all(
                                      color: _input == word
                                          ? AppColors.correct
                                          : const Color(0xFF5C6BC0)
                                              .withValues(alpha: 0.3),
                                      width: 2,
                                    ),
                                  ),
                                  child: Row(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: List.generate(word.length, (i) {
                                      final hasChar = i < _input.length;
                                      final isCorrect =
                                          hasChar && _input[i] == word[i];
                                      return Container(
                                        width: letterSize * 0.85,
                                        height: letterSize * 0.85,
                                        margin: const EdgeInsets.symmetric(
                                          horizontal: 3,
                                        ),
                                        decoration: BoxDecoration(
                                          color: hasChar
                                              ? (isCorrect
                                                  ? AppColors.correct
                                                      .withValues(alpha: 0.15)
                                                  : Colors.white)
                                              : Colors.grey.shade100,
                                          borderRadius: BorderRadius.circular(10),
                                          border: Border.all(
                                            color: hasChar
                                                ? AppColors.correct
                                                    .withValues(alpha: 0.5)
                                                : Colors.grey.shade300,
                                          ),
                                        ),
                                        child: Center(
                                          child: Text(
                                            hasChar ? _input[i].toUpperCase() : '',
                                            style: GoogleFonts.fredoka(
                                              fontSize: letterSize * 0.45,
                                              fontWeight: FontWeight.w600,
                                              color: AppColors.correct,
                                            ),
                                          ),
                                        ),
                                      );
                                    }),
                                  ),
                                ),
                              ),
                              SizedBox(height: isCompact ? 8 : 16),

                              // Hint button
                              if (!_hintUsed)
                                TextButton.icon(
                                  onPressed: _useHint,
                                  icon: const Icon(Icons.lightbulb_outline, size: 18),
                                  label: Text(
                                    'Hint (Tab)',
                                    style: GoogleFonts.nunito(fontSize: 13),
                                  ),
                                  style: TextButton.styleFrom(
                                    foregroundColor: AppColors.secondary,
                                  ),
                                ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildTopBar(bool isCompact) {
    final timerColor = _remainingSeconds <= 10
        ? AppColors.incorrect
        : _remainingSeconds <= 30
            ? AppColors.secondary
            : AppColors.correct;

    return Row(
      children: [
        // Score
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          decoration: BoxDecoration(
            color: const Color(0xFF5C6BC0).withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Row(
            children: [
              const Text('⭐', style: TextStyle(fontSize: 16)),
              const SizedBox(width: 4),
              Text(
                '$_score',
                style: GoogleFonts.fredoka(
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                  color: const Color(0xFF5C6BC0),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(width: 8),
        // Streak
        if (_streak >= 2)
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            decoration: BoxDecoration(
              color: AppColors.secondary.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text(
              '🔥 $_streak',
              style: GoogleFonts.fredoka(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: AppColors.secondary,
              ),
            ),
          ),
        const Spacer(),
        // Timer
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          decoration: BoxDecoration(
            color: timerColor.withValues(alpha: 0.12),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Row(
            children: [
              Icon(Icons.timer_outlined, size: 18, color: timerColor),
              const SizedBox(width: 4),
              Text(
                _formatTime(_remainingSeconds),
                style: GoogleFonts.fredoka(
                  fontSize: 18,
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

  // ── Game Over Phase ──

  Widget _buildGameOver() {
    return KeyboardListener(
      focusNode: _overFocusNode,
      autofocus: true,
      onKeyEvent: (event) {
        if (event is! KeyDownEvent) return;
        final key = event.logicalKey;
        if (key == LogicalKeyboardKey.enter || key == LogicalKeyboardKey.space) {
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
                  _isNewHighScore ? '🏆' : '🧩',
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
                        : const Color(0xFF5C6BC0),
                  ),
                ),
                const SizedBox(height: 24),
                // Stats card
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: Colors.white,
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
                      _statRow('Score', '$_score', const Color(0xFF5C6BC0)),
                      _statRow('Words Built', '$_wordsCompleted', AppColors.correct),
                      _statRow('Best Streak', '$_bestStreak 🔥', AppColors.secondary),
                      _statRow('Errors', '$_errors', AppColors.incorrect),
                      if (_highScore > 0)
                        _statRow('Previous Best', '$_highScore', Colors.grey),
                    ],
                  ),
                ),
                const SizedBox(height: 28),
                // Buttons
                SizedBox(
                  width: double.infinity,
                  height: 50,
                  child: ElevatedButton.icon(
                    onPressed: _startGame,
                    icon: const Icon(Icons.refresh_rounded),
                    label: Text(
                      'Play Again',
                      style: GoogleFonts.fredoka(fontSize: 18),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF5C6BC0),
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

  // ── Helpers ──

  String _formatTime(int seconds) {
    final m = seconds ~/ 60;
    final s = seconds % 60;
    return '${m.toString().padLeft(2, '0')}:${s.toString().padLeft(2, '0')}';
  }

  /// Get remaining letters in scrambled after removing typed ones.
  String _remainingLetters(String scrambled, String typed) {
    final remaining = scrambled.split('');
    for (final c in typed.split('')) {
      remaining.remove(c);
    }
    return remaining.join();
  }

  int _countInString(String s, String c) {
    return s.split('').where((ch) => ch == c).length;
  }
}
