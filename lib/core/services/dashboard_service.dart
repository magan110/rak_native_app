import 'dart:convert';

import 'package:http/http.dart' as http;

import '../models/dashboard_models.dart';

/// Service layer for Dashboard API (HTTPS + explicit port)

class DashboardApi {
  // Host WITHOUT port

  static const String _host = 'qa.birlawhite.com';

  // Explicit HTTPS port

  static const int _port = 55232;

  static const String _basePath = '/api/Dashboard';

  static const Duration _timeout = Duration(seconds: 20);

  /// Optional: set default headers here (JWT, etc.)

  static Map<String, String> get _headers => <String, String>{
    'Accept': 'application/json',

    'Content-Type': 'application/json',
  };

  static Uri _buildUri(String subPath, [Map<String, String>? query]) {
    return Uri(
      scheme: 'https',

      host: _host,

      port: _port,

      path: '$_basePath/$subPath',

      queryParameters: query?.isEmpty ?? true ? null : query,
    );
  }

  static Never _throwHttp(String label, http.Response res) {
    throw Exception(
      '$label failed: HTTP ${res.statusCode} ${res.reasonPhrase ?? ""}',
    );
  }

  static Map<String, dynamic> _decodeBody(String label, String body) {
    final decoded = jsonDecode(body);

    if (decoded is! Map<String, dynamic>) {
      throw Exception('$label returned unexpected payload');
    }

    if (decoded['success'] != true) {
      throw Exception(decoded['message'] ?? '$label API error');
    }

    return decoded;
  }

  /// GET /api/Dashboard/stats?start=yyyy-MM-dd&end=yyyy-MM-dd

  static Future<DashboardStats> getStats({
    String? start, // yyyy-MM-dd

    String? end, // yyyy-MM-dd
  }) async {
    final params = <String, String>{
      if (start != null && start.isNotEmpty) 'start': start,

      if (end != null && end.isNotEmpty) 'end': end,
    };

    final uri = _buildUri('stats', params);

    final res = await http.get(uri, headers: _headers).timeout(_timeout);

    if (res.statusCode != 200) _throwHttp('Stats request', res);

    final map = _decodeBody('Stats', res.body);

    return DashboardStats.fromJson(map);

    // If your model expects just the 'data' object:

    // return DashboardStats.fromJson(map['data'] as Map<String, dynamic>);
  }

  /// GET /api/Dashboard/trends?start=yyyy-MM-dd&end=yyyy-MM-dd

  static Future<TrendsResponse> getTrends({String? start, String? end}) async {
    final params = <String, String>{
      if (start != null && start.isNotEmpty) 'start': start,

      if (end != null && end.isNotEmpty) 'end': end,
    };

    final uri = _buildUri('trends', params);

    final res = await http.get(uri, headers: _headers).timeout(_timeout);

    if (res.statusCode != 200) _throwHttp('Trends request', res);

    final map = _decodeBody('Trends', res.body);

    return TrendsResponse.fromJson(map);

    // Or: return TrendsResponse.fromJson(map['data']);
  }

  /// GET /api/Dashboard/recent?limit=5

  static Future<RecentResponse> getRecent({int limit = 5}) async {
    final uri = _buildUri('recent', {'limit': '$limit'});

    final res = await http.get(uri, headers: _headers).timeout(_timeout);

    if (res.statusCode != 200) _throwHttp('Recent request', res);

    final map = _decodeBody('Recent', res.body);

    return RecentResponse.fromJson(map);

    // Or: return RecentResponse.fromJson(map['data']);
  }
}
