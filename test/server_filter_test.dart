import 'package:flutter_test/flutter_test.dart';
import 'package:alter_vpn/features/servers/data/server_model.dart';
import 'package:alter_vpn/features/servers/data/server_repository.dart';

/// Minimal factory to build a [ServerModel] with controlled fields for tests.
ServerModel _makeServer({
  String countryShort = 'US',
  String? health,
  bool hasConfig = true,
  String id = 'srv1',
}) {
  return ServerModel(
    id: id,
    hostName: 'host.$id.example.com',
    ip: '1.2.3.4',
    countryLong: countryShort == 'US' ? 'United States' : countryShort,
    countryShort: countryShort,
    numVpnSessions: 10,
    ping: 50,
    speed: 1024 * 1024,
    // Provide a non-empty base64 blob so hasConfig returns true when asked.
    openVpnConfigDataBase64: hasConfig ? 'dGVzdA==' : '',
    supportsTcp: true,
    health: health,
  );
}

void main() {
  group('ServerRepository.isUsActive', () {
    test('accepts a US server with no health data', () {
      final server = _makeServer(countryShort: 'US', health: null);
      expect(ServerRepository.isUsActive(server), isTrue);
    });

    test('accepts a US server with health=online', () {
      final server = _makeServer(countryShort: 'US', health: ServerHealth.online);
      expect(ServerRepository.isUsActive(server), isTrue);
    });

    test('accepts a US server with health=degraded', () {
      final server = _makeServer(countryShort: 'US', health: ServerHealth.degraded);
      expect(ServerRepository.isUsActive(server), isTrue);
    });

    test('rejects a US server with health=offline', () {
      final server = _makeServer(countryShort: 'US', health: ServerHealth.offline);
      expect(ServerRepository.isUsActive(server), isFalse);
    });

    test('rejects a non-US server (DE)', () {
      final server = _makeServer(countryShort: 'DE', health: null);
      expect(ServerRepository.isUsActive(server), isFalse);
    });

    test('rejects a non-US server (JP)', () {
      final server = _makeServer(countryShort: 'JP', health: ServerHealth.online);
      expect(ServerRepository.isUsActive(server), isFalse);
    });

    test('rejects a US server with no config', () {
      final server = _makeServer(countryShort: 'US', hasConfig: false);
      expect(ServerRepository.isUsActive(server), isFalse);
    });

    test('rejects a non-US server with health=online and no config', () {
      final server = _makeServer(
        countryShort: 'FR',
        health: ServerHealth.online,
        hasConfig: false,
      );
      expect(ServerRepository.isUsActive(server), isFalse);
    });

    test('countryShort comparison is case-insensitive (lowercase us)', () {
      // Construct a server with lowercase 'us'.
      final server = ServerModel(
        id: 'srv_lower',
        hostName: 'lower.example.com',
        ip: '2.3.4.5',
        countryLong: 'United States',
        countryShort: 'us', // lowercase
        numVpnSessions: 5,
        ping: 30,
        speed: 512 * 1024,
        openVpnConfigDataBase64: 'dGVzdA==',
        supportsTcp: true,
      );
      expect(ServerRepository.isUsActive(server), isTrue);
    });

    test('accepts a US server with ovpnUrl and no inline config', () {
      final server = ServerModel(
        id: 'srv_url',
        hostName: 'url.example.com',
        ip: '3.4.5.6',
        countryLong: 'United States',
        countryShort: 'US',
        numVpnSessions: 10,
        ping: 50,
        speed: 1024 * 1024,
        openVpnConfigDataBase64: '',
        supportsTcp: true,
        ovpnUrl: 'https://example.com/configs/us_northbergen.ovpn',
      );
      expect(ServerRepository.isUsActive(server), isTrue);
    });

    test('rejects a US server with no inline config and no ovpnUrl', () {
      final server = ServerModel(
        id: 'srv_empty',
        hostName: 'empty.example.com',
        ip: '4.5.6.7',
        countryLong: 'United States',
        countryShort: 'US',
        numVpnSessions: 10,
        ping: 50,
        speed: 1024 * 1024,
        openVpnConfigDataBase64: '',
        supportsTcp: true,
      );
      expect(ServerRepository.isUsActive(server), isFalse);
    });
  });
}
