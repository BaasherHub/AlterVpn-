import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../connection/domain/connection_controller.dart';
import '../../connection/domain/connection_state.dart';
import '../../connection/presentation/connection_button.dart';
import '../../connection/presentation/connection_status_bar.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_typography.dart';
import '../../../core/constants/app_spacing.dart';
import '../../../core/constants/app_strings.dart';
import '../../../core/utils/formatters.dart';

class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final connectionState = ref.watch(connectionControllerProvider);
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textColor = isDark ? AppColors.darkText : AppColors.lightText;
    final secondaryColor =
        isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary;

    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            // Top bar
            Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.screenPadding,
                vertical: AppSpacing.lg,
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    AppStrings.appName,
                    style: AppTypography.headingLarge(color: textColor),
                  ),
                  IconButton(
                    icon: Icon(Icons.settings_outlined,
                        color: secondaryColor, size: 22),
                    onPressed: () =>
                        Navigator.of(context).pushNamed('/settings'),
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(
                      minWidth: 44,
                      minHeight: 44,
                    ),
                  ),
                ],
              ),
            ),

            // Connection ring area
            Expanded(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const ConnectionButton(),
                  const SizedBox(height: AppSpacing.xl),
                  // Timer shown when connected
                  AnimatedOpacity(
                    duration: const Duration(milliseconds: 300),
                    opacity: connectionState.isConnected ? 1.0 : 0.0,
                    child: Text(
                      Formatters.formatDuration(
                          connectionState.connectionDuration),
                      style: AppTypography.monoLarge(color: textColor),
                    ),
                  ),
                  if (!connectionState.isConnected)
                    Text(
                      _getStatusText(connectionState),
                      style: AppTypography.bodySmall(color: secondaryColor),
                    ),
                ],
              ),
            ),

            // Selected server selector
            Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.screenPadding,
              ),
              child: _ServerSelector(
                connectionState: connectionState,
                textColor: textColor,
                secondaryColor: secondaryColor,
              ),
            ),

            const SizedBox(height: AppSpacing.lg),
            const ConnectionStatusBar(),
            const SizedBox(height: AppSpacing.xl),
          ],
        ),
      ),
    );
  }

  String _getStatusText(AlterConnectionState state) {
    switch (state.status) {
      case ConnectionStatus.connecting:
        return state.vpnStage.displayName;
      case ConnectionStatus.disconnecting:
        return AppStrings.disconnecting;
      case ConnectionStatus.error:
        return state.errorMessage ?? AppStrings.connectionFailed;
      default:
        return state.selectedServer == null
            ? AppStrings.selectServer
            : AppStrings.tapToConnect;
    }
  }
}

class _ServerSelector extends ConsumerWidget {
  final AlterConnectionState connectionState;
  final Color textColor;
  final Color secondaryColor;

  const _ServerSelector({
    required this.connectionState,
    required this.textColor,
    required this.secondaryColor,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final server = connectionState.selectedServer;

    return GestureDetector(
      onTap: () => Navigator.of(context).pushNamed('/servers'),
      behavior: HitTestBehavior.opaque,
      child: Container(
        height: AppSpacing.minTouchTarget,
        padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            if (server != null) ...[
              Text(
                server.countryFlag,
                style: const TextStyle(fontSize: 18),
              ),
              const SizedBox(width: 10),
              Flexible(
                child: Text(
                  '${server.countryLong} — ${server.hostName}',
                  style: AppTypography.bodyMedium(color: textColor),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ] else ...[
              Text(
                AppStrings.selectServer,
                style: AppTypography.bodyMedium(color: secondaryColor),
              ),
            ],
            const SizedBox(width: 6),
            Icon(Icons.chevron_right, color: secondaryColor, size: 16),
          ],
        ),
      ),
    );
  }
}
