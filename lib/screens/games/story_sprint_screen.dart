import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';

import '../../core/sound_manager.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_theme.dart';
import '../../data/sentence_lists.dart';
import '../../data/word_lists.dart';
import '../../providers/progress_provider.dart';
import '../../widgets/quit_dialog.dart';
import 'widgets/story_sprint_views.dart';

// ─────────────────────────────────────────────────────────────────────────────
// Data
// ─────────────────────────────────────────────────────────────────────────────

enum _Phase { setup, playing, gameOver }

const _accent = Color(0xFFFB8C00);
const _gameDuration = 90;
const _pointsPerChar = 2;
const _sentenceBonus = 40;

// ─────────────────────────────────────────────────────────────────────────────
// Screen
// ─────────────────────────────────────────────────────────────────────────────

/// Side-scrolling sprint: type full sentences — capitals and punctuation
/// included — to run your character down the track. Each finished sentence
/// is another 100 m. Wrong keys make you stumble and don't advance.
class StorySprintScreen extends StatefulWidget {
  const StorySprintScreen({super.key});

  @override
  State<StorySprintScreen> createState() => _StorySprintScreenState();
}

class _StorySprintScreenState extends State<StorySprintScreen> {
  // ── State ──
  _Phase _phase = _Phase.setup;
  ContentDifficulty _difficulty = ContentDifficulty.easy;

  List<String> _sentences = [];
  int _sentenceIndex = 0;
  int _charIndex = 0;
  int _score = 0;
  int _correctChars = 0;
  int _errors = 0;
  int _streak = 0;
  int _bestStreak = 0;
  int _sentencesDone = 0;
  bool _stumbled = false;
  int _remainingSeconds = 0;
  bool _isNewHighScore = false;
  int _highScore = 0;

  Timer? _gameTimer;
  Timer? _stumbleTimer;

  // Focus
  final _setupFocusNode = FocusNode();
  final _gameFocusNode = FocusNode();
  final _overFocusNode = FocusNode();

  final _sfx = SoundManager();

  String get _currentSentence =>
      _sentenceIndex < _sentences.length ? _sentences[_sentenceIndex] : '';

  /// Progress through the current sentence (0..1) — the runner's position.
  double get _legProgress => _currentSentence.isEmpty
      ? 0
      : _charIndex / _currentSentence.length;

  /// Total distance run, 100 m per finished sentence.
  int get _distance => _sentencesDone * 100 + (_legProgress * 100).round();

  @override
  void dispose() {
    _gameTimer?.cancel();
    _stumbleTimer?.cancel();
    _setupFocusNode.dispose();
    _gameFocusNode.dispose();
    _overFocusNode.dispose();
    super.dispose();
  }

  // ── Game Logic ──

  void _startGame() {
    _sentences = SentenceLists.shuffledFor(_difficulty);
    _sentenceIndex = 0;
    _charIndex = 0;
    _score = 0;
    _correctChars = 0;
    _errors = 0;
    _streak = 0;
    _bestStreak = 0;
    _sentencesDone = 0;
    _stumbled = false;
    _remainingSeconds = _gameDuration;
    _isNewHighScore = false;
    _highScore = 0;
    _phase = _Phase.playing;
    _sfx.playGameStart();
    setState(() {});

    _startTimer();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _gameFocusNode.requestFocus();
    });
  }

  void _startTimer() {
    _gameTimer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (!mounted) return;
      setState(() {
        _remainingSeconds--;
        if (_remainingSeconds <= 0) _endGame();
      });
    });
  }

  void _handleGameKey(KeyEvent event) {
    if (event is! KeyDownEvent) return;

    if (event.logicalKey == LogicalKeyboardKey.escape) {
      _showQuitDialog();
      return;
    }

    final char = event.character;
    if (char == null || char.isEmpty) return;
    if (_currentSentence.isEmpty) return;

    final expected = _currentSentence[_charIndex];
    setState(() {
      if (char == expected) {
        _charIndex++;
        _correctChars++;
        _streak++;
        if (_streak > _bestStreak) _bestStreak = _streak;
        _score += _pointsPerChar;
        _sfx.playKeystroke();

        if (_charIndex >= _currentSentence.length) {
          // Sentence finished — another 100 m!
          _sentencesDone++;
          _score += _sentenceBonus;
          _sentenceIndex = (_sentenceIndex + 1) % _sentences.length;
          _charIndex = 0;
          _sfx.playStreak();
        }
      } else {
        _errors++;
        _streak = 0;
        _stumble();
        _sfx.playIncorrect();
      }
    });
  }

  /// Briefly flash the runner/sentence to show the stumble.
  void _stumble() {
    _stumbled = true;
    _stumbleTimer?.cancel();
    _stumbleTimer = Timer(const Duration(milliseconds: 250), () {
      if (mounted) setState(() => _stumbled = false);
    });
  }

  void _endGame() {
    _gameTimer?.cancel();
    _sfx.playGameOver();
    final progress = Provider.of<ProgressProvider>(context, listen: false);
    _highScore = progress.getHighScore('story_sprint');
    progress.recordScore('story_sprint', _score).then((isNew) {
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
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => QuitDialog(
        title: 'Stop Running?',
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
        _startTimer();
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
    return StorySprintMenu(
      difficulty: _difficulty,
      focusNode: _setupFocusNode,
      onDifficultySelected: (d) => setState(() => _difficulty = d),
      onStart: _startGame,
      onBack: () => context.pop(),
    );
  }

  Widget _buildGameOver() {
    final typedMinutes = _gameDuration / 60.0;
    final wpm = (_correctChars / 5.0 / typedMinutes).round();
    final attempts = _correctChars + _errors;
    final accuracy = attempts > 0
        ? (_correctChars / attempts * 100).round()
        : 100;
    return StorySprintGameOver(
      score: _score,
      isNewHighScore: _isNewHighScore,
      highScore: _highScore,
      distance: _distance,
      sentencesDone: _sentencesDone,
      wpm: wpm,
      accuracy: accuracy,
      bestStreak: _bestStreak,
      focusNode: _overFocusNode,
      onPlayAgain: _playAgain,
      onBack: () => context.pop(),
    );
  }

  // ── Playing ───────────────────────────────────────────────────────────────

  Widget _buildGame() {
    final mins = (_remainingSeconds ~/ 60).toString().padLeft(2, '0');
    final secs = (_remainingSeconds % 60).toString().padLeft(2, '0');
    final timerColor = _remainingSeconds <= 10
        ? AppColors.incorrect
        : _accent;

    return Scaffold(
      backgroundColor: const Color(0xFFFFF3E0),
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
                final sentenceFontSize = isWide ? 26.0 : 19.0;

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
                            '🏃 $_distance m',
                            style: GoogleFonts.fredoka(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                              color: _accent,
                            ),
                          ),
                          const SizedBox(width: 12),
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

                    // Running track
                    const SizedBox(height: 12),
                    _buildTrack(screenW),
                    const SizedBox(height: 8),

                    // Sentence to type
                    Expanded(
                      child: Center(
                        child: SingleChildScrollView(
                          padding: const EdgeInsets.symmetric(horizontal: 24),
                          child: _buildSentence(sentenceFontSize),
                        ),
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.only(bottom: 10),
                      child: Text(
                        'Type the sentence — capitals and punctuation count!',
                        style: GoogleFonts.nunito(
                          fontSize: 13,
                          color: AppColors.textSecondary,
                        ),
                      ),
                    ),
                  ],
                );
              },
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildTrack(double screenW) {
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
        child: LayoutBuilder(
          builder: (context, constraints) {
            final trackW = constraints.maxWidth;
            final pos = (_legProgress * (trackW - 28)).clamp(0.0, trackW - 28);

            return SizedBox(
              height: 36,
              child: Stack(
                children: [
                  // Track bed
                  Positioned(
                    left: 0,
                    right: 0,
                    top: 16,
                    child: Container(
                      height: 8,
                      decoration: BoxDecoration(
                        color: const Color(0xFFFFE0B2),
                        borderRadius: BorderRadius.circular(4),
                      ),
                    ),
                  ),
                  // Progress fill
                  Positioned(
                    left: 0,
                    top: 16,
                    child: Container(
                      width: pos + 14,
                      height: 8,
                      decoration: BoxDecoration(
                        color: _accent.withValues(alpha: 0.5),
                        borderRadius: BorderRadius.circular(4),
                      ),
                    ),
                  ),
                  // Runner (faces the finish line)
                  AnimatedPositioned(
                    duration: const Duration(milliseconds: 120),
                    left: pos,
                    top: _stumbled ? 6 : 0,
                    child: Transform.flip(
                      flipX: true,
                      child: Text(
                        _stumbled ? '🤸' : '🏃',
                        style: const TextStyle(fontSize: 26),
                      ),
                    ),
                  ),
                  // Finish flag
                  const Positioned(
                    right: 0,
                    top: 0,
                    child: Text('🏁', style: TextStyle(fontSize: 22)),
                  ),
                ],
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _buildSentence(double fontSize) {
    final sentence = _currentSentence;
    if (sentence.isEmpty) return const SizedBox.shrink();

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: _stumbled
              ? AppColors.incorrect.withValues(alpha: 0.7)
              : _accent.withValues(alpha: 0.35),
          width: 2,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 8,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Text.rich(
        TextSpan(
          children: [
            // Already typed
            TextSpan(
              text: sentence.substring(0, _charIndex),
              style: AppTheme.typingTextStyle(
                fontSize: fontSize,
                fontWeight: FontWeight.w600,
                color: AppColors.correct,
              ),
            ),
            // Current character
            TextSpan(
              text: sentence[_charIndex],
              style:
                  AppTheme.typingTextStyle(
                    fontSize: fontSize,
                    fontWeight: FontWeight.w700,
                    color: _stumbled ? Colors.white : _accent,
                    decoration: TextDecoration.underline,
                    decorationColor: _accent,
                  ).copyWith(
                    backgroundColor: _stumbled
                        ? AppColors.incorrect
                        : _accent.withValues(alpha: 0.18),
                    decorationThickness: 3,
                  ),
            ),
            // Remaining
            if (_charIndex + 1 < sentence.length)
              TextSpan(
                text: sentence.substring(_charIndex + 1),
                style: AppTheme.typingTextStyle(
                  fontSize: fontSize,
                  color: AppColors.textPrimary,
                ),
              ),
          ],
        ),
        textAlign: TextAlign.center,
      ),
    );
  }
}
