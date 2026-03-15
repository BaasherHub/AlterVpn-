class VpnConfig {
  final String config;
  final String serverName;
  final String country;
  final String username;
  final String password;

  const VpnConfig({
    required this.config,
    required this.serverName,
    required this.country,
    this.username = 'vpn',
    this.password = 'vpn',
  });

  @override
  String toString() => 'VpnConfig(server: $serverName, country: $country)';
}
