import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:rak_app/core/constants/app_constants.dart';
import '../models/contractor_models.dart';
import '../network/ssl_http_client.dart';

class ContractorService {
  static String get _baseUrl => AppConstants.baseUrl;
  static const _registerPath = '/api/Contractor/register';
  static const _typesPath = '/api/Contractor/contractor-types';
  static const _emiratesPath = '/api/Contractor/emirates';
  static const _areasPath = '/api/Contractor/areas';
  static const _subAreasPath = '/api/Contractor/subareas';
  static const _licenseTypesPath = '/api/Contractor/license-types';
  static const _issuingAuthoritiesPath = '/api/Contractor/issuing-authorities';
  static const _contractorDetailsPath = '/api/Contractor';
  static const _checkMobilePath = '/api/Contractor/check-mobile';
  static const _getDetailsPath = '/api/Contractor/update';
  static const _updatePath = '/api/Contractor/update';
  static http.Client? _httpClient;

  static Map<String, String> get _jsonHeaders => {
    'Content-Type': 'application/json',
    'Accept': 'application/json',
  };

  /// Get SSL-enabled HTTP client
  static Future<http.Client> _getClient() async {
    _httpClient ??= await SslHttpClient.getClient();
    return _httpClient!;
  }

  // Dropdowns
  static Future<List<String>> getContractorTypes() async {
    final uri = Uri.parse('$_baseUrl$_typesPath');
    final client = await _getClient();
    final res = await client.get(uri, headers: _jsonHeaders);
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
    final client = await _getClient();
    final res = await client.get(uri, headers: _jsonHeaders);
    if (res.statusCode == 200) {
      final body = json.decode(res.body);
      final list = (body is List)
          ? body
          : (body is Map && body['data'] is List)
          ? body['data']
          : [];

      return (list as List)
          .map((e) => EmirateItem.fromJson(e as Map<String, dynamic>))
          .toList();
    }
    throw Exception('Failed to load emirates list (${res.statusCode})');
  }

  static Future<List<AreaItem>> getAreasListByEmirate(
    String emirateCode,
  ) async {
    final uri = Uri.parse(
      '$_baseUrl$_areasPath?emirateCode=${Uri.encodeComponent(emirateCode)}',
    );
    final client = await _getClient();
    final res = await client.get(uri, headers: _jsonHeaders);
    if (res.statusCode == 200) {
      final body = json.decode(res.body);
      final list = (body is List)
          ? body
          : (body is Map && body['data'] is List)
          ? body['data']
          : [];

      return (list as List)
          .map((e) => AreaItem.fromJson(e as Map<String, dynamic>))
          .toList();
    }
    throw Exception('Failed to load areas list (${res.statusCode})');
  }

  /// Get sub-areas for an area code. Returns a map with `hasSubArea` and `data`.
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
    throw Exception('Failed to load subareas list (${res.statusCode})');
  }

  static Future<List<String>> getLicenseTypes() async {
    final uri = Uri.parse('$_baseUrl$_licenseTypesPath');
    final client = await _getClient();
    final res = await client.get(uri, headers: _jsonHeaders);
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
    final client = await _getClient();
    final res = await client.get(uri, headers: _jsonHeaders);
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

  // Register
  static Future<ContractorRegistrationResponse> registerContractor(
    ContractorRegistrationRequest req,
  ) async {
    final uri = Uri.parse('$_baseUrl$_registerPath');
    final requestData = req.toJson();

    // Debug: Print a short summary of the request
    print('=== Contractor Registration Request ===');
    print('MobileNumber: ${requestData['MobileNumber']}');
    print('FirstName: ${requestData['FirstName']}');
    print('EmirateCode: ${requestData['EmirateCode']}');
    print('AreaCode: ${requestData['AreaCode']}');
    print('SubAreaCode: ${requestData['SubAreaCode']}');
    print('PoBox: ${requestData['PoBox']}');
    print('Full Request: ${json.encode(requestData)}');
    print('=======================================');

    final payload = json.encode(requestData);

    final client = await _getClient();
    final res = await client.post(uri, headers: _jsonHeaders, body: payload);

    // Debug response for troubleshooting
    print('=== Contractor register response ===');
    print('Status: ${res.statusCode}');
    print('Body: ${res.body}');
    print('===================================');

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
    final client = await _getClient();
    final res = await client.get(uri, headers: _jsonHeaders);

    if (res.statusCode == 200) {
      final body = json.decode(res.body);
      if (body is Map && body['success'] == true) {
        return body['data'] as Map<String, dynamic>?;
      }
    } else if (res.statusCode == 404) {
      return null; // Contractor not found
    }

    throw Exception('Failed to load contractor details (${res.statusCode})');
  }

  /// Get Contractor Details by Mobile Number
  static Future<ContractorDetailsResponse> getContractorDetailsByMobile(
    String mobileNumber,
  ) async {
    final formattedMobile = formatMobileNumber(mobileNumber);
    final uri = Uri.parse(
      '$_baseUrl$_getDetailsPath?mobileNumber=$formattedMobile',
    );

    try {
      final client = await _getClient();
      final res = await client.get(uri, headers: _jsonHeaders);

      if (res.statusCode == 200) {
        final body = json.decode(res.body) as Map<String, dynamic>;
        return ContractorDetailsResponse.fromJson(body);
      } else if (res.statusCode == 404) {
        return ContractorDetailsResponse(success: false, message: 'Not found');
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

  /// Update contractor by mobileNumber query param (backend expects mobileNumber)
  static Future<ContractorRegistrationResponse> updateContractorByMobile(
    String mobileNumber,
    ContractorRegistrationRequest req,
  ) async {
    final formattedMobile = formatMobileNumber(mobileNumber);
    final uri = Uri.parse(
      '$_baseUrl$_updatePath?mobileNumber=$formattedMobile',
    );
    final payload = json.encode(req.toJson());

    final client = await _getClient();
    final res = await client.post(uri, headers: _jsonHeaders, body: payload);

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
    // Return 12-digit format: 971XXXXXXXXX
    if (formattedNumber.startsWith('971') && formattedNumber.length == 12) {
      return formattedNumber; // 971501234567 (12 digits) - backend should use FormatMobile12
    }

    return formattedNumber;
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
