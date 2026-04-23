import 'dart:convert';
import 'package:http/http.dart' as http;
import '../config/api_config.dart';
import '../models/profile_details_models.dart';
import '../network/ssl_http_client.dart';

/// Unified service for fetching and updating profile details
/// Uses the new /api/ProfileDetails endpoints
class ProfileDetailsService {
  static http.Client? _httpClient;

  /// Get SSL-enabled HTTP client
  static Future<http.Client> _getClient() async {
    _httpClient ??= await SslHttpClient.getClient();
    return _httpClient!;
  }
  /// Fetch profile details by mobile number
  /// GET: /api/ProfileDetails/by-mobile?mobile={mobile}
  static Future<ProfileDetailsResponse> getProfileByMobile(String mobile) async {
    try {
      final url = Uri.parse('${ApiConfig.baseUrl}/api/ProfileDetails/by-mobile')
          .replace(queryParameters: {'mobile': mobile});

      print('📡 Fetching profile details from: $url');

      final client = await _getClient();
      final response = await client.get(
        url,
        headers: {'Content-Type': 'application/json'},
      );

      print('📥 Response status: ${response.statusCode}');
      print('📥 Response body: ${response.body}');

      if (response.statusCode == 200) {
        final json = jsonDecode(response.body) as Map<String, dynamic>;
        return ProfileDetailsResponse.fromJson(json);
      } else if (response.statusCode == 404) {
        return ProfileDetailsResponse(
          success: false,
          message: 'No profile found for this mobile number',
        );
      } else {
        return ProfileDetailsResponse(
          success: false,
          message: 'Failed to fetch profile: ${response.statusCode}',
        );
      }
    } catch (e) {
      print('❌ Error fetching profile: $e');
      return ProfileDetailsResponse(
        success: false,
        message: 'Network error: ${e.toString()}',
      );
    }
  }

  /// Update profile details by mobile number
  /// POST: /api/ProfileDetails/update-by-mobile/{mobile}
  static Future<ProfileDetailsResponse> updateProfileByMobile(
    String mobile,
    ProfileUpdateRequest request,
  ) async {
    try {
      final url = Uri.parse(
        '${ApiConfig.baseUrl}/api/ProfileDetails/update-by-mobile/$mobile',
      );

      print('📡 Updating profile at: $url');
      print('📤 Request body: ${jsonEncode(request.toJson())}');

      final client = await _getClient();
      final response = await client.post(
        url,
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode(request.toJson()),
      );

      print('📥 Response status: ${response.statusCode}');
      print('📥 Response body: ${response.body}');

      if (response.statusCode == 200) {
        final json = jsonDecode(response.body) as Map<String, dynamic>;
        return ProfileDetailsResponse.fromJson(json);
      } else if (response.statusCode == 404) {
        return ProfileDetailsResponse(
          success: false,
          message: 'No profile found for this mobile number',
        );
      } else {
        return ProfileDetailsResponse(
          success: false,
          message: 'Failed to update profile: ${response.statusCode}',
        );
      }
    } catch (e) {
      print('❌ Error updating profile: $e');
      return ProfileDetailsResponse(
        success: false,
        message: 'Network error: ${e.toString()}',
      );
    }
  }

  /// Format mobile number to match API expectations
  /// Keeps only digits and takes last 11 digits if longer
  static String formatMobile(String mobile) {
    final digits = mobile.replaceAll(RegExp(r'\D'), '');
    if (digits.length <= 11) return digits;
    return digits.substring(digits.length - 11);
  }

  /// Format IBAN number (remove spaces, uppercase)
  static String formatIban(String iban) {
    return iban.replaceAll(' ', '').toUpperCase();
  }
}
