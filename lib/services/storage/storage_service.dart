import 'package:shared_preferences/shared_preferences.dart';

class StorageService {
  static const String _keyDarkMode = 'dark_mode';
  static const String _keyKillSwitch = 'kill_switch';
  static const String _keyAutoConnect = 'auto_connect';
  static const String _keyOnboardingDone = 'onboarding_done';
  static const String _keyLastServerId = 'last_server_id';

  final SharedPreferences _prefs;

  StorageService(this._prefs);

  static Future<StorageService> init() async {
    final prefs = await SharedPreferences.getInstance();
    return StorageService(prefs);
  }

  bool get isDarkMode => _prefs.getBool(_keyDarkMode) ?? true;
  set isDarkMode(bool value) => _prefs.setBool(_keyDarkMode, value);

  bool get isKillSwitchEnabled => _prefs.getBool(_keyKillSwitch) ?? false;
  set isKillSwitchEnabled(bool value) => _prefs.setBool(_keyKillSwitch, value);

  bool get isAutoConnectEnabled => _prefs.getBool(_keyAutoConnect) ?? false;
  set isAutoConnectEnabled(bool value) =>
      _prefs.setBool(_keyAutoConnect, value);

  bool get isOnboardingDone => _prefs.getBool(_keyOnboardingDone) ?? false;
  set isOnboardingDone(bool value) =>
      _prefs.setBool(_keyOnboardingDone, value);

  String? get lastServerId => _prefs.getString(_keyLastServerId);
  set lastServerId(String? value) {
    if (value != null) {
      _prefs.setString(_keyLastServerId, value);
    } else {
      _prefs.remove(_keyLastServerId);
    }
  }
}
