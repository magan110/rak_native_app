class PainterRegistrationRequest {
  // Required / backend-aligned fields
  final String? loginId;
  final String? firstName;
  final String? middleName;
  final String? lastName;
  final String? emirateCode;
  final String? emirates;
  final String? areaCode;
  final String? areaName;
  final String? subAreaCode;
  final String? subAreaName;
  final String? poBox;
  final String? address;
  final String? mobileNumber;
  final String? dateOfBirth;
  final String? bankName;
  final String? branchName;
  final String? accountHolderName;
  final String? reference;
  final String? ibanNumber;
  final String? emiratesIdNumber;
  final String? idName;
  final String? nationality;
  final String? companyDetails;
  final String? issueDate;
  final String? expiryDate;
  final String? occupation;
  final String? bankAddress;

  PainterRegistrationRequest({
    this.loginId,
    this.firstName,
    this.middleName,
    this.lastName,
    this.emirateCode,
    this.emirates,
    this.areaCode,
    this.areaName,
    this.subAreaCode,
    this.subAreaName,
    this.poBox,
    this.address,
    this.mobileNumber,
    this.dateOfBirth,
    this.bankName,
    this.branchName,
    this.accountHolderName,
    this.reference,
    this.ibanNumber,
    this.emiratesIdNumber,
    this.idName,
    this.nationality,
    this.companyDetails,
    this.issueDate,
    this.expiryDate,
    this.occupation,
    this.bankAddress,
  });

  String? _nullIfEmpty(String? v) =>
      (v == null || v.trim().isEmpty) ? null : v.trim();

  Map<String, dynamic> toJson() => {
    'LoginId': _nullIfEmpty(loginId),
    'FirstName': _nullIfEmpty(firstName),
    'MiddleName': _nullIfEmpty(middleName),
    'LastName': _nullIfEmpty(lastName),
    'EmirateCode': _nullIfEmpty(emirateCode),
    'Emirates': _nullIfEmpty(emirates),
    'AreaCode': _nullIfEmpty(areaCode),
    'AreaName': _nullIfEmpty(areaName),
    'SubAreaCode': _nullIfEmpty(subAreaCode),
    'SubAreaName': _nullIfEmpty(subAreaName),
    'PoBox': _nullIfEmpty(poBox),
    'Address': _nullIfEmpty(address),
    'MobileNumber': _nullIfEmpty(mobileNumber),
    'DateOfBirth': _nullIfEmpty(dateOfBirth),
    'BankName': _nullIfEmpty(bankName),
    'BranchName': _nullIfEmpty(branchName),
    'AccountHolderName': _nullIfEmpty(accountHolderName),
    'Reference': _nullIfEmpty(reference),
    'IbanNumber': _nullIfEmpty(ibanNumber),
    'EmiratesIdNumber': _nullIfEmpty(emiratesIdNumber),
    'IdName': _nullIfEmpty(idName),
    'Nationality': _nullIfEmpty(nationality),
    'CompanyDetails': _nullIfEmpty(companyDetails),
    'IssueDate': _nullIfEmpty(issueDate),
    'ExpiryDate': _nullIfEmpty(expiryDate),
    'Occupation': _nullIfEmpty(occupation),
    'BankAddress': _nullIfEmpty(bankAddress),
  }..removeWhere((k, v) => v == null);
}

class PainterRegistrationResponse {
  final bool success;
  final String message;
  final String? influencerCode; // inflCode returned from API

  PainterRegistrationResponse({
    required this.success,
    required this.message,
    this.influencerCode,
  });

  factory PainterRegistrationResponse.fromJson(Map<String, dynamic> json) {
    return PainterRegistrationResponse(
      success: json['success'] == true,
      message: (json['message'] ?? '').toString(),
      influencerCode: json['influencerCode']?.toString(),
    );
  }
}

class EmirateItem {
  final String id;
  final String name;

  EmirateItem({required this.id, required this.name});

  factory EmirateItem.fromJson(Map<String, dynamic> json) {
    return EmirateItem(
      id: json['Code']?.toString() ?? json['code']?.toString() ?? '',
      name: json['Name']?.toString() ?? json['name']?.toString() ?? '',
    );
  }
}

class AreaItem {
  final String code;
  final String name;
  final String poBox;

  AreaItem({required this.code, required this.name, required this.poBox});

  factory AreaItem.fromJson(Map<String, dynamic> json) {
    return AreaItem(
      code: json['Code']?.toString() ?? json['code']?.toString() ?? '',
      name: json['Name']?.toString() ?? json['name']?.toString() ?? '',
      poBox: json['PoBox']?.toString() ?? json['pobox']?.toString() ?? '',
    );
  }
}

class SubAreaItem {
  final String code;
  final String name;
  final String poBox;

  SubAreaItem({required this.code, required this.name, required this.poBox});

  factory SubAreaItem.fromJson(Map<String, dynamic> json) {
    return SubAreaItem(
      code: json['Code']?.toString() ?? json['code']?.toString() ?? '',
      name: json['Name']?.toString() ?? json['name']?.toString() ?? '',
      poBox: json['PoBox']?.toString() ?? json['pobox']?.toString() ?? '',
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

class PainterDetailsResponse {
  final bool success;
  final String message;
  final PainterDetails? data;

  PainterDetailsResponse({
    required this.success,
    required this.message,
    this.data,
  });

  factory PainterDetailsResponse.fromJson(Map<String, dynamic> json) {
    return PainterDetailsResponse(
      success: json['success'] == true,
      message: (json['message'] ?? '').toString(),
      data: json['data'] != null ? PainterDetails.fromJson(json['data']) : null,
    );
  }
}

class PainterDetails {
  final String? firstName;
  final String? middleName;
  final String? lastName;
  final String? mobileNumber;
  final String? address;
  final String? area;
  final String? emirates;
  final String? reference;
  final String? emiratesIdNumber;
  final String? idName;
  final String? dateOfBirth;
  final String? nationality;
  final String? companyDetails;
  final String? issueDate;
  final String? expiryDate;
  final String? occupation;
  final String? accountHolderName;
  final String? ibanNumber;
  final String? bankName;
  final String? branchName;
  final String? bankAddress;

  PainterDetails({
    this.firstName,
    this.middleName,
    this.lastName,
    this.mobileNumber,
    this.address,
    this.area,
    this.emirates,
    this.reference,
    this.emiratesIdNumber,
    this.idName,
    this.dateOfBirth,
    this.nationality,
    this.companyDetails,
    this.issueDate,
    this.expiryDate,
    this.occupation,
    this.accountHolderName,
    this.ibanNumber,
    this.bankName,
    this.branchName,
    this.bankAddress,
  });

  factory PainterDetails.fromJson(Map<String, dynamic> json) {
    return PainterDetails(
      firstName: json['firstName']?.toString(),
      middleName: json['middleName']?.toString(),
      lastName: json['lastName']?.toString(),
      mobileNumber: json['mobileNumber']?.toString(),
      address: json['address']?.toString(),
      area: json['area']?.toString(),
      emirates: json['emirates']?.toString(),
      reference: json['reference']?.toString(),
      emiratesIdNumber: json['emiratesIdNumber']?.toString(),
      idName: json['idName']?.toString(),
      dateOfBirth: json['dateOfBirth']?.toString(),
      nationality: json['nationality']?.toString(),
      companyDetails: json['companyDetails']?.toString(),
      issueDate: json['issueDate']?.toString(),
      expiryDate: json['expiryDate']?.toString(),
      occupation: json['occupation']?.toString(),
      accountHolderName: json['accountHolderName']?.toString(),
      ibanNumber: json['ibanNumber']?.toString(),
      bankName: json['bankName']?.toString(),
      branchName: json['branchName']?.toString(),
      bankAddress: json['bankAddress']?.toString(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'firstName': firstName,
      'middleName': middleName,
      'lastName': lastName,
      'mobileNumber': mobileNumber,
      'address': address,
      'area': area,
      'emirates': emirates,
      'reference': reference,
      'emiratesIdNumber': emiratesIdNumber,
      'idName': idName,
      'dateOfBirth': dateOfBirth,
      'nationality': nationality,
      'companyDetails': companyDetails,
      'issueDate': issueDate,
      'expiryDate': expiryDate,
      'occupation': occupation,
      'accountHolderName': accountHolderName,
      'ibanNumber': ibanNumber,
      'bankName': bankName,
      'branchName': branchName,
      'bankAddress': bankAddress,
    };
  }
}
