import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../servers/data/server_model.dart';
import '../../servers/domain/server_controller.dart';
import '../../../services/vpn/vpn_engine.dart';
import '../../../services/vpn/vpn_config_model.dart';
import '../../../services/vpn/vpn_status_model.dart';
import 'connection_state.dart';

final connectionControllerProvider =
    NotifierProvider<ConnectionController, AlterConnectionState>(
  ConnectionController.new,
);

class ConnectionController extends Notifier<AlterConnectionState> {
  StreamSubscription<VpnStage>? _stageSubscription;
  StreamSubscription<VpnStatusModel>? _statusSubscription;
  Timer? _durationTimer;

  @override
  AlterConnectionState build() {
    _listenToVpnStage();
    _listenToVpnStatus();
    ref.onDispose(() {
      _stageSubscription?.cancel();
      _statusSubscription?.cancel();
      _durationTimer?.cancel();
    });
    return const AlterConnectionState();
  }

  void _listenToVpnStage() {
    _stageSubscription = VpnEngine.vpnStageStream.listen(
      _handleStageChange,
      onError: (_) {
        state = state.copyWith(
          status: ConnectionStatus.error,
          errorMessage: 'VPN monitoring error',
        );
      },
    );
  }

  void _listenToVpnStatus() {
    _statusSubscription = VpnEngine.vpnStatusStream.listen(
      (status) => state = state.copyWith(vpnStatus: status),
      onError: (_) {},
    );
  }

  void _handleStageChange(VpnStage stage) {
    if (stage.isConnected && !state.isConnected) {
      _startTimer();
      state = state.copyWith(
        status: ConnectionStatus.connected,
        vpnStage: stage,
        clearError: true,
      );
    } else if (stage == VpnStage.disconnected || stage == VpnStage.unknown) {
      _stopTimer();
      state = state.copyWith(
        status: ConnectionStatus.disconnected,
        vpnStage: stage,
        connectionDuration: Duration.zero,
      );
    } else if (stage == VpnStage.denied) {
      _stopTimer();
      state = state.copyWith(
        status: ConnectionStatus.error,
        vpnStage: stage,
        errorMessage: 'VPN permission denied',
      );
    } else if (stage.isConnecting) {
      state = state.copyWith(
        status: ConnectionStatus.connecting,
        vpnStage: stage,
      );
    }
  }

  void _startTimer() {
    _durationTimer?.cancel();
    _durationTimer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (state.isConnected) {
        state = state.copyWith(
          connectionDuration:
              state.connectionDuration + const Duration(seconds: 1),
        );
      }
    });
  }

  void _stopTimer() {
    _durationTimer?.cancel();
    _durationTimer = null;
  }

  Future<void> toggleConnection() async {
    if (state.isConnected || state.isConnecting) {
      await disconnect();
    } else {
      await connect();
    }
  }

  Future<void> connect() async {
    final server =
        state.selectedServer ?? ref.read(selectedServerProvider);

    if (server == null) return;

    state = state.copyWith(
      status: ConnectionStatus.connecting,
      clearError: true,
    );

    try {
      final config = VpnConfig(
        config: server.openVpnConfig,
        serverName: server.hostName,
        country: server.countryLong,
      );
      await VpnEngine.startVpn(config);
    } catch (e) {
      state = state.copyWith(
        status: ConnectionStatus.error,
        errorMessage: e.toString(),
      );
    }
  }

  Future<void> disconnect() async {
    state = state.copyWith(status: ConnectionStatus.disconnecting);
    try {
      await VpnEngine.stopVpn();
    } catch (_) {
      // Ignore errors on disconnect
    }
    _stopTimer();
    state = state.copyWith(
      status: ConnectionStatus.disconnected,
      connectionDuration: Duration.zero,
    );
  }

  void selectServer(ServerModel server) {
    state = state.copyWith(selectedServer: server);
    ref.read(selectedServerProvider.notifier).state = server;
  }
}
