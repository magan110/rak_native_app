import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'dart:async';
import 'dart:math' as math;

// Import services for auto-login functionality
import '../../../../../core/services/storage_service.dart';
import '../../../../../core/services/autologin_service.dart';
import '../../../../../core/services/auth_service.dart';
import '../../../../../core/services/maintenance_service.dart';
import '../../../../../core/services/location_service.dart';
import '../../../../../shared/widgets/combined_logo_widget.dart';
import '../../../../../shared/widgets/maintenance_dialog.dart';

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

    // Request location permission immediately
    LocationService.requestLocationPermission();

    // Check for auto-login after animations start
    _checkAutoLoginAndNavigate();
  }

  Future<void> _checkAutoLoginAndNavigate() async {
    // Minimum splash screen display time
    const minSplashDuration = Duration(milliseconds: 2000);
    final startTime = DateTime.now();

    try {
      // First check maintenance status
      setState(() {
        _loadingText = 'Checking app status...';
      });

      debugPrint('🔍 Splash: Checking maintenance status...');
      final maintenanceStatus = await MaintenanceService.checkMaintenanceStatus();
      
      debugPrint('🔍 Splash: Maintenance check - success: ${maintenanceStatus.success}, running: ${maintenanceStatus.isRunning}');

      // If app is under maintenance, show dialog and stop
      if (maintenanceStatus.isUnderMaintenance) {
        debugPrint('🚫 Splash: App is under maintenance');
        
        // Ensure minimum splash time has passed
        final elapsed = DateTime.now().difference(startTime);
        if (elapsed < minSplashDuration) {
          await Future.delayed(minSplashDuration - elapsed);
        }

        if (mounted) {
          // Show maintenance dialog
          showDialog(
            context: context,
            barrierDismissible: false,
            builder: (context) => MaintenanceDialog(
              message: maintenanceStatus.message,
            ),
          );
        }
        return;
      }

      // If maintenance check failed but we got a response, log and continue
      if (!maintenanceStatus.success) {
        debugPrint('⚠️ Splash: Maintenance check failed: ${maintenanceStatus.message}');
        // Continue with normal flow - don't block app if maintenance API is down
      }
      /* FOR TESTING: Auto-login as painter with mobile 505555555
      setState(() {
        _loadingText = 'Auto-logging in for testing...';
      });

      await Future.delayed(const Duration(milliseconds: 1000));

      setState(() {
        _loadingText = 'Welcome back, Mohammad Azhar Hussain!';
      });

      await Future.delayed(const Duration(milliseconds: 800));

      // Ensure minimum splash time has passed
      final elapsed = DateTime.now().difference(startTime);
      if (elapsed < minSplashDuration) {
        await Future.delayed(minSplashDuration - elapsed);
      }

      if (mounted) {
        // Navigate directly to painter home screen for testing
        context.go(
          '/painter-home',
          extra: {
            'isNewRegistration': false,
            'userRole': 'painter',
            'registeredName': 'Mohammad Azhar Hussain',
            'emirates': 'Abu Dhabi',
          },
        );
      }
      return;
      */ // End of testing code

      // Check for auto-login data
      setState(() {
        _loadingText = 'Checking for saved login...';
      });

      debugPrint('🔍 Splash: Starting autologin check...');
      final autoLoginResult = await AutoLoginService.performAutoLogin();

      debugPrint(
        '🔍 Splash: Autologin result - isValid: ${autoLoginResult.isValid}, userType: ${autoLoginResult.userType}',
      );

      if (autoLoginResult.isValid) {
        setState(() {
          _loadingText = 'Welcome back, ${autoLoginResult.displayName}!';
        });

        await Future.delayed(const Duration(milliseconds: 800));

        // Ensure minimum splash time has passed
        final elapsed = DateTime.now().difference(startTime);
        if (elapsed < minSplashDuration) {
          await Future.delayed(minSplashDuration - elapsed);
        }

        if (mounted) {
          debugPrint('🔍 Splash: Navigating to ${autoLoginResult.homeRoute}');

          // Navigate to appropriate home screen based on user type
          if (autoLoginResult.isPainter) {
            context.go(
              '/painter-home',
              extra: {
                'isNewRegistration': false,
                'userRole': 'painter',
                'registeredName':
                    autoLoginResult.userData?['userName'] ??
                    autoLoginResult.userData?['emplName'] ??
                    'User',
                'registeredMobile':
                    autoLoginResult.userData?['mobileNumber'] ??
                    autoLoginResult.userData?['userID'] ??
                    '',
                'emirates': autoLoginResult.emirates,
                'userData': autoLoginResult.userData,
              },
            );
          } else if (autoLoginResult.isContractor) {
            context.go(
              '/contractor-home',
              extra: {
                'isNewRegistration': false,
                'userRole': 'contractor',
                'registeredName':
                    autoLoginResult.userData?['userName'] ??
                    autoLoginResult.userData?['emplName'] ??
                    'User',
                'registeredMobile':
                    autoLoginResult.userData?['mobileNumber'] ??
                    autoLoginResult.userData?['userID'] ??
                    '',
                'emirates': autoLoginResult.emirates,
                'userData': autoLoginResult.userData,
              },
            );
          } else if (autoLoginResult.userType == 'general') {
            // For employee/general users — re-authenticate via server to get fresh deptCode etc.
            final serverResult = await AuthService.autoLogin();
            if (serverResult['success'] == true) {
              final userData = serverResult['data'];
              AuthManager.setUser(userData);
            }
            context.go('/home');
          } else {
            // Unknown user type, go to login
            debugPrint('🔍 Splash: Unknown user type, going to login');
            context.go('/login-with-password');
          }
        }
        return;
      } else {
        debugPrint('🔍 Splash: Autologin failed - ${autoLoginResult.reason}');
      }

      // Check if user has saved credentials for login screen auto-fill
      final hasStoredCredentials = await StorageService.hasStoredCredentials();

      if (hasStoredCredentials) {
        setState(() {
          _loadingText = 'Loading login...';
        });
      } else {
        setState(() {
          _loadingText = 'Loading...';
        });
      }

      // Ensure minimum splash time has passed
      final elapsed = DateTime.now().difference(startTime);
      if (elapsed < minSplashDuration) {
        await Future.delayed(minSplashDuration - elapsed);
      }

      // Navigate to login screen
      if (mounted) {
        context.go('/login-with-password');
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
        context.go('/login-with-password');
      }
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
                          child: AnimatedBuilder(
                            animation: _fadeController,
                            builder: (context, child) {
                              return Container(
                                decoration: BoxDecoration(
                                  borderRadius: BorderRadius.circular(20),
                                  border: Border.all(
                                    color: Color.lerp(
                                      const Color(0xFF2C5282),
                                      const Color(0xFF3182CE),
                                      _fadeAnimation.value,
                                    )!,
                                    width: 3.0 + (_fadeAnimation.value * 2.0),
                                  ),
                                  boxShadow: [
                                    BoxShadow(
                                      color: Colors.black.withValues(
                                        alpha: 0.15,
                                      ),
                                      blurRadius: 20,
                                      offset: const Offset(0, 8),
                                    ),
                                    BoxShadow(
                                      color: const Color(0xFF3182CE).withValues(
                                        alpha: 0.3 * _fadeAnimation.value,
                                      ),
                                      blurRadius: 15,
                                      offset: const Offset(0, 0),
                                    ),
                                  ],
                                ),
                                child: Container(
                                  decoration: BoxDecoration(
                                    color: Colors.white,
                                    borderRadius: BorderRadius.circular(16),
                                  ),
                                  padding: EdgeInsets.symmetric(
                                    vertical: 0.0,
                                    horizontal: (logoSize * 0.04).clamp(4, 8),
                                  ),
                                  child: CombinedLogoWidget(
                                    height: (logoSize * 1.0).clamp(120, 220),
                                    width: (logoSize * 1.8).clamp(200, 400),
                                    fit: BoxFit.contain,
                                    isCircular: false,
                                    showBorder: false,
                                  ),
                                ),
                              );
                            },
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
                                'RAK & BIRLA',
                                style: TextStyle(
                                  fontSize: titleSize * 0.85,
                                  fontWeight: FontWeight.bold,
                                  color: const Color(0xFF2C5282),
                                  letterSpacing: 2,
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
    final paint = Paint()
      ..color = const Color(0xFF3182CE).withValues(alpha: 0.08);

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
