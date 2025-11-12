import 'dart:convert';
import 'package:http/http.dart' as http;
import '../config/api_config.dart';
import '../models/user_profile_models.dart';

/// Service class for SMS UAE API integration
class SmsUaeService {
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
        print('🔍 Testing ${entry.key}: ${entry.value}');

        final response = await http
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
        print('${isWorking ? '✅' : '❌'} ${entry.key}: ${response.statusCode}');
      } catch (e) {
        results[entry.key] = false;
        print('❌ ${entry.key}: $e');
      }
    }

    return results;
  }

  /// Check if the SMS UAE service is healthy
  static Future<bool> checkHealth() async {
    try {
      print('🏥 Health check URL: ${ApiConfig.healthCheckUrl}');
      final response = await http
          .get(Uri.parse(ApiConfig.healthCheckUrl))
          .timeout(ApiConfig.defaultTimeout);

      print('🏥 Health check status: ${response.statusCode}');
      print('🏥 Health check body: ${response.body}');

      return response.statusCode == 200;
    } catch (e) {
      print('❌ Health check error: $e');
      return false;
    }
  }

  /// Verify if mobile number is registered
  static Future<SmsUaeVerifyResponse> verifyMobile(String mobileNo) async {
    try {
      final response = await http
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
      final response = await http
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
      print('🔍 Fetching full profile for mobile: $mobileNo');
      final response = await http
          .post(
            Uri.parse(ApiConfig.routeByMobileUrl),
            headers: ApiConfig.standardHeaders,
            body: jsonEncode({'mobileNo': mobileNo}),
          )
          .timeout(ApiConfig.defaultTimeout);

      print('📡 Full profile response status: ${response.statusCode}');
      print('📡 Full profile response body: ${response.body}');

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
      print('❌ Error fetching full profile: $e');
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
      print('🌐 Direct SMS API call to: ${ApiConfig.sendSmsUrl}');
      print(
        '📤 Request body: ${jsonEncode({'mobileNo': mobileNo, 'message': message, 'priority': priority, 'countryCode': countryCode})}',
      );

      final response = await http
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

      print('📡 Direct SMS response status: ${response.statusCode}');
      print('📡 Direct SMS response body: ${response.body}');

      // Check if response is HTML (WAF error page)
      if (response.body.trim().startsWith('<!DOCTYPE html>') ||
          response.body.trim().startsWith('<html>')) {
        print('❌ Direct SMS received HTML error page');
        return SmsUaeSendResponse(
          success: false,
          statusCode: response.statusCode,
          message:
              'Request blocked by security system (${response.statusCode})',
        );
      }

      final data = jsonDecode(response.body) as Map<String, dynamic>;
      print('📡 Parsed response data: $data');

      // Check if the response contains "Invalid Mobile No." error
      final responseText = data['response']?.toString() ?? '';
      final isInvalidMobile = responseText.contains('Invalid Mobile No.');

      if (isInvalidMobile) {
        print('❌ Invalid mobile number detected in response');
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
      print('❌ Direct SMS error: $e');
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
        print('🔄 Attempt ${i + 1}: Trying approach ${i + 1}');

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
        print('❌ Approach ${i + 1} failed: $e');
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
    print('🌐 Making API call to: ${ApiConfig.sendIfRegisteredUrl}');
    print(
      '📱 Request body: ${jsonEncode({'mobileNo': mobileNo, 'message': message, 'priority': priority, 'countryCode': countryCode})}',
    );

    final response = await http
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

    print('📡 Response status: ${response.statusCode}');
    print('📡 Response body: ${response.body}');

    return _parseResponse(response);
  }

  /// Minimal headers approach
  static Future<SmsUaeSendIfRegisteredResponse> _sendWithMinimalHeaders({
    required String mobileNo,
    required String message,
    String priority = 'High',
    String countryCode = 'ALL',
  }) async {
    print('🔄 Trying minimal headers approach...');

    final minimalHeaders = {
      'Content-Type': 'application/json',
      'Accept': 'application/json',
    };

    final response = await http
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

    print('📡 Minimal headers response status: ${response.statusCode}');
    return _parseResponse(response);
  }

  /// Delayed retry approach
  static Future<SmsUaeSendIfRegisteredResponse> _sendWithDelayedRetry({
    required String mobileNo,
    required String message,
    String priority = 'High',
    String countryCode = 'ALL',
  }) async {
    print('🔄 Trying delayed retry approach...');

    // Wait a bit to avoid rate limiting
    await Future.delayed(const Duration(milliseconds: 1000));

    final customHeaders = Map<String, String>.from(ApiConfig.standardHeaders);
    customHeaders['X-Retry-Attempt'] = 'true';
    customHeaders['X-Client-Version'] = '1.0.0';

    final response = await http
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

    print('📡 Delayed retry response status: ${response.statusCode}');
    return _parseResponse(response);
  }

  /// Parse response and handle HTML error pages
  static SmsUaeSendIfRegisteredResponse _parseResponse(http.Response response) {
    try {
      // Check if response is HTML (WAF error page)
      if (response.body.trim().startsWith('<!DOCTYPE html>') ||
          response.body.trim().startsWith('<html>')) {
        print('❌ Received HTML error page instead of JSON');
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
      print('❌ Failed to parse response: $e');
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
