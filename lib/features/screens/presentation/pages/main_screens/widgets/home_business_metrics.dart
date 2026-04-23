import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

/// Business metrics block extracted from HomeScreen.
class HomeBusinessMetrics extends StatelessWidget {
  final bool isTablet;
  final bool isLandscape;
  final double screenWidth;

  const HomeBusinessMetrics({
    super.key,
    required this.isTablet,
    required this.isLandscape,
    required this.screenWidth,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Business Overview',
          style: TextStyle(
            fontSize: 18.sp,
            fontWeight: FontWeight.bold,
            color: const Color(0xFF1F2937),
          ),
        ),
        SizedBox(height: 12.h),
        Builder(
          builder: (context) {
            final double desiredTileHeight = isTablet ? 146.h : 126.h;

            final metrics = [
              () => _buildMetricCard(
                'Total Scans',
                '0',
                '0',
                const Color(0xFF10B981),
                Icons.qr_code_scanner,
              ),
              () => _buildMetricCard(
                'Points',
                '0',
                '0',
                const Color(0xFF60A5FA),
                Icons.star,
              ),
              () => _buildMetricCard(
                'Campaigns',
                '0',
                '0',
                const Color(0xFFF59E0B),
                Icons.campaign,
              ),
              () => _buildMetricCard(
                'Target',
                '0',
                '0',
                const Color(0xFF1E3A8A),
                Icons.trending_up,
              ),
            ];

            return GridView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: metrics.length,
              gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                crossAxisSpacing: 12.w,
                mainAxisSpacing: 12.h,
                mainAxisExtent: desiredTileHeight,
              ),
              itemBuilder: (context, index) => metrics[index](),
            );
          },
        ),
      ],
    );
  }

  Widget _buildMetricCard(
    String title,
    String value,
    String change,
    Color color,
    IconData icon,
  ) {
    return TweenAnimationBuilder<double>(
      duration: const Duration(milliseconds: 600),
      tween: Tween<double>(begin: 0.0, end: 1.0),
      builder: (context, progress, child) {
        return Transform.scale(
          scale: 0.9 + (0.1 * progress),
          child: Container(
            padding: EdgeInsets.all(16.w),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12.r),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.05),
                  blurRadius: 5.r,
                  offset: Offset(0, 2.h),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  padding: EdgeInsets.all(6.w),
                  decoration: BoxDecoration(
                    color: color.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8.r),
                  ),
                  child: Icon(icon, color: color, size: 20.sp),
                ),
                const Spacer(),
                Text(
                  value,
                  style: TextStyle(
                    fontSize: 20.sp,
                    fontWeight: FontWeight.bold,
                    color: const Color(0xFF1F2937),
                  ),
                ),
                SizedBox(height: 2.h),
                Text(
                  title,
                  style: TextStyle(fontSize: 11.sp, color: Colors.grey[600]),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
