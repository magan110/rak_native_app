import 'dart:io';
import 'dart:typed_data'; // Removed unused import
import 'package:flutter/material.dart'; // Removed unused import
import 'package:google_ml_kit/google_ml_kit.dart';
import 'package:path_provider/path_provider.dart';
import 'package:pdfx/pdfx.dart';

class VatCertificateOcrService {
  // OCR processing with retry mechanism
  Future<void> processVatCertificateOcrWithRetry({
    required String vatCertificatePath,
    required Function(Map<String, String?>) onFieldsExtracted,
    required Function(String) onError,
    int maxRetries = 3,
  }) async {
    int attempts = 0;
    bool success = false;

    while (attempts < maxRetries && !success) {
      try {
        await processVatCertificateOcr(
          vatCertificatePath: vatCertificatePath,
          onFieldsExtracted: onFieldsExtracted,
        );
        success = true;
      } catch (e) {
        attempts++;
        if (attempts >= maxRetries) {
          onError('OCR failed after $maxRetries attempts');
        } else {
          // Wait a bit before retrying
          await Future.delayed(const Duration(seconds: 1));
        }
      }
    }
  }

  // OCR processing: runs text recognition on the VAT certificate
  Future<void> processVatCertificateOcr({
    required String vatCertificatePath,
    required Function(Map<String, String?>) onFieldsExtracted,
  }) async {
    // Process the VAT certificate (image or PDF)
    final extractedText = await processFile(vatCertificatePath);

    // Debug logging
    print('VAT Certificate OCR Text: $extractedText');

    // Parse the extracted text for VAT details
    final vatDetails = parseVatDetails(extractedText);
    print('Parsed VAT Details: $vatDetails');

    onFieldsExtracted(vatDetails);
  }

  // Process a file (image or PDF) and return extracted text in the same format as the document
  Future<String> processFile(String filePath) async {
    final file = File(filePath);
    final extension = file.path.toLowerCase().split('.').last;

    if (extension == 'pdf') {
      return await processPdf(file);
    } else {
      return await recognizeText(file);
    }
  }

  // Process PDF file: convert to images and extract text while preserving format
  Future<String> processPdf(File pdfFile) async {
    try {
      final document = await PdfDocument.openFile(pdfFile.path);
      StringBuffer allText = StringBuffer();

      // Process each page of the PDF
      for (int i = 1; i <= document.pagesCount; i++) {
        final page = await document.getPage(i);

        // Render page to image
        final pageImage = await page.render(
          width: page.width * 2, // Higher resolution for better OCR
          height: page.height * 2,
          format: PdfPageImageFormat.jpeg,
          backgroundColor: '#ffffff',
        );

        // Save rendered image to temporary file
        final tempDir = await getTemporaryDirectory();
        final tempImagePath = '${tempDir.path}/temp_vat_page_$i.jpg';
        final tempImageFile = File(tempImagePath);
        await tempImageFile.writeAsBytes(pageImage?.bytes as List<int>);

        // Extract text from the rendered image
        final pageText = await recognizeText(tempImageFile);
        allText.writeln(pageText); // Preserve line breaks

        // Clean up temporary file
        await tempImageFile.delete();

        // Close page
        await page.close();
      }

      await document.close();
      return allText.toString();
    } catch (e) {
      print('Error processing PDF: $e');
      throw Exception('Failed to process PDF: ${e.toString()}');
    }
  }

  // Recognize text from an image while preserving format and layout
  Future<String> recognizeText(File imageFile) async {
    final processedImage = await preprocessImage(imageFile);
    final inputImage = InputImage.fromFilePath(processedImage.path);
    final textRecognizer = GoogleMlKit.vision.textRecognizer();

    try {
      final recognisedText = await textRecognizer.processImage(inputImage);

      // Preserve layout by considering block, line, and element structure
      final buffer = StringBuffer();
      for (final block in recognisedText.blocks) {
        for (final line in block.lines) {
          buffer.writeln(line.text); // Add each line with a newline
        }
        buffer.writeln(); // Add an extra newline between blocks
      }

      return buffer.toString();
    } finally {
      await textRecognizer.close();
    }
  }

  // Placeholder for image preprocessing
  Future<File> preprocessImage(File imageFile) async {
    // You can use image package to enhance the image before OCR
    // For example: increase contrast, convert to grayscale, etc.
    // This is just a placeholder for the actual implementation
    return imageFile;
  }

  // Parse VAT details from extracted text with a more robust, multi-pass approach
  Map<String, String?> parseVatDetails(String text) {
    final result = <String, String?>{
      'firmName': null,
      'taxNumber': null,
      'registeredAddress': null,
      'effectiveDate': null,
    };

    final lines = text
        .split('\n')
        .map((s) => s.trim())
        .where((s) => s.isNotEmpty)
        .toList();

    // --- PASS 1: Look for the most reliable patterns first (Tax Registration Number) ---
    final trnRegex = RegExp(
      r'(?:TRN|Tax Registration Number|VAT Registration)[\s:]+(\d{15})',
      caseSensitive: false,
    );
    final trnMatch = trnRegex.firstMatch(text);
    if (trnMatch != null) {
      result['taxNumber'] = trnMatch.group(1)?.trim();
    } else {
      final digitRegex = RegExp(r'\b(\d{15})\b');
      final digitMatch = digitRegex.firstMatch(text);
      if (digitMatch != null) {
        result['taxNumber'] = digitMatch.group(1)?.trim();
      }
    }

    // --- PASS 2: Loop through lines for explicit key-value pairs ---
    for (int i = 0; i < lines.length; i++) {
      final line = lines[i];
      final lower = line.toLowerCase();

      // Firm Name - join up to 2 lines if needed
      if ((lower.contains('name') ||
              lower.contains('company') ||
              lower.contains('trade name')) &&
          result['firmName'] == null) {
        String firmName = '';
        if (line.contains(':')) {
          firmName = line.split(':').skip(1).join(':').trim();
        } else if (i + 1 < lines.length && _isLikelyAValue(lines[i + 1])) {
          firmName = lines[i + 1];
          // Join next line if it is also likely a value and not a label
          if (i + 2 < lines.length && _isLikelyAValue(lines[i + 2])) {
            firmName += ' ' + lines[i + 2];
          }
        }
        result['firmName'] = firmName;
        continue;
      }

      // Registered Address - join up to 3 lines if needed
      if ((lower.contains('address') || lower.contains('location')) &&
          result['registeredAddress'] == null) {
        String address = '';
        if (line.contains(':')) {
          address = line.split(':').skip(1).join(':').trim();
        } else if (i + 1 < lines.length && _isLikelyAValue(lines[i + 1])) {
          address = lines[i + 1];
          if (i + 2 < lines.length && _isLikelyAValue(lines[i + 2])) {
            address += ', ' + lines[i + 2];
          }
          if (i + 3 < lines.length && _isLikelyAValue(lines[i + 3])) {
            address += ', ' + lines[i + 3];
          }
        }
        result['registeredAddress'] = address;
        continue;
      }

      // Effective Date
      if ((lower.contains('effective date') ||
              lower.contains('date of issue') ||
              lower.contains('issue date') ||
              lower.contains('registration date')) &&
          result['effectiveDate'] == null) {
        if (line.contains(':')) {
          result['effectiveDate'] = _normalizeDate(
            line.split(':').skip(1).join(':').trim(),
          );
        } else if (i + 1 < lines.length && _isLikelyAValue(lines[i + 1])) {
          result['effectiveDate'] = _normalizeDate(lines[i + 1]);
        }
        continue;
      }
    }

    // --- PASS 3: Heuristics for fields that might have been missed ---

    // Firm Name Heuristic: Look for capitalized lines that might be company names
    if (result['firmName'] == null) {
      for (final line in lines) {
        if (line.trim().isNotEmpty &&
            line.trim().length > 3 &&
            _isLikelyCompanyName(line.trim())) {
          result['firmName'] = line.trim();
          break;
        }
      }
    }

    // Registered Address: Look for lines containing UAE emirates
    if (result['registeredAddress'] == null) {
      for (int i = 0; i < lines.length; i++) {
        final line = lines[i].trim();
        if (line.contains('UAE') ||
            line.contains('Dubai') ||
            line.contains('Abu Dhabi') ||
            line.contains('Sharjah') ||
            line.contains('Ajman') ||
            line.contains('Umm Al Quwain') ||
            line.contains('Ras Al Khaimah') ||
            line.contains('Fujairah')) {
          // Include next line if it seems to be part of the address
          String address = line;
          if (i + 1 < lines.length &&
              lines[i + 1].trim().length > 5 &&
              !lines[i + 1].contains(':')) {
            address += '\n' + lines[i + 1].trim();
          }

          result['registeredAddress'] = address;
          break;
        }
      }
    }

    // Effective Date: Look for any date pattern in the text
    if (result['effectiveDate'] == null) {
      final generalDateRegex = RegExp(
        r'\b(\d{1,2}[/-]\d{1,2}[/-]\d{2,4}|\d{2,4}[/-]\d{1,2}[/-]\d{1,2})\b',
      );
      final dateMatch = generalDateRegex.firstMatch(text);
      if (dateMatch != null) {
        result['effectiveDate'] = _normalizeDate(dateMatch.group(1)?.trim());
      }
    }

    return result;
  }

  // Recognize text from an image and auto-fill fields from blocks
  Future<Map<String, String?>> recognizeAndFillFields(File imageFile) async {
    final processedImage = await preprocessImage(imageFile);
    final inputImage = InputImage.fromFilePath(processedImage.path);
    final textRecognizer = GoogleMlKit.vision.textRecognizer();

    try {
      final recognisedText = await textRecognizer.processImage(inputImage);

      // Initialize result map
      final result = <String, String?>{
        'firmName': null,
        'taxNumber': null,
        'registeredAddress': null,
        'effectiveDate': null,
      };

      // Parse text blocks to extract fields
      for (final block in recognisedText.blocks) {
        for (final line in block.lines) {
          final lower = line.text.toLowerCase();

          if (lower.contains('name') && !lower.contains('tax')) {
            result['firmName'] = _extractValue(line.text);
          } else if (lower.contains('tax registration') ||
              lower.contains('trn')) {
            result['taxNumber'] = _extractValue(line.text);
          } else if (lower.contains('address')) {
            // Capture multi-line address
            final addressLines = block.lines
                .skipWhile((l) => !l.text.toLowerCase().contains('address'))
                .map((l) => l.text)
                .take(3) // Limit to 3 lines for address
                .toList();
            result['registeredAddress'] = addressLines.join(', ');
          } else if (lower.contains('effective date') ||
              lower.contains('date of issue')) {
            result['effectiveDate'] = _normalizeDate(_extractValue(line.text));
          }
        }
      }

      return result;
    } finally {
      await textRecognizer.close();
    }
  }

  // Extract VAT fields using Google Generative AI
  Future<Map<String, String?>> extractVatFieldsWithGenAI(
    String extractedText,
  ) async {
    // Generative AI functionality removed as requested.
    throw UnimplementedError('Generative AI extraction has been removed.');
  }

  // Helper to extract JSON from GenAI response text
  // _extractJsonFromText removed as it is no longer used.

  // Helper to extract value after a colon or keyword
  String? _extractValue(String text) {
    if (text.contains(':')) {
      return text.split(':').skip(1).join(':').trim();
    }
    return text.trim();
  }

  // Helper to check if a line is likely a value rather than a label
  bool _isLikelyAValue(String line) {
    // A value is typically not just a single word, doesn't contain common label keywords,
    // and might contain numbers or mixed case.
    final lower = line.toLowerCase();
    final labelKeywords = [
      'name',
      'number',
      'address',
      'date',
      'effective',
      'registration',
      'tax',
      'trn',
    ];

    if (labelKeywords.any((keyword) => lower.contains(keyword))) {
      return false;
    }
    // A good value is probably longer than 3 characters and not all caps (like a title)
    return line.length > 3 && line != line.toUpperCase();
  }

  // Helper to check if the text looks like a company name
  bool _isLikelyCompanyName(String text) {
    // Skip if it contains numbers or looks like a field label
    if (RegExp(r'\d').hasMatch(text) ||
        text.contains(':') ||
        text.toLowerCase().contains('date') ||
        text.toLowerCase().contains('number') ||
        text.toLowerCase().contains('address')) {
      return false;
    }

    // Check if it has multiple words (common in company names)
    final words = text.split(' ');
    if (words.length < 2) return false;

    // Check if most words start with capital letters
    int capitalizedWords = 0;
    for (final word in words) {
      if (word.isNotEmpty && word[0] == word[0].toUpperCase()) {
        capitalizedWords++;
      }
    }

    return capitalizedWords / words.length > 0.7;
  }

  // Normalize date format to DD/MM/YYYY
  String _normalizeDate(String? date) {
    if (date == null || date.isEmpty) return '';

    // Convert various date formats to DD/MM/YYYY
    final parts = date.split(RegExp(r'[/-]'));
    if (parts.length != 3) return date;

    try {
      int day, month, year;

      // Try to determine format
      if (parts[0].length == 4) {
        // YYYY/MM/DD or YYYY-MM-DD
        year = int.parse(parts[0]);
        month = int.parse(parts[1]);
        day = int.parse(parts[2]);
      } else {
        // DD/MM/YYYY or DD-MM-YYYY
        day = int.parse(parts[0]);
        month = int.parse(parts[1]);
        year = int.parse(parts[2]);

        // Handle 2-digit years
        if (year < 100) {
          year += 2000;
        }
      }

      return '${day.toString().padLeft(2, '0')}/${month.toString().padLeft(2, '0')}/$year';
    } catch (e) {
      return date; // Return original if parsing fails
    }
  }

  // Validation helpers
  bool isValidTaxNumber(String taxNumber) {
    // UAE TRN format: 15 digits
    if (taxNumber.length != 15) return false;

    // Check if all characters are digits
    return RegExp(r'^\d{15}$').hasMatch(taxNumber);
  }
}
