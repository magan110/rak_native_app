import 'dart:convert';
import 'dart:developer' as developer;
import 'dart:io';
import 'package:http/http.dart' as http;
import '../models/retailer_registration_models.dart';
import '../network/ssl_http_client.dart';
import 'package:rak_app/core/constants/app_constants.dart';

class AppLogger {
  static const String _tag = 'RetailerOnboarding';

  void debug(String message) {
    developer.log('DEBUG: $message', name: _tag);
  }

  void info(String message) {
    developer.log('INFO: $message', name: _tag);
  }

  void error(String message, [Object? error, StackTrace? stackTrace]) {
    developer.log(
      'ERROR: $message',
      name: _tag,
      error: error,
      stackTrace: stackTrace,
    );
  }
}

class SubAreaResult {
  final bool hasSubArea;
  final List<Map<String, String>> data;

  SubAreaResult({required this.hasSubArea, required this.data});
}

class RetailerOnboardingService {
  static final AppLogger _logger = AppLogger();
  static String get _baseUrl => AppConstants.baseUrl;
  static const Duration _timeout = Duration(seconds: 30);
  static http.Client? _httpClient;

  static Future<http.Client> _getClient() async {
    _httpClient ??= await SslHttpClient.getClient();
    return _httpClient!;
  }

  static Map<String, String> get _jsonHeaders => const {
    'Content-Type': 'application/json',
    'Accept': 'application/json',
  };

  // ---------------------------
  // MASTER DATA
  // ---------------------------

  static Future<List<Map<String, String>>> getEmiratesList() async {
    try {
      final uri = Uri.parse('$_baseUrl/api/Retailer/emirates');
      final client = await _getClient();
      final response = await client.get(uri).timeout(_timeout);

      _logger.debug('Emirates status: ${response.statusCode}');
      _logger.debug('Emirates body: ${response.body}');

      if (response.statusCode != 200) {
        return [];
      }

      final body = jsonDecode(response.body);

      if (body is! Map<String, dynamic>) {
        return [];
      }

      if (body['success'] != true || body['data'] is! List) {
        return [];
      }

      final List<dynamic> data = body['data'];

      return data
          .map<Map<String, String>>((e) {
            final map = Map<String, dynamic>.from(e as Map);
            return {
              "code": (map["Code"] ?? map["code"] ?? '').toString().trim(),
              "name": (map["Name"] ?? map["name"] ?? '').toString().trim(),
            };
          })
          .where((e) => e["code"]!.isNotEmpty && e["name"]!.isNotEmpty)
          .toList();
    } catch (e) {
      _logger.error('Emirates API error', e);
      return [];
    }
  }

  static Future<List<Map<String, String>>> getAreasList(
    String emirateCode,
  ) async {
    try {
      // Controller exposes areas by emirateCode (serves as 'districts' for UI)
      final uri = Uri.parse(
        '$_baseUrl/api/Retailer/areas?emirateCode=${Uri.encodeComponent(emirateCode)}',
      );
      final client = await _getClient();
      final response = await client.get(uri).timeout(_timeout);

      _logger.debug(
        'Areas(status) for emirate [$emirateCode]: ${response.statusCode}',
      );
      _logger.debug('Areas(body): ${response.body}');

      if (response.statusCode != 200) {
        return [];
      }

      final body = jsonDecode(response.body);

      if (body is! Map<String, dynamic>) {
        return [];
      }

      if (body['success'] != true || body['data'] is! List) {
        return [];
      }

      final List<dynamic> data = body['data'];

      return data
          .map<Map<String, String>>((e) {
            final map = Map<String, dynamic>.from(e as Map);
            return {
              "code": (map["Code"] ?? map["code"] ?? '').toString().trim(),
              "name": (map["Name"] ?? map["name"] ?? '').toString().trim(),
              "pobox": (map["PoBox"] ?? map["poBox"] ?? map["areaPinC"] ?? '')
                  .toString()
                  .trim(),
            };
          })
          .where((e) => e["name"]!.isNotEmpty)
          .toList();
    } catch (e) {
      _logger.error('Areas API error', e);
      return [];
    }
  }

  static Future<SubAreaResult> getSubAreasList(String areaCode) async {
    try {
      // Controller exposes subareas by areaCode
      final uri = Uri.parse(
        '$_baseUrl/api/Retailer/subareas?areaCode=${Uri.encodeComponent(areaCode)}',
      );
      final client = await _getClient();
      final response = await client.get(uri).timeout(_timeout);

      _logger.debug(
        'Subareas(status) for area [$areaCode]: ${response.statusCode}',
      );
      _logger.debug('Subareas(body): ${response.body}');

      if (response.statusCode != 200) {
        return SubAreaResult(hasSubArea: false, data: []);
      }

      final body = jsonDecode(response.body);

      if (body is! Map<String, dynamic>) {
        return SubAreaResult(hasSubArea: false, data: []);
      }

      final bool hasSub =
          (body['hasSubArea'] == true) ||
          ((body['data'] is List) && (body['data'] as List).isNotEmpty);

      if (body['data'] is! List) {
        return SubAreaResult(hasSubArea: hasSub, data: []);
      }

      final List<dynamic> data = body['data'];

      final parsed = data
          .map<Map<String, String>>((e) {
            final map = Map<String, dynamic>.from(e as Map);
            return {
              'code': (map['Code'] ?? map['code'] ?? '').toString().trim(),
              'name': (map['Name'] ?? map['name'] ?? '').toString().trim(),
              'pobox': (map['PoBox'] ?? map['poBox'] ?? map['areaPinC'] ?? '')
                  .toString()
                  .trim(),
            };
          })
          .where((e) => e['name']!.isNotEmpty)
          .toList();

      return SubAreaResult(hasSubArea: hasSub, data: parsed);
    } catch (e) {
      _logger.error('Subareas API error', e);
      return SubAreaResult(hasSubArea: false, data: []);
    }
  }

  static Future<bool> uploadDocument(
    String filePath,
    String attFilKy,
    String attFilTy,
  ) async {
    try {
      final uri = Uri.parse(
        '$_baseUrl/api/ImageUpload/upload?attFilKy=$attFilKy&attFilTy=$attFilTy',
      );
      final request = http.MultipartRequest('POST', uri);
      request.files.add(await http.MultipartFile.fromPath('file', filePath));

      final client = await _getClient();
      final response = await client.send(request).timeout(_timeout);

      return response.statusCode >= 200 && response.statusCode < 300;
    } catch (e) {
      _logger.error('Document Upload error', e);
      return false;
    }
  }

  // ---------------------------
  // API CALLS
  // ---------------------------

  static Future<RetailerOnboardingResponse> registerRetailer(
    RetailerOnboardingRequest request,
  ) async {
    try {
      final uri = Uri.parse('$_baseUrl/api/Retailer/register');
      final client = await _getClient();
      final requestBody = jsonEncode(request.toJson());

      final response = await client
          .post(uri, headers: _jsonHeaders, body: requestBody)
          .timeout(_timeout);

      Map<String, dynamic> responseData = {};
      if (response.body.isNotEmpty) {
        responseData = jsonDecode(response.body) as Map<String, dynamic>;
      }

      if (response.statusCode >= 200 && response.statusCode < 300) {
        return RetailerOnboardingResponse.fromJson(responseData);
      }

      return RetailerOnboardingResponse(
        success: false,
        message: responseData['message']?.toString() ?? 'Registration failed',
        error:
            responseData['error']?.toString() ??
            'HTTP ${response.statusCode}: ${response.reasonPhrase}',
        timestamp: DateTime.now(),
      );
    } on SocketException catch (e) {
      _logger.error('Socket error during register', e);
      return RetailerOnboardingResponse(
        success: false,
        message: 'Network connection failed',
        error: 'Unable to reach server.',
        timestamp: DateTime.now(),
      );
    } on FormatException catch (e) {
      _logger.error('JSON parse error during register', e);
      return RetailerOnboardingResponse(
        success: false,
        message: 'Invalid server response',
        error: e.toString(),
        timestamp: DateTime.now(),
      );
    } catch (e) {
      _logger.error('Retailer registration failed', e);
      return RetailerOnboardingResponse(
        success: false,
        message: 'Registration failed',
        error: e.toString(),
        timestamp: DateTime.now(),
      );
    }
  }

  static Future<RetailerOnboardingResponse> updateRetailer(
    String retailerCode,
    RetailerOnboardingRequest request,
  ) async {
    try {
      final uri = Uri.parse(
        '$_baseUrl/api/Retailer/update?retailerCode=${Uri.encodeComponent(retailerCode)}',
      );
      final client = await _getClient();
      final requestBody = jsonEncode(request.toJson());

      final response = await client
          .post(uri, headers: _jsonHeaders, body: requestBody)
          .timeout(_timeout);

      Map<String, dynamic> responseData = {};
      if (response.body.isNotEmpty) {
        responseData = jsonDecode(response.body) as Map<String, dynamic>;
      }

      if (response.statusCode >= 200 && response.statusCode < 300) {
        return RetailerOnboardingResponse.fromJson(responseData);
      }

      return RetailerOnboardingResponse(
        success: false,
        message: responseData['message']?.toString() ?? 'Update failed',
        error:
            responseData['error']?.toString() ??
            'HTTP ${response.statusCode}: ${response.reasonPhrase}',
        timestamp: DateTime.now(),
      );
    } catch (e) {
      _logger.error('Retailer update failed', e);
      return RetailerOnboardingResponse(
        success: false,
        message: 'Update failed',
        error: e.toString(),
        timestamp: DateTime.now(),
      );
    }
  }

  static Future<RetailerOnboardingRequest?> getRetailerDetails(
    String retailerCode,
  ) async {
    try {
      final uri = Uri.parse(
        '$_baseUrl/api/Retailer/update?retailerCode=${Uri.encodeComponent(retailerCode)}',
      );
      final client = await _getClient();
      final response = await client.get(uri).timeout(_timeout);

      if (response.statusCode >= 200 && response.statusCode < 300) {
        final body = jsonDecode(response.body) as Map<String, dynamic>;
        if (body['success'] == true && body['data'] is Map<String, dynamic>) {
          return RetailerOnboardingRequest.fromJson(
            body['data'] as Map<String, dynamic>,
          );
        }
      }
      return null;
    } catch (e) {
      _logger.error('Failed to fetch retailer details', e);
      return null;
    }
  }

  static Future<Map<String, dynamic>> testConnection() async {
    try {
      final uri = Uri.parse('$_baseUrl/api/Retailer/emirates');
      final client = await _getClient();
      final response = await client
          .get(uri, headers: {'Accept': 'application/json'})
          .timeout(const Duration(seconds: 10));

      return {
        'success': response.statusCode == 200,
        'statusCode': response.statusCode,
        'message': response.statusCode == 200
            ? 'Connection successful'
            : 'Connection failed',
      };
    } catch (e) {
      _logger.error('Connection test failed', e);
      return {'success': false, 'error': 'Connection failed: $e'};
    }
  }

  // ---------------------------
  // VALIDATION / FORMATTING
  // ---------------------------

  static String normalizeMobileNumber(String mobile) {
    String digits = mobile.replaceAll(RegExp(r'\D'), '');

    if (digits.startsWith('00971')) {
      digits = digits.substring(2);
    }

    if (digits.startsWith('971') && digits.length == 12) {
      return digits;
    }

    if (digits.startsWith('05') && digits.length == 10) {
      return '971${digits.substring(1)}';
    }

    if (digits.startsWith('5') && digits.length == 9) {
      return '971$digits';
    }

    return digits;
  }

  static String? validateMobileNumber(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Please enter Mobile Number';
    }

    final normalized = normalizeMobileNumber(value);
    if (normalized.length != 12) {
      return 'Mobile number must be 9 digits after 971';
    }

    if (!normalized.startsWith('9715')) {
      return 'Mobile number must start with 5 after 971';
    }

    return null;
  }

  static String? validateIban(String? value) {
    if (value == null || value.trim().isEmpty) return null;

    final cleaned = value.replaceAll(' ', '').toUpperCase();
    if (!cleaned.startsWith('AE')) {
      return 'IBAN should start with AE';
    }
    if (cleaned.length != 23) {
      return 'UAE IBAN should be 23 characters';
    }
    return null;
  }

  static String? validateTaxRegistrationNumber(String? value) {
    if (value == null || value.trim().isEmpty) return null;
    final cleaned = value.replaceAll(RegExp(r'[^\d]'), '');
    if (cleaned.length != 15) {
      return 'TRN should be 15 digits';
    }
    return null;
  }

  static String? validateEmiratesId(String? value) {
    if (value == null || value.trim().isEmpty) return null;
    final cleaned = formatEmiratesId(value);
    if (cleaned.length != 15) {
      return 'Emirates ID must be 15 digits';
    }
    return null;
  }

  static String? validateTextField(
    String? value,
    String fieldName, {
    int maxLength = 255,
    bool isRequired = true,
  }) {
    if (isRequired && (value == null || value.trim().isEmpty)) {
      return 'Please enter $fieldName';
    }
    if (value != null && value.trim().length > maxLength) {
      return '$fieldName must be less than $maxLength characters';
    }
    return null;
  }

  static String? validateFirmName(String? value) {
    return validateTextField(
      value,
      'Firm Name',
      maxLength: 90,
      isRequired: true,
    );
  }

  static String? validateTradeLicence(String? value) {
    if (value == null || value.trim().isEmpty) return null;
    if (value.trim().length > 50) {
      return 'Trade Licence must be less than 50 characters';
    }
    return null;
  }

  static String? validateEmail(String? value) {
    if (value == null || value.trim().isEmpty) return null;
    final email = value.trim();
    final regex = RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$');
    if (!regex.hasMatch(email)) {
      return 'Please enter a valid email';
    }
    if (email.length > 40) {
      return 'Email must be less than 40 characters';
    }
    return null;
  }

  static String? validateAccountHolderName(String? value) {
    return validateTextField(
      value,
      'Account Holder Name',
      maxLength: 90,
      isRequired: false,
    );
  }

  static String? validateBankName(String? value) {
    return validateTextField(
      value,
      'Bank Name',
      maxLength: 60,
      isRequired: false,
    );
  }

  static String? validateAccountNumber(String? value) {
    return validateTextField(
      value,
      'Account Number',
      maxLength: 20,
      isRequired: false,
    );
  }

  static String? validateAddress(String? value) {
    return validateTextField(
      value,
      'Full Address',
      maxLength: 100,
      isRequired: true,
    );
  }

  static String formatIban(String iban) {
    return iban.replaceAll(' ', '').toUpperCase();
  }

  static String formatTaxRegistrationNumber(String trn) {
    return trn.replaceAll(RegExp(r'[^\d]'), '');
  }

  static String formatEmiratesId(String emiratesId) {
    return emiratesId.replaceAll(RegExp(r'[^\d]'), '');
  }
}
