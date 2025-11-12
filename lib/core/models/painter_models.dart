class PainterRegistrationRequest {
  // Personal
  final String? firstName;
  final String? middleName;
  final String? lastName;
  final String? mobileNumber;
  final String? address;
  final String? area;
  final String? emirates;
  final String? reference;
  final String? password;

  // Emirates ID Details
  final String? emiratesIdNumber;
  final String? idName; // Name on ID
  final String? dateOfBirth; // yyyy-MM-dd preferred
  final String? nationality;
  final String? companyDetails; // Employer
  final String? issueDate; // yyyy-MM-dd or string
  final String? expiryDate; // yyyy-MM-dd or string
  final String? occupation;

  // Bank (optional)
  final String? accountHolderName;
  final String? ibanNumber;
  final String? bankName;
  final String? branchName;
  final String? bankAddress;

  PainterRegistrationRequest({
    this.firstName,
    this.middleName,
    this.lastName,
    this.mobileNumber,
    this.address,
    this.area,
    this.emirates,
    this.reference,
    this.password,
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

  // empty string for null/blank
  String _empty(String? v) => (v == null || v.trim().isEmpty) ? '' : v.trim();

  Map<String, dynamic> toJson() => {
    // Personal
    "firstName": _empty(firstName),
    "middleName": _empty(middleName),
    "lastName": _empty(lastName),
    "mobileNumber": _empty(mobileNumber),
    "address": _empty(address),
    "area": _empty(area),
    "emirates": _empty(emirates),
    "reference": _empty(reference),
    "password": _empty(password),

    // Emirates ID
    "emiratesIdNumber": _empty(emiratesIdNumber),
    "idName": _empty(idName),
    "dateOfBirth": _empty(dateOfBirth),
    "nationality": _empty(nationality),
    "companyDetails": _empty(companyDetails),
    "issueDate": _empty(issueDate),
    "expiryDate": _empty(expiryDate),
    "occupation": _empty(occupation),

    // Bank
    "accountHolderName": _empty(accountHolderName),
    "ibanNumber": _empty(ibanNumber),
    "bankName": _empty(bankName),
    "branchName": _empty(branchName),
    "bankAddress": _empty(bankAddress),
  };
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
      id: json['code']?.toString() ?? '',
      name: json['desc']?.toString() ?? '',
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
