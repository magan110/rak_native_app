import 'dart:developer';
import 'sms_uae_service.dart';

/// Test class for SMS UAE Service
/// Use this to test the integration during development
class SmsUaeTest {
  /// Test health check endpoint
  static Future<void> testHealthCheck() async {
    log('Testing SMS UAE Health Check...');
    try {
      final isHealthy = await SmsUaeService.checkHealth();
      log('Health Check Result: ${isHealthy ? 'HEALTHY' : 'UNHEALTHY'}');
    } catch (e) {
      log('Health Check Error: $e');
    }
  }

  /// Test mobile verification
  static Future<void> testVerifyMobile(String mobileNo) async {
    log('Testing Mobile Verification for: $mobileNo');
    try {
      final response = await SmsUaeService.verifyMobile(mobileNo);
      log('Verify Response: success=${response.success}, exists=${response.exists}, inflType=${response.inflType}');
      if (response.message != null) {
        log('Message: ${response.message}');
      }
    } catch (e) {
      log('Verify Mobile Error: $e');
    }
  }

  /// Test route determination
  static Future<void> testGetRoute(String mobileNo) async {
    log('Testing Route Determination for: $mobileNo');
    try {
      final response = await SmsUaeService.getRouteByMobile(mobileNo);
      log('Route Response: success=${response.success}, exists=${response.exists}, route=${response.route}, inflType=${response.inflType}');
      if (response.message != null) {
        log('Message: ${response.message}');
      }
    } catch (e) {
      log('Get Route Error: $e');
    }
  }

  /// Test SMS sending (use with caution - will actually send SMS)
  static Future<void> testSendSms(String mobileNo, String message) async {
    log('Testing SMS Send to: $mobileNo');
    log('Message: $message');
    try {
      final response = await SmsUaeService.sendSmsIfRegistered(
        mobileNo: mobileNo,
        message: message,
      );
      log('Send Response: success=${response.success}, exists=${response.exists}, route=${response.route}');
      log('Kyoto Status: ${response.kyotoStatus}, Kyoto Response: ${response.kyotoResponse}');
      if (response.message != null) {
        log('Message: ${response.message}');
      }
    } catch (e) {
      log('Send SMS Error: $e');
    }
  }

  /// Run all tests (except SMS sending)
  static Future<void> runAllTests(String testMobileNo) async {
    log('=== Starting SMS UAE Service Tests ===');
    
    await testHealthCheck();
    await Future.delayed(const Duration(seconds: 1));
    
    await testVerifyMobile(testMobileNo);
    await Future.delayed(const Duration(seconds: 1));
    
    await testGetRoute(testMobileNo);
    
    log('=== SMS UAE Service Tests Complete ===');
  }
}