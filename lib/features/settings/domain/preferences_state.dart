class PreferencesState {
  final bool isDarkMode;
  final bool isKillSwitchEnabled;
  final bool isAutoConnectEnabled;

  const PreferencesState({
    this.isDarkMode = true,
    this.isKillSwitchEnabled = false,
    this.isAutoConnectEnabled = false,
  });

  PreferencesState copyWith({
    bool? isDarkMode,
    bool? isKillSwitchEnabled,
    bool? isAutoConnectEnabled,
  }) {
    return PreferencesState(
      isDarkMode: isDarkMode ?? this.isDarkMode,
      isKillSwitchEnabled: isKillSwitchEnabled ?? this.isKillSwitchEnabled,
      isAutoConnectEnabled: isAutoConnectEnabled ?? this.isAutoConnectEnabled,
    );
  }
}
