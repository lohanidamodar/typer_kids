import 'dart:async';

import 'package:flutter/foundation.dart';

import '../models/lesson.dart';
import '../models/typing_stats.dart';

/// The state of a single character being typed
enum CharState { pending, correct, incorrect, current }

/// Manages the real-time state of typing during a lesson
class TypingProvider extends ChangeNotifier {
  Lesson? _currentLesson;
  int _currentExerciseIndex = 0;
  String _currentText = '';
  int _cursorPosition = 0;
  List<CharState> _charStates = [];

  int _totalCorrect = 0;
  int _totalIncorrect = 0;
  int _totalTyped = 0;

  /// Per-character error counts for this session: expected char -> error count
  final Map<String, int> _charErrors = {};

  /// Per-character correct counts for this session: expected char -> correct count
  final Map<String, int> _charCorrects = {};

  /// Error map for this session (expected char -> error count)
  Map<String, int> get charErrors => Map.unmodifiable(_charErrors);

  /// Correct map for this session (expected char -> correct count)
  Map<String, int> get charCorrects => Map.unmodifiable(_charCorrects);

  DateTime? _startTime;
  Timer? _timer;
  Duration _elapsed = Duration.zero;

  bool _isFinished = false;
  bool _isPaused = false;

  // Getters
  Lesson? get currentLesson => _currentLesson;
  int get currentExerciseIndex => _currentExerciseIndex;
  String get currentText => _currentText;
  int get cursorPosition => _cursorPosition;
  List<CharState> get charStates => List.unmodifiable(_charStates);
  bool get isFinished => _isFinished;
  bool get isPaused => _isPaused;
  Duration get elapsed => _elapsed;

  int get totalExercises => _currentLesson?.exercises.length ?? 0;
  bool get isLastExercise => _currentExerciseIndex >= totalExercises - 1;

  /// Live accuracy percentage
  double get liveAccuracy {
    if (_totalTyped == 0) return 100;
    return (_totalCorrect / _totalTyped) * 100;
  }

  /// Live WPM
  double get liveWpm {
    if (_elapsed.inSeconds == 0) return 0;
    final minutes = _elapsed.inSeconds / 60.0;
    final words = _totalCorrect / 5.0;
    return words / minutes;
  }

  /// Current character to type (or null if done)
  String? get currentChar {
    if (_cursorPosition >= _currentText.length) return null;
    return _currentText[_cursorPosition];
  }

  /// Start a new lesson
  void startLesson(Lesson lesson) {
    _currentLesson = lesson;
    _currentExerciseIndex = 0;
    _totalCorrect = 0;
    _totalIncorrect = 0;
    _totalTyped = 0;
    _charErrors.clear();
    _charCorrects.clear();
    _isFinished = false;
    _isPaused = false;
    _elapsed = Duration.zero;
    _startTime = null;
    _timer?.cancel();
    _timer = null;
    _loadExercise();
    notifyListeners();
  }

  void _loadExercise() {
    if (_currentLesson == null) return;
    if (_currentExerciseIndex >= _currentLesson!.exercises.length) {
      _finishLesson();
      return;
    }
    _currentText = _currentLesson!.exercises[_currentExerciseIndex];
    _cursorPosition = 0;
    _charStates = List.filled(_currentText.length, CharState.pending);
    if (_charStates.isNotEmpty) {
      _charStates[0] = CharState.current;
    }
    notifyListeners();
  }

  /// Handle a key press event
  void onKeyPressed(String key) {
    if (_isFinished || _isPaused) return;
    if (_cursorPosition >= _currentText.length) return;

    // Start timer on first keypress
    if (_startTime == null) {
      _startTime = DateTime.now();
      _startTimer();
    }

    final expected = _currentText[_cursorPosition];
    _totalTyped++;

    if (key == expected) {
      _charStates[_cursorPosition] = CharState.correct;
      _totalCorrect++;
      _charCorrects[expected] = (_charCorrects[expected] ?? 0) + 1;
    } else {
      _charStates[_cursorPosition] = CharState.incorrect;
      _totalIncorrect++;
      _charErrors[expected] = (_charErrors[expected] ?? 0) + 1;
    }

    _cursorPosition++;

    // Mark next char as current
    if (_cursorPosition < _currentText.length) {
      _charStates[_cursorPosition] = CharState.current;
    }

    // Check if exercise is complete
    if (_cursorPosition >= _currentText.length) {
      _onExerciseComplete();
    }

    notifyListeners();
  }

  void _onExerciseComplete() {
    if (isLastExercise) {
      _finishLesson();
    }
    // Otherwise wait for user to advance to next exercise
  }

  /// Advance to the next exercise
  void nextExercise() {
    if (_isFinished) return;
    _currentExerciseIndex++;
    _loadExercise();
  }

  /// Check if current exercise is complete
  bool get isExerciseComplete => _cursorPosition >= _currentText.length;

  void _finishLesson() {
    _isFinished = true;
    _timer?.cancel();
    notifyListeners();
  }

  void _startTimer() {
    _timer?.cancel();
    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (_startTime != null && !_isPaused) {
        _elapsed = DateTime.now().difference(_startTime!);
        notifyListeners();
      }
    });
  }

  /// Pause the lesson
  void pause() {
    _isPaused = true;
    notifyListeners();
  }

  /// Resume the lesson
  void resume() {
    _isPaused = false;
    notifyListeners();
  }

  /// Get final stats for the lesson
  TypingStats get stats => TypingStats(
    totalCharacters: _totalTyped,
    correctCharacters: _totalCorrect,
    incorrectCharacters: _totalIncorrect,
    elapsed: _elapsed,
    completedAt: DateTime.now(),
  );

  /// Reset and clean up
  void reset() {
    _timer?.cancel();
    _timer = null;
    _currentLesson = null;
    _isFinished = false;
    _isPaused = false;
    _elapsed = Duration.zero;
    _startTime = null;
    notifyListeners();
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }
}
