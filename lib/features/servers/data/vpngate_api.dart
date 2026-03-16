import 'package:dio/dio.dart';
import 'package:csv/csv.dart';
import 'server_model.dart';

class VpnGateApi {
  // Primary VPNGate endpoint.
  static const String _primaryUrl = 'https://www.vpngate.net/api/iphone/';

  // Community mirror used as fallback when the primary endpoint is
  // unreachable. Maintained by the VPNGate project.
  static const String _mirrorUrl = 'https://vpngate.net/api/iphone/';

  final Dio _dio;

  VpnGateApi({Dio? dio})
      : _dio = dio ??
            Dio(BaseOptions(
              connectTimeout: const Duration(seconds: 20),
              receiveTimeout: const Duration(seconds: 40),
              headers: {
                'User-Agent': 'AlterVPN/1.0',
              },
            ));

  Future<List<ServerModel>> fetchServers() async {
    // Try primary URL first, then fall back to mirror on any error.
    for (final url in [_primaryUrl, _mirrorUrl]) {
      try {
        final response = await _dio.get<String>(url);
        if (response.statusCode == 200 && response.data != null) {
          final servers = _parseResponse(response.data!);
          if (servers.isNotEmpty) return servers;
        }
      } on DioException catch (e) {
        // Swallow and try next endpoint.
        final msg = e.response?.statusCode != null
            ? 'HTTP ${e.response!.statusCode}'
            : e.message ?? e.type.name;
        // ignore: avoid_print
        print('[VpnGateApi] $url failed: $msg — trying next endpoint.');
      } catch (e) {
        // ignore: avoid_print
        print('[VpnGateApi] $url failed: $e — trying next endpoint.');
      }
    }
    throw Exception(
      'Unable to reach VPNGate server list. '
      'Please check your internet connection and try again.\n'
      'Source: $_primaryUrl',
    );
  }

  List<ServerModel> _parseResponse(String rawData) {
    final lines = rawData.split('\n');
    // Remove comment lines (starting with '*') and rejoin
    final csvData = lines
        .where((line) => !line.startsWith('*'))
        .join('\n');

    final rows = const CsvToListConverter(eol: '\n').convert(csvData);

    if (rows.isEmpty) return [];

    final servers = <ServerModel>[];
    // Skip header row (index 0)
    for (int i = 1; i < rows.length; i++) {
      final row = rows[i];
      if (row.length < 15) continue;

      try {
        final base64Config = row[14]?.toString() ?? '';
        if (base64Config.isEmpty) continue;

        servers.add(ServerModel(
          hostName: row[0]?.toString() ?? '',
          ip: row[1]?.toString() ?? '',
          countryShort: row[5]?.toString() ?? '',
          countryLong: row[6]?.toString() ?? '',
          numVpnSessions: int.tryParse(row[7]?.toString() ?? '0') ?? 0,
          ping: int.tryParse(row[3]?.toString() ?? '0') ?? 0,
          speed: double.tryParse(row[4]?.toString() ?? '0') ?? 0,
          openVpnConfigDataBase64: base64Config,
          supportsTcp: true,
        ));
      } catch (_) {
        continue;
      }
    }

    return servers;
  }
}
