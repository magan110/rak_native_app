class KycStatusResponse {
  final bool success;
  final String inflCode;
  final String inflName;
  final String status;
  final String statusText;
  final String? message;

  KycStatusResponse({
    required this.success,
    required this.inflCode,
    required this.inflName,
    required this.status,
    required this.statusText,
    this.message,
  });

  factory KycStatusResponse.fromJson(Map<String, dynamic> json) {
    return KycStatusResponse(
      success: json['success'] ?? false,
      inflCode: json['inflCode'] ?? '',
      inflName: json['inflName'] ?? '',
      status: json['status'] ?? 'PENDING',
      statusText: json['statusText'] ?? 'Pending Approval',
      message: json['message'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'success': success,
      'inflCode': inflCode,
      'inflName': inflName,
      'status': status,
      'statusText': statusText,
      'message': message,
    };
  }

  bool get isPending => status == 'PENDING';
  bool get isEidApproved => status == 'EID_APPROVED';
  bool get isFullyApproved => status == 'FULLY_APPROVED';
  bool get isRejected => status == 'REJECTED';
}
