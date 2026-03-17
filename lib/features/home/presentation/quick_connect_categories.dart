import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_spacing.dart';
import '../../../core/constants/app_typography.dart';
import '../../servers/data/server_model.dart';
import '../../servers/domain/server_controller.dart';
import '../../connection/domain/connection_controller.dart';

/// A horizontal scrollable row of quick-connect category pill buttons.
///
/// Each pill auto-selects the best matching server and triggers the normal
/// ad → connect flow (by delegating to [ConnectionController.selectServer]).
class QuickConnectCategories extends ConsumerWidget {
  const QuickConnectCategories({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final serversAsync = ref.watch(serverControllerProvider);

    return serversAsync.maybeWhen(
      data: (servers) {
        if (servers.isEmpty) return const SizedBox.shrink();
        return SizedBox(
          height: 36,
          child: ListView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.screenPadding),
            children: [
              _CategoryPill(
                icon: '⚡',
                label: 'Fast Streaming',
                onTap: () => _selectFastest(ref, servers),
              ),
              const SizedBox(width: AppSpacing.sm),
              _CategoryPill(
                icon: '📈',
                label: 'Best for Trading',
                onTap: () => _selectTrading(ref, servers),
              ),
              const SizedBox(width: AppSpacing.sm),
              _CategoryPill(
                icon: '🔒',
                label: 'Max Privacy',
                onTap: () => _selectMaxPrivacy(ref, servers),
              ),
              const SizedBox(width: AppSpacing.sm),
              _CategoryPill(
                icon: '🎮',
                label: 'Gaming',
                onTap: () => _selectFastest(ref, servers),
              ),
            ],
          ),
        );
      },
      orElse: () => const SizedBox.shrink(),
    );
  }

  // ── Server selection heuristics ──────────────────────────────────────────

  void _selectFastest(WidgetRef ref, List<ServerModel> servers) {
    final sorted = List<ServerModel>.from(servers)
      ..sort((a, b) => a.effectiveLatency.compareTo(b.effectiveLatency));
    _select(ref, sorted.first);
  }

  void _selectTrading(WidgetRef ref, List<ServerModel> servers) {
    const hubs = ['Singapore', 'Japan', 'Germany', 'Hong Kong'];
    final hub = servers.where((s) {
      return hubs.any((h) =>
          s.countryLong.contains(h) || s.countryShort.contains(h));
    }).toList();

    if (hub.isEmpty) {
      _selectFastest(ref, servers);
      return;
    }
    hub.sort((a, b) => a.effectiveLatency.compareTo(b.effectiveLatency));
    _select(ref, hub.first);
  }

  void _selectMaxPrivacy(WidgetRef ref, List<ServerModel> servers) {
    // Prefer servers with highest session count (popular = trusted).
    final sorted = List<ServerModel>.from(servers)
      ..sort((a, b) => b.numVpnSessions.compareTo(a.numVpnSessions));
    _select(ref, sorted.first);
  }

  void _select(WidgetRef ref, ServerModel server) {
    ref.read(connectionControllerProvider.notifier).selectServer(server);
  }
}

// ─── Pill button ─────────────────────────────────────────────────────────────

class _CategoryPill extends StatelessWidget {
  final String icon;
  final String label;
  final VoidCallback onTap;

  const _CategoryPill({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final borderColor =
        isDark ? AppColors.darkBorder : AppColors.lightBorder;
    final textColor =
        isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary;

    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.md,
          vertical: AppSpacing.xs,
        ),
        decoration: BoxDecoration(
          borderRadius:
              BorderRadius.circular(AppSpacing.borderRadiusLg),
          border: Border.all(color: borderColor),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(icon, style: const TextStyle(fontSize: 12)),
            const SizedBox(width: AppSpacing.xs),
            Text(
              label,
              style: AppTypography.bodySmall(color: textColor),
            ),
          ],
        ),
      ),
    );
  }
}
