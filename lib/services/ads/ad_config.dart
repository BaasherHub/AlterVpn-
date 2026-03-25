// TODO: Replace test ad unit IDs with real production IDs before releasing.
// Test IDs are provided by Google and are safe to use during development.
class AdConfig {
  AdConfig._();

  // ─── Feature flag ──────────────────────────────────────────────────────────
  /// Master switch for the rewarded-ad flow.
  ///
  /// Set to `true` once your AdMob account and ad units are fully configured.
  /// While `false` the ad-gate dialog is bypassed and users can connect
  /// without watching an ad, so the VPN remains usable during development
  /// and before ad accounts are wired up.
  ///
  // TODO: Set to `true` when AdMob is fully configured and tested.
  static const bool adsEnabled = false;

  // ─── Ad Unit IDs ───────────────────────────────────────────────────────────
  // TODO: Replace with your real Android Rewarded Ad Unit ID from AdMob console.
  static const String androidRewardedAdUnitId =
      'ca-app-pub-3940256099942544/5224354917';

  // TODO: Replace with your real iOS Rewarded Ad Unit ID from AdMob console.
  static const String iosRewardedAdUnitId =
      'ca-app-pub-8231561205304402/4438704038';

  // ─── Session Settings ──────────────────────────────────────────────────────
  /// How long a VPN session lasts after watching a rewarded ad (2 hours).
  static const int sessionDurationSeconds = 7200;

  /// Number of ads a user must watch in one day to earn a 24-hour free pass.
  static const int streakThreshold = 3;

  /// Minimum gap between showing two rewarded ads (seconds).
  static const int adCooldownSeconds = 5;
}
