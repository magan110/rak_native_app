/// API Endpoints
/// Centralize all API endpoints
class ApiEndpoints {
  // Auth endpoints
  static const String login = '/auth/login';
  static const String register = '/auth/register';
  static const String logout = '/auth/logout';
  static const String refreshToken = '/auth/refresh';

  // Backend auth controller (sparshWebService) endpoints
  static const String authLogin = '/api/Auth/login';
  static const String authAutoLogin = '/api/Auth/auto-login';
  static const String authLogout = '/api/Auth/logout';
  
  // User endpoints
  static const String userProfile = '/user/profile';
  static const String updateProfile = '/user/update';
  
  // Add more endpoints as needed
}
