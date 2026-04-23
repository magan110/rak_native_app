import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:rak_app/core/services/auth_service.dart';
import 'package:provider/provider.dart';
import 'package:rak_app/core/providers/auth_provider.dart';

/// Quick actions grid extracted from HomeScreen.
class HomeQuickActions extends StatelessWidget {
  final bool isTablet;
  final bool isLandscape;
  final double screenWidth;

  const HomeQuickActions({
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
          'Quick Actions',
          style: TextStyle(
            fontSize: 18.sp,
            fontWeight: FontWeight.bold,
            color: const Color(0xFF1F2937),
          ),
        ),
        SizedBox(height: 12.h),
        GridView.count(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          crossAxisCount: 2,
          crossAxisSpacing: 12.w,
          mainAxisSpacing: 12.h,
          childAspectRatio: 1.1,
          children: [
            _buildQuickActionCard(
              context,
              'Products',
              Icons.inventory_2,
              const Color(0xFF10B981),
              () {
                context.push('/product-details');
              },
            ),
            _buildQuickActionCard(
              context,
              'DSR Entry',
              Icons.assignment,
              const Color(0xFF3B82F6),
              () {
                final currentUser = context.read<AuthProvider>().currentUser;
                final loginId =
                    currentUser?.userID ?? currentUser?.emplName ?? '';
                context.push('/dsr-entry', extra: {'loginId': loginId});
              },
            ),
            _buildQuickActionCard(
              context,
              'Sample Distribution',
              Icons.inventory_2_outlined,
              const Color(0xFFF59E0B),
              () {
                context.push('/sample-distribution');
              },
            ),
            _buildQuickActionCard(
              context,
              'Activity Entry',
              Icons.event_note_outlined,
              const Color(0xFFEF4444),
              () {
                context.push('/activity-entry');
              },
            ),
            _buildQuickActionCard(
              context,
              'Sample Execution',
              Icons.science_outlined,
              const Color(0xFF8B5CF6),
              () {
                context.push('/sample-execution');
              },
            ),
            _buildQuickActionCard(
              context,
              'User Management',
              Icons.people_outline,
              const Color(0xFF06B6D4),
              () {
                context.push('/user-list');
              },
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildQuickActionCard(
    BuildContext context,
    String title,
    IconData icon,
    Color color,
    VoidCallback onTap,
  ) {
    return TweenAnimationBuilder<double>(
      duration: const Duration(milliseconds: 600),
      tween: Tween<double>(begin: 0.9, end: 1.0),
      builder: (context, scale, child) {
        return Transform.scale(
          scale: scale,
          child: GestureDetector(
            onTap: () {
              HapticFeedback.lightImpact();
              onTap();
            },
            child: Container(
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
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    width: 48.w,
                    height: 48.h,
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [color, color.withOpacity(0.8)],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      borderRadius: BorderRadius.circular(12.r),
                      boxShadow: [
                        BoxShadow(
                          color: color.withOpacity(0.2),
                          blurRadius: 5.r,
                          offset: Offset(0, 2.h),
                        ),
                      ],
                    ),
                    child: Icon(icon, color: Colors.white, size: 22.sp),
                  ),
                  SizedBox(height: 8.h),
                  Text(
                    title,
                    style: TextStyle(
                      fontSize: 12.sp,
                      fontWeight: FontWeight.w600,
                      color: const Color(0xFF1F2937),
                    ),
                    textAlign: TextAlign.center,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}
