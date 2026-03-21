import 'dart:convert';

/// Possible health states reported by the backend.
/// A `null` value in [ServerModel.health] means no health data was provided.
class ServerHealth {
  static const String online = 'online';
  static const String degraded = 'degraded';
  static const String offline = 'offline';
}

class ServerModel {
  /// Stable server identifier from the backend (may be empty for legacy entries).
  final String id;

  final String hostName;

  /// Server IP address. Also accepts `host` as a JSON key.
  final String ip;

  final String countryLong;
  final String countryShort;

  /// City name (e.g. "Frankfurt"). Empty when backend does not provide it.
  final String city;

  /// Region tag from backend (e.g. "EU", "US", "AF", "AS", "ME").
  final String region;

  /// VPN protocol: "openvpn" or "wireguard". Empty when unknown.
  final String protocol;

  /// Transport layer: "udp" or "tcp". Empty when unknown.
  final String transport;

  /// Server port. 0 when unknown.
  final int port;

  final int numVpnSessions;
  final int ping;
  final double speed;
  final String openVpnConfigDataBase64;
  final bool supportsTcp;

  /// Plain-text OpenVPN config. When non-empty, takes precedence over
  /// [openVpnConfigDataBase64]. Populated when the backend returns raw
  /// config text (field: `ovpnConfig`) instead of a base64-encoded blob.
  final String rawConfig;

  /// Whether this is a premium/paid server.
  final bool isPremium;

  /// Server health state: one of [ServerHealth.online], [ServerHealth.degraded],
  /// [ServerHealth.offline], or `null` when not reported by the backend.
  final String? health;

  /// Measured round-trip latency in ms. 0 when not reported.
  final int latencyMs;

  /// Server load as a percentage (0–100). 0 when not reported.
  final double loadPercent;

  /// ISO 8601 timestamp of the last health check. Null when not reported.
  final String? lastCheckedAt;

  /// URL to fetch the raw OpenVPN config from.
  ///
  /// When non-empty and [rawConfig] / [openVpnConfigDataBase64] are both
  /// absent, the app must download the profile from this URL before connecting.
  final String ovpnUrl;

  /// URL to fetch the TCP fallback OpenVPN config from.
  ///
  /// When non-empty, the app may retry using this profile when the primary
  /// UDP connection (via [ovpnUrl]) times out or is blocked by a firewall.
  final String ovpnUrlTcp;

  const ServerModel({
    this.id = '',
    required this.hostName,
    required this.ip,
    required this.countryLong,
    required this.countryShort,
    this.city = '',
    this.region = '',
    this.protocol = '',
    this.transport = '',
    this.port = 0,
    required this.numVpnSessions,
    required this.ping,
    required this.speed,
    required this.openVpnConfigDataBase64,
    required this.supportsTcp,
    this.rawConfig = '',
    this.ovpnUrl = '',
    this.ovpnUrlTcp = '',
    this.isPremium = false,
    this.health,
    this.latencyMs = 0,
    this.loadPercent = 0,
    this.lastCheckedAt,
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
  ///
  /// Returns `true` when an inline config is present ([rawConfig] or
  /// [openVpnConfigDataBase64]) OR when [ovpnUrl] is set (the config
  /// can be fetched remotely before connecting).
  bool get hasConfig =>
      rawConfig.isNotEmpty ||
      openVpnConfigDataBase64.isNotEmpty ||
      ovpnUrl.isNotEmpty;

  /// Effective latency in ms: prefers [latencyMs] when provided, falls back
  /// to legacy [ping].
  int get effectiveLatency => latencyMs > 0 ? latencyMs : ping;

  /// Human-friendly primary label shown in the server tile.
  ///
  /// When a [city] is known it is returned (the country is already shown in
  /// the section header). Otherwise falls back to a shortened hostname, or
  /// [countryLong] as a last resort.
  String get displayName {
    if (city.isNotEmpty) return city;
    if (hostName.isEmpty) return countryLong;
    final base =
        hostName.contains('.') ? hostName.split('.').first : hostName;
    // For hash-like names longer than 20 chars, show only the last 8 chars.
    if (base.length > 20) {
      return '#${base.substring(base.length - 8)}';
    }
    return base;
  }

  /// Full location label: "Country • City" when city is known, else "Country".
  String get fullLocationLabel {
    if (city.isEmpty) return countryLong;
    return '$countryLong • $city';
  }

  /// Secondary metadata line for the server tile.
  ///
  /// Includes (when available): protocol, transport, latency, load, health /
  /// session count — formatted cleanly for display.
  String get metaLine {
    final parts = <String>[];

    // Protocol / transport
    if (protocol.isNotEmpty && transport.isNotEmpty) {
      parts.add('${protocol.toUpperCase()} • ${transport.toUpperCase()}');
    } else if (protocol.isNotEmpty) {
      parts.add(protocol.toUpperCase());
    } else if (transport.isNotEmpty) {
      parts.add(transport.toUpperCase());
    }

    // Latency
    final lat = effectiveLatency;
    if (lat > 0) parts.add('${lat}ms');

    // Load
    if (loadPercent > 0) parts.add('${loadPercent.round()}% load');

    // Health or session count
    if (health != null && health!.isNotEmpty) {
      parts.add(_healthLabel(health!));
    } else if (numVpnSessions > 0) {
      parts.add('$numVpnSessions sessions');
    }

    if (parts.isEmpty) return '$numVpnSessions sessions';
    return parts.join(' · ');
  }

  static String _healthLabel(String h) {
    switch (h) {
      case ServerHealth.online:
        return 'Online';
      case ServerHealth.degraded:
        return 'Degraded';
      case ServerHealth.offline:
        return 'Offline';
      default:
        return h;
    }
  }

  /// Composite quality score used for sorting (higher = preferred).
  ///
  /// Priority:
  ///   1. Health: online > degraded > offline/unknown.
  ///   2. Has a valid config (connectable).
  ///   3. Active sessions (server is likely reachable).
  ///   4. Lower effective latency.
  ///   5. Lower load.
  int get qualityScore {
    int score = 0;

    // Health status (highest priority when backend provides it)
    if (health == ServerHealth.online) {
      score += 100000;
    } else if (health == ServerHealth.degraded) {
      score += 50000;
    }
    // health == offline or null → no bonus

    // Config presence: connectable entries rank above non-connectable ones.
    if (hasConfig) score += 10000;

    // Active sessions = server is likely reachable.
    if (numVpnSessions > 0) score += 1000;

    // Latency contribution (0–999): lower latency → higher score.
    final lat = effectiveLatency;
    if (lat > 0) score += (1000 - lat.clamp(0, 1000));

    // Load contribution (0–99): lower load → higher score.
    if (loadPercent > 0) {
      score += (100 - loadPercent.clamp(0, 100).round());
    }

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

  /// Constructs a [ServerModel] from a JSON map returned by a backend.
  ///
  /// Supports both the legacy VPNGate-style payload and the new paid-backend
  /// schema. All fields are optional and fall back to empty/zero for
  /// backward compatibility.
  ///
  /// Supported field names:
  /// | JSON field                              | Maps to                 |
  /// |-----------------------------------------|-------------------------|
  /// | id                                      | id                      |
  /// | hostName / serverName / name            | hostName                |
  /// | ip / host                               | ip                      |
  /// | countryLong / country                   | countryLong             |
  /// | countryShort / countryCode              | countryShort            |
  /// | city                                    | city                    |
  /// | region                                  | region                  |
  /// | protocol                                | protocol                |
  /// | transport                               | transport               |
  /// | port                                    | port                    |
  /// | numVpnSessions / sessions               | numVpnSessions          |
  /// | ping                                    | ping                    |
  /// | latencyMs                               | latencyMs               |
  /// | speed                                   | speed                   |
  /// | loadPercent                             | loadPercent             |
  /// | ovpnConfig                              | rawConfig               |
  /// | openVpnConfigDataBase64 / openVpnConfig | openVpnConfigDataBase64 |
  /// | ovpn_url / ovpnUrl                      | ovpnUrl                 |
  /// | supportsTcp                             | supportsTcp             |
  /// | isPremium                               | isPremium               |
  /// | health                                  | health                  |
  /// | lastCheckedAt                           | lastCheckedAt           |
  factory ServerModel.fromJson(Map<String, dynamic> json) {
    final rawCfg =
        ((json['ovpnConfig'] as String?) ?? '').trim();
    final b64Cfg =
        ((json['openVpnConfigDataBase64'] as String?) ??
                (json['openVpnConfig'] as String?) ??
                '')
            .trim();
    final ovpnUrlVal =
        ((json['ovpn_url'] as String?) ?? (json['ovpnUrl'] as String?) ?? '')
            .trim();
    final ovpnUrlTcpVal =
        ((json['ovpn_url_tcp'] as String?) ??
                (json['ovpnUrlTcp'] as String?) ??
                '')
            .trim();
    return ServerModel(
      id: (json['id'] as String?) ?? '',
      hostName: (json['hostName'] as String?) ??
          (json['serverName'] as String?) ??
          (json['name'] as String?) ??
          '',
      ip: (json['ip'] as String?) ?? (json['host'] as String?) ?? '',
      countryLong:
          (json['countryLong'] as String?) ?? (json['country'] as String?) ?? '',
      countryShort: (json['countryShort'] as String?) ??
          (json['countryCode'] as String?) ??
          '',
      city: (json['city'] as String?) ?? '',
      region: (json['region'] as String?) ?? '',
      protocol: (json['protocol'] as String?) ?? '',
      transport: (json['transport'] as String?) ?? '',
      port: ((json['port'] as num?) ?? 0).toInt(),
      numVpnSessions:
          ((json['numVpnSessions'] as num?) ?? (json['sessions'] as num?) ?? 0)
              .toInt(),
      ping: ((json['ping'] as num?) ?? 0).toInt(),
      speed: ((json['speed'] as num?) ?? 0).toDouble(),
      openVpnConfigDataBase64: b64Cfg,
      supportsTcp: (json['supportsTcp'] as bool?) ?? true,
      rawConfig: rawCfg,
      ovpnUrl: ovpnUrlVal,
      ovpnUrlTcp: ovpnUrlTcpVal,
      isPremium: (json['isPremium'] as bool?) ?? false,
      health: json['health'] as String?,
      latencyMs: ((json['latencyMs'] as num?) ?? 0).toInt(),
      loadPercent: ((json['loadPercent'] as num?) ?? 0).toDouble(),
      lastCheckedAt: json['lastCheckedAt'] as String?,
    );
  }

  @override
  String toString() =>
      'Server(${id.isNotEmpty ? id : hostName}, ${fullLocationLabel}, '
      'latency: ${effectiveLatency}ms)';

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
