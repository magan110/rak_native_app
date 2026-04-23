import 'dart:convert';
import 'dart:io';

import 'package:http/http.dart' as http;

import '../config/gemini_config.dart';

/// OCR service powered by Google Gemini.
///
/// This service is designed to be the *primary* OCR engine for
/// Emirates ID, bank documents and VAT certificates.
/// Existing ML Kit based services should be used as a fallback.
class GeminiOcrService {
  /// Extract Emirates ID fields from front and back images/PDFs.
  ///
  /// Expected output keys (all optional, values may be null):
  /// - id
  /// - name
  /// - dob (DD/MM/YYYY)
  /// - nationality
  /// - issue (DD/MM/YYYY)
  /// - expiry (DD/MM/YYYY)
  /// - employer
  /// - occupation
  Future<Map<String, String?>> extractEmiratesIdFields({
    required String frontImagePath,
    required String backImagePath,
  }) async {
    final files = [
      File(frontImagePath),
      File(backImagePath),
    ];

    final systemPrompt = '''
You are an OCR extraction engine for UAE Emirates ID cards.
You will receive one or more images or PDFs representing the *front* and *back* of a single Emirates ID.

Your task:
- Read all text.
- Extract the following fields where possible.
- Return ONLY a single JSON object, with exactly these keys and string values or null:
  {
    "id": "XXX-XXXX-XXXXXXX-X or null",
    "name": "Full name in normal order or null",
    "dob": "DD/MM/YYYY or null",
    "nationality": "Country name in English or null",
    "issue": "Issue date DD/MM/YYYY or null",
    "expiry": "Expiry date DD/MM/YYYY or null",
    "employer": "Employer / sponsor / company name or null",
    "occupation": "Occupation / profession or null"
  }

Formatting rules:
- Dates must be normalised to DD/MM/YYYY when you can infer the year.
- Emirates ID number must keep dashes if present: 784-XXXX-XXXXXXX-X style.
- Do not add any extra keys or text outside the JSON.
''';

    final responseText = await _callGemini(
      files: files,
      systemPrompt: systemPrompt,
    );

    final json = _safeDecodeJsonObject(responseText);
    return json.map((key, value) => MapEntry(key, value?.toString()));
  }

  /// Extract bank details from a bank document (image or PDF).
  ///
  /// Expected keys:
  /// - accountHolder
  /// - iban
  /// - bankName
  /// - branchName
  /// - bankAddress
  Future<Map<String, String?>> extractBankDetailsFields({
    required String bankDocumentPath,
  }) async {
    final file = File(bankDocumentPath);

    final systemPrompt = '''
You are an OCR extraction engine for bank account proof documents (statements, letters, cheques, etc.).
You will receive an image or PDF of a bank document from a UAE bank.

Your task:
- Read all text.
- Extract these fields when present.
- Return ONLY a single JSON object with exactly these keys and string values or null:
  {
    "accountHolder": "Account holder / beneficiary name or null",
    "iban": "IBAN in AE##################### format (no spaces) or null",
    "bankName": "Bank name or null",
    "branchName": "Branch name or null",
    "bankAddress": "Branch address or null"
  }

Formatting rules:
- If you find an IBAN, normalise it to a continuous string without spaces (example: AE120260001082236435001).
- Prefer official bank/branch names as written in the document.
- Do not add any extra keys or text outside the JSON.
''';

    final responseText = await _callGemini(
      files: [file],
      systemPrompt: systemPrompt,
    );

    final json = _safeDecodeJsonObject(responseText);
    return json.map((key, value) => MapEntry(key, value?.toString()));
  }

  /// Extract VAT certificate details from an image/PDF.
  ///
  /// Expected keys:
  /// - firmName
  /// - taxNumber
  /// - registeredAddress
  /// - effectiveDate
  Future<Map<String, String?>> extractVatCertificateFields({
    required String vatCertificatePath,
  }) async {
    final file = File(vatCertificatePath);

    final systemPrompt = '''
You are an OCR extraction engine for UAE VAT registration certificates.
You will receive an image or PDF of a VAT certificate.

Your task:
- Read all text.
- Extract these fields when present.
- Return ONLY a single JSON object with exactly these keys and string values or null:
  {
    "firmName": "Registered firm / legal name or null",
    "taxNumber": "Tax Registration Number (TRN) – 15 digits or null",
    "registeredAddress": "Registered address or null",
    "effectiveDate": "Effective/registration date DD/MM/YYYY or null"
  }

Formatting rules:
- Normalise dates to DD/MM/YYYY when you can infer the year.
- TRN must be 15 digits, numbers only, without spaces.
- Do not add any extra keys or text outside the JSON.
''';

    final responseText = await _callGemini(
      files: [file],
      systemPrompt: systemPrompt,
    );

    final json = _safeDecodeJsonObject(responseText);
    return json.map((key, value) => MapEntry(key, value?.toString()));
  }

  /// Extract Commercial License details from an image/PDF.
  ///
  /// Expected keys:
  /// - licenseNumber
  /// - issuingAuthority
  /// - licenseType
  /// - tradeName
  /// - responsiblePerson
  /// - establishmentDate
  /// - expiryDate
  /// - effectiveDate
  /// - licenseAddress
  Future<Map<String, String?>> extractCommercialLicenseFields({
    required String commercialLicensePath,
  }) async {
    final file = File(commercialLicensePath);

    final systemPrompt = '''
You are an OCR extraction engine for UAE Commercial/Trade License documents.
You will receive an image or PDF of a commercial license.

Your task:
- Read all text carefully.
- Extract these fields when present.
- Return ONLY a single JSON object with exactly these keys and string values or null:
  {
    "licenseNumber": "License/Registration number or null",
    "issuingAuthority": "Issuing authority/department or null",
    "licenseType": "Type of license or null",
    "tradeName": "Trade/Company name or null",
    "responsiblePerson": "Owner/Manager/Responsible person name or null",
    "establishmentDate": "Establishment/Issue date DD/MM/YYYY or null",
    "expiryDate": "Expiry date DD/MM/YYYY or null",
    "effectiveDate": "Effective/Registration date DD/MM/YYYY or null",
    "licenseAddress": "Business address or null"
  }

Formatting rules:
- Normalise all dates to DD/MM/YYYY format when you can infer the year.
- Keep license numbers exactly as shown in the document.
- Extract the full business/trade name as it appears.
- Do not add any extra keys or text outside the JSON.
''';

    final responseText = await _callGemini(
      files: [file],
      systemPrompt: systemPrompt,
    );

    final json = _safeDecodeJsonObject(responseText);
    return json.map((key, value) => MapEntry(key, value?.toString()));
  }

  // ======== Core Gemini HTTP helper ========

  Future<String> _callGemini({
    required List<File> files,
    required String systemPrompt,
  }) async {
    if (!GeminiConfig.isConfigured) {
      // This should normally be checked by the caller, but we log here as well
      // for easier debugging if it is ever hit accidentally.
      // ignore: avoid_print
      print('[GeminiOcrService] GeminiConfig.isConfigured == false, aborting call.');
      throw StateError('Gemini API is not configured. See GeminiConfig.');
    }

    if (files.isEmpty) {
      throw ArgumentError('At least one file is required for Gemini OCR.');
    }

    // ignore: avoid_print
    print(
      '[GeminiOcrService] Calling Gemini model "${GeminiConfig.MODEL}" '
      'with ${files.length} file(s).',
    );

    final uri = Uri.parse(
      'https://generativelanguage.googleapis.com/v1beta/models/${GeminiConfig.MODEL}:generateContent?key=${GeminiConfig.API_KEY}',
    );

    final parts = <Map<String, dynamic>>[
      {
        'text': systemPrompt,
      },
    ];

    for (final file in files) {
      if (!await file.exists()) {
        throw ArgumentError('File does not exist: ${file.path}');
      }
      final bytes = await file.readAsBytes();
      final base64Data = base64Encode(bytes);
      final mimeType = _guessMimeType(file.path);

      parts.add({
        'inlineData': {
          'mimeType': mimeType,
          'data': base64Data,
        },
      });
    }

    final body = jsonEncode({
      'contents': [
        {'parts': parts},
      ],
    });

    final response = await http.post(
      uri,
      headers: {
        'Content-Type': 'application/json',
      },
      body: body,
    );

    if (response.statusCode != 200) {
      // ignore: avoid_print
      print(
        '[GeminiOcrService] Gemini HTTP error '
        '${response.statusCode}: ${response.body}',
      );
      throw HttpException(
        'Gemini OCR request failed: ${response.statusCode} ${response.body}',
        uri: uri,
      );
    }

    final decoded = jsonDecode(response.body) as Map<String, dynamic>;
    final candidates = decoded['candidates'] as List<dynamic>?;
    if (candidates == null || candidates.isEmpty) {
      // ignore: avoid_print
      print('[GeminiOcrService] Gemini OCR returned no candidates.');
      throw StateError('Gemini OCR returned no candidates.');
    }

    final content = candidates.first['content'] as Map<String, dynamic>?;
    final contentParts = content?['parts'] as List<dynamic>?;
    if (contentParts == null || contentParts.isEmpty) {
      // ignore: avoid_print
      print('[GeminiOcrService] Gemini OCR returned empty content parts.');
      throw StateError('Gemini OCR returned empty content.');
    }

    // Concatenate any text parts into one string
    final buffer = StringBuffer();
    for (final part in contentParts) {
      final text = (part as Map<String, dynamic>)['text'] as String?;
      if (text != null && text.trim().isNotEmpty) {
        buffer.writeln(text);
      }
    }

    final resultText = buffer.toString().trim();
    if (resultText.isEmpty) {
      // ignore: avoid_print
      print('[GeminiOcrService] Gemini OCR returned empty text.');
      throw StateError('Gemini OCR returned empty text.');
    }

    // ignore: avoid_print
    print('[GeminiOcrService] Gemini OCR raw response text: $resultText');

    return resultText;
  }

  String _guessMimeType(String path) {
    final lower = path.toLowerCase();
    if (lower.endsWith('.png')) return 'image/png';
    if (lower.endsWith('.jpg') || lower.endsWith('.jpeg')) {
      return 'image/jpeg';
    }
    if (lower.endsWith('.pdf')) return 'application/pdf';
    // Fallback – Gemini is usually fine with generic octet-stream
    return 'application/octet-stream';
  }

  /// Extract a single JSON object from the model response and decode it.
  ///
  /// The model is instructed to return only JSON, but this method is defensive
  /// and will try to locate the first `{` and matching `}` block.
  Map<String, dynamic> _safeDecodeJsonObject(String text) {
    final trimmed = text.trim();
    int start = trimmed.indexOf('{');
    int end = trimmed.lastIndexOf('}');

    if (start == -1 || end <= start) {
      throw FormatException('Gemini OCR response did not contain JSON: $text');
    }

    final jsonSlice = trimmed.substring(start, end + 1);
    final decoded = jsonDecode(jsonSlice);
    if (decoded is Map<String, dynamic>) {
      return decoded;
    }
    throw FormatException('Gemini OCR JSON root is not an object.');
  }
}


