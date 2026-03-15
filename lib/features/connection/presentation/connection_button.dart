import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../domain/connection_controller.dart';
import '../domain/connection_state.dart';
import '../../../widgets/animated_connection_ring.dart';

class ConnectionButton extends ConsumerWidget {
  const ConnectionButton({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final connectionState = ref.watch(connectionControllerProvider);
    final controller = ref.read(connectionControllerProvider.notifier);

    return GestureDetector(
      onTap: connectionState.selectedServer != null
          ? controller.toggleConnection
          : null,
      child: AnimatedConnectionRing(
        status: connectionState.status,
        isEnabled: connectionState.selectedServer != null,
      ),
    );
  }
}
