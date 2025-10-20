/// Application configuration
/// Environment-specific settings
class AppConfig {
  final String apiBaseUrl;
  final bool enableLogging;
  final String environment;
  
  AppConfig._({
    required this.apiBaseUrl,
    required this.enableLogging,
    required this.environment,
  });
  
  /// Development configuration
  static AppConfig get development => AppConfig._(
    apiBaseUrl: 'https://dev-api.example.com',
    enableLogging: true,
    environment: 'development',
  );
  
  /// Staging configuration
  static AppConfig get staging => AppConfig._(
    apiBaseUrl: 'https://staging-api.example.com',
    enableLogging: true,
    environment: 'staging',
  );
  
  /// Production configuration
  static AppConfig get production => AppConfig._(
    apiBaseUrl: 'https://api.example.com',
    enableLogging: false,
    environment: 'production',
  );
  
  /// Current configuration (change based on environment)
  static AppConfig get current => development;
}
