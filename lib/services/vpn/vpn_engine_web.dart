import 'dart:async';
import 'vpn_config_model.dart';
import 'vpn_status_model.dart';

// Web stub — VPN simulation for UI testing on Flutter web.
// All VPN behaviour is mocked; no real tunnel is established.

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
  static final StreamController<VpnStage> _stageController =
      StreamController<VpnStage>.broadcast();
  static final StreamController<VpnStatusModel> _statusController =
      StreamController<VpnStatusModel>.broadcast();

  static VpnStage _currentStage = VpnStage.disconnected;
  static int _mockByteIn = 0;
  static int _mockByteOut = 0;
  static DateTime? _connectedAt;
  static Timer? _statusTimer;

  static Stream<VpnStage> get vpnStageStream => _stageController.stream;

  static Stream<VpnStatusModel> get vpnStatusStream => _statusController.stream;

  static Future<void> startVpn(VpnConfig config) async {
    final stages = [
      VpnStage.prepare,
      VpnStage.connecting,
      VpnStage.authenticating,
      VpnStage.connected,
    ];
    for (final stage in stages) {
      await Future<void>.delayed(const Duration(milliseconds: 800));
      _currentStage = stage;
      _stageController.add(stage);
    }
    _connectedAt = DateTime.now();
    _mockByteIn = 0;
    _mockByteOut = 0;
    _startStatusUpdates();
  }

  static void _startStatusUpdates() {
    _statusTimer?.cancel();
    _statusTimer = Timer.periodic(const Duration(seconds: 2), (_) {
      if (_currentStage != VpnStage.connected) {
        _statusTimer?.cancel();
        return;
      }
      _mockByteIn += 12000 + DateTime.now().millisecond * 80;
      _mockByteOut += 4000 + DateTime.now().millisecond * 25;
      final connected = _connectedAt;
      final elapsed = connected != null
          ? DateTime.now().difference(connected)
          : Duration.zero;
      final h = elapsed.inHours.toString().padLeft(2, '0');
      final m = (elapsed.inMinutes % 60).toString().padLeft(2, '0');
      final s = (elapsed.inSeconds % 60).toString().padLeft(2, '0');
      _statusController.add(VpnStatusModel(
        byteIn: _mockByteIn.toString(),
        byteOut: _mockByteOut.toString(),
        duration: '$h:$m:$s',
        lastPacketReceive: '0',
        connectedOn: connected?.toIso8601String() ?? '',
      ));
    });
  }

  static Future<void> stopVpn() async {
    _statusTimer?.cancel();
    for (final stage in [VpnStage.disconnecting, VpnStage.disconnected]) {
      await Future<void>.delayed(const Duration(milliseconds: 600));
      _currentStage = stage;
      _stageController.add(stage);
    }
    _mockByteIn = 0;
    _mockByteOut = 0;
    _connectedAt = null;
  }

  static Future<String?> currentStage() async => _currentStage.name;

  static Future<bool> isConnected() async =>
      _currentStage == VpnStage.connected;
}
