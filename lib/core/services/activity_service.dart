import '../models/activity_models.dart';
import '../network/api_client.dart';

class ActivityService {
  static const _areaPath = '/api/Activity/emirates-list';
  static const _submitPath = '/api/Activity/submit';

  static Future<List<AreaItem>> getAreas() async {
    final api = await ApiClient.getInstance();
    final data = await api.get(_areaPath);

    if (data is List) {
      return data.map((e) => AreaItem.fromJson(e)).toList();
    }

    throw Exception('Failed to load areas: unexpected response format');
  }

  static Future<ActivitySubmitResponse> submitActivity(
    ActivityEntryRequest req,
  ) async {
    try {
      final api = await ApiClient.getInstance();
      final data = await api.post(_submitPath, body: req.toJson());

      if (data is Map<String, dynamic>) {
        return ActivitySubmitResponse.fromJson(data);
      }
      return ActivitySubmitResponse(
        success: false,
        message: 'Unexpected response format',
      );
    } catch (e) {
      return ActivitySubmitResponse(
        success: false,
        message: 'Submit failed: $e',
      );
    }
  }

  static String formatMobile12(String? value) {
    if (value == null) return '';
    final cleaned = value.replaceAll(RegExp(r'[^0-9]'), '');
    if (cleaned.length <= 12) return cleaned;
    return cleaned.substring(cleaned.length - 12);
  }
}
