import 'package:flutter/services.dart';
import 'vpn_config_model.dart';
import 'vpn_status_model.dart';

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
  static const MethodChannel _methodChannel =
      MethodChannel('com.altervpn/vpnControl');
  static const EventChannel _stageChannel =
      EventChannel('com.altervpn/vpnStage');
  static const EventChannel _statusChannel =
      EventChannel('com.altervpn/vpnStatus');

  static Stream<VpnStage> get vpnStageStream {
    return _stageChannel.receiveBroadcastStream().map((event) {
      return vpnStageFromString(event?.toString() ?? '');
    });
  }

  static Stream<VpnStatusModel> get vpnStatusStream {
    return _statusChannel.receiveBroadcastStream().map((event) {
      if (event == null) return VpnStatusModel.empty();
      final data = Map<String, dynamic>.from(event as Map);
      return VpnStatusModel(
        byteIn: data['byteIn']?.toString() ?? '0',
        byteOut: data['byteOut']?.toString() ?? '0',
        duration: data['duration']?.toString() ?? '00:00:00',
        lastPacketReceive: data['lastPacketReceive']?.toString() ?? '0',
        connectedOn: data['connectedOn']?.toString() ?? '',
      );
    });
  }

  static Future<void> startVpn(VpnConfig config) async {
    try {
      await _methodChannel.invokeMethod('startVpn', {
        'config': config.config,
        'serverName': config.serverName,
        'country': config.country,
        'username': config.username,
        'password': config.password,
      });
    } on PlatformException catch (e) {
      throw Exception('Failed to start VPN: ${e.message}');
    }
  }

  static Future<void> stopVpn() async {
    try {
      await _methodChannel.invokeMethod('stopVpn');
    } on PlatformException catch (e) {
      throw Exception('Failed to stop VPN: ${e.message}');
    }
  }

  static Future<String?> currentStage() async {
    try {
      return await _methodChannel.invokeMethod<String>('currentStage');
    } on PlatformException {
      return null;
    }
  }

  static Future<bool> isConnected() async {
    final stage = await currentStage();
    return stage?.toLowerCase() == 'connected';
  }
}
