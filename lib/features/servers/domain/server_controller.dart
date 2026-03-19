import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../data/server_model.dart';
import '../data/server_repository.dart';

final serverRepositoryProvider = Provider<ServerRepository>((ref) {
  return ServerRepository();
});

final serverControllerProvider =
    AsyncNotifierProvider<ServerController, List<ServerModel>>(
  ServerController.new,
);

class ServerController extends AsyncNotifier<List<ServerModel>> {
  @override
  Future<List<ServerModel>> build() async {
    final servers = await _fetchServers();
    _autoSelectBestUsServer(servers);
    return servers;
  }

  Future<List<ServerModel>> _fetchServers({bool forceRefresh = false}) {
    final repo = ref.read(serverRepositoryProvider);
    return repo.getServers(forceRefresh: forceRefresh);
  }

  Future<void> refresh() async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(() async {
      final servers = await _fetchServers(forceRefresh: true);
      _autoSelectBestUsServer(servers);
      return servers;
    });
  }

  /// Auto-selects the best US server when no server is currently selected.
  ///
  /// Picks the first server in the (already quality-sorted) list, which
  /// ensures the app always has a working default without requiring the user
  /// to visit the server screen.
  void _autoSelectBestUsServer(List<ServerModel> servers) {
    if (servers.isEmpty) return;

    final current = ref.read(selectedServerProvider);
    if (current != null) return; // keep existing selection

    final best = servers.first;
    debugPrint(
      '[ServerController] auto_selected id=${best.id.isNotEmpty ? best.id : best.hostName} '
      'country=${best.countryShort} latency=${best.effectiveLatency}ms',
    );
    ref.read(selectedServerProvider.notifier).state = best;
  }
}

final selectedServerProvider = StateProvider<ServerModel?>((ref) => null);
