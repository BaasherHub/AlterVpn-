import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'ad_config.dart';

/// Riverpod provider that exposes the singleton [AdService].
final adServiceProvider = Provider<AdService>((ref) {
  final service = AdService();
  // Initialize the SDK lazily when the provider is first accessed.
  service.initialize();
  ref.onDispose(service.dispose);
  return service;
});

/// Manages the Google Mobile Ads lifecycle: initialization, pre-loading,
/// showing a rewarded video, and clean-up.
///
/// On web (`kIsWeb`), all ad operations are no-ops and [showRewardedAd]
/// always returns `true` so the rest of the flow works during web testing.
class AdService {
  RewardedAd? _rewardedAd;
  bool _isLoading = false;
  bool _isInitialized = false;

  /// The platform-correct rewarded ad unit ID.
  String get _adUnitId {
    if (defaultTargetPlatform == TargetPlatform.iOS) {
      return AdConfig.iosRewardedAdUnitId;
    }
    return AdConfig.androidRewardedAdUnitId;
  }

  /// Initialise the Mobile Ads SDK and pre-load the first rewarded ad.
  /// Safe to call multiple times — subsequent calls are no-ops.
  Future<void> initialize() async {
    if (kIsWeb || _isInitialized) return;
    _isInitialized = true;
    await MobileAds.instance.initialize();
    _preloadAd();
  }

  /// Pre-load a rewarded ad in the background.
  void _preloadAd() {
    if (kIsWeb || _isLoading || _rewardedAd != null) return;
    _isLoading = true;

    RewardedAd.load(
      adUnitId: _adUnitId,
      request: const AdRequest(),
      rewardedAdLoadCallback: RewardedAdLoadCallback(
        onAdLoaded: (ad) {
          _rewardedAd = ad;
          _isLoading = false;
        },
        onAdFailedToLoad: (error) {
          _isLoading = false;
          _rewardedAd = null;
        },
      ),
    );
  }

  /// Show the pre-loaded rewarded ad.
  ///
  /// Returns `true` when the user earns a reward, `false` if the user
  /// skipped/closed without earning, and `true` (fallback) when no ad could
  /// be loaded — so the user is never blocked from connecting.
  Future<bool> showRewardedAd() async {
    // On web, skip ads entirely — return true so the flow continues.
    if (kIsWeb) return true;

    // Ensure the SDK is initialised (idempotent). If initialization has not
    // finished yet the _rewardedAd will be null and we fail-open below.
    if (!_isInitialized) await initialize();

    final ad = _rewardedAd;
    if (ad == null) {
      // Ad failed to load → grant free connection so the user isn't blocked.
      _preloadAd();
      return true;
    }

    bool rewarded = false;
    final completer = Completer<bool>();

    ad.fullScreenContentCallback = FullScreenContentCallback(
      onAdDismissedFullScreenContent: (ad) {
        ad.dispose();
        _rewardedAd = null;
        // Pre-load the next ad immediately after dismissal.
        _preloadAd();
        if (!completer.isCompleted) completer.complete(rewarded);
      },
      onAdFailedToShowFullScreenContent: (ad, error) {
        ad.dispose();
        _rewardedAd = null;
        _preloadAd();
        if (!completer.isCompleted) completer.complete(true); // fail open
      },
    );

    try {
      await ad.show(
        onUserEarnedReward: (_, reward) {
          rewarded = true;
        },
      );
    } catch (e) {
      // ad.show() can throw if the Activity is gone or the ad is stale.
      // Fail open: dispose the ad, pre-load a fresh one, and let the user
      // through so a broken ad never blocks connectivity.
      debugPrint('[AdService] ad.show() threw: $e');
      ad.dispose();
      _rewardedAd = null;
      _preloadAd();
      return true;
    }

    return completer.future;
  }

  /// Release resources. Called by the Riverpod provider's [onDispose].
  void dispose() {
    _rewardedAd?.dispose();
    _rewardedAd = null;
  }
}
