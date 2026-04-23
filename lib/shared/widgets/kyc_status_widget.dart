import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import '../../core/models/kyc_status_models.dart';

class KycStatusWidget extends StatelessWidget {
  final KycStatusResponse status;
  final VoidCallback? onRefresh;

  const KycStatusWidget({
    super.key,
    required this.status,
    this.onRefresh,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.all(16.w),
      decoration: BoxDecoration(
        color: _getBackgroundColor(),
        borderRadius: BorderRadius.circular(12.r),
        border: Border.all(
          color: _getBorderColor(),
          width: 2,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: EdgeInsets.all(8.w),
                decoration: BoxDecoration(
                  color: _getIconBackgroundColor(),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  _getStatusIcon(),
                  color: _getIconColor(),
                  size: 24.sp,
                ),
              ),
              SizedBox(width: 12.w),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Approval Status',
                      style: TextStyle(
                        fontSize: 14.sp,
                        color: Colors.grey[600],
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    SizedBox(height: 4.h),
                    Text(
                      status.statusText,
                      style: TextStyle(
                        fontSize: 16.sp,
                        fontWeight: FontWeight.bold,
                        color: _getTextColor(),
                      ),
                    ),
                  ],
                ),
              ),
              if (onRefresh != null)
                IconButton(
                  icon: Icon(
                    Icons.refresh_rounded,
                    color: Colors.grey[600],
                  ),
                  onPressed: onRefresh,
                  tooltip: 'Refresh Status',
                ),
            ],
          ),
          SizedBox(height: 12.h),
          _buildProgressIndicator(),
          if (status.inflCode.isNotEmpty) ...[
            SizedBox(height: 12.h),
            Text(
              'Reference: ${status.inflCode}',
              style: TextStyle(
                fontSize: 12.sp,
                color: Colors.grey[600],
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildProgressIndicator() {
    return Column(
      children: [
        Row(
          children: [
            _buildProgressStep(
              'Submitted',
              true,
              Icons.check_circle,
            ),
            _buildProgressLine(status.isEidApproved || status.isFullyApproved),
            _buildProgressStep(
              'EID Approved',
              status.isEidApproved || status.isFullyApproved,
              Icons.credit_card,
            ),
            _buildProgressLine(status.isFullyApproved),
            _buildProgressStep(
              'Fully Approved',
              status.isFullyApproved,
              Icons.verified_user,
            ),
          ],
        ),
        if (status.isRejected) ...[
          SizedBox(height: 12.h),
          Container(
            padding: EdgeInsets.all(12.w),
            decoration: BoxDecoration(
              color: Colors.red[50],
              borderRadius: BorderRadius.circular(8.r),
            ),
            child: Row(
              children: [
                Icon(
                  Icons.error_outline,
                  color: Colors.red[700],
                  size: 20.sp,
                ),
                SizedBox(width: 8.w),
                Expanded(
                  child: Text(
                    'Your registration has been rejected. Please contact support.',
                    style: TextStyle(
                      fontSize: 12.sp,
                      color: Colors.red[700],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildProgressStep(String label, bool isActive, IconData icon) {
    return Expanded(
      child: Column(
        children: [
          Container(
            width: 32.w,
            height: 32.h,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: isActive
                  ? (status.isRejected ? Colors.red : const Color(0xFF10B981))
                  : Colors.grey[300],
            ),
            child: Icon(
              icon,
              color: Colors.white,
              size: 16.sp,
            ),
          ),
          SizedBox(height: 4.h),
          Text(
            label,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 10.sp,
              color: isActive ? Colors.grey[800] : Colors.grey[500],
              fontWeight: isActive ? FontWeight.w600 : FontWeight.normal,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildProgressLine(bool isActive) {
    return Expanded(
      child: Container(
        height: 2.h,
        margin: EdgeInsets.only(bottom: 20.h),
        color: isActive
            ? (status.isRejected ? Colors.red : const Color(0xFF10B981))
            : Colors.grey[300],
      ),
    );
  }

  Color _getBackgroundColor() {
    if (status.isFullyApproved) {
      return const Color(0xFFD1FAE5);
    } else if (status.isEidApproved) {
      return const Color(0xFFDEEDFF);
    } else if (status.isRejected) {
      return const Color(0xFFFEE2E2);
    } else {
      return const Color(0xFFFEF3C7);
    }
  }

  Color _getBorderColor() {
    if (status.isFullyApproved) {
      return const Color(0xFF10B981);
    } else if (status.isEidApproved) {
      return const Color(0xFF3B82F6);
    } else if (status.isRejected) {
      return const Color(0xFFEF4444);
    } else {
      return const Color(0xFFF59E0B);
    }
  }

  Color _getIconBackgroundColor() {
    if (status.isFullyApproved) {
      return const Color(0xFF10B981).withOpacity(0.2);
    } else if (status.isEidApproved) {
      return const Color(0xFF3B82F6).withOpacity(0.2);
    } else if (status.isRejected) {
      return const Color(0xFFEF4444).withOpacity(0.2);
    } else {
      return const Color(0xFFF59E0B).withOpacity(0.2);
    }
  }

  Color _getIconColor() {
    if (status.isFullyApproved) {
      return const Color(0xFF10B981);
    } else if (status.isEidApproved) {
      return const Color(0xFF3B82F6);
    } else if (status.isRejected) {
      return const Color(0xFFEF4444);
    } else {
      return const Color(0xFFF59E0B);
    }
  }

  Color _getTextColor() {
    if (status.isFullyApproved) {
      return const Color(0xFF065F46);
    } else if (status.isEidApproved) {
      return const Color(0xFF1E40AF);
    } else if (status.isRejected) {
      return const Color(0xFF991B1B);
    } else {
      return const Color(0xFF92400E);
    }
  }

  IconData _getStatusIcon() {
    if (status.isFullyApproved) {
      return Icons.verified_user;
    } else if (status.isEidApproved) {
      return Icons.credit_card;
    } else if (status.isRejected) {
      return Icons.cancel;
    } else {
      return Icons.pending;
    }
  }
}
