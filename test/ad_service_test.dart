import 'package:flutter_test/flutter_test.dart';
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

  // The "SDK not available" path (adsEnabled=true, no native plugin) cannot be
  // reliably unit-tested: MissingPluginException from MethodChannel propagates
  // to the test zone before our catch runs. AdService.initialize() and
  // showRewardedAd() handle it in production; verify via integration tests.

  group('AdService — dispose safety', () {
    test('dispose() is idempotent', () {
      final service = AdService(adsEnabled: false);
      service.dispose();
      expect(() => service.dispose(), returnsNormally);
    });
  });
}
