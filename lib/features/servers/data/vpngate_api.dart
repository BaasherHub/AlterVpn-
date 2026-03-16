import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:csv/csv.dart';
import '../../../core/constants/api_constants.dart';
import 'server_model.dart';

class VpnGateApi {
  // All traffic goes through the Railway relay backend so that the server list
  // is reachable even when vpngate.net is blocked in the user's region.
  // To change the endpoint, update ApiConstants.backendBaseUrl in
  // lib/core/constants/api_constants.dart — no other file needs editing.
  static const String _backendUrl = ApiConstants.serversUrl;

  final Dio _dio;

  VpnGateApi({Dio? dio})
      : _dio = dio ??
            Dio(BaseOptions(
              connectTimeout: const Duration(seconds: 15),
              receiveTimeout: const Duration(seconds: 30),
              headers: {
                'User-Agent': 'AlterVPN/1.0',
              },
            ));

  Future<List<ServerModel>> fetchServers() async {
    try {
      final response = await _dio.get<String>(_backendUrl);
      if (response.statusCode == 200 && response.data != null) {
        final servers = _parseResponse(response.data!);
        if (servers.isNotEmpty) return servers;
        throw Exception(
          'Server list is empty. The backend returned no usable servers. '
          'Please try again later.',
        );
      }
      throw Exception(
        'Unexpected response from backend '
        '(HTTP ${response.statusCode}). Please try again.',
      );
    } on DioException catch (e) {
      final detail = e.response?.statusCode != null
          ? 'HTTP ${e.response!.statusCode}'
          : e.message ?? e.type.name;
      debugPrint('[VpnGateApi] Backend request failed ($_backendUrl): $detail');
      throw Exception(
        'Unable to reach the server-list backend. '
        'Please check your internet connection and try again.',
      );
    } catch (e) {
      debugPrint('[VpnGateApi] fetchServers error: $e');
      rethrow;
    }
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
