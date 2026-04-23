import '../models/dashboard_models.dart';
import '../network/api_client.dart';

/// Service layer for Dashboard API
class DashboardApi {
  static const String _basePath = '/api/Dashboard';
  static const Duration _timeout = Duration(seconds: 20);

  /// Validate API response structure
  static Map<String, dynamic> _validateResponse(String label, dynamic data) {
    if (data is! Map<String, dynamic>) {
      throw Exception('$label returned unexpected payload');
    }
    if (data['success'] != true) {
      throw Exception(data['message'] ?? '$label API error');
    }
    return data;
  }

  /// GET /api/Dashboard/stats?start=yyyy-MM-dd&end=yyyy-MM-dd
  static Future<DashboardStats> getStats({
    String? start,
    String? end,
  }) async {
    final queryParams = <String, dynamic>{
      if (start != null && start.isNotEmpty) 'start': start,
      if (end != null && end.isNotEmpty) 'end': end,
    };

    final api = await ApiClient.getInstance();
    final data = await api.get(
      '$_basePath/stats',
      queryParameters: queryParams.isNotEmpty ? queryParams : null,
      timeout: _timeout,
    );

    final map = _validateResponse('Stats', data);
    return DashboardStats.fromJson(map);
  }

  /// GET /api/Dashboard/trends?start=yyyy-MM-dd&end=yyyy-MM-dd
  static Future<TrendsResponse> getTrends({String? start, String? end}) async {
    final queryParams = <String, dynamic>{
      if (start != null && start.isNotEmpty) 'start': start,
      if (end != null && end.isNotEmpty) 'end': end,
    };

    final api = await ApiClient.getInstance();
    final data = await api.get(
      '$_basePath/trends',
      queryParameters: queryParams.isNotEmpty ? queryParams : null,
      timeout: _timeout,
    );

    final map = _validateResponse('Trends', data);
    return TrendsResponse.fromJson(map);
  }

  /// GET /api/Dashboard/recent?limit=5
  static Future<RecentResponse> getRecent({int limit = 5}) async {
    final api = await ApiClient.getInstance();
    final data = await api.get(
      '$_basePath/recent',
      queryParameters: {'limit': '$limit'},
      timeout: _timeout,
    );

    final map = _validateResponse('Recent', data);
    return RecentResponse.fromJson(map);
  }
}
