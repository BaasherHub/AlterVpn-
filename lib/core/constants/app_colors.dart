import 'package:flutter/material.dart';

class AppColors {
  AppColors._();

  // Dark theme colors
  static const Color darkBackground = Color(0xFF0A0A0A);
  static const Color darkSurface = Color(0xFF141414);
  static const Color darkBorder = Color(0xFF1F1F1F);
  static const Color darkText = Color(0xFFFAFAF8);
  static const Color darkTextSecondary = Color(0xFF8A8A8A);

  // Light theme colors
  static const Color lightBackground = Color(0xFFFAFAF8);
  static const Color lightSurface = Color(0xFFF0EFEB);
  static const Color lightBorder = Color(0xFFE5E4E0);
  static const Color lightText = Color(0xFF1A1A1A);
  static const Color lightTextSecondary = Color(0xFF6B6B6B);

  // Brand colors
  static const Color accentGreen = Color(0xFF1B4332);
  static const Color accentGreenLight = Color(0xFF2D6A4F);
  static const Color accentGold = Color(0xFFC9A96E);
  static const Color accentGoldLight = Color(0xFFD4B483);

  // Status colors
  static const Color statusConnected = accentGreen;
  static const Color statusConnecting = accentGold;
  static const Color statusDisconnected = Color(0xFF333333);
  static const Color statusError = Color(0xFF8B2E2E);

  // Common
  static const Color transparent = Colors.transparent;
  static const Color white = Color(0xFFFAFAF8);
  static const Color black = Color(0xFF0A0A0A);
}
