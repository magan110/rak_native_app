import 'dart:math';
import 'package:shared_preferences/shared_preferences.dart';
import '../utils/logger.dart';

/// Centralized OTP generation, storage, and verification service.
///
/// Replaces the duplicated OTP logic in:
/// - login_screen_with_otp.dart (~110 lines)
/// - contractor_registration_screen.dart (~90 lines)
/// - painter_registration_screen.dart (~90 lines)
///
/// Each screen uses a different [keyPrefix] to avoid collisions:
/// - Login: ''  (uses 'otp_code', 'otp_mobile', etc.)
/// - Contractor: 'contractor_'
/// - Painter: 'painter_'
class OtpService {
  static final AppLogger _logger = AppLogger();

  /// OTP length
  static const int otpLength = 6;

  /// OTP expiry duration
  static const Duration otpExpiry = Duration(minutes: 10);

  /// Resend cooldown duration
  static const Duration resendCooldown = Duration(seconds: 60);

  // SharedPreferences keys (with prefix)
  static String _codeKey(String prefix) => '${prefix}otp_code';
  static String _mobileKey(String prefix) => '${prefix}otp_mobile';
  static String _expiryKey(String prefix) => '${prefix}otp_expiry';
  static String _cooldownKey(String prefix) => '${prefix}otp_cooldown';

  /// Generate a random 6-digit OTP
  static String generate() {
    final rng = Random.secure();
    final otp = List.generate(otpLength, (_) => rng.nextInt(10)).join();
    _logger.debug('OTP generated');
    return otp;
  }

  /// Normalize a mobile number by stripping non-digits
  static String normalizeMobile(String raw) {
    return raw.replaceAll(RegExp(r'[^0-9]'), '');
  }

  /// Get all possible mobile number formats for matching
  static List<String> getAllMobileFormats(String rawMobile) {
    final cleaned = normalizeMobile(rawMobile);
    final formats = <String>{cleaned};

    // Add with/without 971 prefix
    if (cleaned.startsWith('971')) {
      formats.add(cleaned.substring(3));
    } else {
      formats.add('971$cleaned');
    }

    // Add with/without leading zero
    if (cleaned.startsWith('0')) {
      formats.add(cleaned.substring(1));
      formats.add('971${cleaned.substring(1)}');
    }

    return formats.toList();
  }

  /// Save OTP + mobile to SharedPreferences with expiry
  static Future<void> save({
    required SharedPreferences prefs,
    required String mobile,
    required String otp,
    String keyPrefix = '',
  }) async {
    final cleanMobile = normalizeMobile(mobile);
    final expiryMs = DateTime.now().add(otpExpiry).millisecondsSinceEpoch;

    await prefs.setString(_codeKey(keyPrefix), otp);
    await prefs.setString(_mobileKey(keyPrefix), cleanMobile);
    await prefs.setInt(_expiryKey(keyPrefix), expiryMs);

    _logger.debug('OTP saved for prefix: $keyPrefix');
  }

  /// Load stored OTP data (returns null if expired or not found)
  static Map<String, dynamic>? load({
    required SharedPreferences prefs,
    String keyPrefix = '',
  }) {
    final code = prefs.getString(_codeKey(keyPrefix));
    final mobile = prefs.getString(_mobileKey(keyPrefix));
    final expiryMs = prefs.getInt(_expiryKey(keyPrefix));

    if (code == null || mobile == null || expiryMs == null) return null;

    final expiry = DateTime.fromMillisecondsSinceEpoch(expiryMs);
    if (DateTime.now().isAfter(expiry)) {
      _logger.debug('OTP expired for prefix: $keyPrefix');
      clear(prefs: prefs, keyPrefix: keyPrefix);
      return null;
    }

    return {
      'code': code,
      'mobile': mobile,
      'expiry': expiry,
    };
  }

  /// Clear stored OTP data
  static Future<void> clear({
    required SharedPreferences prefs,
    String keyPrefix = '',
  }) async {
    await prefs.remove(_codeKey(keyPrefix));
    await prefs.remove(_mobileKey(keyPrefix));
    await prefs.remove(_expiryKey(keyPrefix));
  }

  /// Set resend cooldown timestamp
  static Future<void> setResendCooldown({
    required SharedPreferences prefs,
    String keyPrefix = '',
  }) async {
    final cooldownEnd = DateTime.now().add(resendCooldown).millisecondsSinceEpoch;
    await prefs.setInt(_cooldownKey(keyPrefix), cooldownEnd);
  }

  /// Get remaining cooldown seconds (0 if cooldown is over)
  static int getResendCooldownLeft({
    required SharedPreferences prefs,
    String keyPrefix = '',
  }) {
    final cooldownMs = prefs.getInt(_cooldownKey(keyPrefix));
    if (cooldownMs == null) return 0;

    final now = DateTime.now().millisecondsSinceEpoch;
    final remaining = ((cooldownMs - now) / 1000).ceil();
    return remaining > 0 ? remaining : 0;
  }

  /// Verify an OTP against stored value
  static bool verify({
    required SharedPreferences prefs,
    required String mobile,
    required String enteredOtp,
    String keyPrefix = '',
  }) {
    final stored = load(prefs: prefs, keyPrefix: keyPrefix);
    if (stored == null) {
      _logger.warning('No stored OTP found for verification (prefix: $keyPrefix)');
      return false;
    }

    final storedCode = stored['code'] as String;
    final storedMobile = stored['mobile'] as String;

    // Check OTP matches
    if (enteredOtp != storedCode) {
      _logger.warning('OTP mismatch for prefix: $keyPrefix');
      return false;
    }

    // Check mobile matches (try all formats)
    final cleanedInput = normalizeMobile(mobile);
    final allFormats = getAllMobileFormats(cleanedInput);

    if (!allFormats.contains(storedMobile) &&
        !getAllMobileFormats(storedMobile).contains(cleanedInput)) {
      _logger.warning('Mobile mismatch for prefix: $keyPrefix');
      return false;
    }

    _logger.debug('OTP verified successfully for prefix: $keyPrefix');
    return true;
  }
}
