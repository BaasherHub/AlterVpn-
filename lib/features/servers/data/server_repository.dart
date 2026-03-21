import 'package:flutter/foundation.dart';
import 'server_model.dart';
import 'vpngate_api.dart';

class ServerRepository {
  final VpnGateApi _api;
  List<ServerModel> _cachedServers = [];
  DateTime? _lastFetch;

  ServerRepository({VpnGateApi? api}) : _api = api ?? VpnGateApi();

  static const Duration _cacheExpiry = Duration(minutes: 30);

  /// Fetches and returns servers, applying US-only + health gating.
  ///
  /// Only servers that pass [_isUsActive] are included in the result.
  /// Non-US and offline servers are excluded from the selection path.
  Future<List<ServerModel>> getServers({bool forceRefresh = false}) async {
    final now = DateTime.now();
    final isCacheValid = _lastFetch != null &&
        now.difference(_lastFetch!) < _cacheExpiry &&
        _cachedServers.isNotEmpty;

    if (!forceRefresh && isCacheValid) {
      return _cachedServers;
    }

    final all = await _api.fetchServers();

    // Apply US-only + health gate.
    final usActive = all.where(isUsActive).toList();

    debugPrint(
      '[ServerRepository] total=${all.length} us_active=${usActive.length}',
    );

    // Sort by composite quality score (higher = better):
    //   1. Has a valid config (connectable first).
    //   2. Has active sessions (server is reachable).
    //   3. Lower ping (faster).
    usActive.sort((a, b) => b.qualityScore.compareTo(a.qualityScore));
    _cachedServers = usActive;
    _lastFetch = now;
    return _cachedServers;
  }

  /// Returns `true` when [server] is a valid, active US server.
  ///
  /// Criteria:
  ///   - Country code is "US".
  ///   - Health is `null` (not reported), "online", or "degraded" — never "offline".
  ///   - Server has a usable OpenVPN configuration.
  static bool isUsActive(ServerModel server) {
    final isUs = server.countryShort.toUpperCase() == 'US';
    if (!isUs) return false;

    final health = server.health;
    final healthOk = health == null ||
        health == ServerHealth.online ||
        health == ServerHealth.degraded;
    if (!healthOk) return false;

    if (!server.hasConfig) return false;

    return true;
  }

  Map<String, List<ServerModel>> groupByCountry(List<ServerModel> servers) {
    final grouped = <String, List<ServerModel>>{};
    for (final server in servers) {
      grouped.putIfAbsent(server.countryLong, () => []).add(server);
    }
    return Map.fromEntries(
      grouped.entries.toList()..sort((a, b) => a.key.compareTo(b.key)),
    );
  }

  void clearCache() {
    _cachedServers = [];
    _lastFetch = null;
  }

  /// Returns the raw OpenVPN config text for [server].
  ///
  /// If [server] has an inline config (via [ServerModel.rawConfig] or
  /// [ServerModel.openVpnConfigDataBase64]), it is returned immediately.
  /// Otherwise, if [server.ovpnUrl] is non-empty, the profile is downloaded
  /// from that URL via the API client.
  ///
  /// Throws an [Exception] if no config source is available or the download
  /// fails.
  Future<String> resolveConfig(ServerModel server) async {
    final inline = server.openVpnConfig;
    if (inline.isNotEmpty) return inline;

    if (server.ovpnUrl.isNotEmpty) {
      debugPrint(
        '[ServerRepository] resolveConfig fetch_url=${server.ovpnUrl}',
      );
      return _api.fetchRawConfig(server.ovpnUrl);
    }

    throw Exception(
      'No VPN configuration available for this server. '
      'Please select a different server or try again later.',
    );
  }

  /// Downloads and returns the raw OpenVPN config text from [url].
  ///
  /// Used for fetching alternative profiles (e.g. TCP fallback) when the
  /// primary config has already been resolved via [resolveConfig].
  Future<String> resolveConfigFromUrl(String url) async {
    debugPrint('[ServerRepository] resolveConfigFromUrl url=$url');
    return _api.fetchRawConfig(url);
  }
}
