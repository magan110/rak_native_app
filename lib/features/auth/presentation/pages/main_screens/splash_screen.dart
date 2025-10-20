import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:rak_app/core/services/storage_service.dart';
import 'dart:async';
import 'dart:math' as math;
import '../../../../../core/services/auth_service.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with TickerProviderStateMixin {
  late AnimationController _fadeController;
  late AnimationController _scaleController;
  late AnimationController _slideController;
  late Animation<double> _fadeAnimation;
  late Animation<double> _scaleAnimation;
  late Animation<Offset> _slideAnimation;
  late AnimationController _particleController;
  late Animation<double> _particleAnimation;

  String _loadingText = 'Loading...';

  @override
  void initState() {
    super.initState();

    // Initialize animation controllers
    _fadeController = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    );

    _scaleController = AnimationController(
      duration: const Duration(milliseconds: 1000),
      vsync: this,
    );

    _slideController = AnimationController(
      duration: const Duration(milliseconds: 1200),
      vsync: this,
    );

    _particleController = AnimationController(
      duration: const Duration(milliseconds: 3000),
      vsync: this,
    );

    // Define animations
    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _fadeController, curve: Curves.easeInOut),
    );

    _scaleAnimation = Tween<double>(begin: 0.5, end: 1.0).animate(
      CurvedAnimation(parent: _scaleController, curve: Curves.elasticOut),
    );

    _slideAnimation =
        Tween<Offset>(begin: const Offset(0, 0.5), end: Offset.zero).animate(
          CurvedAnimation(parent: _slideController, curve: Curves.easeOutCubic),
        );

    _particleAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _particleController, curve: Curves.easeInOut),
    );

    // Start animations
    _fadeController.forward();
    _scaleController.forward();
    _slideController.forward();
    _particleController.repeat();

    // Check for auto-login after animations start
    _checkAutoLoginAndNavigate();
  }

  Future<void> _checkAutoLoginAndNavigate() async {
    // Minimum splash screen display time
    const minSplashDuration = Duration(milliseconds: 2000);
    final startTime = DateTime.now();

    try {
      // Check if auto-login is possible
      final canAutoLogin = await StorageService.canAutoLogin();

      if (canAutoLogin) {
        setState(() {
          _loadingText = 'Signing you in...';
        });

        // Attempt auto-login
        final autoLoginResult = await AuthService.autoLogin();

        if (autoLoginResult['success'] == true) {
          final userData = autoLoginResult['data'];

          // Set user data in AuthManager
          AuthManager.setUser(userData);

          setState(() {
            _loadingText = 'Welcome back!';
          });

          // Brief delay to show welcome message
          await Future.delayed(const Duration(milliseconds: 500));

          // Ensure minimum splash time has passed
          final elapsed = DateTime.now().difference(startTime);
          if (elapsed < minSplashDuration) {
            await Future.delayed(minSplashDuration - elapsed);
          }

          if (mounted) {
            _navigateBasedOnRole(userData);
          }
          return;
        } else {
          // Auto-login failed, clear stored data and continue to login
          await StorageService.clearAppRegId();
          setState(() {
            _loadingText = 'Loading...';
          });
        }
      }

      // Ensure minimum splash time has passed
      final elapsed = DateTime.now().difference(startTime);
      if (elapsed < minSplashDuration) {
        await Future.delayed(minSplashDuration - elapsed);
      }

      // Navigate to login screen
      if (mounted) {
        context.go('/login');
      }
    } catch (e) {
      // Handle any errors during auto-login
      debugPrint('Auto-login error: $e');

      setState(() {
        _loadingText = 'Loading...';
      });

      // Ensure minimum splash time has passed
      final elapsed = DateTime.now().difference(startTime);
      if (elapsed < minSplashDuration) {
        await Future.delayed(minSplashDuration - elapsed);
      }

      // Navigate to login screen on error
      if (mounted) {
        context.go('/login');
      }
    }
  }

  void _navigateBasedOnRole(userData) {
    // Check user's pages to determine which screen to navigate to
    final userPages = userData['pages'] as List<dynamic>;
    final userRoles = userData['roles'] as List<dynamic>;

    // Navigate to the appropriate screen based on user's access
    if (userPages.contains('DASHBOARD') || userRoles.contains('ADMIN')) {
      context.go(
        '/home',
      ); // Changed from '/dashboard' to '/home' since that's in your routes
    } else if (userPages.contains('QUALITY_CONTROL') ||
        userRoles.contains('QC_MANAGER')) {
      context.go('/home'); // Update with actual route when available
    } else if (userPages.contains('PRODUCTS') ||
        userRoles.contains('PRODUCT_MANAGER')) {
      context.go('/home'); // Update with actual route when available
    } else if (userPages.contains('REGISTRATION') ||
        userRoles.contains('REGISTRAR')) {
      context.go('/contractor-registration');
    } else {
      // Default to main dashboard/home if no specific role matches
      context.go('/home');
    }
  }

  @override
  void dispose() {
    _fadeController.dispose();
    _scaleController.dispose();
    _slideController.dispose();
    _particleController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // Responsive scaling based on device size
    final media = MediaQuery.of(context);
    final shortestSide = media.size.shortestSide;
    final isTabletLike = shortestSide > 600;

    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA),
      body: Stack(
        children: [
          // Background gradient
          Container(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  Color(0xFFFFFFFF),
                  Color(0xFFF5F7FA),
                  Color(0xFFE9ECEF),
                ],
              ),
            ),
          ),

          // Animated particles background
          AnimatedBuilder(
            animation: _particleAnimation,
            builder: (context, child) {
              return CustomPaint(
                painter: ParticlePainter(_particleAnimation.value),
                size: Size.infinite,
              );
            },
          ),

          // Main content (responsive)
          Center(
            child: LayoutBuilder(
              builder: (context, constraints) {
                final maxWidth = constraints.maxWidth;
                final logoSize =
                    (isTabletLike ? 220.0 : 140.0) *
                    (maxWidth / media.size.width).clamp(0.85, 1.25);
                final titleSize = isTabletLike ? 64.0 : 48.0;
                final subtitleSize = isTabletLike ? 28.0 : 24.0;
                final captionSize = isTabletLike ? 18.0 : 16.0;

                return ConstrainedBox(
                  constraints: BoxConstraints(
                    maxWidth: isTabletLike ? 700 : double.infinity,
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // Logo/Icon container
                      FadeTransition(
                        opacity: _fadeAnimation,
                        child: ScaleTransition(
                          scale: _scaleAnimation,
                          child: Container(
                            width: logoSize,
                            height: logoSize,
                            decoration: BoxDecoration(
                              gradient: const LinearGradient(
                                begin: Alignment.topLeft,
                                end: Alignment.bottomRight,
                                colors: [
                                  Color(0xFF2C5282),
                                  Color(0xFF2B6CB0),
                                  Color(0xFF3182CE),
                                ],
                              ),
                              shape: BoxShape.circle,
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withOpacity(0.25),
                                  blurRadius: 24,
                                  offset: const Offset(0, 10),
                                ),
                                BoxShadow(
                                  color: const Color(
                                    0xFF3182CE,
                                  ).withOpacity(0.28),
                                  blurRadius: 30,
                                  offset: const Offset(0, 6),
                                ),
                              ],
                            ),
                            padding: EdgeInsets.all(
                              (logoSize * 0.06).clamp(6, 18),
                            ),
                            child: Container(
                              decoration: BoxDecoration(
                                color: Colors.white,
                                shape: BoxShape.circle,
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black.withOpacity(0.08),
                                    blurRadius: 10,
                                    offset: const Offset(0, 4),
                                  ),
                                ],
                              ),
                              child: ClipOval(
                                child: Image.asset(
                                  "assets/images/rak_logo.jpg",
                                  fit: BoxFit.cover,
                                  errorBuilder: (context, error, stackTrace) {
                                    return Icon(
                                      Icons.business,
                                      color: const Color(0xFF2C5282),
                                      size: (logoSize * 0.4).clamp(40, 120),
                                    );
                                  },
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),

                      SizedBox(height: logoSize * 0.28),

                      // Company name
                      FadeTransition(
                        opacity: _fadeAnimation,
                        child: SlideTransition(
                          position: _slideAnimation,
                          child: Column(
                            children: [
                              Text(
                                'RAK',
                                style: TextStyle(
                                  fontSize: titleSize,
                                  fontWeight: FontWeight.bold,
                                  color: const Color(0xFF2C5282),
                                  letterSpacing: 3,
                                ),
                              ),
                              SizedBox(height: titleSize * 0.12),
                              Text(
                                'WHITE CEMENT',
                                style: TextStyle(
                                  fontSize: subtitleSize,
                                  fontWeight: FontWeight.w600,
                                  color: const Color(0xFF4A5568),
                                  letterSpacing: 2,
                                ),
                              ),
                              SizedBox(height: subtitleSize * 0.6),
                              Container(
                                width:
                                    (isTabletLike ? 120.0 : 60.0) *
                                    (maxWidth / media.size.width).clamp(
                                      0.9,
                                      1.2,
                                    ),
                                height: 4,
                                decoration: BoxDecoration(
                                  gradient: const LinearGradient(
                                    colors: [
                                      Color(0xFF3182CE),
                                      Color(0xFF2B6CB0),
                                    ],
                                  ),
                                  borderRadius: BorderRadius.circular(4),
                                ),
                              ),
                              SizedBox(height: subtitleSize * 0.9),
                              Text(
                                'Construction Materials',
                                style: TextStyle(
                                  fontSize: captionSize,
                                  fontWeight: FontWeight.w400,
                                  color: const Color(0xFF718096),
                                  letterSpacing: 1,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),

                      SizedBox(height: logoSize * 0.36),

                      // Loading indicator
                      FadeTransition(
                        opacity: _fadeAnimation,
                        child: Column(
                          children: [
                            SizedBox(
                              width:
                                  (isTabletLike ? 56.0 : 40.0) *
                                  (maxWidth / media.size.width).clamp(
                                    0.85,
                                    1.2,
                                  ),
                              height:
                                  (isTabletLike ? 56.0 : 40.0) *
                                  (maxWidth / media.size.width).clamp(
                                    0.85,
                                    1.2,
                                  ),
                              child: CircularProgressIndicator(
                                strokeWidth: 3.5,
                                valueColor: const AlwaysStoppedAnimation<Color>(
                                  Color(0xFF3182CE),
                                ),
                              ),
                            ),
                            SizedBox(height: captionSize * 1.2),
                            Text(
                              _loadingText,
                              style: TextStyle(
                                fontSize: captionSize,
                                color: const Color(0xFF718096),
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
          ),

          // Bottom footer
          Positioned(
            bottom: 30,
            left: 0,
            right: 0,
            child: FadeTransition(
              opacity: _fadeAnimation,
              child: const Column(
                children: [
                  Text(
                    'Est. 1980',
                    style: TextStyle(
                      fontSize: 12,
                      color: Color(0xFFA0AEC0),
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  SizedBox(height: 8),
                  Text(
                    'Ras Al Khaimah, United Arab Emirates',
                    style: TextStyle(
                      fontSize: 12,
                      color: Color(0xFFA0AEC0),
                      fontWeight: FontWeight.w400,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class ParticlePainter extends CustomPainter {
  final double animationValue;

  ParticlePainter(this.animationValue);

  @override
  void paint(Canvas canvas, Size size) {
    // Adaptive particle count for performance
    final baseCount = (size.shortestSide / 40).clamp(8, 28).toInt();
    final paint = Paint()..color = const Color(0xFF3182CE).withOpacity(0.08);

    for (int i = 0; i < baseCount; i++) {
      final progress = (i / baseCount + animationValue) % 1.0;
      final x = (progress * size.width);
      // vertical position oscillates using a sine curve for smooth motion
      final normalized = (i % 5) / 5.0;
      final y =
          size.height *
          (0.35 +
              0.5 *
                  (0.5 +
                      0.5 * math.sin((progress + normalized) * 2 * math.pi)));

      final particleSize =
          1.5 +
          (1.5 * (0.5 + 0.5 * math.cos((progress + i * 0.13) * 2 * math.pi)));
      canvas.drawCircle(Offset(x, y), particleSize, paint);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}
