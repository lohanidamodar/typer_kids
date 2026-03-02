import 'package:flutter/material.dart';

/// Color palette for Typer Kids - bright, fun, kid-friendly colors
class AppColors {
  AppColors._();

  // Primary palette
  static const Color primary = Color(0xFF4CAF50); // Jungle green
  static const Color primaryLight = Color(0xFF81C784);
  static const Color primaryDark = Color(0xFF2E7D32);

  // Secondary palette
  static const Color secondary = Color(0xFFFF9800); // Warm orange
  static const Color secondaryLight = Color(0xFFFFB74D);
  static const Color secondaryDark = Color(0xFFF57C00);

  // Accent colors
  static const Color accent = Color(0xFFE91E63); // Fun pink
  static const Color accentLight = Color(0xFFF48FB1);

  // Background
  static const Color background = Color(0xFFFFF8E1); // Warm cream
  static const Color surface = Color(0xFFFFFFFF);
  static const Color surfaceVariant = Color(0xFFF5F5F5);

  // Text
  static const Color textPrimary = Color(0xFF3E2723); // Dark brown
  static const Color textSecondary = Color(0xFF5D4037);
  static const Color textLight = Color(0xFFFFFFFF);

  // Feedback colors
  static const Color correct = Color(0xFF66BB6A);
  static const Color incorrect = Color(0xFFEF5350);
  static const Color warning = Color(0xFFFFA726);

  // Star colors
  static const Color starFilled = Color(0xFFFFD600);
  static const Color starEmpty = Color(0xFFE0E0E0);

  // Finger color zones for keyboard (color-coded by finger)
  static const Color fingerPinkyLeft = Color(0xFFE57373); // Red
  static const Color fingerRingLeft = Color(0xFFFFB74D); // Orange
  static const Color fingerMiddleLeft = Color(0xFFFFD54F); // Yellow
  static const Color fingerIndexLeft = Color(0xFF81C784); // Green
  static const Color fingerIndexRight = Color(0xFF4FC3F7); // Light blue
  static const Color fingerMiddleRight = Color(0xFF7986CB); // Indigo
  static const Color fingerRingRight = Color(0xFFBA68C8); // Purple
  static const Color fingerPinkyRight = Color(0xFFF06292); // Pink
  static const Color fingerThumb = Color(0xFF90A4AE); // Gray-blue

  // Lesson category colors
  static const Color categoryHomeRow = Color(0xFF66BB6A);
  static const Color categoryTopRow = Color(0xFF42A5F5);
  static const Color categoryBottomRow = Color(0xFFAB47BC);
  static const Color categoryNumbers = Color(0xFFFF7043);
  static const Color categoryWords = Color(0xFFEC407A);
  static const Color categorySentences = Color(0xFF26C6DA);
}
