// Conditionally exports the platform-appropriate VPN engine implementation.
// On web (dart.library.html): uses vpn_engine_web.dart — simulates VPN for UI testing.
// On native (dart.library.io):  uses vpn_engine_native.dart — real OpenVPN integration.
// Fallback stub is used when neither library is available.
export 'vpn_engine_stub.dart'
    if (dart.library.html) 'vpn_engine_web.dart'
    if (dart.library.io) 'vpn_engine_native.dart';
