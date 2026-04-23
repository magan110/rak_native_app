/// Models for the Retailer Onboarding API.
///
/// [RetailerOnboardingRequest] is sent to the server.
/// [RetailerOnboardingResponse] is received from the server.

class RetailerOnboardingRequest {
  final String? processType;
  final String? loginId;
  final String? firmName;
  final String? contName;
  final String? trnNumber;
  final String? tradeLicence;
  final String? counterType;
  final String? businessDetails;
  final String? mobileNumber;
  final String? email;
  // Location fields aligned with backend contract
  final String? emirateCode;
  final String? emirateName;
  final String? areaCode;
  final String? areaName;
  final String? subAreaCode;
  final String? subAreaName;
  final String? poBox;
  final String? fullAddress;
  final String? latitude;
  final String? longitude;
  final String? branchDetails;
  final String? emiratesId;
  final String? bankName;
  final String? accountHolderName;
  final String? accountNumber;
  final String? ibanNumber;

  const RetailerOnboardingRequest({
    this.processType,
    this.loginId,
    this.firmName,
    this.contName,
    this.trnNumber,
    this.tradeLicence,
    this.counterType,
    this.businessDetails,
    this.mobileNumber,
    this.email,
    this.emirateCode,
    this.emirateName,
    this.areaCode,
    this.areaName,
    this.subAreaCode,
    this.subAreaName,
    this.poBox,
    this.fullAddress,
    this.latitude,
    this.longitude,
    this.branchDetails,
    this.emiratesId,
    this.bankName,
    this.accountHolderName,
    this.accountNumber,
    this.ibanNumber,
  });

  Map<String, dynamic> toJson() {
    return {
      if (processType != null) 'ProcessType': processType,
      if (loginId != null) 'LoginId': loginId,
      if (firmName != null) 'FirmName': firmName,
      if (contName != null) 'ContName': contName,
      if (trnNumber != null) 'TrnNumber': trnNumber,
      if (tradeLicence != null) 'TradeLicence': tradeLicence,
      if (counterType != null) 'CounterType': counterType,
      if (businessDetails != null) 'BusinessDetails': businessDetails,
      if (mobileNumber != null) 'MobileNumber': mobileNumber,
      if (email != null) 'Email': email,
      // Send only backend-expected location keys
      if (emirateCode != null) 'EmirateCode': emirateCode,
      if (emirateName != null) 'EmirateName': emirateName,
      if (areaCode != null) 'AreaCode': areaCode,
      if (areaName != null) 'AreaName': areaName,
      if (subAreaCode != null) 'SubAreaCode': subAreaCode,
      if (subAreaName != null) 'SubAreaName': subAreaName,
      if (poBox != null) 'PoBox': poBox,
      if (fullAddress != null) 'FullAddress': fullAddress,
      if (latitude != null) 'Latitude': latitude,
      if (longitude != null) 'Longitude': longitude,
      if (branchDetails != null) 'BranchDetails': branchDetails,
      if (emiratesId != null) 'EmiratesId': emiratesId,
      if (bankName != null) 'BankName': bankName,
      if (accountHolderName != null) 'AccountHolderName': accountHolderName,
      if (accountNumber != null) 'AccountNumber': accountNumber,
      if (ibanNumber != null) 'IbanNumber': ibanNumber,
    };
  }

  factory RetailerOnboardingRequest.fromJson(Map<String, dynamic> json) {
    return RetailerOnboardingRequest(
      processType: (json['ProcessType'] ?? json['processType']) as String?,
      loginId: (json['LoginId'] ?? json['loginId']) as String?,
      firmName: (json['FirmName'] ?? json['firmName']) as String?,
      contName: (json['ContName'] ?? json['contName']) as String?,
      trnNumber: (json['TrnNumber'] ?? json['trnNumber']) as String?,
      tradeLicence: (json['TradeLicence'] ?? json['tradeLicence']) as String?,
      counterType: (json['CounterType'] ?? json['counterType']) as String?,
      businessDetails:
          (json['BusinessDetails'] ?? json['businessDetails']) as String?,
      mobileNumber: (json['MobileNumber'] ?? json['mobileNumber']) as String?,
      email: (json['Email'] ?? json['email']) as String?,
      // Read new backend keys (accept PascalCase and camelCase)
      emirateCode: (json['EmirateCode'] ?? json['emirateCode']) as String?,
      emirateName: (json['EmirateName'] ?? json['emirateName']) as String?,
      areaCode: (json['AreaCode'] ?? json['areaCode']) as String?,
      areaName: (json['AreaName'] ?? json['areaName']) as String?,
      subAreaCode: (json['SubAreaCode'] ?? json['subAreaCode']) as String?,
      subAreaName: (json['SubAreaName'] ?? json['subAreaName']) as String?,
      poBox: (json['PoBox'] ?? json['poBox']) as String?,
      fullAddress: (json['FullAddress'] ?? json['fullAddress']) as String?,
      latitude: (json['Latitude'] ?? json['latitude']) as String?,
      longitude: (json['Longitude'] ?? json['longitude']) as String?,
      branchDetails:
          (json['BranchDetails'] ?? json['branchDetails']) as String?,
      emiratesId: (json['EmiratesId'] ?? json['emiratesId']) as String?,
      bankName: (json['BankName'] ?? json['bankName']) as String?,
      accountHolderName:
          (json['AccountHolderName'] ?? json['accountHolderName']) as String?,
      accountNumber:
          (json['AccountNumber'] ?? json['accountNumber']) as String?,
      ibanNumber: (json['IbanNumber'] ?? json['ibanNumber']) as String?,
    );
  }
}

class RetailerOnboardingResponse {
  final bool success;
  final String message;
  final String? retailerCode;
  final String? error;
  final DateTime timestamp;

  const RetailerOnboardingResponse({
    required this.success,
    required this.message,
    this.retailerCode,
    this.error,
    required this.timestamp,
  });

  factory RetailerOnboardingResponse.fromJson(Map<String, dynamic> json) {
    return RetailerOnboardingResponse(
      success: json['success'] as bool? ?? false,
      message: json['message'] as String? ?? '',
      retailerCode: json['retailerCode'] as String?,
      error: json['error'] as String?,
      timestamp: json['timestamp'] != null
          ? DateTime.tryParse(json['timestamp'].toString()) ?? DateTime.now()
          : DateTime.now(),
    );
  }
}
