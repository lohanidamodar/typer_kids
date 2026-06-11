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
  final Map<String, int> _errorsByKey = {};

  DateTime? _startTime;
  DateTime? _pauseStart;
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
    _errorsByKey.clear();
    _isFinished = false;
    _isPaused = false;
    _elapsed = Duration.zero;
    _startTime = null;
    _pauseStart = null;
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

  /// Handle a key press event.
  /// Returns true if the key matched the expected character, false if it was
  /// a mistake, or null if the input was ignored.
  bool? onKeyPressed(String key) {
    if (_isFinished || _isPaused) return null;
    if (_cursorPosition >= _currentText.length) return null;

    // Start timer on first keypress
    if (_startTime == null) {
      _startTime = DateTime.now();
      _startTimer();
    }

    final expected = _currentText[_cursorPosition];
    _totalTyped++;

    final correct = key == expected;
    if (correct) {
      _charStates[_cursorPosition] = CharState.correct;
      _totalCorrect++;
    } else {
      _charStates[_cursorPosition] = CharState.incorrect;
      _totalIncorrect++;
      // Don't count the space bar as a "tricky key" — misses there are
      // usually rhythm mistakes, not finger placement problems.
      if (expected != ' ') {
        _errorsByKey[expected] = (_errorsByKey[expected] ?? 0) + 1;
      }
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
    return correct;
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
    if (_isPaused) return;
    _isPaused = true;
    _pauseStart = DateTime.now();
    notifyListeners();
  }

  /// Resume the lesson
  void resume() {
    if (!_isPaused) return;
    _isPaused = false;
    // Shift the start time forward by the paused duration so the elapsed
    // time doesn't include the time spent paused.
    if (_pauseStart != null && _startTime != null) {
      _startTime = _startTime!.add(DateTime.now().difference(_pauseStart!));
    }
    _pauseStart = null;
    notifyListeners();
  }

  /// Get final stats for the lesson
  TypingStats get stats => TypingStats(
    totalCharacters: _totalTyped,
    correctCharacters: _totalCorrect,
    incorrectCharacters: _totalIncorrect,
    elapsed: _elapsed,
    completedAt: DateTime.now(),
    errorsByKey: Map.unmodifiable(_errorsByKey),
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
    _pauseStart = null;
    _errorsByKey.clear();
    notifyListeners();
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }
}
