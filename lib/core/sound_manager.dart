import 'package:flutter/services.dart';

/// Manages sound effects for typing feedback
class SoundManager {
  static final SoundManager _instance = SoundManager._();
  factory SoundManager() => _instance;
  SoundManager._();

  bool _enabled = true;

  bool get enabled => _enabled;
  set enabled(bool value) => _enabled = value;

  /// Play a gentle click for correct keypress
  Future<void> playCorrect() async {
    if (!_enabled) return;
    // Using system sounds as fallback - can add custom sounds later
    await HapticFeedback.lightImpact();
  }

  /// Play an error sound for incorrect keypress
  Future<void> playIncorrect() async {
    if (!_enabled) return;
    await HapticFeedback.heavyImpact();
  }

  /// Play a celebration sound for completing a lesson
  Future<void> playCelebration() async {
    if (!_enabled) return;
    await HapticFeedback.mediumImpact();
  }

  /// Play a star earned sound
  Future<void> playStarEarned() async {
    if (!_enabled) return;
    await HapticFeedback.selectionClick();
  }
}
