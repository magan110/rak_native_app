import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:go_router/go_router.dart';
import 'package:rak_app/core/services/auth_service.dart';
import 'package:rak_app/core/models/auth_models.dart';
import 'package:rak_app/core/services/storage_service.dart';
import 'package:rak_app/shared/widgets/custom_back_button.dart';

class LoginWithPasswordScreen extends StatefulWidget {
  const LoginWithPasswordScreen({super.key});

  @override
  State<LoginWithPasswordScreen> createState() =>
      _LoginWithPasswordScreenState();
}

class _LoginWithPasswordScreenState extends State<LoginWithPasswordScreen>
    with SingleTickerProviderStateMixin {
  final _formKey = GlobalKey<FormState>();
  final _userIdController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _isLoading = false;
  final bool _isDarkMode = false;
  bool _rememberMe = false;

  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _initializeAnimations();
    _animationController.forward();
    _loadSavedCredentials();
  }

  Future<void> _loadSavedCredentials() async {
    final rememberMe = await StorageService.getRememberMe();
    if (rememberMe) {
      final savedUserId = await StorageService.getUserId();
      if (savedUserId != null) {
        setState(() {
          _userIdController.text = savedUserId;
          _rememberMe = true;
        });
      }
    }
  }

  void _initializeAnimations() {
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
  }

  @override
  void dispose() {
    _userIdController.dispose();
    _passwordController.dispose();
    _animationController.dispose();
    super.dispose();
  }

  Future<void> _handleLogin() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isLoading = true;
    });

    try {
      final userID = _userIdController.text.trim();
      final password = _passwordController.text.trim();

  // Shortcut: local dummy admin login (no network)
  if (userID == 'admin' && password == 'admin07') {
        // Create minimal UserData and set as current user
        final dummyUser = UserData(
          emplName: 'Administrator',
          areaCode: 'ADM',
          roles: ['ADMIN'],
          pages: ['DASHBOARD'],
          userID: 'admin',
          appRegId: null,
        );

        AuthManager.setUser(dummyUser);

        if (mounted) {
          setState(() => _isLoading = false);
          // Navigate to the app home screen
          context.go('/home');
        }

        return;
      }

      final result = await AuthService.authenticateUser(
        userID: userID,
        password: password,
      );

      if (mounted) {
        setState(() {
          _isLoading = false;
        });

        if (result['success'] == true) {
          final loginResponse = result['data'];
          final userData = loginResponse.data;

          if (_rememberMe) {
            await StorageService.saveUserId(userID);
            await StorageService.saveRememberMe(true);
          } else {
            await StorageService.saveRememberMe(false);
          }

          AuthManager.setUser(userData);
          // After successful auth, go to the home screen
          context.go('/home');
        } else {
          final errorMessage =
              result['error'] ?? 'Login failed. Please try again.';
          _showErrorSnackBar(errorMessage);
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
        _showErrorSnackBar(
          'Network error. Please check your connection and try again.',
        );
      }
    }
  }

  // Navigation is simplified: post-login we now redirect to '/home'.

  void _showErrorSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red,
        behavior: SnackBarBehavior.floating,
        margin: EdgeInsets.all(16.w),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8.r)),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = _isDarkMode;

    SystemChrome.setSystemUIOverlayStyle(
      SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: isDark ? Brightness.light : Brightness.dark,
        statusBarBrightness: isDark ? Brightness.dark : Brightness.light,
      ),
    );

    return Scaffold(
      backgroundColor: isDark ? const Color(0xFF0A0A0A) : Colors.white,
      body: LayoutBuilder(
        builder: (context, constraints) {
          final screenHeight = constraints.maxHeight;
          final screenWidth = constraints.maxWidth;
          final isSmallScreen = screenHeight < 700 || screenWidth < 360;

          return Container(
            width: double.infinity,
            height: double.infinity,
            decoration: BoxDecoration(
              gradient: isDark
                  ? const LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [
                        Color(0xFF0A0A0A),
                        Color(0xFF1A1A2E),
                        Color(0xFF16213E),
                      ],
                    )
                  : const LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [
                        Color(0xFFf8f9ff),
                        Color(0xFFe3f2fd),
                        Color(0xFFffffff),
                      ],
                    ),
            ),
            child: SafeArea(
              child: Stack(
                children: [
                  if (Navigator.of(context).canPop())
                    Positioned(
                      top: 8,
                      left: 8,
                      child: const CustomBackButton(),
                    ),
                  _buildMobileLayout(
                    isDark,
                    screenHeight,
                    screenWidth,
                    isSmallScreen,
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildAnimatedLogo({double size = 100}) {
    return TweenAnimationBuilder<double>(
      tween: Tween<double>(begin: 0, end: 1),
      duration: const Duration(milliseconds: 600),
      curve: Curves.easeOutCubic,
      builder: (context, value, child) {
        return Transform.scale(
          scale: 0.8 + (0.2 * value),
          child: Container(
            height: size,
            width: size,
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
              child: ClipOval(
                child: Image.asset(
                  'assets/images/rak_logo.jpg',
                  fit: BoxFit.contain,
                  errorBuilder: (context, error, stackTrace) {
                    return Container(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [Colors.blue.shade700, Colors.blue.shade500],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        shape: BoxShape.circle,
                      ),
                      child: Center(
                        child: Text(
                          'RAK',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: size * 0.28,
                            fontWeight: FontWeight.bold,
                            letterSpacing: 2,
                          ),
                        ),
                      ),
                    );
                  },
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildMobileLayout(
    bool isDark,
    double screenHeight,
    double screenWidth,
    bool isSmallScreen,
  ) {
    final logoSize = isSmallScreen ? 80.0 : 100.0;
    final horizontalPadding = screenWidth < 360 ? 16.0 : 20.0;
    final cardPadding = isSmallScreen ? 20.0 : 28.0;
    final titleFontSize = isSmallScreen ? 26.0 : 32.0;
    final subtitleFontSize = isSmallScreen ? 13.0 : 15.0;

    return Center(
      child: SingleChildScrollView(
        physics: const BouncingScrollPhysics(),
        padding: EdgeInsets.symmetric(
          horizontal: horizontalPadding,
          vertical: 16,
        ),
        child: FadeTransition(
          opacity: _fadeAnimation,
          child: SlideTransition(
            position: _slideAnimation,
            child: ScaleTransition(
              scale: _scaleAnimation,
              child: Container(
                constraints: BoxConstraints(
                  maxWidth: 440,
                  minHeight: screenHeight * 0.7,
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    // Logo Section
                    _buildAnimatedLogo(size: logoSize),
                    SizedBox(height: isSmallScreen ? 20 : 28),

                    // Welcome Text
                    FadeTransition(
                      opacity: _fadeAnimation,
                      child: Column(
                        children: [
                          Text(
                            'Welcome Back',
                            style: TextStyle(
                              fontSize: titleFontSize,
                              fontWeight: FontWeight.bold,
                              color: isDark
                                  ? Colors.white
                                  : Colors.blue.shade800,
                              letterSpacing: 0.5,
                            ),
                            textAlign: TextAlign.center,
                          ),
                          SizedBox(height: isSmallScreen ? 6 : 8),
                          Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 20),
                            child: Text(
                              'Sign in to access your account',
                              style: TextStyle(
                                fontSize: subtitleFontSize,
                                color: isDark
                                    ? Colors.grey.shade400
                                    : Colors.grey.shade600,
                                height: 1.4,
                              ),
                              textAlign: TextAlign.center,
                            ),
                          ),
                        ],
                      ),
                    ),

                    SizedBox(height: isSmallScreen ? 24 : 32),

                    // Login Form Card
                    Card(
                      elevation: isDark ? 0 : 8,
                      shadowColor: isDark
                          ? Colors.transparent
                          : Colors.blue.withOpacity(0.1),
                      color: isDark
                          ? const Color(0xFF1E1E1E).withOpacity(0.95)
                          : Colors.white.withOpacity(0.98),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(24),
                        side: isDark
                            ? BorderSide(
                                color: Colors.white.withOpacity(0.1),
                                width: 1,
                              )
                            : BorderSide.none,
                      ),
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 300),
                        padding: EdgeInsets.all(cardPadding),
                        child: _buildLoginForm(isDark, isSmallScreen),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildLoginForm(bool isDark, bool isSmallScreen) {
    final fieldSpacing = isSmallScreen ? 16.0 : 20.0;
    final sectionSpacing = isSmallScreen ? 24.0 : 32.0;

    return Form(
      key: _formKey,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _buildAnimatedTitle(isSmallScreen),
          SizedBox(height: sectionSpacing),
          ModernTextField(
            controller: _userIdController,
            labelText: 'User ID',
            hintText: 'Enter your user ID',
            keyboardType: TextInputType.text,
            isDark: isDark,
            prefixIcon: Icons.person_outline,
            validator: (value) {
              if (value == null || value.isEmpty) {
                return 'Please enter your user ID';
              }
              return null;
            },
            delay: const Duration(milliseconds: 300),
          ),
          SizedBox(height: fieldSpacing),
          ModernPasswordField(
            controller: _passwordController,
            labelText: 'Password',
            hintText: 'Enter your password',
            isDark: isDark,
            validator: (value) {
              if (value == null || value.isEmpty) {
                return 'Please enter your password';
              }
              if (value.length < 6) {
                return 'Password must be at least 6 characters';
              }
              return null;
            },
            delay: const Duration(milliseconds: 450),
          ),
          SizedBox(height: isSmallScreen ? 12.0 : 16.0),
          _buildRememberMeSection(isSmallScreen),
          SizedBox(height: sectionSpacing),
          ModernButton(
            text: 'Sign In',
            isLoading: _isLoading,
            onPressed: _handleLogin,
            isPrimary: true,
            isDark: isDark,
            delay: const Duration(milliseconds: 600),
          ),
          SizedBox(height: isSmallScreen ? 12.0 : 16.0),
          ModernButton(
            text: 'Sign Up',
            isLoading: false,
            onPressed: () {
              context.push('/registration-type');
            },
            isPrimary: false,
            isDark: isDark,
            delay: const Duration(milliseconds: 750),
          ),
        ],
      ),
    );
  }

  Widget _buildAnimatedTitle(bool isSmallScreen) {
    final fontSize = isSmallScreen ? 22.0 : 28.0;

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
        'Login',
        style: TextStyle(
          fontSize: fontSize,
          fontWeight: FontWeight.bold,
          color: Colors.blue,
          letterSpacing: 0.5,
        ),
      ),
    );
  }

  Widget _buildRememberMeSection(bool isSmallScreen) {
    final fontSize = isSmallScreen ? 13.0 : 14.0;

    return TweenAnimationBuilder<double>(
      tween: Tween<double>(begin: 0, end: 1),
      duration: const Duration(milliseconds: 600),
      builder: (context, value, child) {
        return Opacity(
          opacity: value,
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              SizedBox(
                width: 22,
                height: 22,
                child: Checkbox(
                  value: _rememberMe,
                  onChanged: (value) {
                    setState(() {
                      _rememberMe = value ?? false;
                    });
                  },
                  activeColor: Colors.blue,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(4),
                  ),
                  materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  visualDensity: VisualDensity.compact,
                ),
              ),
              const SizedBox(width: 8),
              Flexible(
                child: Text(
                  'Remember me',
                  style: TextStyle(
                    fontSize: fontSize,
                    color: _isDarkMode
                        ? Colors.grey.shade300
                        : Colors.grey.shade600,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              const Spacer(),
              Flexible(
                child: TextButton(
                  onPressed: () {
                    _showErrorSnackBar('Forgot password will be implemented');
                  },
                  style: TextButton.styleFrom(
                    padding: EdgeInsets.symmetric(
                      horizontal: isSmallScreen ? 4 : 8,
                      vertical: 4,
                    ),
                    minimumSize: Size.zero,
                    tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  ),
                  child: Text(
                    'Forgot Password?',
                    style: TextStyle(
                      fontSize: fontSize,
                      color: Colors.blue.shade600,
                      fontWeight: FontWeight.w500,
                    ),
                    overflow: TextOverflow.ellipsis,
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

// Modern TextField Component
class ModernTextField extends StatefulWidget {
  final TextEditingController controller;
  final String labelText;
  final String? hintText;
  final TextInputType keyboardType;
  final String? Function(String?)? validator;
  final Duration delay;
  final bool isDark;
  final IconData? prefixIcon;

  const ModernTextField({
    super.key,
    required this.controller,
    required this.labelText,
    this.hintText,
    required this.keyboardType,
    this.validator,
    required this.delay,
    required this.isDark,
    this.prefixIcon,
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
            style: TextStyle(
              fontSize: 16,
              color: widget.isDark ? Colors.white : Colors.black87,
            ),
            decoration: InputDecoration(
              labelText: widget.labelText,
              hintText: widget.hintText,
              prefixIcon: widget.prefixIcon != null
                  ? Icon(
                      widget.prefixIcon,
                      color: _isFocused
                          ? Colors.blue
                          : (widget.isDark
                                ? Colors.grey.shade400
                                : Colors.grey.shade600),
                      size: 22,
                    )
                  : null,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(14),
                borderSide: BorderSide(
                  color: widget.isDark
                      ? Colors.grey.shade600
                      : Colors.grey.shade300,
                ),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(14),
                borderSide: BorderSide(
                  color: widget.isDark
                      ? Colors.grey.shade600
                      : Colors.grey.shade300,
                ),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(14),
                borderSide: const BorderSide(color: Colors.blue, width: 2),
              ),
              errorBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(14),
                borderSide: const BorderSide(color: Colors.red, width: 1),
              ),
              focusedErrorBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(14),
                borderSide: const BorderSide(color: Colors.red, width: 2),
              ),
              filled: true,
              fillColor: widget.isDark
                  ? Colors.grey.shade800.withOpacity(0.3)
                  : Colors.grey.shade50,
              labelStyle: TextStyle(
                fontSize: 15,
                color: _isFocused
                    ? Colors.blue
                    : (widget.isDark
                          ? Colors.grey.shade400
                          : Colors.grey.shade600),
              ),
              hintStyle: TextStyle(
                fontSize: 15,
                color: widget.isDark
                    ? Colors.grey.shade500
                    : Colors.grey.shade400,
              ),
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 16,
                vertical: 16,
              ),
            ),
            validator: widget.validator,
          ),
        ),
      ),
    );
  }
}

// Modern Password Field Component
class ModernPasswordField extends StatefulWidget {
  final TextEditingController controller;
  final String labelText;
  final String? hintText;
  final String? Function(String?)? validator;
  final Duration delay;
  final bool isDark;

  const ModernPasswordField({
    super.key,
    required this.controller,
    required this.labelText,
    this.hintText,
    this.validator,
    required this.delay,
    required this.isDark,
  });

  @override
  State<ModernPasswordField> createState() => _ModernPasswordFieldState();
}

class _ModernPasswordFieldState extends State<ModernPasswordField> {
  bool _isVisible = false;
  bool _obscureText = true;
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
            obscureText: _obscureText,
            style: TextStyle(
              fontSize: 16,
              color: widget.isDark ? Colors.white : Colors.black87,
            ),
            decoration: InputDecoration(
              labelText: widget.labelText,
              hintText: widget.hintText,
              prefixIcon: Icon(
                Icons.lock_outline,
                color: _isFocused
                    ? Colors.blue
                    : (widget.isDark
                          ? Colors.grey.shade400
                          : Colors.grey.shade600),
                size: 22,
              ),
              suffixIcon: IconButton(
                icon: AnimatedSwitcher(
                  duration: const Duration(milliseconds: 200),
                  child: Icon(
                    _obscureText
                        ? Icons.visibility_outlined
                        : Icons.visibility_off_outlined,
                    key: ValueKey(_obscureText),
                    color: widget.isDark
                        ? Colors.grey.shade400
                        : Colors.grey.shade600,
                    size: 22,
                  ),
                ),
                onPressed: () {
                  setState(() {
                    _obscureText = !_obscureText;
                  });
                },
              ),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(14),
                borderSide: BorderSide(
                  color: widget.isDark
                      ? Colors.grey.shade600
                      : Colors.grey.shade300,
                ),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(14),
                borderSide: BorderSide(
                  color: widget.isDark
                      ? Colors.grey.shade600
                      : Colors.grey.shade300,
                ),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(14),
                borderSide: const BorderSide(color: Colors.blue, width: 2),
              ),
              errorBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(14),
                borderSide: const BorderSide(color: Colors.red, width: 1),
              ),
              focusedErrorBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(14),
                borderSide: const BorderSide(color: Colors.red, width: 2),
              ),
              filled: true,
              fillColor: widget.isDark
                  ? Colors.grey.shade800.withOpacity(0.3)
                  : Colors.grey.shade50,
              labelStyle: TextStyle(
                fontSize: 15,
                color: _isFocused
                    ? Colors.blue
                    : (widget.isDark
                          ? Colors.grey.shade400
                          : Colors.grey.shade600),
              ),
              hintStyle: TextStyle(
                fontSize: 15,
                color: widget.isDark
                    ? Colors.grey.shade500
                    : Colors.grey.shade400,
              ),
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 16,
                vertical: 16,
              ),
            ),
            validator: widget.validator,
          ),
        ),
      ),
    );
  }
}

// Modern Button Component
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
          height: 52,
          child: widget.isPrimary
              ? ElevatedButton(
                  onPressed: widget.isLoading ? null : widget.onPressed,
                  style:
                      ElevatedButton.styleFrom(
                        elevation: 4,
                        shadowColor: Colors.blue.withOpacity(0.3),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                        backgroundColor: Colors.blue,
                        foregroundColor: Colors.white,
                      ).copyWith(
                        backgroundColor: WidgetStateProperty.resolveWith((
                          states,
                        ) {
                          if (states.contains(WidgetState.disabled)) {
                            return Colors.grey.shade400;
                          }
                          if (states.contains(WidgetState.pressed)) {
                            return Colors.blue.shade700;
                          }
                          return Colors.blue;
                        }),
                        elevation: WidgetStateProperty.resolveWith((states) {
                          if (states.contains(WidgetState.pressed)) {
                            return 2;
                          }
                          return 4;
                        }),
                      ),
                  child: widget.isLoading
                      ? const Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            SizedBox(
                              width: 18,
                              height: 18,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: Colors.white,
                              ),
                            ),
                            SizedBox(width: 12),
                            Text(
                              'Signing in...',
                              style: TextStyle(fontSize: 15),
                            ),
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
                  style:
                      OutlinedButton.styleFrom(
                        side: BorderSide(
                          color: widget.isDark
                              ? Colors.grey.shade600
                              : Colors.grey.shade300,
                          width: 1.5,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                        backgroundColor: Colors.transparent,
                      ).copyWith(
                        backgroundColor: WidgetStateProperty.resolveWith((
                          states,
                        ) {
                          if (states.contains(WidgetState.pressed)) {
                            return widget.isDark
                                ? Colors.grey.shade800.withOpacity(0.7)
                                : Colors.grey.shade100;
                          }
                          return Colors.transparent;
                        }),
                      ),
                  child: Text(
                    widget.text,
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w500,
                      color: widget.isDark
                          ? Colors.grey.shade300
                          : Colors.grey.shade700,
                      letterSpacing: 0.5,
                    ),
                  ),
                ),
        ),
      ),
    );
  }
}