import 'dart:convert';
import 'package:http/http.dart' as http;
import '../errors/exceptions.dart';

/// HTTP API Client
/// Handle all HTTP requests
class ApiClient {
  final http.Client client;
  final String baseUrl;
  
  ApiClient({
    required this.client,
    required this.baseUrl,
  });
  
  /// GET request
  Future<dynamic> get(
    String endpoint, {
    Map<String, String>? headers,
    Map<String, dynamic>? queryParameters,
  }) async {
    try {
      final uri = _buildUri(endpoint, queryParameters);
      final response = await client.get(
        uri,
        headers: _buildHeaders(headers),
      );
      return _handleResponse(response);
    } catch (e) {
      throw NetworkException('GET request failed: $e');
    }
  }
  
  /// POST request
  Future<dynamic> post(
    String endpoint, {
    Map<String, String>? headers,
    dynamic body,
  }) async {
    try {
      final uri = _buildUri(endpoint);
      final response = await client.post(
        uri,
        headers: _buildHeaders(headers),
        body: jsonEncode(body),
      );
      return _handleResponse(response);
    } catch (e) {
      throw NetworkException('POST request failed: $e');
    }
  }
  
  /// PUT request
  Future<dynamic> put(
    String endpoint, {
    Map<String, String>? headers,
    dynamic body,
  }) async {
    try {
      final uri = _buildUri(endpoint);
      final response = await client.put(
        uri,
        headers: _buildHeaders(headers),
        body: jsonEncode(body),
      );
      return _handleResponse(response);
    } catch (e) {
      throw NetworkException('PUT request failed: $e');
    }
  }
  
  /// DELETE request
  Future<dynamic> delete(
    String endpoint, {
    Map<String, String>? headers,
  }) async {
    try {
      final uri = _buildUri(endpoint);
      final response = await client.delete(
        uri,
        headers: _buildHeaders(headers),
      );
      return _handleResponse(response);
    } catch (e) {
      throw NetworkException('DELETE request failed: $e');
    }
  }
  
  Uri _buildUri(String endpoint, [Map<String, dynamic>? queryParameters]) {
    return Uri.parse('$baseUrl$endpoint').replace(
      queryParameters: queryParameters,
    );
  }
  
  Map<String, String> _buildHeaders(Map<String, String>? headers) {
    return {
      'Content-Type': 'application/json',
      'Accept': 'application/json',
      ...?headers,
    };
  }
  
  dynamic _handleResponse(http.Response response) {
    if (response.statusCode >= 200 && response.statusCode < 300) {
      return jsonDecode(response.body);
    } else if (response.statusCode == 401) {
      throw AuthenticationException('Unauthorized');
    } else if (response.statusCode >= 500) {
      throw ServerException('Server error: ${response.statusCode}');
    } else {
      throw ServerException('Request failed: ${response.statusCode}');
    }
  }
}
