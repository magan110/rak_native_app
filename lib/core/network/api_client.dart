import 'dart:convert';
import 'package:http/http.dart' as http;
import '../config/api_config.dart';
import '../errors/exceptions.dart';
import '../utils/logger.dart';
import 'ssl_http_client.dart';

/// Centralized HTTP API Client
///
/// All services should use this client for API calls instead of
/// directly accessing SslHttpClient. It provides:
/// - SSL support via SslHttpClient
/// - Centralized base URL from ApiConfig
/// - Default headers from ApiConfig.standardHeaders
/// - Consistent timeout handling
/// - Response parsing and error mapping
class ApiClient {
  final http.Client client;
  final String baseUrl;
  static final AppLogger _logger = AppLogger();

  ApiClient._({required this.client, required this.baseUrl});

  /// Singleton instance
  static ApiClient? _instance;

  /// Get or create the singleton API client with SSL
  static Future<ApiClient> getInstance() async {
    if (_instance != null) return _instance!;
    final sslClient = await SslHttpClient.getClient();
    _instance = ApiClient._(client: sslClient, baseUrl: ApiConfig.baseUrl);
    return _instance!;
  }

  /// Create an ApiClient with a custom client (for testing or special cases)
  static ApiClient withClient({
    required http.Client client,
    String? baseUrl,
  }) {
    return ApiClient._(client: client, baseUrl: baseUrl ?? ApiConfig.baseUrl);
  }

  /// Reset the singleton (useful after SSL refresh or for testing)
  static void reset() {
    _instance = null;
  }

  /// GET request
  Future<dynamic> get(
    String endpoint, {
    Map<String, String>? headers,
    Map<String, dynamic>? queryParameters,
    Duration? timeout,
  }) async {
    try {
      final uri = _buildUri(endpoint, queryParameters);
      _logger.debug('GET $endpoint');
      final response = await client
          .get(uri, headers: _mergeHeaders(headers))
          .timeout(timeout ?? ApiConfig.defaultTimeout);
      return _handleResponse(response);
    } on AppException {
      rethrow;
    } catch (e) {
      throw NetworkException('GET $endpoint failed: $e');
    }
  }

  /// POST request (JSON body)
  Future<dynamic> post(
    String endpoint, {
    Map<String, String>? headers,
    dynamic body,
    Duration? timeout,
  }) async {
    try {
      final uri = _buildUri(endpoint);
      _logger.debug('POST $endpoint');
      final encodedBody = body != null ? jsonEncode(body) : null;
      final response = await client
          .post(uri, headers: _mergeHeaders(headers), body: encodedBody)
          .timeout(timeout ?? ApiConfig.defaultTimeout);
      return _handleResponse(response);
    } on AppException {
      rethrow;
    } catch (e) {
      throw NetworkException('POST $endpoint failed: $e');
    }
  }

  /// PUT request
  Future<dynamic> put(
    String endpoint, {
    Map<String, String>? headers,
    dynamic body,
    Duration? timeout,
  }) async {
    try {
      final uri = _buildUri(endpoint);
      _logger.debug('PUT $endpoint');
      final encodedBody = body != null ? jsonEncode(body) : null;
      final response = await client
          .put(uri, headers: _mergeHeaders(headers), body: encodedBody)
          .timeout(timeout ?? ApiConfig.defaultTimeout);
      return _handleResponse(response);
    } on AppException {
      rethrow;
    } catch (e) {
      throw NetworkException('PUT $endpoint failed: $e');
    }
  }

  /// DELETE request
  Future<dynamic> delete(
    String endpoint, {
    Map<String, String>? headers,
    Duration? timeout,
  }) async {
    try {
      final uri = _buildUri(endpoint);
      _logger.debug('DELETE $endpoint');
      final response = await client
          .delete(uri, headers: _mergeHeaders(headers))
          .timeout(timeout ?? ApiConfig.defaultTimeout);
      return _handleResponse(response);
    } on AppException {
      rethrow;
    } catch (e) {
      throw NetworkException('DELETE $endpoint failed: $e');
    }
  }

  /// HEAD request (for connectivity testing)
  Future<int> head(String endpoint, {Duration? timeout}) async {
    try {
      final uri = _buildUri(endpoint);
      final response = await client
          .head(uri, headers: {'Accept': 'application/json'})
          .timeout(timeout ?? const Duration(seconds: 10));
      return response.statusCode;
    } catch (e) {
      throw NetworkException('HEAD $endpoint failed: $e');
    }
  }

  /// Build full URI from endpoint, supporting both relative and absolute URLs
  Uri _buildUri(String endpoint, [Map<String, dynamic>? queryParameters]) {
    final url = endpoint.startsWith('http') ? endpoint : '$baseUrl$endpoint';
    final uri = Uri.parse(url);
    if (queryParameters != null && queryParameters.isNotEmpty) {
      return uri.replace(
        queryParameters: queryParameters.map(
          (key, value) => MapEntry(key, value?.toString() ?? ''),
        ),
      );
    }
    return uri;
  }

  /// Merge default headers with custom headers (custom takes precedence)
  Map<String, String> _mergeHeaders(Map<String, String>? custom) {
    return {
      ...ApiConfig.standardHeaders,
      ...?custom,
    };
  }

  /// Handle response: parse JSON on success, throw typed exceptions on failure
  dynamic _handleResponse(http.Response response) {
    _logger.debug('Response ${response.statusCode}');

    if (response.statusCode >= 200 && response.statusCode < 300) {
      if (response.body.isEmpty) return null;
      try {
        return jsonDecode(response.body);
      } catch (_) {
        // Return raw body if not JSON
        return response.body;
      }
    } else if (response.statusCode == 401) {
      throw AuthenticationException('Unauthorized');
    } else if (response.statusCode >= 500) {
      throw ServerException('Server error: ${response.statusCode}');
    } else {
      throw ServerException('Request failed: ${response.statusCode}');
    }
  }
}
