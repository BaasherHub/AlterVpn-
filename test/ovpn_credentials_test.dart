import 'package:flutter_test/flutter_test.dart';

import 'package:alter_vpn/core/utils/ovpn_credentials.dart';

void main() {
  group('OvpnCredentialsExtractor', () {
    test('extracts credentials from env-style comments', () {
      const config = '''
# OVPN_ACCESS_SERVER_USERNAME=appuser_us
# OVPN_ACCESS_SERVER_PASSWORD=secret_pw
client
dev tun
proto udp
remote 1.2.3.4 1194
auth-user-pass
''';

      final creds = OvpnCredentialsExtractor.extract(
        config,
        defaultCredentials: const OvpnCredentials(
          username: 'vpn',
          password: 'vpn',
        ),
      );

      expect(creds.username, 'appuser_us');
      expect(creds.password, 'secret_pw');
    });

    test('extracts credentials from auth-user-pass inline form', () {
      const config = '''
client
dev tun
proto udp
remote 1.2.3.4 1194
auth-user-pass user1 pass1
''';

      final creds = OvpnCredentialsExtractor.extract(
        config,
        defaultCredentials: const OvpnCredentials(
          username: 'vpn',
          password: 'vpn',
        ),
      );

      expect(creds.username, 'user1');
      expect(creds.password, 'pass1');
    });

    test('falls back to defaults when credentials are missing', () {
      const config = '''
client
dev tun
proto udp
remote 1.2.3.4 1194
auth-user-pass
''';

      final creds = OvpnCredentialsExtractor.extract(
        config,
        defaultCredentials: const OvpnCredentials(
          username: 'vpn',
          password: 'vpn',
        ),
      );

      expect(creds.username, 'vpn');
      expect(creds.password, 'vpn');
    });
  });
}

