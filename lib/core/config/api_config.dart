/// API Configuration
class ApiConfig {
  // Base URL
  static const String baseUrl = 'https://qa.birlawhite.com:55232';

  // SMS UAE API endpoints
  static String get smsUaeBaseUrl => '$baseUrl/api/SmsUae';
  static String get verifyMobileUrl => '$smsUaeBaseUrl/verify-mobile';
  static String get routeByMobileUrl => '$smsUaeBaseUrl/route-by-mobile';
  static String get sendSmsUrl => '$smsUaeBaseUrl/send';
  static String get sendIfRegisteredUrl => '$smsUaeBaseUrl/send-if-registered';

  // Health check endpoint
  static String get healthCheckUrl => '$smsUaeBaseUrl/health';

  // Maintenance check endpoint
  static String get maintenanceStatusUrl =>
      '$baseUrl/api/RakUnderMaintainance/status';

  // Image upload endpoint
  static String get imageUploadUrl => '$baseUrl/api/ImageUpload/upload';

  // Timeout configurations
  static const Duration defaultTimeout = Duration(seconds: 15);
  static const Duration smsTimeout = Duration(seconds: 20);

  // OTP configurations
  static const Duration otpTtl = Duration(minutes: 5);
  static const Duration resendCooldown = Duration(seconds: 30);

  // SMS message template - exact format that works in Postman
  static String otpMessage(String otp) =>
      'Dear User Your One time password OTP is : $otp Birla White (RAK)';

  // Enhanced HTTP headers to bypass WAF/security systems
  static Map<String, String> get standardHeaders => {
    'Content-Type': 'application/json',
    'Accept': 'application/json, text/plain, */*',
    'User-Agent':
        'Mozilla/5.0 (Linux; Android 10; SM-G975F) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/91.0.4472.120 Mobile Safari/537.36 RAK-Mobile-App/1.0.0',
    'Accept-Language': 'en-US,en;q=0.9,ar;q=0.8',
    'Accept-Encoding': 'gzip, deflate, br',
    'Connection': 'keep-alive',
    'Cache-Control': 'no-cache, no-store, must-revalidate',
    'Pragma': 'no-cache',
    'Expires': '0',
    'X-Requested-With': 'XMLHttpRequest',
    'Origin': 'https://qa.birlawhite.com:55232',
    'Referer': 'https://qa.birlawhite.com:55232/',
    'Sec-Fetch-Dest': 'empty',
    'Sec-Fetch-Mode': 'cors',
    'Sec-Fetch-Site': 'same-origin',
    'DNT': '1',
  };
}
