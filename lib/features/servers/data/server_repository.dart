import 'server_model.dart';
import 'vpngate_api.dart';

class ServerRepository {
  final VpnGateApi _api;
  List<ServerModel> _cachedServers = [];
  DateTime? _lastFetch;

  ServerRepository({VpnGateApi? api}) : _api = api ?? VpnGateApi();

  static const Duration _cacheExpiry = Duration(minutes: 30);

  Future<List<ServerModel>> getServers({bool forceRefresh = false}) async {
    final now = DateTime.now();
    final isCacheValid = _lastFetch != null &&
        now.difference(_lastFetch!) < _cacheExpiry &&
        _cachedServers.isNotEmpty;

    if (!forceRefresh && isCacheValid) {
      return _cachedServers;
    }

    final servers = await _api.fetchServers();
    // Sort by ping ascending; servers with ping == 0 go to the end
    servers.sort((a, b) {
      if (a.ping == 0 && b.ping == 0) return 0;
      if (a.ping == 0) return 1;
      if (b.ping == 0) return -1;
      return a.ping.compareTo(b.ping);
    });
    _cachedServers = servers;
    _lastFetch = now;
    return _cachedServers;
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
}
