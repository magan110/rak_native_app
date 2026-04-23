import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:rak_app/core/providers/auth_provider.dart';
import '../config/api_config.dart';
import '../models/auth_models.dart';
import '../utils/logger.dart';
import '../network/ssl_http_client.dart';
import 'storage_service.dart';

class AuthService {
  static final AppLogger _logger = AppLogger();
  static const Duration _defaultTimeout = Duration(seconds: 30);
  static http.Client? _httpClient;

  static String get baseUrl => ApiConfig.baseUrl;
  static const String authEndpoint = '/api/Auth/execute';
  static const String loginEndpoint = '/api/Auth/login';
  static const String autoLoginEndpoint = '/api/Auth/auto-login';
  static const String logoutEndpoint = '/api/Auth/logout';

  /// Force refresh the SSL client (useful after SSL errors)
  static Future<void> refreshSslClient() async {
    _logger.debug('Refreshing SSL client...');

    // Close existing client
    _httpClient?.close();
    _httpClient = null;

    // Dispose SSL client cache
    SslHttpClient.dispose();

    try {
      // Create fresh SSL client
      _httpClient = await SslHttpClient.getClient();
      _logger.debug('SSL client refreshed successfully');
    } catch (e) {
      _logger.error('Failed to refresh SSL client: $e');
      _httpClient = http.Client();
    }
  }

  static Future<bool> testSslConnection() async {
    try {
      _logger.debug('Testing SSL connection to auth server...');

      final client = await SslHttpClient.getClient();
      final uri = Uri.parse('$baseUrl$loginEndpoint');

      // Make a simple HEAD request to test connection
      final response = await client
          .head(uri)
          .timeout(const Duration(seconds: 10));

      _logger.debug('SSL test response: ${response.statusCode}');
      return response.statusCode < 500;
    } catch (e) {
      _logger.error('SSL test failed: $e');
      return false;
    }
  }

  static Future<http.Client> _getClient() async {
    try {
      _logger.debug('AuthService: Getting SSL client...');
      _httpClient ??= await SslHttpClient.getClient();
      return _httpClient!;
    } catch (e) {
      _logger.error(
        'AuthService: Failed to get SSL client, using fallback: $e',
      );
      _httpClient = http.Client();
      return _httpClient!;
    }
  }

  static Future<Map<String, dynamic>> authenticateUser({
    required String userID,
    required String password,
    String? appRegId,
  }) async {
    try {
      _logger.info('Authenticating user: $userID');

      // Test SSL connection first
      _logger.debug('Testing SSL connection to server...');
      final sslTestResult = await SslHttpClient.testConnection(
        '$baseUrl/api/Auth/login',
      );
      _logger.debug('SSL test result: ${sslTestResult ? 'SUCCESS' : 'FAILED'}');

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
      // NOTE: Request body intentionally not logged — contains credentials

      final client = await _getClient();
      final response = await client
          .post(uri, headers: requestHeaders, body: requestBody)
          .timeout(_defaultTimeout);

      _logger.debug('Response status: ${response.statusCode}');

      if (response.statusCode == 200) {
        final responseData = jsonDecode(response.body) as Map<String, dynamic>;

        try {
          // Check if response has the expected structure
          if (responseData['success'] == true && responseData['data'] != null) {
            final userData = responseData['data'] as Map<String, dynamic>;

            // Create UserData with appRegId
            final userDataWithAppRegId = UserData(
              emplName: userData['emplName'] as String,
              areaCode: (userData['areaCode'] ?? '').toString(),
              deptCode: (userData['deptCode'] ?? '').toString(),
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
        // NOTE: Request body intentionally not logged — may contain credentials

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

      // Handle SSL-specific errors
      if (e.toString().contains('HandshakeException') ||
          e.toString().contains('CERTIFICATE_VERIFY_FAILED')) {
        _logger.warning(
          'SSL Error detected, attempting to recreate SSL client...',
        );

        // Clear the cached client and try to recreate it
        _httpClient?.close();
        _httpClient = null;

        try {
          // Try to get a fresh SSL client
          final newClient = await SslHttpClient.createClient();
          _httpClient = newClient;
          _logger.debug('Fresh SSL client created, you may retry the login');
        } catch (sslError) {
          _logger.error('Failed to create fresh SSL client: $sslError');
        }

        return {
          'success': false,
          'error':
              'SSL connection failed. Please check your internet connection and try again.',
          'statusCode': 0,
          'ssl_error': true,
        };
      }

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
      // NOTE: Auto-login request body not logged for security

      final client = await _getClient();
      final response = await client
          .post(uri, headers: requestHeaders, body: requestBody)
          .timeout(_defaultTimeout);

      _logger.debug('Auto-login response status: ${response.statusCode}');
      // NOTE: Auto-login response body not logged for security

      if (response.statusCode == 200) {
        final responseData = jsonDecode(response.body) as Map<String, dynamic>;

        try {
          // Check if response has the expected structure
          if (responseData['success'] == true && responseData['data'] != null) {
            final userData = responseData['data'] as Map<String, dynamic>;

            // Create UserData with appRegId
            final userDataWithAppRegId = UserData(
              emplName: userData['emplName'] as String,
              areaCode: (userData['areaCode'] ?? '').toString(),
              deptCode: (userData['deptCode'] ?? '').toString(),
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

    // Clear local storage including autologin data
    await StorageService.clearAllAuthDataEnhanced();
    AuthManager.clearUser();
    await Future.delayed(const Duration(milliseconds: 500));
  }

  static Future<Map<String, dynamic>> testConnection() async {
    try {
      _logger.info('Testing connection to auth server');

      final uri = Uri.parse('$baseUrl/health');
      final client = await _getClient();
      final response = await client
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

      final client = await _getClient();
      final response = await client
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

      final client = await _getClient();
      final response = await client
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

      final client = await _getClient();
      final response = await client
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
  // Internal AuthProvider instance — will be exposed via Provider package later
  static final AuthProvider _provider = AuthProvider();

  /// Get the underlying AuthProvider (for future Provider integration)
  static AuthProvider get provider => _provider;

  // --- Legacy ValueNotifier for backward compatibility ---
  static final _authChangeNotifier = ValueNotifier<int>(0);
  static ValueNotifier<int> get authChangeNotifier => _authChangeNotifier;

  // --- Delegated getters ---
  static UserData? get currentUser => _provider.currentUser;
  static String? get authToken => _provider.authToken;
  static bool get isLoggedIn => _provider.isLoggedIn;

  // --- Delegated setters ---
  static void setUser(UserData userData, {String? token}) {
    _provider.setUser(userData, token: token);
    _authChangeCallback?.call();
    _authChangeNotifier.value++;
  }

  static void clearUser() {
    _provider.clearUser();
    _authChangeCallback?.call();
    _authChangeNotifier.value++;
  }

  // --- Auth change callback (legacy) ---
  static void Function()? _authChangeCallback;

  static void setAuthChangeCallback(void Function() callback) {
    _authChangeCallback = callback;
  }

  // --- Delegated role/page checks ---
  static bool hasRole(String role) => _provider.hasRole(role);
  static bool hasPage(String page) => _provider.hasPage(page);
  static bool hasAnyRole(List<String> roles) => _provider.hasAnyRole(roles);
  static bool hasAnyPage(List<String> pages) => _provider.hasAnyPage(pages);

  // --- Delegated convenience getters ---
  static List<String> getUserRoles() => _provider.userRoles;
  static List<String> getUserPages() => _provider.userPages;
  static String getUserName() => _provider.userName;
  static String getUserAreaCode() => _provider.userAreaCode;
  static String getUserDeptCode() => _provider.userDeptCode;
}
