import 'package:flutter/material.dart';
import 'lib/core/services/sms_uae_service.dart';
import 'lib/core/config/api_config.dart';

/// Simple test script to verify SMS UAE connectivity and WAF bypass
void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  print('🧪 Testing SMS UAE Service Connectivity');
  print('=' * 50);
  
  // Test endpoint connectivity
  print('1. Testing endpoint connectivity...');
  final connectivity = await SmsUaeService.testEndpointConnectivity();
  
  for (final entry in connectivity.entries) {
    final status = entry.value ? '✅ Working' : '❌ Blocked';
    print('   ${entry.key}: $status');
  }
  
  print('\n2. Testing mobile verification...');
  final testMobile = '505555555';
  final verifyResponse = await SmsUaeService.verifyMobile(testMobile);
  print('   Mobile $testMobile verification:');
  print('   - Success: ${verifyResponse.success}');
  print('   - Exists: ${verifyResponse.exists}');
  print('   - Status Code: ${verifyResponse.statusCode}');
  print('   - Message: ${verifyResponse.message}');
  
  print('\n3. Testing OTP send (if registered)...');
  final sendResponse = await SmsUaeService.sendSmsIfRegistered(
    mobileNo: testMobile,
    message: 'Dear User, your one-time password OTP is: 123456 Birla White (RAK)',
    priority: 'High',
    countryCode: 'ALL',
  );
  
  print('   OTP send result:');
  print('   - Success: ${sendResponse.success}');
  print('   - Exists: ${sendResponse.exists}');
  print('   - Status Code: ${sendResponse.statusCode}');
  print('   - Message: ${sendResponse.message}');
  
  if (sendResponse.kyotoStatus != null) {
    print('   - Kyoto Status: ${sendResponse.kyotoStatus}');
  }
  
  print('\n🏁 Test completed');
}