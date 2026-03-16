import 'package:flutter/material.dart';
import '../data/server_model.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_strings.dart';
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
              if (isSelected)
                Container(
                  width: 6,
                  height: 6,
                  margin: const EdgeInsets.only(right: 12),
                  decoration: const BoxDecoration(
                    color: AppColors.accentGreen,
                    shape: BoxShape.circle,
                  ),
                )
              else
                const SizedBox(width: 18),
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
                    Row(
                      children: [
                        Text(
                          '${server.numVpnSessions} ${AppStrings.sessions}',
                          style:
                              AppTypography.bodySmall(color: secondaryColor),
                        ),
                        if (!connectable) ...[
                          const SizedBox(width: 6),
                          Text(
                            '· Unavailable',
                            style: AppTypography.bodySmall(
                                color: unavailableColor),
                          ),
                        ],
                      ],
                    ),
                  ],
                ),
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    Formatters.formatPing(server.ping),
                    style: AppTypography.mono(
                      color: _pingColor(server.ping),
                      fontSize: 12,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    Formatters.formatSpeed(server.speedMbps),
                    style: AppTypography.mono(
                      color: secondaryColor,
                      fontSize: 11,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Color _pingColor(int ping) {
    if (ping <= 0) return AppColors.darkTextSecondary;
    if (ping < 50) return AppColors.accentGreen;
    if (ping < 150) return AppColors.accentGold;
    return const Color(0xFF8B2E2E);
  }
}
