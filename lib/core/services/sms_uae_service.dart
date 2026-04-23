import 'dart:convert';
import 'package:http/http.dart' as http;
import '../config/api_config.dart';
import '../models/user_profile_models.dart';
import '../network/api_client.dart';
import '../utils/logger.dart';

/// Service class for SMS UAE API integration
class SmsUaeService {
  static http.Client? _httpClient;
  static final AppLogger _logger = AppLogger();

  /// Get SSL-enabled HTTP client
  static Future<http.Client> _getClient() async {
    if (_httpClient == null) {
      final apiClient = await ApiClient.getInstance();
      _httpClient = apiClient.client;
    }
    return _httpClient!;
  }

  /// Test connectivity to different endpoints to find working ones
  static Future<Map<String, bool>> testEndpointConnectivity() async {
    final endpoints = {
      'health': ApiConfig.healthCheckUrl,
      'verify': ApiConfig.verifyMobileUrl,
      'route': ApiConfig.routeByMobileUrl,
      'send': ApiConfig.sendSmsUrl,
      'sendIfRegistered': ApiConfig.sendIfRegisteredUrl,
    };

    final results = <String, bool>{};

    for (final entry in endpoints.entries) {
      try {
        _logger.debug('Testing ${entry.key}: ${entry.value}');

        final client = await _getClient();
        final response = await client
            .get(
              Uri.parse(entry.value),
              headers: {'Accept': 'application/json'},
            )
            .timeout(const Duration(seconds: 10));

        final isWorking =
            response.statusCode != 406 &&
            response.statusCode != 403 &&
            !response.body.contains('<!DOCTYPE html>');

        results[entry.key] = isWorking;
        _logger.debug(
          '${entry.key}: ${response.statusCode} - ${isWorking ? 'OK' : 'FAIL'}',
        );
      } catch (e) {
        results[entry.key] = false;
        _logger.error('${entry.key}: $e');
      }
    }

    return results;
  }

  /// Check if the SMS UAE service is healthy
  static Future<bool> checkHealth() async {
    try {
      _logger.debug('Health check URL: ${ApiConfig.healthCheckUrl}');
      final client = await _getClient();
      final response = await client
          .get(Uri.parse(ApiConfig.healthCheckUrl))
          .timeout(ApiConfig.defaultTimeout);

      _logger.debug('Health check status: ${response.statusCode}');

      return response.statusCode == 200;
    } catch (e) {
      _logger.error('Health check error: $e');
      return false;
    }
  }

  /// Verify if mobile number is registered
  static Future<SmsUaeVerifyResponse> verifyMobile(String mobileNo) async {
    try {
      final client = await _getClient();
      final response = await client
          .post(
            Uri.parse(ApiConfig.verifyMobileUrl),
            headers: ApiConfig.standardHeaders,
            body: jsonEncode({'mobileNo': mobileNo}),
          )
          .timeout(ApiConfig.defaultTimeout);

      final data = jsonDecode(response.body) as Map<String, dynamic>;

      return SmsUaeVerifyResponse(
        success: data['success'] ?? false,
        exists: data['exists'] ?? false,
        inflType: data['inflType']?.toString(),
        message: data['message']?.toString(),
        statusCode: response.statusCode,
      );
    } catch (e) {
      return SmsUaeVerifyResponse(
        success: false,
        exists: false,
        message: 'Network error: ${e.toString()}',
        statusCode: 0,
      );
    }
  }

  /// Get route information for mobile number (painter/contractor)
  static Future<SmsUaeRouteResponse> getRouteByMobile(String mobileNo) async {
    try {
      final client = await _getClient();
      final response = await client
          .post(
            Uri.parse(ApiConfig.routeByMobileUrl),
            headers: ApiConfig.standardHeaders,
            body: jsonEncode({'mobileNo': mobileNo}),
          )
          .timeout(ApiConfig.defaultTimeout);

      final data = jsonDecode(response.body) as Map<String, dynamic>;

      return SmsUaeRouteResponse(
        success: data['success'] ?? false,
        exists: data['exists'] ?? false,
        inflType: data['inflType']?.toString(),
        route: data['route']?.toString(),
        message: data['message']?.toString(),
        statusCode: response.statusCode,
      );
    } catch (e) {
      return SmsUaeRouteResponse(
        success: false,
        exists: false,
        message: 'Network error: ${e.toString()}',
        statusCode: 0,
      );
    }
  }

  /// Get full user profile with all details for mobile number
  static Future<SmsUaeFullProfileResponse> getFullProfileByMobile(
    String mobileNo,
  ) async {
    try {
      _logger.debug('Fetching full profile for mobile');
      final client = await _getClient();
      final response = await client
          .post(
            Uri.parse(ApiConfig.routeByMobileUrl),
            headers: ApiConfig.standardHeaders,
            body: jsonEncode({'mobileNo': mobileNo}),
          )
          .timeout(ApiConfig.defaultTimeout);

      _logger.debug('Full profile response status: ${response.statusCode}');

      final data = jsonDecode(response.body) as Map<String, dynamic>;

      return SmsUaeFullProfileResponse(
        success: data['success'] ?? false,
        exists: data['exists'] ?? false,
        inflType: data['inflType']?.toString(),
        route: data['route']?.toString(),
        data: data['data'] != null
            ? UserProfileData.fromJson(data['data'] as Map<String, dynamic>)
            : null,
        message: data['message']?.toString(),
        statusCode: response.statusCode,
      );
    } catch (e) {
      _logger.error('Error fetching full profile: $e');
      return SmsUaeFullProfileResponse(
        success: false,
        exists: false,
        message: 'Network error: ${e.toString()}',
        statusCode: 0,
      );
    }
  }

  /// Send SMS directly using the SMS UAE controller with enhanced error handling
  static Future<SmsUaeSendResponse> sendSms({
    required String mobileNo,
    required String message,
    String priority = 'High',
    String countryCode = 'ALL',
  }) async {
    try {
      _logger.debug('Direct SMS API call to: ${ApiConfig.sendSmsUrl}');

      final client = await _getClient();
      final response = await client
          .post(
            Uri.parse(ApiConfig.sendSmsUrl),
            headers: ApiConfig.standardHeaders,
            body: jsonEncode({
              'mobileNo': mobileNo,
              'message': message,
              'priority': priority,
              'countryCode': countryCode,
            }),
          )
          .timeout(ApiConfig.smsTimeout);

      _logger.debug('Direct SMS response status: ${response.statusCode}');

      // Check if response is HTML (WAF error page)
      if (response.body.trim().startsWith('<!DOCTYPE html>') ||
          response.body.trim().startsWith('<html>')) {
        _logger.warning('Direct SMS received HTML error page');
        return SmsUaeSendResponse(
          success: false,
          statusCode: response.statusCode,
          message:
              'Request blocked by security system (${response.statusCode})',
        );
      }

      final data = jsonDecode(response.body) as Map<String, dynamic>;
      _logger.debug('Parsed response data keys: ${data.keys.toList()}');

      // Check if the response contains "Invalid Mobile No." error
      final responseText = data['response']?.toString() ?? '';
      final isInvalidMobile = responseText.contains('Invalid Mobile No.');

      if (isInvalidMobile) {
        _logger.warning('Invalid mobile number detected in response');
        return SmsUaeSendResponse(
          success: false,
          statusCode: data['statusCode'] ?? response.statusCode,
          forwardedTo: data['forwardedTo']?.toString(),
          response: responseText,
          message:
              'Invalid mobile number format. Please use format: 971XXXXXXXXX',
        );
      }

      return SmsUaeSendResponse(
        success: data['success'] ?? false,
        statusCode: data['statusCode'] ?? response.statusCode,
        forwardedTo: data['forwardedTo']?.toString(),
        response: responseText,
        message: data['message']?.toString(),
      );
    } catch (e) {
      _logger.error('Direct SMS error: $e');
      return SmsUaeSendResponse(
        success: false,
        statusCode: 0,
        message: 'Network error: ${e.toString()}',
      );
    }
  }

  /// Send SMS only if mobile is registered with enhanced error handling
  static Future<SmsUaeSendIfRegisteredResponse> sendSmsIfRegistered({
    required String mobileNo,
    required String message,
    String priority = 'High',
    String countryCode = 'ALL',
  }) async {
    // Try multiple approaches to bypass WAF
    final approaches = [
      _sendWithStandardHeaders,
      _sendWithMinimalHeaders,
      _sendWithDelayedRetry,
    ];

    SmsUaeSendIfRegisteredResponse? lastResponse;

    for (int i = 0; i < approaches.length; i++) {
      try {
        _logger.debug('Attempt ${i + 1}: Trying approach ${i + 1}');

        final response = await approaches[i](
          mobileNo: mobileNo,
          message: message,
          priority: priority,
          countryCode: countryCode,
        );

        // If successful or if it's a valid JSON response (not HTML error page)
        if (response.statusCode != 406 && response.statusCode != 403) {
          return response;
        }

        lastResponse = response;

        // Add delay between attempts
        if (i < approaches.length - 1) {
          await Future.delayed(Duration(milliseconds: 500 * (i + 1)));
        }
      } catch (e) {
        _logger.error('Approach ${i + 1} failed: $e');
        if (i == approaches.length - 1) {
          return SmsUaeSendIfRegisteredResponse(
            success: false,
            exists: false,
            message: 'All retry attempts failed: ${e.toString()}',
            statusCode: 0,
          );
        }
      }
    }

    // Return the last response if all approaches failed
    return lastResponse ??
        SmsUaeSendIfRegisteredResponse(
          success: false,
          exists: false,
          message: 'All retry attempts failed with WAF blocking',
          statusCode: 406,
        );
  }

  /// Standard approach with full headers
  static Future<SmsUaeSendIfRegisteredResponse> _sendWithStandardHeaders({
    required String mobileNo,
    required String message,
    String priority = 'High',
    String countryCode = 'ALL',
  }) async {
    _logger.debug('Making API call to: ${ApiConfig.sendIfRegisteredUrl}');

    final client = await _getClient();
    final response = await client
        .post(
          Uri.parse(ApiConfig.sendIfRegisteredUrl),
          headers: ApiConfig.standardHeaders,
          body: jsonEncode({
            'mobileNo': mobileNo,
            'message': message,
            'priority': priority,
            'countryCode': countryCode,
          }),
        )
        .timeout(ApiConfig.smsTimeout);

    _logger.debug('Standard headers response status: ${response.statusCode}');

    return _parseResponse(response);
  }

  /// Minimal headers approach
  static Future<SmsUaeSendIfRegisteredResponse> _sendWithMinimalHeaders({
    required String mobileNo,
    required String message,
    String priority = 'High',
    String countryCode = 'ALL',
  }) async {
    _logger.debug('Trying minimal headers approach...');

    final minimalHeaders = {
      'Content-Type': 'application/json',
      'Accept': 'application/json',
    };

    final client = await _getClient();
    final response = await client
        .post(
          Uri.parse(ApiConfig.sendIfRegisteredUrl),
          headers: minimalHeaders,
          body: jsonEncode({
            'mobileNo': mobileNo,
            'message': message,
            'priority': priority,
            'countryCode': countryCode,
          }),
        )
        .timeout(ApiConfig.smsTimeout);

    _logger.debug('Minimal headers response status: ${response.statusCode}');
    return _parseResponse(response);
  }

  /// Delayed retry approach
  static Future<SmsUaeSendIfRegisteredResponse> _sendWithDelayedRetry({
    required String mobileNo,
    required String message,
    String priority = 'High',
    String countryCode = 'ALL',
  }) async {
    _logger.debug('Trying delayed retry approach...');

    // Wait a bit to avoid rate limiting
    await Future.delayed(const Duration(milliseconds: 1000));

    final customHeaders = Map<String, String>.from(ApiConfig.standardHeaders);
    customHeaders['X-Retry-Attempt'] = 'true';
    customHeaders['X-Client-Version'] = '1.0.0';

    final client = await _getClient();
    final response = await client
        .post(
          Uri.parse(ApiConfig.sendIfRegisteredUrl),
          headers: customHeaders,
          body: jsonEncode({
            'mobileNo': mobileNo,
            'message': message,
            'priority': priority,
            'countryCode': countryCode,
          }),
        )
        .timeout(ApiConfig.smsTimeout);

    _logger.debug('Delayed retry response status: ${response.statusCode}');
    return _parseResponse(response);
  }

  /// Parse response and handle HTML error pages
  static SmsUaeSendIfRegisteredResponse _parseResponse(http.Response response) {
    try {
      // Check if response is HTML (WAF error page)
      if (response.body.trim().startsWith('<!DOCTYPE html>') ||
          response.body.trim().startsWith('<html>')) {
        _logger.warning('Received HTML error page instead of JSON');
        return SmsUaeSendIfRegisteredResponse(
          success: false,
          exists: false,
          message:
              'Request blocked by security system (${response.statusCode})',
          statusCode: response.statusCode,
        );
      }

      final data = jsonDecode(response.body) as Map<String, dynamic>;

      return SmsUaeSendIfRegisteredResponse(
        success: data['success'] ?? false,
        exists: data['exists'] ?? false,
        inflType: data['inflType']?.toString(),
        route: data['route']?.toString(),
        kyotoStatus: data['kyotoStatus'],
        kyotoResponse: data['kyotoResponse']?.toString(),
        message: data['message']?.toString(),
        statusCode: response.statusCode,
      );
    } catch (e) {
      _logger.error('Failed to parse response: $e');
      return SmsUaeSendIfRegisteredResponse(
        success: false,
        exists: false,
        message: 'Failed to parse server response: ${e.toString()}',
        statusCode: response.statusCode,
      );
    }
  }
}

/// Response models for SMS UAE API
class SmsUaeVerifyResponse {
  final bool success;
  final bool exists;
  final String? inflType;
  final String? message;
  final int statusCode;

  SmsUaeVerifyResponse({
    required this.success,
    required this.exists,
    this.inflType,
    this.message,
    required this.statusCode,
  });
}

class SmsUaeRouteResponse {
  final bool success;
  final bool exists;
  final String? inflType;
  final String? route;
  final String? message;
  final int statusCode;

  SmsUaeRouteResponse({
    required this.success,
    required this.exists,
    this.inflType,
    this.route,
    this.message,
    required this.statusCode,
  });
}

class SmsUaeSendResponse {
  final bool success;
  final int statusCode;
  final String? forwardedTo;
  final String? response;
  final String? message;

  SmsUaeSendResponse({
    required this.success,
    required this.statusCode,
    this.forwardedTo,
    this.response,
    this.message,
  });
}

class SmsUaeSendIfRegisteredResponse {
  final bool success;
  final bool exists;
  final String? inflType;
  final String? route;
  final int? kyotoStatus;
  final String? kyotoResponse;
  final String? message;
  final int statusCode;

  SmsUaeSendIfRegisteredResponse({
    required this.success,
    required this.exists,
    this.inflType,
    this.route,
    this.kyotoStatus,
    this.kyotoResponse,
    this.message,
    required this.statusCode,
  });
}
