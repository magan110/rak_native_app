class DsrOptionItem {
  final String code;
  final String name;

  const DsrOptionItem({required this.code, required this.name});

  factory DsrOptionItem.fromJson(Map<String, dynamic> json) {
    return DsrOptionItem(
      code:
          (json['code'] ?? json['Code'] ?? json['value'] ?? json['Value'] ?? '')
              .toString(),
      name: (json['name'] ?? json['Name'] ?? json['text'] ?? json['Text'] ?? '')
          .toString(),
    );
  }
}

class DsrSkuItem {
  final String code;
  final String name;
  final String catgPack;
  final double packSize;
  final double bagsPerTon;

  const DsrSkuItem({
    required this.code,
    required this.name,
    required this.catgPack,
    required this.packSize,
    required this.bagsPerTon,
  });

  factory DsrSkuItem.fromJson(Map<String, dynamic> json) {
    return DsrSkuItem(
      code: (json['code'] ?? json['Code'] ?? '').toString(),
      name: (json['name'] ?? json['Name'] ?? '').toString(),
      catgPack: (json['catgPack'] ?? json['CatgPack'] ?? '').toString(),
      packSize:
          double.tryParse(
            (json['packSize'] ?? json['PackSize'] ?? '0').toString(),
          ) ??
          0,
      bagsPerTon:
          double.tryParse(
            (json['bagsPerTon'] ?? json['BagsPerTon'] ?? '0').toString(),
          ) ??
          0,
    );
  }
}

class DsrFieldConfig {
  final String key;
  final String label;
  final String type;
  final bool requiredField;
  final List<DsrOptionItem> options;

  const DsrFieldConfig({
    required this.key,
    required this.label,
    required this.type,
    required this.requiredField,
    required this.options,
  });

  factory DsrFieldConfig.fromJson(Map<String, dynamic> json) {
    final list = (json['options'] ?? json['Options'] ?? []) as List<dynamic>;
    return DsrFieldConfig(
      // Backend sends "name" (camelCase); fallback to "key" for older responses
      key: (json['name'] ?? json['Name'] ?? json['key'] ?? json['Key'] ?? '')
          .toString(),
      label: (json['label'] ?? json['Label'] ?? '').toString(),
      type: (json['type'] ?? json['Type'] ?? 'text').toString(),
      requiredField: (json['required'] ?? json['Required'] ?? false) == true,
      options: list
          .map((e) => DsrOptionItem.fromJson(Map<String, dynamic>.from(e)))
          .toList(),
    );
  }
}

class DsrTemplate {
  final String dsrParam;
  final String deptCode;
  final String formMode;
  final bool submissionDateFixed;
  final bool reportDateEditable;
  final bool customerSelectionRequired;
  final bool customerCodeRequired;
  final bool productGridRequired;
  final bool actionGridRequired;
  final bool projectQtyRequired;
  final bool areaRequired;
  final bool pinCodeRequired;
  final bool mobileRequired;
  final bool counterTypeRequired;
  final bool nearestStockiestRequired;
  final bool showAttachmentSection;
  final bool showGiftSection;
  final bool showCompetitorAvgSection;
  final bool showStockAvailabilitySection;
  final bool showEnrolmentSection;
  final bool showOrderBookedSection;
  final bool showMarketPriceSection;
  final bool showLocationSection;
  final bool useCurrentLocationValidation;
  final List<DsrFieldConfig> fields;

  const DsrTemplate({
    required this.dsrParam,
    required this.deptCode,
    required this.formMode,
    required this.submissionDateFixed,
    required this.reportDateEditable,
    required this.customerSelectionRequired,
    required this.customerCodeRequired,
    required this.productGridRequired,
    required this.actionGridRequired,
    required this.projectQtyRequired,
    required this.areaRequired,
    required this.pinCodeRequired,
    required this.mobileRequired,
    required this.counterTypeRequired,
    required this.nearestStockiestRequired,
    required this.showAttachmentSection,
    required this.showGiftSection,
    required this.showCompetitorAvgSection,
    required this.showStockAvailabilitySection,
    required this.showEnrolmentSection,
    required this.showOrderBookedSection,
    required this.showMarketPriceSection,
    required this.showLocationSection,
    required this.useCurrentLocationValidation,
    required this.fields,
  });

  bool get isClassic => formMode == 'classic';
  bool get isNewVisit => formMode == 'newVisit';
  bool get isCasc => formMode == 'casc';

  factory DsrTemplate.fromJson(Map<String, dynamic> json) {
    final fieldsJson =
        (json['fields'] ?? json['Fields'] ?? []) as List<dynamic>;

    return DsrTemplate(
      dsrParam: (json['dsrParam'] ?? json['DsrParam'] ?? '').toString(),
      deptCode: (json['deptCode'] ?? json['DeptCode'] ?? '').toString(),
      formMode: (json['formMode'] ?? json['FormMode'] ?? 'classic').toString(),
      submissionDateFixed:
          (json['submissionDateFixed'] ??
              json['SubmissionDateFixed'] ??
              true) ==
          true,
      reportDateEditable:
          (json['reportDateEditable'] ?? json['ReportDateEditable'] ?? true) ==
          true,
      customerSelectionRequired:
          (json['customerSelectionRequired'] ??
              json['CustomerSelectionRequired'] ??
              false) ==
          true,
      customerCodeRequired:
          (json['customerCodeRequired'] ??
              json['CustomerCodeRequired'] ??
              false) ==
          true,
      productGridRequired:
          (json['productGridRequired'] ??
              json['ProductGridRequired'] ??
              false) ==
          true,
      actionGridRequired:
          (json['actionGridRequired'] ?? json['ActionGridRequired'] ?? false) ==
          true,
      projectQtyRequired:
          (json['projectQtyRequired'] ?? json['ProjectQtyRequired'] ?? false) ==
          true,
      areaRequired:
          (json['areaRequired'] ?? json['AreaRequired'] ?? false) == true,
      pinCodeRequired:
          (json['pinCodeRequired'] ?? json['PinCodeRequired'] ?? false) == true,
      mobileRequired:
          (json['mobileRequired'] ?? json['MobileRequired'] ?? false) == true,
      counterTypeRequired:
          (json['counterTypeRequired'] ??
              json['CounterTypeRequired'] ??
              false) ==
          true,
      nearestStockiestRequired:
          (json['nearestStockiestRequired'] ??
              json['NearestStockiestRequired'] ??
              false) ==
          true,
      showAttachmentSection:
          (json['showAttachmentSection'] ??
              json['ShowAttachmentSection'] ??
              false) ==
          true,
      showGiftSection:
          (json['showGiftSection'] ?? json['ShowGiftSection'] ?? false) == true,
      showCompetitorAvgSection:
          (json['showCompetitorAvgSection'] ??
              json['ShowCompetitorAvgSection'] ??
              false) ==
          true,
      showStockAvailabilitySection:
          (json['showStockAvailabilitySection'] ??
              json['ShowStockAvailabilitySection'] ??
              false) ==
          true,
      showEnrolmentSection:
          (json['showEnrolmentSection'] ??
              json['ShowEnrolmentSection'] ??
              false) ==
          true,
      showOrderBookedSection:
          (json['showOrderBookedSection'] ??
              json['ShowOrderBookedSection'] ??
              false) ==
          true,
      showMarketPriceSection:
          (json['showMarketPriceSection'] ??
              json['ShowMarketPriceSection'] ??
              false) ==
          true,
      showLocationSection:
          (json['showLocationSection'] ??
              json['ShowLocationSection'] ??
              false) ==
          true,
      useCurrentLocationValidation:
          (json['useCurrentLocationValidation'] ??
              json['UseCurrentLocationValidation'] ??
              false) ==
          true,
      fields: fieldsJson
          .map((e) => DsrFieldConfig.fromJson(Map<String, dynamic>.from(e)))
          .toList(),
    );
  }
}

class DsrParty {
  final String code;
  final String name;
  final String mobileNo;
  final String locaCapr;
  final String subArCod;
  final String district;
  final String pinCodeN;
  final String cityName;
  final String latitute;
  final String lgtitute;
  final String kycVerFl;
  final String mrktName;

  const DsrParty({
    required this.code,
    required this.name,
    required this.mobileNo,
    required this.locaCapr,
    this.subArCod = '',
    this.district = '',
    this.pinCodeN = '',
    this.cityName = '',
    required this.latitute,
    required this.lgtitute,
    required this.kycVerFl,
    required this.mrktName,
  });

  factory DsrParty.fromJson(Map<String, dynamic> json) {
    return DsrParty(
      code: (json['code'] ?? json['Code'] ?? '').toString(),
      name: (json['name'] ?? json['Name'] ?? '').toString(),
      mobileNo: (json['mobileNo'] ?? json['MobileNo'] ?? '').toString(),
      locaCapr: (json['locaCapr'] ?? json['LocaCapr'] ?? '').toString(),
      subArCod:
          (json['subArCod'] ?? json['SubArCod'] ?? json['sub_ar_cod'] ?? '')
              .toString(),
      district: (json['district'] ?? json['District'] ?? '').toString(),
      pinCodeN: (json['pinCodeN'] ?? json['PinCodeN'] ?? '').toString(),
      cityName: (json['cityName'] ?? json['CityName'] ?? '').toString(),
      latitute: (json['latitute'] ?? json['Latitute'] ?? '').toString(),
      lgtitute: (json['lgtitute'] ?? json['Lgtitute'] ?? '').toString(),
      kycVerFl: (json['kycVerFl'] ?? json['KycVerFl'] ?? '').toString(),
      mrktName: (json['mrktName'] ?? json['MrktName'] ?? '').toString(),
    );
  }
}

class DsrDocumentSummary {
  final String docuNumb;
  final String docuDate;
  final String dsrParam;
  final String activityName;

  const DsrDocumentSummary({
    required this.docuNumb,
    required this.docuDate,
    required this.dsrParam,
    required this.activityName,
  });

  factory DsrDocumentSummary.fromJson(Map<String, dynamic> json) {
    return DsrDocumentSummary(
      docuNumb: (json['docuNumb'] ?? json['DocuNumb'] ?? '').toString(),
      docuDate: (json['docuDate'] ?? json['DocuDate'] ?? '').toString(),
      dsrParam: (json['dsrParam'] ?? json['DsrParam'] ?? '').toString(),
      activityName: (json['activityName'] ?? json['ActivityName'] ?? '')
          .toString(),
    );
  }
}

class DsrClassicRow {
  String repoCatg;
  String catgPack;
  String prodQnty;
  String projQnty;
  String prodQtyV;
  String actnRemk;
  String targetDt;
  String mrktData;

  DsrClassicRow({
    this.repoCatg = '',
    this.catgPack = '',
    this.prodQnty = '',
    this.projQnty = '',
    this.prodQtyV = '',
    this.actnRemk = '',
    this.targetDt = '',
    this.mrktData = '',
  });

  factory DsrClassicRow.fromJson(Map<String, dynamic> json) {
    return DsrClassicRow(
      repoCatg: (json['repoCatg'] ?? json['RepoCatg'] ?? '').toString(),
      catgPack: (json['catgPack'] ?? json['CatgPack'] ?? '').toString(),
      prodQnty: (json['prodQnty'] ?? json['ProdQnty'] ?? '').toString(),
      projQnty: (json['projQnty'] ?? json['ProjQnty'] ?? '').toString(),
      prodQtyV: (json['prodQtyV'] ?? json['ProdQtyV'] ?? '').toString(),
      actnRemk: (json['actnRemk'] ?? json['ActnRemk'] ?? '').toString(),
      targetDt: (json['targetDt'] ?? json['TargetDt'] ?? '').toString(),
      mrktData: (json['mrktData'] ?? json['MrktData'] ?? '').toString(),
    );
  }

  Map<String, dynamic> toJson() => {
    'RepoCatg': repoCatg,
    'CatgPack': catgPack,
    'ProdQnty': prodQnty,
    'ProjQnty': projQnty,
    'ProdQtyV': prodQtyV,
    'ActnRemk': actnRemk,
    'TargetDt': targetDt,
    'MrktData': mrktData,
  };
}

class DsrNewVisitOrderRow {
  String repoCatg;
  String catgPack;
  String prodQnty;
  String projQnty;

  DsrNewVisitOrderRow({
    this.repoCatg = '',
    this.catgPack = '',
    this.prodQnty = '',
    this.projQnty = '',
  });

  factory DsrNewVisitOrderRow.fromJson(Map<String, dynamic> json) {
    return DsrNewVisitOrderRow(
      repoCatg: (json['repoCatg'] ?? json['RepoCatg'] ?? '').toString(),
      catgPack: (json['catgPack'] ?? json['CatgPack'] ?? '').toString(),
      prodQnty: (json['prodQnty'] ?? json['ProdQnty'] ?? '').toString(),
      projQnty: (json['projQnty'] ?? json['ProjQnty'] ?? '').toString(),
    );
  }
}

class DsrMarketPriceRow {
  String brandCode;
  String skuCode;
  String bPrice;
  String cPrice;

  DsrMarketPriceRow({
    this.brandCode = '',
    this.skuCode = '',
    this.bPrice = '',
    this.cPrice = '',
  });

  factory DsrMarketPriceRow.fromJson(Map<String, dynamic> json) {
    return DsrMarketPriceRow(
      brandCode: (json['repoCatg'] ?? json['BrandCode'] ?? '').toString(),
      skuCode: (json['catgPack'] ?? json['SkuCode'] ?? '').toString(),
      bPrice: (json['prodQnty'] ?? json['BPrice'] ?? '').toString(),
      cPrice: (json['projQnty'] ?? json['CPrice'] ?? '').toString(),
    );
  }
}

class DsrGiftRow {
  String mrtlCode;
  String isueQnty;

  DsrGiftRow({this.mrtlCode = '', this.isueQnty = ''});

  factory DsrGiftRow.fromJson(Map<String, dynamic> json) {
    return DsrGiftRow(
      mrtlCode: (json['mrtlCode'] ?? json['MrtlCode'] ?? '').toString(),
      isueQnty: (json['isueQnty'] ?? json['IsueQnty'] ?? '').toString(),
    );
  }
}

/// Attachment reference sent to the backend.
/// [tempDocuNumb] is used as AtchNmId (the image GUID / upload key).
/// [fileName] is the file name stored in imagedata DB.
class DsrAttachmentRef {
  final String tempDocuNumb;
  final String attFilTy;
  final String fileName;

  const DsrAttachmentRef({
    required this.tempDocuNumb,
    required this.attFilTy,
    this.fileName = '',
  });

  Map<String, dynamic> toJson() => {
    'AtchNmId': tempDocuNumb,
    'AttFilTy': attFilTy,
    'FileName': fileName,
  };
}

class LocalDsrAttachment {
  final String attFilTy;
  final String filePath;
  final String tempDocuNumb;

  const LocalDsrAttachment({
    required this.attFilTy,
    required this.filePath,
    required this.tempDocuNumb,
  });
}

/// Simplified save request that matches the new backend DsrController DTO.
///
/// Key differences from the old model:
/// - Removed all specialized market-metric top-level fields (wcRakQty, bwWcp5kg, etc.)
/// - Removed orderRows / marketPriceRows / giftRows — caller merges these into
///   [marketMappingRows] before constructing this object.
/// - geoLatit / geoLongt are sent as Latitute / Lgtitute in JSON.
/// - Attachments now serialise as AtchNmId / AttFilTy / FileName.
class DsrSaveRequest {
  final String procType;
  final String formMode;
  final String? docuNumb;
  final String loginId;
  final String deptCode;
  final String docuDate;
  final String ordExDat;
  final String dsrParam;
  final String cusRtlFl;
  final String areaCode;
  final String cusRtlCd;
  final String cuRtType;

  final String dsrRem01;
  final String dsrRem02;
  final String dsrRem03;
  final String dsrRem04;
  final String dsrRem05;
  final String dsrRem06;
  final String dsrRem07;
  final String dsrRem08;
  final String dsrRem09;
  final String dsrRem10;

  final String district;
  final String pinCodeN;
  final String cityName;
  final String cstBisTy;

  final String isTilRtl;
  final String tileStck;

  final String locaCapr;
  final String geoLatit; // serialised as Latitute
  final String geoLongt; // serialised as Lgtitute
  final String ltLgDist;
  final String zoneCode;
  final String subArCod;

  /// Classic product detail rows (mrktData = '').
  final List<DsrClassicRow> classicRows;

  /// All market-metric rows (mrktData = '01','02','04','05','06').
  /// Caller is responsible for merging order rows, price rows, metric rows here.
  final List<DsrClassicRow> marketMappingRows;

  final List<DsrAttachmentRef> attachments;

  const DsrSaveRequest({
    required this.procType,
    required this.formMode,
    this.docuNumb,
    required this.loginId,
    required this.deptCode,
    required this.docuDate,
    required this.ordExDat,
    required this.dsrParam,
    required this.cusRtlFl,
    required this.areaCode,
    required this.cusRtlCd,
    required this.cuRtType,
    required this.dsrRem01,
    required this.dsrRem02,
    required this.dsrRem03,
    required this.dsrRem04,
    required this.dsrRem05,
    required this.dsrRem06,
    required this.dsrRem07,
    required this.dsrRem08,
    required this.dsrRem09,
    required this.dsrRem10,
    required this.district,
    required this.pinCodeN,
    required this.cityName,
    required this.cstBisTy,
    required this.isTilRtl,
    required this.tileStck,
    required this.locaCapr,
    required this.geoLatit,
    required this.geoLongt,
    required this.ltLgDist,
    required this.zoneCode,
    required this.subArCod,
    required this.classicRows,
    required this.marketMappingRows,
    required this.attachments,
  });

  Map<String, dynamic> toJson() => {
    'ProcType': procType,
    'FormMode': formMode,
    if (docuNumb != null && docuNumb!.isNotEmpty) 'DocuNumb': docuNumb,
    'LoginId': loginId,
    'DeptCode': deptCode,
    'DocuDate': docuDate,
    'OrdExDat': ordExDat,
    'DsrParam': dsrParam,
    'CusRtlFl': cusRtlFl,
    'ZoneCode': zoneCode,
    'AreaCode': areaCode,
    'CusRtlCd': cusRtlCd,
    'CuRtType': cuRtType,
    'SubArCod': subArCod,
    'DsrRem01': dsrRem01,
    'DsrRem02': dsrRem02,
    'DsrRem03': dsrRem03,
    'DsrRem04': dsrRem04,
    'DsrRem05': dsrRem05,
    'DsrRem06': dsrRem06,
    'DsrRem07': dsrRem07,
    'DsrRem08': dsrRem08,
    'DsrRem09': dsrRem09,
    'DsrRem10': dsrRem10,
    // District is compatibility-only; primary hierarchy uses ZoneCode/AreaCode/SubArCod
    'District': district,
    'PinCodeN': pinCodeN,
    'CityName': cityName,
    'CstBisTy': cstBisTy,
    'IsTilRtl': isTilRtl,
    'TileStck': tileStck,
    'LocaCapr': locaCapr,
    'Latitute': geoLatit,
    'Lgtitute': geoLongt,
    'LtLgDist': ltLgDist,
    'ClassicRows': classicRows.map((e) => e.toJson()).toList(),
    'MarketMetricRows': marketMappingRows.map((e) => e.toJson()).toList(),
    'Attachments': attachments.map((e) => e.toJson()).toList(),
  };
}

class DsrSaveResponse {
  final bool success;
  final String message;
  final String docuNumb;
  final String error;

  const DsrSaveResponse({
    required this.success,
    required this.message,
    required this.docuNumb,
    required this.error,
  });

  factory DsrSaveResponse.fromJson(Map<String, dynamic> json) {
    final errors = (json['errors'] as List<dynamic>? ?? const <dynamic>[])
        .map((e) => e.toString().trim())
        .where((e) => e.isNotEmpty)
        .toList();
    final baseMessage = (json['message'] ?? '').toString();
    final baseError = (json['error'] ?? '').toString();
    final combinedMessage = errors.isEmpty
        ? baseMessage
        : [baseMessage, ...errors].where((e) => e.isNotEmpty).join('\n');

    return DsrSaveResponse(
      success: json['success'] == true,
      message: combinedMessage.isNotEmpty ? combinedMessage : baseError,
      docuNumb: (json['docuNumb'] ?? '').toString(),
      error: errors.isNotEmpty ? errors.join('\n') : baseError,
    );
  }
}
