/// Unified profile details model matching the ProfileDetailsController API
class ProfileDetails {
  // Keys
  final String? inflCode;
  final String? inflType;
  final String? isActive;
  
  // Names & Basic
  final String? inflName;
  final String? contName;
  final String? contractorType;
  final String? firstName;
  final String? middleName;
  final String? lastName;
  
  // Contact & Address
  final String? mobileNumber;
  final String? emailAddress;
  final String? address;
  final String? address2;
  final String? address3;
  final String? city;
  final String? district;
  final String? pinCode;
  final String? areaCode;
  final String? emirates;
  final String? reference;
  
  // Bank
  final String? bankAccountNo;
  final String? accountHolderName;
  final String? bankName;
  final String? branchName;
  final String? bankBranchNo;
  final String? bankIfscCode;
  final String? bankAddress;
  final String? ibanNumber;
  
  // VAT
  final String? firmName;
  final String? vatAddress;
  final String? taxRegistrationNumber;
  final String? vatEffectiveDate;
  
  // License
  final String? licenseNumber;
  final String? issuingAuthority;
  final String? licenseType;
  final String? establishmentDate;
  final String? licenseExpiryDate;
  final String? tradeName;
  final String? responsiblePerson;
  final String? licenseAddress;
  final String? effectiveDate;
  
  // Emirates ID / Painter
  final String? emiratesIdNumber;
  final String? idName;
  final String? nationality;
  final String? employer;
  final String? issueDate;
  final String? expiryDate;
  final String? occupation;
  
  // Audit
  final String? createId;
  final String? updateId;
  final String? createDt;
  final String? updateDt;

  ProfileDetails({
    this.inflCode,
    this.inflType,
    this.isActive,
    this.inflName,
    this.contName,
    this.contractorType,
    this.firstName,
    this.middleName,
    this.lastName,
    this.mobileNumber,
    this.emailAddress,
    this.address,
    this.address2,
    this.address3,
    this.city,
    this.district,
    this.pinCode,
    this.areaCode,
    this.emirates,
    this.reference,
    this.bankAccountNo,
    this.accountHolderName,
    this.bankName,
    this.branchName,
    this.bankBranchNo,
    this.bankIfscCode,
    this.bankAddress,
    this.ibanNumber,
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
    this.nationality,
    this.employer,
    this.issueDate,
    this.expiryDate,
    this.occupation,
    this.createId,
    this.updateId,
    this.createDt,
    this.updateDt,
  });

  factory ProfileDetails.fromJson(Map<String, dynamic> json) {
    return ProfileDetails(
      inflCode: json['inflCode']?.toString(),
      inflType: json['inflType']?.toString(),
      isActive: json['isActive']?.toString(),
      inflName: json['inflName']?.toString(),
      contName: json['contName']?.toString(),
      contractorType: json['contractorType']?.toString(),
      firstName: json['firstName']?.toString(),
      middleName: json['middleName']?.toString(),
      lastName: json['lastName']?.toString(),
      mobileNumber: json['mobileNumber']?.toString(),
      emailAddress: json['emailAddress']?.toString(),
      address: json['address']?.toString(),
      address2: json['address2']?.toString(),
      address3: json['address3']?.toString(),
      city: json['city']?.toString(),
      district: json['district']?.toString(),
      pinCode: json['pinCode']?.toString(),
      areaCode: json['areaCode']?.toString(),
      emirates: json['emirates']?.toString(),
      reference: json['reference']?.toString(),
      bankAccountNo: json['bankAccountNo']?.toString(),
      accountHolderName: json['accountHolderName']?.toString(),
      bankName: json['bankName']?.toString(),
      branchName: json['branchName']?.toString(),
      bankBranchNo: json['bankBranchNo']?.toString(),
      bankIfscCode: json['bankIfscCode']?.toString(),
      bankAddress: json['bankAddress']?.toString(),
      ibanNumber: json['ibanNumber']?.toString(),
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
      nationality: json['nationality']?.toString(),
      employer: json['employer']?.toString(),
      issueDate: json['issueDate']?.toString(),
      expiryDate: json['expiryDate']?.toString(),
      occupation: json['occupation']?.toString(),
      createId: json['createId']?.toString(),
      updateId: json['updateId']?.toString(),
      createDt: json['createDt']?.toString(),
      updateDt: json['updateDt']?.toString(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'inflCode': inflCode,
      'inflType': inflType,
      'isActive': isActive,
      'inflName': inflName,
      'contName': contName,
      'contractorType': contractorType,
      'firstName': firstName,
      'middleName': middleName,
      'lastName': lastName,
      'mobileNumber': mobileNumber,
      'emailAddress': emailAddress,
      'address': address,
      'address2': address2,
      'address3': address3,
      'city': city,
      'district': district,
      'pinCode': pinCode,
      'areaCode': areaCode,
      'emirates': emirates,
      'reference': reference,
      'bankAccountNo': bankAccountNo,
      'accountHolderName': accountHolderName,
      'bankName': bankName,
      'branchName': branchName,
      'bankBranchNo': bankBranchNo,
      'bankIfscCode': bankIfscCode,
      'bankAddress': bankAddress,
      'ibanNumber': ibanNumber,
      'firmName': firmName,
      'vatAddress': vatAddress,
      'taxRegistrationNumber': taxRegistrationNumber,
      'vatEffectiveDate': vatEffectiveDate,
      'licenseNumber': licenseNumber,
      'issuingAuthority': issuingAuthority,
      'licenseType': licenseType,
      'establishmentDate': establishmentDate,
      'licenseExpiryDate': licenseExpiryDate,
      'tradeName': tradeName,
      'responsiblePerson': responsiblePerson,
      'licenseAddress': licenseAddress,
      'effectiveDate': effectiveDate,
      'emiratesIdNumber': emiratesIdNumber,
      'idName': idName,
      'nationality': nationality,
      'employer': employer,
      'issueDate': issueDate,
      'expiryDate': expiryDate,
      'occupation': occupation,
      'createId': createId,
      'updateId': updateId,
      'createDt': createDt,
      'updateDt': updateDt,
    };
  }

  /// Check if this is a painter profile
  bool get isPainter => inflType?.toUpperCase() == 'PAINTER';

  /// Check if this is a contractor profile
  bool get isContractor => inflType?.toUpperCase() == 'CONTRACTOR';

  /// Get full name
  String get fullName {
    final parts = [firstName, middleName, lastName]
        .where((s) => s != null && s.isNotEmpty)
        .toList();
    return parts.join(' ');
  }
}

/// Response wrapper for profile details API
class ProfileDetailsResponse {
  final bool success;
  final String message;
  final ProfileDetails? data;

  ProfileDetailsResponse({
    required this.success,
    required this.message,
    this.data,
  });

  factory ProfileDetailsResponse.fromJson(Map<String, dynamic> json) {
    return ProfileDetailsResponse(
      success: json['success'] == true,
      message: json['message']?.toString() ?? '',
      data: json['data'] != null 
          ? ProfileDetails.fromJson(json['data'] as Map<String, dynamic>)
          : null,
    );
  }
}

/// Request model for updating profile (patch-like update)
/// Only non-null fields will be updated
class ProfileUpdateRequest {
  final String? contractorType;
  final String? firstName;
  final String? middleName;
  final String? lastName;
  final String? mobileNumber;
  final String? emailAddress;
  final String? address;
  final String? address2;
  final String? address3;
  final String? city;
  final String? district;
  final String? pinCode;
  final String? areaCode;
  final String? emirates;
  final String? reference;
  final String? bankAccountNo;
  final String? accountHolderName;
  final String? bankName;
  final String? branchName;
  final String? bankBranchNo;
  final String? bankIfscCode;
  final String? bankAddress;
  final String? ibanNumber;
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
  final String? emiratesIdNumber;
  final String? idName;
  final String? nationality;
  final String? employer;
  final String? issueDate;
  final String? expiryDate;
  final String? occupation;

  ProfileUpdateRequest({
    this.contractorType,
    this.firstName,
    this.middleName,
    this.lastName,
    this.mobileNumber,
    this.emailAddress,
    this.address,
    this.address2,
    this.address3,
    this.city,
    this.district,
    this.pinCode,
    this.areaCode,
    this.emirates,
    this.reference,
    this.bankAccountNo,
    this.accountHolderName,
    this.bankName,
    this.branchName,
    this.bankBranchNo,
    this.bankIfscCode,
    this.bankAddress,
    this.ibanNumber,
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
    this.nationality,
    this.employer,
    this.issueDate,
    this.expiryDate,
    this.occupation,
  });

  Map<String, dynamic> toJson() {
    final map = <String, dynamic>{};
    
    // Only include non-null values (patch-like update)
    if (contractorType != null) map['contractorType'] = contractorType;
    if (firstName != null) map['firstName'] = firstName;
    if (middleName != null) map['middleName'] = middleName;
    if (lastName != null) map['lastName'] = lastName;
    if (mobileNumber != null) map['mobileNumber'] = mobileNumber;
    if (emailAddress != null) map['emailAddress'] = emailAddress;
    if (address != null) map['address'] = address;
    if (address2 != null) map['address2'] = address2;
    if (address3 != null) map['address3'] = address3;
    if (city != null) map['city'] = city;
    if (district != null) map['district'] = district;
    if (pinCode != null) map['pinCode'] = pinCode;
    if (areaCode != null) map['areaCode'] = areaCode;
    if (emirates != null) map['emirates'] = emirates;
    if (reference != null) map['reference'] = reference;
    if (bankAccountNo != null) map['bankAccountNo'] = bankAccountNo;
    if (accountHolderName != null) map['accountHolderName'] = accountHolderName;
    if (bankName != null) map['bankName'] = bankName;
    if (branchName != null) map['branchName'] = branchName;
    if (bankBranchNo != null) map['bankBranchNo'] = bankBranchNo;
    if (bankIfscCode != null) map['bankIfscCode'] = bankIfscCode;
    if (bankAddress != null) map['bankAddress'] = bankAddress;
    if (ibanNumber != null) map['ibanNumber'] = ibanNumber;
    if (firmName != null) map['firmName'] = firmName;
    if (vatAddress != null) map['vatAddress'] = vatAddress;
    if (taxRegistrationNumber != null) map['taxRegistrationNumber'] = taxRegistrationNumber;
    if (vatEffectiveDate != null) map['vatEffectiveDate'] = vatEffectiveDate;
    if (licenseNumber != null) map['licenseNumber'] = licenseNumber;
    if (issuingAuthority != null) map['issuingAuthority'] = issuingAuthority;
    if (licenseType != null) map['licenseType'] = licenseType;
    if (establishmentDate != null) map['establishmentDate'] = establishmentDate;
    if (licenseExpiryDate != null) map['licenseExpiryDate'] = licenseExpiryDate;
    if (tradeName != null) map['tradeName'] = tradeName;
    if (responsiblePerson != null) map['responsiblePerson'] = responsiblePerson;
    if (licenseAddress != null) map['licenseAddress'] = licenseAddress;
    if (effectiveDate != null) map['effectiveDate'] = effectiveDate;
    if (emiratesIdNumber != null) map['emiratesIdNumber'] = emiratesIdNumber;
    if (idName != null) map['idName'] = idName;
    if (nationality != null) map['nationality'] = nationality;
    if (employer != null) map['employer'] = employer;
    if (issueDate != null) map['issueDate'] = issueDate;
    if (expiryDate != null) map['expiryDate'] = expiryDate;
    if (occupation != null) map['occupation'] = occupation;
    
    return map;
  }
}
