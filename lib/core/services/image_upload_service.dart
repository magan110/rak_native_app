import 'dart:io';
import 'dart:typed_data';
import 'package:http/http.dart' as http;
import 'package:path/path.dart' as path;
import 'dart:convert';
import '../config/api_config.dart';

/// Service for handling image uploads to the server
class ImageUploadService {
  static const String _uploadEndpoint = '/api/ImageUpload/upload';

  /// Upload an image file with registered person's name and mobile number
  ///
  /// [file] - The image file to upload
  /// [personName] - Name of the registered person
  /// [mobileNumber] - Mobile number of the registered person
  /// [attFilTy] - Attachment file type (default: "01")
  /// [createId] - Creator ID (default: "SYSTEM")
  static Future<ImageUploadResponse> uploadImage({
    required File file,
    required String personName,
    required String mobileNumber,
    String attFilTy = "01",
    String createId = "SYSTEM",
  }) async {
    try {
      print('ImageUploadService: Starting upload');
      print('File path: ${file.path}');
      print('Person name: $personName');
      print('Mobile number: $mobileNumber');
      
      // Validate inputs
      if (!await file.exists()) {
        throw ImageUploadException('File does not exist');
      }

      // Create attFilKy from person name and mobile number
      final attFilKy = _createAttFilKy(personName, mobileNumber);
      print('Generated attFilKy: $attFilKy');

      // Prepare the multipart request
      final uri = Uri.parse('${ApiConfig.baseUrl}$_uploadEndpoint');
      print('Upload URL: $uri');
      
      final request = http.MultipartRequest('POST', uri);

      // Add query parameters
      request.fields['attFilKy'] = attFilKy;
      request.fields['attFilTy'] = attFilTy;
      request.fields['createId'] = createId;
      
      print('Request fields: ${request.fields}');

      // Add the file
      final fileBytes = await file.readAsBytes();
      final multipartFile = http.MultipartFile.fromBytes(
        'file',
        fileBytes,
        filename: path.basename(file.path),
      );
      request.files.add(multipartFile);

      // Add headers
      request.headers.addAll({
        'Accept': 'application/json',
        'User-Agent': 'RAK-Mobile-App/1.0.0 (Flutter; Android)',
        'Accept-Language': 'en-US,en;q=0.9',
        'Connection': 'keep-alive',
        'Cache-Control': 'no-cache',
      });

      // Send the request
      final streamedResponse = await request.send().timeout(
        const Duration(seconds: 30),
      );

      final response = await http.Response.fromStream(streamedResponse);

      if (response.statusCode == 200) {
        final responseData = json.decode(response.body);
        return ImageUploadResponse.fromJson(responseData);
      } else {
        throw ImageUploadException(
          'Upload failed with status ${response.statusCode}: ${response.body}',
        );
      }
    } catch (e) {
      if (e is ImageUploadException) {
        rethrow;
      }
      throw ImageUploadException('Failed to upload image: $e');
    }
  }

  /// Upload image from bytes with registered person's name and mobile number
  static Future<ImageUploadResponse> uploadImageFromBytes({
    required Uint8List bytes,
    required String fileName,
    required String personName,
    required String mobileNumber,
    String attFilTy = "01",
    String createId = "SYSTEM",
  }) async {
    try {
      // Create attFilKy from person name and mobile number
      final attFilKy = _createAttFilKy(personName, mobileNumber);

      // Prepare the multipart request
      final uri = Uri.parse('${ApiConfig.baseUrl}$_uploadEndpoint');
      final request = http.MultipartRequest('POST', uri);

      // Add query parameters
      request.fields['attFilKy'] = attFilKy;
      request.fields['attFilTy'] = attFilTy;
      request.fields['createId'] = createId;

      // Add the file from bytes
      final multipartFile = http.MultipartFile.fromBytes(
        'file',
        bytes,
        filename: fileName,
      );
      request.files.add(multipartFile);

      // Add headers
      request.headers.addAll({
        'Accept': 'application/json',
        'User-Agent': 'RAK-Mobile-App/1.0.0 (Flutter; Android)',
        'Accept-Language': 'en-US,en;q=0.9',
        'Connection': 'keep-alive',
        'Cache-Control': 'no-cache',
      });

      // Send the request
      final streamedResponse = await request.send().timeout(
        const Duration(seconds: 30),
      );

      final response = await http.Response.fromStream(streamedResponse);

      if (response.statusCode == 200) {
        final responseData = json.decode(response.body);
        return ImageUploadResponse.fromJson(responseData);
      } else {
        throw ImageUploadException(
          'Upload failed with status ${response.statusCode}: ${response.body}',
        );
      }
    } catch (e) {
      if (e is ImageUploadException) {
        rethrow;
      }
      throw ImageUploadException('Failed to upload image: $e');
    }
  }

  /// Create attFilKy from person name and mobile number
  /// Format: "PersonName_MobileNumber"
  static String _createAttFilKy(String personName, String mobileNumber) {
    // Clean and format the name and mobile number
    final cleanName = personName.trim().replaceAll(
      RegExp(r'[^A-Za-z0-9\s]'),
      '',
    );
    final cleanMobile = mobileNumber.trim().replaceAll(RegExp(r'[^0-9+]'), '');

    // Create the key in format: Name_Mobile
    final attFilKy = '${cleanName}_$cleanMobile';

    // Sanitize according to controller logic (keep only safe characters)
    final sanitized = attFilKy
        .replaceAll(RegExp(r'[^A-Za-z0-9_\-\.@+\s]'), '')
        .replaceAll(RegExp(r'\s+'), '_');

    // Trim to max 50 characters as per controller constraint
    return sanitized.length > 50 ? sanitized.substring(0, 50) : sanitized;
  }

  /// Validate if file is supported
  static bool isValidImageFile(File file) {
    final allowedExtensions = [
      '.jpg',
      '.jpeg',
      '.png',
      '.gif',
      '.bmp',
      '.webp',
      '.pdf',
    ];
    final extension = path.extension(file.path).toLowerCase();
    return allowedExtensions.contains(extension);
  }

  /// Get max file size in bytes (50MB as per controller)
  static int get maxFileSizeBytes => 50 * 1024 * 1024; // 50MB
}

/// Response model for image upload
class ImageUploadResponse {
  final String message;
  final ImageUploadData data;

  ImageUploadResponse({required this.message, required this.data});

  factory ImageUploadResponse.fromJson(Map<String, dynamic> json) {
    return ImageUploadResponse(
      message: json['msg'] ?? '',
      data: ImageUploadData.fromJson(json['data'] ?? {}),
    );
  }
}

/// Data model for upload response
class ImageUploadData {
  final String attFilKy;
  final String fileName;
  final String fileExtn;
  final int fileSizeBytes;
  final String createId;
  final String upsertMode;

  ImageUploadData({
    required this.attFilKy,
    required this.fileName,
    required this.fileExtn,
    required this.fileSizeBytes,
    required this.createId,
    required this.upsertMode,
  });

  factory ImageUploadData.fromJson(Map<String, dynamic> json) {
    return ImageUploadData(
      attFilKy: json['attFilKy'] ?? '',
      fileName: json['fileName'] ?? '',
      fileExtn: json['fileExtn'] ?? '',
      fileSizeBytes: json['fileSizeBytes'] ?? 0,
      createId: json['createId'] ?? '',
      upsertMode: json['upsertMode'] ?? '',
    );
  }
}

/// Exception for image upload errors
class ImageUploadException implements Exception {
  final String message;

  ImageUploadException(this.message);

  @override
  String toString() => 'ImageUploadException: $message';
}
