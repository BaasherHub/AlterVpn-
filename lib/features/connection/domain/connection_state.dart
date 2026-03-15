import '../../servers/data/server_model.dart';
import '../../../services/vpn/vpn_engine.dart';
import '../../../services/vpn/vpn_status_model.dart';

enum ConnectionStatus {
  disconnected,
  connecting,
  connected,
  disconnecting,
  error,
}

class AlterConnectionState {
  final ConnectionStatus status;
  final ServerModel? selectedServer;
  final VpnStage vpnStage;
  final VpnStatusModel vpnStatus;
  final Duration connectionDuration;
  final String? errorMessage;

  const AlterConnectionState({
    this.status = ConnectionStatus.disconnected,
    this.selectedServer,
    this.vpnStage = VpnStage.disconnected,
    this.vpnStatus = const VpnStatusModel(),
    this.connectionDuration = Duration.zero,
    this.errorMessage,
  });

  bool get isConnected => status == ConnectionStatus.connected;
  bool get isConnecting => status == ConnectionStatus.connecting;
  bool get isDisconnecting => status == ConnectionStatus.disconnecting;
  bool get isDisconnected => status == ConnectionStatus.disconnected;
  bool get hasError => status == ConnectionStatus.error;

  AlterConnectionState copyWith({
    ConnectionStatus? status,
    ServerModel? selectedServer,
    VpnStage? vpnStage,
    VpnStatusModel? vpnStatus,
    Duration? connectionDuration,
    String? errorMessage,
    bool clearError = false,
    bool clearServer = false,
  }) {
    return AlterConnectionState(
      status: status ?? this.status,
      selectedServer:
          clearServer ? null : (selectedServer ?? this.selectedServer),
      vpnStage: vpnStage ?? this.vpnStage,
      vpnStatus: vpnStatus ?? this.vpnStatus,
      connectionDuration: connectionDuration ?? this.connectionDuration,
      errorMessage: clearError ? null : (errorMessage ?? this.errorMessage),
    );
  }

  @override
  String toString() =>
      'ConnectionState(status: $status, stage: $vpnStage)';
}
