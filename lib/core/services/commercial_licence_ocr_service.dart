import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import '../network/ssl_http_client.dart';

class CommercialLicenseOcrService {
  // Replace with your actual API key
  static const String _apiKey =
      'eyJ0eXAiOiJKV1QiLCJhbGciOiJIUzI1NiJ9.eyJmcmVzaCI6ZmFsc2UsImlhdCI6MTYzNDEyMDQzMiwianRpIjoiMjY2YzliZGQtNTYyOC00M2I1LThkOGQtZjc5NjNjNGFjMmZkIiwidHlwZSI6ImFjY2VzcyIsImlkZW50aXR5IjoiZGV2LmFkaXR5YWJpcmxhQGFhZGhhYXJhcGkuaW8iLCJuYmYiOjE2MzQxMjA0MzIsImV4cCI6MTk0OTQ4MDQzMiwidXNlcl9jbGFpbXMiOnsic2NvcGVzIjpbInJlYWQiXX19._tHfR3FwZsQZ-EBvKlga031KdCPeUdXGw-JksGRIQVE';

  /// Process commercial license document using Surepass OCR API
  /// [apiUrl] The full URL endpoint for the OCR service
  /// [filePath] Path to the file to be processed
  /// Returns the extracted data as a Map if successful, null otherwise
  static Future<Map<String, dynamic>?> processDocument(
    String apiUrl,
    String filePath,
  ) async {
    try {
      // Check if file exists
      final file = File(filePath);
      if (!await file.exists()) {
        print('Error: File not found at path: $filePath');
        return null;
      }

      // Create multipart request
      final request = http.MultipartRequest('POST', Uri.parse(apiUrl));

      // Add headers
      request.headers.addAll({
        'Authorization': 'Bearer $_apiKey',
        'Accept': 'application/json',
      });

      // Add file to request
      final fileBytes = await file.readAsBytes();
      final multipartFile = http.MultipartFile.fromBytes(
        'file',
        fileBytes,
        filename: file.path.split('/').last,
      );
      request.files.add(multipartFile);

      print('Sending document to OCR API at: $apiUrl');

      // Send request using SSL-enabled client
      final client = await SslHttpClient.getClient();
      final streamedResponse = await client.send(request);
      final response = await http.Response.fromStream(streamedResponse);

      // Process response
      if (response.statusCode == 200) {
        final responseData = json.decode(response.body);
        print('OCR processing successful!');

        // Print extracted data to console
        _printExtractedData(responseData);

        return responseData;
      } else {
        print('Error: API returned status code ${response.statusCode}');
        print('Response body: ${response.body}');
        return null;
      }
    } catch (e) {
      print('Error processing document: $e');
      return null;
    }
  }

  /// Print the extracted data to console in a readable format
  static void _printExtractedData(Map<String, dynamic> data) {
    print('\n========== COMMERCIAL LICENSE OCR RESULTS ==========');

    // Check if data contains the expected structure
    if (data.containsKey('data') && data['data'] is Map) {
      final extractedData = data['data'] as Map<String, dynamic>;

      // Print each field if it exists
      _printField('License Number', extractedData['license_number']);
      _printField('Issuing Authority', extractedData['issuing_authority']);
      _printField('License Type', extractedData['license_type']);
      _printField('Trade Name', extractedData['trade_name']);
      _printField('Responsible Person', extractedData['responsible_person']);
      _printField('Establishment Date', extractedData['establishment_date']);
      _printField('Expiry Date', extractedData['expiry_date']);
      _printField(
        'Effective Registration Date',
        extractedData['effective_registration_date'],
      );

      // Print raw text if available
      if (extractedData.containsKey('raw_text')) {
        print('\n--- RAW TEXT ---');
        print(extractedData['raw_text']);
      }
    } else {
      // If structure is different, print the entire response
      print('Response data:');
      print(const JsonEncoder.withIndent('  ').convert(data));
    }

    print('\n========== END OF OCR RESULTS ==========\n');
  }

  /// Helper method to print a field if it exists
  static void _printField(String label, dynamic value) {
    if (value != null && value.toString().isNotEmpty) {
      print('$label: $value');
    }
  }
}
