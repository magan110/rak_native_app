import 'package:flutter/foundation.dart';
import 'gemini_ocr_service.dart';
import '../config/gemini_config.dart';

/// OCR service that uses Gemini only (no ML Kit fallback).
/// This keeps the existing `HybridOcrService` API but delegates
/// all extraction to `GeminiOcrService` per user request.
class HybridOcrService {
  final _geminiOcrService = GeminiOcrService();

  /// Extract Emirates ID fields with Gemini first, fallback to ML Kit
  Future<Map<String, String?>> extractEmiratesIdFields({
    required String frontImagePath,
    required String backImagePath,
  }) async {
    // Use Gemini only
    if (!GeminiConfig.isConfigured) {
      throw StateError(
        'Gemini API not configured. Set GeminiConfig.API_KEY in code.',
      );
    }
    debugPrint('[HybridOCR] Delegating Emirates ID extraction to Gemini...');
    final result = await _geminiOcrService.extractEmiratesIdFields(
      frontImagePath: frontImagePath,
      backImagePath: backImagePath,
    );
    return result;
  }

  /// Extract bank details with Gemini first, fallback to ML Kit
  Future<Map<String, String?>> extractBankDetailsFields({
    required String bankDocumentPath,
  }) async {
    if (!GeminiConfig.isConfigured) {
      throw StateError(
        'Gemini API not configured. Set GeminiConfig.API_KEY in code.',
      );
    }
    debugPrint('[HybridOCR] Delegating bank details extraction to Gemini...');
    final result = await _geminiOcrService.extractBankDetailsFields(
      bankDocumentPath: bankDocumentPath,
    );
    return result;
  }

  /// Extract VAT certificate with Gemini first, fallback to ML Kit
  Future<Map<String, String?>> extractVatCertificateFields({
    required String vatCertificatePath,
  }) async {
    if (!GeminiConfig.isConfigured) {
      throw StateError(
        'Gemini API not configured. Set GeminiConfig.API_KEY in code.',
      );
    }
    debugPrint(
      '[HybridOCR] Delegating VAT certificate extraction to Gemini...',
    );
    final result = await _geminiOcrService.extractVatCertificateFields(
      vatCertificatePath: vatCertificatePath,
    );
    return result;
  }

  /// Extract Commercial License with Gemini first, fallback to ML Kit
  Future<Map<String, String?>> extractCommercialLicenseFields({
    required String commercialLicensePath,
  }) async {
    if (!GeminiConfig.isConfigured) {
      throw StateError(
        'Gemini API not configured. Set GeminiConfig.API_KEY in code.',
      );
    }
    debugPrint(
      '[HybridOCR] Delegating Commercial License extraction to Gemini...',
    );
    final result = await _geminiOcrService.extractCommercialLicenseFields(
      commercialLicensePath: commercialLicensePath,
    );
    return result;
  }

  /// Parse VAT certificate details from extracted text (ML Kit fallback)
  Map<String, String?> _parseVatCertificateFromText(String text) {
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

    for (int i = 0; i < lines.length; i++) {
      final line = lines[i];
      final lower = line.toLowerCase();

      // Firm Name
      if ((lower.contains('firm name') ||
              lower.contains('legal name') ||
              lower.contains('registered name')) &&
          result['firmName'] == null) {
        if (line.contains(':')) {
          result['firmName'] = line.split(':').skip(1).join(':').trim();
        } else if (i + 1 < lines.length) {
          result['firmName'] = lines[i + 1];
        }
        continue;
      }

      // Tax Registration Number (TRN)
      if ((lower.contains('trn') ||
              lower.contains('tax registration') ||
              lower.contains('tax number')) &&
          result['taxNumber'] == null) {
        final trnRegex = RegExp(r'\d{15}');
        final match = trnRegex.firstMatch(line);
        if (match != null) {
          result['taxNumber'] = match.group(0);
        } else if (i + 1 < lines.length) {
          final nextMatch = trnRegex.firstMatch(lines[i + 1]);
          if (nextMatch != null) {
            result['taxNumber'] = nextMatch.group(0);
          }
        }
        continue;
      }

      // Registered Address
      if ((lower.contains('registered address') || lower.contains('address')) &&
          result['registeredAddress'] == null) {
        List<String> addressParts = [];
        int startLine = lower.contains(':') ? i : i + 1;
        for (int j = startLine; j < lines.length && j < startLine + 3; j++) {
          final potentialAddressLine = lines[j];
          if (potentialAddressLine.length > 5) {
            addressParts.add(potentialAddressLine);
          }
        }
        if (addressParts.isNotEmpty) {
          result['registeredAddress'] = addressParts.join(', ');
        }
        continue;
      }

      // Effective Date
      if ((lower.contains('effective date') ||
              lower.contains('registration date')) &&
          result['effectiveDate'] == null) {
        final dateRegex = RegExp(r'\d{1,2}[/-]\d{1,2}[/-]\d{4}');
        final match = dateRegex.firstMatch(line);
        if (match != null) {
          result['effectiveDate'] = match.group(0)?.replaceAll('-', '/');
        } else if (i + 1 < lines.length) {
          final nextMatch = dateRegex.firstMatch(lines[i + 1]);
          if (nextMatch != null) {
            result['effectiveDate'] = nextMatch.group(0)?.replaceAll('-', '/');
          }
        }
        continue;
      }
    }

    return result;
  }

  /// Parse Commercial License details from extracted text (ML Kit fallback)
  Map<String, String?> _parseCommercialLicenseFromText(String text) {
    final result = <String, String?>{
      'licenseNumber': null,
      'issuingAuthority': null,
      'licenseType': null,
      'tradeName': null,
      'responsiblePerson': null,
      'establishmentDate': null,
      'expiryDate': null,
      'effectiveDate': null,
      'licenseAddress': null,
    };

    final lines = text
        .split('\n')
        .map((s) => s.trim())
        .where((s) => s.isNotEmpty)
        .toList();

    for (int i = 0; i < lines.length; i++) {
      final line = lines[i];
      final lower = line.toLowerCase();

      // License Number
      if ((lower.contains('license number') ||
              lower.contains('licence number') ||
              lower.contains('registration number')) &&
          result['licenseNumber'] == null) {
        if (line.contains(':')) {
          result['licenseNumber'] = line.split(':').skip(1).join(':').trim();
        } else if (i + 1 < lines.length) {
          result['licenseNumber'] = lines[i + 1];
        }
        continue;
      }

      // Issuing Authority
      if ((lower.contains('issuing authority') ||
              lower.contains('issued by') ||
              lower.contains('department')) &&
          result['issuingAuthority'] == null) {
        if (line.contains(':')) {
          result['issuingAuthority'] = line.split(':').skip(1).join(':').trim();
        } else if (i + 1 < lines.length) {
          result['issuingAuthority'] = lines[i + 1];
        }
        continue;
      }

      // License Type
      if ((lower.contains('license type') ||
              lower.contains('licence type') ||
              lower.contains('activity')) &&
          result['licenseType'] == null) {
        if (line.contains(':')) {
          result['licenseType'] = line.split(':').skip(1).join(':').trim();
        } else if (i + 1 < lines.length) {
          result['licenseType'] = lines[i + 1];
        }
        continue;
      }

      // Trade Name
      if ((lower.contains('trade name') ||
              lower.contains('company name') ||
              lower.contains('business name')) &&
          result['tradeName'] == null) {
        if (line.contains(':')) {
          result['tradeName'] = line.split(':').skip(1).join(':').trim();
        } else if (i + 1 < lines.length) {
          result['tradeName'] = lines[i + 1];
        }
        continue;
      }

      // Responsible Person
      if ((lower.contains('owner') ||
              lower.contains('manager') ||
              lower.contains('responsible person')) &&
          result['responsiblePerson'] == null) {
        if (line.contains(':')) {
          result['responsiblePerson'] = line
              .split(':')
              .skip(1)
              .join(':')
              .trim();
        } else if (i + 1 < lines.length) {
          result['responsiblePerson'] = lines[i + 1];
        }
        continue;
      }

      // Establishment Date
      if ((lower.contains('establishment date') ||
              lower.contains('issue date') ||
              lower.contains('issued on')) &&
          result['establishmentDate'] == null) {
        final dateRegex = RegExp(r'\d{1,2}[/-]\d{1,2}[/-]\d{4}');
        final match = dateRegex.firstMatch(line);
        if (match != null) {
          result['establishmentDate'] = match.group(0)?.replaceAll('-', '/');
        } else if (i + 1 < lines.length) {
          final nextMatch = dateRegex.firstMatch(lines[i + 1]);
          if (nextMatch != null) {
            result['establishmentDate'] = nextMatch
                .group(0)
                ?.replaceAll('-', '/');
          }
        }
        continue;
      }

      // Expiry Date
      if ((lower.contains('expiry date') ||
              lower.contains('valid until') ||
              lower.contains('expires on')) &&
          result['expiryDate'] == null) {
        final dateRegex = RegExp(r'\d{1,2}[/-]\d{1,2}[/-]\d{4}');
        final match = dateRegex.firstMatch(line);
        if (match != null) {
          result['expiryDate'] = match.group(0)?.replaceAll('-', '/');
        } else if (i + 1 < lines.length) {
          final nextMatch = dateRegex.firstMatch(lines[i + 1]);
          if (nextMatch != null) {
            result['expiryDate'] = nextMatch.group(0)?.replaceAll('-', '/');
          }
        }
        continue;
      }

      // Business Address
      if ((lower.contains('address') || lower.contains('location')) &&
          result['licenseAddress'] == null) {
        List<String> addressParts = [];
        int startLine = lower.contains(':') ? i : i + 1;
        for (int j = startLine; j < lines.length && j < startLine + 3; j++) {
          final potentialAddressLine = lines[j];
          if (potentialAddressLine.length > 5) {
            addressParts.add(potentialAddressLine);
          }
        }
        if (addressParts.isNotEmpty) {
          result['licenseAddress'] = addressParts.join(', ');
        }
        continue;
      }
    }

    return result;
  }
}
