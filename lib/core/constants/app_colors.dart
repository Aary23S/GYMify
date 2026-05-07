import 'package:flutter/material.dart';

class AppColors {
  AppColors._();

  // PRIMARY COLORS
  static const Color primary = Color(0xFF1E3A5F);
  static const Color primaryLight = Color(0xFF2E5D9E);
  static const Color primaryDark = Color(0xFF0F2644);

  // ACCENT COLORS (Action Colors)
  static const Color accent = Color(0xFFFF6B35);
  static const Color accentLight = Color(0xFFFF9D72);
  static const Color accentDark = Color(0xFFE55A20);

  // TEXT COLORS
  static const Color textPrimary =
      Color(0xFF111827); // Very dark for maximum contrast
  static const Color textSecondary =
      Color(0xFF374151); // Dark grey, still very readable
  static const Color textMuted =
      Color(0xFF6B7280); // For labels/captions, WCAG compliant
  static const Color textOnDark =
      Colors.white; // For primary/accent backgrounds
  static const Color textOnPrimary = Colors.white;
  static const Color textOnAccent = Colors.white;

  // SURFACE COLORS
  static const Color background = Color(0xFFF9FAFB);
  static const Color surface = Colors.white;
  static const Color card = Colors.white;
  static const Color border =
      Color(0xFFD1D5DB); // Stronger border for better visibility
  static const Color divider = Color(0xFFE5E7EB);

  // STATE COLORS
  static const Color success = Color(0xFF065F46); // Deep green
  static const Color warning = Color(0xFF92400E); // Deep orange/brown
  static const Color danger = Color(0xFF991B1B); // Deep red
  static const Color info = Color(0xFF1E40AF); // Deep blue

  // STATUS COLORS
  static const Color statusActive = Color(0xFF065F46);
  static const Color statusExpired = Color(0xFF991B1B);
  static const Color statusPaused = Color(0xFF92400E);
  static const Color statusInactive = Color(0xFF374151);
}
