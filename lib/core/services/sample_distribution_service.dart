import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/sample_distribution_models.dart';
import '../constants/app_constants.dart';
import '../network/ssl_http_client.dart';
import 'auth_service.dart';

class SampleDistributionService {
  static String get _baseUrl => AppConstants.baseUrl;
  static const String apiPath = '/api/sampledistribution';
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

  static Future<List<AreaItem>> getAreas({bool onlyActive = true}) async {
    try {
      final uri = Uri.parse('$_baseUrl$apiPath/areas').replace(
        queryParameters: {'onlyActive': onlyActive.toString()},
      );

      final client = await _getClient();
      final response = await client.get(uri, headers: _jsonHeaders);

      if (response.statusCode == 200) {
        final List<dynamic> data = json.decode(response.body);
        return data.map((item) => AreaItem.fromJson(item)).toList();
      } else {
        throw Exception('Failed to load areas: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Error fetching areas: $e');
    }
  }

  static Future<SubmitResponse> submitSampleDistribution(
    SampleDistributionRequest request,
  ) async {
    try {
      final uri = Uri.parse('$_baseUrl$apiPath/submit');
      final headers = <String, String>{..._jsonHeaders};

      // Get loginId from current authenticated user
      final currentUser = AuthManager.currentUser;
      if (currentUser != null && currentUser.userID != null) {
        // Use userID from the login (max 6 characters as per API requirement)
        final loginId = currentUser.userID!.length > 6
            ? currentUser.userID!.substring(0, 6)
            : currentUser.userID!;
        headers['LoginID'] = loginId;
      }

      final client = await _getClient();
      final response = await client.post(
        uri,
        headers: headers,
        body: json.encode(request.toJson()),
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        return SubmitResponse.fromJson(data);
      } else {
        final errorData = json.decode(response.body);
        return SubmitResponse(
          success: false,
          message: errorData['message'] ?? 'Unknown error occurred',
        );
      }
    } catch (e) {
      return SubmitResponse(
        success: false,
        message: 'Error submitting sample distribution: $e',
      );
    }
  }
}
