import 'package:flutter/material.dart';
import '../core/constants/app_colors.dart';

/// Circular shield mark used as the in-app logo (no raster asset required).
class AlterLogoMark extends StatelessWidget {
  final double size;

  const AlterLogoMark({super.key, this.size = 40});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final fill = isDark ? AppColors.darkSurface : AppColors.lightSurface;
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        border: Border.all(color: AppColors.accentGold, width: 1.5),
        color: fill,
      ),
      child: Icon(
        Icons.shield_outlined,
        color: AppColors.accentGold,
        size: size * 0.5,
      ),
    );
  }
}
