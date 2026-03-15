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
  });

  String get openVpnConfig {
    try {
      return utf8.decode(base64.decode(openVpnConfigDataBase64));
    } catch (_) {
      return '';
    }
  }

  double get speedMbps => speed / (1024 * 1024);

  String get countryFlag {
    if (countryShort.isEmpty) return '🌐';
    return countryShort.toUpperCase().replaceAllMapped(
          RegExp(r'[A-Z]'),
          (m) => String.fromCharCode(m[0]!.codeUnitAt(0) + 127397),
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
