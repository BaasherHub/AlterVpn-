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

class ServerListScreen extends ConsumerStatefulWidget {
  const ServerListScreen({super.key});

  @override
  ConsumerState<ServerListScreen> createState() => _ServerListScreenState();
}

class _ServerListScreenState extends ConsumerState<ServerListScreen> {
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';

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
                final filtered = _searchQuery.isEmpty
                    ? servers
                    : servers
                        .where((s) =>
                            s.countryLong
                                .toLowerCase()
                                .contains(_searchQuery) ||
                            s.hostName.toLowerCase().contains(_searchQuery))
                        .toList();

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
                                Text(
                                  country,
                                  style: AppTypography.headingMedium(
                                      color: textColor),
                                ),
                                const SizedBox(width: 8),
                                Text(
                                  '(${countryServers.length})',
                                  style: AppTypography.bodySmall(
                                      color: secondaryColor),
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
