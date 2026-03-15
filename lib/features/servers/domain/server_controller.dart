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
    return _fetchServers();
  }

  Future<List<ServerModel>> _fetchServers({bool forceRefresh = false}) {
    final repo = ref.read(serverRepositoryProvider);
    return repo.getServers(forceRefresh: forceRefresh);
  }

  Future<void> refresh() async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(
      () => _fetchServers(forceRefresh: true),
    );
  }
}

final selectedServerProvider = StateProvider<ServerModel?>((ref) => null);
