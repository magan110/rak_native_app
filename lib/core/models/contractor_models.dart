class EmirateItem {
  final String code;
  final String desc;

  EmirateItem({required this.code, required this.desc});

  factory EmirateItem.fromJson(Map<String, dynamic> json) {
    return EmirateItem(
      code: (json['code'] ?? json['areaCode'] ?? '').toString().trim(),
      desc: (json['desc'] ?? json['areaDesc'] ?? '').toString().trim(),
    );
  }

  @override
  String toString() => desc;

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is EmirateItem && other.code == code && other.desc == desc;
  }

  @override
  int get hashCode => code.hashCode ^ desc.hashCode;
}

class ContractorRegistrationRequest {
  // Personal Details (Mandatory)
  final String? contractorType;
  final String? firstName;
  final String? middleName;
  final String? lastName;
  final String? mobileNumber; // 9-digit UAE format (50,52,54,55,56,58)
  final String? address; // Address-1
  final String? area; // Area code from emirates selection
  final String? emirates;
  final String? profilePhoto; // Upload/Click
  final String? password; // User password

  // Contractor Certificate (Mandatory)
  final String? contractorCertificate;

  // Bank Details (Mandatory)
  final String? accountHolderName;
  final String? ibanNumber;
  final String? bankName;
  final String? branchName;
  final String? bankAddress;
  final String? bankDocument;

  // VAT Certificate (Non-Mandatory for turnover below 375,000 AED)
  final String? vatCertificate; // Document upload
  final String? firmName; // Name of the Firm
  final String? vatAddress; // Registered Address
  final String?
  taxRegistrationNumber; // XXX-XXXXXXXXX-XXX (15 digits total, numeric only)
  final String? vatEffectiveDate; // Effective Registration Date

  // Commercial License (Mandatory)
  final String? licenseDocument; // License upload
  final String? licenseNumber;
  final String? issuingAuthority;
  final String? licenseType;
  final String? establishmentDate;
  final String? licenseExpiryDate;
  final String? tradeName;
  final String? responsiblePerson;
  final String? licenseAddress; // Registered Address
  final String? effectiveDate; // Effective Registration Date

  ContractorRegistrationRequest({
    // Personal Details (Mandatory)
    this.contractorType,
    this.firstName,
    this.middleName,
    this.lastName,
    this.mobileNumber,
    this.address,
    this.area,
    this.emirates,
    this.profilePhoto,
    this.password,

    // Contractor Certificate (Mandatory)
    this.contractorCertificate,

    // Bank Details (Mandatory)
    this.accountHolderName,
    this.ibanNumber,
    this.bankName,
    this.branchName,
    this.bankAddress,
    this.bankDocument,

    // VAT Certificate (Non-Mandatory)
    this.vatCertificate,
    this.firmName,
    this.vatAddress,
    this.taxRegistrationNumber,
    this.vatEffectiveDate,

    // Commercial License (Mandatory)
    this.licenseDocument,
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

  // helper: empty string if null/blank
  String _empty(String? v) => (v == null || v.trim().isEmpty) ? '' : v.trim();

  Map<String, dynamic> toJson() {
    return {
      // Personal Details (Mandatory)
      "contractorType": _empty(contractorType),
      "firstName": _empty(firstName),
      "middleName": _empty(middleName),
      "lastName": _empty(lastName),
      "mobileNumber": _empty(mobileNumber),
      "address": _empty(address),
      "area": _empty(area),
      "emirates": _empty(emirates),
      "profilePhoto": _empty(profilePhoto),
      "password": _empty(password),

      // Contractor Certificate (Mandatory)
      "contractorCertificate": _empty(contractorCertificate),

      // Bank Details (Mandatory)
      "accountHolderName": _empty(accountHolderName),
      "ibanNumber": _empty(ibanNumber),
      "bankName": _empty(bankName),
      "branchName": _empty(branchName),
      "bankAddress": _empty(bankAddress),
      "bankDocument": _empty(bankDocument),

      // VAT Certificate (Non-Mandatory)
      "vatCertificate": _empty(vatCertificate),
      "firmName": _empty(firmName),
      "vatAddress": _empty(vatAddress),
      "taxRegistrationNumber": _empty(taxRegistrationNumber),
      "vatEffectiveDate": _empty(vatEffectiveDate),

      // Commercial License (Mandatory)
      "licenseDocument": _empty(licenseDocument),
      "licenseNumber": _empty(licenseNumber),
      "issuingAuthority": _empty(issuingAuthority),
      "licenseType": _empty(licenseType),
      "establishmentDate": _empty(establishmentDate),
      "licenseExpiryDate": _empty(licenseExpiryDate),
      "tradeName": _empty(tradeName),
      "responsiblePerson": _empty(responsiblePerson),
      "licenseAddress": _empty(licenseAddress),
      "effectiveDate": _empty(effectiveDate),
    };
  }
}

class ContractorRegistrationResponse {
  final bool success;
  final String message;
  final String?
  contractorId; // API returns influencerCode or contractorId; handle both
  final String? influencerCode;

  ContractorRegistrationResponse({
    required this.success,
    required this.message,
    this.contractorId,
    this.influencerCode,
  });

  factory ContractorRegistrationResponse.fromJson(Map<String, dynamic> json) {
    return ContractorRegistrationResponse(
      success: json['success'] == true,
      message: (json['message'] ?? '').toString(),
      contractorId: json['contractorId']?.toString(),
      influencerCode: json['influencerCode']?.toString(),
    );
  }
}

class MobileDuplicateCheckResponse {
  final bool success;
  final bool exists;
  final String message;

  MobileDuplicateCheckResponse({
    required this.success,
    required this.exists,
    required this.message,
  });

  factory MobileDuplicateCheckResponse.fromJson(Map<String, dynamic> json) {
    return MobileDuplicateCheckResponse(
      success: json['success'] == true,
      exists: json['exists'] == true,
      message: (json['message'] ?? '').toString(),
    );
  }
}

class ContractorDetailsResponse {
  final bool success;
  final String message;
  final ContractorDetails? data;

  ContractorDetailsResponse({
    required this.success,
    required this.message,
    this.data,
  });

  factory ContractorDetailsResponse.fromJson(Map<String, dynamic> json) {
    return ContractorDetailsResponse(
      success: json['success'] == true,
      message: (json['message'] ?? '').toString(),
      data: json['data'] != null ? ContractorDetails.fromJson(json['data']) : null,
    );
  }
}

class ContractorDetails {
  final String? contractorType;
  final String? firstName;
  final String? middleName;
  final String? lastName;
  final String? mobileNumber;
  final String? address;
  final String? area;
  final String? emirates;
  final String? profilePhoto;
  final String? contractorCertificate;
  final String? accountHolderName;
  final String? ibanNumber;
  final String? bankName;
  final String? branchName;
  final String? bankAddress;
  final String? bankDocument;
  final String? vatCertificate;
  final String? firmName;
  final String? vatAddress;
  final String? taxRegistrationNumber;
  final String? vatEffectiveDate;
  final String? licenseDocument;
  final String? licenseNumber;
  final String? issuingAuthority;
  final String? licenseType;
  final String? establishmentDate;
  final String? licenseExpiryDate;
  final String? tradeName;
  final String? responsiblePerson;
  final String? licenseAddress;
  final String? effectiveDate;

  ContractorDetails({
    this.contractorType,
    this.firstName,
    this.middleName,
    this.lastName,
    this.mobileNumber,
    this.address,
    this.area,
    this.emirates,
    this.profilePhoto,
    this.contractorCertificate,
    this.accountHolderName,
    this.ibanNumber,
    this.bankName,
    this.branchName,
    this.bankAddress,
    this.bankDocument,
    this.vatCertificate,
    this.firmName,
    this.vatAddress,
    this.taxRegistrationNumber,
    this.vatEffectiveDate,
    this.licenseDocument,
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

  factory ContractorDetails.fromJson(Map<String, dynamic> json) {
    return ContractorDetails(
      contractorType: json['contractorType']?.toString(),
      firstName: json['firstName']?.toString(),
      middleName: json['middleName']?.toString(),
      lastName: json['lastName']?.toString(),
      mobileNumber: json['mobileNumber']?.toString(),
      address: json['address']?.toString(),
      area: json['area']?.toString(),
      emirates: json['emirates']?.toString(),
      profilePhoto: json['profilePhoto']?.toString(),
      contractorCertificate: json['contractorCertificate']?.toString(),
      accountHolderName: json['accountHolderName']?.toString(),
      ibanNumber: json['ibanNumber']?.toString(),
      bankName: json['bankName']?.toString(),
      branchName: json['branchName']?.toString(),
      bankAddress: json['bankAddress']?.toString(),
      bankDocument: json['bankDocument']?.toString(),
      vatCertificate: json['vatCertificate']?.toString(),
      firmName: json['firmName']?.toString(),
      vatAddress: json['vatAddress']?.toString(),
      taxRegistrationNumber: json['taxRegistrationNumber']?.toString(),
      vatEffectiveDate: json['vatEffectiveDate']?.toString(),
      licenseDocument: json['licenseDocument']?.toString(),
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

  Map<String, dynamic> toJson() {
    return {
      'contractorType': contractorType,
      'firstName': firstName,
      'middleName': middleName,
      'lastName': lastName,
      'mobileNumber': mobileNumber,
      'address': address,
      'area': area,
      'emirates': emirates,
      'profilePhoto': profilePhoto,
      'contractorCertificate': contractorCertificate,
      'accountHolderName': accountHolderName,
      'ibanNumber': ibanNumber,
      'bankName': bankName,
      'branchName': branchName,
      'bankAddress': bankAddress,
      'bankDocument': bankDocument,
      'vatCertificate': vatCertificate,
      'firmName': firmName,
      'vatAddress': vatAddress,
      'taxRegistrationNumber': taxRegistrationNumber,
      'vatEffectiveDate': vatEffectiveDate,
      'licenseDocument': licenseDocument,
      'licenseNumber': licenseNumber,
      'issuingAuthority': issuingAuthority,
      'licenseType': licenseType,
      'establishmentDate': establishmentDate,
      'licenseExpiryDate': licenseExpiryDate,
      'tradeName': tradeName,
      'responsiblePerson': responsiblePerson,
      'licenseAddress': licenseAddress,
      'effectiveDate': effectiveDate,
    };
  }
}
