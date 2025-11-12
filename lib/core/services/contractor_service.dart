import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:rak_app/core/constants/app_constants.dart';
import '../models/contractor_models.dart';

class ContractorService {
  static String get _baseUrl => AppConstants.baseUrl;
  static const _registerPath = '/api/Contractor/register';
  static const _typesPath = '/api/Contractor/contractor-types';
  static const _emiratesPath = '/api/Contractor/emirates-list';
  static const _licenseTypesPath = '/api/Contractor/license-types';
  static const _issuingAuthoritiesPath = '/api/Contractor/issuing-authorities';
  static const _contractorDetailsPath = '/api/Contractor';
  static const _checkMobilePath = '/api/Contractor/check-mobile';
  static const _getDetailsPath = '/api/Contractor/details';
  static const _updatePath = '/api/Contractor/update';

  static Map<String, String> get _jsonHeaders => {
    'Content-Type': 'application/json',
    'Accept': 'application/json',
  };

  // Dropdowns
  static Future<List<String>> getContractorTypes() async {
    final uri = Uri.parse('$_baseUrl$_typesPath');
    final res = await http.get(uri, headers: _jsonHeaders);
    if (res.statusCode == 200) {
      final body = json.decode(res.body);
      final list =
          (body['data'] as List?)?.map((e) => e.toString()).toList() ??
          const [];
      return list;
    }
    throw Exception('Failed to load contractor types (${res.statusCode})');
  }

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

  static Future<List<String>> getLicenseTypes() async {
    final uri = Uri.parse('$_baseUrl$_licenseTypesPath');
    final res = await http.get(uri, headers: _jsonHeaders);
    if (res.statusCode == 200) {
      final body = json.decode(res.body);
      final list =
          (body['data'] as List?)?.map((e) => e.toString()).toList() ??
          const [];
      return list;
    }
    throw Exception('Failed to load license types (${res.statusCode})');
  }

  static Future<List<String>> getIssuingAuthorities() async {
    final uri = Uri.parse('$_baseUrl$_issuingAuthoritiesPath');
    final res = await http.get(uri, headers: _jsonHeaders);
    if (res.statusCode == 200) {
      final body = json.decode(res.body);
      final list =
          (body['data'] as List?)?.map((e) => e.toString()).toList() ??
          const [];
      return list;
    }
    throw Exception('Failed to load issuing authorities (${res.statusCode})');
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

  // Register
  static Future<ContractorRegistrationResponse> registerContractor(
    ContractorRegistrationRequest req,
  ) async {
    final uri = Uri.parse('$_baseUrl$_registerPath');
    final payload = json.encode(req.toJson());

    final res = await http.post(uri, headers: _jsonHeaders, body: payload);

    if (res.statusCode == 200) {
      final jsonBody = json.decode(res.body) as Map<String, dynamic>;
      return ContractorRegistrationResponse.fromJson(jsonBody);
    } else {
      try {
        final jsonBody = json.decode(res.body) as Map<String, dynamic>;
        return ContractorRegistrationResponse(
          success: false,
          message: (jsonBody['message'] ?? 'Registration failed').toString(),
          contractorId: jsonBody['contractorId']?.toString(),
          influencerCode: jsonBody['influencerCode']?.toString(),
        );
      } catch (_) {
        return ContractorRegistrationResponse(
          success: false,
          message: 'Registration failed (${res.statusCode})',
        );
      }
    }
  }

  // Get contractor details by ID
  static Future<Map<String, dynamic>?> getContractorDetails(
    String contractorId,
  ) async {
    final uri = Uri.parse('$_baseUrl$_contractorDetailsPath/$contractorId');
    final res = await http.get(uri, headers: _jsonHeaders);

    if (res.statusCode == 200) {
      final body = json.decode(res.body);
      if (body['success'] == true) {
        return body['data'] as Map<String, dynamic>?;
      }
    } else if (res.statusCode == 404) {
      return null; // Contractor not found
    }

    throw Exception('Failed to load contractor details (${res.statusCode})');
  }

  /// Get Contractor Details by Mobile Number
  static Future<ContractorDetailsResponse> getContractorDetailsByMobile(String mobileNumber) async {
    final formattedMobile = formatMobileNumber(mobileNumber);
    final uri = Uri.parse('$_baseUrl$_getDetailsPath?mobileNumber=$formattedMobile');
    
    try {
      final res = await http.get(uri, headers: _jsonHeaders);
      
      if (res.statusCode == 200) {
        final body = json.decode(res.body) as Map<String, dynamic>;
        return ContractorDetailsResponse.fromJson(body);
      } else {
        return ContractorDetailsResponse(
          success: false,
          message: 'Failed to get contractor details (${res.statusCode})',
        );
      }
    } catch (e) {
      return ContractorDetailsResponse(
        success: false,
        message: 'Error getting contractor details: ${e.toString()}',
      );
    }
  }

  /// Update Contractor Details
  static Future<ContractorRegistrationResponse> updateContractor(
    ContractorRegistrationRequest req,
  ) async {
    final uri = Uri.parse('$_baseUrl$_updatePath');
    final payload = json.encode(req.toJson());

    final res = await http.put(uri, headers: _jsonHeaders, body: payload);

    if (res.statusCode == 200) {
      final jsonBody = json.decode(res.body) as Map<String, dynamic>;
      return ContractorRegistrationResponse.fromJson(jsonBody);
    } else {
      try {
        final jsonBody = json.decode(res.body) as Map<String, dynamic>;
        return ContractorRegistrationResponse(
          success: false,
          message: (jsonBody['message'] ?? 'Update failed').toString(),
          contractorId: jsonBody['contractorId']?.toString(),
          influencerCode: jsonBody['influencerCode']?.toString(),
        );
      } catch (_) {
        return ContractorRegistrationResponse(
          success: false,
          message: 'Update failed (${res.statusCode})',
        );
      }
    }
  }

  // Utilities you referenced in validators
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
    if (value == null || value.trim().isEmpty) return 'IBAN is required';
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

  static String? formatMobileNumber(String? value) {
    if (value == null) return '';
    final cleaned = value.replaceAll(RegExp(r'[^0-9]'), '');
    // Add +971 country code if not present
    if (cleaned.length == 9 && !cleaned.startsWith('971')) {
      return '+971$cleaned';
    }
    return cleaned;
  }

  static String? formatIban(String? value) {
    if (value == null) return '';
    return value.replaceAll(' ', '').toUpperCase();
  }

  // New validation methods for contractor requirements
  static String? validateTaxRegistrationNumber(String? value) {
    if (value == null || value.trim().isEmpty) return null; // Not mandatory

    final trn = value.replaceAll(
      RegExp(r'[^0-9-]'),
      '',
    ); // Keep only digits and hyphens

    // Format: XXX-XXXXXXXXX-XXX (15 total digits, 3-9-3 pattern)
    if (!RegExp(r'^[0-9]{3}-[0-9]{9}-[0-9]{3}$').hasMatch(trn)) {
      return 'Tax Registration Number must be in format XXX-XXXXXXXXX-XXX';
    }

    return null;
  }

  static String formatTaxRegistrationNumber(String? value) {
    if (value == null) return '';
    final digits = value.replaceAll(RegExp(r'[^0-9]'), '');

    if (digits.length == 15) {
      return '${digits.substring(0, 3)}-${digits.substring(3, 12)}-${digits.substring(12, 15)}';
    }

    return value;
  }

  static String? validateName(String? value, String fieldName) {
    if (value == null || value.trim().isEmpty) {
      return '$fieldName is required (as per Emirates ID)';
    }

    if (value.trim().length < 2) {
      return '$fieldName must be at least 2 characters';
    }

    // Only allow letters, spaces, apostrophes, and hyphens
    if (!RegExp(r"^[a-zA-Z\s'\-]+$").hasMatch(value.trim())) {
      return '$fieldName can only contain letters, spaces, apostrophes, and hyphens';
    }

    return null;
  }
}
