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
    _storage = await StorageService.init();
    state = PreferencesState(
      isDarkMode: _storage!.isDarkMode,
      isKillSwitchEnabled: _storage!.isKillSwitchEnabled,
      isAutoConnectEnabled: _storage!.isAutoConnectEnabled,
    );
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
