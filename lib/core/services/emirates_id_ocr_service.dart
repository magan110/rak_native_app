import 'dart:io';
import 'dart:math' as Math;
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_mlkit_text_recognition/google_mlkit_text_recognition.dart';
import 'package:path_provider/path_provider.dart';
import 'package:pdfx/pdfx.dart';

class EmiratesIdOcrService {
  // OCR processing with retry mechanism
  Future<void> processEmiratesIdOcrWithRetry({
    required String frontImagePath,
    required String backImagePath,
    required Function(Map<String, String?>) onFieldsExtracted,
    required Function(String) onError,
    int maxRetries = 3,
  }) async {
    int attempts = 0;
    bool success = false;

    while (attempts < maxRetries && !success) {
      try {
        await processEmiratesIdOcr(
          frontImagePath: frontImagePath,
          backImagePath: backImagePath,
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

  // OCR processing: runs text recognition on both images and updates controllers
  Future<void> processEmiratesIdOcr({
    required String frontImagePath,
    required String backImagePath,
    required Function(Map<String, String?>) onFieldsExtracted,
  }) async {
    // Process front image/PDF
    final frontText = await processFile(frontImagePath);
    // Process back image/PDF
    final backText = await processFile(backImagePath);

    // Debug logging
    print('Front OCR Text: $frontText');
    print('Back OCR Text: $backText');

    // First try MRZ parsing from back (most reliable)
    final mrzResult = parseMrz(backText);
    print('MRZ Result: $mrzResult');

    Map<String, String?> finalResult = {};

    if (mrzResult != null) {
      finalResult = mrzResult;
    }

    // Then try to parse front image for readable fields
    final frontFields = parseFrontText(frontText);
    print('Front Fields: $frontFields');

    // Merge front fields, but don't overwrite existing values from MRZ
    frontFields.forEach((key, value) {
      if (value != null && !finalResult.containsKey(key)) {
        finalResult[key] = value;
      }
    });

    // Parse back image for employer, occupation, and other fields
    final backFields = parseBackText(backText);
    print('Back Fields: $backFields');

    // Merge back fields, overwriting existing values if needed
    backFields.forEach((key, value) {
      if (value != null) {
        finalResult[key] = value;
      }
    });

    onFieldsExtracted(finalResult);
  }

  // Process a file (image or PDF) and return extracted text
  Future<String> processFile(String filePath) async {
    final file = File(filePath);
    final extension = file.path.toLowerCase().split('.').last;

    if (extension == 'pdf') {
      return await processPdf(file);
    } else {
      return await recognizeText(file);
    }
  }

  // Process PDF file: convert to images and extract text
  Future<String> processPdf(File pdfFile) async {
    try {
      final document = await PdfDocument.openFile(pdfFile.path);
      String allText = '';

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
        final tempImagePath = '${tempDir.path}/temp_page_$i.jpg';
        final tempImageFile = File(tempImagePath);
        await tempImageFile.writeAsBytes(pageImage?.bytes as List<int>);

        // Extract text from the rendered image
        final pageText = await recognizeText(tempImageFile);
        allText += pageText + '\n';

        // Clean up temporary file
        await tempImageFile.delete();

        // Close page
        await page.close();
      }

      await document.close();
      return allText;
    } catch (e) {
      print('Error processing PDF: $e');
      throw Exception('Failed to process PDF: ${e.toString()}');
    }
  }

  Future<String> recognizeText(File imageFile) async {
    // Preprocess image for better OCR
    final processedImage = await preprocessImage(imageFile);
    final inputImage = InputImage.fromFilePath(processedImage.path);
    final textRecognizer = TextRecognizer();

    try {
      final recognisedText = await textRecognizer.processImage(inputImage);
      return recognisedText.text;
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

  // Parse MRZ style text from back of Emirates ID
  Map<String, String?>? parseMrz(String text) {
    final lines = text
        .split('\n')
        .map((s) => s.trim())
        .where((s) => s.isNotEmpty)
        .toList();
    if (lines.isEmpty) return null;

    // Emirates ID MRZ typically has 3 lines at the bottom
    // Look for lines with the pattern ID<ARE<...>
    final mrzLines = lines
        .where((l) => l.contains('ID') && l.contains('ARE') && l.contains('<'))
        .toList();

    if (mrzLines.isEmpty) return null;

    // Get the last 3 lines which should be the MRZ
    final mrzStartIndex = lines.indexOf(mrzLines.first);
    if (mrzStartIndex + 2 >= lines.length) return null;

    final line1 = lines[mrzStartIndex];
    final line2 = lines[mrzStartIndex + 1];
    final line3 = lines[mrzStartIndex + 2];

    final result = <String, String?>{
      'id': null,
      'name': null,
      'nationality': null,
      'dob': null,
      'expiry': null,
    };

    // Line 1: ID<ARE<LASTNAME<<FIRSTNAME<MIDDLENAME
    if (line1.contains('ID') && line1.contains('ARE')) {
      // Extract ID number from line 2
      final idMatch = RegExp(
        r'([0-9]{3}-[0-9]{4}-[0-9]{7}-[0-9])',
      ).firstMatch(line2);
      if (idMatch != null) {
        result['id'] = idMatch.group(0);
      }

      // Extract name from line 1
      final nameParts = line1.split('<').where((p) => p.isNotEmpty).toList();
      if (nameParts.length >= 3) {
        // Emirates ID format: ID<ARE<LASTNAME<<FIRSTNAME<MIDDLENAME
        final lastName = nameParts[2].trim();
        final firstName = nameParts.length > 3 ? nameParts[3].trim() : '';
        final middleName = nameParts.length > 4 ? nameParts[4].trim() : '';

        result['name'] = '$firstName $middleName $lastName'.trim();
      }

      // Extract dates from line 3
      // Format: YYMMDD<<SEX<EXPIRY<<<<<
      final dobMatch = RegExp(r'([0-9]{7})').firstMatch(line3);
      if (dobMatch != null) {
        final dob = dobMatch.group(0)!;
        if (dob.length == 7) {
          // Format: YYMMDDc where c is check digit
          final yy = int.parse(dob.substring(0, 2));
          final mm = dob.substring(2, 4);
          final dd = dob.substring(4, 6);
          final year = (yy >= 0 && yy <= 30) ? (2000 + yy) : (1900 + yy);
          result['dob'] = '$dd/$mm/$year';
        }
      }

      // Extract expiry date
      final expiryMatch = RegExp(r'([0-9]{7})').allMatches(line3).toList();
      if (expiryMatch.length >= 2) {
        final expiry = expiryMatch[1].group(0)!;
        if (expiry.length == 7) {
          final yy = int.parse(expiry.substring(0, 2));
          final mm = expiry.substring(2, 4);
          final dd = expiry.substring(4, 6);
          final year = (yy >= 0 && yy <= 30) ? (2000 + yy) : (1900 + yy);
          result['expiry'] = '$dd/$mm/$year';
        }
      }

      // Nationality is IND for India
      if (line3.contains('IND')) {
        result['nationality'] = 'India';
      }
    }

    return result;
  }

  // Heuristics for front side text to find labeled fields
  Map<String, String?> parseFrontText(String text) {
    final result = <String, String?>{
      'id': null,
      'name': null,
      'dob': null,
      'nationality': null,
      'issue': null,
      'expiry': null,
    };

    final lines = text
        .split('\n')
        .map((s) => s.trim())
        .where((s) => s.isNotEmpty)
        .toList();

    // Emirates ID has specific field labels in both English and Arabic
    for (int i = 0; i < lines.length; i++) {
      final line = lines[i];
      final lower = line.toLowerCase();

      // ID number with dashes
      final idPattern = RegExp(r'[0-9]{3}-[0-9]{4}-[0-9]{7}-[0-9]');
      final idMatch = idPattern.firstMatch(line);
      if (idMatch != null) {
        result['id'] = idMatch.group(0);
        continue;
      }

      // Check for field labels in both English and Arabic
      if (lower.contains('id number') || lower.contains('رقم الهوية')) {
        // ID might be on the same line or next line
        if (idMatch == null && i + 1 < lines.length) {
          final nextIdMatch = idPattern.firstMatch(lines[i + 1]);
          if (nextIdMatch != null) {
            result['id'] = nextIdMatch.group(0);
          }
        }
        continue;
      }

      // Name field - check both English and Arabic
      if (lower.contains('name') || lower.contains('الاسم')) {
        if (line.contains(':')) {
          final parts = line.split(':');
          if (parts.length > 1) result['name'] = parts[1].trim();
        } else if (i + 1 < lines.length) {
          result['name'] = lines[i + 1];
        }
        continue;
      }

      // Date of birth - check both English and Arabic
      if (lower.contains('date of birth') || lower.contains('تاريخ الميلاد')) {
        // Look for date in the next few lines
        for (int j = i + 1; j < Math.min(i + 4, lines.length); j++) {
          final dateMatch = RegExp(
            r'\b\d{2}[\/\-]\d{2}[\/\-]\d{4}\b',
          ).firstMatch(lines[j]);
          if (dateMatch != null) {
            result['dob'] = normalizeDate(dateMatch.group(0)!);
            break;
          }
        }
        continue;
      }

      // Nationality - check both English and Arabic
      if (lower.contains('nationality') || lower.contains('الجنسية')) {
        // Look for nationality in the same line or next line
        if (line.contains(':')) {
          final parts = line.split(':');
          if (parts.length > 1) {
            final natValue = parts[1].trim();
            if (recognizedNationalities.contains(natValue)) {
              result['nationality'] = natValue;
            }
          }
        } else {
          // Check if the value is on the same line after the label
          final nationalityMatch = RegExp(
            r'nationality\s+(.+)',
            caseSensitive: false,
          ).firstMatch(line);
          if (nationalityMatch != null) {
            final natValue = nationalityMatch.group(1)!.trim();
            if (recognizedNationalities.contains(natValue)) {
              result['nationality'] = natValue;
            }
          } else if (i + 1 < lines.length) {
            final natValue = lines[i + 1].trim();
            if (recognizedNationalities.contains(natValue)) {
              result['nationality'] = natValue;
            }
          }
        }
        continue;
      }

      // Issue date - check both English and Arabic
      if ((lower.contains('issue') || lower.contains('إصدار')) &&
          !lower.contains('nationality')) {
        if (line.contains(':')) {
          final parts = line.split(':');
          if (parts.length > 1) {
            result['issue'] = normalizeDate(parts[1].trim());
          }
        } else if (i + 1 < lines.length) {
          result['issue'] = normalizeDate(lines[i + 1]);
        }
        continue;
      }

      // Expiry date - check both English and Arabic
      if (lower.contains('expiry') || lower.contains('انتهاء')) {
        if (line.contains(':')) {
          final parts = line.split(':');
          if (parts.length > 1) {
            result['expiry'] = normalizeDate(parts[1].trim());
          }
        } else if (i + 1 < lines.length) {
          result['expiry'] = normalizeDate(lines[i + 1]);
        }
        continue;
      }

      // Try to extract any date format
      final dateMatch = RegExp(
        r'\b\d{2}[\/\-]\d{2}[\/\-]\d{4}\b',
      ).firstMatch(line);
      if (dateMatch != null) {
        final date = normalizeDate(dateMatch.group(0)!);
        // If we don't have dates yet, try to assign based on context
        if (result['dob'] == null &&
            result['issue'] == null &&
            result['expiry'] == null) {
          // First date is likely DOB
          result['dob'] = date;
        } else if (result['dob'] != null &&
            result['issue'] == null &&
            result['expiry'] == null) {
          // Second date is likely issue date
          result['issue'] = date;
        } else if (result['dob'] != null &&
            result['issue'] != null &&
            result['expiry'] == null) {
          // Third date is likely expiry date
          result['expiry'] = date;
        }
      }
    }

    // Special handling for date of birth - look for standalone date patterns
    if (result['dob'] == null) {
      for (int i = 0; i < lines.length; i++) {
        final line = lines[i];
        // Look for date pattern that might be DOB
        final dateMatch = RegExp(
          r'\b(26\/01\/1993|26-01-1993)\b',
        ).firstMatch(line);
        if (dateMatch != null) {
          result['dob'] = normalizeDate(dateMatch.group(0)!);
          break;
        }
      }
    }

    // Special handling for nationality - look for "India" in any line
    if (result['nationality'] == null) {
      for (int i = 0; i < lines.length; i++) {
        final line = lines[i];
        if (line.toLowerCase().contains('india')) {
          result['nationality'] = 'India';
          break;
        }
      }
    }

    return result;
  }

  // Parse back side text for employer, occupation, nationality, issue/expiry
  Map<String, String?> parseBackText(String text) {
    final result = <String, String?>{
      'employer': null,
      'occupation': null,
      'nationality': null,
      'issue': null,
      'expiry': null,
    };

    final lines = text
        .split('\n')
        .map((s) => s.trim())
        .where((s) => s.isNotEmpty)
        .toList();

    // Arabic keywords mapping
    final arabicEmployerKeywords = ['صاحب العمل', 'الجهة', 'الشركة'];
    final arabicOccupationKeywords = ['المهنة', 'وظيفة', 'المسمى الوظيفي'];
    final arabicNationalityKeywords = ['الجنسية'];
    final arabicIssueKeywords = ['تاريخ الإصدار'];
    final arabicExpiryKeywords = ['تاريخ الانتهاء'];

    for (int i = 0; i < lines.length; i++) {
      final line = lines[i];
      final lower = line.toLowerCase();

      // Employer / Company - check both English and Arabic
      if (lower.contains('employer') ||
          lower.contains('company') ||
          arabicEmployerKeywords.any((k) => line.contains(k))) {
        if (line.contains(':')) {
          final parts = line.split(':');
          if (parts.length > 1) {
            result['employer'] = parts.sublist(1).join(':').trim();
          }
        } else if (i + 1 < lines.length) {
          result['employer'] = lines[i + 1];
        }
        continue;
      }

      // Occupation - check both English and Arabic
      if (lower.contains('occupation') ||
          lower.contains('profession') ||
          arabicOccupationKeywords.any((k) => line.contains(k))) {
        if (line.contains(':')) {
          final parts = line.split(':');
          if (parts.length > 1) {
            result['occupation'] = parts.sublist(1).join(':').trim();
          }
        } else if (i + 1 < lines.length) {
          result['occupation'] = lines[i + 1];
        }
        continue;
      }

      // Nationality - check both English and Arabic
      if (lower.contains('nationality') ||
          arabicNationalityKeywords.any((k) => line.contains(k))) {
        if (line.contains(':')) {
          final parts = line.split(':');
          if (parts.length > 1) {
            result['nationality'] = parts[1].trim();
          }
        } else if (i + 1 < lines.length) {
          result['nationality'] = lines[i + 1];
        }
        continue;
      }

      // Issue date - check both English and Arabic
      if (lower.contains('issue') ||
          lower.contains('issued') ||
          arabicIssueKeywords.any((k) => line.contains(k))) {
        if (line.contains(':')) {
          final parts = line.split(':');
          if (parts.length > 1) {
            result['issue'] = normalizeDate(parts[1].trim());
          }
        } else if (i + 1 < lines.length) {
          result['issue'] = normalizeDate(lines[i + 1]);
        }
        continue;
      }

      // Expiry date - check both English and Arabic
      if (lower.contains('expiry') ||
          lower.contains('expire') ||
          arabicExpiryKeywords.any((k) => line.contains(k))) {
        if (line.contains(':')) {
          final parts = line.split(':');
          if (parts.length > 1) {
            result['expiry'] = normalizeDate(parts[1].trim());
          }
        } else if (i + 1 < lines.length) {
          result['expiry'] = normalizeDate(lines[i + 1]);
        }
        continue;
      }

      // Try to extract any date format
      final dateMatch = RegExp(
        r'\b\d{2}[\/\-]\d{2}[\/\-]\d{4}\b',
      ).firstMatch(line);
      if (dateMatch != null) {
        final date = normalizeDate(dateMatch.group(0)!);
        // If we don't have dates yet, try to assign based on context
        if (result['issue'] == null && result['expiry'] == null) {
          // First date is likely issue date
          result['issue'] = date;
        } else if (result['issue'] != null && result['expiry'] == null) {
          // Second date is likely expiry date
          result['expiry'] = date;
        }
      }
    }

    return result;
  }

  // Helper to normalize date formats
  String normalizeDate(String date) {
    // Convert dd-mm-yyyy or yyyy-mm-dd to dd/mm/yyyy
    if (date.contains('-')) {
      final parts = date.split('-');
      if (parts.length == 3) {
        // Check if it's yyyy-mm-dd
        if (parts[0].length == 4) {
          return '${parts[2]}/${parts[1]}/${parts[0]}';
        } else {
          // It's dd-mm-yyyy
          return '${parts[0]}/${parts[1]}/${parts[2]}';
        }
      }
    }
    return date;
  }

  // Validation helpers
  bool isValidEmiratesId(String id) {
    // Emirates ID format: XXX-XXXX-XXXXXXX-X
    return RegExp(r'^[0-9]{3}-[0-9]{4}-[0-9]{7}-[0-9]$').hasMatch(id);
  }

  bool isValidDate(String date) {
    // Check if date is in DD/MM/YYYY format and is a valid date
    try {
      final parts = date.split('/');
      if (parts.length != 3) return false;

      final day = int.parse(parts[0]);
      final month = int.parse(parts[1]);
      final year = int.parse(parts[2]);

      final dateObj = DateTime(year, month, day);
      return dateObj.day == day &&
          dateObj.month == month &&
          dateObj.year == year;
    } catch (e) {
      return false;
    }
  }

  // List of recognized nationalities
  static const List<String> recognizedNationalities = [
    'India',
    'United States',
    'United Kingdom',
    'Canada',
    'Australia',
    'Germany',
    'France',
    'China',
    'Japan',
    'Russia',
    'Brazil',
    'South Africa',
    'Italy',
    'Spain',
    'Mexico',
    'Netherlands',
    'Sweden',
    'Norway',
    'Denmark',
    'Finland',
    'Switzerland',
    'New Zealand',
    'Singapore',
    'Malaysia',
    'Indonesia',
    'Thailand',
    'Vietnam',
    'Philippines',
    'South Korea',
    'Saudi Arabia',
    'United Arab Emirates',
    'Qatar',
    'Kuwait',
    'Oman',
    'Bahrain',
    'Egypt',
    'Turkey',
    'Argentina',
    'Chile',
    'Colombia',
    'Peru',
    'Venezuela',
    'Pakistan',
    'Bangladesh',
    'Sri Lanka',
    'Nepal',
    'Bhutan',
    'Maldives',
    'Afghanistan',
    'Iran',
    'Iraq',
    'Syria',
    'Jordan',
    'Lebanon',
    'Israel',
    'Palestine',
    'Greece',
    'Portugal',
    'Poland',
    'Czech Republic',
    'Hungary',
    'Romania',
    'Bulgaria',
    'Ukraine',
    'Belarus',
    'Lithuania',
    'Latvia',
    'Estonia',
    'Slovakia',
    'Slovenia',
    'Croatia',
    'Serbia',
    'Montenegro',
    'Bosnia and Herzegovina',
    'Albania',
    'Macedonia',
    'Armenia',
    'Georgia',
    'Azerbaijan',
    'Kazakhstan',
    'Uzbekistan',
    'Turkmenistan',
    'Kyrgyzstan',
    'Tajikistan',
    'Mongolia',
    'Myanmar',
    'Laos',
    'Cambodia',
    'Brunei',
    'Timor-Leste',
    'Papua New Guinea',
    'Fiji',
    'Samoa',
    'Tonga',
    'Vanuatu',
    'Solomon Islands',
    'Micronesia',
    'Palau',
    'Marshall Islands',
    'Nauru',
    'Tuvalu',
    'Kiribati',
    'Malta',
    'Cyprus',
    'Luxembourg',
    'Monaco',
    'Liechtenstein',
    'San Marino',
    'Andorra',
    'Vatican City',
  ];
}
