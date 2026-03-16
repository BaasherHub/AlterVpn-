import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../domain/connection_controller.dart';
import '../domain/session_controller.dart';
import '../../../widgets/animated_connection_ring.dart';
import 'ad_gate_dialog.dart';

class ConnectionButton extends ConsumerWidget {
  const ConnectionButton({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final connectionState = ref.watch(connectionControllerProvider);
    final sessionData = ref.watch(sessionControllerProvider);

    Future<void> handleTap() async {
      final controller =
          ref.read(connectionControllerProvider.notifier);

      if (connectionState.isConnected || connectionState.isConnecting) {
        await controller.disconnect();
        return;
      }

      if (connectionState.selectedServer == null) return;

      // If the user has a 24-hour free pass, connect directly.
      if (sessionData.hasFreePass) {
        await ref
            .read(sessionControllerProvider.notifier)
            .onFreePassUsed();
        await controller.connect();
        return;
      }

      // Otherwise show the ad-gate dialog.
      if (!context.mounted) return;
      final rewarded = await showAdGateDialog(context);
      if (!rewarded) return;

      // Ad was shown and reward was earned — record streak and connect.
      await ref
          .read(sessionControllerProvider.notifier)
          .onAdRewarded();
      await controller.connect();
    }

    return GestureDetector(
      onTap: connectionState.selectedServer != null ? handleTap : null,
      child: AnimatedConnectionRing(
        status: connectionState.status,
        isEnabled: connectionState.selectedServer != null,
      ),
    );
  }
}
