import 'dart:convert';
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

  /// Parses the raw backend response, auto-detecting JSON vs. VPNGate CSV.
  List<ServerModel> _parseResponse(String rawData) {
    final trimmed = rawData.trimLeft();
    // JSON response: starts with '[' or '{'
    if (trimmed.startsWith('[') || trimmed.startsWith('{')) {
      return _parseJson(trimmed);
    }
    return _parseCsv(rawData);
  }

  /// Parses a JSON array of server objects returned by a custom JSON backend.
  ///
  /// Each object is normalised via [ServerModel.fromJson], which supports
  /// both raw-text configs (`ovpnConfig`) and base64 blobs
  /// (`openVpnConfigDataBase64`).
  List<ServerModel> _parseJson(String jsonData) {
    try {
      final dynamic decoded = json.decode(jsonData);
      final List<dynamic> list = decoded is List
          ? decoded
          : (decoded['servers'] as List? ?? [decoded]);
      final servers = <ServerModel>[];
      for (final item in list) {
        if (item is! Map<String, dynamic>) {
          debugPrint('[VpnGateApi] Skipping non-object JSON item: $item');
          continue;
        }
        try {
          final server = ServerModel.fromJson(item);
          if (!server.hasConfig) {
            debugPrint(
                '[VpnGateApi] JSON server missing config, skipping: '
                '${server.hostName}');
            continue;
          }
          servers.add(server);
        } catch (e) {
          debugPrint('[VpnGateApi] Failed to parse JSON server object: $e');
        }
      }
      debugPrint('[VpnGateApi] Parsed ${servers.length} servers from JSON');
      return servers;
    } catch (e) {
      debugPrint('[VpnGateApi] JSON parse error: $e');
      return [];
    }
  }

  /// Parses the VPNGate CSV format.
  ///
  /// VPNGate CSV column order (0-based):
  ///   0  HostName
  ///   1  IP
  ///   2  Score
  ///   3  Ping
  ///   4  Speed
  ///   5  CountryLong
  ///   6  CountryShort
  ///   7  NumVpnSessions
  ///   ...
  ///   14 OpenVPN_ConfigData_Base64
  List<ServerModel> _parseCsv(String rawData) {
    final lines = rawData.split('\n');
    // Remove VPNGate comment lines (starting with '*') and rejoin
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
        if (base64Config.isEmpty) {
          debugPrint(
              '[VpnGateApi] CSV row $i missing config (col 14), skipping: '
              '${row[0]}');
          continue;
        }

        servers.add(ServerModel(
          hostName: row[0]?.toString() ?? '',
          ip: row[1]?.toString() ?? '',
          // Column 5 = CountryLong (full name), column 6 = CountryShort (code)
          countryLong: row[5]?.toString() ?? '',
          countryShort: row[6]?.toString() ?? '',
          numVpnSessions: int.tryParse(row[7]?.toString() ?? '0') ?? 0,
          ping: int.tryParse(row[3]?.toString() ?? '0') ?? 0,
          speed: double.tryParse(row[4]?.toString() ?? '0') ?? 0,
          openVpnConfigDataBase64: base64Config,
          supportsTcp: true,
        ));
      } catch (e) {
        debugPrint('[VpnGateApi] Failed to parse CSV row $i: $e');
        continue;
      }
    }

    debugPrint('[VpnGateApi] Parsed ${servers.length} servers from CSV');
    return servers;
  }
}
