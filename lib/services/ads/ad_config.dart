// TODO: Replace test ad unit IDs with real production IDs before releasing.
// Test IDs are provided by Google and are safe to use during development.
class AdConfig {
  AdConfig._();

  // ─── Ad Unit IDs ───────────────────────────────────────────────────────────
  // TODO: Replace with your real Android Rewarded Ad Unit ID from AdMob console.
  static const String androidRewardedAdUnitId =
      'ca-app-pub-3940256099942544/5224354917';

  // TODO: Replace with your real iOS Rewarded Ad Unit ID from AdMob console.
  static const String iosRewardedAdUnitId =
      'ca-app-pub-3940256099942544/1712485313';

  // ─── Session Settings ──────────────────────────────────────────────────────
  /// How long a VPN session lasts after watching a rewarded ad (2 hours).
  static const int sessionDurationSeconds = 7200;

  /// Number of ads a user must watch in one day to earn a 24-hour free pass.
  static const int streakThreshold = 3;

  /// Minimum gap between showing two rewarded ads (seconds).
  static const int adCooldownSeconds = 5;
}
