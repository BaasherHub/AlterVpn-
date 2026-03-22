import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_spacing.dart';
import '../../../core/constants/app_typography.dart';
import '../../../services/ads/ad_config.dart';
import '../../../services/ads/ad_service.dart';
import '../domain/session_controller.dart';

/// The rotating messages shown while an ad is loading or VPN is connecting.
const List<String> _loadingMessages = [
  'Brewing your free connection…',
  'Privacy loading…',
  'Almost there…',
  'Securing your tunnel…',
  'Good things come to those who wait…',
];

/// Shows the ad-gate bottom sheet.
///
/// Returns a tri-state [bool?]:
/// - `true`  — user watched the ad and earned a reward.
/// - `null`  — ad was unavailable; user chose to connect anyway (no reward).
/// - `false` — user skipped or dismissed without connecting.
Future<bool?> showAdGateDialog(BuildContext context) {
  return showModalBottomSheet<bool?>(
    context: context,
    backgroundColor: Colors.transparent,
    isScrollControlled: true,
    builder: (_) => const _AdGateSheet(),
  );
}

// ─── Bottom Sheet ───────────────────────────────────────────────────────────

class _AdGateSheet extends ConsumerStatefulWidget {
  const _AdGateSheet();

  @override
  ConsumerState<_AdGateSheet> createState() => _AdGateSheetState();
}

class _AdGateSheetState extends ConsumerState<_AdGateSheet> {
  bool _isLoading = false;
  bool _adUnavailable = false;
  int _msgIndex = 0;
  StreamSubscription<int>? _tickerSubscription;

  @override
  void dispose() {
    _tickerSubscription?.cancel();
    super.dispose();
  }

  void _nextMessage() {
    if (mounted) {
      setState(() {
        _msgIndex = (_msgIndex + 1) % _loadingMessages.length;
      });
    }
  }

  Future<void> _handleWatch() async {
    setState(() {
      _isLoading = true;
      _adUnavailable = false;
    });

    // Cycle loading messages while waiting.
    _tickerSubscription?.cancel();
    _tickerSubscription = Stream.periodic(
      const Duration(milliseconds: 1200),
      (i) => i,
    ).listen((_) => _nextMessage());

    final adService = ref.read(adServiceProvider);
    final bool rewarded;
    try {
      rewarded = await adService.showRewardedAd();
    } catch (_) {
      // Defensive: should never reach here since AdService already catches,
      // but guard anyway to prevent any uncaught exception reaching the UI.
      _tickerSubscription?.cancel();
      _tickerSubscription = null;
      if (mounted) {
        setState(() {
          _isLoading = false;
          _adUnavailable = true;
        });
      }
      return;
    }

    _tickerSubscription?.cancel();
    _tickerSubscription = null;

    if (!mounted) return;

    if (rewarded) {
      Navigator.of(context).pop(true);
    } else {
      // Ad closed without reward — let the user know.
      setState(() {
        _isLoading = false;
        _adUnavailable = true;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final session = ref.watch(sessionControllerProvider);
    final adsWatched = session.adsWatchedToday;
    final streakLeft = (AdConfig.streakThreshold - adsWatched).clamp(0, AdConfig.streakThreshold);

    // When ads are globally disabled, the sheet shows an informational notice
    // and a "Connect for Free" button that pops `null` (connect without reward).
    final bool adsDisabled = !AdConfig.adsEnabled || kIsWeb;

    return Container(
      decoration: const BoxDecoration(
        color: AppColors.darkSurface,
        borderRadius: BorderRadius.vertical(
          top: Radius.circular(AppSpacing.borderRadiusLg),
        ),
      ),
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.screenPadding,
        AppSpacing.lg,
        AppSpacing.screenPadding,
        AppSpacing.xl,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Drag handle
          Container(
            width: 36,
            height: 4,
            decoration: BoxDecoration(
              color: AppColors.darkBorder,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(height: AppSpacing.lg),

          // Ads-disabled / web-preview notice
          if (adsDisabled)
            Container(
              margin: const EdgeInsets.only(bottom: AppSpacing.md),
              padding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.md,
                vertical: AppSpacing.sm,
              ),
              decoration: BoxDecoration(
                color: AppColors.accentGold.withValues(alpha: 0.12),
                borderRadius:
                    BorderRadius.circular(AppSpacing.borderRadiusMd),
                border: Border.all(
                    color: AppColors.accentGold.withValues(alpha: 0.3)),
              ),
              child: Text(
                kIsWeb
                    ? 'Ads are disabled in web preview mode'
                    : 'Ads are not available right now',
                style: AppTypography.bodySmall(
                    color: AppColors.accentGold),
                textAlign: TextAlign.center,
              ),
            ),

          // Ad-unavailable notice (ads enabled but none loaded)
          if (!adsDisabled && _adUnavailable)
            Container(
              margin: const EdgeInsets.only(bottom: AppSpacing.md),
              padding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.md,
                vertical: AppSpacing.sm,
              ),
              decoration: BoxDecoration(
                color: AppColors.accentGreenLight.withValues(alpha: 0.12),
                borderRadius:
                    BorderRadius.circular(AppSpacing.borderRadiusMd),
              ),
              child: Text(
                'Ad unavailable right now. Please try again later.',
                style: AppTypography.bodySmall(
                    color: AppColors.accentGreenLight),
                textAlign: TextAlign.center,
              ),
            ),

          // Headline
          Text(
            'Watch a short video to connect for free',
            style: AppTypography.headingMedium(
                color: AppColors.darkText),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: AppSpacing.sm),
          Text(
            'Your privacy is worth 30 seconds',
            style: AppTypography.bodySmall(
                color: AppColors.darkTextSecondary),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: AppSpacing.lg),

          // Streak progress
          _StreakIndicator(
              adsWatched: adsWatched, streakLeft: streakLeft),
          const SizedBox(height: AppSpacing.lg),

          // Loading message
          AnimatedSwitcher(
            duration: const Duration(milliseconds: 400),
            child: _isLoading
                ? Text(
                    _loadingMessages[_msgIndex],
                    key: ValueKey(_msgIndex),
                    style: AppTypography.bodySmall(
                        color: AppColors.darkTextSecondary)
                        .copyWith(fontStyle: FontStyle.italic),
                    textAlign: TextAlign.center,
                  )
                : const SizedBox.shrink(),
          ),
          if (_isLoading) const SizedBox(height: AppSpacing.md),

          // Primary action button
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: _isLoading
                  ? null
                  : () {
                      if (adsDisabled || _adUnavailable) {
                        // Connect without granting a streak reward.
                        Navigator.of(context).pop(null);
                      } else {
                        _handleWatch();
                      }
                    },
              style: ElevatedButton.styleFrom(
                backgroundColor: (adsDisabled || _adUnavailable)
                    ? AppColors.accentGreenLight
                    : AppColors.accentGreen,
                foregroundColor: AppColors.darkText,
                padding: const EdgeInsets.symmetric(
                    vertical: AppSpacing.md),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(
                      AppSpacing.borderRadiusMd),
                ),
                elevation: 0,
              ),
              child: _isLoading
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: AppColors.darkText,
                      ),
                    )
                  : Text(
                      (adsDisabled || _adUnavailable)
                          ? 'Connect for Free'
                          : 'Watch & Connect',
                      style: AppTypography.labelLarge(
                          color: AppColors.darkText),
                    ),
            ),
          ),
          const SizedBox(height: AppSpacing.md),

          // Skip button (closes dialog, does NOT connect)
          GestureDetector(
            onTap: () => Navigator.of(context).pop(false),
            child: Text(
              'Skip',
              style: AppTypography.bodySmall(
                  color: AppColors.darkTextSecondary),
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Streak Indicator ────────────────────────────────────────────────────────

class _StreakIndicator extends StatelessWidget {
  final int adsWatched;
  final int streakLeft;

  const _StreakIndicator({
    required this.adsWatched,
    required this.streakLeft,
  });

  @override
  Widget build(BuildContext context) {
    final filled = adsWatched.clamp(0, AdConfig.streakThreshold);

    return Column(
      children: [
        Row(
          mainAxisSize: MainAxisSize.min,
          children: List.generate(AdConfig.streakThreshold, (i) {
            final active = i < filled;
            return Padding(
              padding: const EdgeInsets.symmetric(horizontal: 3),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 300),
                width: active ? 10 : 8,
                height: active ? 10 : 8,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: active
                      ? AppColors.accentGold
                      : AppColors.darkBorder,
                ),
              ),
            );
          }),
        ),
        const SizedBox(height: AppSpacing.xs),
        Text(
          streakLeft > 0
              ? '$filled/${AdConfig.streakThreshold} — watch $streakLeft more for 24-hour free pass!'
              : '🌟 Free pass active until midnight',
          style: AppTypography.bodySmall(
              color: AppColors.accentGold.withValues(alpha: 0.85)),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }
}
