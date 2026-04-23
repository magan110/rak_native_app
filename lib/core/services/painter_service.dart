import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:rak_app/core/constants/app_constants.dart';

import '../models/painter_models.dart';
import '../network/ssl_http_client.dart';

class PainterService {
  static String get _baseUrl => AppConstants.baseUrl;

  static const _registerPath = '/api/Painter/register';
  static const _emiratesPath = '/api/Painter/emirates';
  static const _areasPath = '/api/Painter/areas';
  static const _subAreasPath = '/api/Painter/subareas';
  static const _checkMobilePath = '/api/Painter/check-mobile';

  static const _updatePath = '/api/Painter/update';
  static http.Client? _httpClient;

  static Map<String, String> get _jsonHeaders => const {
    'Content-Type': 'application/json',
    'Accept': 'application/json',
  };

  /// Get SSL-enabled HTTP client
  static Future<http.Client> _getClient() async {
    _httpClient ??= await SslHttpClient.getClient();
    return _httpClient!;
  }

  // Get Emirates List for dropdown
  static Future<List<EmirateItem>> getEmiratesList() async {
    final uri = Uri.parse('$_baseUrl$_emiratesPath');
    final client = await _getClient();
    final res = await client.get(uri, headers: _jsonHeaders);
    if (res.statusCode == 200) {
      final body = json.decode(res.body) as Map<String, dynamic>;
      final data = body['data'];
      if (data is List) {
        return data
            .map((e) => EmirateItem.fromJson(e as Map<String, dynamic>))
            .toList();
      }
    }
    throw Exception('Failed to load emirates list (${res.statusCode})');
  }

  /// Get areas for a given emirate code
  static Future<List<AreaItem>> getAreasListByEmirate(
    String emirateCode,
  ) async {
    final uri = Uri.parse(
      '$_baseUrl$_areasPath?emirateCode=${Uri.encodeQueryComponent(emirateCode)}',
    );
    final client = await _getClient();
    final res = await client.get(uri, headers: _jsonHeaders);
    if (res.statusCode == 200) {
      final body = json.decode(res.body) as Map<String, dynamic>;
      final data = body['data'];
      if (data is List) {
        return data
            .map((e) => AreaItem.fromJson(e as Map<String, dynamic>))
            .toList();
      }
      return [];
    }
    throw Exception('Failed to load areas (${res.statusCode})');
  }

  /// Get sub-areas for an area code. Response includes hasSubArea flag and data list.
  static Future<Map<String, dynamic>> getSubAreasListByArea(
    String areaCode,
  ) async {
    final uri = Uri.parse(
      '$_baseUrl$_subAreasPath?areaCode=${Uri.encodeQueryComponent(areaCode)}',
    );
    final client = await _getClient();
    final res = await client.get(uri, headers: _jsonHeaders);
    if (res.statusCode == 200) {
      final body = json.decode(res.body) as Map<String, dynamic>;
      final hasSub = body['hasSubArea'] == true;
      final data = <SubAreaItem>[];
      if (body['data'] is List) {
        for (final e in body['data']) {
          data.add(SubAreaItem.fromJson(e as Map<String, dynamic>));
        }
      }
      return {'hasSubArea': hasSub, 'data': data};
    }
    throw Exception('Failed to load subareas (${res.statusCode})');
  }

  /// Check if mobile number is already registered
  static Future<MobileDuplicateCheckResponse> checkMobileDuplicate(
    String mobileNumber,
  ) async {
    final formattedMobile = formatMobileNumber(mobileNumber);
    final uri = Uri.parse(
      '$_baseUrl$_checkMobilePath?mobileNumber=$formattedMobile',
    );

    try {
      final client = await _getClient();
      final res = await client.get(uri, headers: _jsonHeaders);

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
    final requestData = req.toJson();
    final payload = json.encode(requestData);

    final client = await _getClient();
    final res = await client.post(uri, headers: _jsonHeaders, body: payload);

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

  // Get Painter Details by influencer code (inflCode)
  static Future<PainterDetailsResponse> getPainterDetailsByCode(
    String inflCode,
  ) async {
    final uri = Uri.parse(
      '$_baseUrl$_updatePath?inflCode=${Uri.encodeQueryComponent(inflCode)}',
    );

    try {
      final client = await _getClient();
      final res = await client.get(uri, headers: _jsonHeaders);

      if (res.statusCode == 200) {
        final body = json.decode(res.body) as Map<String, dynamic>;
        return PainterDetailsResponse.fromJson(body);
      } else if (res.statusCode == 404) {
        return PainterDetailsResponse(
          success: false,
          message: 'Painter not found',
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
    String inflCode,
    PainterRegistrationRequest req,
  ) async {
    final uri = Uri.parse(
      '$_baseUrl$_updatePath?inflCode=${Uri.encodeQueryComponent(inflCode)}',
    );
    final payload = json.encode(req.toJson());

    final client = await _getClient();
    final res = await client.post(uri, headers: _jsonHeaders, body: payload);

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

    String formattedNumber;

    // If it's 9 digits (UAE mobile without country code), add 971
    if (cleaned.length == 9 && !cleaned.startsWith('971')) {
      formattedNumber = '971$cleaned';
    }
    // If it starts with 05, replace with 971
    else if (cleaned.startsWith('05') && cleaned.length == 9) {
      formattedNumber = '971${cleaned.substring(1)}';
    }
    // If it already starts with 971, use as is
    else if (cleaned.startsWith('971')) {
      formattedNumber = cleaned;
    }
    // If it's longer than 9 digits but doesn't start with 971, take last 9 and add 971
    else if (cleaned.length > 9 && !cleaned.startsWith('971')) {
      final last9 = cleaned.substring(cleaned.length - 9);
      formattedNumber = '971$last9';
    } else {
      formattedNumber = cleaned;
    }

    // Database column is now varchar(12), so we can store 12 digits: 971XXXXXXXXX
    // Backend should be updated to FormatMobile12() to take last 12 digits
    // For now, if backend still uses FormatMobile11 (takes last 11), we need workaround
    // If backend uses FormatMobile12 (takes last 12), we can send 971XXXXXXXXX directly
    // Since column is varchar(12), we assume backend will be updated to FormatMobile12
    // Return 12-digit format: 971XXXXXXXXX
    if (formattedNumber.startsWith('971') && formattedNumber.length == 12) {
      return formattedNumber; // 971501234567 (12 digits) - backend should use FormatMobile12
    }

    return formattedNumber;
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
