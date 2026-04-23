import 'dart:convert';
import '../models/sampling_drive_models.dart';
import '../constants/app_constants.dart';
import 'package:http/http.dart' as http;
import '../network/ssl_http_client.dart';

class SamplingExecutionService {
  static String get _baseUrl => AppConstants.baseUrl;
  static const String _apiPath = '/api/SamplingExecutionEntry';
  static http.Client? _httpClient;

  static Map<String, String> get _jsonHeaders => {
        'Content-Type': 'application/json',
        'Accept': 'application/json',
      };

  /// Get SSL-enabled HTTP client
  static Future<http.Client> _getClient() async {
    _httpClient ??= await SslHttpClient.getClient();
    return _httpClient!;
  }

  /// Normalize any common API payload shape into a List of JSON objects
  static List<dynamic> _normalizeToList(dynamic data) {
    if (data == null) return const [];
    if (data is List) return data;
    
    if (data is String) {
      try {
        final parsed = jsonDecode(data);
        return _normalizeToList(parsed);
      } catch (e) {
        return const [];
      }
    }
    
    if (data is Map) {
      const candidates = [
        'raw',
        'items',
        'data',
        'records',
        'result',
        'Results',
        'Rows',
      ];
      
      for (final k in candidates) {
        if (data.containsKey(k)) {
          final list = _normalizeToList(data[k]);
          if (list.isNotEmpty) return list;
        }
      }
      
      // Last resort: scan nested values
      for (final v in data.values) {
        final list = _normalizeToList(v);
        if (list.isNotEmpty) return list;
      }
    }
    
    return const [];
  }

  static Map<String, dynamic> _ok(List<SamplingDriveEntry> entries) => {
        'success': true,
        'data': entries,
      };

  static Map<String, dynamic> _fail(String msg, {Object? extra}) => {
        'success': false,
        'error': msg,
        if (extra != null) 'extra': extra,
      };

  static List<SamplingDriveEntry> _parseEntries(List<dynamic> itemList) {
    final entries = <SamplingDriveEntry>[];
    for (final item in itemList) {
      if (item is Map<String, dynamic>) {
        entries.add(SamplingDriveEntry.fromJson(item));
      } else if (item is String) {
        final parsed = jsonDecode(item);
        entries.add(
          SamplingDriveEntry.fromJson(parsed as Map<String, dynamic>),
        );
      } else {
        throw const FormatException('List item is not a JSON object');
      }
    }
    return entries;
  }

  /// Flexible search hitting `/api/SamplingExecutionEntry/search`
  static Future<Map<String, dynamic>> searchSamplingDriveEntries({
    String? retailerCode,
    String? retailerName,
    String? painterName,
    String? start,
    String? end,
    int top = 200,
  }) async {
    try {
      final queryParams = <String, String>{};
      
      if (retailerCode != null && retailerCode.isNotEmpty) {
        queryParams['retailerCode'] = retailerCode;
      }
      if (retailerName != null && retailerName.isNotEmpty) {
        queryParams['retailerName'] = retailerName;
      }
      if (painterName != null && painterName.isNotEmpty) {
        queryParams['painterNameFilter'] = painterName;
      }
      if (start != null && start.isNotEmpty) {
        queryParams['start'] = start;
      }
      if (end != null && end.isNotEmpty) {
        queryParams['end'] = end;
      }
      queryParams['top'] = top.toString();

      final queryString = queryParams.entries
          .map((e) =>
              '${Uri.encodeComponent(e.key)}=${Uri.encodeComponent(e.value)}')
          .join('&');

      final uri = Uri.parse('$_baseUrl$_apiPath/search?$queryString');
      final client = await _getClient();
      final response = await client.get(uri, headers: _jsonHeaders);

      if (response.statusCode == 200) {
        final result = jsonDecode(response.body);
        final itemList = _normalizeToList(result);
        
        if (itemList.isEmpty) {
          return _fail('Search returned no rows');
        }
        
        final entries = _parseEntries(itemList);
        return _ok(entries);
      } else {
        return _fail('Failed to search: ${response.statusCode}');
      }
    } catch (e) {
      return _fail('Failed to search sampling drive entries: $e');
    }
  }

  /// Fetch the latest 100 entries from `/api/SamplingExecutionEntry/top100`
  static Future<Map<String, dynamic>> getTop100SamplingDriveEntries() async {
    try {
      final uri = Uri.parse('$_baseUrl$_apiPath/top100');
      final client = await _getClient();
      final response = await client.get(uri, headers: _jsonHeaders);

      if (response.statusCode == 200) {
        final result = jsonDecode(response.body);
        final itemList = _normalizeToList(result);
        
        if (itemList.isEmpty) {
          return _fail('Top100 returned no rows');
        }
        
        final entries = _parseEntries(itemList);
        return _ok(entries);
      } else {
        return _fail('Failed to fetch top100: ${response.statusCode}');
      }
    } catch (e) {
      return _fail('Failed to fetch top 100 sampling drive entries: $e');
    }
  }

  /// Convenience: try top100 first, fall back to `/search?top=100` if empty/blocked
  static Future<Map<String, dynamic>> getTop100WithFallback() async {
    final r = await getTop100SamplingDriveEntries();
    if (r['success'] == true) return r;
    
    return searchSamplingDriveEntries(top: 100);
  }

  /// Submit a new sampling execution entry
  static Future<Map<String, dynamic>> submitSamplingExecution(
    SamplingDriveRequest request,
  ) async {
    try {
      final uri = Uri.parse('$_baseUrl$_apiPath/submit');
      
      print('[SAMPLING_EXEC] Submitting to: $uri');
      print('[SAMPLING_EXEC] Request body: ${json.encode(request.toJson())}');
      
      final client = await _getClient();
      final response = await client.post(
        uri,
        headers: _jsonHeaders,
        body: json.encode(request.toJson()),
      );

      print('[SAMPLING_EXEC] Response status: ${response.statusCode}');
      print('[SAMPLING_EXEC] Response body: ${response.body}');

      if (response.statusCode == 200 || response.statusCode == 500) {
        // API returns envelope format even for 500 errors
        try {
          final result = jsonDecode(response.body);
          
          // Handle envelope response: { success: bool, data: docuNumb, error: string }
          if (result is Map<String, dynamic>) {
            if (result['success'] == true) {
              return {
                'success': true,
                'docuNumb': result['data']?.toString(),
                'message': 'Saved successfully',
              };
            } else {
              return {
                'success': false,
                'message': result['error'] ?? 'Unknown error occurred',
              };
            }
          }
          
          return _fail('Unexpected response format: $result');
        } catch (e) {
          return _fail('Failed to parse response: $e - ${response.body}');
        }
      } else if (response.statusCode == 400) {
        try {
          final errorData = jsonDecode(response.body);
          return {
            'success': false,
            'message': errorData['error'] ?? errorData['message'] ?? 'Bad request',
          };
        } catch (e) {
          return {
            'success': false,
            'message': 'Bad request: ${response.body}',
          };
        }
      } else {
        return _fail('Failed to submit: ${response.statusCode} - ${response.body}');
      }
    } catch (e, stackTrace) {
      print('[SAMPLING_EXEC] Exception: $e');
      print('[SAMPLING_EXEC] Stack trace: $stackTrace');
      return _fail('Failed to submit sampling execution: $e');
    }
  }
}
