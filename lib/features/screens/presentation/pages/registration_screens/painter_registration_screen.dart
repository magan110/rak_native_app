import 'package:rak_app/core/utils/uae_phone_utils.dart';
import 'dart:async';
import 'dart:math';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:rak_app/core/routes/route_names.dart';
import '../../../../../core/services/emirates_id_ocr_service.dart';
import '../../../../../core/services/bank_details_ocr_service.dart';
import '../../../../../core/services/hybrid_ocr_service.dart';
import '../../../../../core/services/painter_service.dart';
import '../../../../../core/services/autologin_service.dart';
import '../../../../../core/services/auth_service.dart';
import '../../../../../core/services/image_upload_service.dart';
import '../../../../../core/services/sms_uae_service.dart';
import '../../../../../core/services/kyc_status_service.dart';
import '../../../../../core/config/api_config.dart';
import '../../../../../core/models/painter_models.dart';
import '../../../../../core/models/kyc_status_models.dart';
import '../../../../../shared/widgets/custom_back_button.dart';
import '../../../../../shared/widgets/file_upload_widget.dart';
import '../../../../../shared/widgets/modern_dropdown.dart';
import '../../../../../shared/widgets/responsive_widgets.dart';
import '../../../../../shared/widgets/kyc_status_widget.dart';
import '../../../../../core/utils/snackbar_utils.dart';

class PainterRegistrationScreen extends StatefulWidget {
  final bool isEmployeeRegistration;

  const PainterRegistrationScreen({
    super.key,
    this.isEmployeeRegistration = false,
  });

  @override
  State<PainterRegistrationScreen> createState() =>
      _PainterRegistrationScreenState();
}

class _PainterRegistrationScreenState extends State<PainterRegistrationScreen>
    with TickerProviderStateMixin {
  late AnimationController _mainController;
  late AnimationController _fabController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;
  late Animation<double> _scaleAnimation;

  // Current step state (1 = Mobile/OTP, 2 = Emirates ID, 3 = Personal, 4 = Bank)
  int _currentStep = 1;

  // Form controllers
  final TextEditingController _firstNameController = TextEditingController();
  final TextEditingController _middleNameController = TextEditingController();
  final TextEditingController _lastNameController = TextEditingController();
  final TextEditingController _mobileController = TextEditingController();
  final TextEditingController _otpController = TextEditingController();
  final TextEditingController _addressController = TextEditingController();
  final TextEditingController _emiratesIdController = TextEditingController();
  final TextEditingController _nameOfHolderController = TextEditingController();
  final TextEditingController _dobController = TextEditingController();
  final TextEditingController _nationalityController = TextEditingController();
  final TextEditingController _companyDetailsController =
      TextEditingController();
  final TextEditingController _issueDateController = TextEditingController();
  final TextEditingController _expiryDateController = TextEditingController();
  final TextEditingController _occupationController = TextEditingController();
  final TextEditingController _accountHolderController =
      TextEditingController();
  final TextEditingController _ibanController = TextEditingController();
  final TextEditingController _bankNameController = TextEditingController();
  final TextEditingController _branchNameController = TextEditingController();
  final TextEditingController _bankAddressController = TextEditingController();

  // File paths for uploads
  String? _profilePhotoPath;
  String? _emiratesIdFrontFile;
  String? _emiratesIdBackFile;
  String? _bankDocumentFile;

  // OCR processing flags
  bool _isProcessingOcr = false;
  bool _isProcessingBankOcr = false;
  bool _isSubmitting = false;

  // Mobile validation state
  bool _isCheckingMobile = false;
  String? _mobileValidationError;

  // OTP state
  bool _showOtpField = false;
  bool _isOtpVerified = false;
  bool _isSendingOtp = false;
  Timer? _resendTimer;
  SharedPreferences? _prefs;

  // OTP constants
  static const _otpKeyCode = 'painter_otp_code';
  static const _otpKeyMobile = 'painter_otp_mobile';
  static const _otpKeyExpiry = 'painter_otp_expiry';
  static const _otpKeyCooldown = 'painter_otp_cooldown';

  // Bypass configuration — only active in debug mode
  static final String _bypassMobile = kDebugMode ? '527777777' : '';
  static final String _bypassOtp = kDebugMode ? '123456' : '';

  String? _selectedEmirate;
  String? _selectedEmirateCode;
  List<EmirateItem> _emiratesList = [];
  List<AreaItem> _areasList = [];
  List<SubAreaItem> _subAreasList = [];
  String? _selectedAreaCode;
  String? _selectedAreaName;
  String? _selectedSubAreaCode;
  String? _selectedSubAreaName;
  bool _hasSubArea = false;
  final TextEditingController _poBoxController = TextEditingController();

  // KYC Status state
  KycStatusResponse? _kycStatus;
  bool _isCheckingKycStatus = false;

  // Scroll controller for scrolling to top on step change
  final ScrollController _scrollController = ScrollController();

  // Hybrid OCR service (Gemini with ML Kit fallback)
  final HybridOcrService _hybridOcrService = HybridOcrService();

  // Legacy OCR services (kept for compatibility)
  final EmiratesIdOcrService _ocrService = EmiratesIdOcrService();
  final BankDetailsOcrService _bankOcrService = BankDetailsOcrService();

  @override
  void initState() {
    super.initState();

    // Skip mobile verification step for employee registration
    if (widget.isEmployeeRegistration) {
      _currentStep = 2; // Start from Emirates ID step
      _isOtpVerified = true; // Mark as verified to allow progression
    }

    _mainController = AnimationController(
      duration: const Duration(milliseconds: 1000),
      vsync: this,
    );
    _fabController = AnimationController(
      duration: const Duration(milliseconds: 400),
      vsync: this,
    );
    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _mainController,
        curve: const Interval(0.0, 0.5, curve: Curves.easeOut),
      ),
    );
    _slideAnimation =
        Tween<Offset>(begin: const Offset(0, 0.3), end: Offset.zero).animate(
          CurvedAnimation(
            parent: _mainController,
            curve: const Interval(0.2, 0.7, curve: Curves.easeOutCubic),
          ),
        );
    _scaleAnimation = Tween<double>(begin: 0.95, end: 1.0).animate(
      CurvedAnimation(
        parent: _mainController,
        curve: const Interval(0.3, 0.8, curve: Curves.easeOutCubic),
      ),
    );
    _mainController.forward();
    _fabController.forward();

    // Add listener for mobile number validation only if not employee registration
    if (!widget.isEmployeeRegistration) {
      _mobileController.addListener(_onMobileNumberChanged);
    }

    // Load emirates master list
    _loadEmirates();
  }

  @override
  void dispose() {
    _debounceTimer?.cancel();
    _resendTimer?.cancel();
    if (!widget.isEmployeeRegistration) {
      _mobileController.removeListener(_onMobileNumberChanged);
    }
    _scrollController.dispose();
    _mainController.dispose();
    _fabController.dispose();
    _firstNameController.dispose();
    _middleNameController.dispose();
    _lastNameController.dispose();
    _mobileController.dispose();
    _otpController.dispose();
    _addressController.dispose();
    _emiratesIdController.dispose();
    _nameOfHolderController.dispose();
    _dobController.dispose();
    _nationalityController.dispose();
    _companyDetailsController.dispose();
    _issueDateController.dispose();
    _expiryDateController.dispose();
    _occupationController.dispose();
    _accountHolderController.dispose();
    _ibanController.dispose();
    _bankNameController.dispose();
    _branchNameController.dispose();
    _bankAddressController.dispose();
    _poBoxController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      body: CustomScrollView(
        controller: _scrollController,
        slivers: [
          SliverAppBar(
            expandedHeight: 200.h,
            floating: false,
            pinned: true,
            elevation: 0,
            backgroundColor: const Color(0xFF1E3A8A),
            foregroundColor: Colors.white,
            systemOverlayStyle: const SystemUiOverlayStyle(
              statusBarColor: Colors.transparent,
              statusBarIconBrightness: Brightness.light,
            ),
            leading: Navigator.of(context).canPop()
                ? Padding(
                    padding: EdgeInsets.all(8.w),
                    child: CustomBackButton(
                      animated: false,
                      size: 36.sp,
                      color: Colors.white,
                    ),
                  )
                : null,
            flexibleSpace: FlexibleSpaceBar(
              title: Text(
                'Painter Registration',
                style: TextStyle(
                  fontSize: 16.sp,
                  fontWeight: FontWeight.w600,
                  color: Colors.white,
                  shadows: [
                    Shadow(
                      offset: Offset(0, 2.h),
                      blurRadius: 4.0,
                      color: Color(0x40000000),
                    ),
                  ],
                ),
              ),
              titlePadding: EdgeInsets.only(left: 72.w, bottom: 16.h),
              background: Stack(
                fit: StackFit.expand,
                children: [
                  Container(
                    decoration: const BoxDecoration(
                      gradient: LinearGradient(
                        colors: [Color(0xFF1E3A8A), Color(0xFF3B82F6)],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                    ),
                  ),
                  Positioned(
                    right: -50.w,
                    top: -50.h,
                    child: Container(
                      width: 200.w,
                      height: 200.h,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: Colors.white.withOpacity(0.1),
                      ),
                    ),
                  ),
                  Positioned(
                    right: 20.w,
                    top: 60.h,
                    child: Icon(
                      Icons.format_paint,
                      size: 100.sp,
                      color: Colors.white.withOpacity(0.2),
                    ),
                  ),
                ],
              ),
            ),
            actions: [
              IconButton(
                icon: const Icon(
                  Icons.help_outline_rounded,
                  color: Colors.white,
                ),
                onPressed: () => _showHelpDialog(),
              ),
            ],
          ),
          SliverToBoxAdapter(
            child: FadeTransition(
              opacity: _fadeAnimation,
              child: SlideTransition(
                position: _slideAnimation,
                child: Padding(
                  padding: EdgeInsets.symmetric(
                    horizontal: 16.w,
                    vertical: 16.h,
                  ),
                  child: ScaleTransition(
                    scale: _scaleAnimation,
                    child: Column(
                      children: [
                        _buildProgressIndicator(),
                        SizedBox(height: 24.h),
                        _buildDesktopLayout(),
                        SizedBox(height: 24.h),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildProgressIndicator() {
    return Container(
      padding: EdgeInsets.all(16.w),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.7),
        borderRadius: BorderRadius.circular(12.r),
        border: Border.all(color: Colors.grey.shade200, width: 1),
      ),
      child: Column(
        children: [
          Row(
            children: [
              _buildProgressStep(1, 'Mobile', _currentStep >= 1),
              _buildProgressLine(_currentStep >= 2),
              _buildProgressStep(2, 'Emirates ID', _currentStep >= 2),
              _buildProgressLine(_currentStep >= 3),
              _buildProgressStep(3, 'Personal', _currentStep >= 3),
              _buildProgressLine(_currentStep >= 4),
              _buildProgressStep(4, 'Bank', _currentStep >= 4),
            ],
          ),
          SizedBox(height: 12.h),
          Text(
            'Step $_currentStep of 4: ${_getStepTitle()}',
            style: TextStyle(
              color: Colors.grey.shade600,
              fontSize: 14.sp,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  String _getStepTitle() {
    switch (_currentStep) {
      case 1:
        return 'Mobile Verification';
      case 2:
        return 'Emirates ID Verification';
      case 3:
        return 'Personal Details';
      case 4:
        return 'Bank Details';
      default:
        return '';
    }
  }

  Widget _buildProgressStep(int step, String title, bool isActive) {
    return Column(
      children: [
        Container(
          width: 40.w,
          height: 40.h,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: isActive ? const Color(0xFF1E3A8A) : Colors.grey.shade300,
            boxShadow: isActive
                ? [
                    BoxShadow(
                      color: const Color(0xFF1E3A8A).withOpacity(0.3),
                      blurRadius: 8.r,
                      offset: Offset(0, 2.h),
                    ),
                  ]
                : null,
          ),
          child: Center(
            child: Text(
              '$step',
              style: TextStyle(
                color: isActive ? Colors.white : Colors.grey.shade600,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ),
        SizedBox(height: 8.h),
        Text(
          title,
          style: TextStyle(
            color: isActive ? const Color(0xFF1E3A8A) : Colors.grey.shade600,
            fontSize: 12.sp,
            fontWeight: isActive ? FontWeight.w600 : FontWeight.normal,
          ),
        ),
      ],
    );
  }

  Widget _buildProgressLine(bool isActive) {
    return Expanded(
      child: Container(
        height: 2.h,
        margin: EdgeInsets.symmetric(horizontal: 8.w),
        decoration: BoxDecoration(
          color: isActive ? const Color(0xFF1E3A8A) : Colors.grey.shade300,
          borderRadius: BorderRadius.circular(1.r),
        ),
      ),
    );
  }

  Widget _buildDesktopLayout() {
    // Show only the current step's section
    Widget currentSection;

    switch (_currentStep) {
      case 1:
        currentSection = _buildMobileVerificationSection();
        break;
      case 2:
        currentSection = _buildEmiratesIdSection();
        break;
      case 3:
        currentSection = _buildPersonalDetailsSection();
        break;
      case 4:
        currentSection = _buildBankDetailsSection();
        break;
      default:
        currentSection = _buildMobileVerificationSection();
    }

    return Column(
      children: [
        currentSection,
        SizedBox(height: 24.h),
        _buildNavigationButtons(),
      ],
    );
  }

  /// Build navigation buttons (Previous/Next/Submit)
  Widget _buildNavigationButtons() {
    return Row(
      children: [
        // Previous button (hidden on first step)
        if (_currentStep > 1)
          Expanded(
            child: OutlinedButton(
              onPressed: () {
                setState(() {
                  _currentStep--;
                });
                // Scroll to top
                _scrollController.animateTo(
                  0,
                  duration: const Duration(milliseconds: 300),
                  curve: Curves.easeOut,
                );
              },
              style: OutlinedButton.styleFrom(
                foregroundColor: const Color(0xFF1E3A8A),
                side: const BorderSide(color: Color(0xFF1E3A8A), width: 2),
                padding: EdgeInsets.symmetric(vertical: 16.h),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12.r),
                ),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.arrow_back_rounded),
                  SizedBox(width: 8.w),
                  Text(
                    'Previous',
                    style: TextStyle(
                      fontSize: 16.sp,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
          ),

        if (_currentStep > 1) SizedBox(width: 16.w),

        // Next/Submit button
        Expanded(
          child: ElevatedButton(
            onPressed: () {
              // Skip OTP verification for employee registration
              if (_currentStep == 1 &&
                  !_isOtpVerified &&
                  !widget.isEmployeeRegistration) {
                // Cannot proceed without OTP verification
                AppSnackBar.showWarning(
                  context,
                  'Please verify your mobile number with OTP first',
                );
                return;
              }

              // Validate emirates/area/subarea when moving from step 3 to step 4
              if (_currentStep == 3) {
                if (_selectedEmirateCode == null ||
                    _selectedEmirateCode!.isEmpty) {
                  AppSnackBar.showError(
                    context,
                    'Please select an emirate to continue',
                  );
                  return;
                }

                if (_selectedAreaCode == null || _selectedAreaCode!.isEmpty) {
                  AppSnackBar.showError(
                    context,
                    'Please select an area to continue',
                  );
                  return;
                }

                if (_hasSubArea == true &&
                    (_selectedSubAreaCode == null ||
                        _selectedSubAreaCode!.isEmpty)) {
                  AppSnackBar.showError(
                    context,
                    'Please select a sub-area to continue',
                  );
                  return;
                }
              }

              if (_currentStep < 4) {
                setState(() {
                  _currentStep++;
                });
                // Scroll to top
                _scrollController.animateTo(
                  0,
                  duration: const Duration(milliseconds: 300),
                  curve: Curves.easeOut,
                );
              } else {
                // Submit form
                _handleSubmit();
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF1E3A8A),
              foregroundColor: Colors.white,
              elevation: 0,
              padding: EdgeInsets.symmetric(vertical: 16.h),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12.r),
              ),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  _currentStep < 4 ? 'Next' : 'Submit Registration',
                  style: TextStyle(
                    fontSize: 16.sp,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                SizedBox(width: 8.w),
                Icon(
                  _currentStep < 4
                      ? Icons.arrow_forward_rounded
                      : Icons.check_circle_rounded,
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  void _handleSubmit() {
    // New implementation: validate, build request, call API and show feedback
    if (_isSubmitting) return;

    // Validate emirates (compulsory)
    if (_selectedEmirate == null || _selectedEmirate!.isEmpty) {
      AppSnackBar.showError(context, 'Please select an emirate');
      return;
    }

    // Basic validations
    final firstNameErr = PainterService.validateName(
      _firstNameController.text,
      'First name',
    );
    if (firstNameErr != null) {
      AppSnackBar.showError(context, firstNameErr);
      return;
    }

    final lastNameErr = PainterService.validateName(
      _lastNameController.text,
      'Last name',
    );
    if (lastNameErr != null) {
      AppSnackBar.showError(context, lastNameErr);
      return;
    }

    final mobileErr = PainterService.validateMobileNumber(
      _mobileController.text,
    );
    if (mobileErr != null) {
      AppSnackBar.showError(context, mobileErr);
      return;
    }

    // Check if there's a real-time validation error
    if (_mobileValidationError != null) {
      AppSnackBar.showError(context, _mobileValidationError!);
      return;
    }

    final emiratesErr = PainterService.validateEmiratesId(
      _emiratesIdController.text,
    );
    if (emiratesErr != null) {
      AppSnackBar.showError(context, emiratesErr);
      return;
    }

    // Check for duplicate mobile number before proceeding
    _checkDuplicateMobileAndProceed();
  }

  void _checkDuplicateMobileAndProceed() async {
    if (_isSubmitting) return;

    setState(() => _isSubmitting = true);
    // Show checking message using centralized AppSnackBar
    final _loadingController = AppSnackBar.showLoading(
      context,
      'Checking mobile number...',
    );

    try {
      // Check for duplicate mobile number
      final duplicateCheck = await PainterService.checkMobileDuplicate(
        _mobileController.text,
      );

      AppSnackBar.hide(context);

      if (!duplicateCheck.success) {
        // API call failed, show warning but allow to proceed
        AppSnackBar.showWarning(context, duplicateCheck.message);
        // Continue with registration despite check failure
        _proceedWithRegistration();
        return;
      }

      if (duplicateCheck.exists) {
        // Mobile number already exists, prevent registration
        AppSnackBar.showError(
          context,
          duplicateCheck.message.isNotEmpty
              ? duplicateCheck.message
              : 'This mobile number is already registered. Please use a different number.',
        );
        setState(() => _isSubmitting = false);
        return;
      }

      // Mobile number is available, proceed with registration
      _proceedWithRegistration();
    } catch (e) {
      AppSnackBar.hide(context);
      AppSnackBar.showWarning(
        context,
        'Error checking mobile number: ${e.toString()}',
      );
      // Continue with registration despite check failure
      _proceedWithRegistration();
    }
  }

  void _proceedWithRegistration() async {
    final messenger = ScaffoldMessenger.of(context);

    // Calculate total points for new painter registration (100 points)
    final totalPoints = _calculateTotalPoints();

    // Get current logged-in user's ID for loginId field
    final currentUser = AuthManager.currentUser;
    final loginId = currentUser?.userID ?? currentUser?.emplName ?? 'SYSTEM';

    // Build the registration request from form fields (backend contract)
    final req = PainterRegistrationRequest(
      loginId: loginId,
      firstName: _firstNameController.text.trim(),
      middleName: _middleNameController.text.trim(),
      lastName: _lastNameController.text.trim(),
      emirateCode: _selectedEmirateCode,
      emirates: _selectedEmirate,
      areaCode: _selectedAreaCode,
      areaName: _selectedAreaName,
      subAreaCode: _selectedSubAreaCode,
      subAreaName: _selectedSubAreaName,
      poBox: _poBoxController.text.trim(),
      address: _addressController.text.trim(),
      mobileNumber: PainterService.formatMobileNumber(_mobileController.text),
      dateOfBirth: _dobController.text.trim(),
      bankName: _bankNameController.text.trim(),
      branchName: _branchNameController.text.trim(),
      accountHolderName: _accountHolderController.text.trim(),
      reference: null,
      ibanNumber: PainterService.formatIban(_ibanController.text),
      emiratesIdNumber: _emiratesIdController.text.trim(),
      idName: _nameOfHolderController.text.trim(),
      nationality: _nationalityController.text.trim(),
      companyDetails: _companyDetailsController.text.trim(),
      issueDate: _issueDateController.text.trim(),
      expiryDate: _expiryDateController.text.trim(),
      occupation: _occupationController.text.trim(),
      bankAddress: _bankAddressController.text.trim(),
    );

    // Show image upload progress
    final loading = SnackBar(
      content: Row(
        children: [
          const SizedBox(width: 4),
          const CircularProgressIndicator(),
          const SizedBox(width: 12),
          const Expanded(child: Text('Uploading images...')),
        ],
      ),
      behavior: SnackBarBehavior.floating,
    );
    messenger.showSnackBar(loading);

    try {
      // 1. Upload files first
      final uploadSuccess = await _uploadFilesToServer();

      if (!uploadSuccess && mounted) {
        messenger.hideCurrentSnackBar();
        setState(() => _isSubmitting = false);
        return; // Stop registration if file upload failed
      }

      // Show registration progress
      messenger.hideCurrentSnackBar();
      messenger.showSnackBar(
        const SnackBar(
          content: Row(
            children: [
              SizedBox(width: 4),
              CircularProgressIndicator(),
              SizedBox(width: 12),
              Expanded(child: Text('Registering painter...')),
            ],
          ),
          behavior: SnackBarBehavior.floating,
        ),
      );

      // 2. Register painter in DB
      final resp = await PainterService.registerPainter(req);
      messenger.hideCurrentSnackBar();

      if (resp.success) {
        messenger.showSnackBar(
          SnackBar(
            content: Row(
              children: [
                const Icon(Icons.check_circle, color: Colors.white),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    resp.message.isNotEmpty
                        ? resp.message
                        : 'Registration successful',
                  ),
                ),
              ],
            ),
            backgroundColor: const Color(0xFF10B981),
            behavior: SnackBarBehavior.floating,
          ),
        );

        // Removed: Upload files to server after successful registration
        // (This is now done before registration)

        final registeredName =
            ('${_firstNameController.text} ${_lastNameController.text}').trim();

        // For employee registration, show dialog instead of navigating
        if (widget.isEmployeeRegistration) {
          await Future.delayed(const Duration(milliseconds: 500));
          if (mounted) {
            _showRegistrationCompletedDialog(registeredName);
          }
        } else {
          // Save autologin data for future automatic login (only for self-registration)
          final userId = _mobileController.text
              .trim(); // Using mobile as userId

          await AutoLoginService.saveAutoLoginAfterRegistration(
            userId: userId,
            userType: 'painter',
            userName: registeredName,
            emirates: _selectedEmirate ?? '',
            influencerCode: resp.influencerCode,
            additionalData: {
              'mobileNumber': PainterService.formatMobileNumber(
                _mobileController.text,
              ),
              'emiratesId': _emiratesIdController.text.trim(),
              'nationality': _nationalityController.text.trim(),
              'occupation': _occupationController.text.trim(),
            },
          );

          // Navigate to painter home after short delay so user sees the success snackbar
          await Future.delayed(const Duration(seconds: 1));
          if (mounted) {
            // Pass isNewRegistration so home screen can show congratulations dialog
            context.go(
              RouteNames.painterHome,
              extra: {
                'isNewRegistration': true,
                'userRole': 'painter',
                'registeredName': registeredName,
                'emirates': _selectedEmirate ?? '',
                'influencerCode': resp.influencerCode,
              },
            );
          }
        }
      } else {
        messenger.showSnackBar(
          SnackBar(
            content: Text(
              resp.message.isNotEmpty ? resp.message : 'Registration failed',
            ),
            backgroundColor: Colors.redAccent,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } catch (e) {
      messenger.hideCurrentSnackBar();
      messenger.showSnackBar(
        SnackBar(
          content: Text('Registration failed: ${e.toString()}'),
          backgroundColor: Colors.redAccent,
          behavior: SnackBarBehavior.floating,
        ),
      );
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  void _showRegistrationCompletedDialog(String painterName) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20.r),
          ),
          contentPadding: EdgeInsets.zero,
          content: Container(
            padding: EdgeInsets.all(24.w),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(20.r),
              gradient: const LinearGradient(
                colors: [Color(0xFFF8FAFC), Colors.white],
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
              ),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  padding: EdgeInsets.all(16.w),
                  decoration: BoxDecoration(
                    color: const Color(0xFF10B981).withOpacity(0.1),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    Icons.check_circle_rounded,
                    color: const Color(0xFF10B981),
                    size: 64.sp,
                  ),
                ),
                SizedBox(height: 20.h),
                Text(
                  'Registration Completed!',
                  style: TextStyle(
                    fontSize: 22.sp,
                    fontWeight: FontWeight.bold,
                    color: const Color(0xFF1F2937),
                  ),
                  textAlign: TextAlign.center,
                ),
                SizedBox(height: 12.h),
                Text(
                  'Painter "$painterName" has been successfully registered.',
                  style: TextStyle(
                    fontSize: 15.sp,
                    color: Colors.grey[600],
                    height: 1.4,
                  ),
                  textAlign: TextAlign.center,
                ),
                SizedBox(height: 24.h),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () {
                      Navigator.of(context).pop(); // Close dialog
                      context.pop(); // Go back to home screen
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF1E3A8A),
                      foregroundColor: Colors.white,
                      elevation: 0,
                      padding: EdgeInsets.symmetric(vertical: 14.h),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12.r),
                      ),
                    ),
                    child: Text(
                      'Done',
                      style: TextStyle(
                        fontSize: 16.sp,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  // ========= OTP Helper Methods =========
  Future<void> _initPrefs() async {
    _prefs ??= await SharedPreferences.getInstance();
  }

  String _genOtp6() {
    final rnd = Random.secure();
    return (rnd.nextInt(900000) + 100000).toString();
  }

  String _normalizeForPrefs(String raw) {
    var d = raw.replaceAll(RegExp(r'\D'), '');
    if (d.startsWith('971')) return d;
    return '971$d';
  }

  List<String> _getAllMobileFormats(String rawMobile) {
    final cleaned = rawMobile.replaceAll(RegExp(r'[^0-9]'), '');
    final formats = <String>[];

    if (cleaned.isNotEmpty) {
      formats.add(cleaned);
    }

    if (cleaned.length == 9) {
      formats.add('971$cleaned');
    }

    if (cleaned.startsWith('971') && cleaned.length == 12) {
      formats.add(cleaned.substring(3));
    }

    if (cleaned.length > 9) {
      final last9 = cleaned.substring(cleaned.length - 9);
      formats.add(last9);
      formats.add('971$last9');
    }

    final uniqueFormats = <String>[];
    for (final format in formats) {
      if (!uniqueFormats.contains(format)) {
        uniqueFormats.add(format);
      }
    }

    return uniqueFormats;
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

  Future<void> _checkKycStatus() async {
    if (_isCheckingKycStatus) return;

    setState(() => _isCheckingKycStatus = true);

    try {
      final status = await KycStatusService.getKycStatusByMobile(
        _mobileController.text.trim(),
      );

      if (mounted) {
        setState(() {
          _kycStatus = status;
          _isCheckingKycStatus = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isCheckingKycStatus = false);
      }
    }
  }

  void _onMobileNumberChanged() {
    final mobile = _mobileController.text;

    // Clear previous error when user starts typing
    if (_mobileValidationError != null) {
      setState(() {
        _mobileValidationError = null;
      });
    }

    // Reset OTP verification if mobile changes
    if (_isOtpVerified) {
      setState(() {
        _isOtpVerified = false;
        _showOtpField = false;
        _otpController.clear();
        _kycStatus = null; // Clear KYC status when mobile changes
      });
    }

    // Only check if mobile number is valid format
    final mobileErr = PainterService.validateMobileNumber(mobile);
    if (mobileErr != null) {
      return; // Don't check duplicate if format is invalid
    }

    // Debounce the API call
    _debounceTimer?.cancel();
    _debounceTimer = Timer(const Duration(milliseconds: 800), () {
      _checkMobileDuplicateRealTime(mobile);
    });
  }

  Timer? _debounceTimer;

  /// Calculate total points for new painter registration
  /// All new painters receive 100 points upon successful registration
  int _calculateTotalPoints() {
    return 100;
  }

  Future<void> _loadEmirates() async {
    try {
      final items = await PainterService.getEmiratesList();
      setState(() {
        _emiratesList = items;
      });
    } catch (e) {
      // Non-fatal - show warning
      AppSnackBar.showWarning(
        context,
        'Failed to load emirates: ${e.toString()}',
      );
    }
  }

  Future<void> _sendOtp() async {
    if (_isSendingOtp) return;

    final mobileRaw = _mobileController.text.trim();
    final mobileErr = PainterService.validateMobileNumber(mobileRaw);
    if (mobileErr != null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(mobileErr), backgroundColor: Colors.red),
      );
      return;
    }

    // Check if this is the bypass number
    final cleanedMobile = mobileRaw.replaceAll(RegExp(r'\D'), '');
    final isBypassNumber =
        cleanedMobile == _bypassMobile ||
        cleanedMobile == '971$_bypassMobile' ||
        cleanedMobile.endsWith(_bypassMobile);

    // Check cooldown
    final leftMs = await _getResendCooldownLeft();
    if (leftMs != null && leftMs > 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Please wait ${(leftMs / 1000).ceil()} seconds before resending',
          ),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    setState(() => _isSendingOtp = true);

    try {
      // If bypass number, skip SMS and use fixed OTP
      if (isBypassNumber) {
        debugPrint('🔓 Bypass number detected (Painter): $mobileRaw');
        await _saveOtpLocally(
          mobile: _normalizeForPrefs(mobileRaw),
          otp: _bypassOtp,
        );
        await _setResendCooldown();
        setState(() {
          _showOtpField = true;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('OTP: $_bypassOtp (Bypass mode)'),
            backgroundColor: Colors.green,
          ),
        );
        setState(() => _isSendingOtp = false);
        return;
      }

      final otp = _genOtp6();
      final formats = _getAllMobileFormats(mobileRaw);
      bool sent = false;
      String? lastError;

      // Try sending SMS directly without checking registration status
      for (final format in formats) {
        final result = await SmsUaeService.sendSms(
          mobileNo: format,
          message: ApiConfig.otpMessage(otp),
          priority: 'High',
          countryCode: 'ALL',
        );

        if (result.success) {
          sent = true;
          await _saveOtpLocally(
            mobile: _normalizeForPrefs(mobileRaw),
            otp: otp,
          );
          await _setResendCooldown();
          setState(() {
            _showOtpField = true;
          });
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('OTP sent successfully'),
              backgroundColor: Colors.green,
            ),
          );
          break;
        } else {
          lastError = result.message ?? 'Failed to send OTP';
        }
      }

      if (!sent && lastError != null) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(lastError), backgroundColor: Colors.red),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error sending OTP: ${e.toString()}'),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      setState(() => _isSendingOtp = false);
    }
  }

  Future<void> _verifyOtp() async {
    final enteredOtp = _otpController.text.trim();
    if (enteredOtp.length != 6) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please enter a valid 6-digit OTP'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    final stored = await _loadOtp();
    if (stored == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('No OTP found. Please request a new OTP.'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    final now = DateTime.now().millisecondsSinceEpoch;
    final targetMobile = stored['mobile'] as String;
    final savedOtp = stored['otp'] as String;
    final expiry = stored['expiry'] as int;

    if (_normalizeForPrefs(_mobileController.text) != targetMobile) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Mobile number mismatch. Request OTP again.'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    if (now > expiry) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('OTP expired. Please request a new OTP.'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    if (enteredOtp != savedOtp) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Invalid OTP. Please try again.'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    // OTP verified successfully
    await _clearOtp();
    setState(() {
      _isOtpVerified = true;
    });
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Mobile number verified successfully!'),
        backgroundColor: Colors.green,
      ),
    );

    // Check KYC status after successful OTP verification
    _checkKycStatus();
  }

  void _checkMobileDuplicateRealTime(String mobile) async {
    if (!mounted || mobile.isEmpty) return;

    setState(() {
      _isCheckingMobile = true;
      _mobileValidationError = null;
    });

    try {
      final duplicateCheck = await PainterService.checkMobileDuplicate(mobile);

      if (mounted) {
        setState(() {
          _isCheckingMobile = false;
          if (duplicateCheck.success && duplicateCheck.exists) {
            _mobileValidationError = duplicateCheck.message.isNotEmpty
                ? duplicateCheck.message
                : 'This mobile number is already registered';
          }
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isCheckingMobile = false;
          // Don't show error for real-time check failures
        });
      }
    }
  }

  Widget _buildMobileNumberField() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(bottom: 8.0),
          child: Text(
            'Mobile Number *',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: Colors.black87,
            ),
          ),
        ),
        TextFormField(
          controller: _mobileController,
          keyboardType: TextInputType.phone,
          inputFormatters: UaePhoneUtils.inputFormatters(),
          decoration: InputDecoration(
            hintText: UaePhoneUtils.localHint,
            hintStyle: TextStyle(color: Colors.grey[400], fontSize: 14),
            prefixIcon: Icon(
              Icons.phone_outlined,
              color: Colors.grey[600],
              size: 20,
            ),
            prefixText: UaePhoneUtils.countryPrefix,
            suffixIcon: _isCheckingMobile
                ? Padding(
                    padding: const EdgeInsets.all(12.0),
                    child: SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        valueColor: AlwaysStoppedAnimation<Color>(Colors.blue),
                      ),
                    ),
                  )
                : _mobileValidationError != null
                ? Icon(Icons.error_outline, color: Colors.red, size: 20)
                : null,
            filled: true,
            fillColor: Colors.grey[50],
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: Colors.grey[300]!),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(
                color: _mobileValidationError != null
                    ? Colors.red
                    : Colors.grey[300]!,
              ),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(
                color: _mobileValidationError != null
                    ? Colors.red
                    : Colors.blue,
                width: 2,
              ),
            ),
            errorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: Colors.red),
            ),
            focusedErrorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: Colors.red, width: 2),
            ),
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 8,
              vertical: 16,
            ),
          ),
          style: const TextStyle(fontSize: 14, color: Colors.black87),
        ),
        if (_mobileValidationError != null) ...[
          const SizedBox(height: 6),
          Row(
            children: [
              Icon(Icons.error_outline, color: Colors.red, size: 16),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  _mobileValidationError!,
                  style: const TextStyle(
                    color: Colors.red,
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ],
          ),
        ],
      ],
    );
  }

  Widget _buildPersonalDetailsSection() {
    return ResponsiveSection(
      title: 'Personal Details',
      icon: Icons.person_rounded,
      subtitle: 'Tell us about yourself',
      children: [
        ResponsiveRow(
          children: [
            ResponsiveTextField(
              label: 'First Name',
              icon: Icons.person_outline_rounded,
              controller: _firstNameController,
            ),
            ResponsiveTextField(
              label: 'Middle Name',
              icon: Icons.person_outline_rounded,
              controller: _middleNameController,
              isRequired: false,
            ),
          ],
        ),
        const ResponsiveSpacing(mobile: 20),
        ResponsiveRow(
          children: [
            ResponsiveTextField(
              label: 'Last Name',
              icon: Icons.person_outline_rounded,
              controller: _lastNameController,
            ),
            _buildMobileNumberField(),
          ],
        ),
        const ResponsiveSpacing(mobile: 20),
        ResponsiveTextField(
          label: 'Address',
          icon: Icons.home_outlined,
          controller: _addressController,
        ),
        const ResponsiveSpacing(mobile: 20),
        ModernDropdown(
          label: 'Emirates',
          icon: Icons.public_outlined,
          items: _emiratesList.map((e) => e.name).toList(),
          value: _selectedEmirate,
          isRequired: true,
          onChanged: (String? value) async {
            setState(() {
              _selectedEmirate = value;
              _selectedEmirateCode = _emiratesList
                  .firstWhere(
                    (e) => e.name == value,
                    orElse: () => EmirateItem(id: '', name: ''),
                  )
                  .id;

              // clear area/subarea selections
              _areasList = [];
              _subAreasList = [];
              _selectedAreaCode = null;
              _selectedAreaName = null;
              _selectedSubAreaCode = null;
              _selectedSubAreaName = null;
              _hasSubArea = false;
              _poBoxController.text = '';
            });

            if (_selectedEmirateCode != null &&
                _selectedEmirateCode!.isNotEmpty) {
              try {
                final areas = await PainterService.getAreasListByEmirate(
                  _selectedEmirateCode!,
                );
                setState(() {
                  _areasList = areas;
                });
              } catch (e) {
                AppSnackBar.showWarning(
                  context,
                  'Failed loading areas: ${e.toString()}',
                );
              }
            }
          },
        ),
        const ResponsiveSpacing(mobile: 12),
        // Area dropdown
        ModernDropdown(
          label: 'Area',
          icon: Icons.location_city_outlined,
          items: _areasList.map((a) => a.name).toList(),
          value: _selectedAreaName,
          isRequired: true,
          onChanged: (String? value) async {
            setState(() {
              _selectedAreaName = value;
              final found = _areasList.firstWhere(
                (a) => a.name == value,
                orElse: () => AreaItem(code: '', name: '', poBox: ''),
              );
              _selectedAreaCode = found.code;
              _selectedSubAreaCode = null;
              _selectedSubAreaName = null;
              _subAreasList = [];
              _hasSubArea = false;
              _poBoxController.text = '';
            });

            if (_selectedAreaCode != null && _selectedAreaCode!.isNotEmpty) {
              try {
                final res = await PainterService.getSubAreasListByArea(
                  _selectedAreaCode!,
                );
                setState(() {
                  _hasSubArea = res['hasSubArea'] == true;
                  _subAreasList = (res['data'] as List<SubAreaItem>?) ?? [];
                  if (!_hasSubArea) {
                    // auto-fill poBox from area
                    final area = _areasList.firstWhere(
                      (a) => a.code == _selectedAreaCode,
                      orElse: () => AreaItem(code: '', name: '', poBox: ''),
                    );
                    _poBoxController.text = area.poBox;
                  }
                });
              } catch (e) {
                AppSnackBar.showWarning(
                  context,
                  'Failed loading sub-areas: ${e.toString()}',
                );
              }
            }
          },
        ),
        const ResponsiveSpacing(mobile: 12),
        if (_hasSubArea) ...[
          ModernDropdown(
            label: 'Sub-area',
            icon: Icons.place_outlined,
            items: _subAreasList.map((s) => s.name).toList(),
            value: _selectedSubAreaName,
            isRequired: true,
            onChanged: (String? value) {
              setState(() {
                _selectedSubAreaName = value;
                final found = _subAreasList.firstWhere(
                  (s) => s.name == value,
                  orElse: () => SubAreaItem(code: '', name: '', poBox: ''),
                );
                _selectedSubAreaCode = found.code;
                _poBoxController.text = found.poBox;
              });
            },
          ),
          const ResponsiveSpacing(mobile: 12),
        ],
        ResponsiveTextField(
          label: 'Place Code (PoBox)',
          icon: Icons.local_post_office_outlined,
          controller: _poBoxController,
          isRequired: true,
        ),
        const ResponsiveSpacing(mobile: 20),
        _buildPhotoUploadSection(),
      ],
    );
  }

  Widget _buildPhotoUploadSection() {
    return Container(
      padding: EdgeInsets.all(20.w),
      decoration: BoxDecoration(
        color: const Color(0xFFF0F9FF),
        borderRadius: BorderRadius.circular(12.r),
        border: Border.all(color: const Color(0xFF3B82F6).withOpacity(0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.camera_alt_outlined,
                color: const Color(0xFF3B82F6),
                size: 24.sp,
              ),
              SizedBox(width: 12.w),
              Text(
                'Profile Photo',
                style: TextStyle(
                  fontSize: 16.sp,
                  fontWeight: FontWeight.w600,
                  color: const Color(0xFF1E3A8A),
                ),
              ),
            ],
          ),
          SizedBox(height: 12.h),
          FileUploadWidget(
            label: '',
            icon: Icons.camera_alt_outlined,
            allowedExtensions: const ['jpg', 'jpeg', 'png'],
            enableServerUpload: false,
            onFileSelected: (file) {
              print('Profile photo selected: $file');
              setState(() {
                _profilePhotoPath = file;
              });
            },
          ),
          SizedBox(height: 12.h),
          Text(
            'Upload a clear photo of yourself (JPG, PNG - Max 10MB)',
            style: TextStyle(fontSize: 12.sp, color: Colors.grey.shade600),
          ),
        ],
      ),
    );
  }

  Widget _buildEmiratesIdSection() {
    return ResponsiveSection(
      title: 'Emirates ID Verification',
      icon: Icons.badge_outlined,
      subtitle: 'Upload both sides of your Emirates ID',
      children: [
        _buildIdUploadStatus(),
        Padding(
          padding: const EdgeInsets.only(top: 12.0),
          child: Row(
            children: [
              ElevatedButton.icon(
                onPressed: () async {
                  if (_emiratesIdFrontFile != null &&
                      _emiratesIdBackFile != null) {
                    await _processEmiratesIdOcrWithRetry();
                  } else {
                    if (mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text(
                            'Please upload both front and back images first',
                          ),
                        ),
                      );
                    }
                  }
                },
                icon: const Icon(Icons.refresh_rounded),
                label: const Text('Re-scan ID'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF1E3A8A),
                ),
              ),
              const SizedBox(width: 12),
              if (_isProcessingOcr) ...[
                const CircularProgressIndicator(),
                const SizedBox(width: 12),
                const Text('Processing ID images...'),
              ],
            ],
          ),
        ),
        const ResponsiveSpacing(mobile: 24),
        ResponsiveRow(
          children: [
            _buildIdUploadCard(
              'Front Side',
              Icons.credit_card,
              'Upload the front of your Emirates ID',
              isFront: true,
            ),
            _buildIdUploadCard(
              'Back Side',
              Icons.credit_card,
              'Upload the back of your Emirates ID',
              isFront: false,
            ),
          ],
        ),
        const ResponsiveSpacing(mobile: 24),
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: const Color(0xFF1E3A8A).withOpacity(0.05),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: const Color(0xFF1E3A8A).withOpacity(0.1)),
          ),
          child: Row(
            children: [
              Icon(
                Icons.info_outline_rounded,
                color: const Color(0xFF1E3A8A),
                size: 20,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  'Make sure all details are clearly visible and not blurry. You can upload images (JPG, PNG) or PDF files.',
                  style: TextStyle(
                    fontSize: 13,
                    color: const Color(0xFF1E3A8A),
                  ),
                ),
              ),
            ],
          ),
        ),
        const ResponsiveSpacing(mobile: 24),
        _buildEmiratesIdForm(),
      ],
    );
  }

  Widget _buildIdUploadStatus() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            const Color(0xFF1E3A8A).withOpacity(0.1),
            const Color(0xFF3B82F6).withOpacity(0.1),
          ],
        ),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFF1E3A8A).withOpacity(0.2)),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: const Color(0xFF1E3A8A),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.cloud_upload_outlined,
              color: Colors.white,
              size: 24,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'ID Verification Status',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: const Color(0xFF1E3A8A),
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Upload both sides to begin verification',
                  style: TextStyle(fontSize: 13, color: Colors.grey.shade700),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildIdUploadCard(
    String title,
    IconData icon,
    String subtitle, {
    required bool isFront,
  }) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: Colors.grey.shade300,
          width: 2,
          style: BorderStyle.solid,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.03),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          Icon(icon, size: 48, color: Colors.grey.shade400),
          const SizedBox(height: 12),
          Text(
            title,
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: Colors.grey.shade700,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            subtitle,
            style: TextStyle(fontSize: 12, color: Colors.grey.shade500),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 16),
          FileUploadWidget(
            label: '',
            icon: Icons.cloud_upload_outlined,
            allowedExtensions: const [
              'jpg',
              'jpeg',
              'png',
              'pdf',
            ], // Added 'pdf'
            enableServerUpload: false,
            onFileSelected: (file) async {
              // Store selected file path for later verification
              if (file != null) {
                print(
                  'Emirates ID ${isFront ? 'Front' : 'Back'} selected: $file',
                );
                setState(() {
                  if (isFront) {
                    _emiratesIdFrontFile = file;
                  } else {
                    _emiratesIdBackFile = file;
                  }
                });
                final isPdf = file.toLowerCase().endsWith('.pdf');
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('${isPdf ? 'PDF' : 'Image'} uploaded'),
                  ),
                );
                // If both sides uploaded, run OCR to autofill fields
                if (_emiratesIdFrontFile != null &&
                    _emiratesIdBackFile != null) {
                  await _processEmiratesIdOcrWithRetry();
                }
              }
            },
          ),
          SizedBox(height: 8.h),
          if (isFront
              ? (_emiratesIdFrontFile != null)
              : (_emiratesIdBackFile != null))
            Align(
              alignment: Alignment.centerLeft,
              child: Text(
                'Uploaded',
                style: TextStyle(
                  color: Colors.green.shade700,
                  fontSize: 12.sp,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildEmiratesIdForm() {
    return Column(
      children: [
        _buildModernTextField(
          label: 'Emirates ID Number',
          icon: Icons.pin_outlined,
          controller: _emiratesIdController,
        ),
        const SizedBox(height: 20),
        _buildModernTextField(
          label: 'Name of Holder',
          icon: Icons.person_outline_rounded,
          controller: _nameOfHolderController,
        ),
        const SizedBox(height: 20),
        _buildResponsiveRow(
          children: [
            _buildModernDateField(
              label: 'Date of Birth',
              icon: Icons.cake_outlined,
              controller: _dobController,
            ),
            _buildModernTextField(
              label: 'Nationality',
              icon: Icons.flag_outlined,
              controller: _nationalityController,
            ),
          ],
        ),
        const SizedBox(height: 20),
        _buildModernTextField(
          label: 'Company Details / Sponsor Name',
          icon: Icons.business_outlined,
          controller: _companyDetailsController,
        ),
        const SizedBox(height: 20),
        _buildResponsiveRow(
          children: [
            _buildModernDateField(
              label: 'Issue Date',
              icon: Icons.event_outlined,
              controller: _issueDateController,
            ),
            _buildModernDateField(
              label: 'Expiry Date',
              icon: Icons.event_available_outlined,
              controller: _expiryDateController,
            ),
          ],
        ),
        const SizedBox(height: 20),
        _buildModernTextField(
          label: 'Occupation',
          icon: Icons.work_outline,
          controller: _occupationController,
        ),
      ],
    );
  }

  Widget _buildBankDetailsSection() {
    return _buildModernSection(
      title: 'Bank Details',
      icon: Icons.account_balance_outlined,
      subtitle: 'Optional but recommended for payments',
      isOptional: true,
      children: [
        Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [Colors.grey.shade50, Colors.grey.shade100],
            ),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.grey.shade300),
          ),
          child: Row(
            children: [
              Icon(
                Icons.info_outline_rounded,
                color: Colors.grey.shade600,
                size: 24,
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Secure Bank Information',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: Colors.grey.shade700,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Your bank details are encrypted and securely stored. Upload a bank document to auto-fill details.',
                      style: TextStyle(
                        fontSize: 13,
                        color: Colors.grey.shade600,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 24),
        FileUploadWidget(
          label: 'Bank Document (Optional)',
          icon: Icons.attach_file_outlined,
          allowedExtensions: const ['jpg', 'jpeg', 'png', 'pdf'],
          enableServerUpload: false,
          onFileSelected: (file) async {
            if (file != null) {
              print('Bank document selected: $file');
              setState(() {
                _bankDocumentFile = file;
              });

              final isPdf = file.toLowerCase().endsWith('.pdf');
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(
                    '${isPdf ? 'PDF' : 'Image'} uploaded. Processing...',
                  ),
                ),
              );

              // Process the bank document for OCR
              await _processBankDocumentOcr();
            }
          },
        ),
        const SizedBox(height: 24),
        if (_isProcessingBankOcr) ...[
          const Center(
            child: Padding(
              padding: EdgeInsets.all(16.0),
              child: Column(
                children: [
                  CircularProgressIndicator(),
                  SizedBox(height: 12),
                  Text('Processing bank document...'),
                ],
              ),
            ),
          ),
          const SizedBox(height: 24),
        ],
        _buildResponsiveRow(
          children: [
            _buildModernTextField(
              label: 'Account Holder Name',
              icon: Icons.person_outline_rounded,
              controller: _accountHolderController,
              isRequired: false,
            ),
            _buildModernTextField(
              label: 'IBAN Number',
              icon: Icons.account_balance_wallet_outlined,
              controller: _ibanController,
              isRequired: false,
            ),
          ],
        ),
        const SizedBox(height: 20),
        _buildResponsiveRow(
          children: [
            _buildModernTextField(
              label: 'Bank Name',
              icon: Icons.business_outlined,
              controller: _bankNameController,
              isRequired: false,
            ),
            _buildModernTextField(
              label: 'Branch Name',
              icon: Icons.location_on_outlined,
              controller: _branchNameController,
              isRequired: false,
            ),
          ],
        ),
        const SizedBox(height: 20),
        _buildModernTextField(
          label: 'Bank Address',
          icon: Icons.location_city_outlined,
          controller: _bankAddressController,
          isRequired: false,
        ),
        if (_bankDocumentFile != null) ...[
          const SizedBox(height: 16),
          ElevatedButton.icon(
            onPressed: () async {
              if (_bankDocumentFile != null) {
                await _processBankDocumentOcr();
              }
            },
            icon: const Icon(Icons.refresh_rounded),
            label: const Text('Re-scan Bank Document'),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF1E3A8A),
            ),
          ),
        ],
      ],
    );
  }

  /// Helper method to create responsive field layouts
  Widget _buildResponsiveRow({required List<Widget> children}) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final isMobile = constraints.maxWidth < 600;

        if (isMobile) {
          // Stack vertically on mobile
          return Column(
            children: [
              for (int i = 0; i < children.length; i++) ...[
                children[i],
                if (i < children.length - 1) const SizedBox(height: 20),
              ],
            ],
          );
        } else {
          // Keep horizontal layout on larger screens
          return Row(
            children: [
              for (int i = 0; i < children.length; i++) ...[
                Expanded(child: children[i]),
                if (i < children.length - 1) const SizedBox(width: 16),
              ],
            ],
          );
        }
      },
    );
  }

  Widget _buildModernSection({
    required String title,
    required IconData icon,
    required List<Widget> children,
    bool isOptional = false,
    String? subtitle,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Section Header
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 16),
          child: Row(
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      const Color(0xFF1E3A8A).withOpacity(0.1),
                      const Color(0xFF3B82F6).withOpacity(0.1),
                    ],
                  ),
                  shape: BoxShape.circle,
                ),
                child: Icon(icon, color: const Color(0xFF1E3A8A), size: 24),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Text(
                          title,
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF1F2937),
                          ),
                        ),
                        if (isOptional) ...[
                          const SizedBox(width: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 4,
                            ),
                            decoration: BoxDecoration(
                              color: Colors.grey.shade200,
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Text(
                              'Optional',
                              style: TextStyle(
                                fontSize: 11,
                                color: Colors.grey.shade600,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ),
                        ],
                      ],
                    ),
                    if (subtitle != null)
                      Padding(
                        padding: const EdgeInsets.only(top: 4),
                        child: Text(
                          subtitle,
                          style: TextStyle(
                            fontSize: 13,
                            color: Colors.grey.shade600,
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            ],
          ),
        ),
        // Section Content
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: children,
          ),
        ),
      ],
    );
  }

  Widget _buildModernTextField({
    required String label,
    required IconData icon,
    TextEditingController? controller,
    bool isPhone = false,
    bool isRequired = true,
  }) {
    return TextFormField(
      controller: controller,
      style: TextStyle(
        color: Colors.black87, // Dark color for the input text
        fontSize: 16.sp,
        fontWeight: FontWeight.w500,
      ),
      decoration: InputDecoration(
        labelText: isRequired ? '$label *' : label,
        labelStyle: TextStyle(
          color: Colors.grey.shade600,
          fontWeight: FontWeight.w500,
        ),
        prefixIcon: Container(
          margin: const EdgeInsets.all(12),
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: const Color(0xFF1E3A8A).withOpacity(0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(icon, color: const Color(0xFF1E3A8A), size: 20),
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Colors.grey.shade300),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Colors.grey.shade300),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Color(0xFF1E3A8A), width: 2),
        ),
        filled: true,
        fillColor: Colors.grey.shade50,
        prefixText: isPhone ? UaePhoneUtils.countryPrefix : null,
        hintText: isPhone ? UaePhoneUtils.localHint : null,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 16,
        ),
      ),
      keyboardType: isPhone ? TextInputType.phone : TextInputType.text,
      inputFormatters: isPhone ? UaePhoneUtils.inputFormatters() : null,
    );
  }

  Widget _buildModernDateField({
    required String label,
    required IconData icon,
    TextEditingController? controller,
    bool isRequired = true,
  }) {
    return TextFormField(
      controller: controller,
      style: TextStyle(
        color: Colors.black87, // Dark color for the input text
        fontSize: 16.sp,
        fontWeight: FontWeight.w500,
      ),
      decoration: InputDecoration(
        labelText: isRequired ? '$label *' : label,
        labelStyle: TextStyle(
          color: Colors.grey.shade600,
          fontWeight: FontWeight.w500,
        ),
        prefixIcon: Container(
          margin: const EdgeInsets.all(12),
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: const Color(0xFF1E3A8A).withOpacity(0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(icon, color: const Color(0xFF1E3A8A), size: 20),
        ),
        suffixIcon: Container(
          margin: const EdgeInsets.all(12),
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: Colors.grey.shade100,
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(
            Icons.calendar_today_rounded,
            color: Colors.grey.shade600,
            size: 20,
          ),
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Colors.grey.shade300),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Colors.grey.shade300),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Color(0xFF1E3A8A), width: 2),
        ),
        filled: true,
        fillColor: Colors.grey.shade50,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 16,
        ),
      ),
      readOnly: true,
      onTap: () async {
        final date = await showDatePicker(
          context: context,
          initialDate: DateTime.now(),
          firstDate: DateTime(1900),
          lastDate: DateTime(2100),
          builder: (context, child) {
            return Theme(
              data: Theme.of(context).copyWith(
                colorScheme: const ColorScheme.light(
                  primary: Color(0xFF1E3A8A),
                ),
              ),
              child: child!,
            );
          },
        );
        if (date != null && controller != null) {
          controller.text = '${date.day}/${date.month}/${date.year}';
        }
      },
    );
  }

  void _showHelpDialog() {
    showDialog(
      context: context,
      builder: (context) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        child: Container(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: const Color(0xFF1E3A8A).withOpacity(0.1),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.help_outline_rounded,
                  size: 48,
                  color: Color(0xFF1E3A8A),
                ),
              ),
              const SizedBox(height: 20),
              Text(
                'Registration Help',
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                  color: const Color(0xFF1F2937),
                ),
              ),
              const SizedBox(height: 16),
              Text(
                'Fill in all required fields marked with *. Upload your Emirates ID (images or PDF) to auto-fill information. Upload bank documents to auto-fill bank details. Bank details are optional but recommended for faster payments.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: Colors.black,
                  fontSize: 15,
                  height: 1.5,
                ),
              ),
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () => context.pop(),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF1E3A8A),
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: const Text(
                    'Got it',
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w600,
                      fontSize: 16,
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

  // OCR processing for Emirates ID using Gemini first, ML Kit as fallback
  Future<void> _processEmiratesIdOcrWithRetry() async {
    if (_emiratesIdFrontFile == null || _emiratesIdBackFile == null) return;

    setState(() {
      _isProcessingOcr = true;
    });

    try {
      debugPrint(
        '[PainterRegistration] Using Hybrid OCR for Emirates ID (Gemini with ML Kit fallback)',
      );

      final result = await _hybridOcrService.extractEmiratesIdFields(
        frontImagePath: _emiratesIdFrontFile!,
        backImagePath: _emiratesIdBackFile!,
      );

      _updateFieldsFromResult(result);

      if (mounted) {
        AppSnackBar.showSuccess(
          context,
          'Emirates ID fields autofilled with AI',
        );
      }
    } catch (e) {
      debugPrint('Error in Emirates ID OCR: $e');
      if (mounted) {
        AppSnackBar.showError(
          context,
          'Error processing Emirates ID: ${e.toString()}',
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isProcessingOcr = false;
        });
      }
    }
  }

  // OCR processing for bank document using Hybrid service (Gemini with ML Kit fallback)
  Future<void> _processBankDocumentOcr() async {
    if (_bankDocumentFile == null) return;

    setState(() {
      _isProcessingBankOcr = true;
    });

    try {
      debugPrint(
        '[PainterRegistration] Using Hybrid OCR for Bank Details (Gemini with ML Kit fallback)',
      );

      final result = await _hybridOcrService.extractBankDetailsFields(
        bankDocumentPath: _bankDocumentFile!,
      );

      _updateBankFieldsFromResult(result);

      if (mounted) {
        AppSnackBar.showSuccess(context, 'Bank details autofilled with AI');
      }
    } catch (e) {
      debugPrint('Error in Bank Details OCR: $e');
      if (mounted) {
        AppSnackBar.showError(
          context,
          'Error processing bank document: ${e.toString()}',
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isProcessingBankOcr = false;
        });
      }
    }
  }

  // Helper to update form fields from parsed Emirates ID results
  void _updateFieldsFromResult(Map<String, String?> result) {
    if (result['id'] != null && _ocrService.isValidEmiratesId(result['id']!)) {
      _emiratesIdController.text = result['id']!;
    }

    if (result['name'] != null) {
      _nameOfHolderController.text = result['name']!;

      // Try to split name into first, middle, last
      final nameParts = result['name']!.split(' ');
      if (nameParts.isNotEmpty) {
        _firstNameController.text = nameParts.first;
      }
      if (nameParts.length > 2) {
        _middleNameController.text = nameParts
            .sublist(1, nameParts.length - 1)
            .join(' ');
      }
      if (nameParts.length > 1) {
        _lastNameController.text = nameParts.last;
      }
    }

    if (result['dob'] != null && result['dob']!.isNotEmpty) {
      if (_ocrService.isValidDate(result['dob']!)) {
        _dobController.text = result['dob']!;
      }
    }

    if (result['nationality'] != null) {
      _nationalityController.text = result['nationality']!;
    }

    if (result['issue'] != null) {
      if (_ocrService.isValidDate(result['issue']!)) {
        _issueDateController.text = result['issue']!;
      }
    }

    if (result['expiry'] != null) {
      if (_ocrService.isValidDate(result['expiry']!)) {
        _expiryDateController.text = result['expiry']!;
      }
    }

    if (result['employer'] != null) {
      _companyDetailsController.text = result['employer']!;
    }

    if (result['occupation'] != null) {
      _occupationController.text = result['occupation']!;
    }
  }

  // Helper to update bank form fields from parsed results
  void _updateBankFieldsFromResult(Map<String, String?> result) {
    if (result['accountHolder'] != null &&
        result['accountHolder']!.isNotEmpty) {
      _accountHolderController.text = result['accountHolder']!;
    }

    if (result['iban'] != null && result['iban']!.isNotEmpty) {
      if (_bankOcrService.isValidIban(result['iban']!)) {
        _ibanController.text = result['iban']!;
      }
    }

    if (result['bankName'] != null && result['bankName']!.isNotEmpty) {
      _bankNameController.text = result['bankName']!;
    }

    if (result['branchName'] != null && result['branchName']!.isNotEmpty) {
      _branchNameController.text = result['branchName']!;
    }

    if (result['bankAddress'] != null && result['bankAddress']!.isNotEmpty) {
      _bankAddressController.text = result['bankAddress']!;
    }
  }

  /// Upload all selected files to server before registration
  /// Returns [true] if all files uploaded successfully, [false] if any failed or none selected
  Future<bool> _uploadFilesToServer() async {
    print('=== Starting painter file upload to server ===');

    final firstName = _firstNameController.text.trim();
    final lastName = _lastNameController.text.trim();
    final mobile = _mobileController.text.trim();

    print('Name: $firstName $lastName');
    print('Mobile: $mobile');

    if (firstName.isEmpty || lastName.isEmpty || mobile.isEmpty) {
      print('Skipping upload - name or mobile is empty');
      return true; // Return true as there's technically no failure, but this shouldn't happen
    }

    // Map file paths to document types
    final filePathsByType = <String, String>{
      if (_profilePhotoPath != null && _profilePhotoPath!.isNotEmpty)
        DocumentType.profilePhoto: _profilePhotoPath!,
      if (_emiratesIdFrontFile != null && _emiratesIdFrontFile!.isNotEmpty)
        DocumentType.emiratesIdFront: _emiratesIdFrontFile!,
      if (_emiratesIdBackFile != null && _emiratesIdBackFile!.isNotEmpty)
        DocumentType.emiratesIdBack: _emiratesIdBackFile!,
      if (_bankDocumentFile != null && _bankDocumentFile!.isNotEmpty)
        DocumentType.bankDocument: _bankDocumentFile!,
    };

    if (filePathsByType.isEmpty) {
      print('No files to upload');
      return true; // No files to upload is fine
    }

    print('Files to upload: ${filePathsByType.keys.toList()}');

    // Get current user ID for createId
    final currentUser = AuthManager.currentUser;
    final createId = currentUser?.userID ?? currentUser?.emplName ?? 'SYSTEM';

    // Upload all files in batch
    final results = await ImageUploadService.uploadMultipleImages(
      filePathsByType: filePathsByType,
      firstName: firstName,
      lastName: lastName,
      mobile: mobile,
      createId: createId,
    );

    // Show results
    int successCount = 0;
    int failCount = 0;
    String firstError = '';

    results.forEach((docType, response) {
      if (response.success) {
        successCount++;
        print('✅ $docType uploaded: ${response.attFilKy}');
      } else {
        failCount++;
        if (firstError.isEmpty) {
          firstError = response.message;
        }
        print('❌ $docType failed: ${response.message}');
      }
    });

    // Handle failure
    if (failCount > 0 && mounted) {
      await showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: const Row(
            children: [
              Icon(Icons.error_outline, color: Colors.red),
              SizedBox(width: 8),
              Text('Upload Failed'),
            ],
          ),
          content: Text(
            'Failed to upload $failCount document(s).\n\nDetails: $firstError\n\nPlease check your internet connection and try again.',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('OK'),
            ),
          ],
        ),
      );
      print(
        '=== File upload completed with errors: $successCount success, $failCount failed ===',
      );
      return false; // Indicating upload failure to prevent DB registration
    }

    print('=== File upload completed successfully: $successCount success ===');
    return true; // Success
  }

  /// Build mobile verification section (Step 1)
  Widget _buildMobileVerificationSection() {
    return ResponsiveSection(
      title: 'Mobile Verification',
      icon: Icons.phone_outlined,
      subtitle: 'Verify your mobile number with OTP',
      children: [
        ResponsiveRow(
          children: [
            ResponsiveTextField(
              label: 'Mobile Number',
              icon: Icons.phone_outlined,
              controller: _mobileController,
              keyboardType: TextInputType.phone,
              inputFormatters: [
                FilteringTextInputFormatter.digitsOnly,
                LengthLimitingTextInputFormatter(9),
              ],
              validator: (value) {
                if (value == null || value.trim().isEmpty) {
                  return 'Please enter mobile number';
                }
                return PainterService.validateMobileNumber(value);
              },
              suffixIcon: _isCheckingMobile
                  ? const Padding(
                      padding: EdgeInsets.all(12.0),
                      child: SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      ),
                    )
                  : _mobileValidationError != null
                  ? const Icon(Icons.error_outline, color: Colors.red)
                  : _isOtpVerified
                  ? const Icon(Icons.check_circle, color: Colors.green)
                  : null,
            ),
          ],
        ),
        if (_mobileValidationError != null) ...[
          const SizedBox(height: 8),
          Row(
            children: [
              const Icon(Icons.error_outline, color: Colors.red, size: 16),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  _mobileValidationError!,
                  style: const TextStyle(
                    color: Colors.red,
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ],
          ),
        ],
        const ResponsiveSpacing(mobile: 20),
        if (!_showOtpField) ...[
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: _isSendingOtp ? null : _sendOtp,
              icon: _isSendingOtp
                  ? const SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                      ),
                    )
                  : const Icon(Icons.sms_outlined),
              label: Text(_isSendingOtp ? 'Sending OTP...' : 'Send OTP'),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF1E3A8A),
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
          ),
        ],
        if (_showOtpField) ...[
          ResponsiveRow(
            children: [
              ResponsiveTextField(
                label: 'Enter OTP',
                icon: Icons.security_outlined,
                controller: _otpController,
                keyboardType: TextInputType.number,
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Please enter OTP';
                  }
                  if (value.trim().length != 6) {
                    return 'OTP must be 6 digits';
                  }
                  return null;
                },
                suffixIcon: _isOtpVerified
                    ? const Icon(Icons.check_circle, color: Colors.green)
                    : null,
              ),
            ],
          ),
          const ResponsiveSpacing(mobile: 20),
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: _isSendingOtp ? null : _sendOtp,
                  icon: _isSendingOtp
                      ? const SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Icon(Icons.refresh_outlined),
                  label: Text(_isSendingOtp ? 'Sending...' : 'Resend OTP'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: const Color(0xFF1E3A8A),
                    side: const BorderSide(color: Color(0xFF1E3A8A)),
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: _isOtpVerified ? null : _verifyOtp,
                  icon: _isOtpVerified
                      ? const Icon(Icons.check_circle)
                      : const Icon(Icons.verified_outlined),
                  label: Text(_isOtpVerified ? 'Verified' : 'Verify OTP'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: _isOtpVerified
                        ? Colors.green
                        : const Color(0xFF1E3A8A),
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
        if (_isOtpVerified) ...[
          const ResponsiveSpacing(mobile: 20),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.green.shade50,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.green.shade200),
            ),
            child: Row(
              children: [
                Icon(Icons.check_circle, color: Colors.green.shade700),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    'Mobile number verified successfully! You can now proceed to the next step.',
                    style: TextStyle(
                      color: Colors.green.shade700,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
        if (_isCheckingKycStatus) ...[
          const ResponsiveSpacing(mobile: 20),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.blue.shade50,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.blue.shade200),
            ),
            child: Row(
              children: [
                const SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(strokeWidth: 2),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    'Checking registration status...',
                    style: TextStyle(
                      color: Colors.blue.shade700,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
        if (_kycStatus != null && _kycStatus!.success) ...[
          const ResponsiveSpacing(mobile: 20),
          KycStatusWidget(status: _kycStatus!, onRefresh: _checkKycStatus),
        ],
      ],
    );
  }
}
