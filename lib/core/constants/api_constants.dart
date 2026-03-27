/// Centralised API endpoint configuration.
///
/// Change [backendBaseUrl] here to point all server-list fetches at a
/// different relay without touching any other file.
class ApiConstants {
  ApiConstants._();

  /// Production Railway backend that serves the AlterVPN server list.
  static const String backendBaseUrl =
      'https://altervpn-production.up.railway.app';

  /// Path that returns the JSON server list (see nginx.conf).
  ///
  /// Response format: JSON with shape:
  /// ```json
  /// {
  ///   "servers": [
  ///     {
  ///       "id": "us_northbergen",
  ///       "ovpn_url": "https://.../configs/us_northbergen.ovpn"
  ///     },
  ///     {
  ///       "id": "uk_london",
  ///       "ovpn_url": "https://.../configs/uk_london.ovpn"
  ///     }
  ///   ]
  /// }
  /// ```
  static const String serversPath = '/api/iphone/';

  /// Full server-list endpoint.
  static const String serversUrl = '$backendBaseUrl$serversPath';
}
