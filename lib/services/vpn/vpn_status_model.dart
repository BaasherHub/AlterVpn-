class VpnStatusModel {
  final String byteIn;
  final String byteOut;
  final String duration;
  final String lastPacketReceive;
  final String connectedOn;

  const VpnStatusModel({
    this.byteIn = '0',
    this.byteOut = '0',
    this.duration = '00:00:00',
    this.lastPacketReceive = '0',
    this.connectedOn = '',
  });

  factory VpnStatusModel.empty() => const VpnStatusModel();

  double get downloadSpeed {
    final bytes = double.tryParse(byteIn) ?? 0;
    return bytes;
  }

  double get uploadSpeed {
    final bytes = double.tryParse(byteOut) ?? 0;
    return bytes;
  }

  @override
  String toString() =>
      'VpnStatus(byteIn: $byteIn, byteOut: $byteOut, duration: $duration)';
}
