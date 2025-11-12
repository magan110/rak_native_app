import 'package:flutter/material.dart';
import 'lib/core/services/maintenance_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  print('🔍 Testing Maintenance Service...');
  
  try {
    final status = await MaintenanceService.checkMaintenanceStatus();
    
    print('✅ Maintenance Status Check Results:');
    print('   Success: ${status.success}');
    print('   Is Running: ${status.isRunning}');
    print('   Message: ${status.message}');
    print('   Is Under Maintenance: ${status.isUnderMaintenance}');
    print('   Can Proceed: ${status.canProceed}');
    
    if (status.isUnderMaintenance) {
      print('🚫 App should show maintenance dialog and stop');
    } else if (status.canProceed) {
      print('✅ App can proceed normally');
    } else {
      print('⚠️ Maintenance check failed, but app should continue');
    }
    
  } catch (e) {
    print('❌ Error testing maintenance service: $e');
  }
}