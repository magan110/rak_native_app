import '../models/auth_models.dart';
import '../utils/logger.dart';
import 'storage_service.dart';
import 'auth_service.dart';

/// Enhanced AutoLogin Service for Painter and Contractor users
class AutoLoginService {
  static final AppLogger _logger = AppLogger();

  /// Perform autologin on app startup
  static Future<AutoLoginResult> performAutoLogin() async {
    try {
      _logger.info('🔍 AutoLogin: Attempting autologin...');
      
      // First check if we have stored autologin data
      final autoLoginResult = await StorageService.validateAutoLogin();
      
      _logger.info('🔍 AutoLogin: Validation result - isValid: ${autoLoginResult.isValid}, userType: ${autoLoginResult.userType}, userId: ${autoLoginResult.userId}');
      
      if (!autoLoginResult.isValid) {
        _logger.info('🔍 AutoLogin: No valid autologin data found: ${autoLoginResult.reason}');
        return autoLoginResult;
      }
      
      // Restore user session in AuthManager
      await restoreUserSession(autoLoginResult);
      
      _logger.info('🔍 AutoLogin: Autologin successful for ${autoLoginResult.userType}: ${autoLoginResult.userId}');
      return autoLoginResult;
      
    } catch (e) {
      _logger.error('🔍 AutoLogin: Error during autologin', e);
      return AutoLoginResult(
        isValid: false,
        reason: 'Autologin failed: ${e.toString()}',
      );
    }
  }

  /// Restore user session in AuthManager from autologin data
  static Future<void> restoreUserSession(AutoLoginResult autoLoginResult) async {
    try {
      if (autoLoginResult.userData == null) {
        _logger.info('🔍 AutoLogin: No user data to restore');
        return;
      }

      // Convert stored user data back to UserData object
      final userData = _createUserDataFromStoredData(autoLoginResult.userData!);
      
      // Set user in AuthManager
      AuthManager.setUser(userData);
      
      _logger.info('🔍 AutoLogin: User session restored for ${userData.emplName}');
    } catch (e) {
      _logger.error('🔍 AutoLogin: Error restoring user session', e);
    }
  }

  /// Create UserData object from stored autologin data
  static UserData _createUserDataFromStoredData(Map<String, dynamic> storedData) {
    return UserData(
      userID: storedData['userID'] ?? storedData['userId'],
      emplName: storedData['emplName'] ?? storedData['userName'] ?? 'User',
      areaCode: storedData['areaCode'] ?? storedData['emirates'] ?? '',
      roles: _parseStringList(storedData['roles']),
      pages: _parseStringList(storedData['pages']),
      appRegId: storedData['appRegId'],
    );
  }

  /// Helper method to parse string lists from stored data
  static List<String> _parseStringList(dynamic value) {
    if (value == null) return [];
    if (value is List<String>) return value;
    if (value is List) return value.map((e) => e.toString()).toList();
    if (value is String) return [value];
    return [];
  }

  /// Save autologin data after successful registration or login
  static Future<bool> saveAutoLoginAfterRegistration({
    required String userId,
    required String userType, // 'painter' or 'contractor'
    required String userName,
    required String emirates,
    String? influencerCode,
    String? contractorId,
    Map<String, dynamic>? additionalData,
  }) async {
    try {
      // Create user data map
      final userData = <String, dynamic>{
        'userId': userId,
        'userName': userName,
        'emirates': emirates,
        'userType': userType,
        'registrationDate': DateTime.now().toIso8601String(),
        if (influencerCode != null) 'influencerCode': influencerCode,
        if (contractorId != null) 'contractorId': contractorId,
        if (additionalData != null) ...additionalData,
      };

      // Save autologin data
      final success = await StorageService.saveAutoLoginData(
        userId: userId,
        userType: userType,
        userData: userData,
      );

      if (success) {
        _logger.info('Autologin data saved after registration for $userType: $userId');
      }

      return success;
    } catch (e) {
      _logger.error('Error saving autologin data after registration', e);
      return false;
    }
  }

  /// Save autologin data after successful login
  static Future<bool> saveAutoLoginAfterLogin({
    required UserData userData,
    required String userType,
  }) async {
    try {
      // Convert UserData to map for storage
      final userDataMap = userData.toJson();
      userDataMap['userType'] = userType;
      userDataMap['loginDate'] = DateTime.now().toIso8601String();

      // Save autologin data
      final success = await StorageService.saveAutoLoginData(
        userId: userData.userID ?? userData.emplName,
        userType: userType,
        userData: userDataMap,
      );

      if (success) {
        _logger.info('Autologin data saved after login for $userType: ${userData.userID}');
      }

      return success;
    } catch (e) {
      _logger.error('Error saving autologin data after login', e);
      return false;
    }
  }

  /// Determine user type based on roles or other criteria
  static String determineUserType(UserData userData) {
    // Check roles to determine if user is painter or contractor
    if (userData.hasRole('painter') || userData.hasRole('Painter')) {
      return 'painter';
    } else if (userData.hasRole('contractor') || userData.hasRole('Contractor')) {
      return 'contractor';
    }
    
    // Check pages as fallback
    if (userData.hasPage('painter') || userData.hasPage('Painter')) {
      return 'painter';
    } else if (userData.hasPage('contractor') || userData.hasPage('Contractor')) {
      return 'contractor';
    }
    
    // Default fallback - you might want to handle this differently
    return 'general';
  }

  /// Get the appropriate home route based on user type
  static String getHomeRouteForUserType(String userType) {
    switch (userType.toLowerCase()) {
      case 'painter':
        return '/painter-home';
      case 'contractor':
        return '/contractor-home';
      default:
        return '/home'; // General home screen
    }
  }

  /// Clear autologin data (for logout)
  static Future<bool> clearAutoLogin() async {
    try {
      final success = await StorageService.clearAutoLoginData();
      if (success) {
        _logger.info('Autologin data cleared successfully');
      }
      return success;
    } catch (e) {
      _logger.error('Error clearing autologin data', e);
      return false;
    }
  }

  /// Check if autologin is available
  static Future<bool> isAutoLoginAvailable() async {
    final result = await StorageService.validateAutoLogin();
    return result.isValid;
  }

  /// Get stored user type without full validation
  static Future<String?> getStoredUserType() async {
    return await StorageService.getUserType();
  }

  /// Validate hash integrity (optional security check)
  static bool validateHashIntegrity(String storedHash, String userId, String userType) {
    // You can implement additional hash validation logic here
    // For example, check if hash was generated recently, validate format, etc.
    return storedHash.isNotEmpty && storedHash.length == 64; // SHA-256 length
  }

  /// Refresh autologin data (extend session)
  static Future<bool> refreshAutoLoginSession() async {
    try {
      final currentData = await StorageService.validateAutoLogin();
      
      if (!currentData.isValid || currentData.userData == null) {
        return false;
      }

      // Update the hash while keeping other data
      final userData = Map<String, dynamic>.from(currentData.userData!);
      userData['lastRefresh'] = DateTime.now().toIso8601String();

      final success = await StorageService.saveAutoLoginData(
        userId: currentData.userId!,
        userType: currentData.userType!,
        userData: userData,
      );

      if (success) {
        _logger.info('Autologin session refreshed for ${currentData.userType}: ${currentData.userId}');
      }

      return success;
    } catch (e) {
      _logger.error('Error refreshing autologin session', e);
      return false;
    }
  }
}

/// Enhanced AutoLoginResult with additional helper methods
extension AutoLoginResultExtensions on AutoLoginResult {
  /// Get the appropriate home route for this user
  String get homeRoute => AutoLoginService.getHomeRouteForUserType(userType ?? 'general');
  
  /// Check if this is a painter user
  bool get isPainter => userType?.toLowerCase() == 'painter';
  
  /// Check if this is a contractor user
  bool get isContractor => userType?.toLowerCase() == 'contractor';
  
  /// Get user display name
  String get displayName => userData?['userName'] ?? userData?['emplName'] ?? 'User';
  
  /// Get user emirates
  String get emirates => userData?['emirates'] ?? userData?['areaCode'] ?? '';
}