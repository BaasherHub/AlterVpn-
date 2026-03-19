import 'package:flutter/foundation.dart';

/// Result of an OpenVPN profile validation.
class OvpnValidationResult {
  final bool isValid;
  final String? errorMessage;

  const OvpnValidationResult._({required this.isValid, this.errorMessage});

  factory OvpnValidationResult.ok() =>
      const OvpnValidationResult._(isValid: true);

  factory OvpnValidationResult.fail(String message) =>
      OvpnValidationResult._(isValid: false, errorMessage: message);
}

/// Strict preflight validator for OpenVPN `.ovpn` profile content.
///
/// Checks that the essential directives required to establish a connection
/// are present before the config is handed off to the VPN engine.
class OvpnValidator {
  OvpnValidator._();

  /// Directives that every valid OpenVPN config must contain.
  static const _requiredDirectives = ['remote', 'proto', 'dev'];

  /// At least one auth/cert block must be present.
  static const _authMaterialPatterns = [
    '<ca>',
    '<cert>',
    '<tls-auth>',
    '<tls-crypt>',
    'auth-user-pass',
  ];

  /// Validates [config] and returns a [OvpnValidationResult].
  ///
  /// Returns `fail` with an actionable message when:
  ///   - [config] is null or empty
  ///   - any required directive (`remote`, `proto`, `dev`) is missing
  ///   - no authentication / certificate material is present
  static OvpnValidationResult validate(String? config) {
    if (config == null || config.trim().isEmpty) {
      debugPrint('[OvpnValidator] FAIL reason=empty_config');
      return OvpnValidationResult.fail(
        'Server profile is empty. '
        'Please return to the server list and choose a different server.',
      );
    }

    final lower = config.toLowerCase();

    for (final directive in _requiredDirectives) {
      // Directive must appear at the start of a line (possibly with leading whitespace).
      final pattern = RegExp(r'(^|\n)\s*' + RegExp.escape(directive) + r'\b');
      if (!pattern.hasMatch(lower)) {
        debugPrint('[OvpnValidator] FAIL reason=missing_directive directive=$directive');
        return OvpnValidationResult.fail(
          'Server profile is invalid: missing required directive "$directive". '
          'Please select a different server or contact support.',
        );
      }
    }

    final hasAuth = _authMaterialPatterns.any((p) => lower.contains(p));
    if (!hasAuth) {
      debugPrint('[OvpnValidator] FAIL reason=missing_auth_material');
      return OvpnValidationResult.fail(
        'Server profile is missing authentication material. '
        'Please select a different server or contact support.',
      );
    }

    debugPrint('[OvpnValidator] OK');
    return OvpnValidationResult.ok();
  }
}
