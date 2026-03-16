/// Centralised API endpoint configuration.
///
/// Change [backendBaseUrl] here to point all server-list fetches at a
/// different relay without touching any other file.
class ApiConstants {
  ApiConstants._();

  /// Production Railway backend that relays the VPNGate server list.
  /// The server at this origin fetches from VPNGate on behalf of the app,
  /// which ensures reachability from regions where vpngate.net is blocked.
  static const String backendBaseUrl =
      'https://altervpn-production.up.railway.app';

  /// Path exposed by the Railway nginx relay (see nginx.conf).
  /// Response format: VPNGate CSV (identical to the upstream source).
  static const String serversPath = '/api/iphone/';

  /// Full server-list endpoint.
  static const String serversUrl = '$backendBaseUrl$serversPath';
}
