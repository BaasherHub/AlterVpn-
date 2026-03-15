import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'app_colors.dart';

class AppTypography {
  AppTypography._();

  static TextStyle displayLarge({Color? color}) => GoogleFonts.playfairDisplay(
        fontSize: 48,
        fontWeight: FontWeight.w700,
        letterSpacing: 12,
        color: color ?? AppColors.darkText,
      );

  static TextStyle displayMedium({Color? color}) => GoogleFonts.playfairDisplay(
        fontSize: 32,
        fontWeight: FontWeight.w600,
        letterSpacing: 2,
        color: color ?? AppColors.darkText,
      );

  static TextStyle displaySmall({Color? color}) => GoogleFonts.playfairDisplay(
        fontSize: 24,
        fontWeight: FontWeight.w600,
        color: color ?? AppColors.darkText,
      );

  static TextStyle headingLarge({Color? color}) => GoogleFonts.dmSans(
        fontSize: 20,
        fontWeight: FontWeight.w600,
        letterSpacing: 0.5,
        color: color ?? AppColors.darkText,
      );

  static TextStyle headingMedium({Color? color}) => GoogleFonts.dmSans(
        fontSize: 16,
        fontWeight: FontWeight.w600,
        color: color ?? AppColors.darkText,
      );

  static TextStyle bodyLarge({Color? color}) => GoogleFonts.dmSans(
        fontSize: 16,
        fontWeight: FontWeight.w400,
        color: color ?? AppColors.darkText,
      );

  static TextStyle bodyMedium({Color? color}) => GoogleFonts.dmSans(
        fontSize: 14,
        fontWeight: FontWeight.w400,
        color: color ?? AppColors.darkText,
      );

  static TextStyle bodySmall({Color? color}) => GoogleFonts.dmSans(
        fontSize: 12,
        fontWeight: FontWeight.w400,
        color: color ?? AppColors.darkTextSecondary,
      );

  static TextStyle labelLarge({Color? color}) => GoogleFonts.dmSans(
        fontSize: 14,
        fontWeight: FontWeight.w500,
        letterSpacing: 1.2,
        color: color ?? AppColors.darkText,
      );

  static TextStyle mono({Color? color, double fontSize = 14}) =>
      GoogleFonts.jetBrainsMono(
        fontSize: fontSize,
        fontWeight: FontWeight.w400,
        color: color ?? AppColors.darkText,
      );

  static TextStyle monoLarge({Color? color}) => GoogleFonts.jetBrainsMono(
        fontSize: 24,
        fontWeight: FontWeight.w500,
        color: color ?? AppColors.darkText,
      );

  static TextStyle splashTitle({Color? color}) => GoogleFonts.playfairDisplay(
        fontSize: 48,
        fontWeight: FontWeight.w700,
        letterSpacing: 12,
        color: color ?? AppColors.darkText,
      );

  static TextStyle splashSubtitle({Color? color}) => GoogleFonts.dmSans(
        fontSize: 14,
        fontWeight: FontWeight.w300,
        letterSpacing: 8,
        color: color ?? AppColors.darkTextSecondary,
      );
}
