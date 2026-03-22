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
/// always returns `false` so the ad-unavailable path is exercised in preview.
class AdService {
  /// Whether the rewarded-ad feature is enabled.
  /// Defaults to [AdConfig.adsEnabled]; pass an explicit value in tests.
  final bool adsEnabled;

  AdService({this.adsEnabled = AdConfig.adsEnabled});

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
  /// Any SDK-level exception is caught and logged so the app never crashes.
  Future<void> initialize() async {
    if (kIsWeb || _isInitialized || !adsEnabled) return;
    _isInitialized = true;
    try {
      await MobileAds.instance.initialize();
      _preloadAd();
    } catch (e) {
      debugPrint('[AdService] SDK initialization failed: $e');
      _isInitialized = false; // allow retry on next call
    }
  }

  /// Pre-load a rewarded ad in the background.
  void _preloadAd() {
    if (kIsWeb || _isLoading || _rewardedAd != null || !adsEnabled) return;
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
          debugPrint('[AdService] Ad failed to load: $error');
          _isLoading = false;
          _rewardedAd = null;
        },
      ),
    );
  }

  /// Show the pre-loaded rewarded ad.
  ///
  /// Returns `true` **only** when the user earns a reward via the
  /// [onUserEarnedReward] callback.  All failure paths — SDK not ready,
  /// no ad loaded, show error, or any exception — return `false` so that
  /// the caller can surface a graceful "ads unavailable" message rather than
  /// silently granting a reward or crashing.
  Future<bool> showRewardedAd() async {
    // Feature flag off — ads not configured yet.
    if (!adsEnabled) return false;

    // On web, skip ads entirely.
    if (kIsWeb) return false;

    // Ensure the SDK is initialised.
    if (!_isInitialized) {
      try {
        await initialize();
      } catch (e) {
        debugPrint('[AdService] initialize() threw during showRewardedAd: $e');
        return false;
      }
    }

    final ad = _rewardedAd;
    if (ad == null) {
      // No ad loaded yet — trigger a background load for the next attempt.
      _preloadAd();
      return false;
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
        debugPrint('[AdService] Ad failed to show: $error');
        ad.dispose();
        _rewardedAd = null;
        _preloadAd();
        // Reward was NOT earned — return false so UI can show a message.
        if (!completer.isCompleted) completer.complete(false);
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
      debugPrint('[AdService] ad.show() threw: $e');
      ad.dispose();
      _rewardedAd = null;
      _preloadAd();
      return false;
    }

    return completer.future;
  }

  /// Release resources. Called by the Riverpod provider's [onDispose].
  void dispose() {
    _rewardedAd?.dispose();
    _rewardedAd = null;
  }
}
