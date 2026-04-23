import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';

/// Featured products block extracted from HomeScreen.
class HomeFeaturedProducts extends StatelessWidget {
  final PageController pageController;
  final int currentBannerIndex;
  final ValueChanged<int> onPageChanged;
  final bool isTablet;
  final bool isLandscape;
  final double screenWidth;

  const HomeFeaturedProducts({
    super.key,
    required this.pageController,
    required this.currentBannerIndex,
    required this.onPageChanged,
    required this.isTablet,
    required this.isLandscape,
    required this.screenWidth,
  });

  @override
  Widget build(BuildContext context) {
    // Responsive sizing
    final titleFontSize = isTablet ? 22.0 : 18.0;
    final cardHeight = isTablet ? 200.0 : (isLandscape ? 180.0 : 160.0);

    final products = [
      {
        'image': 'assets/images/MBF-Product-Usage1.jpeg',
        'title': 'MBF Product Range',
        'badge': 'Advanced Solutions',
        'color': '0xFF3B82F6',
      },
      {
        'image': 'assets/images/RWC-Product-Usage2-1.jpeg',
        'title': 'RWC Product Range',
        'badge': 'Premium Quality',
        'color': '0xFF10B981',
      },
      {
        'image': 'assets/images/MBF-Product-Usage3.jpeg',
        'title': 'Construction Materials',
        'badge': 'Best in Class',
        'color': '0xFFF59E0B',
      },
    ];

    return SafeArea(
      top: false,
      bottom: false,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Featured Products',
                style: TextStyle(
                  fontSize: titleFontSize,
                  fontWeight: FontWeight.bold,
                  color: const Color(0xFF1F2937),
                ),
              ),
              GestureDetector(
                onTap: () {
                  HapticFeedback.lightImpact();
                  context.push('/product-details');
                },
                child: Container(
                  padding: EdgeInsets.symmetric(
                    horizontal: (isTablet ? 14 : 10).w,
                    vertical: (isTablet ? 6 : 4).h,
                  ),
                  decoration: BoxDecoration(
                    color: const Color(0xFF3B82F6).withOpacity(0.1),
                    borderRadius: BorderRadius.circular((isTablet ? 14 : 12).r),
                  ),
                ),
              ),
            ],
          ),
          SizedBox(height: (isTablet ? 16 : 12).h),
          SizedBox(
            height: cardHeight,
            child: PageView.builder(
              controller: pageController,
              onPageChanged: onPageChanged,
              itemCount: products.length,
              itemBuilder: (context, index) {
                final product = products[index];
                return Padding(
                  padding: EdgeInsets.only(right: (isTablet ? 16 : 12).w),
                  child: GestureDetector(
                    onTap: () {
                      HapticFeedback.lightImpact();
                      context.push('/product-details');
                    },
                    child: _buildProductCard(
                      product['image']!,
                      product['title']!,
                      product['badge']!,
                      product['color']!,
                      isTablet: isTablet,
                    ),
                  ),
                );
              },
            ),
          ),
          SizedBox(height: (isTablet ? 16 : 12).h),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: List.generate(
              products.length,
              (index) => AnimatedContainer(
                duration: const Duration(milliseconds: 300),
                margin: EdgeInsets.symmetric(horizontal: (isTablet ? 4 : 3).w),
                width: currentBannerIndex == index
                    ? (isTablet ? 24 : 20).w
                    : (isTablet ? 8 : 6).w,
                height: (isTablet ? 8 : 6).h,
                decoration: BoxDecoration(
                  color: currentBannerIndex == index
                      ? const Color(0xFF3B82F6)
                      : Colors.grey[300],
                  borderRadius: BorderRadius.circular((isTablet ? 4 : 3).r),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildProductCard(
    String imagePath,
    String title,
    String badge,
    String colorCode, {
    required bool isTablet,
  }) {
    final color = Color(int.parse(colorCode));
    final badgeFontSize = isTablet ? 12.0 : 10.0;
    final titleFontSize = isTablet ? 18.0 : 16.0;
    final borderRadius = isTablet ? 16.0 : 12.0;

    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(borderRadius),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: (isTablet ? 10 : 8).r,
            offset: Offset(0, (isTablet ? 5 : 4).h),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(borderRadius),
        child: Stack(
          fit: StackFit.expand,
          children: [
            Image.asset(imagePath, fit: BoxFit.cover),
            Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [Colors.transparent, Colors.black.withOpacity(0.6)],
                ),
              ),
            ),
            Padding(
              padding: EdgeInsets.all((isTablet ? 20 : 16).w),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    padding: EdgeInsets.symmetric(
                      horizontal: (isTablet ? 10 : 8).w,
                      vertical: (isTablet ? 5 : 4).h,
                    ),
                    decoration: BoxDecoration(
                      color: color,
                      borderRadius: BorderRadius.circular(
                        (isTablet ? 10 : 8).r,
                      ),
                    ),
                    child: Text(
                      badge,
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: badgeFontSize,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                  const Spacer(),
                  Text(
                    title,
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: titleFontSize,
                      fontWeight: FontWeight.bold,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  SizedBox(height: (isTablet ? 8 : 6).h),
                  Container(
                    padding: EdgeInsets.symmetric(
                      horizontal: 8.w,
                      vertical: 4.h,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(12.r),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        SizedBox(width: 3.w),
                        Icon(
                          Icons.arrow_forward,
                          color: Colors.white,
                          size: 12.sp,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
