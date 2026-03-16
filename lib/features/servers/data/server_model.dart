import 'dart:convert';

class ServerModel {
  final String hostName;
  final String ip;
  final String countryLong;
  final String countryShort;
  final int numVpnSessions;
  final int ping;
  final double speed;
  final String openVpnConfigDataBase64;
  final bool supportsTcp;

  /// Plain-text OpenVPN config. When non-empty, takes precedence over
  /// [openVpnConfigDataBase64]. Populated when the backend returns raw
  /// config text (field: `ovpnConfig`) instead of a base64-encoded blob.
  final String rawConfig;

  const ServerModel({
    required this.hostName,
    required this.ip,
    required this.countryLong,
    required this.countryShort,
    required this.numVpnSessions,
    required this.ping,
    required this.speed,
    required this.openVpnConfigDataBase64,
    required this.supportsTcp,
    this.rawConfig = '',
  });

  /// Returns the decoded OpenVPN configuration string.
  ///
  /// Priority:
  ///   1. [rawConfig] — used as-is when non-empty (plain-text from backend).
  ///   2. [openVpnConfigDataBase64] — base64-decoded.
  ///
  /// VPNGate embeds newlines inside the base64 blob; those are stripped
  /// before decoding so that `base64.decode()` does not throw.
  String get openVpnConfig {
    if (rawConfig.isNotEmpty) return rawConfig;
    if (openVpnConfigDataBase64.isEmpty) return '';
    try {
      // Strip all whitespace — VPNGate wraps base64 with embedded newlines.
      final clean = openVpnConfigDataBase64.replaceAll(RegExp(r'\s'), '');
      if (clean.isEmpty) return '';
      return utf8.decode(base64.decode(clean));
    } catch (_) {
      return '';
    }
  }

  /// Whether this server has a usable OpenVPN configuration.
  bool get hasConfig => rawConfig.isNotEmpty || openVpnConfigDataBase64.isNotEmpty;

  /// Human-friendly display name.
  /// Shows the base hostname without the domain suffix so the list is easier
  /// to scan.  Full noisy hostnames like `public-vpn-1.vpngate.net` become
  /// `public-vpn-1`.
  String get displayName {
    if (hostName.isEmpty) return countryLong;
    final base =
        hostName.contains('.') ? hostName.split('.').first : hostName;
    // For hash-like names longer than 20 chars, show only the last 8 chars.
    if (base.length > 20) {
      return '#${base.substring(base.length - 8)}';
    }
    return base;
  }

  /// Composite quality score used for sorting (higher = preferred).
  ///
  /// Criteria (descending priority):
  ///   1. Has a valid config (connectable).
  ///   2. Has active sessions (server is reachable).
  ///   3. Lower ping (faster).
  int get qualityScore {
    int score = 0;
    if (hasConfig) score += 10000;      // config presence outweighs all else
    if (numVpnSessions > 0) score += 1000; // active sessions = likely reachable
    // Ping contribution (0–1000): lower ping → higher score; ping==0 = unknown.
    if (ping > 0) score += (1000 - ping.clamp(0, 1000));
    return score;
  }

  double get speedMbps => speed / (1024 * 1024);

  String get countryFlag {
    if (countryShort.isEmpty) return '🌐';
    return countryShort.toUpperCase().replaceAllMapped(
          RegExp(r'[A-Z]'),
          (m) => String.fromCharCode(m[0]!.codeUnitAt(0) + 127397),
        );
  }

  /// Constructs a [ServerModel] from a JSON map returned by a JSON backend.
  ///
  /// Supported field names (all optional — falls back to empty/zero):
  /// | JSON field               | Maps to            |
  /// |--------------------------|-------------------|
  /// | hostName / serverName    | hostName          |
  /// | ip                       | ip                |
  /// | countryLong / country    | countryLong       |
  /// | countryShort / countryCode| countryShort     |
  /// | numVpnSessions / sessions| numVpnSessions    |
  /// | ping                     | ping              |
  /// | speed                    | speed             |
  /// | ovpnConfig               | rawConfig         |
  /// | openVpnConfigDataBase64 / openVpnConfig | openVpnConfigDataBase64 |
  factory ServerModel.fromJson(Map<String, dynamic> json) {
    final rawCfg =
        ((json['ovpnConfig'] as String?) ?? '').trim();
    final b64Cfg =
        ((json['openVpnConfigDataBase64'] as String?) ??
                (json['openVpnConfig'] as String?) ??
                '')
            .trim();
    return ServerModel(
      hostName: (json['hostName'] as String?) ??
          (json['serverName'] as String?) ??
          '',
      ip: (json['ip'] as String?) ?? '',
      countryLong:
          (json['countryLong'] as String?) ?? (json['country'] as String?) ?? '',
      countryShort: (json['countryShort'] as String?) ??
          (json['countryCode'] as String?) ??
          '',
      numVpnSessions:
          ((json['numVpnSessions'] as num?) ?? (json['sessions'] as num?) ?? 0)
              .toInt(),
      ping: ((json['ping'] as num?) ?? 0).toInt(),
      speed: ((json['speed'] as num?) ?? 0).toDouble(),
      openVpnConfigDataBase64: b64Cfg,
      supportsTcp: (json['supportsTcp'] as bool?) ?? true,
      rawConfig: rawCfg,
    );
  }

  @override
  String toString() =>
      'Server($hostName, $countryLong, ping: ${ping}ms)';

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ServerModel &&
          runtimeType == other.runtimeType &&
          hostName == other.hostName &&
          ip == other.ip;

  @override
  int get hashCode => hostName.hashCode ^ ip.hashCode;
}
