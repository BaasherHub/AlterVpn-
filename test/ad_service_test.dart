import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:alter_vpn/services/ads/ad_service.dart';

// These tests exercise [AdService] logic that does NOT require the real
// Google Mobile Ads SDK to be initialized.  Paths that touch MobileAds or
// the native ad layer are not covered here because the SDK cannot be
// initialised in a pure-Dart test environment.

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('AdService — ads disabled path', () {
    test('showRewardedAd returns false immediately when adsEnabled=false', () async {
      final service = AdService(adsEnabled: false);
      final result = await service.showRewardedAd();
      expect(result, isFalse);
    });

    test('initialize() is a no-op when adsEnabled=false', () async {
      final service = AdService(adsEnabled: false);
      // Should complete without throwing even though the SDK is absent.
      await expectLater(service.initialize(), completes);
    });

    test('dispose() is safe to call without prior initialization', () {
      final service = AdService(adsEnabled: false);
      expect(() => service.dispose(), returnsNormally);
    });

    test('multiple showRewardedAd calls are safe and return false', () async {
      final service = AdService(adsEnabled: false);
      for (var i = 0; i < 3; i++) {
        final result = await service.showRewardedAd();
        expect(result, isFalse,
            reason: 'call $i should return false when ads disabled');
      }
    });
  });

  group('AdService — ad unavailable path (adsEnabled=true, no loaded ad)', () {
    // When adsEnabled=true but the SDK is absent in a test context the
    // initialize() call will throw; showRewardedAd() must catch that and
    // return false without propagating the exception.
    test('showRewardedAd returns false when SDK not available', () async {
      SharedPreferences.setMockInitialValues({});
      final service = AdService(adsEnabled: true);
      // initialize() will fail (no SDK in test env) — showRewardedAd should
      // still return false rather than throwing.
      final result = await service.showRewardedAd();
      expect(result, isFalse);
    });
  });

  group('AdService — dispose safety', () {
    test('dispose() is idempotent', () {
      final service = AdService(adsEnabled: false);
      service.dispose();
      expect(() => service.dispose(), returnsNormally);
    });
  });
}
