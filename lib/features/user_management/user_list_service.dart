import 'dart:convert';
import 'package:http/http.dart' as http;
import '../../core/network/ssl_http_client.dart';
import 'user_list_models.dart';

class UserListService {
  static const String baseUrl = 'https://qa.birlawhite.com:55232';
  static http.Client? _httpClient;

  /// Get SSL-enabled HTTP client
  static Future<http.Client> _getClient() async {
    _httpClient ??= await SslHttpClient.getClient();
    return _httpClient!;
  }

  /// Get all users (contractors and painters)
  /// Endpoint: GET /api/Users/all
  Future<UserListResponse> getAllUsers({String? search, String? type}) async {
    try {
      final queryParams = <String, String>{};

      if (search != null && search.isNotEmpty) {
        queryParams['search'] = search;
      }
      if (type != null && type.isNotEmpty && type != 'All') {
        queryParams['type'] = type;
      }

      final uri = Uri.parse('$baseUrl/api/Users/all').replace(queryParameters: queryParams);

      print('DEBUG: Fetching users from: $uri');

      final client = await _getClient();
      final response = await client
          .get(uri, headers: {'Content-Type': 'application/json', 'Accept': 'application/json'})
          .timeout(const Duration(seconds: 30));

      print('DEBUG: Response status: ${response.statusCode}');
      print('DEBUG: Response body: ${response.body}');

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        return UserListResponse.fromJson(data);
      } else {
        throw Exception('Failed to load users: ${response.statusCode} - ${response.body}');
      }
    } catch (e) {
      print('DEBUG: Error fetching users: $e');
      throw Exception('Error fetching users: $e');
    }
  }

  /// Get user details by ID
  /// Endpoint: GET /api/Users/{userId}
  Future<UserDetailDto> getUserById(String userId) async {
    try {
      final uri = Uri.parse('$baseUrl/api/Users/$userId');

      print('DEBUG: Fetching user details from: $uri');

      final client = await _getClient();
      final response = await client
          .get(uri, headers: {'Content-Type': 'application/json', 'Accept': 'application/json'})
          .timeout(const Duration(seconds: 30));

      print('DEBUG: Response status: ${response.statusCode}');
      print('DEBUG: Response body: ${response.body}');

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['success'] == true && data['data'] != null) {
          return UserDetailDto.fromJson(data['data']);
        } else {
          throw Exception('Invalid response format');
        }
      } else if (response.statusCode == 404) {
        throw Exception('User not found');
      } else {
        throw Exception('Failed to load user: ${response.statusCode} - ${response.body}');
      }
    } catch (e) {
      print('DEBUG: Error fetching user details: $e');
      throw Exception('Error fetching user details: $e');
    }
  }

  /// Update user details
  /// Endpoint: POST /api/Users/update/{userId}
  /// Note: Backend changed from PUT to POST to bypass WAF blocking
  Future<bool> updateUser(String userId, UserUpdateRequest request) async {
    try {
      final uri = Uri.parse('$baseUrl/api/Users/update/$userId');

      // Clean the request to only include non-null values
      final cleanedJson = request.toJson();

      print('DEBUG: Updating user at: $uri');
      print('DEBUG: Request body fields: ${cleanedJson.keys.join(', ')}');
      print('DEBUG: Request body size: ${json.encode(cleanedJson).length} bytes');

      // Try POST first (some WAFs block PUT), fallback to PUT if needed
      final client = await _getClient();
      final response = await client
          .post(
            uri,
            headers: {
              'Content-Type': 'application/json',
              'Accept': 'application/json',
              'User-Agent': 'RAKApp-Mobile/1.0',
              'X-Requested-With': 'XMLHttpRequest',
            },
            body: json.encode(cleanedJson),
          )
          .timeout(const Duration(seconds: 30));

      print('DEBUG: Response status: ${response.statusCode}');

      if (response.statusCode == 200) {
        // Check if response is JSON
        if (response.body.trim().startsWith('{')) {
          print('DEBUG: Response body: ${response.body}');
          final data = json.decode(response.body);
          return data['success'] ?? false;
        } else {
          print('DEBUG: Non-JSON response received');
          throw Exception('Server returned non-JSON response');
        }
      } else if (response.statusCode == 400) {
        print('DEBUG: Validation error: ${response.body}');
        if (response.body.trim().startsWith('{')) {
          final data = json.decode(response.body);
          final errors = data['errors'] as List<dynamic>?;
          throw Exception('Validation failed: ${errors?.join(', ') ?? data['message']}');
        } else {
          throw Exception('Validation failed: ${response.body}');
        }
      } else if (response.statusCode == 404) {
        throw Exception('User not found');
      } else if (response.statusCode == 406) {
        print('DEBUG: WAF blocked request (406)');
        print(
          'DEBUG: Response: ${response.body.substring(0, response.body.length > 500 ? 500 : response.body.length)}',
        );
        throw Exception(
          'Request blocked by security firewall. This may be due to network security policies. Please try again or contact your administrator.',
        );
      } else {
        // For HTML responses, extract just the status code
        if (response.body.contains('<!DOCTYPE html>')) {
          print('DEBUG: HTML error page received');
          throw Exception('Server error ${response.statusCode}: Request was blocked by security system');
        }
        print('DEBUG: Unexpected error: ${response.body}');
        throw Exception('Failed to update user: ${response.statusCode}');
      }
    } catch (e) {
      print('DEBUG: Error updating user: $e');
      if (e.toString().contains('Exception:')) {
        rethrow;
      }
      throw Exception('Error updating user: $e');
    }
  }
}
