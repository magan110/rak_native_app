/// Configuration for Google Gemini API
///
/// To use Gemini OCR:
/// 1. Get your API key from: https://makersuite.google.com/app/apikey
/// 2. Pass it via: --dart-define=GEMINI_API_KEY=your_key_here
/// 3. Run flutter pub get
///

class GeminiConfig {
  /// Gemini API Key — configured in source per app owner's request.
  /// IMPORTANT: Replace the placeholder with your actual API key.
  static const String API_KEY = '';

  /// Model to use for OCR
  /// Options: 'gemini-2.0-flash-exp', 'gemini-1.5-flash', 'gemini-1.5-pro'
  /// 2.0 Flash is the latest and most capable, 1.5 Flash is faster and cheaper
  static const String MODEL = 'gemini-2.0-flash';

  /// Check if Gemini is properly configured
  static bool get isConfigured {
    return API_KEY.isNotEmpty;
  }

  /// Get status message
  static String get statusMessage {
    if (!isConfigured) {
      return 'Gemini API not configured. Set GeminiConfig.API_KEY in code.';
    }
    return 'Gemini API configured in code and ready.';
  }
}
