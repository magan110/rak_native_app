/// App-wide constants
/// Store all constant values like API keys, timeouts, limits, etc.
class AppConstants {
  // API Configuration
  static const String baseUrl = 'https://api.example.com';
  static const Duration apiTimeout = Duration(seconds: 30);
  
  // App Configuration
  static const String appName = 'RAK App';
  static const String appVersion = '1.0.0';
  
  // Pagination
  static const int defaultPageSize = 20;
  static const int maxPageSize = 100;
  
  // Cache
  static const Duration cacheValidDuration = Duration(hours: 1);
  
  // Animation
  static const Duration defaultAnimationDuration = Duration(milliseconds: 300);
}
