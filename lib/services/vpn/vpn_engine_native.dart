import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:openvpn_flutter/openvpn_flutter.dart';
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
  unknown;

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

/// VPN engine backed by the openvpn_flutter plugin.
/// Uses a singleton [OpenVPN] instance so that stage and status streams
/// remain alive for the lifetime of the app.
class VpnEngine {
  VpnEngine._();

  static OpenVPN? _openVpn;
  static bool _initialized = false;

  static final StreamController<VpnStage> _stageController =
      // Intentionally never closed — VpnEngine is a static singleton that
      // lives for the entire app lifetime and continuously delivers events.
      StreamController<VpnStage>.broadcast();
  static final StreamController<VpnStatusModel> _statusController =
      // Same rationale as _stageController above.
      StreamController<VpnStatusModel>.broadcast();

  static Stream<VpnStage> get vpnStageStream => _stageController.stream;
  static Stream<VpnStatusModel> get vpnStatusStream =>
      _statusController.stream;

  /// Initializes the OpenVPN plugin. Safe to call multiple times.
  static Future<void> _ensureInitialized() async {
    if (_initialized) return;
    _openVpn = OpenVPN(
      onVpnStageChanged: (stage, rawStage) {
        debugPrint('[VpnEngine] stage=$stage raw=$rawStage');
        _stageController.add(vpnStageFromString(rawStage));
      },
      onVpnStatusChanged: (status) {
        if (status == null) return;
        _statusController.add(VpnStatusModel(
          byteIn: status.byteIn ?? '0',
          byteOut: status.byteOut ?? '0',
          duration: status.duration ?? '00:00:00',
          // lastPacketReceive is not provided by openvpn_flutter's VpnStatus.
          lastPacketReceive: '0',
          // connectedOn is a DateTime? in openvpn_flutter; convert to String.
          connectedOn: status.connectedOn?.toIso8601String() ?? '',
        ));
      },
    );
    // groupIdentifier and providerBundleIdentifier are iOS-only.
    await _openVpn!.initialize(
      groupIdentifier: null,
      providerBundleIdentifier: null,
      localizedDescription: 'AlterVPN',
    );
    _initialized = true;
  }

  static Future<void> startVpn(VpnConfig config) async {
    await _ensureInitialized();
    if (config.config.isEmpty) {
      throw Exception('OpenVPN config is empty — cannot connect.');
    }
    await _openVpn!.connect(
      config.config,
      config.serverName,
      username: config.username,
      password: config.password,
      // certIsRequired: false allows VPNGate servers that embed auth inline.
      certIsRequired: false,
    );
  }

  static Future<void> stopVpn() async {
    _openVpn?.disconnect();
    // Emit disconnected immediately so UI updates without waiting for the
    // native callback (which may be delayed on some devices).
    _stageController.add(VpnStage.disconnected);
  }

  static Future<String?> currentStage() async {
    if (_openVpn == null) return null;
    try {
      final stage = await _openVpn!.stage();
      return stage.name;
    } catch (_) {
      return null;
    }
  }

  static Future<bool> isConnected() async {
    if (_openVpn == null) return false;
    try {
      return await _openVpn!.isConnected();
    } catch (_) {
      return false;
    }
  }
}
