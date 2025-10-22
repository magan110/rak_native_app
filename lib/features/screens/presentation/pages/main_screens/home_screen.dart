import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:go_router/go_router.dart';
import 'package:rak_app/core/services/auth_service.dart';
import 'package:rak_app/core/utils/responsive_utils.dart';

/// Clean Modern Responsive Mobile Home Screen
class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> with TickerProviderStateMixin {
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();
  final TextEditingController _searchController = TextEditingController();
  final PageController _pageController = PageController();
  int _currentIndex = 0;
  int _currentBannerIndex = 0;
  Timer? _autoScrollTimer;

  // Animation controllers
  late AnimationController _fadeAnimationController;
  late AnimationController _slideAnimationController;
  late AnimationController _scaleAnimationController;

  // Animations
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _startAutoScroll();
    _initializeAnimations();
    _startAnimations();
  }

  void _initializeAnimations() {
    // Fade animation
    _fadeAnimationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1000),
    );
    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _fadeAnimationController,
        curve: Curves.easeInOut,
      ),
    );

    // Slide animation
    _slideAnimationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );
    _slideAnimation =
        Tween<Offset>(begin: const Offset(0, 0.2), end: Offset.zero).animate(
          CurvedAnimation(
            parent: _slideAnimationController,
            curve: Curves.easeOutCubic,
          ),
        );

    // Scale animation
    _scaleAnimationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );
    _scaleAnimation = Tween<double>(begin: 0.9, end: 1.0).animate(
      CurvedAnimation(
        parent: _scaleAnimationController,
        curve: Curves.elasticOut,
      ),
    );
  }

  void _startAnimations() {
    _fadeAnimationController.forward();
    _slideAnimationController.forward();
    _scaleAnimationController.forward();
  }

  @override
  void dispose() {
    _searchController.dispose();
    _pageController.dispose();
    _autoScrollTimer?.cancel();
    _fadeAnimationController.dispose();
    _slideAnimationController.dispose();
    _scaleAnimationController.dispose();
    super.dispose();
  }

  void _startAutoScroll() {
    _autoScrollTimer = Timer.periodic(const Duration(seconds: 4), (timer) {
      if (_pageController.hasClients && mounted) {
        final nextPage = (_currentBannerIndex + 1) % 3;
        _pageController.animateToPage(
          nextPage,
          duration: const Duration(milliseconds: 500),
          curve: Curves.easeInOut,
        );
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    SystemChrome.setSystemUIOverlayStyle(
      const SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: Brightness.dark,
      ),
    );

    return LayoutBuilder(
      builder: (context, constraints) {
        // Using ResponsiveUtils for clean responsive logic
        final isTablet =
            ResponsiveUtils.isTablet(context) ||
            ResponsiveUtils.isDesktop(context);
        final screenWidth = constraints.maxWidth;
        final screenHeight = constraints.maxHeight;
        final isLandscape = screenWidth > screenHeight;

        return Scaffold(
          key: _scaffoldKey,
          backgroundColor: const Color(0xFFF8FAFC),
          appBar: _buildAppBar(),
          drawer: _buildDrawer(),
          body: SafeArea(
            top: false, // AppBar already handles top
            bottom: false,
            child: _buildMainContent(
              isTablet: isTablet,
              isLandscape: isLandscape,
              screenWidth: screenWidth,
              screenHeight: screenHeight,
            ),
          ),
          bottomNavigationBar: SafeArea(
            top: false,
            child: _buildBottomNavigation(
              isTablet: isTablet,
              screenWidth: screenWidth,
            ),
          ),
        );
      },
    );
  }

  PreferredSizeWidget _buildAppBar() {
    final currentUser = AuthManager.currentUser;
    final userName = currentUser?.emplName ?? 'Guest';

    return AppBar(
      backgroundColor: Colors.white,
      elevation: 0,
      toolbarHeight: 70.h,
      surfaceTintColor: Colors.transparent,
      shadowColor: Colors.black.withOpacity(0.05),
      bottom: PreferredSize(
        preferredSize: Size.fromHeight(1.h),
        child: Container(
          height: 1.h,
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                Colors.transparent,
                Colors.grey.withOpacity(0.1),
                Colors.transparent,
              ],
            ),
          ),
        ),
      ),
      leading: Builder(
        builder: (context) => Padding(
          padding: EdgeInsets.only(left: 8.w),
          child: IconButton(
            onPressed: () {
              HapticFeedback.lightImpact();
              Scaffold.of(context).openDrawer();
            },
            icon: Icon(Icons.menu, color: const Color(0xFF1E3A8A), size: 24.sp),
            tooltip: 'Open menu',
          ),
        ),
      ),
      title: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            children: [
              Text(
                'Hello, ',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w400,
                  color: Colors.grey[600],
                ),
              ),
              Flexible(
                child: Text(
                  userName.split(' ').first,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    color: Color(0xFF1E3A8A),
                  ),
                  overflow: TextOverflow.ellipsis,
                  maxLines: 1,
                ),
              ),
              const Text(' 👋', style: TextStyle(fontSize: 16)),
            ],
          ),
          const SizedBox(height: 2),
          Text(
            'Welcome back!',
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w400,
              color: Colors.grey[500],
            ),
            overflow: TextOverflow.ellipsis,
            maxLines: 1,
          ),
        ],
      ),
      actions: [
        // Search Button
        Padding(
          padding: EdgeInsets.only(right: 8.w),
          child: IconButton(
            onPressed: () {
              // Show search dialog or navigate to search page
              showSearch(context: context, delegate: _CustomSearchDelegate());
            },
            icon: Container(
              padding: EdgeInsets.all(10.w),
              decoration: BoxDecoration(
                color: const Color(0xFFF8FAFC),
                borderRadius: BorderRadius.circular(12.r),
                border: Border.all(
                  color: Colors.grey.withOpacity(0.2),
                  width: 1.w,
                ),
              ),
              child: Icon(
                Icons.search_rounded,
                color: Colors.grey[700],
                size: 22.sp,
              ),
            ),
          ),
        ),
        // Notifications Button
        Padding(
          padding: EdgeInsets.only(right: 8.w),
          child: IconButton(
            onPressed: () {},
            icon: Container(
              padding: EdgeInsets.all(10.w),
              decoration: BoxDecoration(
                color: const Color(0xFFF8FAFC),
                borderRadius: BorderRadius.circular(12.r),
                border: Border.all(
                  color: Colors.grey.withOpacity(0.2),
                  width: 1.w,
                ),
              ),
              child: Stack(
                clipBehavior: Clip.none,
                children: [
                  Icon(
                    Icons.notifications_rounded,
                    color: Colors.grey[700],
                    size: 22.sp,
                  ),
                  Positioned(
                    right: -2.w,
                    top: -2.h,
                    child: Container(
                      padding: EdgeInsets.all(4.w),
                      decoration: BoxDecoration(
                        color: const Color(0xFFEF4444),
                        shape: BoxShape.circle,
                        border: Border.all(color: Colors.white, width: 2.w),
                      ),
                      constraints: BoxConstraints(
                        minWidth: 18.w,
                        minHeight: 18.h,
                      ),
                      child: Text(
                        '3',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 9.sp,
                          fontWeight: FontWeight.bold,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildDrawer() {
    final currentUser = AuthManager.currentUser;
    final userName = currentUser?.emplName ?? 'Guest User';
    final userArea = currentUser?.areaCode ?? 'N/A';
    final userInitial = userName.isNotEmpty ? userName[0].toUpperCase() : 'G';

    return Drawer(
      backgroundColor: const Color(0xFFFAFAFA),
      width: MediaQuery.of(context).size.width * 0.85,
      child: Column(
        children: [
          // Modern Compact Header
          Container(
            width: double.infinity,
            margin: EdgeInsets.all(16.w),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFF1E3A8A), Color(0xFF3B82F6)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(20.r),
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFF1E3A8A).withOpacity(0.3),
                  blurRadius: 16.r,
                  offset: Offset(0, 4.h),
                  spreadRadius: 0,
                ),
              ],
            ),
            child: SafeArea(
              bottom: false,
              child: Padding(
                padding: EdgeInsets.symmetric(
                  horizontal: 20.w,
                  vertical: 20.h,
                ),
                child: Row(
                  children: [
                    // User Avatar
                    Container(
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: Colors.white.withOpacity(0.3),
                          width: 2.5.w,
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.15),
                            blurRadius: 8.r,
                            offset: Offset(0, 2.h),
                          ),
                        ],
                      ),
                      child: CircleAvatar(
                        radius: 28.r,
                        backgroundColor: Colors.white,
                        child: Text(
                          userInitial,
                          style: TextStyle(
                            fontSize: 22.sp,
                            fontWeight: FontWeight.bold,
                            color: const Color(0xFF1E3A8A),
                          ),
                        ),
                      ),
                    ),
                    SizedBox(width: 16.w),
                    // User Info
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            userName,
                            style: TextStyle(
                              fontSize: 17.sp,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                              letterSpacing: 0.3,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          SizedBox(height: 4.h),
                          Container(
                            padding: EdgeInsets.symmetric(
                              horizontal: 10.w,
                              vertical: 4.h,
                            ),
                            decoration: BoxDecoration(
                              color: Colors.white.withOpacity(0.2),
                              borderRadius: BorderRadius.circular(12.r),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(
                                  Icons.location_on,
                                  color: Colors.white,
                                  size: 12.sp,
                                ),
                                SizedBox(width: 4.w),
                                Text(
                                  userArea,
                                  style: TextStyle(
                                    fontSize: 11.sp,
                                    color: Colors.white,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                    // Logo (optional, remove if too crowded)
                    Container(
                      padding: EdgeInsets.all(8.w),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.15),
                        borderRadius: BorderRadius.circular(12.r),
                      ),
                      child: Image.asset(
                        'assets/images/rak_logo.jpg',
                        height: 36.h,
                        width: 36.w,
                        fit: BoxFit.contain,
                        errorBuilder: (context, error, stackTrace) =>
                            Icon(
                              Icons.business_rounded,
                              color: Colors.white,
                              size: 36.sp,
                            ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          // Menu Items
          Expanded(
            child: Container(
              margin: EdgeInsets.symmetric(horizontal: 16.w),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(20.r),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.05),
                    blurRadius: 10.r,
                    offset: Offset(0, 2.h),
                  ),
                ],
              ),
              child: ListView(
                padding: EdgeInsets.symmetric(
                  vertical: 12.h,
                  horizontal: 8.w,
                ),
                children: _buildDrawerItems(isMobile: true),
              ),
            ),
          ),
          SizedBox(height: 16.h),
        ],
      ),
    );
  }

  Widget _buildDrawerItem(IconData icon, String title, VoidCallback onTap) {
    return Container(
      margin: EdgeInsets.symmetric(horizontal: 8.w, vertical: 3.h),
      decoration: BoxDecoration(borderRadius: BorderRadius.circular(12.r)),
      child: ListTile(
        onTap: () {
          HapticFeedback.lightImpact();
          onTap();
        },
        leading: Container(
          height: 40.h,
          width: 40.w,
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                const Color(0xFF1E3A8A).withOpacity(0.1),
                const Color(0xFF3B82F6).withOpacity(0.05),
              ],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(10.r),
            border: Border.all(
              color: const Color(0xFF1E3A8A).withOpacity(0.1),
              width: 1.w,
            ),
          ),
          child: Icon(icon, color: const Color(0xFF1E3A8A), size: 20.sp),
        ),
        title: Text(
          title,
          style: TextStyle(
            fontSize: 15.sp,
            fontWeight: FontWeight.w600,
            color: const Color(0xFF1F2937),
            letterSpacing: 0.2,
          ),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        trailing: Container(
          padding: EdgeInsets.all(4.w),
          decoration: BoxDecoration(
            color: const Color(0xFF1E3A8A).withOpacity(0.05),
            borderRadius: BorderRadius.circular(6.r),
          ),
          child: Icon(
            Icons.chevron_right_rounded,
            color: const Color(0xFF1E3A8A),
            size: 18.sp,
          ),
        ),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12.r)),
        contentPadding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 8.h),
      ),
    );
  }

  Widget _buildMainContent({
    required bool isTablet,
    required bool isLandscape,
    required double screenWidth,
    required double screenHeight,
  }) {
    return IndexedStack(
      index: _currentIndex,
      children: [
        _buildHomeTab(
          isTablet: isTablet,
          isLandscape: isLandscape,
          screenWidth: screenWidth,
          screenHeight: screenHeight,
        ),
        _buildScanTab(isTablet: isTablet, screenWidth: screenWidth),
        _buildProfileTab(isTablet: isTablet, screenWidth: screenWidth),
      ],
    );
  }

  Widget _buildHomeTab({
    required bool isTablet,
    required bool isLandscape,
    required double screenWidth,
    required double screenHeight,
  }) {
    // Using ResponsiveUtils for consistent responsive design
    // Automatically adjusts padding based on device type (mobile/tablet/desktop)
    final horizontalPadding = isTablet ? 32.0 : 16.0;
    final verticalPadding = isTablet ? 24.0 : 16.0;

    return SingleChildScrollView(
      padding: EdgeInsets.symmetric(
        horizontal: horizontalPadding,
        vertical: verticalPadding,
      ),
      child: FadeTransition(
        opacity: _fadeAnimation,
        child: SlideTransition(
          position: _slideAnimation,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildWelcomeCard(isTablet: isTablet, screenWidth: screenWidth),
              SizedBox(height: isTablet ? 24.h : 20.h),
              _buildFeaturedProducts(
                isTablet: isTablet,
                isLandscape: isLandscape,
                screenWidth: screenWidth,
              ),
              SizedBox(height: isTablet ? 24.h : 20.h),
              _buildQuickActions(
                isTablet: isTablet,
                isLandscape: isLandscape,
                screenWidth: screenWidth,
              ),
              SizedBox(height: isTablet ? 24.h : 20.h),
              _buildBusinessMetrics(
                isTablet: isTablet,
                isLandscape: isLandscape,
                screenWidth: screenWidth,
              ),
              SizedBox(height: isTablet ? 32.h : 24.h), // Bottom padding
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildWelcomeCard({
    required bool isTablet,
    required double screenWidth,
  }) {
    // Responsive sizing
    final cardPadding = isTablet ? 28.0 : 20.0;
    final titleFontSize = isTablet ? 28.0 : 24.0;
    final subtitleFontSize = isTablet ? 13.0 : 11.0;
    final logoSize = isTablet ? 80.0 : 60.0;

    return ScaleTransition(
      scale: _scaleAnimation,
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
              width: logoSize,
              height: logoSize,
              padding: EdgeInsets.all((isTablet ? 10 : 8).w),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular((isTablet ? 14 : 12).r),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.1),
                    blurRadius: (isTablet ? 7 : 5).r,
                    offset: Offset(0, 2.h),
                  ),
                ],
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular((isTablet ? 10 : 8).r),
                child: Image.asset(
                  'assets/images/rak_logo.jpg',
                  fit: BoxFit.contain,
                  errorBuilder: (context, error, stackTrace) => Icon(
                    Icons.business_rounded,
                    color: const Color(0xFF1E3A8A),
                    size: (isTablet ? 32 : 24).sp,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFeaturedProducts({
    required bool isTablet,
    required bool isLandscape,
    required double screenWidth,
  }) {
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
                onTap: () {},
                child: Container(
                  padding: EdgeInsets.symmetric(
                    horizontal: (isTablet ? 14 : 10).w,
                    vertical: (isTablet ? 6 : 4).h,
                  ),
                  decoration: BoxDecoration(
                    color: const Color(0xFF3B82F6).withOpacity(0.1),
                    borderRadius: BorderRadius.circular((isTablet ? 14 : 12).r),
                  ),
                  child: Text(
                    'View All',
                    style: TextStyle(
                      fontSize: (isTablet ? 14 : 12).sp,
                      fontWeight: FontWeight.w600,
                      color: const Color(0xFF3B82F6),
                    ),
                  ),
                ),
              ),
            ],
          ),
          SizedBox(height: (isTablet ? 16 : 12).h),
          SizedBox(
            height: cardHeight,
            child: PageView.builder(
              controller: _pageController,
              onPageChanged: (index) =>
                  setState(() => _currentBannerIndex = index),
              itemCount: products.length,
              itemBuilder: (context, index) {
                final product = products[index];
                return Padding(
                  padding: EdgeInsets.only(right: (isTablet ? 16 : 12).w),
                  child: _buildProductCard(
                    product['image']!,
                    product['title']!,
                    product['badge']!,
                    product['color']!,
                    isTablet: isTablet,
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
                width: _currentBannerIndex == index
                    ? (isTablet ? 24 : 20).w
                    : (isTablet ? 8 : 6).w,
                height: (isTablet ? 8 : 6).h,
                decoration: BoxDecoration(
                  color: _currentBannerIndex == index
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
                      borderRadius: BorderRadius.circular((isTablet ? 10 : 8).r),
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
                        Text(
                          'Explore',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 10.sp,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
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

  Widget _buildQuickActions({
    required bool isTablet,
    required bool isLandscape,
    required double screenWidth,
  }) {
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
              'Scan QR',
              Icons.qr_code_scanner,
              const Color(0xFF3B82F6),
              () {},
            ),
            _buildQuickActionCard(
              'Products',
              Icons.inventory_2,
              const Color(0xFF10B981),
              () {},
            ),
            _buildQuickActionCard(
              'Rewards',
              Icons.card_giftcard,
              const Color(0xFFF59E0B),
              () {},
            ),
            _buildQuickActionCard(
              'Reports',
              Icons.bar_chart,
              const Color(0xFF60A5FA),
              () {},
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildQuickActionCard(
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

  Widget _buildBusinessMetrics({
    required bool isTablet,
    required bool isLandscape,
    required double screenWidth,
  }) {
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
        // Use a fixed tile height to avoid layout overflow on small screens.
        // Compute a reasonable mainAxisExtent based on whether the device
        // is a tablet and the ScreenUtil sizing. This prevents the grid
        // from trying to expand vertically beyond the available viewport.
        Builder(builder: (context) {
          // Desired tile height (responsive) - nudged slightly larger to
          // prevent 1-3 pixel bottom overflow on some devices/screens.
          final double desiredTileHeight = isTablet ? 146.h : 126.h;

          final metrics = [
            () => _buildMetricCard(
                  'Total Scans',
                  '1,234',
                  '+12.5%',
                  const Color(0xFF10B981),
                  Icons.qr_code_scanner,
                ),
            () => _buildMetricCard(
                  'Points',
                  '5,678',
                  '+8.2%',
                  const Color(0xFF60A5FA),
                  Icons.star,
                ),
            () => _buildMetricCard(
                  'Campaigns',
                  '12',
                  '+2',
                  const Color(0xFFF59E0B),
                  Icons.campaign,
                ),
            () => _buildMetricCard(
                  'Target',
                  '85%',
                  '+15%',
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
              // Fix each tile to a predictable height to avoid overflow
              mainAxisExtent: desiredTileHeight,
            ),
            itemBuilder: (context, index) => metrics[index](),
          );
        }),
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
                SizedBox(height: 2.h),
                Row(
                  children: [
                    Icon(Icons.trending_up, color: color, size: 12.sp),
                    SizedBox(width: 2.w),
                    Text(
                      change,
                      style: TextStyle(
                        fontSize: 11.sp,
                        color: color,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildScanTab({required bool isTablet, required double screenWidth}) {
    return Center(
      child: Padding(
        padding: EdgeInsets.all(16.w),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            TweenAnimationBuilder<double>(
              duration: const Duration(milliseconds: 800),
              tween: Tween<double>(begin: 0.0, end: 1.0),
              builder: (context, value, child) {
                return Transform.scale(
                  scale: value,
                  child: Container(
                    width: 120.w,
                    height: 120.h,
                    decoration: BoxDecoration(
                      color: const Color(0xFF3B82F6).withOpacity(0.1),
                      borderRadius: BorderRadius.circular(60.r),
                    ),
                    child: Icon(
                      Icons.qr_code_scanner,
                      color: const Color(0xFF3B82F6),
                      size: 60.sp,
                    ),
                  ),
                );
              },
            ),
            SizedBox(height: 20.h),
            Text(
              'Scan QR Code',
              style: TextStyle(
                fontSize: 20.sp,
                fontWeight: FontWeight.bold,
                color: const Color(0xFF1F2937),
              ),
            ),
            SizedBox(height: 6.h),
            Text(
              'Position the QR code within the frame',
              style: TextStyle(fontSize: 14.sp, color: Colors.grey[600]),
            ),
            SizedBox(height: 24.h),
            TweenAnimationBuilder<double>(
              duration: const Duration(milliseconds: 600),
              tween: Tween<double>(begin: 0.9, end: 1.0),
              builder: (context, scale, child) {
                return Transform.scale(
                  scale: scale,
                  child: ElevatedButton(
                    onPressed: () {},
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF3B82F6),
                      foregroundColor: Colors.white,
                      padding: EdgeInsets.symmetric(
                        horizontal: 24.w,
                        vertical: 12.h,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(24.r),
                      ),
                      elevation: 3,
                    ),
                    child: Text(
                      'Open Scanner',
                      style: TextStyle(
                        fontSize: 16.sp,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildProfileTab({
    required bool isTablet,
    required double screenWidth,
  }) {
    return SingleChildScrollView(
      padding: EdgeInsets.all(16.w),
      child: Column(
        children: [
          SizedBox(height: 20.h),
          TweenAnimationBuilder<double>(
            duration: const Duration(milliseconds: 800),
            tween: Tween<double>(begin: 0.0, end: 1.0),
            builder: (context, value, child) {
              return Transform.scale(
                scale: value,
                child: Container(
                  width: 100.w,
                  height: 100.h,
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [Color(0xFF1E3A8A), Color(0xFF3B82F6)],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(50.r),
                  ),
                  child: Icon(
                    Icons.person,
                    color: Colors.white,
                    size: 50.sp,
                  ),
                ),
              );
            },
          ),
          SizedBox(height: 16.h),
          Text(
            'User Name',
            style: TextStyle(
              fontSize: 20.sp,
              fontWeight: FontWeight.bold,
              color: const Color(0xFF1F2937),
            ),
          ),
          SizedBox(height: 4.h),
          Text(
            'user@example.com',
            style: TextStyle(fontSize: 14.sp, color: Colors.grey[600]),
          ),
          SizedBox(height: 24.h),
          TweenAnimationBuilder<double>(
            duration: const Duration(milliseconds: 600),
            tween: Tween<double>(begin: 0.9, end: 1.0),
            builder: (context, scale, child) {
              return Transform.scale(
                scale: scale,
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
                    children: [
                      _buildProfileItem(
                        'My Points',
                        '5,678',
                        Icons.star,
                        const Color(0xFFF59E0B),
                      ),
                      Divider(height: 24.h),
                      _buildProfileItem(
                        'Total Scans',
                        '1,234',
                        Icons.qr_code_scanner,
                        const Color(0xFF3B82F6),
                      ),
                      Divider(height: 24.h),
                      _buildProfileItem(
                        'Rewards',
                        '12',
                        Icons.card_giftcard,
                        const Color(0xFF10B981),
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
          SizedBox(height: 24.h),
          TweenAnimationBuilder<double>(
            duration: const Duration(milliseconds: 600),
            tween: Tween<double>(begin: 0.9, end: 1.0),
            builder: (context, scale, child) {
              return Transform.scale(
                scale: scale,
                child: ElevatedButton(
                  onPressed: () {},
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFFEF4444),
                    foregroundColor: Colors.white,
                    padding: EdgeInsets.symmetric(
                      horizontal: 24.w,
                      vertical: 12.h,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(24.r),
                    ),
                    elevation: 3,
                  ),
                  child: Text(
                    'Logout',
                    style: TextStyle(fontSize: 16.sp, fontWeight: FontWeight.w600),
                  ),
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildProfileItem(
    String title,
    String value,
    IconData icon,
    Color color,
  ) {
    return Row(
      children: [
        Container(
          padding: EdgeInsets.all(8.w),
          decoration: BoxDecoration(
            color: color.withOpacity(0.1),
            borderRadius: BorderRadius.circular(8.r),
          ),
          child: Icon(icon, color: color, size: 20.sp),
        ),
        SizedBox(width: 12.w),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: TextStyle(fontSize: 14.sp, color: Colors.grey[600]),
              ),
              Text(
                value,
                style: TextStyle(
                  fontSize: 18.sp,
                  fontWeight: FontWeight.bold,
                  color: const Color(0xFF1F2937),
                ),
              ),
            ],
          ),
        ),
        Icon(Icons.arrow_forward_ios, color: Colors.grey[400], size: 16.sp),
      ],
    );
  }

  Widget _buildBottomNavigation({
    required bool isTablet,
    required double screenWidth,
  }) {
    // Using ResponsiveUtils for consistent sizing
    final navHeight = isTablet ? 80.0 : 70.0;

    return TweenAnimationBuilder<double>(
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeOutCubic,
      tween: Tween<double>(begin: 0, end: 1),
      builder: (context, value, child) {
        return Transform.translate(
          offset: Offset(0, 20 * (1 - value)),
          child: Opacity(opacity: value, child: child),
        );
      },
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.08),
              blurRadius: (isTablet ? 16 : 12).r,
              offset: Offset(0, (isTablet ? -5 : -4).h),
              spreadRadius: 0,
            ),
          ],
        ),
        child: NavigationBar(
          selectedIndex: _currentIndex,
          onDestinationSelected: (index) {
            HapticFeedback.mediumImpact();
            setState(() => _currentIndex = index);
          },
          elevation: 0,
          height: navHeight,
          backgroundColor: Colors.transparent,
          surfaceTintColor: Colors.transparent,
          shadowColor: Colors.transparent,
          indicatorColor: const Color(0xFF1E3A8A).withOpacity(0.12),
          indicatorShape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16.r),
          ),
          labelBehavior: NavigationDestinationLabelBehavior.alwaysShow,
          animationDuration: const Duration(milliseconds: 500),
          destinations: [
            _buildAnimatedDestination(
              index: 0,
              outlinedIcon: Icons.home_outlined,
              filledIcon: Icons.home_rounded,
              label: 'Home',
            ),
            _buildAnimatedDestination(
              index: 1,
              outlinedIcon: Icons.qr_code_scanner_outlined,
              filledIcon: Icons.qr_code_scanner_rounded,
              label: 'Scan',
            ),
            _buildAnimatedDestination(
              index: 2,
              outlinedIcon: Icons.person_outline_rounded,
              filledIcon: Icons.person_rounded,
              label: 'Profile',
            ),
          ],
        ),
      ),
    );
  }

  NavigationDestination _buildAnimatedDestination({
    required int index,
    required IconData outlinedIcon,
    required IconData filledIcon,
    required String label,
  }) {
    final isSelected = _currentIndex == index;

    return NavigationDestination(
      icon: TweenAnimationBuilder<double>(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOutCubic,
        tween: Tween<double>(begin: isSelected ? 0.8 : 1.0, end: 1.0),
        builder: (context, scale, child) {
          return Transform.scale(
            scale: scale,
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 300),
              curve: Curves.easeOutBack,
              child: Icon(
                outlinedIcon,
                color: isSelected ? const Color(0xFF1E3A8A) : Colors.grey[600],
              ),
            ),
          );
        },
      ),
      selectedIcon: TweenAnimationBuilder<double>(
        duration: const Duration(milliseconds: 400),
        curve: Curves.elasticOut,
        tween: Tween<double>(begin: 0.7, end: 1.0),
        builder: (context, scale, child) {
          return Transform.scale(
            scale: scale,
            child: TweenAnimationBuilder<double>(
              duration: const Duration(milliseconds: 300),
              curve: Curves.easeInOut,
              tween: Tween<double>(begin: 0, end: 1),
              builder: (context, rotation, child) {
                return Transform.rotate(
                  angle: rotation * 0.1,
                  child: Icon(filledIcon, color: const Color(0xFF1E3A8A)),
                );
              },
            ),
          );
        },
      ),
      label: label,
    );
  }

  List<Widget> _buildDrawerItems({bool isMobile = false}) {
    // Check if user has painter or contractor role
    final userRoles = AuthManager.getUserRoles();
    final isPainterOrContractor =
        userRoles.contains('PAINTER') || userRoles.contains('CONTRACTOR');

    if (isPainterOrContractor) {
      // Simplified menu for painters and contractors
      return [
        _buildDrawerItem(Icons.dashboard, 'Dashboard', () {
          if (isMobile) context.pop();
          context.push('/dashboard');
        }),
        const Divider(height: 32),
        _buildDrawerItem(Icons.settings, 'Settings', () {
          if (isMobile) context.pop();
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Settings - Coming Soon!')),
          );
        }),
        _buildDrawerItem(Icons.help_outline, 'Help & Support', () {
          if (isMobile) context.pop();
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Help & Support - Coming Soon!')),
          );
        }),
        _buildDrawerItem(Icons.logout, 'Logout', () async {
          await AuthService.logout();
          if (context.mounted) {
            context.go('/login-password');
          }
        }),
      ];
    } else {
      // Full menu for other users
      return [
        _buildDrawerItem(Icons.dashboard, 'Dashboard', () {
          if (isMobile) context.pop();
          context.push('/dashboard');
        }),
        _buildDrawerItem(Icons.format_paint, 'Painter Registration', () {
          if (isMobile) context.pop();
          // Navigate using named route so the correct screen is resolved
          context.pushNamed('painter-registration');
        }),
        _buildDrawerItem(Icons.construction, 'Contractor Registration', () {
          if (isMobile) context.pop();
          // Navigate using named route so the correct screen is resolved
          context.pushNamed('contractor-registration');
        }),
        _buildDrawerItem(Icons.approval, 'Approval Dashboard', () {
          if (isMobile) context.pop();
          context.push('/approval-dashboard');
        }),
        _buildDrawerItem(Icons.storefront, 'Retailer Onboarding', () {
          if (isMobile) context.pop();
          context.pushNamed('retailer-registration');
        }),
        _buildDrawerItem(Icons.inventory, 'Sample Distribution Entry', () {
          if (isMobile) context.pop();
          context.push('/sample-distribution');
        }),
        _buildDrawerItem(Icons.science, 'Sample Execution Entry', () {
          if (isMobile) context.pop();
          context.push('/sampling-drive-form');
        }),
        const Divider(height: 32),
        _buildDrawerItem(Icons.settings, 'Settings', () {
          if (isMobile) context.pop();
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Settings - Coming Soon!')),
          );
        }),
        _buildDrawerItem(Icons.help_outline, 'Help & Support', () {
          if (isMobile) context.pop();
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Help & Support - Coming Soon!')),
          );
        }),
        _buildDrawerItem(Icons.logout, 'Logout', () async {
          await AuthService.logout();
          if (context.mounted) {
            context.go('/login-password');
          }
        }),
      ];
    }
  }
}

// Custom Search Delegate for the AppBar search functionality
class _CustomSearchDelegate extends SearchDelegate<String> {
  @override
  List<Widget> buildActions(BuildContext context) {
    return [
      if (query.isNotEmpty)
        IconButton(
          icon: const Icon(Icons.clear),
          onPressed: () {
            query = '';
          },
        ),
    ];
  }

  @override
  Widget buildLeading(BuildContext context) {
    return IconButton(
      icon: const Icon(Icons.arrow_back),
      onPressed: () {
        close(context, '');
      },
    );
  }

  @override
  Widget buildResults(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.search, size: 80, color: Colors.grey[400]),
            const SizedBox(height: 16),
            Text(
              'Search results for: "$query"',
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              'This feature is coming soon!',
              style: TextStyle(fontSize: 14, color: Colors.grey[600]),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget buildSuggestions(BuildContext context) {
    final suggestions =
        [
              'Painter Registration',
              'Contractor Registration',
              'Retailer Onboarding',
              'Sample Distribution',
              'Activity Entry',
            ]
            .where(
              (suggestion) =>
                  suggestion.toLowerCase().contains(query.toLowerCase()),
            )
            .toList();

    return ListView.builder(
      itemCount: suggestions.length,
      itemBuilder: (context, index) {
        return ListTile(
          leading: const Icon(Icons.search, color: Color(0xFF1E3A8A)),
          title: Text(suggestions[index]),
          onTap: () {
            query = suggestions[index];
            showResults(context);
          },
        );
      },
    );
  }
}
