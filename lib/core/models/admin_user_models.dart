/// Admin User Models for User Management
/// These models handle fetching and updating user data by registration ID
library;

class AdminUserData {
  // Core information
  final String? inflCode;
  final String? areaCode;
  final String? inflType;
  final String? inflName;
  final String? contName;

  // Name cluster
  final String? firstName;
  final String? middleName;
  final String? lastName;

  // Address / contact
  final String? address1;
  final String? address2;
  final String? address3;
  final String? city;
  final String? district;
  final String? pincode;
  final String? emirates;
  final String? mobileNumber;
  final String? email;

  // Bank details
  final String? accountHolderName;
  final String? ibanNumber;
  final String? bankName;
  final String? branchName;
  final String? bankAddress;
  final String? bankAccountNo;
  final String? bankIFSC;

  // VAT / license / extras
  final String? firmName;
  final String? vatAddress;
  final String? taxRegistrationNumber;
  final String? vatEffectiveDate;
  final String? licenseNumber;
  final String? issuingAuthority;
  final String? licenseType;
  final String? establishmentDate;
  final String? licenseExpiryDate;
  final String? tradeName;
  final String? responsiblePerson;
  final String? licenseAddress;
  final String? effectiveDate;

  // ID/KYC
  final String? emiratesIdNumber;
  final String? idName;
  final String? idHolder;  // idholder field from API
  final String? nationality;
  final String? employer;
  final String? issueDate;
  final String? expiryDate;
  final String? occupation;
  final String? contractorType;
  final String? reference;
  final String? kycVerifiedFlag;
  final String? kycVerifiedDate;
  final String? idCardType;
  final String? idCardNo;
  final String? kycVerifyType;
  final String? inDocCount;
  final String? rejectRemark;

  // Misc
  final String? dateOfBirth;
  final String? businessStartYear;
  final String? qualification;
  final String? expertise;
  final String? workerDetail;
  final String? anniversaryDate;
  final String? landline;
  final String? isActive;
  final String? createId;
  final String? createDate;
  final String? updateId;
  final String? updateDate;

  AdminUserData({
    this.inflCode,
    this.areaCode,
    this.inflType,
    this.inflName,
    this.contName,
    this.firstName,
    this.middleName,
    this.lastName,
    this.address1,
    this.address2,
    this.address3,
    this.city,
    this.district,
    this.pincode,
    this.emirates,
    this.mobileNumber,
    this.email,
    this.accountHolderName,
    this.ibanNumber,
    this.bankName,
    this.branchName,
    this.bankAddress,
    this.bankAccountNo,
    this.bankIFSC,
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
    this.emiratesIdNumber,
    this.idName,
    this.idHolder,
    this.nationality,
    this.employer,
    this.issueDate,
    this.expiryDate,
    this.occupation,
    this.contractorType,
    this.reference,
    this.kycVerifiedFlag,
    this.kycVerifiedDate,
    this.idCardType,
    this.idCardNo,
    this.kycVerifyType,
    this.inDocCount,
    this.rejectRemark,
    this.dateOfBirth,
    this.businessStartYear,
    this.qualification,
    this.expertise,
    this.workerDetail,
    this.anniversaryDate,
    this.landline,
    this.isActive,
    this.createId,
    this.createDate,
    this.updateId,
    this.updateDate,
  });

  factory AdminUserData.fromJson(Map<String, dynamic> json) {
    // The API returns data with camelCase field names (UseUpdateView format)
    return AdminUserData(
      inflCode: json['inflCode']?.toString(),
      areaCode: json['areaCode']?.toString(),
      inflType: json['inflType']?.toString(),
      inflName: json['inflName']?.toString(),
      contName: json['contName']?.toString(),
      firstName: json['firstName']?.toString(),
      middleName: json['middleName']?.toString(),
      lastName: json['lastName']?.toString(),
      address1: json['address']?.toString(),
      address2: json['address2']?.toString(),
      address3: json['address3']?.toString(),
      city: json['city']?.toString(),
      district: json['district']?.toString(),
      pincode: json['pinCode']?.toString(),
      emirates: json['emirates']?.toString(),
      mobileNumber: json['mobileNumber']?.toString(),
      email: json['emailAddress']?.toString(),
      accountHolderName: json['accountHolderName']?.toString(),
      ibanNumber: json['ibanNumber']?.toString(),
      bankName: json['bankName']?.toString(),
      branchName: json['branchName']?.toString(),
      bankAddress: json['bankAddress']?.toString(),
      bankAccountNo: json['bankAccountNo']?.toString(),
      bankIFSC: json['bankIfscCode']?.toString(),
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
      emiratesIdNumber: json['emiratesIdNumber']?.toString(),
      idName: json['idName']?.toString(),
      idHolder: json['idholder']?.toString(),
      nationality: json['nationality']?.toString(),
      employer: json['employer']?.toString(),
      issueDate: json['issueDate']?.toString(),
      expiryDate: json['expiryDate']?.toString(),
      occupation: json['occupation']?.toString(),
      contractorType: json['contractorType']?.toString(),
      reference: json['reference']?.toString(),
      // These fields are not in the current API
      kycVerifiedFlag: null,
      kycVerifiedDate: null,
      idCardType: null,
      idCardNo: null,
      kycVerifyType: null,
      inDocCount: null,
      rejectRemark: null,
      dateOfBirth: null,
      businessStartYear: null,
      qualification: null,
      expertise: null,
      workerDetail: null,
      anniversaryDate: null,
      landline: null,
      isActive: json['isActive']?.toString(),
      createId: json['createId']?.toString(),
      createDate: json['createDt']?.toString(),
      updateId: json['updateId']?.toString(),
      updateDate: json['updateDt']?.toString(),
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
  bool get isContractor => inflType?.toUpperCase() == '2IK';

  /// Get user type display name
  String get userTypeDisplay {
    if (isPainter) return 'Painter';
    if (isContractor) return 'Contractor';
    return inflType ?? 'Unknown';
  }

  /// Convert to update request format - matches UseUpdatePatch exactly
  Map<String, dynamic> toUpdateJson({String? loginId}) {
    final Map<String, dynamic> json = {};
    
    // Helper function to check if value is valid (not null, not empty, and not "{}")
    bool isValid(String? value) {
      if (value == null) return false;
      final trimmed = value.trim();
      return trimmed.isNotEmpty && trimmed != '{}' && trimmed != 'null';
    }
    
    // Add loginId if provided
    if (isValid(loginId)) {
      json['loginId'] = loginId;
    }
    
    // Match the API's UseUpdatePatch field names exactly
    if (isValid(firstName)) json['FirstName'] = firstName;
    if (isValid(middleName)) json['MiddleName'] = middleName;
    if (isValid(lastName)) json['LastName'] = lastName;
    if (isValid(mobileNumber)) json['MobileNumber'] = mobileNumber;
    if (isValid(email)) json['EmailAddress'] = email;
    if (isValid(address1)) json['Address'] = address1;
    if (isValid(address2)) json['Address2'] = address2;
    if (isValid(address3)) json['Address3'] = address3;
    if (isValid(city)) json['City'] = city;
    if (isValid(district)) json['District'] = district;
    if (isValid(pincode)) json['PinCode'] = pincode;
    if (isValid(areaCode)) json['AreaCode'] = areaCode;
    if (isValid(emirates)) json['Emirates'] = emirates;
    
    if (isValid(bankAccountNo)) json['BankAccountNo'] = bankAccountNo;
    if (isValid(accountHolderName)) json['AccountHolderName'] = accountHolderName;
    if (isValid(bankName)) json['BankName'] = bankName;
    if (isValid(branchName)) json['BranchName'] = branchName;
    if (isValid(bankAddress)) json['BankAddress'] = bankAddress;
    if (isValid(bankIFSC)) json['BankIfscCode'] = bankIFSC;
    if (isValid(ibanNumber)) json['IbanNumber'] = ibanNumber;
    
    if (isValid(firmName)) json['FirmName'] = firmName;
    if (isValid(vatAddress)) json['VatAddress'] = vatAddress;
    if (isValid(taxRegistrationNumber)) json['TaxRegistrationNumber'] = taxRegistrationNumber;
    if (isValid(vatEffectiveDate)) json['VatEffectiveDate'] = vatEffectiveDate;
    
    if (isValid(licenseNumber)) json['LicenseNumber'] = licenseNumber;
    if (isValid(issuingAuthority)) json['IssuingAuthority'] = issuingAuthority;
    if (isValid(licenseType)) json['LicenseType'] = licenseType;
    if (isValid(establishmentDate)) json['EstablishmentDate'] = establishmentDate;
    if (isValid(licenseExpiryDate)) json['LicenseExpiryDate'] = licenseExpiryDate;
    if (isValid(tradeName)) json['TradeName'] = tradeName;
    if (isValid(responsiblePerson)) json['ResponsiblePerson'] = responsiblePerson;
    if (isValid(licenseAddress)) json['LicenseAddress'] = licenseAddress;
    if (isValid(effectiveDate)) json['EffectiveDate'] = effectiveDate;
    
    if (isValid(emiratesIdNumber)) json['EmiratesIdNumber'] = emiratesIdNumber;
    if (isValid(idName)) json['IdName'] = idName;
    if (isValid(nationality)) json['Nationality'] = nationality;
    if (isValid(employer)) json['Employer'] = employer;
    if (isValid(issueDate)) json['IssueDate'] = issueDate;
    if (isValid(expiryDate)) json['ExpiryDate'] = expiryDate;
    if (isValid(occupation)) json['Occupation'] = occupation;
    if (isValid(contractorType)) json['ContractorType'] = contractorType;
    if (isValid(reference)) json['Reference'] = reference;
    
    return json;
  }
}

/// Response model for admin user fetch
class AdminUserResponse {
  final bool success;
  final String? message;
  final AdminUserData? data;

  AdminUserResponse({
    required this.success,
    this.message,
    this.data,
  });

  factory AdminUserResponse.fromJson(Map<String, dynamic> json) {
    return AdminUserResponse(
      success: json['success'] ?? false,
      message: json['message']?.toString(),
      data: json['data'] != null 
          ? AdminUserData.fromJson(json['data'] as Map<String, dynamic>)
          : null,
    );
  }
}

/// Response model for admin user update
class AdminUserUpdateResponse {
  final bool success;
  final String? message;
  final AdminUserData? data;

  AdminUserUpdateResponse({
    required this.success,
    this.message,
    this.data,
  });

  factory AdminUserUpdateResponse.fromJson(Map<String, dynamic> json) {
    return AdminUserUpdateResponse(
      success: json['success'] ?? false,
      message: json['message']?.toString(),
      data: json['data'] != null 
          ? AdminUserData.fromJson(json['data'] as Map<String, dynamic>)
          : null,
    );
  }
}

/// Search suggestion item model
class UserSearchSuggestion {
  final String value;      // inflCode (registration ID)
  final String label;      // display name
  final String? subLabel;  // additional info (mobile, area, type)

  UserSearchSuggestion({
    required this.value,
    required this.label,
    this.subLabel,
  });

  factory UserSearchSuggestion.fromJson(Map<String, dynamic> json) {
    return UserSearchSuggestion(
      value: json['value']?.toString() ?? '',
      label: json['label']?.toString() ?? '',
      subLabel: json['subLabel']?.toString(),
    );
  }
}

/// Response model for user search suggestions
class UserSearchResponse {
  final bool success;
  final String? message;
  final List<UserSearchSuggestion> data;

  UserSearchResponse({
    required this.success,
    this.message,
    required this.data,
  });

  factory UserSearchResponse.fromJson(Map<String, dynamic> json) {
    final List<UserSearchSuggestion> suggestions = [];
    
    if (json['data'] is List) {
      for (final item in json['data'] as List) {
        if (item is Map<String, dynamic>) {
          suggestions.add(UserSearchSuggestion.fromJson(item));
        }
      }
    }

    return UserSearchResponse(
      success: json['success'] ?? false,
      message: json['message']?.toString(),
      data: suggestions,
    );
  }
}