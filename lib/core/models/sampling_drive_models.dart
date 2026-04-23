class SamplingDriveEntry {
  final String? docuNumb;
  final String retailerName;
  final String retailerCode;
  final String distributorName;
  final String emirates;
  
  // Back-compat so existing code that uses entry.area still works
  String get area => emirates;
  
  final DateTime distributionDate;
  final String painterName;
  final String painterMobile;
  final double qtyDistributedKg;
  final String siteAddress;
  final DateTime? sampleDate;
  final String product;
  final String? photoImage;
  final String reimbursementMode;
  final double reimbursementAmountAED;
  final String? sampleCancelFlag;
  
  // Not in API → keep but default
  final String skuSizeLabel;
  final double missedQtyKg;
  final double effectiveDistributedKg;
  final double totalReceivedKg;
  final double remainingKg;
  final String serialNo;
  final double materialQty;

  SamplingDriveEntry({
    this.docuNumb,
    required this.retailerName,
    required this.retailerCode,
    required this.distributorName,
    required this.emirates,
    required this.distributionDate,
    required this.painterName,
    required this.painterMobile,
    required this.skuSizeLabel,
    required this.qtyDistributedKg,
    required this.missedQtyKg,
    required this.effectiveDistributedKg,
    required this.totalReceivedKg,
    required this.remainingKg,
    required this.reimbursementMode,
    required this.reimbursementAmountAED,
    this.photoImage,
    required this.serialNo,
    required this.materialQty,
    this.sampleCancelFlag,
    required this.siteAddress,
    this.sampleDate,
    required this.product,
  });

  static DateTime? _parseDate(dynamic v) {
    if (v == null) return null;
    if (v is int) return DateTime.fromMillisecondsSinceEpoch(v);
    if (v is String && v.isNotEmpty) return DateTime.tryParse(v);
    return null;
  }

  static double _numToDouble(dynamic v, {double def = 0.0}) {
    if (v == null) return def;
    if (v is num) return v.toDouble();
    return double.tryParse(v.toString()) ?? def;
  }

  static String _str(dynamic v, {String def = ''}) {
    if (v == null) return def;
    final s = v.toString().trim();
    return s.isEmpty ? def : s;
  }

  factory SamplingDriveEntry.fromJson(Map<String, dynamic> json) {
    final qty = _numToDouble(json['qtyDistributedKg'], def: 0.0);
    final missed = _numToDouble(json['missedQtyKg'], def: 0.0);
    final effective = _numToDouble(
      json['effectiveDistributedKg'],
      def: (qty - missed).clamp(0, double.infinity),
    );

    return SamplingDriveEntry(
      docuNumb: json['docuNumb']?.toString(),
      retailerName: _str(json['retailerName']),
      retailerCode: _str(json['retailerCode']),
      distributorName: _str(json['distributorName']),
      emirates: _str(json['emirates']),
      distributionDate: _parseDate(json['distributionDate']) ?? DateTime.now(),
      painterName: _str(json['painterName']),
      painterMobile: _str(json['painterMobile']),
      qtyDistributedKg: qty,
      siteAddress: _str(json['siteAddress']),
      sampleDate: _parseDate(json['sampleDate']),
      product: _str(json['product']),
      photoImage: json['photoImage']?.toString(),
      reimbursementMode: _str(json['reimbursementMode']),
      reimbursementAmountAED: _numToDouble(
        json['reimbursementAmountAED'],
        def: 0.0,
      ),
      sampleCancelFlag: json['sampleCancelFlag']?.toString(),
      skuSizeLabel: _str(json['skuSizeLabel'], def: ''),
      missedQtyKg: missed,
      effectiveDistributedKg: effective,
      totalReceivedKg: _numToDouble(json['totalReceivedKg'], def: 0.0),
      remainingKg: _numToDouble(json['remainingKg'], def: 0.0),
      serialNo: _str(json['serialNo'], def: ''),
      materialQty: _numToDouble(json['materialQty'], def: 0.0),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'docuNumb': docuNumb,
      'retailerName': retailerName,
      'retailerCode': retailerCode,
      'distributorName': distributorName,
      'emirates': emirates,
      'area': emirates,
      'distributionDate': distributionDate.toIso8601String(),
      'painterName': painterName,
      'painterMobile': painterMobile,
      'skuSizeLabel': skuSizeLabel,
      'qtyDistributedKg': qtyDistributedKg,
      'missedQtyKg': missedQtyKg,
      'effectiveDistributedKg': effectiveDistributedKg,
      'totalReceivedKg': totalReceivedKg,
      'remainingKg': remainingKg,
      'reimbursementMode': reimbursementMode,
      'reimbursementAmountAED': reimbursementAmountAED,
      'photoImage': photoImage,
      'serialNo': serialNo,
      'materialQty': materialQty,
      'sampleCancelFlag': sampleCancelFlag,
      'siteAddress': siteAddress,
      'sampleDate': sampleDate?.toIso8601String(),
      'product': product,
    };
  }
}

class SamplingDriveRequest {
  final String retailerName;
  final String retailerCode;
  final String distributorName;
  final String emirates;
  final String distributionDate;
  final String painterName;
  final String painterMobile;
  final double qtyDistributedKg;
  final String siteAddress;
  final DateTime? sampleDate;
  final String product;
  final String? photoImage;
  final String reimbursementMode;
  final double reimbursementAmountAED;
  final String? sampleCancelFlag;

  SamplingDriveRequest({
    required this.retailerName,
    required this.retailerCode,
    required this.distributorName,
    required this.emirates,
    required this.distributionDate,
    required this.painterName,
    required this.painterMobile,
    required this.qtyDistributedKg,
    this.siteAddress = '',
    this.sampleDate,
    this.product = '',
    this.photoImage,
    required this.reimbursementMode,
    required this.reimbursementAmountAED,
    this.sampleCancelFlag,
  });

  Map<String, dynamic> toJson() {
    return {
      'retailerName': retailerName,
      'retailerCode': retailerCode,
      'distributorName': distributorName,
      'emirates': emirates,
      'distributionDate': distributionDate,
      'painterName': painterName,
      'painterMobile': painterMobile,
      'qtyDistributedKg': qtyDistributedKg,
      'siteAddress': siteAddress,
      'sampleDate': sampleDate?.toIso8601String(),
      'product': product,
      'photoImage': photoImage,
      'reimbursementMode': reimbursementMode,
      'reimbursementAmountAED': reimbursementAmountAED,
      'sampleCancelFlag': sampleCancelFlag ?? 'S',
    };
  }
}
