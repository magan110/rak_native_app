import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:go_router/go_router.dart';
import 'package:rak_app/core/routes/route_names.dart';

class RegistrationTypeScreen extends StatefulWidget {
  const RegistrationTypeScreen({super.key});

  @override
  State<RegistrationTypeScreen> createState() => _RegistrationTypeScreenState();
}

class _RegistrationTypeScreenState extends State<RegistrationTypeScreen>
    with TickerProviderStateMixin {
  late AnimationController _animationController;
  late AnimationController _contractorCardController;
  late AnimationController _painterCardController;

  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;
  late Animation<double> _scaleAnimation;
  late Animation<double> _contractorCardAnimation;
  late Animation<double> _painterCardAnimation;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 1000),
      vsync: this,
    );
    _contractorCardController = AnimationController(
      duration: const Duration(milliseconds: 600),
      vsync: this,
    );
    _painterCardController = AnimationController(
      duration: const Duration(milliseconds: 600),
      vsync: this,
    );

    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _animationController,
        curve: const Interval(0.0, 0.5, curve: Curves.easeOut),
      ),
    );
    _slideAnimation =
        Tween<Offset>(begin: const Offset(0, 0.3), end: Offset.zero).animate(
          CurvedAnimation(
            parent: _animationController,
            curve: const Interval(0.2, 0.7, curve: Curves.easeOutCubic),
          ),
        );
    _scaleAnimation = Tween<double>(begin: 0.95, end: 1.0).animate(
      CurvedAnimation(
        parent: _animationController,
        curve: const Interval(0.3, 0.8, curve: Curves.easeOutCubic),
      ),
    );
    _contractorCardAnimation = CurvedAnimation(
      parent: _contractorCardController,
      curve: Curves.easeOutCubic,
    );
    _painterCardAnimation = CurvedAnimation(
      parent: _painterCardController,
      curve: Curves.easeOutCubic,
    );

    _animationController.forward();
    Future.delayed(const Duration(milliseconds: 200), () {
      if (mounted) _contractorCardController.forward();
    });
    Future.delayed(const Duration(milliseconds: 400), () {
      if (mounted) _painterCardController.forward();
    });
  }

  @override
  void dispose() {
    _animationController.dispose();
    _contractorCardController.dispose();
    _painterCardController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    SystemChrome.setSystemUIOverlayStyle(
      const SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: Brightness.dark,
        statusBarBrightness: Brightness.light,
      ),
    );

    return Scaffold(
      backgroundColor: Colors.white,
      body: LayoutBuilder(
        builder: (context, constraints) {
          final screenHeight = constraints.maxHeight;
          final screenWidth = constraints.maxWidth;
          final isSmallScreen = screenHeight < 700 || screenWidth < 360;

          return Container(
            width: double.infinity,
            height: double.infinity,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  Colors.blue.shade50,
                  Colors.white,
                  Colors.blue.shade50.withOpacity(0.5),
                ],
              ),
            ),
            child: SafeArea(
              child: FadeTransition(
                opacity: _fadeAnimation,
                child: SlideTransition(
                  position: _slideAnimation,
                  child: Column(
                    children: [
                      _buildMobileAppBar(isSmallScreen),
                      Expanded(
                        child: _buildMobileLayout(
                          screenHeight,
                          screenWidth,
                          isSmallScreen,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildMobileAppBar(bool isSmallScreen) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 8.h),
      child: Row(
        children: [
          Expanded(
            child: Text(
              'Registration Type',
              style: TextStyle(
                fontWeight: FontWeight.w600,
                fontSize: isSmallScreen ? 18.sp : 20.sp,
                color: Colors.blue.shade800,
              ),
            ),
          ),
          IconButton(
            icon: Icon(Icons.help_outline_rounded, color: Colors.blue.shade700),
            onPressed: () => _showHelpDialog(),
          ),
        ],
      ),
    );
  }

  Widget _buildMobileLayout(
    double screenHeight,
    double screenWidth,
    bool isSmallScreen,
  ) {
    final horizontalPadding = screenWidth < 360 ? 16.0 : 20.0;
    final verticalSpacing = isSmallScreen ? 16.0 : 24.0;
    final cardSpacing = isSmallScreen ? 16.0 : 20.0;

    return SingleChildScrollView(
      physics: const BouncingScrollPhysics(),
      padding: EdgeInsets.symmetric(
        horizontal: horizontalPadding.w,
        vertical: 16.h,
      ),
      child: ScaleTransition(
        scale: _scaleAnimation,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _buildAnimatedHeader(isSmallScreen),
            SizedBox(height: verticalSpacing.h),
            _buildSubtitle(isSmallScreen),
            SizedBox(height: (verticalSpacing + 8).h),

            // Registration Cards
            ScaleTransition(
              scale: _contractorCardAnimation,
              child: _MobileRegistrationCard(
                title: 'Contractor',
                subtitle: 'Maintenance Contractor',
                description:
                    'Register as a contractor if you run a business that hires painters or provide painting services.',
                icon: Icons.business_rounded,
                primaryColor: Colors.blue.shade600,
                accentColor: Colors.blue.shade700,
                lightColor: Colors.blue.shade400,
                onTap: () => context.push(RouteNames.contractorRegistration),
                isSmallScreen: isSmallScreen,
              ),
            ),
            SizedBox(height: cardSpacing),
            ScaleTransition(
              scale: _painterCardAnimation,
              child: _MobileRegistrationCard(
                title: 'Painter',
                subtitle: 'Works under contractor',
                description:
                    'Register as a painter if you work under a contractor or as an individual service provider.',
                icon: Icons.format_paint_rounded,
                primaryColor: Colors.blue.shade500,
                accentColor: Colors.blue.shade600,
                lightColor: Colors.blue.shade300,
                onTap: () => context.push(RouteNames.painterRegistration),
                isSmallScreen: isSmallScreen,
              ),
            ),
            SizedBox(height: verticalSpacing + 8),

            // Information Section
            _buildInformationSection(isSmallScreen),
            SizedBox(height: verticalSpacing),
          ],
        ),
      ),
    );
  }

  Widget _buildAnimatedHeader(bool isSmallScreen) {
    return TweenAnimationBuilder<double>(
      tween: Tween<double>(begin: 0, end: 1),
      duration: const Duration(milliseconds: 600),
      curve: Curves.easeOutCubic,
      builder: (context, value, child) {
        return Transform.translate(
          offset: Offset(0, 20 * (1 - value)),
          child: Opacity(opacity: value, child: child),
        );
      },
      child: Text(
        'Choose Your Role',
        style: TextStyle(
          fontSize: isSmallScreen ? 26 : 32,
          fontWeight: FontWeight.bold,
          color: Colors.blue.shade800,
          letterSpacing: 0.5,
        ),
        textAlign: TextAlign.center,
      ),
    );
  }

  Widget _buildSubtitle(bool isSmallScreen) {
    return TweenAnimationBuilder<double>(
      tween: Tween<double>(begin: 0, end: 1),
      duration: const Duration(milliseconds: 600),
      curve: Curves.easeOutCubic,
      builder: (context, value, child) {
        return Transform.translate(
          offset: Offset(0, 15 * (1 - value)),
          child: Opacity(opacity: value, child: child),
        );
      },
      child: Text(
        'Select the registration type that best describes your role to get started',
        style: TextStyle(
          fontSize: isSmallScreen ? 14 : 16,
          color: Colors.grey.shade600,
          height: 1.5,
        ),
        textAlign: TextAlign.center,
      ),
    );
  }

  Widget _buildInformationSection(bool isSmallScreen) {
    final padding = isSmallScreen ? 16.0 : 20.0;
    final titleSize = isSmallScreen ? 16.0 : 18.0;
    final itemSpacing = isSmallScreen ? 12.0 : 16.0;

    return Container(
      padding: EdgeInsets.all(padding),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.08),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
        border: Border.all(color: Colors.grey.shade200, width: 1),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.info_outline_rounded,
                color: Colors.blue.shade700,
                size: isSmallScreen ? 20 : 22,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  'Need help choosing?',
                  style: TextStyle(
                    fontSize: titleSize,
                    fontWeight: FontWeight.bold,
                    color: Colors.black87,
                  ),
                ),
              ),
            ],
          ),
          SizedBox(height: itemSpacing),
          _buildInfoItem(
            icon: Icons.business_rounded,
            iconColor: Colors.blue.shade600,
            title: 'Contractor',
            description:
                'For businesses that hire painters or provide painting services to clients',
            isSmallScreen: isSmallScreen,
          ),
          SizedBox(height: itemSpacing),
          _buildInfoItem(
            icon: Icons.format_paint_rounded,
            iconColor: Colors.blue.shade500,
            title: 'Painter',
            description:
                'For individuals working under contractors or as independent service providers',
            isSmallScreen: isSmallScreen,
          ),
          SizedBox(height: itemSpacing),
          SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              onPressed: _showHelpDialog,
              icon: Icon(
                Icons.help_outline_rounded,
                size: isSmallScreen ? 18 : 20,
              ),
              label: Text(
                'Get Additional Help',
                style: TextStyle(fontSize: isSmallScreen ? 13 : 14),
              ),
              style: OutlinedButton.styleFrom(
                padding: EdgeInsets.symmetric(
                  vertical: isSmallScreen ? 10 : 12,
                  horizontal: 16,
                ),
                side: BorderSide(color: Colors.blue.shade300),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoItem({
    required IconData icon,
    required Color iconColor,
    required String title,
    required String description,
    required bool isSmallScreen,
  }) {
    final iconSize = isSmallScreen ? 16.0 : 18.0;
    final containerSize = isSmallScreen ? 36.0 : 40.0;
    final titleSize = isSmallScreen ? 14.0 : 15.0;
    final descSize = isSmallScreen ? 12.0 : 13.0;

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: containerSize,
          height: containerSize,
          decoration: BoxDecoration(
            color: iconColor.withOpacity(0.1),
            shape: BoxShape.circle,
          ),
          child: Icon(icon, color: iconColor, size: iconSize),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: TextStyle(
                  fontSize: titleSize,
                  fontWeight: FontWeight.bold,
                  color: Colors.black87,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                description,
                style: TextStyle(
                  fontSize: descSize,
                  color: Colors.grey.shade600,
                  height: 1.4,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  void _showHelpDialog() {
    showDialog(
      context: context,
      builder: (context) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20.r)),
        child: Container(
          padding: EdgeInsets.all(24.w),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 64.w,
                height: 64.h,
                decoration: BoxDecoration(
                  color: Colors.blue.shade50,
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  Icons.help_outline_rounded,
                  size: 32.sp,
                  color: Colors.blue.shade700,
                ),
              ),
              SizedBox(height: 16.h),
              Text(
                'Need Help?',
                style: TextStyle(
                  fontSize: 20.sp,
                  fontWeight: FontWeight.bold,
                  color: Colors.black87,
                ),
              ),
              SizedBox(height: 12.h),
              Text(
                'If you\'re unsure which registration type to select, please contact our support team for assistance.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 14.sp,
                  color: Colors.grey.shade600,
                  height: 1.5,
                ),
              ),
              SizedBox(height: 24.h),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () => Navigator.pop(context),
                  style: ElevatedButton.styleFrom(
                    padding: EdgeInsets.symmetric(vertical: 14.h),
                    backgroundColor: Colors.blue,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12.r),
                    ),
                  ),
                  child: Text(
                    'Got it',
                    style: TextStyle(
                      fontSize: 16.sp,
                      fontWeight: FontWeight.w600,
                      color: Colors.white,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _MobileRegistrationCard extends StatefulWidget {
  final String title;
  final String subtitle;
  final String description;
  final IconData icon;
  final Color primaryColor;
  final Color accentColor;
  final Color lightColor;
  final VoidCallback onTap;
  final bool isSmallScreen;

  const _MobileRegistrationCard({
    required this.title,
    required this.subtitle,
    required this.description,
    required this.icon,
    required this.primaryColor,
    required this.accentColor,
    required this.lightColor,
    required this.onTap,
    required this.isSmallScreen,
  });

  @override
  State<_MobileRegistrationCard> createState() =>
      _MobileRegistrationCardState();
}

class _MobileRegistrationCardState extends State<_MobileRegistrationCard>
    with SingleTickerProviderStateMixin {
  late AnimationController _scaleController;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _scaleController = AnimationController(
      duration: const Duration(milliseconds: 150),
      vsync: this,
    );
    _scaleAnimation = Tween<double>(begin: 1.0, end: 0.97).animate(
      CurvedAnimation(parent: _scaleController, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _scaleController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final padding = widget.isSmallScreen ? 16.0 : 20.0;
    final iconSize = widget.isSmallScreen ? 48.0 : 56.0;
    final titleSize = widget.isSmallScreen ? 20.0 : 24.0;
    final subtitleSize = widget.isSmallScreen ? 13.0 : 14.0;
    final descSize = widget.isSmallScreen ? 13.0 : 14.0;
    final buttonTextSize = widget.isSmallScreen ? 14.0 : 15.0;

    return GestureDetector(
      onTapDown: (_) => _scaleController.forward(),
      onTapUp: (_) {
        _scaleController.reverse();
        widget.onTap();
      },
      onTapCancel: () => _scaleController.reverse(),
      child: AnimatedBuilder(
        animation: _scaleAnimation,
        builder: (context, child) {
          return Transform.scale(scale: _scaleAnimation.value, child: child);
        },
        child: Container(
          padding: EdgeInsets.all(padding),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(24),
            boxShadow: [
              BoxShadow(
                color: widget.primaryColor.withOpacity(0.15),
                blurRadius: 20,
                offset: const Offset(0, 8),
                spreadRadius: 0,
              ),
              BoxShadow(
                color: Colors.black.withOpacity(0.05),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
            ],
            border: Border.all(
              color: widget.primaryColor.withOpacity(0.2),
              width: 1.5,
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    width: iconSize + 16,
                    height: iconSize + 16,
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          widget.primaryColor.withOpacity(0.15),
                          widget.lightColor.withOpacity(0.1),
                        ],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: widget.primaryColor.withOpacity(0.2),
                          blurRadius: 8,
                          offset: const Offset(0, 3),
                        ),
                      ],
                    ),
                    child: Icon(
                      widget.icon,
                      size: iconSize,
                      color: widget.accentColor,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          widget.title,
                          style: TextStyle(
                            fontSize: titleSize,
                            fontWeight: FontWeight.bold,
                            color: widget.accentColor,
                            letterSpacing: 0.3,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: widget.lightColor.withOpacity(0.15),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text(
                            widget.subtitle,
                            style: TextStyle(
                              fontSize: subtitleSize - 1,
                              color: widget.accentColor,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              SizedBox(height: padding),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.grey.shade50,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.grey.shade200, width: 1),
                ),
                child: Row(
                  children: [
                    Icon(
                      Icons.info_outline_rounded,
                      size: 16,
                      color: widget.primaryColor,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        widget.description,
                        style: TextStyle(
                          fontSize: descSize,
                          color: Colors.grey.shade700,
                          height: 1.5,
                        ),
                        maxLines: 3,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              ),
              SizedBox(height: padding),
              Container(
                width: double.infinity,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [widget.primaryColor, widget.accentColor],
                    begin: Alignment.centerLeft,
                    end: Alignment.centerRight,
                  ),
                  borderRadius: BorderRadius.circular(14),
                  boxShadow: [
                    BoxShadow(
                      color: widget.primaryColor.withOpacity(0.4),
                      blurRadius: 12,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Material(
                  color: Colors.transparent,
                  child: InkWell(
                    onTap: widget.onTap,
                    borderRadius: BorderRadius.circular(14),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                        vertical: 14,
                        horizontal: 16,
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            'Register as ${widget.title}',
                            style: TextStyle(
                              fontSize: buttonTextSize,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                              letterSpacing: 0.5,
                            ),
                          ),
                          const SizedBox(width: 8),
                          Icon(
                            Icons.arrow_forward_rounded,
                            size: buttonTextSize + 4,
                            color: Colors.white,
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
