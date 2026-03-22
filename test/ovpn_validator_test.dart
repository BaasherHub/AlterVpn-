import 'package:flutter_test/flutter_test.dart';
import 'package:alter_vpn/core/utils/ovpn_validator.dart';

// Minimal valid OpenVPN config used as a base for tests.
const _validConfig = '''
client
dev tun
proto udp
remote 1.2.3.4 1194
resolv-retry infinite
nobind
persist-key
persist-tun
<ca>
-----BEGIN CERTIFICATE-----
MIID...
-----END CERTIFICATE-----
</ca>
verb 3
''';

void main() {
  group('OvpnValidator', () {
    test('accepts a valid config', () {
      final result = OvpnValidator.validate(_validConfig);
      expect(result.isValid, isTrue);
      expect(result.errorMessage, isNull);
    });

    test('rejects null config', () {
      final result = OvpnValidator.validate(null);
      expect(result.isValid, isFalse);
      expect(result.errorMessage, isNotNull);
      expect(result.errorMessage!.toLowerCase(), contains('empty'));
    });

    test('rejects empty string config', () {
      final result = OvpnValidator.validate('');
      expect(result.isValid, isFalse);
      expect(result.errorMessage, isNotNull);
    });

    test('rejects whitespace-only config', () {
      final result = OvpnValidator.validate('   \n  \t  ');
      expect(result.isValid, isFalse);
    });

    test('rejects config missing "remote" directive', () {
      final noRemote = _validConfig.replaceAll(RegExp(r'remote\s+\S+ \S+\n'), '');
      final result = OvpnValidator.validate(noRemote);
      expect(result.isValid, isFalse);
      expect(result.errorMessage!.toLowerCase(), contains('remote'));
      expect(result.missingDirectives, contains('remote'));
    });

    test('rejects config missing "proto" directive', () {
      final noProto = _validConfig.replaceAll(RegExp(r'proto \w+\n'), '');
      final result = OvpnValidator.validate(noProto);
      expect(result.isValid, isFalse);
      expect(result.errorMessage!.toLowerCase(), contains('proto'));
      expect(result.missingDirectives, contains('proto'));
    });

    test('rejects config missing "dev" directive', () {
      final noDev = _validConfig.replaceAll(RegExp(r'dev \w+\n'), '');
      final result = OvpnValidator.validate(noDev);
      expect(result.isValid, isFalse);
      expect(result.errorMessage!.toLowerCase(), contains('dev'));
      expect(result.missingDirectives, contains('dev'));
    });

    test('rejects config with no auth/cert material', () {
      final noAuth = _validConfig
          .replaceAll('<ca>', '')
          .replaceAll('</ca>', '')
          .replaceAll('-----BEGIN CERTIFICATE-----', '')
          .replaceAll('-----END CERTIFICATE-----', '')
          .replaceAll('MIID...', '');
      final result = OvpnValidator.validate(noAuth);
      expect(result.isValid, isFalse);
      expect(result.errorMessage!.toLowerCase(), contains('authentication'));
    });

    test('accepts config with auth-user-pass instead of ca block', () {
      final authUserPass = '''
client
dev tun
proto tcp
remote 5.6.7.8 443
auth-user-pass
''';
      final result = OvpnValidator.validate(authUserPass);
      expect(result.isValid, isTrue);
    });

    test('accepts config with tls-auth block', () {
      final tlsAuth = '''
client
dev tun
proto udp
remote 9.10.11.12 1194
<tls-auth>
-----BEGIN OpenVPN Static key V1-----
somekey
-----END OpenVPN Static key V1-----
</tls-auth>
''';
      final result = OvpnValidator.validate(tlsAuth);
      expect(result.isValid, isTrue);
    });

    test('accepts config with tls-crypt block', () {
      final tlsCrypt = '''
client
dev tun
proto udp
remote 9.10.11.12 1194
<tls-crypt>
somekey
</tls-crypt>
''';
      final result = OvpnValidator.validate(tlsCrypt);
      expect(result.isValid, isTrue);
    });

    test('validation result ok() has isValid=true and null errorMessage', () {
      final r = OvpnValidationResult.ok();
      expect(r.isValid, isTrue);
      expect(r.errorMessage, isNull);
      expect(r.missingDirectives, isEmpty);
    });

    test('validation result fail() has isValid=false and non-null errorMessage', () {
      final r = OvpnValidationResult.fail('test error');
      expect(r.isValid, isFalse);
      expect(r.errorMessage, 'test error');
      expect(r.missingDirectives, isEmpty);
    });

    test('validation result fail() populates missingDirectives when provided', () {
      final r = OvpnValidationResult.fail(
        'missing proto',
        missingDirectives: ['proto'],
      );
      expect(r.isValid, isFalse);
      expect(r.missingDirectives, ['proto']);
    });
  });
}
