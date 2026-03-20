import 'dart:convert';
import 'dart:math' show min;
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
        final body = response.data!;

        // Log payload size to detect unexpectedly large responses.
        debugPrint(
          '[VpnGateApi] payload_bytes=${body.length} endpoint=$_backendUrl',
        );

        // Guard: reject responses that are clearly not JSON.
        // The /api/iphone/ endpoint always returns application/json, so a
        // non-JSON body indicates a proxy misconfiguration or upstream error.
        // We check the body shape unconditionally — even if Content-Type says
        // application/json, a garbled body must not reach the parser.
        final contentType =
            response.headers.value(Headers.contentTypeHeader) ?? '';
        final trimmed = body.trimLeft();
        final looksLikeJson =
            trimmed.startsWith('{') || trimmed.startsWith('[');
        if (!looksLikeJson) {
          final preview = trimmed.substring(0, min(200, trimmed.length));
          debugPrint(
            '[VpnGateApi] REJECT reason=non_json '
            'content_type=$contentType preview=$preview',
          );
          throw Exception(
            'Server returned an unexpected format (not JSON). '
            'Please try again or contact support.',
          );
        }

        final servers = _parseResponse(body);
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

  /// Downloads a raw `.ovpn` profile from [url] and returns it as a string.
  ///
  /// Throws an [Exception] with a user-friendly message if the download fails
  /// or the server responds with a non-200 status code.
  Future<String> fetchRawConfig(String url) async {
    try {
      final response = await _dio.get<String>(
        url,
        options: Options(receiveTimeout: const Duration(seconds: 30)),
      );
      if (response.statusCode == 200 && response.data != null) {
        final config = response.data!;
        debugPrint(
          '[VpnGateApi] config_fetch_ok url=$url bytes=${config.length}',
        );
        return config;
      }
      throw Exception(
        'Config fetch failed (HTTP ${response.statusCode}).',
      );
    } on DioException catch (e) {
      final detail = e.response?.statusCode != null
          ? 'HTTP ${e.response!.statusCode}'
          : e.message ?? e.type.name;
      debugPrint('[VpnGateApi] config_fetch_error url=$url detail=$detail');
      throw Exception(
        'Unable to download VPN configuration. '
        'Please check your internet connection and try again.',
      );
    } catch (e) {
      debugPrint('[VpnGateApi] fetchRawConfig error url=$url: $e');
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
  /// (`openVpnConfigDataBase64`). Entries that fail validation are excluded
  /// and the rejection reason is logged for debugging.
  List<ServerModel> _parseJson(String jsonData) {
    try {
      final dynamic decoded = json.decode(jsonData);
      final List<dynamic> list = decoded is List
          ? decoded
          : (decoded['servers'] as List? ?? [decoded]);
      final servers = <ServerModel>[];
      int skipped = 0;
      for (final item in list) {
        if (item is! Map<String, dynamic>) {
          debugPrint(
              '[VpnGateApi] SKIP reason=non_object item: $item');
          skipped++;
          continue;
        }
        try {
          final server = ServerModel.fromJson(item);
          if (!server.hasConfig) {
            debugPrint(
                '[VpnGateApi] SKIP reason=no_config '
                'id=${server.id} host=${server.hostName}');
            skipped++;
            continue;
          }
          servers.add(server);
        } catch (e) {
          debugPrint(
              '[VpnGateApi] SKIP reason=parse_error error=$e '
              'entry=${item['hostName'] ?? item['id'] ?? '?'}');
          skipped++;
        }
      }
      debugPrint(
          '[VpnGateApi] JSON parsed=${servers.length} skipped=$skipped');
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
              '[VpnGateApi] SKIP reason=no_config(csv) row=$i '
              'host=${row[0]}');
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
        debugPrint('[VpnGateApi] SKIP reason=parse_error(csv) row=$i error=$e');
        continue;
      }
    }

    debugPrint('[VpnGateApi] CSV parsed=${servers.length}');
    return servers;
  }
}
