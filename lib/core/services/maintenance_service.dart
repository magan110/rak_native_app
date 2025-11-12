import 'dart:convert';
import 'package:http/http.dart' as http;
import '../config/api_config.dart';

class MaintenanceService {
  static const String _maintenanceEndpoint = '/api/RakUnderMaintainance/status';
  
  /// Check if the app is under maintenance
  /// Returns MaintenanceStatus with the current status
  static Future<MaintenanceStatus> checkMaintenanceStatus() async {
    try {
      final url = Uri.parse('${ApiConfig.baseUrl}$_maintenanceEndpoint');
      
      final response = await http.get(
        url,
        headers: ApiConfig.standardHeaders,
      ).timeout(ApiConfig.defaultTimeout);

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        
        return MaintenanceStatus(
          success: data['success'] ?? false,
          isRunning: data['running'] ?? false,
          message: data['message'] ?? 'Unknown status',
        );
      } else {
        return MaintenanceStatus(
          success: false,
          isRunning: false,
          message: 'Failed to check maintenance status',
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