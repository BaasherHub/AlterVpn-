/// Utilities for extracting OpenVPN authentication credentials from a `.ovpn`
/// profile text.
///
/// Many provider-generated configs contain credentials either:
/// - in comments like `# OVPN_ACCESS_SERVER_USERNAME=...`
/// - directly on the `auth-user-pass` line (less common, but supported here)
///
/// If credentials cannot be extracted, callers should fall back to their own
/// defaults.
class OvpnCredentials {
  final String username;
  final String password;

  const OvpnCredentials({
    required this.username,
    required this.password,
  });
}

class OvpnCredentialsExtractor {
  const OvpnCredentialsExtractor._();

  /// Extracts [OvpnCredentials] from a raw `.ovpn` profile.
  ///
  /// Supported patterns:
  /// - `OVPN_ACCESS_SERVER_USERNAME=...` / `OVPN_ACCESS_SERVER_PASSWORD=...`
  ///   (often present as commented lines in provider-generated configs)
  /// - `auth-user-pass <username> <password>`
  ///
  /// Returns [defaultCredentials] when nothing matches.
  static OvpnCredentials extract(
    String config, {
    OvpnCredentials defaultCredentials = const OvpnCredentials(
      username: 'vpn',
      password: 'vpn',
    ),
  }) {
    final cfg = config;

    final fromComment = _extractFromEnvComments(cfg);
    if (fromComment != null) return fromComment;

    final fromAuthUserPass = _extractFromAuthUserPassLine(cfg);
    if (fromAuthUserPass != null) return fromAuthUserPass;

    return defaultCredentials;
  }

  static OvpnCredentials? _extractFromEnvComments(String config) {
    // Examples we want to support:
    //   # OVPN_ACCESS_SERVER_USERNAME=appuser_us
    //   # OVPN_ACCESS_SERVER_PASSWORD=whatever
    //
    // Notes:
    // - We intentionally stop at whitespace or `#` to avoid capturing
    //   trailing comment content.
    final userMatch = RegExp(
      r'(?im)^\s*#?\s*OVPN_ACCESS_SERVER_USERNAME\s*=\s*([^\s#]+)',
    ).firstMatch(config);
    final passMatch = RegExp(
      r'(?im)^\s*#?\s*OVPN_ACCESS_SERVER_PASSWORD\s*=\s*([^\s#]+)',
    ).firstMatch(config);

    final username = userMatch?.group(1);
    final password = passMatch?.group(1);
    if (username == null || password == null) return null;

    return OvpnCredentials(username: username, password: password);
  }

  static OvpnCredentials? _extractFromAuthUserPassLine(String config) {
    // Example (supported):
    //   auth-user-pass username password
    //
    // We don't try to parse `auth-user-pass /path/to/file` because it would
    // require I/O and the file isn't necessarily shipped.
    final match = RegExp(
      r'(?im)^\s*auth-user-pass\s+([^\s]+)\s+([^\s]+)\s*$',
    ).firstMatch(config);

    final username = match?.group(1);
    final password = match?.group(2);
    if (username == null || password == null) return null;

    return OvpnCredentials(username: username, password: password);
  }
}

