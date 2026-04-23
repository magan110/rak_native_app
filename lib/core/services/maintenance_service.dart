import '../network/api_client.dart';

class MaintenanceService {
  static const String _maintenanceEndpoint = '/api/RakUnderMaintainance/status';

  /// Check if the app is under maintenance
  /// Returns MaintenanceStatus with the current status
  static Future<MaintenanceStatus> checkMaintenanceStatus() async {
    try {
      final api = await ApiClient.getInstance();
      final data = await api.get(_maintenanceEndpoint);

      if (data is Map<String, dynamic>) {
        return MaintenanceStatus(
          success: data['success'] ?? false,
          isRunning: data['running'] ?? false,
          message: data['message'] ?? 'Unknown status',
        );
      } else {
        return MaintenanceStatus(
          success: false,
          isRunning: false,
          message: 'Invalid response format',
        );
      }
    } catch (e) {
      return MaintenanceStatus(
        success: false,
        isRunning: false,
        message: 'Network error: Unable to check maintenance status',
      );
    }
  }
}

class MaintenanceStatus {
  final bool success;
  final bool isRunning;
  final String message;

  MaintenanceStatus({
    required this.success,
    required this.isRunning,
    required this.message,
  });

  bool get isUnderMaintenance => success && !isRunning;
  bool get canProceed => success && isRunning;
}