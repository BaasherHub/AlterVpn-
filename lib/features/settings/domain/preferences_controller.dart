import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../services/storage/storage_service.dart';
import 'preferences_state.dart';

final storageServiceProvider = FutureProvider<StorageService>((ref) async {
  return StorageService.init();
});

final preferencesControllerProvider =
    NotifierProvider<PreferencesController, PreferencesState>(
  PreferencesController.new,
);

class PreferencesController extends Notifier<PreferencesState> {
  StorageService? _storage;

  @override
  PreferencesState build() {
    _initStorage();
    return const PreferencesState();
  }

  Future<void> _initStorage() async {
    try {
      final storage = await StorageService.init();
      _storage = storage;
      state = PreferencesState(
        isDarkMode: storage.isDarkMode,
        isKillSwitchEnabled: storage.isKillSwitchEnabled,
        isAutoConnectEnabled: storage.isAutoConnectEnabled,
      );
    } catch (_) {
      // Keep default state if storage init fails
    }
  }

  void toggleDarkMode() {
    final newValue = !state.isDarkMode;
    state = state.copyWith(isDarkMode: newValue);
    _storage?.isDarkMode = newValue;
  }

  void toggleKillSwitch() {
    final newValue = !state.isKillSwitchEnabled;
    state = state.copyWith(isKillSwitchEnabled: newValue);
    _storage?.isKillSwitchEnabled = newValue;
  }

  void toggleAutoConnect() {
    final newValue = !state.isAutoConnectEnabled;
    state = state.copyWith(isAutoConnectEnabled: newValue);
    _storage?.isAutoConnectEnabled = newValue;
  }
}
