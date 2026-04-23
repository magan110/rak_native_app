import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:google_mlkit_text_recognition/google_mlkit_text_recognition.dart';
import 'package:path_provider/path_provider.dart';
import 'package:pdfx/pdfx.dart';

class BankDetailsOcrService {
  // OCR processing with retry mechanism
  Future<void> processBankDetailsOcrWithRetry({
    required String bankDocumentPath,
    required Function(Map<String, String?>) onFieldsExtracted,
    required Function(String) onError,
    int maxRetries = 3,
  }) async {
    int attempts = 0;
    bool success = false;

    while (attempts < maxRetries && !success) {
      try {
        await processBankDetailsOcr(
          bankDocumentPath: bankDocumentPath,
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

  // OCR processing: runs text recognition on the bank document
  Future<void> processBankDetailsOcr({
    required String bankDocumentPath,
    required Function(Map<String, String?>) onFieldsExtracted,
  }) async {
    // Process the bank document (image or PDF)
    final extractedText = await processFile(bankDocumentPath);

    // Debug logging
    print('Bank Document OCR Text: $extractedText');

    // Parse the extracted text for bank details
    final bankDetails = parseBankDetails(extractedText);
    print('Parsed Bank Details: $bankDetails');

    onFieldsExtracted(bankDetails);
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
        final tempImagePath = '${tempDir.path}/temp_bank_page_$i.jpg';
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
    final textRecognizer = TextRecognizer(script: TextRecognitionScript.latin);

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
      textRecognizer.close();
    }
  }

  // Placeholder for image preprocessing
  Future<File> preprocessImage(File imageFile) async {
    // You can use image package to enhance the image before OCR
    // For example: increase contrast, convert to grayscale, etc.
    // This is just a placeholder for the actual implementation
    return imageFile;
  }

  // Parse bank details from extracted text with a more robust, multi-pass approach
  Map<String, String?> parseBankDetails(String text) {
    final result = <String, String?>{
      'accountHolder': null,
      'iban': null,
      'bankName': null,
      'branchName': null,
      'bankAddress': null,
    };

    final lines = text
        .split('\n')
        .map((s) => s.trim())
        .where((s) => s.isNotEmpty)
        .toList();

    // --- PASS 1: Look for the most reliable patterns first (IBAN, Bank Name) ---

    // IBAN is the most unique identifier. Use a robust regex to find it in any format.
    // Try multiple patterns to handle different IBAN formats

    // Pattern 1: Standard UAE IBAN format (AE + 2 digits + 3 letters + 16 digits)
    final standardIbanRegex = RegExp(
      r'AE\s?\d{2}\s?[A-Z]{3}\s?\d{4}\s?\d{4}\s?\d{4}\s?\d{4}',
      caseSensitive: false,
    );
    final standardIbanMatch = standardIbanRegex.firstMatch(text);

    // Pattern 2: Alternative UAE IBAN format (AE + 2 digits + 4 digits + 15 digits)
    // Based on the example: AE88 0400 0001 8227 1199 002
    final alternativeIbanRegex = RegExp(
      r'AE\s?\d{2}\s?\d{4}\s?\d{4}\s?\d{4}\s?\d{4}\s?\d{3}',
      caseSensitive: false,
    );
    final alternativeIbanMatch = alternativeIbanRegex.firstMatch(text);

    // Pattern 3: Generic IBAN pattern (starts with AE, followed by 21 alphanumeric characters)
    final genericIbanRegex = RegExp(
      r'AE\s?\d{2}\s?[A-Z0-9]{19}',
      caseSensitive: false,
    );
    final genericIbanMatch = genericIbanRegex.firstMatch(text);

    // Use the first match found, prioritizing the more specific patterns
    if (standardIbanMatch != null) {
      result['iban'] = standardIbanMatch
          .group(0)!
          .replaceAll(RegExp(r'[\s-]'), '');
    } else if (alternativeIbanMatch != null) {
      result['iban'] = alternativeIbanMatch
          .group(0)!
          .replaceAll(RegExp(r'[\s-]'), '');
    } else if (genericIbanMatch != null) {
      result['iban'] = genericIbanMatch
          .group(0)!
          .replaceAll(RegExp(r'[\s-]'), '');
    }

    // Check for common UAE bank names
    final uaeBanks = [
      'Emirates NBD',
      'Dubai Islamic Bank',
      'Abu Dhabi Commercial Bank',
      'First Abu Dhabi Bank (FAB)',
      'Mashreq Bank',
      'Emirates Islamic Bank',
      'Sharjah Islamic Bank',
      'Abu Dhabi Islamic Bank',
      'RAK Bank',
      'National Bank of Abu Dhabi',
      'National Bank of Dubai',
      'Union National Bank',
      'Commercial Bank of Dubai',
      'Al Hilal Bank',
      'Al Waha Bank',
      'Emirates Development Bank',
      'HSBC Bank Middle East',
      'Standard Chartered UAE',
      'Barclays Bank',
      'Citibank',
      'Bank of Baroda',
      'Bank of Sharjah',
      'Arab Bank',
      'Burgan Bank',
    ];
    for (final bank in uaeBanks) {
      if (text.toLowerCase().contains(bank.toLowerCase())) {
        result['bankName'] = bank;
        break; // Assume the first match is correct
      }
    }

    // --- PASS 2: Loop through lines for explicit key-value pairs ---
    for (int i = 0; i < lines.length; i++) {
      final line = lines[i];
      final lower = line.toLowerCase();

      // Account Holder Name - check multiple keywords
      // REMOVED HEURISTIC: Only populate if an explicit label is found.
      if ((lower.contains('account holder') ||
              lower.contains('beneficiary name') ||
              lower.contains('account name') ||
              lower.contains('customer name')) &&
          result['accountHolder'] == null) {
        if (line.contains(':')) {
          result['accountHolder'] = line.split(':').skip(1).join(':').trim();
        } else if (i + 1 < lines.length && _isLikelyAValue(lines[i + 1])) {
          result['accountHolder'] = lines[i + 1];
        }
        continue;
      }

      // Bank Name - if not found in Pass 1
      if ((lower.contains('bank name') || lower.contains('beneficiary bank')) &&
          result['bankName'] == null) {
        if (line.contains(':')) {
          result['bankName'] = line.split(':').skip(1).join(':').trim();
        } else if (i + 1 < lines.length && _isLikelyAValue(lines[i + 1])) {
          result['bankName'] = lines[i + 1];
        }
        continue;
      }

      // Branch Name
      if (lower.contains('branch') && result['branchName'] == null) {
        if (line.contains(':')) {
          result['branchName'] = line.split(':').skip(1).join(':').trim();
        } else if (i + 1 < lines.length && _isLikelyAValue(lines[i + 1])) {
          result['branchName'] = lines[i + 1];
        }
        continue;
      }
    }

    // --- PASS 3: Heuristics for fields that might have been missed ---

    // Account Holder Heuristic REMOVED as per user request.

    // Bank Address: Look for the keyword "address" and grab subsequent lines.
    if (result['bankAddress'] == null) {
      // Define keywords that might precede an address
      final addressKeywords = [
        'address',
        'location',
        'office',
        'head office',
        'postal address',
      ];

      for (int i = 0; i < lines.length; i++) {
        final lineLower = lines[i].toLowerCase();

        // Check if the line contains an address keyword
        if (addressKeywords.any((keyword) => lineLower.contains(keyword))) {
          List<String> addressParts = [];

          // Start from the line after the keyword, or from the same line if it contains a colon
          int startLine = lineLower.contains(':') ? i : i + 1;

          for (int j = startLine; j < lines.length && j < startLine + 4; j++) {
            // Max 3 lines for address
            final potentialAddressLine = lines[j];

            // Stop conditions: if we hit another known field label, a phone number, or a very short line
            final stopKeywords = [
              'iban',
              'swift',
              'bic',
              'tel',
              'phone',
              'fax',
              'email',
              'po box',
              'p.o. box',
            ];
            if (stopKeywords.any(
                  (keyword) =>
                      potentialAddressLine.toLowerCase().contains(keyword),
                ) ||
                RegExp(r'^\d{2,}-\d{6,}$').hasMatch(
                  potentialAddressLine,
                ) || // Matches phone-like numbers
                potentialAddressLine.length < 5) {
              break;
            }
            addressParts.add(potentialAddressLine);
          }

          if (addressParts.isNotEmpty) {
            result['bankAddress'] = addressParts.join(', ');
            print('Found address: ${result['bankAddress']}'); // Debug log
          }
          break; // Found an address, stop looking.
        }
      }
    }

    return result;
  }

  // Recognize text from an image and auto-fill fields from blocks
  Future<Map<String, String?>> recognizeAndFillFields(File imageFile) async {
    final processedImage = await preprocessImage(imageFile);
    final inputImage = InputImage.fromFilePath(processedImage.path);
    final textRecognizer = TextRecognizer(script: TextRecognitionScript.latin);

    try {
      final recognisedText = await textRecognizer.processImage(inputImage);

      // Initialize result map
      final result = <String, String?>{
        'accountName': null,
        'bankName': null,
        'branchName': null,
        'bankAddress': null,
        'iban': null,
        'swiftCode': null,
      };

      // Parse text blocks to extract fields
      for (final block in recognisedText.blocks) {
        for (final line in block.lines) {
          final lower = line.text.toLowerCase();

          if (lower.contains('account name')) {
            result['accountName'] = _extractValue(line.text);
          } else if (lower.contains('bank name')) {
            result['bankName'] = _extractValue(line.text);
          } else if (lower.contains('branch name')) {
            result['branchName'] = _extractValue(line.text);
          } else if (lower.contains('address')) {
            // Capture multi-line address
            final addressLines = block.lines
                .skipWhile((l) => !l.text.toLowerCase().contains('address'))
                .map((l) => l.text)
                .take(3) // Limit to 3 lines for address
                .toList();
            result['bankAddress'] = addressLines.join(', ');
          } else if (lower.contains('iban')) {
            result['iban'] = _extractValue(line.text);
          } else if (lower.contains('swift code')) {
            result['swiftCode'] = _extractValue(line.text);
          }
        }
      }

      return result;
    } finally {
      textRecognizer.close();
    }
  }

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
      'iban',
      'address',
      'branch',
      'bank',
      'account',
      'details',
    ];

    if (labelKeywords.any((keyword) => lower.contains(keyword))) {
      return false;
    }
    // A good value is probably longer than 3 characters and not all caps (like a title)
    return line.length > 3 && line != line.toUpperCase();
  }

  // Validation helpers
  bool isValidIban(String iban) {
    // UAE IBAN format: AE + 2 digits + 3 letters + 16 digits (total 23 characters)
    // OR AE + 2 digits + 4 digits + 15 digits (total 23 characters)
    if (iban.length != 23) return false;

    // Check if it starts with AE
    if (!iban.startsWith('AE')) return false;

    // Check if it matches either of the two patterns
    final standardPattern = RegExp(r'AE\d{2}[A-Z]{3}\d{16}');
    final alternativePattern = RegExp(r'AE\d{2}\d{19}');

    return standardPattern.hasMatch(iban) || alternativePattern.hasMatch(iban);
  }
}
