import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../servers/data/server_model.dart';
import '../../servers/domain/server_controller.dart';
import '../../../services/vpn/vpn_engine.dart';
import '../../../services/vpn/vpn_config_model.dart';
import '../../../services/vpn/vpn_status_model.dart';
import '../../../core/constants/app_strings.dart';
import '../../../core/utils/ovpn_validator.dart';
import '../../../core/utils/vpn_error_mapper.dart';
import 'connection_state.dart';
import 'session_controller.dart';

final connectionControllerProvider =
    NotifierProvider<ConnectionController, AlterConnectionState>(
  ConnectionController.new,
);

/// Maximum time allowed for a single connection attempt before it is
/// considered a timeout failure.
const _kConnectTimeout = Duration(seconds: 30);

class ConnectionController extends Notifier<AlterConnectionState> {
  StreamSubscription<VpnStage>? _stageSubscription;
  StreamSubscription<VpnStatusModel>? _statusSubscription;
  Timer? _durationTimer;

  /// Guards against duplicate concurrent connect calls.
  bool _connectInProgress = false;

  /// Timeout timer for the current connection attempt.
  Timer? _connectTimeoutTimer;

  /// Set to `true` once a TCP fallback attempt has been made for the current
  /// connection sequence so we do not fall back more than once.
  bool _tcpFallbackAttempted = false;

  @override
  AlterConnectionState build() {
    _listenToVpnStage();
    _listenToVpnStatus();
    _listenToSessionExpiry();
    ref.onDispose(() {
      _stageSubscription?.cancel();
      _statusSubscription?.cancel();
      _durationTimer?.cancel();
      _connectTimeoutTimer?.cancel();
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

  void _listenToSessionExpiry() {
    ref.listen<SessionData>(sessionControllerProvider, (prev, next) {
      if (next.sessionState == SessionState.expired && state.isConnected) {
        // Session timer ran out — disconnect automatically.
        disconnect();
      }
    });
  }

  void _handleStageChange(VpnStage stage) {
    if (stage.isConnected && !state.isConnected) {
      _onConnected();
    } else if (stage == VpnStage.disconnected || stage == VpnStage.unknown) {
      _onDisconnected(stage);
    } else if (stage == VpnStage.denied) {
      _onDenied();
    } else if (stage.isConnecting) {
      state = state.copyWith(
        status: ConnectionStatus.connecting,
        vpnStage: stage,
      );
    }
  }

  void _onConnected() {
    debugPrint('[ConnectionController] connect_result=connected');
    _cancelConnectTimeout();
    _connectInProgress = false;
    _startTimer();
    state = state.copyWith(
      status: ConnectionStatus.connected,
      vpnStage: VpnStage.connected,
      clearError: true,
    );
  }

  void _onDisconnected(VpnStage stage) {
    debugPrint('[ConnectionController] connect_result=disconnected stage=$stage');
    _cancelConnectTimeout();
    _connectInProgress = false;
    _stopTimer();
    state = state.copyWith(
      status: ConnectionStatus.disconnected,
      vpnStage: stage,
      connectionDuration: Duration.zero,
    );
  }

  void _onDenied() {
    debugPrint('[ConnectionController] connect_result=denied');
    _cancelConnectTimeout();
    _connectInProgress = false;
    _stopTimer();
    state = state.copyWith(
      status: ConnectionStatus.error,
      vpnStage: VpnStage.denied,
      errorMessage: AppStrings.permissionDenied,
    );
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

  void _cancelConnectTimeout() {
    _connectTimeoutTimer?.cancel();
    _connectTimeoutTimer = null;
  }

  /// Starts the connection timeout watchdog.
  ///
  /// If [_kConnectTimeout] elapses while we are still in a connecting state,
  /// the attempt is cancelled. When the server has a TCP fallback URL
  /// ([ServerModel.ovpnUrlTcp]) and no TCP attempt has been made yet, the
  /// fallback is tried automatically before surfacing an error.
  void _startConnectTimeout(ServerModel server) {
    _cancelConnectTimeout();
    _connectTimeoutTimer = Timer(_kConnectTimeout, () async {
      if (!state.isConnecting) return; // already resolved

      debugPrint(
        '[ConnectionController] connect_timeout '
        'server=${server.id.isNotEmpty ? server.id : server.hostName}',
      );

      await VpnEngine.stopVpn();

      // Attempt TCP fallback once if the server advertises an alternate URL.
      if (!_tcpFallbackAttempted && server.ovpnUrlTcp.isNotEmpty) {
        debugPrint(
          '[ConnectionController] tcp_fallback_start '
          'server=${server.id.isNotEmpty ? server.id : server.hostName}',
        );
        _tcpFallbackAttempted = true;
        await _doConnectFallbackTcp(server);
        return;
      }

      _connectInProgress = false;
      state = state.copyWith(
        status: ConnectionStatus.error,
        errorMessage: AppStrings.transportTimeout,
      );
    });
  }

  /// Retries the connection using the server's TCP fallback profile.
  ///
  /// Downloads and validates [ServerModel.ovpnUrlTcp], then starts a new
  /// VPN connection attempt with its own timeout watchdog.
  Future<void> _doConnectFallbackTcp(ServerModel server) async {
    state = state.copyWith(
      status: ConnectionStatus.connecting,
      clearError: true,
    );

    String vpnConfig;
    try {
      final repo = ref.read(serverRepositoryProvider);
      vpnConfig = await repo.resolveConfigFromUrl(server.ovpnUrlTcp);
    } catch (e) {
      _connectInProgress = false;
      final mapped = VpnErrorMapper.map(e.toString());
      debugPrint(
        '[ConnectionController] tcp_fallback_config_error '
        'server=${server.id.isNotEmpty ? server.id : server.hostName} '
        'category=${mapped.category}',
      );
      state = state.copyWith(
        status: ConnectionStatus.error,
        errorMessage: mapped.userMessage,
      );
      return;
    }

    final validation = OvpnValidator.validate(vpnConfig);
      'server=${server.id.isNotEmpty ? server.id : server.hostName} '
      'valid=${validation.isValid}',
    );

    if (!validation.isValid) {
      _connectInProgress = false;
      state = state.copyWith(
        status: ConnectionStatus.error,
        errorMessage: validation.errorMessage,
      );
      return;
    }

    try {
      final config = VpnConfig(
        config: vpnConfig,
        serverName: server.hostName,
        country: server.countryLong,
      );
      _startConnectTimeout(server);
      await VpnEngine.startVpn(config);
    } catch (e) {
      _cancelConnectTimeout();
      _connectInProgress = false;
      final mapped = VpnErrorMapper.map(e.toString());
      debugPrint(
        '[ConnectionController] tcp_fallback_connect_error '
        'category=${mapped.category} '
        'server=${server.id.isNotEmpty ? server.id : server.hostName}',
      );
      state = state.copyWith(
        status: ConnectionStatus.error,
        errorMessage: mapped.userMessage,
      );
    }
  }

  Future<void> toggleConnection() async {
    if (state.isConnected || state.isConnecting) {
      await disconnect();
    } else {
      await connect();
    }
  }

  Future<void> connect() async {
    // Guard: ignore duplicate connect calls while one is in progress.
    if (_connectInProgress) {
      debugPrint('[ConnectionController] connect_ignored reason=already_in_progress');
      return;
    }

    final server =
        state.selectedServer ?? ref.read(selectedServerProvider);

    if (server == null) {
      debugPrint('[ConnectionController] connect_ignored reason=no_server_selected');
      return;
    }

    await _doConnect(server);
  }

  Future<void> _doConnect(ServerModel server) async {
    _connectInProgress = true;
    _tcpFallbackAttempted = false;
    state = state.copyWith(
      status: ConnectionStatus.connecting,
      clearError: true,
    );

    debugPrint(
      '[ConnectionController] connect_start '
      'server_id=${server.id.isNotEmpty ? server.id : server.hostName} '
      'country=${server.countryShort}',
    );

    // --- Preflight: decode / fetch config ----------------------------------
    // For servers with inline configs (base64 or raw text) this is immediate.
    // For servers with ovpnUrl, the profile is downloaded from the URL first.
    String vpnConfig;
    try {
      final repo = ref.read(serverRepositoryProvider);
      vpnConfig = await repo.resolveConfig(server);
    } catch (e) {
      _connectInProgress = false;
      final mapped = VpnErrorMapper.map(e.toString());
      debugPrint(
        '[ConnectionController] config_resolve_error '
        'server_id=${server.id.isNotEmpty ? server.id : server.hostName} '
        'category=${mapped.category}',
      );
      state = state.copyWith(
        status: ConnectionStatus.error,
        errorMessage: mapped.userMessage,
      );
      return;
    }

    // --- Preflight: validate profile ---------------------------------------
    final validation = OvpnValidator.validate(vpnConfig);
    debugPrint(
      '[ConnectionController] profile_validation '
      'server_id=${server.id.isNotEmpty ? server.id : server.hostName} '
      'valid=${validation.isValid}',
    );

    if (!validation.isValid) {
      _connectInProgress = false;
      state = state.copyWith(
        status: ConnectionStatus.error,
        errorMessage: validation.errorMessage,
      );
      return;
    }

    // --- Connect ----------------------------------------------------------
    try {
      final config = VpnConfig(
        config: vpnConfig,
        serverName: server.hostName,
        country: server.countryLong,
      );

      // Start timeout watchdog before handing off to the native engine.
      _startConnectTimeout(server);

      await VpnEngine.startVpn(config);
    } catch (e) {
      _cancelConnectTimeout();
      _connectInProgress = false;
      final mapped = VpnErrorMapper.map(e.toString());
      debugPrint(
        '[ConnectionController] connect_error '
        'category=${mapped.category} '
        'server_id=${server.id.isNotEmpty ? server.id : server.hostName}',
      );
      state = state.copyWith(
        status: ConnectionStatus.error,
        errorMessage: mapped.userMessage,
      );
    }
  }

  Future<void> disconnect() async {
    debugPrint('[ConnectionController] disconnect_start');
    _cancelConnectTimeout();
    _connectInProgress = false;
    state = state.copyWith(status: ConnectionStatus.disconnecting);
    try {
      await VpnEngine.stopVpn();
    } catch (_) {
      // Disconnect errors are intentionally ignored — the VPN process
      // may already be stopped or unreachable at this point.
    }
    _stopTimer();
    // End the session timer.
    await ref.read(sessionControllerProvider.notifier).endSession();
    debugPrint('[ConnectionController] disconnect_complete');
    state = state.copyWith(
      status: ConnectionStatus.disconnected,
      connectionDuration: Duration.zero,
    );
  }

  void selectServer(ServerModel server) {
    debugPrint(
      '[ConnectionController] server_selected '
      'id=${server.id.isNotEmpty ? server.id : server.hostName} '
      'country=${server.countryShort}',
    );
    state = state.copyWith(selectedServer: server);
    ref.read(selectedServerProvider.notifier).state = server;
  }
}
