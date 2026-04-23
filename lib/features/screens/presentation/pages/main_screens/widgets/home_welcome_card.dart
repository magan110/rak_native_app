import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:rak_app/shared/widgets/combined_logo_widget.dart';

/// Extracted welcome card from `home_screen.dart`.
/// Keeps the same visuals and accepts the scale animation from the parent.
class HomeWelcomeCard extends StatelessWidget {
  final bool isTablet;
  final double screenWidth;
  final Animation<double> scaleAnimation;

  const HomeWelcomeCard({
    super.key,
    required this.isTablet,
    required this.screenWidth,
    required this.scaleAnimation,
  });

  @override
  Widget build(BuildContext context) {
    final cardPadding = isTablet ? 28.0 : 20.0;
    final titleFontSize = isTablet ? 28.0 : 24.0;
    final subtitleFontSize = isTablet ? 13.0 : 11.0;
    final logoSize = isTablet ? 80.0 : 60.0;

    return ScaleTransition(
      scale: scaleAnimation,
      child: Container(
        width: double.infinity,
        padding: EdgeInsets.all(cardPadding),
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            colors: [Color(0xFF1E3A8A), Color(0xFF3B82F6)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular((isTablet ? 20 : 16).r),
          boxShadow: [
            BoxShadow(
              color: const Color(0xFF1E3A8A).withOpacity(0.2),
              blurRadius: (isTablet ? 15 : 10).r,
              offset: Offset(0, (isTablet ? 6 : 4).h),
              spreadRadius: 0,
            ),
          ],
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    padding: EdgeInsets.symmetric(
                      horizontal: (isTablet ? 12 : 8).w,
                      vertical: (isTablet ? 5 : 3).h,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.2),
                      borderRadius: BorderRadius.circular((isTablet ? 8 : 6).r),
                    ),
                    child: Text(
                      'Welcome Back !',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: (isTablet ? 12 : 10).sp,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                  SizedBox(height: (isTablet ? 14 : 10).h),
                  Text(
                    'Welcome',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: titleFontSize,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  SizedBox(height: (isTablet ? 8 : 6).h),
                  Text(
                    'RAK White Cement &\nConstruction Materials',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: subtitleFontSize,
                      height: 1.3,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
            SizedBox(width: (isTablet ? 20 : 16).w),
            Container(
              width: logoSize * 2.4,
              height: logoSize * 1.5,
              decoration: BoxDecoration(
                border: Border.all(color: const Color(0xFF2C5282), width: 2.0),
                borderRadius: BorderRadius.circular((isTablet ? 14 : 12).r),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.1),
                    blurRadius: 8,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Container(
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular((isTablet ? 12 : 10).r),
                ),
                padding: EdgeInsets.symmetric(
                  vertical: 0.0,
                  horizontal: (isTablet ? 4 : 3).w,
                ),
                child: CombinedLogoWidget(
                  height: (isTablet ? 70 : 55).sp,
                  width: (isTablet ? 180 : 140).sp,
                  fit: BoxFit.contain,
                  isCircular: false,
                  showBorder: false,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
