import 'package:flutter/material.dart';
import '../core/constants/app_colors.dart';
import '../features/connection/domain/connection_state.dart';

class StatusIndicator extends StatelessWidget {
  final ConnectionStatus status;
  final double size;

  const StatusIndicator({
    super.key,
    required this.status,
    this.size = 8,
  });

  Color get _color {
    switch (status) {
      case ConnectionStatus.connected:
        return AppColors.accentGreen;
      case ConnectionStatus.connecting:
      case ConnectionStatus.disconnecting:
        return AppColors.accentGold;
      case ConnectionStatus.error:
        return AppColors.statusError;
      case ConnectionStatus.disconnected:
        return AppColors.statusDisconnected;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: _color,
        shape: BoxShape.circle,
      ),
    );
  }
}
