import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../connection/domain/connection_controller.dart';
import '../../connection/domain/connection_state.dart';
import '../../connection/domain/session_controller.dart';
import '../../connection/presentation/connection_button.dart';
import '../../connection/presentation/connection_status_bar.dart';
import '../../servers/domain/server_controller.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_typography.dart';
import '../../../core/constants/app_spacing.dart';
import '../../../core/constants/app_strings.dart';
import '../../../core/utils/formatters.dart';
import '../../../services/ads/ad_config.dart';
import '../../../widgets/alter_logo_mark.dart';

class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final connectionState = ref.watch(connectionControllerProvider);
    final sessionData = ref.watch(sessionControllerProvider);
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
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      AlterLogoMark(size: 36),
                      const SizedBox(width: AppSpacing.sm),
                      Text(
                        AppStrings.appName,
                        style: AppTypography.headingLarge(color: textColor),
                      ),
                    ],
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

            // Ad streak / free-pass indicator
            _StreakBar(
              sessionData: sessionData,
              secondaryColor: secondaryColor,
            ),

            // Web preview notice
            if (kIsWeb)
              Padding(
                padding: const EdgeInsets.symmetric(
                    horizontal: AppSpacing.screenPadding,
                    vertical: AppSpacing.xs),
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppSpacing.md,
                    vertical: AppSpacing.xs,
                  ),
                  decoration: BoxDecoration(
                    color: AppColors.accentGold.withValues(alpha: 0.10),
                    borderRadius: BorderRadius.circular(
                        AppSpacing.borderRadiusMd),
                    border: Border.all(
                        color: AppColors.accentGold.withValues(alpha: 0.25)),
                  ),
                  child: Text(
                    'Ads are disabled in web preview mode',
                    style: AppTypography.bodySmall(
                        color: AppColors.accentGold),
                    textAlign: TextAlign.center,
                  ),
                ),
              ),

            // Connection ring area
            Expanded(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const ConnectionButton(),
                  const SizedBox(height: AppSpacing.xl),

                  // Session timer shown when connected
                  AnimatedOpacity(
                    duration: const Duration(milliseconds: 300),
                    opacity: connectionState.isConnected &&
                            sessionData.sessionState == SessionState.active
                        ? 1.0
                        : 0.0,
                    child: Column(
                      children: [
                        Text(
                          sessionData.formattedRemaining,
                          style: AppTypography.monoLarge(color: textColor),
                        ),
                        const SizedBox(height: AppSpacing.xs),
                        Text(
                          'Session expires in…',
                          style: AppTypography.bodySmall(
                              color: secondaryColor),
                        ),
                      ],
                    ),
                  ),

                  // Connection duration timer (when connected, no session)
                  if (connectionState.isConnected &&
                      sessionData.sessionState != SessionState.active)
                    Text(
                      Formatters.formatDuration(
                          connectionState.connectionDuration),
                      style: AppTypography.monoLarge(color: textColor),
                    ),

                  // Status text when not connected
                  if (!connectionState.isConnected)
                    Text(
                      _getStatusText(
                          connectionState, sessionData,
                          noServers: _noHealthyServers(ref)),
                      style: AppTypography.bodySmall(
                          color: secondaryColor),
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

  String _getStatusText(
      AlterConnectionState state, SessionData sessionData,
      {bool noServers = false}) {
    switch (state.status) {
      case ConnectionStatus.connecting:
        return state.vpnStage.displayName;
      case ConnectionStatus.disconnecting:
        return AppStrings.disconnecting;
      case ConnectionStatus.error:
        return state.errorMessage ?? AppStrings.connectionFailed;
      default:
        if (noServers) return AppStrings.noHealthyServers;
        if (state.selectedServer == null) return AppStrings.selectServer;
        if (sessionData.hasFreePass) return 'Connect Free';
        return 'Watch Ad & Connect';
    }
  }

  /// Returns `true` when the server list has loaded but contains no healthy
  /// US servers, so the connect button should be blocked.
  static bool _noHealthyServers(WidgetRef ref) {
    final serversAsync = ref.watch(serverControllerProvider);
    return serversAsync.whenOrNull(data: (servers) => servers.isEmpty) == true;
  }
}

// ─── Streak bar ──────────────────────────────────────────────────────────────

class _StreakBar extends StatelessWidget {
  final SessionData sessionData;
  final Color secondaryColor;

  const _StreakBar({
    required this.sessionData,
    required this.secondaryColor,
  });

  @override
  Widget build(BuildContext context) {
    if (sessionData.hasFreePass) {
      return Padding(
        padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.screenPadding,
            vertical: AppSpacing.xs),
        child: Text(
          '🌟 Free pass active until midnight',
          style: AppTypography.bodySmall(
              color: AppColors.accentGold),
          textAlign: TextAlign.center,
        ),
      );
    }

    final watched = sessionData.adsWatchedToday
        .clamp(0, AdConfig.streakThreshold);
    final remaining = AdConfig.streakThreshold - watched;

    return Padding(
      padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.screenPadding,
          vertical: AppSpacing.xs),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          ...List.generate(AdConfig.streakThreshold, (i) {
            final active = i < watched;
            return Padding(
              padding: const EdgeInsets.symmetric(horizontal: 3),
              child: Container(
                width: active ? 8 : 6,
                height: active ? 8 : 6,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: active
                      ? AppColors.accentGold
                      : AppColors.darkBorder,
                ),
              ),
            );
          }),
          const SizedBox(width: AppSpacing.sm),
          Text(
            '$watched/${AdConfig.streakThreshold} — '
            '${remaining > 0 ? 'watch $remaining more for 24 hr pass' : '🌟 Free pass earned!'}',
            style: AppTypography.bodySmall(color: secondaryColor),
          ),
        ],
      ),
    );
  }
}

// ─── Server selector ─────────────────────────────────────────────────────────

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

