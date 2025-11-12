import '../models/user_profile_models.dart';
import '../routes/route_names.dart';

/// Service to determine profile completion status and navigation logic
class ProfileCompletionService {
  
  /// Determine the appropriate screen to navigate to based on profile completeness
  static ProfileNavigationResult determineNavigationTarget(UserProfileData profile) {
    final missingFields = profile.missingRequiredFields;
    
    // Always navigate to home screen regardless of profile completeness
    final homeRoute = profile.isPainter 
        ? RouteNames.painterHome 
        : RouteNames.contractorHome;
    
    final isComplete = missingFields.isEmpty;
    
    return ProfileNavigationResult(
      targetRoute: homeRoute,
      isProfileComplete: isComplete,
      missingFields: missingFields,
      requiresUpdate: !isComplete,
      message: isComplete ? 'Welcome back!' : 'Profile has some incomplete fields',
    );
  }

  /// Check if specific fields are missing for painter profile
  static List<String> getMissingPainterFields(UserProfileData profile) {
    final missing = <String>[];
    
    // Basic required fields
    if (profile.firstName == null || profile.firstName!.isEmpty) {
      missing.add('First Name');
    }
    if (profile.lastName == null || profile.lastName!.isEmpty) {
      missing.add('Last Name');
    }
    if (profile.emirates == null || profile.emirates!.isEmpty) {
      missing.add('Emirates');
    }
    
    // Painter-specific required fields
    if (profile.emiratesIdNumber == null || profile.emiratesIdNumber!.isEmpty) {
      missing.add('Emirates ID Number');
    }
    if (profile.nationality == null || profile.nationality!.isEmpty) {
      missing.add('Nationality');
    }
    if (profile.occupation == null || profile.occupation!.isEmpty) {
      missing.add('Occupation');
    }
    
    return missing;
  }

  /// Check if specific fields are missing for contractor profile
  static List<String> getMissingContractorFields(UserProfileData profile) {
    final missing = <String>[];
    
    // Basic required fields
    if (profile.firstName == null || profile.firstName!.isEmpty) {
      missing.add('First Name');
    }
    if (profile.lastName == null || profile.lastName!.isEmpty) {
      missing.add('Last Name');
    }
    if (profile.emirates == null || profile.emirates!.isEmpty) {
      missing.add('Emirates');
    }
    
    // Contractor-specific required fields
    if (profile.contractorType == null || profile.contractorType!.isEmpty) {
      missing.add('Contractor Type');
    }
    if (profile.licenseNumber == null || profile.licenseNumber!.isEmpty) {
      missing.add('License Number');
    }
    if (profile.issuingAuthority == null || profile.issuingAuthority!.isEmpty) {
      missing.add('Issuing Authority');
    }
    if (profile.licenseType == null || profile.licenseType!.isEmpty) {
      missing.add('License Type');
    }
    
    return missing;
  }

  /// Get completion percentage for profile
  static double getCompletionPercentage(UserProfileData profile) {
    final totalRequiredFields = profile.isPainter ? 6 : 7; // Adjust based on requirements
    final missingFields = profile.missingRequiredFields.length;
    final completedFields = totalRequiredFields - missingFields;
    
    return (completedFields / totalRequiredFields) * 100;
  }

  /// Get user-friendly completion status message
  static String getCompletionStatusMessage(UserProfileData profile) {
    final percentage = getCompletionPercentage(profile);
    
    if (percentage == 100) {
      return 'Profile is complete';
    } else if (percentage >= 80) {
      return 'Profile is almost complete';
    } else if (percentage >= 50) {
      return 'Profile is partially complete';
    } else {
      return 'Profile needs completion';
    }
  }
}

/// Result class for profile navigation logic
class ProfileNavigationResult {
  final String targetRoute;
  final bool isProfileComplete;
  final List<String> missingFields;
  final bool requiresUpdate;
  final String message;

  ProfileNavigationResult({
    required this.targetRoute,
    required this.isProfileComplete,
    required this.missingFields,
    required this.requiresUpdate,
    required this.message,
  });

  /// Get extra parameters to pass with navigation
  Map<String, dynamic> getNavigationExtras(UserProfileData profile, String mobileNumber) {
    return {
      'userProfile': profile,
      'mobileNumber': mobileNumber,
      'isNewRegistration': false,
      'userRole': profile.isPainter ? 'PAINTER' : 'CONTRACTOR',
      'requiresUpdate': requiresUpdate,
      'missingFields': missingFields,
      'completionMessage': message,
    };
  }
}