import 'package:shared_preferences/shared_preferences.dart';
import '../utils/logger.dart';
import 'dart:math';
import 'dart:convert';
import 'dart:typed_data';

class StorageService {
  static final AppLogger _logger = AppLogger();
  static const String _appRegIdKey = 'app_reg_id';
  static const String _userIdKey = 'user_id';
  static const String _rememberMeKey = 'remember_me';

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
        _logger.debug('Retrieved app registration ID: $appRegId');
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
}
