import 'package:flutter/material.dart';

extension StringExtensions on String {
  String get capitalize => isEmpty
      ? this
      : '${this[0].toUpperCase()}${substring(1).toLowerCase()}';

  bool get isValidIpAddress {
    final parts = split('.');
    if (parts.length != 4) return false;
    return parts.every((part) {
      final n = int.tryParse(part);
      return n != null && n >= 0 && n <= 255;
    });
  }
}

extension DurationExtensions on Duration {
  String get formatted {
    final hours = inHours.toString().padLeft(2, '0');
    final minutes = (inMinutes % 60).toString().padLeft(2, '0');
    final seconds = (inSeconds % 60).toString().padLeft(2, '0');
    return '$hours:$minutes:$seconds';
  }
}

extension ColorExtensions on Color {
  Color withOpacityFactor(double factor) =>
      withValues(alpha: (a * factor).clamp(0.0, 1.0));
}

extension ContextExtensions on BuildContext {
  ThemeData get theme => Theme.of(this);
  TextTheme get textTheme => Theme.of(this).textTheme;
  ColorScheme get colorScheme => Theme.of(this).colorScheme;
  bool get isDark => Theme.of(this).brightness == Brightness.dark;
  double get screenWidth => MediaQuery.of(this).size.width;
  double get screenHeight => MediaQuery.of(this).size.height;
}
