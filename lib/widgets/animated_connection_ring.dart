import 'package:flutter/material.dart';
import 'dart:math' as math;
import '../core/constants/app_colors.dart';
import '../core/constants/app_typography.dart';
import '../features/connection/domain/connection_state.dart';

class AnimatedConnectionRing extends StatefulWidget {
  final ConnectionStatus status;
  final bool isEnabled;

  const AnimatedConnectionRing({
    super.key,
    required this.status,
    required this.isEnabled,
  });

  @override
  State<AnimatedConnectionRing> createState() => _AnimatedConnectionRingState();
}

class _AnimatedConnectionRingState extends State<AnimatedConnectionRing>
    with SingleTickerProviderStateMixin {
  late AnimationController _rotationController;

  @override
  void initState() {
    super.initState();
    _rotationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2000),
    );
    _updateAnimation();
  }

  @override
  void didUpdateWidget(AnimatedConnectionRing oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.status != widget.status) {
      _updateAnimation();
    }
  }

  void _updateAnimation() {
    if (widget.status == ConnectionStatus.connecting) {
      _rotationController.repeat();
    } else {
      _rotationController.stop();
      _rotationController.reset();
    }
  }

  @override
  void dispose() {
    _rotationController.dispose();
    super.dispose();
  }

  Color get _ringColor {
    switch (widget.status) {
      case ConnectionStatus.connected:
        return AppColors.accentGreen;
      case ConnectionStatus.connecting:
        return AppColors.accentGold;
      case ConnectionStatus.disconnecting:
        return AppColors.accentGold;
      case ConnectionStatus.error:
        return AppColors.statusError;
      case ConnectionStatus.disconnected:
        return AppColors.statusDisconnected;
    }
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _rotationController,
      builder: (context, child) {
        return Transform.rotate(
          angle: _rotationController.value * 2 * math.pi,
          child: SizedBox(
            width: 160,
            height: 160,
            child: Stack(
              alignment: Alignment.center,
              children: [
                CustomPaint(
                  size: const Size(160, 160),
                  painter: _RingPainter(
                    color: _ringColor,
                    isAnimating:
                        widget.status == ConnectionStatus.connecting,
                    progress: _rotationController.value,
                  ),
                ),
                Transform.rotate(
                  angle: -_rotationController.value * 2 * math.pi,
                  child: _RingContent(status: widget.status),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

class _RingContent extends StatelessWidget {
  final ConnectionStatus status;

  const _RingContent({required this.status});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textColor = isDark ? AppColors.darkText : AppColors.lightText;

    switch (status) {
      case ConnectionStatus.connected:
        return const Icon(
          Icons.check,
          color: AppColors.accentGreen,
          size: 32,
        );
      case ConnectionStatus.connecting:
      case ConnectionStatus.disconnecting:
        return const SizedBox.shrink();
      case ConnectionStatus.error:
        return const Icon(
          Icons.error_outline,
          color: AppColors.statusError,
          size: 28,
        );
      case ConnectionStatus.disconnected:
        return Text(
          'TAP',
          style: AppTypography.mono(
            color: textColor.withOpacity(0.4),
            fontSize: 11,
          ),
        );
    }
  }
}

class _RingPainter extends CustomPainter {
  final Color color;
  final bool isAnimating;
  final double progress;

  _RingPainter({
    required this.color,
    required this.isAnimating,
    required this.progress,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = (size.width - 4) / 2;
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.0
      ..strokeCap = StrokeCap.round;

    if (isAnimating) {
      // Dashed arc for connecting state
      const dashCount = 8;
      const arcLength = math.pi * 2 / dashCount;
      const gap = arcLength * 0.4;
      const dash = arcLength - gap;

      for (int i = 0; i < dashCount; i++) {
        final startAngle = i * arcLength;
        canvas.drawArc(
          Rect.fromCircle(center: center, radius: radius),
          startAngle,
          dash,
          false,
          paint,
        );
      }
    } else {
      paint.color = color.withOpacity(0.8);
      canvas.drawCircle(center, radius, paint);
    }
  }

  @override
  bool shouldRepaint(_RingPainter oldDelegate) =>
      oldDelegate.color != color ||
      oldDelegate.isAnimating != isAnimating ||
      oldDelegate.progress != progress;
}
