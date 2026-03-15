import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:package_info_plus/package_info_plus.dart';
import '../domain/preferences_controller.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_typography.dart';
import '../../../core/constants/app_spacing.dart';
import '../../../core/constants/app_strings.dart';
import '../../../widgets/alter_app_bar.dart';

class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final prefs = ref.watch(preferencesControllerProvider);
    final controller = ref.read(preferencesControllerProvider.notifier);
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textColor = isDark ? AppColors.darkText : AppColors.lightText;
    final secondaryColor =
        isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary;

    return Scaffold(
      appBar: AlterAppBar(title: AppStrings.settingsTitle),
      body: ListView(
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.screenPadding,
          vertical: AppSpacing.lg,
        ),
        children: [
          _SectionHeader(title: AppStrings.connectionSection),
          const SizedBox(height: AppSpacing.md),
          _SettingRow(
            label: AppStrings.killSwitch,
            subtitle: AppStrings.killSwitchSubtitle,
            trailing: Switch(
              value: prefs.isKillSwitchEnabled,
              onChanged: (_) => controller.toggleKillSwitch(),
            ),
            textColor: textColor,
            subtitleColor: secondaryColor,
          ),
          const SizedBox(height: AppSpacing.lg),
          _SettingRow(
            label: AppStrings.autoConnect,
            subtitle: AppStrings.autoConnectSubtitle,
            trailing: Switch(
              value: prefs.isAutoConnectEnabled,
              onChanged: (_) => controller.toggleAutoConnect(),
            ),
            textColor: textColor,
            subtitleColor: secondaryColor,
          ),
          const SizedBox(height: AppSpacing.sectionGap),
          _SectionHeader(title: AppStrings.appearanceSection),
          const SizedBox(height: AppSpacing.md),
          _SettingRow(
            label: AppStrings.darkMode,
            subtitle: AppStrings.darkModeSubtitle,
            trailing: Switch(
              value: prefs.isDarkMode,
              onChanged: (_) => controller.toggleDarkMode(),
            ),
            textColor: textColor,
            subtitleColor: secondaryColor,
          ),
          const SizedBox(height: AppSpacing.sectionGap),
          _SectionHeader(title: AppStrings.aboutSection),
          const SizedBox(height: AppSpacing.md),
          FutureBuilder<PackageInfo>(
            future: PackageInfo.fromPlatform(),
            builder: (context, snapshot) {
              final version = snapshot.data?.version ?? '1.0.0';
              return _SettingRow(
                label: AppStrings.version,
                subtitle: version,
                trailing: const SizedBox.shrink(),
                textColor: textColor,
                subtitleColor: secondaryColor,
              );
            },
          ),
          const SizedBox(height: AppSpacing.lg),
          _SettingRow(
            label: AppStrings.licenses,
            subtitle: '',
            trailing: Icon(
              Icons.chevron_right,
              color: secondaryColor,
              size: 18,
            ),
            onTap: () => showLicensePage(context: context),
            textColor: textColor,
            subtitleColor: secondaryColor,
          ),
          const SizedBox(height: AppSpacing.xxl),
          Center(
            child: Text(
              AppStrings.madeWith,
              style: AppTypography.bodySmall(color: secondaryColor),
            ),
          ),
          const SizedBox(height: AppSpacing.lg),
        ],
      ),
    );
  }
}

class _SectionHeader extends StatelessWidget {
  final String title;

  const _SectionHeader({required this.title});

  @override
  Widget build(BuildContext context) {
    return Text(
      title.toUpperCase(),
      style: AppTypography.labelLarge(
        color: AppColors.accentGold,
      ).copyWith(fontSize: 11, letterSpacing: 2),
    );
  }
}

class _SettingRow extends StatelessWidget {
  final String label;
  final String subtitle;
  final Widget trailing;
  final VoidCallback? onTap;
  final Color textColor;
  final Color subtitleColor;

  const _SettingRow({
    required this.label,
    required this.subtitle,
    required this.trailing,
    required this.textColor,
    required this.subtitleColor,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: AppTypography.bodyMedium(color: textColor),
                ),
                if (subtitle.isNotEmpty) ...[
                  const SizedBox(height: 2),
                  Text(
                    subtitle,
                    style: AppTypography.bodySmall(color: subtitleColor),
                  ),
                ],
              ],
            ),
          ),
          trailing,
        ],
      ),
    );
  }
}
