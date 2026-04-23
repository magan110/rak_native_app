import 'package:flutter/material.dart';

/// Application color palette — matches actual project usage
class AppColors {
  // Brand colors (RAK corporate — used across all feature screens)
  static const Color primaryNavy = Color(0xFF1E3A8A);
  static const Color primaryBlue = Color(0xFF3B82F6);

  // Keep 'primary' / 'secondary' aliases for theme compatibility
  static const Color primary = primaryNavy;
  static const Color secondary = primaryBlue;

  // Neutral colors
  static const Color white = Color(0xFFFFFFFF);
  static const Color black = Color(0xFF000000);
  static const Color grey = Color(0xFF9E9E9E);

  // Semantic colors
  static const Color success = Color(0xFF10B981);
  static const Color error = Color(0xFFEF4444);
  static const Color warning = Color(0xFFF59E0B);
  static const Color info = Color(0xFF2196F3);

  // Background colors
  static const Color background = Color(0xFFF8FAFC);
  static const Color surface = Color(0xFFFFFFFF);

  // Text colors
  static const Color textPrimary = Color(0xFF1F2937);
  static const Color textSecondary = Color(0xFF6B7280);
  static const Color textLight = Color(0xFF9CA3AF);

  // Gradient presets
  static const List<Color> primaryGradient = [primaryNavy, primaryBlue];
}
