import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/approval_models.dart';
import '../network/ssl_http_client.dart';
import 'image_upload_service.dart';

class ApprovalService {
  static const String baseUrl = 'https://qa.birlawhite.com:55232';
  static http.Client? _httpClient;

  /// Get SSL-enabled HTTP client
  static Future<http.Client> _getClient() async {
    _httpClient ??= await SslHttpClient.getClient();
    return _httpClient!;
  }

  Future<ApprovalResponse> getPendingApprovals({
    String? search,
    String? type,
    int page = 1,
    int pageSize = 1000,
    String? sort,
  }) async {
    try {
      final queryParams = <String, String>{'page': page.toString(), 'pageSize': pageSize.toString()};

      if (search != null && search.isNotEmpty) {
        queryParams['search'] = search;
      }
      if (type != null && type.isNotEmpty) {
        queryParams['type'] = type;
      }
      if (sort != null && sort.isNotEmpty) {
        queryParams['sort'] = sort;
      }

      final uri = Uri.parse('$baseUrl/api/Approval/pending').replace(queryParameters: queryParams);

      final client = await _getClient();
      final response = await client
          .get(uri, headers: {'Content-Type': 'application/json', 'Accept': 'application/json'})
          .timeout(const Duration(seconds: 30));

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        return ApprovalResponse.fromJson(data);
      } else {
        throw Exception('Failed to load pending approvals: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Error fetching pending approvals: $e');
    }
  }

  Future<ApprovalStats> getApprovalStats() async {
    try {
      final uri = Uri.parse('$baseUrl/api/Approval/stats');

      final client = await _getClient();
      final response = await client
          .get(uri, headers: {'Content-Type': 'application/json', 'Accept': 'application/json'})
          .timeout(const Duration(seconds: 30));

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        return ApprovalStats.fromJson(data);
      } else {
        throw Exception('Failed to load approval stats: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Error fetching approval stats: $e');
    }
  }

  Future<ApprovalActionResponse> approveItem(String inflCode, {String? loginId}) async {
    try {
      final request = ApprovalActionRequest(inflCode: inflCode, loginId: loginId);

      final uri = Uri.parse('$baseUrl/api/Approval/approve');

      final client = await _getClient();
      final response = await client
          .post(
            uri,
            headers: {'Content-Type': 'application/json', 'Accept': 'application/json'},
            body: json.encode(request.toJson()),
          )
          .timeout(const Duration(seconds: 30));

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        return ApprovalActionResponse.fromJson(data);
      } else {
        throw Exception('Failed to approve item: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Error approving item: $e');
    }
  }

  Future<ApprovalActionResponse> approveEmiratesId(String inflCode, {String? loginId}) async {
    try {
      final request = ApprovalActionRequest(inflCode: inflCode, loginId: loginId);

      final uri = Uri.parse('$baseUrl/api/Approval/approve/eid');

      final client = await _getClient();
      final response = await client
          .post(
            uri,
            headers: {'Content-Type': 'application/json', 'Accept': 'application/json'},
            body: json.encode(request.toJson()),
          )
          .timeout(const Duration(seconds: 30));

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        return ApprovalActionResponse.fromJson(data);
      } else {
        throw Exception('Failed to approve Emirates ID: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Error approving Emirates ID: $e');
    }
  }

  Future<ApprovalActionResponse> approveFinal(String inflCode, {String? loginId}) async {
    try {
      final request = ApprovalActionRequest(inflCode: inflCode, loginId: loginId);

      final uri = Uri.parse('$baseUrl/api/Approval/approve/final');

      final client = await _getClient();
      final response = await client
          .post(
            uri,
            headers: {'Content-Type': 'application/json', 'Accept': 'application/json'},
            body: json.encode(request.toJson()),
          )
          .timeout(const Duration(seconds: 30));

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        return ApprovalActionResponse.fromJson(data);
      } else {
        throw Exception('Failed to approve final: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Error approving final: $e');
    }
  }

  Future<ApprovalActionResponse> rejectItem(String inflCode, {String? reason, String? loginId}) async {
    try {
      final request = RejectionActionRequest(inflCode: inflCode, reason: reason, loginId: loginId);

      final uri = Uri.parse('$baseUrl/api/Approval/reject');

      final client = await _getClient();
      final response = await client
          .post(
            uri,
            headers: {'Content-Type': 'application/json', 'Accept': 'application/json'},
            body: json.encode(request.toJson()),
          )
          .timeout(const Duration(seconds: 30));

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        return ApprovalActionResponse.fromJson(data);
      } else {
        throw Exception('Failed to reject item: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Error rejecting item: $e');
    }
  }

  Future<String> lookupInflCode(String identifier) async {
    try {
      final uri = Uri.parse('$baseUrl/api/Approval/lookup/$identifier');
      print('DEBUG API: Looking up inflCode for identifier: $identifier');
      print('DEBUG API: Lookup URL: $uri');

      final client = await _getClient();
      final response = await client
          .get(uri, headers: {'Content-Type': 'application/json', 'Accept': 'application/json'})
          .timeout(const Duration(seconds: 30));

      print('DEBUG API: Lookup response status: ${response.statusCode}');
      print('DEBUG API: Lookup response body: ${response.body}');

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final inflCode = data['inflCode'] ?? '';
        print('DEBUG API: Found inflCode: $inflCode');
        return inflCode;
      } else if (response.statusCode == 404) {
        throw Exception('Person not found for identifier: $identifier');
      } else {
        throw Exception('Failed to lookup inflCode: ${response.statusCode} - ${response.body}');
      }
    } catch (e) {
      print('DEBUG API: Lookup exception: $e');
      throw Exception('Error looking up inflCode: $e');
    }
  }

  Future<RegistrationDetails> getRegistrationDetails(String inflCode) async {
    try {
      final uri = Uri.parse('$baseUrl/api/Approval/details/$inflCode');
      print('DEBUG API: Requesting URL: $uri');

      final client = await _getClient();
      final response = await client
          .get(uri, headers: {'Content-Type': 'application/json', 'Accept': 'application/json'})
          .timeout(const Duration(seconds: 30));

      print('DEBUG API: Response status: ${response.statusCode}');
      print('DEBUG API: Response body: ${response.body}');

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        print('DEBUG API: Parsed data: $data');
        return RegistrationDetails.fromJson(data);
      } else if (response.statusCode == 404) {
        throw Exception('Registration details not found for inflCode: $inflCode');
      } else {
        throw Exception('Failed to load registration details: ${response.statusCode} - ${response.body}');
      }
    } catch (e) {
      print('DEBUG API: Exception occurred: $e');
      throw Exception('Error fetching registration details: $e');
    }
  }

  Future<RegistrationDetails> getRegistrationDetailsByIdentifier(String identifier) async {
    try {
      print('DEBUG: Getting details for identifier: $identifier');

      // First lookup the inflCode
      final inflCode = await lookupInflCode(identifier);

      // Then get the full details
      final details = await getRegistrationDetails(inflCode);

      // Enrich with image URLs
      return _enrichWithImageUrls(details);
    } catch (e) {
      print('DEBUG: Error in getRegistrationDetailsByIdentifier: $e');
      rethrow;
    }
  }

  /// Enrich registration details with image URLs based on person's name and mobile
  RegistrationDetails _enrichWithImageUrls(RegistrationDetails details) {
    try {
      // Extract first and last name from fullName
      // Handle different name formats: "First Last", "First Middle Last", "First"
      final nameParts = details.fullName.trim().split(RegExp(r'\s+'));
      final firstName = nameParts.isNotEmpty ? nameParts.first : '';
      final lastName = nameParts.length > 1 ? nameParts.last : '';

      // Normalize mobile number - remove country code if present
      var mobile = details.mobile.replaceAll(RegExp(r'[^0-9]'), '');
      // Remove 971 prefix if present (UAE country code)
      if (mobile.startsWith('971') && mobile.length > 9) {
        mobile = mobile.substring(3); // Remove first 3 digits (971)
      }

      print('DEBUG: Enriching images for ${details.fullName}');
      print('DEBUG: Extracted - First: "$firstName", Last: "$lastName", Mobile: "$mobile" (normalized)');
      print('DEBUG: Original mobile from DB: ${details.mobile}');

      if (firstName.isEmpty || mobile.isEmpty) {
        print('DEBUG: Cannot generate image URLs - missing name or mobile');
        print('DEBUG: firstName isEmpty: ${firstName.isEmpty}, mobile isEmpty: ${mobile.isEmpty}');
        return details;
      }

      // Determine document types based on user type
      final documentTypes = details.type.toLowerCase().contains('contractor')
          ? DocumentType.getContractorDocumentTypes()
          : DocumentType.getPainterDocumentTypes();

      print('DEBUG: User type: ${details.type}, Document types: ${documentTypes.length}');

      // Generate image URLs
      final imageUrls = ImageUploadService.getPersonImageUrls(
        firstName: firstName,
        lastName: lastName,
        mobile: mobile,
        documentTypes: documentTypes,
      );

      print('DEBUG: Generated ${imageUrls.length} image URLs for ${details.fullName}:');
      imageUrls.forEach((key, value) {
        print('  ✓ $key: $value');
      });

      // Create new instance with image URLs
      return RegistrationDetails(
        success: details.success,
        id: details.id,
        name: details.name,
        type: details.type,
        mobile: details.mobile,
        email: details.email,
        submittedDate: details.submittedDate,
        status: details.status,
        stage: details.stage,
        fullName: details.fullName,
        address: details.address,
        reference: details.reference,
        companyName: details.companyName,
        licenseNumber: details.licenseNumber,
        trnNumber: details.trnNumber,
        accountHolder: details.accountHolder,
        iban: details.iban,
        bankName: details.bankName,
        branch: details.branch,
        avatar: details.avatar,
        emiratesId: details.emiratesId,
        // Add image URLs
        profilePhoto: imageUrls[DocumentType.profilePhoto],
        emiratesIdFront: imageUrls[DocumentType.emiratesIdFront],
        emiratesIdBack: imageUrls[DocumentType.emiratesIdBack],
        bankDocument: imageUrls[DocumentType.bankDocument],
        contractorCertificate: imageUrls[DocumentType.contractorCertificate],
        vatCertificate: imageUrls[DocumentType.vatCertificate],
        commercialLicense: imageUrls[DocumentType.commercialLicense],
      );
    } catch (e) {
      print('DEBUG: Error enriching with image URLs: $e');
      return details; // Return original if enrichment fails
    }
  }
}
