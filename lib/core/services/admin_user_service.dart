import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:rak_app/core/config/api_config.dart';
import 'package:rak_app/core/models/admin_user_models.dart';

/// Admin User Service for managing user data by registration ID
class AdminUserService {
  static const String _baseUrl = 'https://qa.birlawhite.com:55232/api/UseUpdate';

  /// Fetch user details by registration ID (inflCode)
  static Future<AdminUserResponse> getUserByInflCode(String inflCode) async {
    try {
      if (inflCode.trim().isEmpty) {
        return AdminUserResponse(
          success: false,
          message: 'Registration ID is required',
        );
      }

      final url = Uri.parse('$_baseUrl/by-inflcode/${inflCode.trim()}');
      print('DEBUG: Fetching user from: $url'); // Debug log
      
      final response = await http.get(
        url,
        headers: ApiConfig.standardHeaders,
      ).timeout(ApiConfig.defaultTimeout);

      final Map<String, dynamic> responseData = json.decode(response.body);
      
      print('DEBUG: GET Response status: ${response.statusCode}'); // Debug log
      print('DEBUG: GET Response body: ${response.body}'); // Debug log

      if (response.statusCode == 200) {
        return AdminUserResponse.fromJson(responseData);
      } else if (response.statusCode == 404) {
        return AdminUserResponse(
          success: false,
          message: 'No user found with registration ID: $inflCode',
        );
      } else {
        return AdminUserResponse(
          success: false,
          message: responseData['message'] ?? 'Failed to fetch user details',
        );
      }
    } catch (e) {
      return AdminUserResponse(
        success: false,
        message: 'Network error: ${e.toString()}',
      );
    }
  }

  /// Update user details by registration ID (inflCode)
  static Future<AdminUserUpdateResponse> updateUserByInflCode(
    String inflCode,
    AdminUserData userData,
  ) async {
    try {
      if (inflCode.trim().isEmpty) {
        return AdminUserUpdateResponse(
          success: false,
          message: 'Registration ID is required',
        );
      }

      final url = Uri.parse('$_baseUrl/update-by-inflcode/${inflCode.trim()}');
      final updateData = userData.toUpdateJson();

      print('DEBUG: Update URL: $url'); // Debug log
      print('DEBUG: Update data: ${json.encode(updateData)}'); // Debug log
      print('DEBUG: Update data count: ${updateData.length}'); // Debug log

      if (updateData.isEmpty) {
        return AdminUserUpdateResponse(
          success: false,
          message: 'No fields to update',
        );
      }

      final response = await http.post(
        url,
        headers: ApiConfig.standardHeaders,
        body: json.encode(updateData),
      ).timeout(ApiConfig.defaultTimeout);

      print('DEBUG: Response status: ${response.statusCode}'); // Debug log
      print('DEBUG: Response body: ${response.body}'); // Debug log

      final Map<String, dynamic> responseData = json.decode(response.body);

      if (response.statusCode == 200) {
        return AdminUserUpdateResponse.fromJson(responseData);
      } else if (response.statusCode == 404) {
        return AdminUserUpdateResponse(
          success: false,
          message: 'No user found with registration ID: $inflCode',
        );
      } else {
        return AdminUserUpdateResponse(
          success: false,
          message: responseData['message'] ?? 'Failed to update user details. Status: ${response.statusCode}',
        );
      }
    } catch (e) {
      print('DEBUG: Update error: $e'); // Debug log
      return AdminUserUpdateResponse(
        success: false,
        message: 'Network error: ${e.toString()}',
      );
    }
  }

  /// Validate registration ID format
  static bool isValidInflCode(String inflCode) {
    if (inflCode.trim().isEmpty) return false;
    
    // Basic validation - adjust based on your requirements
    final trimmed = inflCode.trim();
    return trimmed.length >= 3 && trimmed.length <= 20;
  }

  /// Search users with typeahead suggestions
  static Future<UserSearchResponse> searchUsers({
    required String query,
    int limit = 10,
    bool includeInactive = false,
    String? area,
  }) async {
    try {
      if (query.trim().isEmpty) {
        return UserSearchResponse(
          success: true,
          data: [],
        );
      }

      final uri = Uri.parse('$_baseUrl/search').replace(queryParameters: {
        'q': query.trim(),
        'limit': limit.toString(),
        'includeInactive': includeInactive.toString(),
        if (area != null && area.trim().isNotEmpty) 'area': area.trim(),
      });

      print('DEBUG: Search URL: $uri'); // Debug log
      
      final response = await http.get(
        uri,
        headers: ApiConfig.standardHeaders,
      ).timeout(ApiConfig.defaultTimeout);

      print('DEBUG: Search Response status: ${response.statusCode}'); // Debug log
      print('DEBUG: Search Response body: ${response.body}'); // Debug log

      final Map<String, dynamic> responseData = json.decode(response.body);

      if (response.statusCode == 200) {
        return UserSearchResponse.fromJson(responseData);
      } else {
        return UserSearchResponse(
          success: false,
          message: responseData['message'] ?? 'Search failed',
          data: [],
        );
      }
    } catch (e) {
      print('DEBUG: Search error: $e'); // Debug log
      return UserSearchResponse(
        success: false,
        message: 'Network error: ${e.toString()}',
        data: [],
      );
    }
  }

  /// Get user type display name from inflType
  static String getUserTypeDisplay(String? inflType) {
    switch (inflType?.toUpperCase()) {
      case 'PN':
        return 'Painter';
      case '2IK':
        return 'Contractor';
      default:
        return inflType ?? 'Unknown';
    }
  }
}