import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../data/server_model.dart';
import '../domain/server_controller.dart';
import '../../connection/domain/connection_controller.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_typography.dart';
import '../../../core/constants/app_spacing.dart';
import '../../../core/constants/app_strings.dart';
import '../../../widgets/alter_app_bar.dart';
import 'server_tile.dart';

// ---------------------------------------------------------------------------
// Region filter
// ---------------------------------------------------------------------------

enum _Region { all, europe, americas, asia, other }

const _regionLabels = {
  _Region.all: 'All',
  _Region.europe: 'Europe',
  _Region.americas: 'Americas',
  _Region.asia: 'Asia',
  _Region.other: 'Other',
};

// ISO 3166-1 alpha-2 codes per region
const _europeCodes = {
  'AL', 'AD', 'AM', 'AT', 'AZ', 'BY', 'BE', 'BA', 'BG', 'HR',
  'CY', 'CZ', 'DK', 'EE', 'FI', 'FR', 'GE', 'DE', 'GR', 'HU',
  'IS', 'IE', 'IT', 'KZ', 'XK', 'LV', 'LI', 'LT', 'LU', 'MT',
  'MD', 'MC', 'ME', 'NL', 'MK', 'NO', 'PL', 'PT', 'RO', 'RU',
  'SM', 'RS', 'SK', 'SI', 'ES', 'SE', 'CH', 'TR', 'UA', 'GB',
  'VA',
};

const _americasCodes = {
  'AG', 'AR', 'AW', 'BS', 'BB', 'BZ', 'BO', 'BR', 'CA', 'CL',
  'CO', 'CR', 'CU', 'DM', 'DO', 'EC', 'SV', 'GD', 'GT', 'GY',
  'HT', 'HN', 'JM', 'MX', 'NI', 'PA', 'PY', 'PE', 'KN', 'LC',
  'VC', 'SR', 'TT', 'US', 'UY', 'VE',
};

const _asiaCodes = {
  'AF', 'AM', 'AZ', 'BH', 'BD', 'BT', 'BN', 'KH', 'CN', 'CY',
  'GE', 'IN', 'ID', 'IR', 'IQ', 'IL', 'JP', 'JO', 'KZ', 'KW',
  'KG', 'LA', 'LB', 'MY', 'MV', 'MN', 'MM', 'NP', 'KP', 'OM',
  'PK', 'PS', 'PH', 'QA', 'SA', 'SG', 'KR', 'LK', 'SY', 'TW',
  'TJ', 'TH', 'TL', 'TM', 'AE', 'UZ', 'VN', 'YE',
};

_Region _regionFor(ServerModel s) {
  // Prefer the backend-supplied region tag when available.
  if (s.region.isNotEmpty) {
    switch (s.region.toUpperCase()) {
      case 'EU':
        return _Region.europe;
      case 'US':
      case 'AM':
        return _Region.americas;
      case 'AS':
      case 'ME':
        return _Region.asia;
    }
  }

  final code = s.countryShort.toUpperCase();
  if (_europeCodes.contains(code)) return _Region.europe;
  if (_americasCodes.contains(code)) return _Region.americas;
  if (_asiaCodes.contains(code)) return _Region.asia;
  return _Region.other;
}

// ---------------------------------------------------------------------------

class ServerListScreen extends ConsumerStatefulWidget {
  const ServerListScreen({super.key});

  @override
  ConsumerState<ServerListScreen> createState() => _ServerListScreenState();
}

class _ServerListScreenState extends ConsumerState<ServerListScreen> {
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';
  _Region _region = _Region.all;

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final serversAsync = ref.watch(serverControllerProvider);
    final selectedServer = ref.watch(selectedServerProvider);
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bgColor =
        isDark ? AppColors.darkBackground : AppColors.lightBackground;
    final borderColor =
        isDark ? AppColors.darkBorder : AppColors.lightBorder;
    final textColor = isDark ? AppColors.darkText : AppColors.lightText;
    final secondaryColor =
        isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary;

    return Scaffold(
      appBar: AlterAppBar(title: AppStrings.serversTitle),
      body: Column(
        children: [
          // Search bar
          Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.screenPadding,
              vertical: AppSpacing.md,
            ),
            child: TextField(
              controller: _searchController,
              onChanged: (v) => setState(() => _searchQuery = v.toLowerCase()),
              style: AppTypography.bodyMedium(color: textColor),
              decoration: InputDecoration(
                hintText: AppStrings.searchPlaceholder,
                hintStyle: AppTypography.bodyMedium(color: secondaryColor),
                border: UnderlineInputBorder(
                  borderSide: BorderSide(color: borderColor),
                ),
                enabledBorder: UnderlineInputBorder(
                  borderSide: BorderSide(color: borderColor),
                ),
                focusedBorder: const UnderlineInputBorder(
                  borderSide:
                      BorderSide(color: AppColors.accentGold, width: 1),
                ),
                prefixIcon: Icon(Icons.search, color: secondaryColor, size: 18),
                contentPadding: const EdgeInsets.symmetric(vertical: 12),
              ),
            ),
          ),
          // Region filter chips
          SizedBox(
            height: 36,
            child: ListView(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(
                  horizontal: AppSpacing.screenPadding),
              children: _Region.values.map((r) {
                final selected = _region == r;
                return Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: GestureDetector(
                    onTap: () => setState(() => _region = r),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 150),
                      padding: const EdgeInsets.symmetric(
                          horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        color: selected
                            ? AppColors.accentGold
                            : Colors.transparent,
                        border: Border.all(
                          color: selected
                              ? AppColors.accentGold
                              : borderColor,
                        ),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        _regionLabels[r]!,
                        style: AppTypography.bodySmall(
                          color: selected
                              ? AppColors.darkBackground
                              : secondaryColor,
                        ),
                      ),
                    ),
                  ),
                );
              }).toList(),
            ),
          ),
          const SizedBox(height: 8),
          Expanded(
            child: serversAsync.when(
              loading: () => Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const CircularProgressIndicator(
                      color: AppColors.accentGold,
                      strokeWidth: 1.5,
                    ),
                    const SizedBox(height: 16),
                    Text(
                      AppStrings.loadingServers,
                      style: AppTypography.bodySmall(color: secondaryColor),
                    ),
                  ],
                ),
              ),
              error: (e, _) => Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      AppStrings.errorTitle,
                      style: AppTypography.bodyMedium(color: textColor),
                    ),
                    const SizedBox(height: 8),
                    Padding(
                      padding: const EdgeInsets.symmetric(
                          horizontal: AppSpacing.screenPadding),
                      child: Text(
                        e.toString(),
                        style: AppTypography.bodySmall(color: secondaryColor),
                        textAlign: TextAlign.center,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Check your internet connection and try again.',
                      style: AppTypography.bodySmall(color: secondaryColor),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 16),
                    TextButton(
                      onPressed: () =>
                          ref.read(serverControllerProvider.notifier).refresh(),
                      child: Text(
                        AppStrings.errorRetry,
                        style: AppTypography.bodyMedium(
                            color: AppColors.accentGold),
                      ),
                    ),
                  ],
                ),
              ),
              data: (servers) {
                // Apply search filter
                var filtered = _searchQuery.isEmpty
                    ? servers
                    : servers
                        .where((s) =>
                            s.countryLong
                                .toLowerCase()
                                .contains(_searchQuery) ||
                            s.city
                                .toLowerCase()
                                .contains(_searchQuery) ||
                            s.displayName
                                .toLowerCase()
                                .contains(_searchQuery))
                        .toList();

                // Apply region filter
                if (_region != _Region.all) {
                  filtered = filtered
                      .where((s) => _regionFor(s) == _region)
                      .toList();
                }

                if (filtered.isEmpty) {
                  return Center(
                    child: Text(
                      AppStrings.noServers,
                      style: AppTypography.bodyMedium(color: secondaryColor),
                    ),
                  );
                }

                final repo = ref.read(serverRepositoryProvider);
                final grouped = repo.groupByCountry(filtered);

                return RefreshIndicator(
                  onRefresh: () =>
                      ref.read(serverControllerProvider.notifier).refresh(),
                  color: AppColors.accentGold,
                  backgroundColor: bgColor,
                  child: ListView.builder(
                    padding: const EdgeInsets.symmetric(
                        horizontal: AppSpacing.screenPadding),
                    itemCount: grouped.length,
                    itemBuilder: (context, index) {
                      final country = grouped.keys.elementAt(index);
                      final countryServers = grouped[country]!;
                      final firstServer = countryServers.first;
                      final connectableCount =
                          countryServers.where((s) => s.hasConfig).length;

                      return Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Padding(
                            padding: const EdgeInsets.only(
                                top: AppSpacing.lg, bottom: AppSpacing.sm),
                            child: Row(
                              children: [
                                Text(
                                  firstServer.countryFlag,
                                  style: const TextStyle(fontSize: 16),
                                ),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: Text(
                                    country,
                                    style: AppTypography.headingMedium(
                                        color: textColor),
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Text(
                                  connectableCount == 0
                                      ? 'None available'
                                      : '$connectableCount / ${countryServers.length}',
                                  style: AppTypography.bodySmall(
                                    color: connectableCount == 0
                                        ? secondaryColor.withValues(alpha: 0.5)
                                        : secondaryColor,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          ...countryServers.map((server) => ServerTile(
                                server: server,
                                isSelected: selectedServer?.hostName ==
                                    server.hostName,
                                onTap: () => _selectServer(server),
                              )),
                          Divider(color: borderColor, height: 1),
                        ],
                      );
                    },
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  void _selectServer(ServerModel server) {
    ref.read(connectionControllerProvider.notifier).selectServer(server);
    Navigator.of(context).pop();
  }
}
