import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:rak_app/core/constants/app_constants.dart';

import '../models/painter_models.dart';

class PainterService {
  static String get _baseUrl => AppConstants.baseUrl;

  static const _registerPath = '/api/Painter/register';
  static const _emiratesPath = '/api/Painter/emirates-list';
  static const _checkMobilePath = '/api/Painter/check-mobile';

  static const _updatePath = '/api/Painter/update';

  static Map<String, String> get _jsonHeaders => const {
    'Content-Type': 'application/json',
    'Accept': 'application/json',
  };

  // Get Emirates List for dropdown
  static Future<List<EmirateItem>> getEmiratesList() async {
    final uri = Uri.parse('$_baseUrl$_emiratesPath');
    final res = await http.get(uri, headers: _jsonHeaders);
    if (res.statusCode == 200) {
      final body = json.decode(res.body);
      if (body is List) {
        return body
            .map((e) => EmirateItem.fromJson(e as Map<String, dynamic>))
            .toList();
      }
    }
    throw Exception('Failed to load emirates list (${res.statusCode})');
  }

  /// Check if mobile number is already registered
  static Future<MobileDuplicateCheckResponse> checkMobileDuplicate(
    String mobileNumber,
  ) async {
    final formattedMobile = formatMobileNumber(mobileNumber);
    final uri = Uri.parse('$_baseUrl$_checkMobilePath?mobileNumber=$formattedMobile');
    
    try {
      final res = await http.get(uri, headers: _jsonHeaders);
      
      if (res.statusCode == 200) {
        final body = json.decode(res.body) as Map<String, dynamic>;
        return MobileDuplicateCheckResponse.fromJson(body);
      } else if (res.statusCode == 404) {
        // Mobile not found - this means it doesn't exist
        return MobileDuplicateCheckResponse(
          success: true,
          exists: false,
          message: 'Mobile number not found',
        );
      } else {
        return MobileDuplicateCheckResponse(
          success: false,
          exists: false,
          message: 'Failed to check mobile number (${res.statusCode})',
        );
      }
    } catch (e) {
      return MobileDuplicateCheckResponse(
        success: false,
        exists: false,
        message: 'Error checking mobile number: ${e.toString()}',
      );
    }
  }

  /// Register Painter
  static Future<PainterRegistrationResponse> registerPainter(
    PainterRegistrationRequest req,
  ) async {
    final uri = Uri.parse('$_baseUrl$_registerPath');
    final payload = json.encode(req.toJson());

    final res = await http.post(uri, headers: _jsonHeaders, body: payload);

    // Success
    if (res.statusCode == 200) {
      final body = json.decode(res.body) as Map<String, dynamic>;
      return PainterRegistrationResponse.fromJson(body);
    }

    // Error body from API
    try {
      final body = json.decode(res.body) as Map<String, dynamic>;
      return PainterRegistrationResponse(
        success: false,
        message: (body['message'] ?? 'Registration failed').toString(),
        influencerCode: body['influencerCode']?.toString(),
      );
    } catch (_) {
      // Generic fallback
      return PainterRegistrationResponse(
        success: false,
        message: 'Registration failed (${res.statusCode})',
      );
    }
  }

  /// Get Painter Details by Mobile Number
  static Future<PainterDetailsResponse> getPainterDetails(String mobileNumber) async {
    final formattedMobile = formatMobileNumber(mobileNumber);
    final uri = Uri.parse('$_baseUrl$_updatePath?mobileNumber=$formattedMobile');
    
    try {
      final res = await http.get(uri, headers: _jsonHeaders);
      
      if (res.statusCode == 200) {
        final body = json.decode(res.body) as Map<String, dynamic>;
        return PainterDetailsResponse.fromJson(body);
      } else if (res.statusCode == 404) {
        return PainterDetailsResponse(
          success: false,
          message: 'No painter found for this mobile number',
        );
      } else {
        return PainterDetailsResponse(
          success: false,
          message: 'Failed to get painter details (${res.statusCode})',
        );
      }
    } catch (e) {
      return PainterDetailsResponse(
        success: false,
        message: 'Error getting painter details: ${e.toString()}',
      );
    }
  }

  /// Update Painter Details
  static Future<PainterRegistrationResponse> updatePainter(
    PainterRegistrationRequest req,
  ) async {
    final formattedMobile = formatMobileNumber(req.mobileNumber);
    final uri = Uri.parse('$_baseUrl$_updatePath?mobileNumber=$formattedMobile');
    final payload = json.encode(req.toJson());

    final res = await http.post(uri, headers: _jsonHeaders, body: payload);

    // Success
    if (res.statusCode == 200) {
      final body = json.decode(res.body) as Map<String, dynamic>;
      return PainterRegistrationResponse.fromJson(body);
    }

    // Error body from API
    try {
      final body = json.decode(res.body) as Map<String, dynamic>;
      return PainterRegistrationResponse(
        success: false,
        message: (body['message'] ?? 'Update failed').toString(),
        influencerCode: body['influencerCode']?.toString(),
      );
    } catch (_) {
      // Generic fallback
      return PainterRegistrationResponse(
        success: false,
        message: 'Update failed (${res.statusCode})',
      );
    }
  }

  // ---------- Validation helpers for UI ----------

  static String? validateMobileNumber(String? value) {
    if (value == null || value.trim().isEmpty)
      return 'Mobile number is required';
    final v = value.replaceAll(RegExp(r'[^0-9]'), ''); // Remove non-digits

    // Check if it's exactly 9 digits (UAE mobile without country code)
    if (v.length != 9) {
      return 'Mobile number must be 9 digits';
    }

    // Check if it starts with valid UAE prefixes
    final validPrefixes = ['50', '52', '54', '55', '56', '58'];
    final prefix = v.substring(0, 2);

    if (!validPrefixes.contains(prefix)) {
      return 'Mobile number must start with 50, 52, 54, 55, 56, or 58';
    }

    return null;
  }

  static String? validateIban(String? value) {
    if (value == null || value.trim().isEmpty)
      return null; // Optional for painters
    final iban = value.replaceAll(' ', '').toUpperCase();

    // UAE IBAN format: AE followed by 21 digits
    if (!iban.startsWith('AE')) {
      return 'UAE IBAN must start with AE';
    }

    if (iban.length != 23) {
      return 'UAE IBAN must be 23 characters long';
    }

    // Check if remaining characters are digits
    final digits = iban.substring(2);
    if (!RegExp(r'^[0-9]{21}$').hasMatch(digits)) {
      return 'Invalid IBAN format';
    }

    return null;
  }

  static String? validateEmiratesId(String? value) {
    if (value == null || value.trim().isEmpty) return 'Emirates ID is required';

    final cleaned = value.replaceAll(RegExp(r'[^0-9]'), '');

    if (cleaned.length != 15) {
      return 'Emirates ID must be 15 digits';
    }

    return null;
  }

  static String formatMobileNumber(String? value) {
    if (value == null) return '';
    final cleaned = value.replaceAll(RegExp(r'[^0-9]'), '');
    // Return cleaned 9-digit number
    if (cleaned.length == 9) {
      return cleaned;
    }
    // If longer, take last 9 digits
    if (cleaned.length > 9) {
      return cleaned.substring(cleaned.length - 9);
    }
    return cleaned;
  }

  static String formatIban(String? value) {
    if (value == null) return '';
    return value.replaceAll(' ', '').toUpperCase();
  }

  static String? validateName(String? value, String fieldName) {
    if (value == null || value.trim().isEmpty) {
      return '$fieldName is required';
    }

    if (value.trim().length < 2) {
      return '$fieldName must be at least 2 characters';
    }

    // Allow letters, spaces, apostrophes, hyphens, and Arabic characters
    if (!RegExp(r"^[a-zA-Z\u0600-\u06FF\s'\-]+$").hasMatch(value.trim())) {
      return '$fieldName can only contain letters, spaces, apostrophes, and hyphens';
    }

    return null;
  }

  static String? validateNationality(String? value) {
    if (value == null || value.trim().isEmpty) return 'Nationality is required';
    return validateName(value, 'Nationality');
  }

  static String? validateOccupation(String? value) {
    if (value == null || value.trim().isEmpty) return 'Occupation is required';
    return null;
  }
}
