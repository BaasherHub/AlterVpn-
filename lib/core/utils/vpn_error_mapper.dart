import 'package:flutter/foundation.dart';

/// High-level categories for VPN connection failures.
enum VpnErrorCategory {
  /// The fetched or loaded `.ovpn` profile is malformed or incomplete.
  invalidProfile,

  /// The server rejected the credentials (wrong password, cert mismatch, etc.).
  authFailure,

  /// The device cannot reach the server (timeout, no route, etc.).
  networkUnreachable,

  /// The server is down or actively refusing connections.
  serverUnavailable,

  /// The OS VPN permission was denied by the user.
  permissionDenied,

  /// Catch-all for errors that do not match any specific category.
  unknown,
}

/// Structured error returned by [VpnErrorMapper.map].
class MappedVpnError {
  final VpnErrorCategory category;

  /// Human-readable message suitable for display in the app UI.
  final String userMessage;

  const MappedVpnError(this.category, this.userMessage);

  @override
  String toString() => 'MappedVpnError($category, "$userMessage")';
}

/// Maps raw exception / error strings to [MappedVpnError] instances.
///
/// Call [map] with the raw exception message obtained from a `catch` block.
/// The mapper logs the raw message at DEBUG level and returns a sanitised,
/// user-friendly description.
///
/// **Security note:** raw credentials must never appear in error strings
/// passed to this mapper. The VPN engine should not include passwords in its
/// exception messages, but callers must ensure this remains true.
class VpnErrorMapper {
  VpnErrorMapper._();

  /// Maps [rawError] to a [MappedVpnError].
  static MappedVpnError map(String rawError) {
    // Log the technical detail for debugging — never log credentials.
    debugPrint('[VpnErrorMapper] raw_error="${_redact(rawError)}"');

    final lower = rawError.toLowerCase();

    // --- Invalid / missing profile -----------------------------------------
    if (_matchesAny(lower, [
      'config is empty',
      'missing required directive',
      'missing authentication material',
      'profile is empty',
      'profile is invalid',
      'no openvpn config',
      'malformed',
    ])) {
      debugPrint('[VpnErrorMapper] category=invalidProfile');
      return const MappedVpnError(
        VpnErrorCategory.invalidProfile,
        'Invalid server profile. Please select a different server.',
      );
    }

    // --- Authentication / credential failure --------------------------------
    if (_matchesAny(lower, [
      'auth',
      'password',
      'credential',
      'certificate',
      'tls handshake',
      'tls error',
    ])) {
      debugPrint('[VpnErrorMapper] category=authFailure');
      return const MappedVpnError(
        VpnErrorCategory.authFailure,
        'Authentication failed. Please check your credentials and try again.',
      );
    }

    // --- Transport timeout / network unreachable ----------------------------
    if (_matchesAny(lower, [
      'timeout',
      'timed out',
      'unreachable',
      'no route',
      'network error',
      'socket',
      'connection error',
      'unable to reach',
      'check your internet',
    ])) {
      debugPrint('[VpnErrorMapper] category=networkUnreachable');
      return const MappedVpnError(
        VpnErrorCategory.networkUnreachable,
        'Network unreachable. Please check your internet connection and try again.',
      );
    }

    // --- Server unavailable -------------------------------------------------
    if (_matchesAny(lower, [
      'connection refused',
      'server unavailable',
      'server is down',
      'no healthy server',
      'no server',
    ])) {
      debugPrint('[VpnErrorMapper] category=serverUnavailable');
      return const MappedVpnError(
        VpnErrorCategory.serverUnavailable,
        'Server unavailable. Please try again later.',
      );
    }

    // --- Permission denied --------------------------------------------------
    if (_matchesAny(lower, ['permission', 'denied', 'vpn_generate_config'])) {
      debugPrint('[VpnErrorMapper] category=permissionDenied');
      return const MappedVpnError(
        VpnErrorCategory.permissionDenied,
        'VPN permission denied. Go to Settings → Install VPN Profile and accept the prompt.',
      );
    }

    // --- Unknown ------------------------------------------------------------
    debugPrint('[VpnErrorMapper] category=unknown');
    return const MappedVpnError(
      VpnErrorCategory.unknown,
      'Connection failed. Please try again.',
    );
  }

  static bool _matchesAny(String lower, List<String> keywords) =>
      keywords.any((k) => lower.contains(k));

  /// Redacts likely credential patterns before logging.
  static String _redact(String raw) {
    return raw
        .replaceAll(RegExp(r'password\s*[=:]\s*\S+', caseSensitive: false), 'password=***')
        .replaceAll(RegExp(r'user\s*[=:]\s*\S+', caseSensitive: false), 'user=***');
  }
}
