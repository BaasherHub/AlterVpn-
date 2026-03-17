import 'package:flutter/material.dart';
import '../data/server_model.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_typography.dart';
import '../../../core/utils/formatters.dart';

class ServerTile extends StatelessWidget {
  final ServerModel server;
  final bool isSelected;
  final VoidCallback onTap;

  const ServerTile({
    super.key,
    required this.server,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textColor = isDark ? AppColors.darkText : AppColors.lightText;
    final secondaryColor =
        isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary;
    final unavailableColor = textColor.withValues(alpha: 0.35);

    final bool connectable = server.hasConfig;

    return GestureDetector(
      onTap: connectable ? onTap : null,
      behavior: HitTestBehavior.opaque,
      child: Opacity(
        opacity: connectable ? 1.0 : 0.45,
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 12),
          child: Row(
            children: [
              // Selection / health indicator dot
              _LeadingDot(
                isSelected: isSelected,
                health: server.health,
              ),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      server.displayName,
                      style: AppTypography.bodyMedium(
                          color: connectable ? textColor : unavailableColor),
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 2),
                    Text(
                      connectable
                          ? server.metaLine
                          : '${server.metaLine} · Unavailable',
                      style: AppTypography.bodySmall(color: secondaryColor),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
              // Right-side latency indicator (quick visual scan)
              Text(
                Formatters.formatPing(server.effectiveLatency),
                style: AppTypography.mono(
                  color: _latencyColor(server.effectiveLatency),
                  fontSize: 12,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Color _latencyColor(int ms) {
    if (ms <= 0) return AppColors.darkTextSecondary;
    if (ms < 50) return AppColors.accentGreen;
    if (ms < 150) return AppColors.accentGold;
    return const Color(0xFF8B2E2E);
  }
}

/// Leading dot: gold when selected, health-coloured when health is known,
/// otherwise an empty spacer so the tile rows stay aligned.
class _LeadingDot extends StatelessWidget {
  final bool isSelected;
  final String? health;

  const _LeadingDot({required this.isSelected, this.health});

  @override
  Widget build(BuildContext context) {
    Color? dotColor;
    if (isSelected) {
      dotColor = AppColors.accentGreen;
    } else if (health == ServerHealth.online) {
      dotColor = AppColors.accentGreen;
    } else if (health == ServerHealth.degraded) {
      dotColor = AppColors.accentGold;
    } else if (health == ServerHealth.offline) {
      dotColor = const Color(0xFF8B2E2E);
    }

    if (dotColor == null) return const SizedBox(width: 18);

    return Container(
      width: 6,
      height: 6,
      margin: const EdgeInsets.only(right: 12),
      decoration: BoxDecoration(
        color: dotColor,
        shape: BoxShape.circle,
      ),
    );
  }
}
