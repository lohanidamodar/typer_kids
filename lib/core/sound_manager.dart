import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/foundation.dart';

/// Manages sound effects for the app.
/// All sounds are CC0 synthesized originals (see tool/generate_sfx.dart).
class SoundManager {
  static final SoundManager _instance = SoundManager._();
  factory SoundManager() => _instance;
  SoundManager._();

  bool _enabled = true;
  bool get enabled => _enabled;
  set enabled(bool value) => _enabled = value;

  /// Set to false if audio subsystem is unavailable (e.g. missing VC++ runtime).
  bool _audioAvailable = true;

  // Pool of players so overlapping sounds work
  final List<AudioPlayer> _pool = [];
  static const _poolSize = 6;

  AudioPlayer _getPlayer() {
    // Reuse a stopped player or create a new one
    for (final p in _pool) {
      if (p.state != PlayerState.playing) return p;
    }
    if (_pool.length < _poolSize) {
      final p = AudioPlayer();
      _pool.add(p);
      return p;
    }
    // All busy — reuse the first
    return _pool.first;
  }

  Future<void> _play(String asset, {double volume = 0.5}) async {
    if (!_enabled || !_audioAvailable) return;
    try {
      final player = _getPlayer();
      await player.setVolume(volume);
      await player.play(AssetSource('sounds/$asset'));
    } catch (e) {
      debugPrint('Audio error ($asset): $e');
      // Disable audio to prevent repeated failures / native crashes
      _audioAvailable = false;
    }
  }

  /// Correct keypress / word match
  Future<void> playCorrect() => _play('correct.wav', volume: 0.5);

  /// Wrong keypress / mismatch
  Future<void> playIncorrect() => _play('wrong.wav', volume: 0.4);

  /// Bubble pop / word destroyed
  Future<void> playPop() => _play('pop.wav', volume: 0.6);

  /// Missed word
  Future<void> playMiss() => _play('miss.wav', volume: 0.4);

  /// Game starting
  Future<void> playGameStart() => _play('game_start.wav', volume: 0.5);

  /// Game over
  Future<void> playGameOver() => _play('game_over.wav', volume: 0.5);

  /// Streak bonus
  Future<void> playStreak() => _play('streak.wav', volume: 0.45);

  /// Soft key click
  Future<void> playKeystroke() => _play('keystroke.wav', volume: 0.25);

  /// Star earned / celebration
  Future<void> playCelebration() => _play('streak.wav', volume: 0.6);

  /// Alias kept for backward compat
  Future<void> playStarEarned() => playCelebration();

  void dispose() {
    for (final p in _pool) {
      p.dispose();
    }
    _pool.clear();
  }
}
