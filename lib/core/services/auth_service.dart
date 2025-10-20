import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import '../models/auth_models.dart';
import '../utils/logger.dart';
import 'storage_service.dart';

class AuthService {
  static final AppLogger _logger = AppLogger();
  static const Duration _defaultTimeout = Duration(seconds: 30);

  static const String baseUrl = 'https://qa.birlawhite.com:55232';
  static const String authEndpoint = '/api/Auth/execute';
  static const String loginEndpoint = '/api/Auth/login';
  static const String autoLoginEndpoint = '/api/Auth/auto-login';
  static const String logoutEndpoint = '/api/Auth/logout';

  static Future<Map<String, dynamic>> authenticateUser({
    required String userID,
    required String password,
    String? appRegId,
  }) async {
    try {
      _logger.info('Authenticating user: $userID');

      // Generate or use provided appRegId
      final finalAppRegId = appRegId ?? StorageService.generateAppRegId();

      final loginRequest = LoginRequest(
        userID: userID,
        password: password,
        appRegId: finalAppRegId,
      );

      final uri = Uri.parse('$baseUrl$loginEndpoint');
      final requestHeaders = {
        'Content-Type': 'application/json',
        'Accept': 'application/json',
      };

      final requestBody = jsonEncode(loginRequest.toJson());

      _logger.debug('Making POST request to: $uri');
      _logger.debug('Request headers: $requestHeaders');
      _logger.debug('Request body: $requestBody');

      final response = await http
          .post(uri, headers: requestHeaders, body: requestBody)
          .timeout(_defaultTimeout);

      _logger.debug('Response status: ${response.statusCode}');
      _logger.debug('Response headers: ${response.headers}');
      _logger.debug('Response body: ${response.body}');

      if (response.statusCode == 200) {
        final responseData = jsonDecode(response.body) as Map<String, dynamic>;

        try {
          // Check if response has the expected structure
          if (responseData['success'] == true && responseData['data'] != null) {
            final userData = responseData['data'] as Map<String, dynamic>;

            // Create UserData with appRegId
            final userDataWithAppRegId = UserData(
              emplName: userData['emplName'] as String,
              areaCode: userData['areaCode'] as String,
              roles: (userData['roles'] as List<dynamic>).cast<String>(),
              pages: (userData['pages'] as List<dynamic>).cast<String>(),
              userID: userData['userID'] as String? ?? userID,
              appRegId: finalAppRegId,
            );

            // Save appRegId to local storage for auto-login
            await StorageService.saveAppRegId(finalAppRegId);

            _logger.info('Authentication successful for user: $userID');

            return {
              'success': true,
              'data': LoginResponse(
                msg: 'Login successful',
                data: userDataWithAppRegId,
              ),
              'statusCode': response.statusCode,
            };
          } else {
            return {
              'success': false,
              'error': responseData['error'] ?? 'Invalid response format',
              'statusCode': response.statusCode,
            };
          }
        } catch (e) {
          _logger.error('Failed to parse login response', e);
          return {
            'success': false,
            'error': 'Invalid response format from server',
            'statusCode': response.statusCode,
          };
        }
      } else if (response.statusCode == 401) {
        final errorData = _safeJsonDecode(response.body);
        final errorMessage = errorData['error'] ?? 'Authentication failed';

        _logger.warning(
          'Authentication failed for user: $userID - $errorMessage',
        );

        return {
          'success': false,
          'error': errorMessage,
          'statusCode': response.statusCode,
        };
      } else if (response.statusCode == 400) {
        final errorData = _safeJsonDecode(response.body);
        final errorMessage = errorData['error'] ?? response.body.isNotEmpty
            ? response.body
            : 'Invalid request parameters';

        _logger.warning('Bad request for user: $userID - $errorMessage');
        _logger.warning('Request was: $requestBody');

        return {
          'success': false,
          'error': 'Bad Request: $errorMessage',
          'statusCode': response.statusCode,
          'raw_response': response.body,
        };
      } else {
        final errorData = _safeJsonDecode(response.body);
        final errorMessage = errorData['error'] ?? 'Server error occurred';

        _logger.error(
          'Server error during authentication: ${response.statusCode} - $errorMessage',
        );

        return {
          'success': false,
          'error': errorMessage,
          'statusCode': response.statusCode,
        };
      }
    } on http.ClientException catch (e) {
      _logger.error('Network error during authentication', e);
      return {
        'success': false,
        'error':
            'Network connection failed. Please check your internet connection.',
        'statusCode': 0,
      };
    } on FormatException catch (e) {
      _logger.error('JSON parsing error during authentication', e);
      return {
        'success': false,
        'error': 'Invalid response from server',
        'statusCode': 0,
      };
    } catch (e) {
      _logger.error('Unexpected error during authentication', e);
      return {
        'success': false,
        'error': 'An unexpected error occurred: ${e.toString()}',
        'statusCode': 0,
      };
    }
  }

  /// Auto-login using stored appRegId
  static Future<Map<String, dynamic>> autoLogin() async {
    try {
      _logger.info('Attempting auto-login');

      // Get stored appRegId
      final appRegId = await StorageService.getAppRegId();
      if (appRegId == null || appRegId.isEmpty) {
        _logger.info('No stored appRegId found for auto-login');
        return {
          'success': false,
          'error': 'No stored session found',
          'statusCode': 0,
        };
      }

      final autoLoginRequest = AutoLoginRequest(appRegId: appRegId);
      final uri = Uri.parse('$baseUrl$autoLoginEndpoint');
      final requestHeaders = {
        'Content-Type': 'application/json',
        'Accept': 'application/json',
      };

      final requestBody = jsonEncode(autoLoginRequest.toJson());

      _logger.debug('Making auto-login POST request to: $uri');
      _logger.debug('Request body: $requestBody');

      final response = await http
          .post(uri, headers: requestHeaders, body: requestBody)
          .timeout(_defaultTimeout);

      _logger.debug('Auto-login response status: ${response.statusCode}');
      _logger.debug('Auto-login response body: ${response.body}');

      if (response.statusCode == 200) {
        final responseData = jsonDecode(response.body) as Map<String, dynamic>;

        try {
          // Check if response has the expected structure
          if (responseData['success'] == true && responseData['data'] != null) {
            final userData = responseData['data'] as Map<String, dynamic>;

            // Create UserData with appRegId
            final userDataWithAppRegId = UserData(
              emplName: userData['emplName'] as String,
              areaCode: userData['areaCode'] as String,
              roles: (userData['roles'] as List<dynamic>).cast<String>(),
              pages: (userData['pages'] as List<dynamic>).cast<String>(),
              userID: userData['userID'] as String?,
              appRegId: appRegId,
            );

            _logger.info('Auto-login successful');

            return {
              'success': true,
              'data': userDataWithAppRegId,
              'statusCode': response.statusCode,
            };
          } else {
            return {
              'success': false,
              'error': responseData['error'] ?? 'Invalid response format',
              'statusCode': response.statusCode,
            };
          }
        } catch (e) {
          _logger.error('Failed to parse auto-login response', e);
          return {
            'success': false,
            'error': 'Invalid response format from server',
            'statusCode': response.statusCode,
          };
        }
      } else if (response.statusCode == 401) {
        final errorData = _safeJsonDecode(response.body);
        final errorMessage = errorData['error'] ?? 'Session expired';

        _logger.warning('Auto-login failed: $errorMessage');

        // Clear invalid appRegId
        await StorageService.clearAppRegId();

        return {
          'success': false,
          'error': errorMessage,
          'statusCode': response.statusCode,
        };
      } else {
        final errorData = _safeJsonDecode(response.body);
        final errorMessage = errorData['error'] ?? 'Auto-login failed';

        _logger.error(
          'Auto-login server error: ${response.statusCode} - $errorMessage',
        );

        return {
          'success': false,
          'error': errorMessage,
          'statusCode': response.statusCode,
        };
      }
    } on http.ClientException catch (e) {
      _logger.error('Network error during auto-login', e);
      return {
        'success': false,
        'error':
            'Network connection failed. Please check your internet connection.',
        'statusCode': 0,
      };
    } catch (e) {
      _logger.error('Unexpected error during auto-login', e);
      return {
        'success': false,
        'error': 'An unexpected error occurred: ${e.toString()}',
        'statusCode': 0,
      };
    }
  }

  static Future<bool> login(String userId, String password) async {
    final result = await authenticateUser(userID: userId, password: password);
    if (result['success'] == true) {
      final loginResponse = result['data'] as LoginResponse;
      AuthManager.setUser(loginResponse.data);
      return true;
    }
    return false;
  }

  static Future<bool> loginWithOtp(String mobile, String otp) async {
    await Future.delayed(const Duration(seconds: 1));
    return mobile.isNotEmpty && otp.isNotEmpty;
  }

  static Future<bool> sendOtp(String mobile) async {
    await Future.delayed(const Duration(seconds: 1));
    return mobile.isNotEmpty;
  }

  static Future<void> logout() async {
    // Try to logout from server first
    final serverLogout = await logoutFromServer();
    if (!serverLogout['success']) {
      _logger.warning('Server logout failed, clearing local session anyway');
    }

    // Clear local storage
    await StorageService.clearAllAuthData();
    AuthManager.clearUser();
    await Future.delayed(const Duration(milliseconds: 500));
  }

  static Future<Map<String, dynamic>> testConnection() async {
    try {
      _logger.info('Testing connection to auth server');

      final uri = Uri.parse('$baseUrl/health');
      final response = await http
          .get(uri, headers: {'Accept': 'application/json'})
          .timeout(const Duration(seconds: 10));

      _logger.debug('Health check response: ${response.statusCode}');

      return {
        'success': response.statusCode == 200,
        'statusCode': response.statusCode,
        'message': response.statusCode == 200
            ? 'Connection successful'
            : 'Server responded with status ${response.statusCode}',
      };
    } catch (e) {
      _logger.error('Connection test failed', e);
      return {
        'success': false,
        'statusCode': 0,
        'message': 'Connection failed: ${e.toString()}',
      };
    }
  }

  static Map<String, dynamic> _safeJsonDecode(String body) {
    try {
      final decoded = jsonDecode(body);
      return decoded is Map<String, dynamic>
          ? decoded
          : {'raw': decoded.toString()};
    } catch (_) {
      return {'raw': body};
    }
  }

  // Session validation endpoint
  static Future<Map<String, dynamic>> validateSession() async {
    try {
      _logger.info('Validating user session');

      final uri = Uri.parse('$baseUrl/auth/me');
      final requestHeaders = {
        'Content-Type': 'application/json',
        'Accept': 'application/json',
      };

      final response = await http
          .get(uri, headers: requestHeaders)
          .timeout(const Duration(seconds: 10));

      _logger.debug('Session validation response: ${response.statusCode}');

      if (response.statusCode == 200) {
        final responseData = jsonDecode(response.body) as Map<String, dynamic>;

        return {
          'success': true,
          'data': responseData,
          'statusCode': response.statusCode,
        };
      } else {
        return {
          'success': false,
          'error': 'Session validation failed',
          'statusCode': response.statusCode,
        };
      }
    } catch (e) {
      _logger.error('Session validation error', e);
      return {
        'success': false,
        'error': 'Network error during session validation',
        'statusCode': 0,
      };
    }
  }

  // Token refresh endpoint
  static Future<Map<String, dynamic>> refreshToken() async {
    try {
      _logger.info('Refreshing access token');

      final uri = Uri.parse('$baseUrl/auth/refresh');
      final requestHeaders = {
        'Content-Type': 'application/json',
        'Accept': 'application/json',
      };

      final response = await http
          .post(uri, headers: requestHeaders)
          .timeout(const Duration(seconds: 10));

      _logger.debug('Token refresh response: ${response.statusCode}');

      if (response.statusCode == 200) {
        final responseData = jsonDecode(response.body) as Map<String, dynamic>;

        return {
          'success': true,
          'data': responseData,
          'statusCode': response.statusCode,
        };
      } else {
        return {
          'success': false,
          'error': 'Token refresh failed',
          'statusCode': response.statusCode,
        };
      }
    } catch (e) {
      _logger.error('Token refresh error', e);
      return {
        'success': false,
        'error': 'Network error during token refresh',
        'statusCode': 0,
      };
    }
  }

  // Enhanced logout with server-side session clearing
  static Future<Map<String, dynamic>> logoutFromServer() async {
    try {
      _logger.info('Logging out from server');

      // Get stored appRegId for logout
      final appRegId = await StorageService.getAppRegId();
      if (appRegId == null || appRegId.isEmpty) {
        _logger.info('No appRegId found for server logout');
        return {'success': true, 'statusCode': 200};
      }

      final logoutRequest = LogoutRequest(appRegId: appRegId);
      final uri = Uri.parse('$baseUrl$logoutEndpoint');
      final requestHeaders = {
        'Content-Type': 'application/json',
        'Accept': 'application/json',
      };

      final requestBody = jsonEncode(logoutRequest.toJson());

      final response = await http
          .post(uri, headers: requestHeaders, body: requestBody)
          .timeout(const Duration(seconds: 10));

      _logger.debug('Server logout response: ${response.statusCode}');

      return {
        'success': response.statusCode == 200,
        'statusCode': response.statusCode,
      };
    } catch (e) {
      _logger.error('Server logout error', e);
      return {
        'success': false,
        'error': 'Network error during logout',
        'statusCode': 0,
      };
    }
  }
}

class AuthManager {
  static UserData? _currentUser;
  static String? _authToken;
  static final _authChangeNotifier = ValueNotifier<int>(0);

  static UserData? get currentUser => _currentUser;
  static String? get authToken => _authToken;
  static bool get isLoggedIn => _currentUser != null;
  static ValueNotifier<int> get authChangeNotifier => _authChangeNotifier;

  static void setUser(UserData userData, {String? token}) {
    _currentUser = userData;
    _authToken = token;
    _notifyAuthChanged();
  }

  static void clearUser() {
    _currentUser = null;
    _authToken = null;
    _notifyAuthChanged();
  }

  static void Function()? _authChangeCallback;

  static void setAuthChangeCallback(void Function() callback) {
    _authChangeCallback = callback;
  }

  static void _notifyAuthChanged() {
    _authChangeCallback?.call();
    _authChangeNotifier.value++;
  }

  static bool hasRole(String role) {
    return _currentUser?.hasRole(role) ?? false;
  }

  static bool hasPage(String page) {
    return _currentUser?.hasPage(page) ?? false;
  }

  static bool hasAnyRole(List<String> roles) {
    return _currentUser?.hasAnyRole(roles) ?? false;
  }

  static bool hasAnyPage(List<String> pages) {
    return _currentUser?.hasAnyPage(pages) ?? false;
  }

  static List<String> getUserRoles() {
    return _currentUser?.roles ?? [];
  }

  static List<String> getUserPages() {
    return _currentUser?.pages ?? [];
  }

  static String getUserName() {
    return _currentUser?.emplName ?? '';
  }

  static String getUserAreaCode() {
    return _currentUser?.areaCode ?? '';
  }
}
