class ApprovalItem {
  final String id;
  final String name;
  final String type;
  final String date;
  final String status;
  final String avatar;

  ApprovalItem({
    required this.id,
    required this.name,
    required this.type,
    required this.date,
    required this.status,
    required this.avatar,
  });

  factory ApprovalItem.fromJson(Map<String, dynamic> json) {
    return ApprovalItem(
      id: json['id'] ?? '',
      name: json['name'] ?? '',
      type: json['type'] ?? 'Contractor',
      date: json['date'] ?? '',
      status: json['status'] ?? 'Pending',
      avatar: json['avatar'] ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'type': type,
      'date': date,
      'status': status,
      'avatar': avatar,
    };
  }
}

class ApprovalStats {
  final int totalPending;
  final int contractors;
  final int painters;
  final DateTime timestamp;

  ApprovalStats({
    required this.totalPending,
    required this.contractors,
    required this.painters,
    required this.timestamp,
  });

  factory ApprovalStats.fromJson(Map<String, dynamic> json) {
    return ApprovalStats(
      totalPending: json['totalPending'] ?? 0,
      contractors: json['contractors'] ?? 0,
      painters: json['painters'] ?? 0,
      timestamp: json['timestamp'] != null
          ? DateTime.parse(json['timestamp'])
          : DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'totalPending': totalPending,
      'contractors': contractors,
      'painters': painters,
      'timestamp': timestamp.toIso8601String(),
    };
  }
}

class ApprovalResponse {
  final bool success;
  final int page;
  final int pageSize;
  final int total;
  final List<ApprovalItem> items;

  ApprovalResponse({
    required this.success,
    required this.page,
    required this.pageSize,
    required this.total,
    required this.items,
  });

  factory ApprovalResponse.fromJson(Map<String, dynamic> json) {
    return ApprovalResponse(
      success: json['success'] ?? false,
      page: json['page'] ?? 1,
      pageSize: json['pageSize'] ?? 20,
      total: json['total'] ?? 0,
      items:
          (json['items'] as List<dynamic>?)
              ?.map((item) => ApprovalItem.fromJson(item))
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

class ApprovalActionRequest {
  final String inflCode;
  final String? actorId;

  ApprovalActionRequest({required this.inflCode, this.actorId});

  Map<String, dynamic> toJson() {
    return {'inflCode': inflCode, 'actorId': actorId};
  }
}

class RejectionActionRequest extends ApprovalActionRequest {
  final String? reason;

  RejectionActionRequest({required super.inflCode, super.actorId, this.reason});

  @override
  Map<String, dynamic> toJson() {
    return {'inflCode': inflCode, 'actorId': actorId, 'reason': reason};
  }
}

class ApprovalActionResponse {
  final bool success;
  final String message;
  final String? influencerCode;

  ApprovalActionResponse({
    required this.success,
    required this.message,
    this.influencerCode,
  });

  factory ApprovalActionResponse.fromJson(Map<String, dynamic> json) {
    return ApprovalActionResponse(
      success: json['success'] ?? false,
      message: json['message'] ?? '',
      influencerCode: json['influencerCode'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'success': success,
      'message': message,
      'influencerCode': influencerCode,
    };
  }
}

class RegistrationDetails {
  final bool success;
  final String id;
  final String name;
  final String type;
  final String mobile;
  final String email;
  final String submittedDate;
  final String status;
  final String fullName;
  final String address;
  final String reference;
  final String companyName;
  final String licenseNumber;
  final String trnNumber;
  final String accountHolder;
  final String iban;
  final String bankName;
  final String branch;
  final String avatar;

  RegistrationDetails({
    required this.success,
    required this.id,
    required this.name,
    required this.type,
    required this.mobile,
    required this.email,
    required this.submittedDate,
    required this.status,
    required this.fullName,
    required this.address,
    required this.reference,
    required this.companyName,
    required this.licenseNumber,
    required this.trnNumber,
    required this.accountHolder,
    required this.iban,
    required this.bankName,
    required this.branch,
    required this.avatar,
  });

  factory RegistrationDetails.fromJson(Map<String, dynamic> json) {
    return RegistrationDetails(
      success: json['success'] ?? false,
      id: json['id'] ?? '',
      name: json['name'] ?? '',
      type: json['type'] ?? '',
      mobile: json['mobile'] ?? '',
      email: json['email'] ?? '',
      submittedDate: json['submittedDate'] ?? '',
      status: json['status'] ?? '',
      fullName: json['fullName'] ?? '',
      address: json['address'] ?? '',
      reference: json['reference'] ?? '',
      companyName: json['companyName'] ?? '',
      licenseNumber: json['licenseNumber'] ?? '',
      trnNumber: json['trnNumber'] ?? '',
      accountHolder: json['accountHolder'] ?? '',
      iban: json['iban'] ?? '',
      bankName: json['bankName'] ?? '',
      branch: json['branch'] ?? '',
      avatar: json['avatar'] ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'success': success,
      'id': id,
      'name': name,
      'type': type,
      'mobile': mobile,
      'email': email,
      'submittedDate': submittedDate,
      'status': status,
      'fullName': fullName,
      'address': address,
      'reference': reference,
      'companyName': companyName,
      'licenseNumber': licenseNumber,
      'trnNumber': trnNumber,
      'accountHolder': accountHolder,
      'iban': iban,
      'bankName': bankName,
      'branch': branch,
      'avatar': avatar,
    };
  }
}
