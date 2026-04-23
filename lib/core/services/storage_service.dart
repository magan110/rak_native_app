import 'package:shared_preferences/shared_preferences.dart';
import '../utils/logger.dart';
import 'dart:math';
import 'dart:convert';
import 'package:crypto/crypto.dart';

class StorageService {
  static final AppLogger _logger = AppLogger();
  static const String _appRegIdKey = 'app_reg_id';
  static const String _userIdKey = 'user_id';
  static const String _rememberMeKey = 'remember_me';
  static const String _autoLoginHashKey = 'auto_login_hash';
  static const String _userTypeKey = 'user_type';
  static const String _userDataKey = 'user_data';

  /// Generate a unique app registration ID for this device/app installation
  /// Creates a hash-like string with characters, numbers, and special symbols
  static String generateAppRegId() {
    final random = Random.secure();
    const chars =
        'ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789';
    const symbols = '!@#\$%^&*()_+-=[]{}|;:,.<>?~';

    final buffer = StringBuffer();

    // Generate a 24-character hash-like string
    for (int i = 0; i < 24; i++) {
      if (i % 6 == 0 && i > 0) {
        // Add a symbol every 6 characters
        buffer.write(symbols[random.nextInt(symbols.length)]);
      } else {
        // Add random character or number
        buffer.write(chars[random.nextInt(chars.length)]);
      }
    }

    return buffer.toString();
  }

  /// Save app registration ID to local storage
  static Future<bool> saveAppRegId(String appRegId) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final success = await prefs.setString(_appRegIdKey, appRegId);
      if (success) {
        _logger.info('App registration ID saved successfully');
      } else {
        _logger.error('Failed to save app registration ID');
      }
      return success;
    } catch (e) {
      _logger.error('Error saving app registration ID', e);
      return false;
    }
  }

  /// Get stored app registration ID
  static Future<String?> getAppRegId() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final appRegId = prefs.getString(_appRegIdKey);
      if (appRegId != null) {
        _logger.debug('Retrieved app registration ID: [present]');
      }
      return appRegId;
    } catch (e) {
      _logger.error('Error retrieving app registration ID', e);
      return null;
    }
  }

  /// Clear app registration ID (for logout)
  static Future<bool> clearAppRegId() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final success = await prefs.remove(_appRegIdKey);
      if (success) {
        _logger.info('App registration ID cleared successfully');
      }
      return success;
    } catch (e) {
      _logger.error('Error clearing app registration ID', e);
      return false;
    }
  }

  /// Save user ID for remember me functionality
  static Future<bool> saveUserId(String userId) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      return await prefs.setString(_userIdKey, userId);
    } catch (e) {
      _logger.error('Error saving user ID', e);
      return false;
    }
  }

  /// Get stored user ID
  static Future<String?> getUserId() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      return prefs.getString(_userIdKey);
    } catch (e) {
      _logger.error('Error retrieving user ID', e);
      return null;
    }
  }

  /// Save remember me preference
  static Future<bool> saveRememberMe(bool remember) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      return await prefs.setBool(_rememberMeKey, remember);
    } catch (e) {
      _logger.error('Error saving remember me preference', e);
      return false;
    }
  }

  /// Get remember me preference
  static Future<bool> getRememberMe() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      return prefs.getBool(_rememberMeKey) ?? false;
    } catch (e) {
      _logger.error('Error retrieving remember me preference', e);
      return false;
    }
  }

  /// Clear all stored authentication data
  static Future<bool> clearAllAuthData() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final results = await Future.wait([
        prefs.remove(_appRegIdKey),
        prefs.remove(_userIdKey),
        prefs.remove(_rememberMeKey),
      ]);

      final success = results.every((result) => result);
      if (success) {
        _logger.info('All authentication data cleared successfully');
      }
      return success;
    } catch (e) {
      _logger.error('Error clearing authentication data', e);
      return false;
    }
  }

  /// Check if auto-login is possible (has stored appRegId)
  static Future<bool> canAutoLogin() async {
    final appRegId = await getAppRegId();
    return appRegId != null && appRegId.isNotEmpty;
  }

  /// Check if user has stored credentials (for splash screen)
  static Future<bool> hasStoredCredentials() async {
    final userId = await getUserId();
    final rememberMe = await getRememberMe();
    return userId != null && userId.isNotEmpty && rememberMe;
  }

  /// Generate a secure hash key for autologin
  /// Combines device info, timestamp, and random data for uniqueness
  static String generateAutoLoginHash({
    required String userId,
    required String userType, // 'painter' or 'contractor'
    String? deviceId,
  }) {
    final timestamp = DateTime.now().millisecondsSinceEpoch.toString();
    final random = Random.secure();
    final randomBytes = List.generate(16, (_) => random.nextInt(256));
    
    // Create a unique string combining user info, timestamp, and random data
    final combinedData = '$userId:$userType:$timestamp:${deviceId ?? 'unknown'}:${randomBytes.join(',')}';
    
    // Generate SHA-256 hash
    final bytes = utf8.encode(combinedData);
    final digest = sha256.convert(bytes);
    
    return digest.toString();
  }

  /// Save autologin hash and user data for automatic login
  static Future<bool> saveAutoLoginData({
    required String userId,
    required String userType, // 'painter' or 'contractor'
    required Map<String, dynamic> userData,
    String? deviceId,
  }) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      
      // Generate unique hash for this login session
      final hash = generateAutoLoginHash(
        userId: userId,
        userType: userType,
        deviceId: deviceId,
      );
      
      // Save all autologin data
      final results = await Future.wait([
        prefs.setString(_autoLoginHashKey, hash),
        prefs.setString(_userTypeKey, userType),
        prefs.setString(_userDataKey, jsonEncode(userData)),
        prefs.setString(_userIdKey, userId),
      ]);
      
      final success = results.every((result) => result);
      if (success) {
        _logger.info('Autologin data saved successfully for $userType: $userId');
      } else {
        _logger.error('Failed to save autologin data');
      }
      return success;
    } catch (e) {
      _logger.error('Error saving autologin data', e);
      return false;
    }
  }

  /// Get stored autologin hash
  static Future<String?> getAutoLoginHash() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      return prefs.getString(_autoLoginHashKey);
    } catch (e) {
      _logger.error('Error retrieving autologin hash', e);
      return null;
    }
  }

  /// Get stored user type (painter/contractor)
  static Future<String?> getUserType() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      return prefs.getString(_userTypeKey);
    } catch (e) {
      _logger.error('Error retrieving user type', e);
      return null;
    }
  }

  /// Get stored user data
  static Future<Map<String, dynamic>?> getUserData() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final userDataString = prefs.getString(_userDataKey);
      if (userDataString != null) {
        return jsonDecode(userDataString) as Map<String, dynamic>;
      }
      return null;
    } catch (e) {
      _logger.error('Error retrieving user data', e);
      return null;
    }
  }

  /// Validate autologin hash and return user data if valid
  static Future<AutoLoginResult> validateAutoLogin() async {
    try {
      _logger.info('🔍 Storage: Starting autologin validation...');
      
      final hash = await getAutoLoginHash();
      final userType = await getUserType();
      final userData = await getUserData();
      final userId = await getUserId();
      
      _logger.info('🔍 Storage: Retrieved data - hash: ${hash != null ? 'exists' : 'null'}, userType: $userType, userData: ${userData != null ? 'exists' : 'null'}, userId: $userId');
      
      if (hash == null || userType == null || userData == null || userId == null) {
        final reason = 'Missing data - hash: ${hash == null ? 'missing' : 'ok'}, userType: ${userType == null ? 'missing' : 'ok'}, userData: ${userData == null ? 'missing' : 'ok'}, userId: ${userId == null ? 'missing' : 'ok'}';
        _logger.info('🔍 Storage: Incomplete autologin data found - $reason');
        return AutoLoginResult(
          isValid: false,
          reason: reason,
        );
      }
      
      // Verify hash is still valid (you can add expiration logic here)
      // For now, we'll consider it valid if all data exists
      _logger.info('🔍 Storage: Valid autologin data found for $userType: $userId');
      
      return AutoLoginResult(
        isValid: true,
        userType: userType,
        userData: userData,
        userId: userId,
        hash: hash,
      );
    } catch (e) {
      _logger.error('🔍 Storage: Error validating autologin', e);
      return AutoLoginResult(
        isValid: false,
        reason: 'Error validating autologin: ${e.toString()}',
      );
    }
  }

  /// Clear autologin data
  static Future<bool> clearAutoLoginData() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final results = await Future.wait([
        prefs.remove(_autoLoginHashKey),
        prefs.remove(_userTypeKey),
        prefs.remove(_userDataKey),
      ]);
      
      final success = results.every((result) => result);
      if (success) {
        _logger.info('Autologin data cleared successfully');
      }
      return success;
    } catch (e) {
      _logger.error('Error clearing autologin data', e);
      return false;
    }
  }

  /// Enhanced clear all auth data to include autologin data (replaces clearAllAuthData)
  static Future<bool> clearAllAuthDataEnhanced() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final results = await Future.wait([
        prefs.remove(_appRegIdKey),
        prefs.remove(_userIdKey),
        prefs.remove(_rememberMeKey),
        prefs.remove(_autoLoginHashKey),
        prefs.remove(_userTypeKey),
        prefs.remove(_userDataKey),
      ]);

      final success = results.every((result) => result);
      if (success) {
        _logger.info('All authentication and autologin data cleared successfully');
      }
      return success;
    } catch (e) {
      _logger.error('Error clearing all authentication data', e);
      return false;
    }
  }
}

/// Result class for autologin validation
class AutoLoginResult {
  final bool isValid;
  final String? userType;
  final Map<String, dynamic>? userData;
  final String? userId;
  final String? hash;
  final String? reason;

  AutoLoginResult({
    required this.isValid,
    this.userType,
    this.userData,
    this.userId,
    this.hash,
    this.reason,
  });
}
