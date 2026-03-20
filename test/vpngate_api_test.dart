import 'package:flutter_test/flutter_test.dart';
import 'package:alter_vpn/features/servers/data/server_model.dart';

void main() {
  // ── ServerModel.fromJson — new /api/iphone/ JSON schema ─────────────────────

  group('ServerModel.fromJson (ovpn_url schema)', () {
    test('parses ovpn_url field (snake_case)', () {
      final json = <String, dynamic>{
        'id': 'us_northbergen',
        'name': 'US - North Bergen',
        'countryLong': 'United States',
        'countryShort': 'US',
        'city': 'North Bergen',
        'active': true,
        'ovpn_url': 'https://example.com/configs/us_northbergen.ovpn',
      };
      final server = ServerModel.fromJson(json);
      expect(server.id, 'us_northbergen');
      expect(server.countryShort, 'US');
      expect(server.city, 'North Bergen');
      expect(server.ovpnUrl,
          'https://example.com/configs/us_northbergen.ovpn');
      expect(server.hasConfig, isTrue);
    });

    test('parses ovpnUrl field (camelCase fallback)', () {
      final json = <String, dynamic>{
        'id': 'us_test',
        'countryShort': 'US',
        'ovpnUrl': 'https://example.com/configs/us_test.ovpn',
      };
      final server = ServerModel.fromJson(json);
      expect(server.ovpnUrl, 'https://example.com/configs/us_test.ovpn');
      expect(server.hasConfig, isTrue);
    });

    test('ovpn_url takes precedence over camelCase ovpnUrl when both present', () {
      final json = <String, dynamic>{
        'id': 'us_test',
        'countryShort': 'US',
        'ovpn_url': 'https://example.com/snake.ovpn',
        'ovpnUrl': 'https://example.com/camel.ovpn',
      };
      final server = ServerModel.fromJson(json);
      // snake_case wins (checked first in fromJson)
      expect(server.ovpnUrl, 'https://example.com/snake.ovpn');
    });

    test('ovpnUrl is empty string when field is absent', () {
      final json = <String, dynamic>{
        'id': 'us_test',
        'countryShort': 'US',
        'openVpnConfigDataBase64': 'dGVzdA==',
      };
      final server = ServerModel.fromJson(json);
      expect(server.ovpnUrl, isEmpty);
    });

    test('ovpnUrl is empty string when field is empty string', () {
      final json = <String, dynamic>{
        'id': 'us_test',
        'countryShort': 'US',
        'ovpn_url': '',
      };
      final server = ServerModel.fromJson(json);
      expect(server.ovpnUrl, isEmpty);
    });

    test('both ovpn_url and openVpnConfigDataBase64 can coexist', () {
      final json = <String, dynamic>{
        'id': 'us_test',
        'countryShort': 'US',
        'ovpn_url': 'https://example.com/configs/us.ovpn',
        'openVpnConfigDataBase64': 'dGVzdA==',
      };
      final server = ServerModel.fromJson(json);
      expect(server.ovpnUrl, 'https://example.com/configs/us.ovpn');
      expect(server.openVpnConfigDataBase64, 'dGVzdA==');
      expect(server.hasConfig, isTrue);
    });

    test('name field maps to hostName when hostName absent', () {
      final json = <String, dynamic>{
        'id': 'us_northbergen',
        'name': 'US - North Bergen',
        'countryShort': 'US',
        'ovpn_url': 'https://example.com/configs/us_northbergen.ovpn',
      };
      final server = ServerModel.fromJson(json);
      expect(server.hostName, 'US - North Bergen');
    });

    test('unwraps servers wrapper object (mirrors VpnGateApi._parseJson)', () {
      // The full /api/iphone/ JSON response shape as returned by nginx.
      final response = <String, dynamic>{
        'servers': <dynamic>[
          <String, dynamic>{
            'id': 'us_northbergen',
            'name': 'US - North Bergen',
            'countryLong': 'United States',
            'countryShort': 'US',
            'city': 'North Bergen',
            'active': true,
            'ovpn_url':
                'https://altervpn-production.up.railway.app/configs/us_northbergen.ovpn',
          }
        ],
      };

      // Replicate VpnGateApi._parseJson unwrap logic.
      final dynamic decoded = response;
      final List<dynamic> list = decoded is List
          ? decoded
          : (decoded['servers'] as List? ?? [decoded]);
      final servers = list
          .whereType<Map<String, dynamic>>()
          .map(ServerModel.fromJson)
          .toList();

      expect(servers.length, 1);
      expect(servers.first.id, 'us_northbergen');
      expect(servers.first.countryShort, 'US');
      expect(servers.first.ovpnUrl,
          'https://altervpn-production.up.railway.app/configs/us_northbergen.ovpn');
      expect(servers.first.hasConfig, isTrue);
    });
  });

  // ── hasConfig ────────────────────────────────────────────────────────────────

  group('ServerModel.hasConfig', () {
    ServerModel _base() => const ServerModel(
          hostName: 'h.example.com',
          ip: '1.2.3.4',
          countryLong: 'United States',
          countryShort: 'US',
          numVpnSessions: 0,
          ping: 0,
          speed: 0,
          openVpnConfigDataBase64: '',
          supportsTcp: true,
        );

    test('true when openVpnConfigDataBase64 is non-empty', () {
      final s = ServerModel(
        hostName: _base().hostName,
        ip: _base().ip,
        countryLong: _base().countryLong,
        countryShort: _base().countryShort,
        numVpnSessions: 0,
        ping: 0,
        speed: 0,
        openVpnConfigDataBase64: 'dGVzdA==',
        supportsTcp: true,
      );
      expect(s.hasConfig, isTrue);
    });

    test('true when rawConfig is non-empty', () {
      final s = ServerModel(
        hostName: _base().hostName,
        ip: _base().ip,
        countryLong: _base().countryLong,
        countryShort: _base().countryShort,
        numVpnSessions: 0,
        ping: 0,
        speed: 0,
        openVpnConfigDataBase64: '',
        supportsTcp: true,
        rawConfig: 'client\ndev tun\n',
      );
      expect(s.hasConfig, isTrue);
    });

    test('true when ovpnUrl is non-empty', () {
      final s = ServerModel(
        hostName: _base().hostName,
        ip: _base().ip,
        countryLong: _base().countryLong,
        countryShort: _base().countryShort,
        numVpnSessions: 0,
        ping: 0,
        speed: 0,
        openVpnConfigDataBase64: '',
        supportsTcp: true,
        ovpnUrl: 'https://example.com/configs/us.ovpn',
      );
      expect(s.hasConfig, isTrue);
    });

    test('false when all config fields are empty', () {
      expect(_base().hasConfig, isFalse);
    });
  });

  // ── Non-JSON response detection ──────────────────────────────────────────────

  group('API response format detection', () {
    bool _looksLikeJson(String body) {
      final t = body.trimLeft();
      return t.startsWith('{') || t.startsWith('[');
    }

    test('garbled/CSV response is detected as non-JSON', () {
      const garbled =
          '*VPN Gate Public VPN Relay Servers\n#HostName,IP,Score,...\n';
      expect(_looksLikeJson(garbled), isFalse);
    });

    test('JSON object response is detected as JSON', () {
      const json = '{"servers":[]}';
      expect(_looksLikeJson(json), isTrue);
    });

    test('JSON array response is detected as JSON', () {
      const json = '[{"id":"srv1"}]';
      expect(_looksLikeJson(json), isTrue);
    });

    test('JSON with leading whitespace is detected as JSON', () {
      const json = '  \n{"servers":[]}';
      expect(_looksLikeJson(json), isTrue);
    });

    test('binary/empty response is detected as non-JSON', () {
      expect(_looksLikeJson(''), isFalse);
      expect(_looksLikeJson('   '), isFalse);
    });
  });

  // ── OvpnUrl servers pass ServerRepository.isUsActive ─────────────────────────
  // (complementary to the dedicated server_filter_test.dart tests)

  group('ServerModel ovpnUrl — hasConfig contract', () {
    test('server with only ovpnUrl has hasConfig=true', () {
      final json = <String, dynamic>{
        'id': 'us_northbergen',
        'countryShort': 'US',
        'ovpn_url': 'https://example.com/configs/us_northbergen.ovpn',
      };
      final server = ServerModel.fromJson(json);
      expect(server.ovpnUrl, isNotEmpty);
      expect(server.openVpnConfigDataBase64, isEmpty);
      expect(server.rawConfig, isEmpty);
      expect(server.hasConfig, isTrue);
    });
  });
}
