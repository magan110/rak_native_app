class AreaItem {
  final String code;
  final String desc;

  AreaItem({
    required this.code,
    required this.desc,
  });

  factory AreaItem.fromJson(Map<String, dynamic> json) {
    return AreaItem(
      code: json['code']?.toString() ?? '',
      desc: json['desc']?.toString() ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'code': code,
      'desc': desc,
    };
  }
}

class SampleDistributionRequest {
  final String? loginId;
  final String emirate;
  final String retailerName;
  final String? retailerCode;
  final String distributor;
  final String painterName;
  final String? painterMobile;
  final String? materialQty;
  final String distributionDate;

  SampleDistributionRequest({
    this.loginId,
    required this.emirate,
    required this.retailerName,
    this.retailerCode,
    required this.distributor,
    required this.painterName,
    this.painterMobile,
    this.materialQty,
    required this.distributionDate,
  });

  Map<String, dynamic> toJson() {
    return {
      'loginId': loginId,
      'emirate': emirate,
      'retailerName': retailerName,
      'retailerCode': retailerCode,
      'distributor': distributor,
      'painterName': painterName,
      'painterMobile': painterMobile,
      'materialQty': materialQty,
      'distributionDate': distributionDate,
    };
  }
}

class SubmitResponse {
  final bool success;
  final String message;
  final String? docuNumb;

  SubmitResponse({
    required this.success,
    required this.message,
    this.docuNumb,
  });

  factory SubmitResponse.fromJson(Map<String, dynamic> json) {
    return SubmitResponse(
      success: json['success'] ?? false,
      message: json['message']?.toString() ?? '',
      docuNumb: json['docuNumb']?.toString(),
    );
  }
}

class SupplyChainEntry {
  final String retailerName;
  final String retailerCode;
  final String distributorName;
  final String painterName;
  final String painterMobile;
  final double qtyDistributed;
  final double totalReceived;
  final double remaining;

  SupplyChainEntry({
    required this.retailerName,
    required this.retailerCode,
    required this.distributorName,
    required this.painterName,
    required this.painterMobile,
    required this.qtyDistributed,
    required this.totalReceived,
    required this.remaining,
  });
}
