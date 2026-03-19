import 'package:flutter_test/flutter_test.dart';
import 'package:alter_vpn/core/utils/vpn_error_mapper.dart';

void main() {
  group('VpnErrorMapper', () {
    test('maps empty-config error to invalidProfile', () {
      final result = VpnErrorMapper.map('OpenVPN config is empty — cannot connect.');
      expect(result.category, VpnErrorCategory.invalidProfile);
      expect(result.userMessage, isNotEmpty);
    });

    test('maps missing directive error to invalidProfile', () {
      final result = VpnErrorMapper.map(
        'Server profile is invalid: missing required directive "remote".',
      );
      expect(result.category, VpnErrorCategory.invalidProfile);
    });

    test('maps missing auth material to invalidProfile', () {
      final result = VpnErrorMapper.map(
        'Server profile is missing authentication material.',
      );
      expect(result.category, VpnErrorCategory.invalidProfile);
    });

    test('maps auth keyword to authFailure', () {
      final result = VpnErrorMapper.map('AUTH_FAILED: bad credentials');
      expect(result.category, VpnErrorCategory.authFailure);
    });

    test('maps TLS handshake error to authFailure', () {
      final result = VpnErrorMapper.map('TLS handshake failed');
      expect(result.category, VpnErrorCategory.authFailure);
    });

    test('maps timeout error to networkUnreachable', () {
      final result = VpnErrorMapper.map('Connection timed out after 30s');
      expect(result.category, VpnErrorCategory.networkUnreachable);
    });

    test('maps "unable to reach" error to networkUnreachable', () {
      final result = VpnErrorMapper.map(
        'Unable to reach the server-list backend. Please check your internet connection.',
      );
      expect(result.category, VpnErrorCategory.networkUnreachable);
    });

    test('maps network error keyword to networkUnreachable', () {
      final result = VpnErrorMapper.map('Network error: no route to host');
      expect(result.category, VpnErrorCategory.networkUnreachable);
    });

    test('maps connection refused to serverUnavailable', () {
      final result = VpnErrorMapper.map('Connection refused by remote host');
      expect(result.category, VpnErrorCategory.serverUnavailable);
    });

    test('maps permission denied to permissionDenied', () {
      final result = VpnErrorMapper.map('VPN permission denied by user');
      expect(result.category, VpnErrorCategory.permissionDenied);
    });

    test('maps unknown error to unknown category', () {
      final result = VpnErrorMapper.map('Something completely unexpected happened');
      expect(result.category, VpnErrorCategory.unknown);
    });

    test('all mapped errors have non-empty userMessage', () {
      final errors = [
        'OpenVPN config is empty',
        'AUTH_FAILED',
        'timed out',
        'Connection refused',
        'permission denied',
        'totally unknown',
      ];
      for (final err in errors) {
        final result = VpnErrorMapper.map(err);
        expect(result.userMessage, isNotEmpty,
            reason: 'userMessage should not be empty for error: $err');
      }
    });

    test('MappedVpnError toString includes category', () {
      const err = MappedVpnError(VpnErrorCategory.authFailure, 'Auth failed');
      expect(err.toString(), contains('authFailure'));
    });
  });
}
