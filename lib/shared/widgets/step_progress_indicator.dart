import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import '../../core/theme/app_colors.dart';

/// Reusable multi-step progress indicator.
/// Replaces the duplicated _buildProgressIndicator, _buildProgressStep,
/// and _buildProgressLine methods in contractor, painter, and DSR screens.
///
/// Usage:
/// ```dart
/// StepProgressIndicator(
///   currentStep: _currentStep,
///   totalSteps: 5,
///   stepLabels: ['Mobile', 'Emirates ID', 'Personal', 'Business', 'Bank'],
/// )
/// ```
class StepProgressIndicator extends StatelessWidget {
  final int currentStep;
  final int totalSteps;
  final List<String> stepLabels;
  final Color? activeColor;
  final Color? inactiveColor;
  final String? statusText;

  const StepProgressIndicator({
    super.key,
    required this.currentStep,
    required this.totalSteps,
    required this.stepLabels,
    this.activeColor,
    this.inactiveColor,
    this.statusText,
  }) : assert(stepLabels.length == totalSteps);

  @override
  Widget build(BuildContext context) {
    final active = activeColor ?? AppColors.primaryNavy;
    final inactive = inactiveColor ?? Colors.grey.shade300;

    return Container(
      padding: EdgeInsets.all(16.w),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.7),
        borderRadius: BorderRadius.circular(12.r),
        border: Border.all(color: Colors.grey.shade200, width: 1),
      ),
      child: Column(
        children: [
          Row(
            children: _buildStepRow(active, inactive),
          ),
          SizedBox(height: 12.h),
          Text(
            statusText ?? 'Step $currentStep of $totalSteps: ${stepLabels[currentStep - 1]}',
            style: TextStyle(
              color: Colors.grey.shade600,
              fontSize: 14.sp,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  List<Widget> _buildStepRow(Color active, Color inactive) {
    final widgets = <Widget>[];
    for (int i = 1; i <= totalSteps; i++) {
      widgets.add(_buildStep(i, stepLabels[i - 1], currentStep >= i, active, inactive));
      if (i < totalSteps) {
        widgets.add(_buildLine(currentStep > i, active, inactive));
      }
    }
    return widgets;
  }

  Widget _buildStep(int step, String title, bool isActive, Color active, Color inactive) {
    return Column(
      children: [
        Container(
          width: 40.w,
          height: 40.h,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: isActive ? active : inactive,
            boxShadow: isActive
                ? [
                    BoxShadow(
                      color: active.withValues(alpha: 0.3),
                      blurRadius: 8.r,
                      offset: Offset(0, 2.h),
                    ),
                  ]
                : null,
          ),
          child: Center(
            child: step <= currentStep
                ? Icon(
                    step < currentStep ? Icons.check_rounded : Icons.circle,
                    color: Colors.white,
                    size: step < currentStep ? 20.sp : 8.sp,
                  )
                : Text(
                    '$step',
                    style: TextStyle(
                      color: Colors.grey.shade600,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
          ),
        ),
        SizedBox(height: 8.h),
        Text(
          title,
          style: TextStyle(
            color: isActive ? active : Colors.grey.shade600,
            fontSize: 12.sp,
            fontWeight: isActive ? FontWeight.w600 : FontWeight.normal,
          ),
        ),
      ],
    );
  }

  Widget _buildLine(bool isActive, Color active, Color inactive) {
    return Expanded(
      child: Container(
        height: 2.h,
        margin: EdgeInsets.symmetric(horizontal: 8.w),
        decoration: BoxDecoration(
          color: isActive ? active : inactive,
          borderRadius: BorderRadius.circular(1.r),
        ),
      ),
    );
  }
}
