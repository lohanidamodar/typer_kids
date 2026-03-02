import 'package:flutter/material.dart';

import '../core/theme/app_colors.dart';

/// Maps each key to the finger that should type it and its color
class KeyboardData {
  KeyboardData._();

  /// The three rows of keys on a QWERTY keyboard
  static const List<List<String>> keyboardRows = [
    // Number row
    ['`', '1', '2', '3', '4', '5', '6', '7', '8', '9', '0', '-', '='],
    // Top row
    ['q', 'w', 'e', 'r', 't', 'y', 'u', 'i', 'o', 'p', '[', ']', '\\'],
    // Home row
    ['a', 's', 'd', 'f', 'g', 'h', 'j', 'k', 'l', ';', "'"],
    // Bottom row
    ['z', 'x', 'c', 'v', 'b', 'n', 'm', ',', '.', '/'],
    // Space bar
    [' '],
  ];

  /// Which finger types each key (finger name)
  static const Map<String, String> keyToFinger = {
    // Left pinky
    '`': 'left-pinky', '1': 'left-pinky',
    'q': 'left-pinky', 'a': 'left-pinky', 'z': 'left-pinky',
    // Left ring
    '2': 'left-ring',
    'w': 'left-ring', 's': 'left-ring', 'x': 'left-ring',
    // Left middle
    '3': 'left-middle',
    'e': 'left-middle', 'd': 'left-middle', 'c': 'left-middle',
    // Left index
    '4': 'left-index', '5': 'left-index',
    'r': 'left-index', 't': 'left-index',
    'f': 'left-index', 'g': 'left-index',
    'v': 'left-index', 'b': 'left-index',
    // Right index
    '6': 'right-index', '7': 'right-index',
    'y': 'right-index', 'u': 'right-index',
    'h': 'right-index', 'j': 'right-index',
    'n': 'right-index', 'm': 'right-index',
    // Right middle
    '8': 'right-middle',
    'i': 'right-middle', 'k': 'right-middle', ',': 'right-middle',
    // Right ring
    '9': 'right-ring',
    'o': 'right-ring', 'l': 'right-ring', '.': 'right-ring',
    // Right pinky
    '0': 'right-pinky', '-': 'right-pinky', '=': 'right-pinky',
    'p': 'right-pinky', '[': 'right-pinky', ']': 'right-pinky',
    '\\': 'right-pinky',
    ';': 'right-pinky', "'": 'right-pinky', '/': 'right-pinky',
    // Thumbs
    ' ': 'thumb',
  };

  /// Color for each finger
  static Color fingerColor(String finger) => switch (finger) {
    'left-pinky' => AppColors.fingerPinkyLeft,
    'left-ring' => AppColors.fingerRingLeft,
    'left-middle' => AppColors.fingerMiddleLeft,
    'left-index' => AppColors.fingerIndexLeft,
    'right-index' => AppColors.fingerIndexRight,
    'right-middle' => AppColors.fingerMiddleRight,
    'right-ring' => AppColors.fingerRingRight,
    'right-pinky' => AppColors.fingerPinkyRight,
    'thumb' => AppColors.fingerThumb,
    _ => Colors.grey,
  };

  /// Get the color for a specific key
  static Color colorForKey(String key) {
    final finger = keyToFinger[key.toLowerCase()];
    if (finger == null) return Colors.grey.shade300;
    return fingerColor(finger);
  }

  /// Get the finger name for a specific key (kid-friendly)
  static String fingerNameForKey(String key) {
    final finger = keyToFinger[key.toLowerCase()];
    return switch (finger) {
      'left-pinky' => 'Left Pinky 🤙',
      'left-ring' => 'Left Ring 💍',
      'left-middle' => 'Left Middle ☝️',
      'left-index' => 'Left Pointer 👆',
      'right-index' => 'Right Pointer 👆',
      'right-middle' => 'Right Middle ☝️',
      'right-ring' => 'Right Ring 💍',
      'right-pinky' => 'Right Pinky 🤙',
      'thumb' => 'Thumb 👍',
      _ => 'Unknown',
    };
  }

  /// Home row keys that fingers rest on
  static const List<String> homeRowKeys = [
    'a',
    's',
    'd',
    'f',
    'j',
    'k',
    'l',
    ';',
  ];

  /// Display label for special keys
  static String displayLabel(String key) => switch (key) {
    ' ' => 'Space',
    ';' => ';',
    "'" => "'",
    ',' => ',',
    '.' => '.',
    '/' => '/',
    _ => key.toUpperCase(),
  };
}
