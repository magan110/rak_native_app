import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class UaePhoneUtils {
  static const String countryPrefix = '+971 ';
  static const String localHint = '5XXXXXXXX';
  static const int localDigits = 9;
  static final RegExp _phoneLabelPattern = RegExp(
    r'\b(mobile|phone)\b|contact\s*(number|no\.?|mobile|phone)',
    caseSensitive: false,
  );

  static bool isPhoneField({
    TextInputType? keyboardType,
    bool isPhone = false,
    String? label,
    String? hint,
  }) {
    if (isPhone || keyboardType == TextInputType.phone) {
      return true;
    }

    final combinedText = '${label ?? ''} ${hint ?? ''}'.trim();
    return combinedText.isNotEmpty && _phoneLabelPattern.hasMatch(combinedText);
  }

  static List<TextInputFormatter> inputFormatters({
    List<TextInputFormatter>? additional,
  }) {
    return [
      FilteringTextInputFormatter.digitsOnly,
      LengthLimitingTextInputFormatter(localDigits),
      ...?additional,
    ];
  }

  static String? validate(String? value, {bool required = false}) {
    final digits = (value ?? '').replaceAll(RegExp(r'\D'), '');

    if (required && digits.isEmpty) {
      return 'Mobile number is required';
    }

    if (digits.isNotEmpty && digits.length != localDigits) {
      return 'Mobile number must be $localDigits digits';
    }

    return null;
  }
}
