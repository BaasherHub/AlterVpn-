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

  /// Raw bytes received (cumulative from VPN status update).
  double get downloadBytes {
    return double.tryParse(byteIn) ?? 0;
  }

  /// Raw bytes sent (cumulative from VPN status update).
  double get uploadBytes {
    return double.tryParse(byteOut) ?? 0;
  }

  // Keep legacy names pointing to raw bytes for display formatting.
  double get downloadSpeed => downloadBytes;
  double get uploadSpeed => uploadBytes;

  @override
  String toString() =>
      'VpnStatus(byteIn: $byteIn, byteOut: $byteOut, duration: $duration)';
}
