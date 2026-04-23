import 'dart:io';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:rak_app/core/config/api_config.dart';
import '../network/ssl_http_client.dart';
import '../utils/logger.dart';

/// Service for uploading and retrieving images using the ImageUploadController
/// 
/// Key Format: {Name}_{MobileNumber}_{DocumentType}
/// Example: "John_Doe_971501234567_ProfilePhoto"
class ImageUploadService {
  static const String baseUrl = ApiConfig.baseUrl;
  static http.Client? _httpClient;
  static final AppLogger _logger = AppLogger();

  /// Get SSL-enabled HTTP client
  static Future<http.Client> _getClient() async {
    _httpClient ??= await SslHttpClient.getClient();
    return _httpClient!;
  }

  /// Generate a unique key for the image
  /// Format: {firstName}_{lastName}_{mobile}_{documentType}
  /// 
  /// Note: Mobile number is normalized to remove country code (971)
  /// to match the format used during upload
  static String generateImageKey({
    required String firstName,
    required String lastName,
    required String mobile,
    required String documentType,
  }) {
    // Clean and format the components
    final cleanFirstName = _sanitize(firstName);
    final cleanLastName = _sanitize(lastName);
    
    // Normalize mobile number - remove country code if present
    var cleanMobile = mobile.replaceAll(RegExp(r'[^0-9]'), '');
    // Remove 971 prefix if present (UAE country code)
    if (cleanMobile.startsWith('971') && cleanMobile.length > 9) {
      cleanMobile = cleanMobile.substring(3); // Remove first 3 digits (971)
    }
    
    final cleanDocType = _sanitize(documentType);

    // Create unique key
    return '${cleanFirstName}_${cleanLastName}_${cleanMobile}_$cleanDocType';
  }

  /// Sanitize string to match backend requirements
  /// Allowed: A-Z a-z 0-9 _ - . @ +
  static String _sanitize(String input) {
    if (input.isEmpty) return '';
    // Remove invalid characters
    var cleaned = input.replaceAll(RegExp(r'[^A-Za-z0-9_\-\.@+\s]'), '');
    // Replace spaces with underscores
    cleaned = cleaned.replaceAll(RegExp(r'\s+'), '_');
    // Trim to 50 chars max
    if (cleaned.length > 50) cleaned = cleaned.substring(0, 50);
    return cleaned;
  }

  /// Upload an image file
  /// 
  /// Parameters:
  /// - filePath: Local file path
  /// - attFilKy: Unique key (use generateImageKey)
  /// - attFilTy: File type (default "01")
  /// - createId: User ID who is uploading (default "SYSTEM")
  static Future<ImageUploadResponse> uploadImage({
    required String filePath,
    required String attFilKy,
    String attFilTy = '01',
    String createId = 'SYSTEM',
  }) async {
    try {
      final file = File(filePath);
      if (!await file.exists()) {
        return ImageUploadResponse(
          success: false,
          message: 'File does not exist: $filePath',
        );
      }

      final uri = Uri.parse('$baseUrl/api/ImageUpload/upload')
          .replace(queryParameters: {
        'attFilKy': attFilKy,
        'attFilTy': attFilTy,
        'createId': createId,
      });

      final client = await _getClient();
      final request = http.MultipartRequest('POST', uri);
      request.files.add(await http.MultipartFile.fromPath('file', filePath));

      _logger.debug('Uploading image: $attFilKy');

      final streamedResponse = await client.send(request).timeout(
        const Duration(seconds: 120),
      );

      final response = await http.Response.fromStream(streamedResponse);

      _logger.debug('Upload response: ${response.statusCode}');

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        return ImageUploadResponse(
          success: true,
          message: data['msg'] ?? 'Upload successful',
          attFilKy: attFilKy,
          fileName: data['data']?['fileName'],
          fileExtn: data['data']?['fileExtn'],
          fileSizeBytes: data['data']?['fileSizeBytes'],
          upsertMode: data['data']?['upsertMode'],
        );
      } else {
        return ImageUploadResponse(
          success: false,
          message: 'Upload failed: ${response.statusCode} - ${response.body}',
        );
      }
    } catch (e) {
      _logger.error('Upload error: $e');
      return ImageUploadResponse(
        success: false,
        message: 'Upload error: ${e.toString()}',
      );
    }
  }

  /// Get the URL to view/download an image
  /// 
  /// Parameters:
  /// - attFilKy: Unique key used during upload
  static String getImageUrl(String attFilKy) {
    return '$baseUrl/api/ImageUpload/view?attFilKy=${Uri.encodeComponent(attFilKy)}';
  }

  /// Check if an image exists by attempting to fetch it
  static Future<bool> imageExists(String attFilKy) async {
    try {
      final url = getImageUrl(attFilKy);
      final client = await _getClient();
      final response = await client.head(Uri.parse(url)).timeout(
        const Duration(seconds: 10),
      );
      return response.statusCode == 200;
    } catch (e) {
      _logger.error('Image exists check error: $e');
      return false;
    }
  }

  /// Upload multiple images in batch
  /// Returns a map of document types to their upload responses
  static Future<Map<String, ImageUploadResponse>> uploadMultipleImages({
    required Map<String, String> filePathsByType,
    required String firstName,
    required String lastName,
    required String mobile,
    String createId = 'SYSTEM',
    bool useParallelUpload = false,
  }) async {
    final results = <String, ImageUploadResponse>{};

    if (filePathsByType.isEmpty) {
      return results;
    }

    _logger.debug('Starting batch upload of ${filePathsByType.length} files (parallel: $useParallelUpload)');

    if (useParallelUpload && filePathsByType.length > 1) {
      // Parallel upload for better performance (but more server load)
      final futures = <Future<MapEntry<String, ImageUploadResponse>>>[];
      
      for (final entry in filePathsByType.entries) {
        final documentType = entry.key;
        final filePath = entry.value;

        if (filePath.isEmpty) continue;

        final attFilKy = generateImageKey(
          firstName: firstName,
          lastName: lastName,
          mobile: mobile,
          documentType: documentType,
        );

        futures.add(
          uploadImage(
            filePath: filePath,
            attFilKy: attFilKy,
            createId: createId,
          ).then((response) => MapEntry(documentType, response))
        );
      }

      // Wait for all uploads to complete
      final completedUploads = await Future.wait(futures);
      
      for (final entry in completedUploads) {
        results[entry.key] = entry.value;
      }
    } else {
      // Sequential upload (default) - more reliable for unstable connections
      for (final entry in filePathsByType.entries) {
        final documentType = entry.key;
        final filePath = entry.value;

        if (filePath.isEmpty) continue;

        final attFilKy = generateImageKey(
          firstName: firstName,
          lastName: lastName,
          mobile: mobile,
          documentType: documentType,
        );

        _logger.debug('Uploading $documentType...');
        final response = await uploadImage(
          filePath: filePath,
          attFilKy: attFilKy,
          createId: createId,
        );

        results[documentType] = response;

        // Add delay between uploads to avoid overwhelming the server
        if (entry != filePathsByType.entries.last) {
          await Future.delayed(const Duration(milliseconds: 1000));
        }
      }
    }

    // Log summary
    final successCount = results.values.where((r) => r.success).length;
    final failCount = results.length - successCount;
    _logger.debug('Batch upload complete: $successCount success, $failCount failed');

    return results;
  }

  /// Get all image URLs for a person
  /// Returns a map of document types to their URLs
  static Map<String, String> getPersonImageUrls({
    required String firstName,
    required String lastName,
    required String mobile,
    required List<String> documentTypes,
  }) {
    final urls = <String, String>{};

    for (final docType in documentTypes) {
      final attFilKy = generateImageKey(
        firstName: firstName,
        lastName: lastName,
        mobile: mobile,
        documentType: docType,
      );
      urls[docType] = getImageUrl(attFilKy);
    }

    return urls;
  }
}

/// Response model for image upload
class ImageUploadResponse {
  final bool success;
  final String message;
  final String? attFilKy;
  final String? fileName;
  final String? fileExtn;
  final int? fileSizeBytes;
  final String? upsertMode;

  ImageUploadResponse({
    required this.success,
    required this.message,
    this.attFilKy,
    this.fileName,
    this.fileExtn,
    this.fileSizeBytes,
    this.upsertMode,
  });

  @override
  String toString() {
    return 'ImageUploadResponse(success: $success, message: $message, '
        'attFilKy: $attFilKy, upsertMode: $upsertMode)';
  }
}

/// Document type constants for consistent naming
class DocumentType {
  // Common documents
  static const String profilePhoto = 'ProfilePhoto';
  static const String emiratesIdFront = 'EmiratesID_Front';
  static const String emiratesIdBack = 'EmiratesID_Back';
  static const String bankDocument = 'BankDocument';

  // Contractor-specific documents
  static const String contractorCertificate = 'ContractorCertificate';
  static const String vatCertificate = 'VATCertificate';
  static const String commercialLicense = 'CommercialLicense';

  // Retailer-specific documents
  static const String trnDocument = 'TRNDocument';
  static const String bankCheque = 'BankCheque';

  /// Get all document types for painters
  static List<String> getPainterDocumentTypes() {
    return [
      profilePhoto,
      emiratesIdFront,
      emiratesIdBack,
      bankDocument,
    ];
  }

  /// Get all document types for contractors
  static List<String> getContractorDocumentTypes() {
    return [
      profilePhoto,
      emiratesIdFront,
      emiratesIdBack,
      bankDocument,
      contractorCertificate,
      vatCertificate,
      commercialLicense,
    ];
  }

  /// Get all document types for retailers
  static List<String> getRetailerDocumentTypes() {
    return [
      trnDocument,
      bankCheque,
    ];
  }
}
