import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../domain/connection_controller.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_typography.dart';
import '../../../core/utils/formatters.dart';

class ConnectionStatusBar extends ConsumerWidget {
  const ConnectionStatusBar({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final connectionState = ref.watch(connectionControllerProvider);

    if (!connectionState.isConnected) return const SizedBox.shrink();

    final status = connectionState.vpnStatus;

    return AnimatedOpacity(
      duration: const Duration(milliseconds: 300),
      opacity: connectionState.isConnected ? 1.0 : 0.0,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            _StatChip(
              label: '↓',
              value: Formatters.formatBytes(status.downloadSpeed),
            ),
            const SizedBox(width: 32),
            _StatChip(
              label: '↑',
              value: Formatters.formatBytes(status.uploadSpeed),
            ),
          ],
        ),
      ),
    );
  }
}

class _StatChip extends StatelessWidget {
  final String label;
  final String value;

  const _StatChip({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          label,
          style: AppTypography.mono(
            color: AppColors.accentGold,
            fontSize: 12,
          ),
        ),
        const SizedBox(width: 6),
        Text(
          value,
          style: AppTypography.mono(
            color: AppColors.darkTextSecondary,
            fontSize: 12,
          ),
        ),
      ],
    );
  }
}
