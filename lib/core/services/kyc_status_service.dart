import '../models/kyc_status_models.dart';
import '../network/api_client.dart';

class KycStatusService {
  static Future<KycStatusResponse> getKycStatusByMobile(String mobileNumber) async {
    try {
      final api = await ApiClient.getInstance();
      final data = await api.get('/api/KycStatus/mobile/$mobileNumber');

      if (data is Map<String, dynamic>) {
        return KycStatusResponse.fromJson(data);
      } else {
        throw Exception('Invalid response format');
      }
    } catch (e) {
      // Handle 404 as "not found" instead of error
      if (e.toString().contains('404')) {
        return KycStatusResponse(
          success: false,
          inflCode: '',
          inflName: '',
          status: 'NOT_FOUND',
          statusText: 'Not Found',
          message: 'No record found for given mobile number.',
        );
      }
      throw Exception('Error fetching KYC status: $e');
    }
  }
}
