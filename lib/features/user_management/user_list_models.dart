class UserItem {
  final String id;
  final String name;
  final String type; // 'Contractor' or 'Painter'
  final String emiratesId;
  final String registrationId;
  final String mobile;
  final String email;
  final String status; // 'Active' or 'Inactive'
  final String avatar;
  final String? companyName; // For contractors
  final String? licenseNumber; // For contractors

  UserItem({
    required this.id,
    required this.name,
    required this.type,
    required this.emiratesId,
    required this.registrationId,
    required this.mobile,
    required this.email,
    required this.status,
    required this.avatar,
    this.companyName,
    this.licenseNumber,
  });

  factory UserItem.fromJson(Map<String, dynamic> json) {
    return UserItem(
      id: json['id'] ?? '',
      name: json['name'] ?? '',
      type: json['type'] ?? 'Contractor',
      emiratesId: json['emiratesId'] ?? '',
      registrationId: json['registrationId'] ?? '',
      mobile: json['mobile'] ?? '',
      email: json['email'] ?? '',
      status: json['status'] ?? 'Active',
      avatar: json['avatar'] ?? '',
      companyName: json['companyName'],
      licenseNumber: json['licenseNumber'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'type': type,
      'emiratesId': emiratesId,
      'registrationId': registrationId,
      'mobile': mobile,
      'email': email,
      'status': status,
      'avatar': avatar,
      'companyName': companyName,
      'licenseNumber': licenseNumber,
    };
  }
}

class UserListResponse {
  final bool success;
  final int page;
  final int pageSize;
  final int total;
  final List<UserItem> items;

  UserListResponse({
    required this.success,
    required this.page,
    required this.pageSize,
    required this.total,
    required this.items,
  });

  factory UserListResponse.fromJson(Map<String, dynamic> json) {
    return UserListResponse(
      success: json['success'] ?? false,
      page: json['page'] ?? 1,
      pageSize: json['pageSize'] ?? 20,
      total: json['total'] ?? 0,
      items: (json['items'] as List<dynamic>?)
              ?.map((item) => UserItem.fromJson(item))
              .toList() ??
          [],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'success': success,
      'page': page,
      'pageSize': pageSize,
      'total': total,
      'items': items.map((item) => item.toJson()).toList(),
    };
  }
}

/// Detailed user information from GET /api/Users/{userId}
class UserDetailDto {
  final String? userId;
  final String? type;
  final String? status;
  final String? contractorType;
  final String? firstName;
  final String? middleName;
  final String? lastName;
  final String? mobileNumber;
  final String? address;
  final String? area;
  final String? emirates;
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
  final String? licenseNumber;
  final String? issuingAuthority;
  final String? licenseType;
  final String? establishmentDate;
  final String? licenseExpiryDate;
  final String? tradeName;
  final String? responsiblePerson;
  final String? licenseAddress;
  final String? effectiveDate;
  final String? firmName;
  final String? vatAddress;
  final String? taxRegistrationNumber;
  final String? vatEffectiveDate;

  UserDetailDto({
    this.userId,
    this.type,
    this.status,
    this.contractorType,
    this.firstName,
    this.middleName,
    this.lastName,
    this.mobileNumber,
    this.address,
    this.area,
    this.emirates,
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
    this.licenseNumber,
    this.issuingAuthority,
    this.licenseType,
    this.establishmentDate,
    this.licenseExpiryDate,
    this.tradeName,
    this.responsiblePerson,
    this.licenseAddress,
    this.effectiveDate,
    this.firmName,
    this.vatAddress,
    this.taxRegistrationNumber,
    this.vatEffectiveDate,
  });

  factory UserDetailDto.fromJson(Map<String, dynamic> json) {
    return UserDetailDto(
      userId: json['userId']?.toString(),
      type: json['type']?.toString(),
      status: json['status']?.toString(),
      contractorType: json['contractorType']?.toString(),
      firstName: json['firstName']?.toString(),
      middleName: json['middleName']?.toString(),
      lastName: json['lastName']?.toString(),
      mobileNumber: json['mobileNumber']?.toString(),
      address: json['address']?.toString(),
      area: json['area']?.toString(),
      emirates: json['emirates']?.toString(),
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
      licenseNumber: json['licenseNumber']?.toString(),
      issuingAuthority: json['issuingAuthority']?.toString(),
      licenseType: json['licenseType']?.toString(),
      establishmentDate: json['establishmentDate']?.toString(),
      licenseExpiryDate: json['licenseExpiryDate']?.toString(),
      tradeName: json['tradeName']?.toString(),
      responsiblePerson: json['responsiblePerson']?.toString(),
      licenseAddress: json['licenseAddress']?.toString(),
      effectiveDate: json['effectiveDate']?.toString(),
      firmName: json['firmName']?.toString(),
      vatAddress: json['vatAddress']?.toString(),
      taxRegistrationNumber: json['taxRegistrationNumber']?.toString(),
      vatEffectiveDate: json['vatEffectiveDate']?.toString(),
    );
  }
}

/// Request model for PUT /api/Users/update/{userId}
class UserUpdateRequest {
  final String? status;
  final String? contractorType;
  final String? firstName;
  final String? middleName;
  final String? lastName;
  final String? mobileNumber;
  final String? address;
  final String? area;
  final String? emirates;
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
  final String? licenseNumber;
  final String? issuingAuthority;
  final String? licenseType;
  final String? establishmentDate;
  final String? licenseExpiryDate;
  final String? tradeName;
  final String? responsiblePerson;
  final String? licenseAddress;
  final String? effectiveDate;
  final String? firmName;
  final String? vatAddress;
  final String? taxRegistrationNumber;
  final String? vatEffectiveDate;
  
  // Login ID (User who is updating)
  final String? loginId;

  UserUpdateRequest({
    this.status,
    this.contractorType,
    this.firstName,
    this.middleName,
    this.lastName,
    this.mobileNumber,
    this.address,
    this.area,
    this.emirates,
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
    this.licenseNumber,
    this.issuingAuthority,
    this.licenseType,
    this.establishmentDate,
    this.licenseExpiryDate,
    this.tradeName,
    this.responsiblePerson,
    this.licenseAddress,
    this.effectiveDate,
    this.firmName,
    this.vatAddress,
    this.taxRegistrationNumber,
    this.vatEffectiveDate,
    this.loginId,
  });

  Map<String, dynamic> toJson() {
    // Helper to sanitize strings and remove null values
    String? sanitize(String? value) {
      if (value == null || value.trim().isEmpty) return null;
      return value.trim();
    }
    
    final map = <String, dynamic>{};
    
    if (sanitize(status) != null) map['status'] = sanitize(status);
    if (sanitize(contractorType) != null) map['contractorType'] = sanitize(contractorType);
    if (sanitize(firstName) != null) map['firstName'] = sanitize(firstName);
    if (sanitize(middleName) != null) map['middleName'] = sanitize(middleName);
    if (sanitize(lastName) != null) map['lastName'] = sanitize(lastName);
    if (sanitize(mobileNumber) != null) map['mobileNumber'] = sanitize(mobileNumber);
    if (sanitize(address) != null) map['address'] = sanitize(address);
    if (sanitize(area) != null) map['area'] = sanitize(area);
    if (sanitize(emirates) != null) map['emirates'] = sanitize(emirates);
    if (sanitize(emiratesIdNumber) != null) map['emiratesIdNumber'] = sanitize(emiratesIdNumber);
    if (sanitize(idName) != null) map['idName'] = sanitize(idName);
    if (sanitize(dateOfBirth) != null) map['dateOfBirth'] = sanitize(dateOfBirth);
    if (sanitize(nationality) != null) map['nationality'] = sanitize(nationality);
    if (sanitize(companyDetails) != null) map['companyDetails'] = sanitize(companyDetails);
    if (sanitize(issueDate) != null) map['issueDate'] = sanitize(issueDate);
    if (sanitize(expiryDate) != null) map['expiryDate'] = sanitize(expiryDate);
    if (sanitize(occupation) != null) map['occupation'] = sanitize(occupation);
    if (sanitize(accountHolderName) != null) map['accountHolderName'] = sanitize(accountHolderName);
    if (sanitize(ibanNumber) != null) map['ibanNumber'] = sanitize(ibanNumber);
    if (sanitize(bankName) != null) map['bankName'] = sanitize(bankName);
    if (sanitize(branchName) != null) map['branchName'] = sanitize(branchName);
    if (sanitize(bankAddress) != null) map['bankAddress'] = sanitize(bankAddress);
    if (sanitize(licenseNumber) != null) map['licenseNumber'] = sanitize(licenseNumber);
    if (sanitize(issuingAuthority) != null) map['issuingAuthority'] = sanitize(issuingAuthority);
    if (sanitize(licenseType) != null) map['licenseType'] = sanitize(licenseType);
    if (sanitize(establishmentDate) != null) map['establishmentDate'] = sanitize(establishmentDate);
    if (sanitize(licenseExpiryDate) != null) map['licenseExpiryDate'] = sanitize(licenseExpiryDate);
    if (sanitize(tradeName) != null) map['tradeName'] = sanitize(tradeName);
    if (sanitize(responsiblePerson) != null) map['responsiblePerson'] = sanitize(responsiblePerson);
    if (sanitize(licenseAddress) != null) map['licenseAddress'] = sanitize(licenseAddress);
    if (sanitize(effectiveDate) != null) map['effectiveDate'] = sanitize(effectiveDate);
    if (sanitize(firmName) != null) map['firmName'] = sanitize(firmName);
    if (sanitize(vatAddress) != null) map['vatAddress'] = sanitize(vatAddress);
    if (sanitize(taxRegistrationNumber) != null) map['taxRegistrationNumber'] = sanitize(taxRegistrationNumber);
    if (sanitize(vatEffectiveDate) != null) map['vatEffectiveDate'] = sanitize(vatEffectiveDate);
    if (sanitize(loginId) != null) map['loginId'] = sanitize(loginId);
    
    return map;
  }
}
