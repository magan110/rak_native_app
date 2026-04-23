class AreaItem {
  final String code;
  final String desc;

  AreaItem({required this.code, required this.desc});

  factory AreaItem.fromJson(Map<String, dynamic> json) {
    return AreaItem(
      code: (json['code'] ?? json['areaCode'])?.toString().trim() ?? '',
      desc: (json['desc'] ?? json['areaDesc'])?.toString().trim() ?? '',
    );
  }
}

class ActivityParticipant {
  final String attnType; // single-char code: P, C, R, T, A, O
  final String attnCode;
  final String partName;
  final String partMobl;
  final String kycStsFl; // N, P, F
  final int? giftQnty;
  final String giftItem;

  ActivityParticipant({
    required this.attnType,
    required this.attnCode,
    required this.partName,
    required this.partMobl,
    required this.kycStsFl,
    this.giftQnty,
    required this.giftItem,
  });

  /// Map single-char attnType to full label for backend partType
  static String _typeCodeToLabel(String code) {
    switch (code) {
      case 'P':
        return 'Painter';
      case 'C':
        return 'Contractor';
      case 'R':
        return 'Retailer';
      case 'T':
        return 'Tile Applicator';
      case 'A':
        return 'Architect';
      case 'O':
        return 'Other';
      default:
        return code;
    }
  }

  /// Map KYC single-char to full label
  static String _kycCodeToText(String code) {
    switch (code) {
      case 'N':
        return 'No';
      case 'P':
        return 'Partial';
      case 'F':
        return 'Full';
      default:
        return code;
    }
  }

  Map<String, dynamic> toJson() {
    return {
      "attnType": "I", // main participant
      "attnCode": attnCode,
      "partType": _typeCodeToLabel(attnType),
      "name": partName,
      "mobileNo": partMobl,
      "kycSts": kycStsFl,
      "kycText": _kycCodeToText(kycStsFl),
      "retlCode": "",
      "codeName": attnCode,
      "giftFlag": (giftQnty != null && giftQnty! > 0) ? "Y" : "N",
      "appDownd": "",
    };
  }
}

class ActivityEntryRequest {
  final String loginId;
  final String areaCode;
  final String actvName;
  final String caaActTy;
  final String caaObjTy;
  final String meetDate;
  final String meetVenu;
  final String venuAddr;
  final String actvCity;
  final String district;
  final String pinCodeN;
  final String actvRmrk;
  final String mobileNo;
  final String latitude;
  final String longitude;
  final String giftDist;
  final int? giftQnty;
  final String giftByWh;
  final double? amtSpend;
  final String claimLnk;
  final String statFlag;
  final int? noOfEnqu;
  final int? noOfVist;
  final String empPrsLs;
  final String tempDocuNumb;
  final List<String> prodList;
  final List<ActivityParticipant> participants;

  ActivityEntryRequest({
    required this.loginId,
    required this.areaCode,
    required this.actvName,
    required this.caaActTy,
    required this.caaObjTy,
    required this.meetDate,
    required this.meetVenu,
    required this.venuAddr,
    required this.actvCity,
    required this.district,
    required this.pinCodeN,
    required this.actvRmrk,
    required this.mobileNo,
    required this.latitude,
    required this.longitude,
    required this.giftDist,
    this.giftQnty,
    required this.giftByWh,
    this.amtSpend,
    required this.claimLnk,
    required this.statFlag,
    this.noOfEnqu,
    this.noOfVist,
    required this.empPrsLs,
    required this.tempDocuNumb,
    required this.prodList,
    required this.participants,
  });

  Map<String, dynamic> toJson() {
    // Build uploadKeys from tempDocuNumb
    final List<String> uploadKeys = [];
    if (tempDocuNumb.isNotEmpty) {
      uploadKeys.add(tempDocuNumb);
    }

    return {
      "procType": "A", // Add mode
      "loginId": loginId,
      "areaCode": areaCode,
      "actvName": actvName,
      "caaActTy": caaActTy,
      // Dates as strings (backend parses them)
      "actvDate": meetDate,
      "meetDate": meetDate,
      "meetVenu": meetVenu,
      "actvCity": actvCity,
      "district": district,
      "pinCodeN": pinCodeN,
      "actvRmrk": actvRmrk,
      "mobileNo": mobileNo,
      // Coordinates as strings (backend's ToSparshNumericText handles them)
      "latitude": latitude,
      "longtude": longitude,
      // Gift & financial fields (separate top-level fields)
      "giftDisb": giftDist,
      "giftQty": giftQnty,
      "giftPurBy": giftByWh,
      "amntSpnt": amtSpend,
      "statFlag": statFlag,
      "noOfEnqu": noOfEnqu,
      "noOfVist": noOfVist,
      "noOfPart": participants.length,
      // Products as prodCtLs
      "prodCtLs": prodList,
      // Participants list
      "participants": participants.map((e) => e.toJson()).toList(),
      // Upload keys for temp doc linking
      "uploadKeys": uploadKeys,
    };
  }
}

class ActivitySubmitResponse {
  final bool success;
  final String message;
  final String? docuNumb;

  ActivitySubmitResponse({
    required this.success,
    required this.message,
    this.docuNumb,
  });

  factory ActivitySubmitResponse.fromJson(Map<String, dynamic> json) {
    return ActivitySubmitResponse(
      success: json['success'] == true,
      message: json['message']?.toString() ?? '',
      docuNumb: json['docuNumb']?.toString(),
    );
  }
}
