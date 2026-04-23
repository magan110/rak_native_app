class EmirateItem {
  final String code;
  final String name;

  EmirateItem({required this.code, String? name, String? desc})
    : name = (name ?? desc ?? '');

  factory EmirateItem.fromJson(Map<String, dynamic> json) {
    return EmirateItem(
      code: (json['Code'] ?? json['code'] ?? json['EmirateCode'] ?? '')
          .toString()
          .trim(),
      name:
          (json['Name'] ??
                  json['name'] ??
                  json['EmirateName'] ??
                  json['Desc'] ??
                  '')
              .toString()
              .trim(),
    );
  }

  @override
  String toString() => name;

  // Compatibility getter used elsewhere in the codebase
  String get desc => name;

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is EmirateItem && other.code == code && other.name == name;
  }

  @override
  int get hashCode => code.hashCode ^ name.hashCode;
}

class AreaItem {
  final String code;
  final String name;
  final String poBox;

  AreaItem({required this.code, required this.name, required this.poBox});

  factory AreaItem.fromJson(Map<String, dynamic> json) {
    return AreaItem(
      code: (json['Code'] ?? json['code'] ?? json['AreaCode'] ?? '')
          .toString()
          .trim(),
      name:
          (json['Name'] ??
                  json['name'] ??
                  json['AreaName'] ??
                  json['Desc'] ??
                  '')
              .toString()
              .trim(),
      poBox: (json['PoBox'] ?? json['poBox'] ?? json['Pobox'] ?? '')
          .toString()
          .trim(),
    );
  }

  @override
  String toString() => name;
}

class SubAreaItem {
  final String code;
  final String name;
  final String poBox;

  SubAreaItem({required this.code, required this.name, required this.poBox});

  factory SubAreaItem.fromJson(Map<String, dynamic> json) {
    return SubAreaItem(
      code: (json['Code'] ?? json['code'] ?? json['SubAreaCode'] ?? '')
          .toString()
          .trim(),
      name:
          (json['Name'] ??
                  json['name'] ??
                  json['SubAreaName'] ??
                  json['Desc'] ??
                  '')
              .toString()
              .trim(),
      poBox: (json['PoBox'] ?? json['poBox'] ?? json['Pobox'] ?? '')
          .toString()
          .trim(),
    );
  }

  @override
  String toString() => name;
}

class ContractorRegistrationRequest {
  // Personal Details (Mandatory)
  final String? contractorType;
  final String? firstName;
  final String? middleName;
  final String? lastName;
  final String? mobileNumber; // 9-digit UAE format (50,52,54,55,56,58)
  final String? address; // Address-1

  // Master location codes/names
  final String? emirateCode;
  final String? emirateName;
  // Backend expects `Emirates` (plural). Keep both fields for compatibility;
  // `emirates` will be used when present. toJson() will emit `Emirates` key.
  final String? emirates;
  final String? areaCode;
  final String? areaName;
  final bool? hasSubArea;
  final String? subAreaCode;
  final String? subAreaName;
  final String? poBox;

  final String? profilePhoto; // Upload/Click
  final String? password; // User password

  // Emirates ID Details (Mandatory)
  final String? emiratesIdNumber;
  final String? idName; // Name on ID
  final String? dateOfBirth;
  final String? nationality;
  final String? companyDetails; // Employer
  final String? issueDate;
  final String? expiryDate;
  final String? occupation;

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

  // Total Points
  final int? totalPoints;

  // Login ID (User who is registering the contractor)
  final String? loginId;

  ContractorRegistrationRequest({
    // Personal Details (Mandatory)
    this.contractorType,
    this.firstName,
    this.middleName,
    this.lastName,
    this.mobileNumber,
    this.address,

    // Master location
    this.emirateCode,
    this.emirateName,
    this.emirates,
    this.areaCode,
    this.areaName,
    this.hasSubArea,
    this.subAreaCode,
    this.subAreaName,
    this.poBox,

    this.profilePhoto,
    this.password,

    // Emirates ID Details (Mandatory)
    this.emiratesIdNumber,
    this.idName,
    this.dateOfBirth,
    this.nationality,
    this.companyDetails,
    this.issueDate,
    this.expiryDate,
    this.occupation,

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

    // Total Points
    this.totalPoints,

    // Login ID
    this.loginId,
  });

  // helper: empty string if null/blank
  // helper: empty string if null/blank; sanitize to remove control chars/newlines
  String _empty(String? v) {
    if (v == null || v.trim().isEmpty) return '';
    // Replace newlines/tabs and collapse multiple whitespace into single space
    final cleaned = v.replaceAll(RegExp(r'[\r\n\t]+'), ' ');
    return cleaned.replaceAll(RegExp(r'\s+'), ' ').trim();
  }

  String? _nullIfEmpty(String? v) {
    if (v == null || v.trim().isEmpty) return null;
    final cleaned = v.replaceAll(RegExp(r'[\r\n\t]+'), ' ');
    return cleaned.replaceAll(RegExp(r'\s+'), ' ').trim();
  }

  Map<String, dynamic> toJson() {
    final map = {
      // Personal Details (PascalCase keys expected by backend)
      'ContractorType': _empty(contractorType),
      'FirstName': _empty(firstName),
      'MiddleName': _empty(middleName),
      'LastName': _empty(lastName),
      'MobileNumber': _empty(mobileNumber),
      'Address': _empty(address),

      // Master location
      // Use `Emirates` key required by backend. Prefer `emirates` field if set,
      // otherwise fall back to `emirateName` for backward compatibility.
      'EmirateCode': _empty(emirateCode),
      'Emirates': _empty(emirates ?? emirateName),
      'AreaCode': _empty(areaCode),
      'AreaName': _empty(areaName),
      'HasSubArea': hasSubArea == true,
      'SubAreaCode': _nullIfEmpty(subAreaCode),
      'SubAreaName': _nullIfEmpty(subAreaName),
      'PoBox': _empty(poBox),

      'ProfilePhoto': _empty(profilePhoto),
      'Password': _empty(password),

      // Emirates ID Details (PascalCase)
      'EmiratesIdNumber': _empty(emiratesIdNumber),
      'IdName': _empty(idName),
      'DateOfBirth': _empty(dateOfBirth),
      'Nationality': _empty(nationality),
      'CompanyDetails': _empty(companyDetails),
      'IssueDate': _empty(issueDate),
      'ExpiryDate': _empty(expiryDate),
      'Occupation': _empty(occupation),

      // Contractor Certificate
      'ContractorCertificate': _empty(contractorCertificate),

      // Bank Details
      'AccountHolderName': _empty(accountHolderName),
      'IbanNumber': _empty(ibanNumber),
      'BankName': _empty(bankName),
      'BranchName': _empty(branchName),
      'BankAddress': _empty(bankAddress),
      'BankDocument': _empty(bankDocument),

      // VAT
      'VatCertificate': _empty(vatCertificate),
      'FirmName': _empty(firmName),
      'VatAddress': _empty(vatAddress),
      'TaxRegistrationNumber': _empty(taxRegistrationNumber),
      'VatEffectiveDate': _empty(vatEffectiveDate),

      // Commercial License
      'LicenseDocument': _empty(licenseDocument),
      'LicenseNumber': _empty(licenseNumber),
      'IssuingAuthority': _empty(issuingAuthority),
      'LicenseType': _empty(licenseType),
      'EstablishmentDate': _empty(establishmentDate),
      'LicenseExpiryDate': _empty(licenseExpiryDate),
      'TradeName': _empty(tradeName),
      'ResponsiblePerson': _empty(responsiblePerson),
      'LicenseAddress': _empty(licenseAddress),
      'EffectiveDate': _empty(effectiveDate),

      // Total Points
      'TotalPoints': totalPoints,

      // Login ID
      'LoginId': _empty(loginId),
    };

    // Remove explicit nulls so we don't send blank sub-area fields when none exist
    map.removeWhere((k, v) => v == null);

    return map;
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
      data: json['data'] != null
          ? ContractorDetails.fromJson(json['data'])
          : null,
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

  // Master codes
  final String? emirateCode;
  final String? emirateName;
  final String? areaCode;
  final String? areaName;
  final bool? hasSubArea;
  final String? subAreaCode;
  final String? subAreaName;
  final String? poBox;

  final String? profilePhoto;
  final String? emiratesIdNumber;
  final String? idName;
  final String? dateOfBirth;
  final String? nationality;
  final String? companyDetails;
  final String? issueDate;
  final String? expiryDate;
  final String? occupation;
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
    this.emirateCode,
    this.emirateName,
    this.areaCode,
    this.areaName,
    this.hasSubArea,
    this.subAreaCode,
    this.subAreaName,
    this.poBox,
    this.profilePhoto,
    this.emiratesIdNumber,
    this.idName,
    this.dateOfBirth,
    this.nationality,
    this.companyDetails,
    this.issueDate,
    this.expiryDate,
    this.occupation,
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
      contractorType: (json['ContractorType'] ?? json['contractorType'])
          ?.toString(),
      firstName: (json['FirstName'] ?? json['firstName'])?.toString(),
      middleName: (json['MiddleName'] ?? json['middleName'])?.toString(),
      lastName: (json['LastName'] ?? json['lastName'])?.toString(),
      mobileNumber: (json['MobileNumber'] ?? json['mobileNumber'])?.toString(),
      address: (json['Address'] ?? json['address'])?.toString(),

      emirateCode:
          (json['EmirateCode'] ?? json['emirateCode'] ?? json['EmiratesCode'])
              ?.toString(),
      emirateName:
          (json['EmirateName'] ?? json['emirates'] ?? json['emirateName'])
              ?.toString(),
      areaCode:
          (json['AreaCode'] ?? json['areaCode'] ?? json['Area'] ?? json['area'])
              ?.toString(),
      areaName: (json['AreaName'] ?? json['areaName'])?.toString(),
      hasSubArea: json['HasSubArea'] != null
          ? (json['HasSubArea'] == true)
          : null,
      subAreaCode: (json['SubAreaCode'] ?? json['subAreaCode'])?.toString(),
      subAreaName: (json['SubAreaName'] ?? json['subAreaName'])?.toString(),
      poBox: (json['PoBox'] ?? json['poBox'] ?? json['Pobox'])?.toString(),

      profilePhoto: (json['ProfilePhoto'] ?? json['profilePhoto'])?.toString(),
      emiratesIdNumber: (json['EmiratesIdNumber'] ?? json['emiratesIdNumber'])
          ?.toString(),
      idName: (json['IdName'] ?? json['idName'] ?? json['idName'])?.toString(),
      dateOfBirth: (json['DateOfBirth'] ?? json['dateOfBirth'])?.toString(),
      nationality: (json['Nationality'] ?? json['nationality'])?.toString(),
      companyDetails: (json['CompanyDetails'] ?? json['companyDetails'])
          ?.toString(),
      issueDate: (json['IssueDate'] ?? json['issueDate'])?.toString(),
      expiryDate: (json['ExpiryDate'] ?? json['expiryDate'])?.toString(),
      occupation: (json['Occupation'] ?? json['occupation'])?.toString(),
      contractorCertificate:
          (json['ContractorCertificate'] ?? json['contractorCertificate'])
              ?.toString(),
      accountHolderName:
          (json['AccountHolderName'] ?? json['accountHolderName'])?.toString(),
      ibanNumber: (json['IbanNumber'] ?? json['ibanNumber'])?.toString(),
      bankName: (json['BankName'] ?? json['bankName'])?.toString(),
      branchName: (json['BranchName'] ?? json['branchName'])?.toString(),
      bankAddress: (json['BankAddress'] ?? json['bankAddress'])?.toString(),
      bankDocument: (json['BankDocument'] ?? json['bankDocument'])?.toString(),
      vatCertificate: (json['VatCertificate'] ?? json['vatCertificate'])
          ?.toString(),
      firmName: (json['FirmName'] ?? json['firmName'])?.toString(),
      vatAddress: (json['VatAddress'] ?? json['vatAddress'])?.toString(),
      taxRegistrationNumber:
          (json['TaxRegistrationNumber'] ?? json['taxRegistrationNumber'])
              ?.toString(),
      vatEffectiveDate: (json['VatEffectiveDate'] ?? json['vatEffectiveDate'])
          ?.toString(),
      licenseDocument: (json['LicenseDocument'] ?? json['licenseDocument'])
          ?.toString(),
      licenseNumber: (json['LicenseNumber'] ?? json['licenseNumber'])
          ?.toString(),
      issuingAuthority: (json['IssuingAuthority'] ?? json['issuingAuthority'])
          ?.toString(),
      licenseType: (json['LicenseType'] ?? json['licenseType'])?.toString(),
      establishmentDate:
          (json['EstablishmentDate'] ?? json['establishmentDate'])?.toString(),
      licenseExpiryDate:
          (json['LicenseExpiryDate'] ?? json['licenseExpiryDate'])?.toString(),
      tradeName: (json['TradeName'] ?? json['tradeName'])?.toString(),
      responsiblePerson:
          (json['ResponsiblePerson'] ?? json['responsiblePerson'])?.toString(),
      licenseAddress: (json['LicenseAddress'] ?? json['licenseAddress'])
          ?.toString(),
      effectiveDate: (json['EffectiveDate'] ?? json['effectiveDate'])
          ?.toString(),
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
      'area': areaName,
      'emirates': emirateName,
      'profilePhoto': profilePhoto,
      'emiratesIdNumber': emiratesIdNumber,
      'idName': idName,
      'dateOfBirth': dateOfBirth,
      'nationality': nationality,
      'companyDetails': companyDetails,
      'issueDate': issueDate,
      'expiryDate': expiryDate,
      'occupation': occupation,
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

  // Convenience getters for legacy field names used across the codebase
  String? get area => areaName;
  String? get emirates => emirateName;
}
