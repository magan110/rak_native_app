/// User Profile Models for OTP Login
/// These models represent the full user profile data returned by the backend

class UserProfileData {
  // Core information
  final String? inflCode;
  final String? inflType;
  final String? route;
  final String? areaCode;

  // Personal information
  final String? firstName;
  final String? middleName;
  final String? lastName;
  final String? mobileNumber;
  final String? address;
  final String? emirates;

  // Painter-specific fields
  final String? emiratesIdNumber;
  final String? idName;
  final String? nationality;
  final String? companyDetails;
  final String? issueDate;
  final String? expiryDate;
  final String? occupation;
  final String? bankAddress;

  // Contractor/shared fields
  final String? contractorType;
  final String? accountHolderName;
  final String? ibanNumber;
  final String? bankName;
  final String? branchName;

  // VAT information
  final String? firmName;
  final String? vatAddress;
  final String? taxRegistrationNumber;
  final String? vatEffectiveDate;

  // License information
  final String? licenseNumber;
  final String? issuingAuthority;
  final String? licenseType;
  final String? establishmentDate;
  final String? licenseExpiryDate;
  final String? tradeName;
  final String? responsiblePerson;
  final String? licenseAddress;
  final String? effectiveDate;

  UserProfileData({
    this.inflCode,
    this.inflType,
    this.route,
    this.areaCode,
    this.firstName,
    this.middleName,
    this.lastName,
    this.mobileNumber,
    this.address,
    this.emirates,
    this.emiratesIdNumber,
    this.idName,
    this.nationality,
    this.companyDetails,
    this.issueDate,
    this.expiryDate,
    this.occupation,
    this.bankAddress,
    this.contractorType,
    this.accountHolderName,
    this.ibanNumber,
    this.bankName,
    this.branchName,
    this.firmName,
    this.vatAddress,
    this.taxRegistrationNumber,
    this.vatEffectiveDate,
    this.licenseNumber,
    this.issuingAuthority,
    this.licenseType,
    this.establishmentDate,
    this.licenseExpiryDate,
    this.tradeName,
    this.responsiblePerson,
    this.licenseAddress,
    this.effectiveDate,
  });

  factory UserProfileData.fromJson(Map<String, dynamic> json) {
    return UserProfileData(
      inflCode: json['inflCode']?.toString(),
      inflType: json['inflType']?.toString(),
      route: json['route']?.toString(),
      areaCode: json['areaCode']?.toString(),
      firstName: json['firstName']?.toString(),
      middleName: json['middleName']?.toString(),
      lastName: json['lastName']?.toString(),
      mobileNumber: json['mobileNumber']?.toString(),
      address: json['address']?.toString(),
      emirates: json['emirates']?.toString(),
      emiratesIdNumber: json['emiratesIdNumber']?.toString(),
      idName: json['idName']?.toString(),
      nationality: json['nationality']?.toString(),
      companyDetails: json['companyDetails']?.toString(),
      issueDate: json['issueDate']?.toString(),
      expiryDate: json['expiryDate']?.toString(),
      occupation: json['occupation']?.toString(),
      bankAddress: json['bankAddress']?.toString(),
      contractorType: json['contractorType']?.toString(),
      accountHolderName: json['accountHolderName']?.toString(),
      ibanNumber: json['ibanNumber']?.toString(),
      bankName: json['bankName']?.toString(),
      branchName: json['branchName']?.toString(),
      firmName: json['firmName']?.toString(),
      vatAddress: json['vatAddress']?.toString(),
      taxRegistrationNumber: json['taxRegistrationNumber']?.toString(),
      vatEffectiveDate: json['vatEffectiveDate']?.toString(),
      licenseNumber: json['licenseNumber']?.toString(),
      issuingAuthority: json['issuingAuthority']?.toString(),
      licenseType: json['licenseType']?.toString(),
      establishmentDate: json['establishmentDate']?.toString(),
      licenseExpiryDate: json['licenseExpiryDate']?.toString(),
      tradeName: json['tradeName']?.toString(),
      responsiblePerson: json['responsiblePerson']?.toString(),
      licenseAddress: json['licenseAddress']?.toString(),
      effectiveDate: json['effectiveDate']?.toString(),
    );
  }

  /// Get full name combining first, middle, and last names
  String get fullName {
    final parts = [firstName, middleName, lastName]
        .where((part) => part != null && part.isNotEmpty)
        .toList();
    return parts.join(' ');
  }

  /// Check if this is a painter profile
  bool get isPainter => inflType?.toUpperCase() == 'PN';

  /// Check if this is a contractor profile
  bool get isContractor => !isPainter;

  /// Check if basic profile information is complete
  bool get isBasicProfileComplete {
    return firstName != null &&
        firstName!.isNotEmpty &&
        lastName != null &&
        lastName!.isNotEmpty &&
        mobileNumber != null &&
        mobileNumber!.isNotEmpty &&
        emirates != null &&
        emirates!.isNotEmpty;
  }

  /// Check if painter-specific profile is complete
  bool get isPainterProfileComplete {
    if (!isPainter) return true; // Not applicable for contractors
    
    return isBasicProfileComplete &&
        emiratesIdNumber != null &&
        emiratesIdNumber!.isNotEmpty &&
        nationality != null &&
        nationality!.isNotEmpty &&
        occupation != null &&
        occupation!.isNotEmpty;
  }

  /// Check if contractor-specific profile is complete
  bool get isContractorProfileComplete {
    if (isPainter) return true; // Not applicable for painters
    
    return isBasicProfileComplete &&
        contractorType != null &&
        contractorType!.isNotEmpty &&
        licenseNumber != null &&
        licenseNumber!.isNotEmpty &&
        issuingAuthority != null &&
        issuingAuthority!.isNotEmpty &&
        licenseType != null &&
        licenseType!.isNotEmpty;
  }

  /// Check if the overall profile is complete based on user type
  bool get isProfileComplete {
    return isPainter ? isPainterProfileComplete : isContractorProfileComplete;
  }

  /// Get list of missing required fields
  List<String> get missingRequiredFields {
    final missing = <String>[];

    // Basic fields
    if (firstName == null || firstName!.isEmpty) missing.add('First Name');
    if (lastName == null || lastName!.isEmpty) missing.add('Last Name');
    if (emirates == null || emirates!.isEmpty) missing.add('Emirates');

    if (isPainter) {
      // Painter-specific required fields
      if (emiratesIdNumber == null || emiratesIdNumber!.isEmpty) {
        missing.add('Emirates ID Number');
      }
      if (nationality == null || nationality!.isEmpty) {
        missing.add('Nationality');
      }
      if (occupation == null || occupation!.isEmpty) {
        missing.add('Occupation');
      }
    } else {
      // Contractor-specific required fields
      if (contractorType == null || contractorType!.isEmpty) {
        missing.add('Contractor Type');
      }
      if (licenseNumber == null || licenseNumber!.isEmpty) {
        missing.add('License Number');
      }
      if (issuingAuthority == null || issuingAuthority!.isEmpty) {
        missing.add('Issuing Authority');
      }
      if (licenseType == null || licenseType!.isEmpty) {
        missing.add('License Type');
      }
    }

    return missing;
  }
}

/// Response model for full profile API call
class SmsUaeFullProfileResponse {
  final bool success;
  final bool exists;
  final String? inflType;
  final String? route;
  final UserProfileData? data;
  final String? message;
  final int statusCode;

  SmsUaeFullProfileResponse({
    required this.success,
    required this.exists,
    this.inflType,
    this.route,
    this.data,
    this.message,
    required this.statusCode,
  });

  factory SmsUaeFullProfileResponse.fromJson(Map<String, dynamic> json) {
    return SmsUaeFullProfileResponse(
      success: json['success'] ?? false,
      exists: json['exists'] ?? false,
      inflType: json['inflType']?.toString(),
      route: json['route']?.toString(),
      data: json['data'] != null 
          ? UserProfileData.fromJson(json['data'] as Map<String, dynamic>)
          : null,
      message: json['message']?.toString(),
      statusCode: json['statusCode'] ?? 0,
    );
  }
}