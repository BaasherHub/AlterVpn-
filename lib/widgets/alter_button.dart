import 'package:flutter/material.dart';
import '../core/constants/app_colors.dart';
import '../core/constants/app_typography.dart';
import '../core/constants/app_spacing.dart';

enum AlterButtonVariant { primary, secondary, ghost }

class AlterButton extends StatelessWidget {
  final String label;
  final VoidCallback? onPressed;
  final AlterButtonVariant variant;
  final bool isLoading;
  final IconData? icon;

  const AlterButton({
    super.key,
    required this.label,
    this.onPressed,
    this.variant = AlterButtonVariant.primary,
    this.isLoading = false,
    this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: AppSpacing.minTouchTarget,
      child: _buildButton(),
    );
  }

  Widget _buildButton() {
    switch (variant) {
      case AlterButtonVariant.primary:
        return ElevatedButton(
          onPressed: isLoading ? null : onPressed,
          style: ElevatedButton.styleFrom(
            backgroundColor: AppColors.accentGreen,
            foregroundColor: AppColors.white,
            elevation: 0,
            shape:
                const RoundedRectangleBorder(borderRadius: BorderRadius.zero),
          ),
          child: _buildChild(AppColors.white),
        );
      case AlterButtonVariant.secondary:
        return OutlinedButton(
          onPressed: isLoading ? null : onPressed,
          style: OutlinedButton.styleFrom(
            side: const BorderSide(color: AppColors.accentGreen),
            shape:
                const RoundedRectangleBorder(borderRadius: BorderRadius.zero),
          ),
          child: _buildChild(AppColors.accentGreen),
        );
      case AlterButtonVariant.ghost:
        return TextButton(
          onPressed: isLoading ? null : onPressed,
          child: _buildChild(AppColors.darkTextSecondary),
        );
    }
  }

  Widget _buildChild(Color color) {
    if (isLoading) {
      return SizedBox(
        width: 20,
        height: 20,
        child: CircularProgressIndicator(
          color: color,
          strokeWidth: 1.5,
        ),
      );
    }
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        if (icon != null) ...[
          Icon(icon, size: 16, color: color),
          const SizedBox(width: 8),
        ],
        Text(
          label.toUpperCase(),
          style:
              AppTypography.labelLarge(color: color).copyWith(letterSpacing: 2),
        ),
      ],
    );
  }
}
