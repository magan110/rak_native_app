/// Base exception class
class AppException implements Exception {
  final String message;
  final String? code;
  
  AppException(this.message, [this.code]);
  
  @override
  String toString() => 'AppException: $message${code != null ? ' (Code: $code)' : ''}';
}

/// Server exception
class ServerException extends AppException {
  ServerException([super.message = 'Server error occurred', super.code]);
}

/// Cache exception
class CacheException extends AppException {
  CacheException([super.message = 'Cache error occurred', super.code]);
}

/// Network exception
class NetworkException extends AppException {
  NetworkException([super.message = 'Network connection failed', super.code]);
}

/// Validation exception
class ValidationException extends AppException {
  ValidationException([super.message = 'Validation failed', super.code]);
}

/// Authentication exception
class AuthenticationException extends AppException {
  AuthenticationException([super.message = 'Authentication failed', super.code]);
}
