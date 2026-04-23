import 'dart:convert';
import 'dart:math';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../../../shared/widgets/custom_back_button.dart';
import '../../../../../core/services/auth_service.dart';
import '../../../../../core/services/sms_uae_service.dart';
import '../../../../../core/services/profile_completion_service.dart';
import '../../../../../core/config/api_config.dart';
import '../../../../../core/models/auth_models.dart';
import '../../../../../core/models/user_profile_models.dart';
import '../../../../../core/routes/route_names.dart';
import '../../../../../shared/widgets/dual_logo_widget.dart';
import '../../../../../core/utils/snackbar_utils.dart';

class LoginScreenWithOtp extends StatefulWidget {
  const LoginScreenWithOtp({super.key});

  @override
  State<LoginScreenWithOtp> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreenWithOtp>
    with SingleTickerProviderStateMixin {
  final _formKey = GlobalKey<FormState>();
  final _mobileController = TextEditingController();
  final _otpController = TextEditingController();
  bool _showOtpField = false;
  bool _isLoading = false;
  bool _isResending = false;

  // ===== OTP constants & keys =====
  static const _otpKeyCode = 'otp_code';
  static const _otpKeyMobile = 'otp_mobile';
  static const _otpKeyExpiry = 'otp_expiry'; // epoch millis
  static const _otpKeyCooldown = 'otp_cooldown'; // epoch millis

  // Bypass configuration — only active in debug mode
  static final String _bypassMobile = kDebugMode ? '527777777' : '';
  static final String _bypassOtp = kDebugMode ? '123456' : '';

  // Using SMS UAE Service for all API calls

  SharedPreferences? _prefs;
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    // Initialize animations
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1000),
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
    _animationController.forward();
  }

  // ========= SharedPreferences helpers =========
  Future<void> _initPrefs() async {
    _prefs ??= await SharedPreferences.getInstance();
  }

  Future<void> _saveOtpLocally({
    required String mobile,
    required String otp,
  }) async {
    await _initPrefs();
    final expiry = DateTime.now().add(ApiConfig.otpTtl).millisecondsSinceEpoch;
    await _prefs!.setString(_otpKeyCode, otp);
    await _prefs!.setString(_otpKeyMobile, mobile);
    await _prefs!.setInt(_otpKeyExpiry, expiry);
  }

  Future<Map<String, dynamic>?> _loadOtp() async {
    await _initPrefs();
    final otp = _prefs!.getString(_otpKeyCode);
    final mobile = _prefs!.getString(_otpKeyMobile);
    final expiry = _prefs!.getInt(_otpKeyExpiry);
    if (otp == null || mobile == null || expiry == null) return null;
    return {'otp': otp, 'mobile': mobile, 'expiry': expiry};
  }

  Future<void> _clearOtp() async {
    await _initPrefs();
    await _prefs!.remove(_otpKeyCode);
    await _prefs!.remove(_otpKeyMobile);
    await _prefs!.remove(_otpKeyExpiry);
  }

  Future<void> _setResendCooldown() async {
    await _initPrefs();
    final ts = DateTime.now()
        .add(ApiConfig.resendCooldown)
        .millisecondsSinceEpoch;
    await _prefs!.setInt(_otpKeyCooldown, ts);
  }

  Future<int?> _getResendCooldownLeft() async {
    await _initPrefs();
    final until = _prefs!.getInt(_otpKeyCooldown);
    if (until == null) return null;
    final now = DateTime.now().millisecondsSinceEpoch;
    final left = until - now;
    return left > 0 ? left : 0;
  }

  // ========= OTP utils & API =========
  String _genOtp6() {
    final rnd = Random.secure();
    final otp = (rnd.nextInt(900000) + 100000).toString(); // 100000..999999
    assert(otp.length == 6, 'OTP must be exactly 6 digits, got: $otp');
    debugPrint('🔢 Generated OTP: $otp (length: ${otp.length})');
    return otp;
  }

  // Store in prefs as MSISDN starting with 971 to avoid mismatch later.
  String _normalizeForPrefs(String raw) {
    var d = raw.replaceAll(RegExp(r'\D'), '');
    if (d.startsWith('971')) return d;
    return '971$d';
  }

  // Debug method to show mobile number formats
  void _debugMobileFormats(String rawMobile) {
    debugPrint('=== Mobile Number Debug ===');
    debugPrint('Raw input: $rawMobile');
    debugPrint('Normalized for prefs: ${_normalizeForPrefs(rawMobile)}');
    debugPrint('All formats to try: ${_getAllMobileFormats(rawMobile)}');
    debugPrint('========================');
  }

  // Get all possible mobile number formats to try
  // Priority: 971 prefix formats first (as they work in Postman)
  List<String> _getAllMobileFormats(String rawMobile) {
    final cleaned = rawMobile.replaceAll(RegExp(r'[^0-9]'), '');
    final formats = <String>[];

    // PRIORITY 1: If it's 9 digits, try with 971 prefix FIRST
    if (cleaned.length == 9) {
      formats.add('971$cleaned'); // Try this first!
      formats.add(cleaned); // Then try without prefix
    }
    // PRIORITY 2: If it already starts with 971 and is 12 digits, use it as-is
    else if (cleaned.startsWith('971') && cleaned.length == 12) {
      formats.add(cleaned); // Already has 971 prefix
      formats.add(cleaned.substring(3)); // Also try without prefix
    }
    // PRIORITY 3: If it's longer than 9, extract last 9 and add 971 prefix
    else if (cleaned.length > 9) {
      final last9 = cleaned.substring(cleaned.length - 9);
      formats.add('971$last9'); // Try with 971 prefix first
      formats.add(last9); // Then try without prefix
    }
    // FALLBACK: Use cleaned input as-is
    else if (cleaned.isNotEmpty) {
      formats.add(cleaned);
    }

    // Remove duplicates while preserving order
    final uniqueFormats = <String>[];
    for (final format in formats) {
      if (!uniqueFormats.contains(format)) {
        uniqueFormats.add(format);
      }
    }

    debugPrint('📱 Mobile formats (priority order): $uniqueFormats');
    return uniqueFormats;
  }

  // --- Send OTP using direct SMS UAE Service endpoint ---
  Future<Map<String, dynamic>> _sendOtpDirectly(
    String rawMobile,
    String otp,
  ) async {
    final msg = ApiConfig.otpMessage(otp);

    try {
      debugPrint('📤 Sending OTP to: $rawMobile');
      debugPrint('📤 URL: ${ApiConfig.sendSmsUrl}');
      debugPrint('📤 Message: $msg');
      debugPrint(
        '📤 Request body: {"mobileNo": "$rawMobile", "message": "$msg", "priority": "High", "countryCode": "ALL"}',
      );

      final response = await SmsUaeService.sendSms(
        mobileNo: rawMobile,
        message: msg,
        priority: 'High',
        countryCode: 'ALL',
      );

      debugPrint('📥 Response status: ${response.statusCode}');
      debugPrint('📥 Response success: ${response.success}');
      debugPrint('📥 Response message: ${response.message}');

      // Build detailed response message
      String responseDetails =
          'Status: ${response.statusCode}, Success: ${response.success}';
      if (response.message != null && response.message!.isNotEmpty) {
        responseDetails += ', Message: ${response.message}';
      }
      if (response.forwardedTo != null) {
        responseDetails += ', ForwardedTo: ${response.forwardedTo}';
      }
      if (response.response != null) {
        responseDetails += ', Response: ${response.response}';
      }

      if (response.success) {
        debugPrint('✅ OTP sent successfully to $rawMobile');
        return {
          'success': true,
          'error': null,
          'responseDetails': responseDetails,
        };
      }

      String errorMsg = 'Failed to send OTP';
      if (response.message != null && response.message!.isNotEmpty) {
        errorMsg = response.message!;
      } else {
        errorMsg += ' (Status: ${response.statusCode})';
      }

      debugPrint('❌ Failed to send OTP to $rawMobile: $errorMsg');
      return {
        'success': false,
        'error': errorMsg,
        'responseDetails': responseDetails,
      };
    } catch (e) {
      final errorMsg = 'Network error: ${e.toString()}';
      debugPrint('❌ Network error sending OTP to $rawMobile: $e');
      return {
        'success': false,
        'error': errorMsg,
        'responseDetails': 'Exception: $e',
      };
    }
  }

  // ========= Actions =========
  Future<void> _handleOtpLogin() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      final mobileRaw = _mobileController.text.trim();
      final enteredOtp = _otpController.text.trim();

      if (enteredOtp.isEmpty) {
        setState(() => _isLoading = false);
        _showErrorSnackBar('Please enter OTP');
        return;
      }

      if (enteredOtp.length != 6 || !RegExp(r'^\d{6}$').hasMatch(enteredOtp)) {
        setState(() => _isLoading = false);
        _showErrorSnackBar('OTP must be 6 digits');
        return;
      }

      final stored = await _loadOtp();
      if (stored == null) {
        setState(() => _isLoading = false);
        _showErrorSnackBar('No OTP found. Please request a new OTP.');
        return;
      }

      final now = DateTime.now().millisecondsSinceEpoch;
      final targetMobile = stored['mobile'] as String;
      final savedOtp = stored['otp'] as String;
      final expiry = stored['expiry'] as int;

      if (_normalizeForPrefs(mobileRaw) != targetMobile) {
        setState(() => _isLoading = false);
        _showErrorSnackBar('Mobile number mismatch. Request OTP again.');
        return;
      }

      if (now > expiry) {
        setState(() => _isLoading = false);
        _showErrorSnackBar('OTP expired. Please request a new OTP.');
        return;
      }

      if (enteredOtp != savedOtp) {
        setState(() => _isLoading = false);
        _showErrorSnackBar('Invalid OTP. Please try again.');
        return;
      }

      // Success -> clear OTP
      await _clearOtp();

      // Get full user profile with all details
      debugPrint('🔍 Fetching full user profile for navigation...');
      final profileResponse = await SmsUaeService.getFullProfileByMobile(
        mobileRaw,
      );

      if (!profileResponse.success || profileResponse.data == null) {
        setState(() => _isLoading = false);
        _showNotRegisteredDialog();
        return;
      }

      final userProfile = profileResponse.data!;
      debugPrint(
        '👤 User profile loaded: ${userProfile.fullName} (${userProfile.route})',
      );
      debugPrint('📊 Profile complete: ${userProfile.isProfileComplete}');
      debugPrint('📝 Missing fields: ${userProfile.missingRequiredFields}');

      // Determine navigation target based on profile completeness
      final navigationResult =
          ProfileCompletionService.determineNavigationTarget(userProfile);

      // Set enhanced user session with profile data
      final role = userProfile.isPainter ? 'PAINTER' : 'CONTRACTOR';
      final enhancedUser = UserData(
        emplName: userProfile.fullName.isNotEmpty
            ? userProfile.fullName
            : 'OTP User',
        areaCode: userProfile.areaCode ?? 'DEFAULT',
        deptCode: '',
        roles: [role],
        pages: ['DASHBOARD'],
      );
      AuthManager.setUser(enhancedUser);

      // Store mobile number in SharedPreferences for profile fetching
      await _initPrefs();
      final normalizedMobile = _normalizeForPrefs(mobileRaw);
      await _prefs!.setString('user_mobile', normalizedMobile);
      if (userProfile.isPainter) {
        await _prefs!.setString('painter_mobile', normalizedMobile);
      } else {
        await _prefs!.setString('contractor_mobile', normalizedMobile);
      }
      debugPrint('💾 Stored mobile number: $normalizedMobile');

      if (!mounted) return;

      // Show welcome message
      _showSuccessSnackBar('Welcome back, ${userProfile.fullName}!');

      // Navigate to home screen with full context
      debugPrint('🧭 Navigating to: ${navigationResult.targetRoute}');
      context.go(
        navigationResult.targetRoute,
        extra: navigationResult.getNavigationExtras(userProfile, mobileRaw),
      );

      setState(() => _isLoading = false);
    } catch (_) {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  void _showErrorSnackBar(String message) {
    AppSnackBar.showError(context, message);
  }

  void _showSuccessSnackBar(String message, {IconData? icon}) {
    AppSnackBar.showSuccess(context, message, icon: icon);
  }

  void _showNotRegisteredDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          title: Row(
            children: [
              Icon(
                Icons.person_add_outlined,
                color: Colors.blue.shade600,
                size: 28,
              ),
              const SizedBox(width: 12),
              const Text(
                'Not Registered',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
              ),
            ],
          ),
          content: const Text(
            'You are not registered yet. Please complete your registration first to access your account.',
            style: TextStyle(fontSize: 16, height: 1.4),
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: Text(
                'Cancel',
                style: TextStyle(color: Colors.grey.shade600, fontSize: 16),
              ),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.of(context).pop();
                context.go(RouteNames.registrationType);
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.blue.shade600,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(
                  horizontal: 24,
                  vertical: 12,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              child: const Text(
                'Register',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
              ),
            ),
          ],
        );
      },
    );
  }

  @override
  void dispose() {
    _mobileController.dispose();
    _otpController.dispose();
    _animationController.dispose();
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
          final isMobile = constraints.maxWidth < 600;
          final isTablet =
              constraints.maxWidth >= 600 && constraints.maxWidth < 1200;
          final isDesktop = constraints.maxWidth >= 1200;

          return Container(
            width: double.infinity,
            height: double.infinity,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  Colors.blue.shade50,
                  Colors.blue.shade100,
                  Colors.purple.shade50,
                ],
              ),
            ),
            child: Stack(
              children: [
                if (Navigator.of(context).canPop())
                  const Positioned(
                    top: 50,
                    left: 20,
                    child: CustomBackButton(),
                  ),
                isMobile
                    ? _buildMobileLayout()
                    : _buildWebLayout(isTablet, isDesktop),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildMobileLayout() {
    return Center(
      child: SingleChildScrollView(
        child: FadeTransition(
          opacity: _fadeAnimation,
          child: SlideTransition(
            position: _slideAnimation,
            child: ScaleTransition(
              scale: _scaleAnimation,
              child: Container(
                constraints: const BoxConstraints(maxWidth: 420),
                margin: const EdgeInsets.symmetric(horizontal: 24),
                child: Card(
                  elevation: 24,
                  shadowColor: Colors.blue.withOpacity(0.15),
                  color: Colors.white.withOpacity(0.98),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(28),
                  ),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 300),
                    padding: const EdgeInsets.all(40),
                    child: _buildLoginForm(),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildWebLayout(bool isTablet, bool isDesktop) {
    return Row(
      children: [
        // Left side - Branding/Info
        Expanded(
          flex: isDesktop ? 3 : 2,
          child: Container(
            padding: EdgeInsets.all(isDesktop ? 80 : 60),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildAnimatedLogo(),
                SizedBox(height: isDesktop ? 40 : 32),
                Text(
                  'Welcome Back',
                  style: TextStyle(
                    fontSize: isDesktop ? 48 : 36,
                    fontWeight: FontWeight.bold,
                    color: Colors.blue.shade800,
                  ),
                ),
                SizedBox(height: isDesktop ? 20 : 16),
                Text(
                  'Enter your mobile number to receive an OTP and access your RAK account.',
                  style: TextStyle(
                    fontSize: isDesktop ? 18 : 16,
                    color: Colors.grey.shade600,
                    height: 1.5,
                  ),
                ),
              ],
            ),
          ),
        ),
        // Right side - Login Form
        Expanded(
          flex: isDesktop ? 2 : 3,
          child: Container(
            height: double.infinity,
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.98),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.1),
                  blurRadius: 20,
                  offset: const Offset(-5, 0),
                ),
              ],
            ),
            child: Center(
              child: SingleChildScrollView(
                padding: EdgeInsets.all(isDesktop ? 60 : 40),
                child: FadeTransition(
                  opacity: _fadeAnimation,
                  child: SlideTransition(
                    position: _slideAnimation,
                    child: Container(
                      constraints: const BoxConstraints(maxWidth: 400),
                      child: _buildLoginForm(),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildAnimatedLogo() {
    return TweenAnimationBuilder<double>(
      tween: Tween<double>(begin: 0, end: 1),
      duration: const Duration(milliseconds: 600),
      curve: Curves.easeOutCubic,
      builder: (context, value, child) {
        return Transform.scale(
          scale: 0.8 + (0.2 * value),
          child: Container(
            height: 120,
            width: 120,
            decoration: BoxDecoration(
              color: Colors.white,
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: Colors.blue.withOpacity(0.2),
                  blurRadius: 15,
                  spreadRadius: 3,
                ),
              ],
            ),
            child: Padding(
              padding: const EdgeInsets.all(8.0),
              child: DualLogoWidget(
                height: 70.0,
                width: 120.0,
                fit: BoxFit.contain,
                isCircular: true,
                spacing: 6.0,
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildLoginForm() {
    return Form(
      key: _formKey,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildAnimatedTitle(),
          const SizedBox(height: 32),
          ModernTextField(
            controller: _mobileController,
            labelText: 'Mobile Number',
            hintText: '50XXXXXXX',
            prefixText: '+971 ',
            keyboardType: TextInputType.phone,
            isDark: false,
            prefixIcon: Icons.phone_outlined,
            maxLength: 9,
            validator: (value) {
              if (value == null || value.trim().isEmpty) {
                return 'Please enter mobile number';
              }
              if (value.trim().length != 9) {
                return 'Mobile number must be 9 digits';
              }
              return null;
            },
            delay: const Duration(milliseconds: 300),
          ),
          const SizedBox(height: 24),
          if (_showOtpField)
            ModernTextField(
              controller: _otpController,
              labelText: 'OTP',
              hintText: 'Enter 6-digit OTP',
              keyboardType: TextInputType.number,
              isDark: false,
              prefixIcon: Icons.security_outlined,
              maxLength: 6,
              validator: (value) {
                if (!_showOtpField) return null;
                if (value == null || value.trim().isEmpty) {
                  return 'Please enter OTP';
                }
                if (value.trim().length != 6) {
                  return 'OTP must be 6 digits';
                }
                return null;
              },
              delay: const Duration(milliseconds: 450),
            ),
          const SizedBox(height: 32),
          if (!_showOtpField)
            ModernButton(
              text: 'Get OTP',
              isLoading: _isLoading,
              onPressed: () async {
                if (_isLoading) return;
                if (!_formKey.currentState!.validate()) return;

                final mobileRaw = _mobileController.text.trim();

                // Check if this is the bypass number
                final cleanedMobile = mobileRaw.replaceAll(RegExp(r'\D'), '');
                final isBypassNumber =
                    cleanedMobile == _bypassMobile ||
                    cleanedMobile == '971$_bypassMobile' ||
                    cleanedMobile.endsWith(_bypassMobile);

                // Rate-limit for resend
                final leftMs = await _getResendCooldownLeft();
                if (leftMs != null && leftMs > 0) {
                  return;
                }

                setState(() => _isLoading = true);

                // If bypass number, skip SMS and use fixed OTP
                if (isBypassNumber) {
                  debugPrint('🔓 Bypass number detected: $mobileRaw');
                  await _saveOtpLocally(
                    mobile: _normalizeForPrefs(mobileRaw),
                    otp: _bypassOtp,
                  );
                  await _setResendCooldown();

                  if (mounted) {
                    setState(() => _isLoading = false);
                    _showSuccessSnackBar(
                      'OTP: $_bypassOtp (Bypass mode)',
                      icon: Icons.message_outlined,
                    );
                    setState(() => _showOtpField = true);
                  }
                  return;
                }

                // Debug mobile number formats
                _debugMobileFormats(mobileRaw);

                // Test basic connectivity first
                debugPrint('🔍 Testing API connectivity...');
                debugPrint('🌐 Base URL: ${ApiConfig.baseUrl}');
                debugPrint('� Heealth URL: ${ApiConfig.healthCheckUrl}');
                debugPrint(
                  '🌐 Send-if-registered URL: ${ApiConfig.sendIfRegisteredUrl}',
                );
                final healthCheck = await SmsUaeService.checkHealth();
                debugPrint('🏥 Health check result: $healthCheck');

                // Generate OTP and send using direct SMS UAE Service endpoint
                final otp = _genOtp6();
                bool sent = false;
                String? lastError;

                // Try different mobile formats until one works
                final formats = _getAllMobileFormats(mobileRaw);
                debugPrint('Trying ${formats.length} formats: $formats');

                // Send OTP directly using /api/SmsUae/send endpoint
                String? responseDetails;
                for (final format in formats) {
                  final result = await _sendOtpDirectly(format, otp);
                  responseDetails = result['responseDetails'];
                  if (result['success'] == true) {
                    sent = true;
                    debugPrint('✅ OTP sent successfully with format: $format');
                    break;
                  } else {
                    lastError = result['error'];
                  }
                }

                if (mounted) setState(() => _isLoading = false);

                if (sent) {
                  // Save OTP locally for client-side match
                  await _saveOtpLocally(
                    mobile: _normalizeForPrefs(mobileRaw),
                    otp: otp,
                  );
                  await _setResendCooldown();

                  if (mounted) {
                    _showSuccessSnackBar(
                      'OTP sent successfully to your mobile',
                      icon: Icons.message_outlined,
                    );
                    setState(() => _showOtpField = true);
                  }
                } else {
                  // All attempts failed - show the last error
                  debugPrint('❌ Failed to send OTP with all formats: $formats');
                  debugPrint('❌ API Response: $responseDetails');
                  if (mounted) {
                    _showErrorSnackBar(
                      lastError ?? 'Failed to send OTP. Please try again.',
                    );
                  }
                }
              },
              isPrimary: true,
              isDark: false,
              delay: const Duration(milliseconds: 600),
            ),
          if (_showOtpField) ...[
            ModernButton(
              text: 'Verify & Login',
              isLoading: _isLoading,
              onPressed: () async => _handleOtpLogin(),
              isPrimary: true,
              isDark: false,
              delay: const Duration(milliseconds: 600),
            ),
            const SizedBox(height: 16),
            ModernButton(
              text: 'Resend OTP',
              isLoading: _isResending,
              onPressed: () async {
                if (_isResending) return;

                // Check cooldown
                final leftMs = await _getResendCooldownLeft();
                if (leftMs != null && leftMs > 0) {
                  final seconds = (leftMs / 1000).ceil();
                  if (mounted) {
                    _showErrorSnackBar(
                      'Please wait $seconds seconds before resending',
                    );
                  }
                  return;
                }

                final mobileRaw = _mobileController.text.trim();
                if (mobileRaw.isEmpty) {
                  _showErrorSnackBar('Mobile number is required');
                  return;
                }

                // Check if this is the bypass number
                final cleanedMobile = mobileRaw.replaceAll(RegExp(r'\D'), '');
                final isBypassNumber =
                    cleanedMobile == _bypassMobile ||
                    cleanedMobile == '971$_bypassMobile' ||
                    cleanedMobile.endsWith(_bypassMobile);

                setState(() => _isResending = true);

                try {
                  // If bypass number, skip SMS and use fixed OTP
                  if (isBypassNumber) {
                    debugPrint(
                      '🔓 Bypass number detected (resend): $mobileRaw',
                    );
                    await _saveOtpLocally(
                      mobile: _normalizeForPrefs(mobileRaw),
                      otp: _bypassOtp,
                    );
                    await _setResendCooldown();

                    if (mounted) {
                      _showSuccessSnackBar(
                        'OTP: $_bypassOtp (Bypass mode)',
                        icon: Icons.refresh,
                      );
                    }
                    return;
                  }

                  // Generate new OTP and send using direct SMS UAE Service endpoint
                  final otp = _genOtp6();
                  bool sent = false;
                  String? lastError;
                  String? responseDetails;

                  // Try different mobile formats until one works
                  final formats = _getAllMobileFormats(mobileRaw);
                  debugPrint(
                    'Resending OTP with ${formats.length} formats: $formats',
                  );

                  for (final format in formats) {
                    final result = await _sendOtpDirectly(format, otp);
                    responseDetails = result['responseDetails'];
                    if (result['success'] == true) {
                      sent = true;
                      debugPrint(
                        '✅ OTP resent successfully with format: $format',
                      );
                      break;
                    } else {
                      lastError = result['error'];
                      debugPrint('❌ Failed with format $format: $lastError');
                    }
                  }

                  if (sent) {
                    await _saveOtpLocally(
                      mobile: _normalizeForPrefs(mobileRaw),
                      otp: otp,
                    );
                    await _setResendCooldown();

                    if (mounted) {
                      _showSuccessSnackBar(
                        'OTP resent successfully',
                        icon: Icons.refresh,
                      );
                    }
                  } else {
                    // Resend failed - show the last error
                    debugPrint('❌ API Response: $responseDetails');
                    if (mounted) {
                      _showErrorSnackBar(
                        lastError ?? 'Failed to resend OTP. Please try again.',
                      );
                    }
                  }
                } finally {
                  if (mounted) {
                    setState(() => _isResending = false);
                  }
                }
              },
              isPrimary: false,
              isDark: false,
              delay: const Duration(milliseconds: 750),
            ),
          ],
          const SizedBox(height: 24),
          _buildSignUpSection(),
        ],
      ),
    );
  }

  Widget _buildAnimatedTitle() {
    return TweenAnimationBuilder<double>(
      tween: Tween<double>(begin: 0, end: 1),
      duration: const Duration(milliseconds: 600),
      curve: Curves.easeOut,
      builder: (context, value, child) {
        return Opacity(
          opacity: value,
          child: Transform.translate(
            offset: Offset(0, 20 * (1 - value)),
            child: child,
          ),
        );
      },
      child: Text(
        'OTP Login',
        style: const TextStyle(
          fontSize: 28,
          fontWeight: FontWeight.bold,
          color: Colors.blue,
        ),
      ),
    );
  }

  Widget _buildSignUpSection() {
    return TweenAnimationBuilder<double>(
      tween: Tween<double>(begin: 0, end: 1),
      duration: const Duration(milliseconds: 800),
      builder: (context, value, child) {
        return Opacity(
          opacity: value,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                "Don't have an account? ",
                style: TextStyle(fontSize: 14, color: Colors.grey.shade600),
              ),
              TextButton(
                onPressed: () {
                  context.push(RouteNames.registrationType);
                },
                style: TextButton.styleFrom(
                  padding: const EdgeInsets.symmetric(horizontal: 8),
                  minimumSize: Size.zero,
                  tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                ),
                child: Text(
                  'Sign up',
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.blue.shade600,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

// ---------------- Shared UI widgets (unchanged) ----------------
class ModernTextField extends StatefulWidget {
  final TextEditingController controller;
  final String labelText;
  final String? hintText;
  final String? prefixText;
  final TextInputType keyboardType;
  final String? Function(String?)? validator;
  final Duration delay;
  final bool isDark;
  final IconData? prefixIcon;
  final int? maxLength;

  const ModernTextField({
    super.key,
    required this.controller,
    required this.labelText,
    this.hintText,
    this.prefixText,
    required this.keyboardType,
    this.validator,
    required this.delay,
    required this.isDark,
    this.prefixIcon,
    this.maxLength,
  });

  @override
  State<ModernTextField> createState() => _ModernTextFieldState();
}

class _ModernTextFieldState extends State<ModernTextField> {
  bool _isVisible = false;
  bool _isFocused = false;

  @override
  void initState() {
    super.initState();
    Future.delayed(widget.delay, () {
      if (mounted) {
        setState(() {
          _isVisible = true;
        });
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedOpacity(
      opacity: _isVisible ? 1.0 : 0.0,
      duration: const Duration(milliseconds: 500),
      curve: Curves.easeOut,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        transform: Matrix4.translationValues(_isVisible ? 0 : 20, 0, 0),
        child: Focus(
          onFocusChange: (focused) {
            setState(() {
              _isFocused = focused;
            });
          },
          child: TextFormField(
            controller: widget.controller,
            keyboardType: widget.keyboardType,
            maxLength: widget.maxLength,
            style: const TextStyle(fontSize: 16, color: Colors.black87),
            decoration: InputDecoration(
              counterText: widget.maxLength != null ? '' : null,
              labelText: widget.labelText,
              hintText: widget.hintText,
              prefixText: widget.prefixText,
              prefixStyle: const TextStyle(
                fontSize: 16,
                color: Colors.black87,
                fontWeight: FontWeight.w500,
              ),
              prefixIcon: widget.prefixIcon != null
                  ? Icon(
                      widget.prefixIcon,
                      color: _isFocused ? Colors.blue : Colors.grey.shade600,
                    )
                  : null,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(16),
                borderSide: BorderSide(color: Colors.grey.shade300),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(16),
                borderSide: BorderSide(color: Colors.grey.shade300),
              ),
              focusedBorder: const OutlineInputBorder(
                borderRadius: BorderRadius.all(Radius.circular(16)),
                borderSide: BorderSide(color: Colors.blue, width: 2),
              ),
              errorBorder: const OutlineInputBorder(
                borderRadius: BorderRadius.all(Radius.circular(16)),
                borderSide: BorderSide(color: Colors.red, width: 1),
              ),
              focusedErrorBorder: const OutlineInputBorder(
                borderRadius: BorderRadius.all(Radius.circular(16)),
                borderSide: BorderSide(color: Colors.red, width: 2),
              ),
              filled: true,
              fillColor: Colors.grey.shade50,
              labelStyle: TextStyle(
                color: _isFocused ? Colors.blue : Colors.grey.shade600,
              ),
              hintStyle: TextStyle(color: Colors.grey.shade400),
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 20,
                vertical: 20,
              ),
            ),
            validator: widget.validator,
          ),
        ),
      ),
    );
  }
}

class ModernButton extends StatefulWidget {
  final String text;
  final bool isLoading;
  final VoidCallback onPressed;
  final Duration delay;
  final bool isPrimary;
  final bool isDark;

  const ModernButton({
    super.key,
    required this.text,
    required this.isLoading,
    required this.onPressed,
    required this.delay,
    required this.isPrimary,
    required this.isDark,
  });

  @override
  State<ModernButton> createState() => _ModernButtonState();
}

class _ModernButtonState extends State<ModernButton> {
  bool _isVisible = false;
  bool _isHovered = false;

  @override
  void initState() {
    super.initState();
    Future.delayed(widget.delay, () {
      if (mounted) {
        setState(() {
          _isVisible = true;
        });
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedOpacity(
      opacity: _isVisible ? 1.0 : 0.0,
      duration: const Duration(milliseconds: 500),
      curve: Curves.easeOut,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        transform: Matrix4.translationValues(_isVisible ? 0 : 20, 0, 0),
        child: SizedBox(
          width: double.infinity,
          height: 56,
          child: widget.isPrimary
              ? ElevatedButton(
                  onPressed: widget.isLoading ? null : widget.onPressed,
                  style:
                      ElevatedButton.styleFrom(
                        elevation: _isHovered ? 12 : 6,
                        shadowColor: Colors.blue.withOpacity(0.3),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                        backgroundColor: Colors.blue,
                        foregroundColor: Colors.white,
                      ).copyWith(
                        backgroundColor: MaterialStateProperty.resolveWith((
                          states,
                        ) {
                          if (states.contains(MaterialState.disabled)) {
                            return Colors.grey.shade400;
                          }
                          return Colors.blue;
                        }),
                      ),
                  onHover: (hovering) {
                    setState(() {
                      _isHovered = hovering;
                    });
                  },
                  child: widget.isLoading
                      ? const Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: Colors.white,
                              ),
                            ),
                            SizedBox(width: 16),
                            Text('Please wait...'),
                          ],
                        )
                      : Text(
                          widget.text,
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                            letterSpacing: 0.5,
                          ),
                        ),
                )
              : OutlinedButton(
                  onPressed: widget.onPressed,
                  style: OutlinedButton.styleFrom(
                    side: BorderSide(color: Colors.grey.shade300, width: 1.5),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                    backgroundColor: _isHovered ? Colors.grey.shade50 : null,
                  ),
                  onHover: (hovering) {
                    setState(() {
                      _isHovered = hovering;
                    });
                  },
                  child: Text(
                    widget.text,
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w500,
                      color: Colors.grey.shade700,
                      letterSpacing: 0.5,
                    ),
                  ),
                ),
        ),
      ),
    );
  }
}

class AnimatedTextField extends StatefulWidget {
  final TextEditingController controller;
  final String labelText;
  final String? hintText;
  final String? prefixText;
  final TextInputType keyboardType;
  final String? Function(String?)? validator;
  final Duration delay;

  const AnimatedTextField({
    super.key,
    required this.controller,
    required this.labelText,
    this.hintText,
    this.prefixText,
    required this.keyboardType,
    this.validator,
    required this.delay,
  });

  @override
  State<AnimatedTextField> createState() => _AnimatedTextFieldState();
}

class _AnimatedTextFieldState extends State<AnimatedTextField> {
  bool _isVisible = false;

  @override
  void initState() {
    super.initState();
    Future.delayed(widget.delay, () {
      if (mounted) {
        setState(() {
          _isVisible = true;
        });
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedOpacity(
      opacity: _isVisible ? 1.0 : 0.0,
      duration: const Duration(milliseconds: 500),
      curve: Curves.easeOut,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        transform: Matrix4.translationValues(_isVisible ? 0 : 20, 0, 0),
        child: TextFormField(
          controller: widget.controller,
          decoration: InputDecoration(
            labelText: widget.labelText,
            hintText: widget.hintText,
            prefixText: widget.prefixText,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide.none,
            ),
            filled: true,
            fillColor: Colors.grey.shade100,
            focusedBorder: const OutlineInputBorder(
              borderRadius: BorderRadius.all(Radius.circular(12)),
              borderSide: BorderSide(color: Colors.blue, width: 2),
            ),
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 16,
              vertical: 16,
            ),
          ),
          keyboardType: widget.keyboardType,
          validator: widget.validator,
        ),
      ),
    );
  }
}

class AnimatedCheckbox extends StatefulWidget {
  final bool value;
  final Function(bool?)? onChanged;
  final Duration delay;

  const AnimatedCheckbox({
    super.key,
    required this.value,
    this.onChanged,
    required this.delay,
  });

  @override
  State<AnimatedCheckbox> createState() => _AnimatedCheckboxState();
}

class _AnimatedCheckboxState extends State<AnimatedCheckbox> {
  bool _isVisible = false;

  @override
  void initState() {
    super.initState();
    Future.delayed(widget.delay, () {
      if (mounted) {
        setState(() {
          _isVisible = true;
        });
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedOpacity(
      opacity: _isVisible ? 1.0 : 0.0,
      duration: const Duration(milliseconds: 500),
      curve: Curves.easeOut,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        transform: Matrix4.translationValues(_isVisible ? 0 : 20, 0, 0),
        child: Row(
          children: [
            AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: widget.value ? Colors.blue : Colors.transparent,
                border: Border.all(
                  color: widget.value ? Colors.blue : Colors.grey,
                  width: 2,
                ),
              ),
              width: 24,
              height: 24,
              child: widget.value
                  ? const Icon(Icons.check, color: Colors.white, size: 16)
                  : null,
            ),
            const SizedBox(width: 12),
            GestureDetector(
              onTap: () => widget.onChanged?.call(!widget.value),
              child: const Text(
                'Employee Login',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class AnimatedButton extends StatefulWidget {
  final String text;
  final bool isLoading;
  final VoidCallback onPressed;
  final Duration delay;
  final Color? textColor;

  const AnimatedButton({
    super.key,
    required this.text,
    required this.isLoading,
    required this.onPressed,
    required this.delay,
    this.textColor,
  });

  @override
  State<AnimatedButton> createState() => _AnimatedButtonState();
}

class _AnimatedButtonState extends State<AnimatedButton> {
  bool _isVisible = false;

  @override
  void initState() {
    super.initState();
    Future.delayed(widget.delay, () {
      if (mounted) {
        setState(() {
          _isVisible = true;
        });
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedOpacity(
      opacity: _isVisible ? 1.0 : 0.0,
      duration: const Duration(milliseconds: 500),
      curve: Curves.easeOut,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        transform: Matrix4.translationValues(_isVisible ? 0 : 20, 0, 0),
        child: SizedBox(
          width: double.infinity,
          height: 56,
          child: ElevatedButton(
            onPressed: widget.isLoading ? null : widget.onPressed,
            style: ElevatedButton.styleFrom(
              elevation: 8,
              shadowColor: Colors.blue.withOpacity(0.3),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              backgroundColor: Colors.blue,
              foregroundColor: widget.textColor ?? Colors.white,
            ),
            child: widget.isLoading
                ? const Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      ),
                      SizedBox(width: 16),
                      Text('Please wait...'),
                    ],
                  )
                : Text(
                    widget.text,
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: widget.textColor ?? Colors.white,
                    ),
                  ),
          ),
        ),
      ),
    );
  }
}

class AnimatedOutlineButton extends StatefulWidget {
  final String text;
  final VoidCallback onPressed;
  final Duration delay;

  const AnimatedOutlineButton({
    super.key,
    required this.text,
    required this.onPressed,
    required this.delay,
  });

  @override
  State<AnimatedOutlineButton> createState() => _AnimatedOutlineButtonState();
}

class _AnimatedOutlineButtonState extends State<AnimatedOutlineButton> {
  bool _isVisible = false;
  bool _isHovered = false;

  @override
  void initState() {
    super.initState();
    Future.delayed(widget.delay, () {
      if (mounted) {
        setState(() {
          _isVisible = true;
        });
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedOpacity(
      opacity: _isVisible ? 1.0 : 0.0,
      duration: const Duration(milliseconds: 500),
      curve: Curves.easeOut,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        transform: Matrix4.translationValues(_isVisible ? 0 : 20, 0, 0),
        child: MouseRegion(
          onEnter: (_) => setState(() => _isHovered = true),
          onExit: (_) => setState(() => _isHovered = false),
          child: OutlinedButton(
            onPressed: widget.onPressed,
            style: OutlinedButton.styleFrom(
              side: BorderSide(
                color: _isHovered ? Colors.blue : Colors.grey.shade400,
                width: 1.5,
              ),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              backgroundColor: _isHovered
                  ? Colors.blue.withOpacity(0.05)
                  : null,
            ),
            child: Text(
              widget.text,
              style: TextStyle(
                fontSize: 14,
                color: _isHovered ? Colors.blue : Colors.grey.shade700,
              ),
            ),
          ),
        ),
      ),
    );
  }
}
