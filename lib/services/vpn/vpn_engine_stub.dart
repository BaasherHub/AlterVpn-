import 'dart:async';
import 'vpn_config_model.dart';
import 'vpn_status_model.dart';

// Fallback stub for platforms where neither dart:io nor dart:html is available.

enum VpnStage {
  prepare,
  authenticating,
  connecting,
  connected,
  disconnecting,
  disconnected,
  denied,
  error,
  reconnecting,
  unknown,
}

extension VpnStageExtension on VpnStage {
  String get displayName {
    switch (this) {
      case VpnStage.prepare:
        return 'Preparing';
      case VpnStage.authenticating:
        return 'Authenticating';
      case VpnStage.connecting:
        return 'Connecting';
      case VpnStage.connected:
        return 'Connected';
      case VpnStage.disconnecting:
        return 'Disconnecting';
      case VpnStage.disconnected:
        return 'Disconnected';
      case VpnStage.denied:
        return 'Permission Denied';
      case VpnStage.error:
        return 'Error';
      case VpnStage.reconnecting:
        return 'Reconnecting';
      case VpnStage.unknown:
        return 'Unknown';
    }
  }

  bool get isActive =>
      this == VpnStage.connected ||
      this == VpnStage.connecting ||
      this == VpnStage.authenticating ||
      this == VpnStage.reconnecting;

  bool get isConnected => this == VpnStage.connected;

  bool get isConnecting =>
      this == VpnStage.connecting ||
      this == VpnStage.authenticating ||
      this == VpnStage.prepare ||
      this == VpnStage.reconnecting;
}

VpnStage vpnStageFromString(String stage) {
  switch (stage.toLowerCase()) {
    case 'prepare':
      return VpnStage.prepare;
    case 'authenticating':
    case 'auth':
      return VpnStage.authenticating;
    case 'connecting':
    case 'tcp_connect':
    case 'wait':
    case 'assign_ip':
    case 'add_routes':
      return VpnStage.connecting;
    case 'connected':
      return VpnStage.connected;
    case 'disconnecting':
      return VpnStage.disconnecting;
    case 'disconnected':
    case 'noprocess':
      return VpnStage.disconnected;
    case 'vpn_generate_config':
    case 'denied':
      return VpnStage.denied;
    case 'reconnecting':
    case 'resolve':
      return VpnStage.reconnecting;
    default:
      return VpnStage.unknown;
  }
}

class VpnEngine {
  static Stream<VpnStage> get vpnStageStream =>
      Stream.value(VpnStage.disconnected);

  static Stream<VpnStatusModel> get vpnStatusStream =>
      Stream.value(VpnStatusModel.empty());

  static Future<void> startVpn(VpnConfig config) async {
    throw UnsupportedError('VPN is not supported on this platform.');
  }

  static Future<void> stopVpn() async {
    throw UnsupportedError('VPN is not supported on this platform.');
  }

  static Future<String?> currentStage() async => VpnStage.disconnected.name;

  static Future<bool> isConnected() async => false;
}
