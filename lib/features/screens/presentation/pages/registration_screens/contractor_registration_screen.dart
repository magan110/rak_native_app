import 'package:rak_app/core/utils/uae_phone_utils.dart';
import 'dart:async';
import 'dart:io';
import 'dart:math';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../../../shared/widgets/custom_back_button.dart';
import '../../../../../shared/widgets/modern_dropdown.dart';
import '../../../../../shared/widgets/file_upload_widget.dart';
import '../../../../../shared/widgets/responsive_widgets.dart';
import '../../../../../core/services/emirates_id_ocr_service.dart';
import '../../../../../core/services/bank_details_ocr_service.dart';
import '../../../../../core/services/hybrid_ocr_service.dart';
import '../../../../../core/services/contractor_service.dart';
import '../../../../../core/services/autologin_service.dart';
import '../../../../../core/services/auth_service.dart';
import '../../../../../core/services/image_upload_service.dart';
import '../../../../../core/services/sms_uae_service.dart';
import '../../../../../core/services/kyc_status_service.dart';
import '../../../../../core/config/api_config.dart';
import '../../../../../core/models/contractor_models.dart';
import '../../../../../core/models/kyc_status_models.dart';
import '../../../../../shared/widgets/kyc_status_widget.dart';
import '../../../../../core/utils/snackbar_utils.dart';
import 'package:google_mlkit_text_recognition/google_mlkit_text_recognition.dart';
import 'package:path_provider/path_provider.dart';
import 'package:pdfx/pdfx.dart';
import 'package:go_router/go_router.dart';
import 'package:rak_app/core/routes/route_names.dart';

class ContractorRegistrationScreen extends StatefulWidget {
  final bool isEmployeeRegistration;

  const ContractorRegistrationScreen({
    super.key,
    this.isEmployeeRegistration = false,
  });

  @override
  State<ContractorRegistrationScreen> createState() =>
      _ContractorRegistrationScreenState();
}

class _ContractorRegistrationScreenState
    extends State<ContractorRegistrationScreen>
    with TickerProviderStateMixin {
  late AnimationController _mainController;
  late AnimationController _fabController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;
  late Animation<double> _scaleAnimation;

  // Current step state (1 = Mobile/OTP, 2 = Emirates ID, 3 = Personal, 4 = Business, 5 = Bank)
  int _currentStep = 1;

  // Form controllers for auto-fill
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
  final TextEditingController _firmNameController = TextEditingController();
  final TextEditingController _registeredAddressController =
      TextEditingController();
  final TextEditingController _taxNumberController = TextEditingController();
  final TextEditingController _tradeLicenseController = TextEditingController();
  final TextEditingController _licenseNumberController =
      TextEditingController();
  final TextEditingController _issuingAuthorityController =
      TextEditingController();
  final TextEditingController _licenseTypeController = TextEditingController();
  final TextEditingController _tradeNameController = TextEditingController();
  final TextEditingController _responsiblePersonController =
      TextEditingController();
  final TextEditingController _establishmentDateController =
      TextEditingController();
  final TextEditingController _licenseExpiryDateController =
      TextEditingController();
  final TextEditingController _effectiveRegDateController =
      TextEditingController();
  final TextEditingController _effectiveVatDateController =
      TextEditingController();

  String? _selectedEmirate;
  String? _selectedContractorType;
  String? _selectedLicenseType;
  String? _selectedIssuingAuthority;

  // Master location lists and selection codes/names
  List<EmirateItem> _emiratesList = [];
  List<AreaItem> _areasList = [];
  List<SubAreaItem> _subAreasList = [];
  String? _selectedEmirateCode;
  String? _selectedArea;
  String? _selectedAreaCode;
  String? _selectedSubArea;
  String? _selectedSubAreaCode;
  bool _hasSubArea = false;
  final TextEditingController _poBoxController = TextEditingController();

  // File upload paths to persist across navigation
  String? _profilePhotoPath;
  String? _certificatePath;
  String? _vatCertificatePath;
  String? _commercialLicensePath;
  String? _bankDocumentPath;
  String? _emiratesIdFrontFile;
  String? _emiratesIdBackFile;

  // Bank details OCR processing flag
  bool _isProcessingBankOcr = false;

  // VAT certificate OCR processing flag
  bool _isProcessingVatOcr = false;

  // Commercial Licence OCR processing flag
  bool _isProcessingCommercialLicenceOcr = false;

  // Emirates ID OCR processing flag
  bool _isProcessingOcr = false;
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

  // KYC Status state
  KycStatusResponse? _kycStatus;
  bool _isCheckingKycStatus = false;

  // OTP constants
  static const _otpKeyCode = 'contractor_otp_code';
  static const _otpKeyMobile = 'contractor_otp_mobile';
  static const _otpKeyExpiry = 'contractor_otp_expiry';
  static const _otpKeyCooldown = 'contractor_otp_cooldown';

  // Bypass configuration — only active in debug mode
  static final String _bypassMobile = kDebugMode ? '527777777' : '';
  static final String _bypassOtp = kDebugMode ? '123456' : '';

  // Scroll controller for scrolling to top on step change
  final ScrollController _scrollController = ScrollController();

  // Hybrid OCR service (Gemini with ML Kit fallback)
  final HybridOcrService _hybridOcrService = HybridOcrService();

  // Legacy OCR services (kept for compatibility)
  final EmiratesIdOcrService _ocrService = EmiratesIdOcrService();
  final BankDetailsOcrService _bankOcrService = BankDetailsOcrService();

  // OCR processing states for unified system
  // Note: These states are managed by individual boolean flags above

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
    // Load master data for location dropdowns
    _loadEmirates();
  }

  @override
  void dispose() {
    _debounceTimer?.cancel();
    _resendTimer?.cancel();
    if (!widget.isEmployeeRegistration) {
      _mobileController.removeListener(_onMobileNumberChanged);
    }
    _poBoxController.dispose();
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
    _firmNameController.dispose();
    _registeredAddressController.dispose();
    _taxNumberController.dispose();
    _tradeLicenseController.dispose();
    _licenseNumberController.dispose();
    _issuingAuthorityController.dispose();
    _licenseTypeController.dispose();
    _tradeNameController.dispose();
    _responsiblePersonController.dispose();
    _establishmentDateController.dispose();
    _licenseExpiryDateController.dispose();
    _effectiveRegDateController.dispose();
    _effectiveVatDateController.dispose();

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
                'Contractor Registration',
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
                      Icons.business_center,
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
              _buildProgressStep(4, 'Business', _currentStep >= 4),
              _buildProgressLine(_currentStep >= 5),
              _buildProgressStep(5, 'Bank', _currentStep >= 5),
            ],
          ),
          SizedBox(height: 12.h),
          Text(
            'Step $_currentStep of 5: ${_getStepTitle()}',
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
        return 'Business Information';
      case 5:
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
        currentSection = _buildBusinessDetailsSection();
        break;
      case 5:
        currentSection = _buildBankDetailsSection();
        break;
      default:
        currentSection = _buildMobileVerificationSection();
    }

    return Column(
      children: [
        currentSection,
        const SizedBox(height: 24),
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
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.arrow_back_rounded),
                  const SizedBox(width: 8),
                  Text(
                    'Previous',
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
          ),

        if (_currentStep > 1) const SizedBox(width: 16),

        // Next/Submit button
        Expanded(
          child: ElevatedButton(
            onPressed: _isSubmitting
                ? null
                : () {
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

                    // Validate contractor type and location hierarchy when moving from step 3 to step 4
                    if (_currentStep == 3) {
                      if (_selectedContractorType == null ||
                          _selectedContractorType!.isEmpty) {
                        AppSnackBar.showError(
                          context,
                          'Please select a contractor type to continue',
                        );
                        return;
                      }

                      if (_selectedEmirateCode == null ||
                          _selectedEmirateCode!.isEmpty) {
                        AppSnackBar.showError(
                          context,
                          'Please select an emirate to continue',
                        );
                        return;
                      }

                      if (_selectedAreaCode == null ||
                          _selectedAreaCode!.isEmpty) {
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

                    if (_currentStep < 5) {
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
                      _submitContractorRegistration();
                    }
                  },
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF1E3A8A),
              foregroundColor: Colors.white,
              elevation: 0,
              padding: const EdgeInsets.symmetric(vertical: 16),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                if (_isSubmitting && _currentStep == 4) ...[
                  const SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                    ),
                  ),
                  const SizedBox(width: 12),
                ],
                Text(
                  _currentStep < 5
                      ? 'Next'
                      : (_isSubmitting
                            ? 'Submitting...'
                            : 'Submit Registration'),
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                if (!_isSubmitting || _currentStep < 5) ...[
                  const SizedBox(width: 8),
                  Icon(
                    _currentStep < 5
                        ? Icons.arrow_forward_rounded
                        : Icons.check_circle_rounded,
                  ),
                ],
              ],
            ),
          ),
        ),
      ],
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

  Future<void> _sendOtp() async {
    if (_isSendingOtp) return;

    final mobileRaw = _mobileController.text.trim();
    final mobileErr = ContractorService.validateMobileNumber(mobileRaw);
    if (mobileErr != null) {
      AppSnackBar.showError(context, mobileErr);
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
      AppSnackBar.showWarning(
        context,
        'Please wait ${(leftMs / 1000).ceil()} seconds before resending',
      );
      return;
    }

    setState(() => _isSendingOtp = true);

    try {
      // If bypass number, skip SMS and use fixed OTP
      if (isBypassNumber) {
        debugPrint('🔓 Bypass number detected (Contractor): $mobileRaw');
        await _saveOtpLocally(
          mobile: _normalizeForPrefs(mobileRaw),
          otp: _bypassOtp,
        );
        await _setResendCooldown();
        setState(() {
          _showOtpField = true;
        });
        AppSnackBar.showSuccess(context, 'OTP: $_bypassOtp (Bypass mode)');
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
          AppSnackBar.showSuccess(context, 'OTP sent successfully');
          break;
        } else {
          lastError = result.message ?? 'Failed to send OTP';
        }
      }

      if (!sent && lastError != null) {
        AppSnackBar.showError(context, lastError);
      }
    } catch (e) {
      AppSnackBar.showError(context, 'Error sending OTP: ${e.toString()}');
    } finally {
      setState(() => _isSendingOtp = false);
    }
  }

  Future<void> _verifyOtp() async {
    final enteredOtp = _otpController.text.trim();
    if (enteredOtp.length != 6) {
      AppSnackBar.showError(context, 'Please enter a valid 6-digit OTP');
      return;
    }

    final stored = await _loadOtp();
    if (stored == null) {
      AppSnackBar.showError(context, 'No OTP found. Please request a new OTP.');
      return;
    }

    final now = DateTime.now().millisecondsSinceEpoch;
    final targetMobile = stored['mobile'] as String;
    final savedOtp = stored['otp'] as String;
    final expiry = stored['expiry'] as int;

    if (_normalizeForPrefs(_mobileController.text) != targetMobile) {
      AppSnackBar.showError(
        context,
        'Mobile number mismatch. Request OTP again.',
      );
      return;
    }

    if (now > expiry) {
      AppSnackBar.showError(context, 'OTP expired. Please request a new OTP.');
      return;
    }

    if (enteredOtp != savedOtp) {
      AppSnackBar.showError(context, 'Invalid OTP. Please try again.');
      return;
    }

    // OTP verified successfully
    await _clearOtp();
    setState(() {
      _isOtpVerified = true;
    });
    AppSnackBar.showSuccess(context, 'Mobile number verified successfully!');

    // Check KYC status after successful OTP verification
    _checkKycStatus();
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
    final mobileErr = ContractorService.validateMobileNumber(mobile);
    if (mobileErr != null) {
      return; // Don't check duplicate if format is invalid
    }

    // Debounce the API call
    _debounceTimer?.cancel();
    _debounceTimer = Timer(const Duration(milliseconds: 800), () {
      _checkMobileDuplicateRealTime(mobile);
    });
  }

  /// Calculate total points for new contractor registration
  /// All new contractors receive 250 points upon successful registration
  int _calculateTotalPoints() {
    return 250;
  }

  Timer? _debounceTimer;

  void _checkMobileDuplicateRealTime(String mobile) async {
    if (!mounted || mobile.isEmpty) return;

    setState(() {
      _isCheckingMobile = true;
      _mobileValidationError = null;
    });

    try {
      final duplicateCheck = await ContractorService.checkMobileDuplicate(
        mobile,
      );

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

  void _submitContractorRegistration() {
    // Basic validations
    if (_isSubmitting) return;

    // Validate contractor type (compulsory)
    if (_selectedContractorType == null || _selectedContractorType!.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please select a contractor type'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    // Validate emirates (compulsory)
    if (_selectedEmirate == null || _selectedEmirate!.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please select an emirate'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    final firstNameErr = ContractorService.validateName(
      _firstNameController.text,
      'First name',
    );
    if (firstNameErr != null) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(firstNameErr)));
      return;
    }

    final lastNameErr = ContractorService.validateName(
      _lastNameController.text,
      'Last name',
    );
    if (lastNameErr != null) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(lastNameErr)));
      return;
    }

    final mobileErr = ContractorService.validateMobileNumber(
      _mobileController.text,
    );
    if (mobileErr != null) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(mobileErr)));
      return;
    }

    // Check if there's a real-time validation error
    if (_mobileValidationError != null) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(_mobileValidationError!)));
      return;
    }

    // Check for duplicate mobile number before proceeding
    _checkDuplicateMobileAndProceed();
  }

  void _checkDuplicateMobileAndProceed() async {
    if (_isSubmitting) return;

    setState(() => _isSubmitting = true);
    final messenger = ScaffoldMessenger.of(context);

    // Show checking message
    final checkingSnackBar = SnackBar(
      content: Row(
        children: [
          const SizedBox(width: 4),
          const CircularProgressIndicator(),
          const SizedBox(width: 12),
          const Expanded(child: Text('Checking mobile number...')),
        ],
      ),
      behavior: SnackBarBehavior.floating,
    );
    messenger.showSnackBar(checkingSnackBar);

    try {
      // Check for duplicate mobile number
      final duplicateCheck = await ContractorService.checkMobileDuplicate(
        _mobileController.text,
      );

      messenger.hideCurrentSnackBar();

      if (!duplicateCheck.success) {
        // API call failed, show error but allow to proceed
        messenger.showSnackBar(
          SnackBar(
            content: Text(duplicateCheck.message),
            backgroundColor: Colors.orange,
            behavior: SnackBarBehavior.floating,
          ),
        );
        // Continue with registration despite check failure
        _proceedWithRegistration();
        return;
      }

      if (duplicateCheck.exists) {
        // Mobile number already exists, prevent registration
        messenger.showSnackBar(
          SnackBar(
            content: Row(
              children: [
                const Icon(Icons.error_outline, color: Colors.white),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    duplicateCheck.message.isNotEmpty
                        ? duplicateCheck.message
                        : 'This mobile number is already registered. Please use a different number.',
                  ),
                ),
              ],
            ),
            backgroundColor: Colors.redAccent,
            behavior: SnackBarBehavior.floating,
            duration: const Duration(seconds: 4),
          ),
        );
        setState(() => _isSubmitting = false);
        return;
      }

      // Mobile number is available, proceed with registration
      _proceedWithRegistration();
    } catch (e) {
      messenger.hideCurrentSnackBar();
      messenger.showSnackBar(
        SnackBar(
          content: Text('Error checking mobile number: ${e.toString()}'),
          backgroundColor: Colors.orange,
          behavior: SnackBarBehavior.floating,
        ),
      );
      // Continue with registration despite check failure
      _proceedWithRegistration();
    }
  }

  void _proceedWithRegistration() async {
    final messenger = ScaffoldMessenger.of(context);

    // Calculate total points based on form completeness
    final totalPoints = _calculateTotalPoints();

    // Get current logged-in user's ID for loginId field
    final currentUser = AuthManager.currentUser;
    final loginId = currentUser?.userID ?? currentUser?.emplName ?? 'SYSTEM';

    // Build the registration request from form fields
    final req = ContractorRegistrationRequest(
      contractorType: _selectedContractorType,
      firstName: _firstNameController.text.trim(),
      middleName: _middleNameController.text.trim(),
      lastName: _lastNameController.text.trim(),
      mobileNumber: ContractorService.formatMobileNumber(
        _mobileController.text,
      ),
      address: _addressController.text.trim(),

      // Master location values
      emirateCode: _selectedEmirateCode,
      emirateName: _selectedEmirate,
      areaCode: _selectedAreaCode,
      areaName: _selectedArea,
      hasSubArea: _hasSubArea,
      subAreaCode: _selectedSubAreaCode,
      subAreaName: _selectedSubArea,
      poBox: _poBoxController.text.trim(),

      profilePhoto: _profilePhotoPath,
      contractorCertificate: _certificatePath,
      // Emirates ID Details
      emiratesIdNumber: _emiratesIdController.text.trim(),
      idName: _nameOfHolderController.text.trim(),
      dateOfBirth: _dobController.text.trim(),
      nationality: _nationalityController.text.trim(),
      companyDetails: _companyDetailsController.text.trim(),
      issueDate: _issueDateController.text.trim(),
      expiryDate: _expiryDateController.text.trim(),
      occupation: _occupationController.text.trim(),
      // Bank Details
      accountHolderName: _accountHolderController.text.trim(),
      ibanNumber: ContractorService.formatIban(_ibanController.text),
      bankName: _bankNameController.text.trim(),
      branchName: _branchNameController.text.trim(),
      bankAddress: _bankAddressController.text.trim(),
      bankDocument: _bankDocumentPath,
      // VAT Certificate
      vatCertificate: _vatCertificatePath,
      firmName: _firmNameController.text.trim(),
      vatAddress: _registeredAddressController.text.trim(),
      taxRegistrationNumber: _taxNumberController.text.trim(),
      vatEffectiveDate: _effectiveVatDateController.text.trim(),
      // Commercial License
      licenseDocument: _commercialLicensePath,
      licenseNumber: _licenseNumberController.text.trim(),
      issuingAuthority: _selectedIssuingAuthority,
      licenseType: _selectedLicenseType,
      establishmentDate: _establishmentDateController.text.trim(),
      licenseExpiryDate: _licenseExpiryDateController.text.trim(),
      tradeName: _tradeNameController.text.trim(),
      responsiblePerson: _responsiblePersonController.text.trim(),
      licenseAddress: _tradeLicenseController.text.trim(),
      effectiveDate: _effectiveRegDateController.text.trim(),
      totalPoints: totalPoints,
      loginId: loginId,
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
              Expanded(child: Text('Registering contractor...')),
            ],
          ),
          behavior: SnackBarBehavior.floating,
        ),
      );

      // 2. Register contractor in DB
      final resp = await ContractorService.registerContractor(req);
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
            userType: 'contractor',
            userName: registeredName,
            emirates: _selectedEmirate ?? '',
            influencerCode: resp.influencerCode,
            additionalData: {
              'mobileNumber': ContractorService.formatMobileNumber(
                _mobileController.text,
              ),
              'contractorType': _selectedContractorType ?? '',
              'firmName': _firmNameController.text.trim(),
              'licenseNumber': _licenseNumberController.text.trim(),
            },
          );

          // Navigate to contractor home after short delay so user sees the success snackbar
          await Future.delayed(const Duration(seconds: 1));
          if (mounted) {
            // Pass isNewRegistration so home screen can show congratulations dialog
            context.go(
              RouteNames.contractorHome,
              extra: {
                'isNewRegistration': true,
                'userRole': 'contractor',
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

  Future<void> _loadEmirates() async {
    try {
      final list = await ContractorService.getEmiratesList();
      setState(() => _emiratesList = list);
    } catch (e) {
      // ignore silently; user can still type/select
      print('Failed to load emirates: ${e.toString()}');
    }
  }

  Future<void> _fetchAreasForEmirate(String emirateCode) async {
    try {
      _areasList = await ContractorService.getAreasListByEmirate(emirateCode);
      setState(() {
        _subAreasList = [];
        _selectedArea = null;
        _selectedAreaCode = null;
        _selectedSubArea = null;
        _selectedSubAreaCode = null;
        _hasSubArea = false;
        _poBoxController.text = '';
      });
    } catch (e) {
      print('Failed to load areas: ${e.toString()}');
      setState(() => _areasList = []);
    }
  }

  Future<void> _fetchSubAreasForArea(String areaCode) async {
    try {
      final res = await ContractorService.getSubAreasListByArea(areaCode);
      setState(() {
        _hasSubArea = res['hasSubArea'] == true;
        _subAreasList = (res['data'] as List<SubAreaItem>?) ?? [];
        if (!_hasSubArea) {
          // find poBox from selected area
          final area = _areasList.firstWhere(
            (a) => a.code == areaCode,
            orElse: () => AreaItem(code: '', name: '', poBox: ''),
          );
          _poBoxController.text = area.poBox;
        } else {
          _poBoxController.text = '';
        }
      });
    } catch (e) {
      print('Failed to load subareas: ${e.toString()}');
      setState(() {
        _subAreasList = [];
        _hasSubArea = false;
      });
    }
  }

  void _showRegistrationCompletedDialog(String contractorName) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          contentPadding: EdgeInsets.zero,
          content: Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(20),
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
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: const Color(0xFF10B981).withOpacity(0.1),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.check_circle_rounded,
                    color: Color(0xFF10B981),
                    size: 64,
                  ),
                ),
                const SizedBox(height: 20),
                const Text(
                  'Registration Completed!',
                  style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF1F2937),
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 12),
                Text(
                  'Contractor "$contractorName" has been successfully registered.',
                  style: TextStyle(
                    fontSize: 15,
                    color: Colors.grey[600],
                    height: 1.4,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 24),
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
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: const Text(
                      'Done',
                      style: TextStyle(
                        fontSize: 16,
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
        ModernDropdown(
          label: 'Contractor Type',
          icon: Icons.business_center_outlined,
          items: const ['Maintenance Contractor', 'Petty contractors'],
          value: _selectedContractorType,
          isRequired: true,
          onChanged: (String? value) {
            setState(() {
              _selectedContractorType = value;
            });
          },
        ),
        const ResponsiveSpacing(mobile: 20),
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
                    orElse: () => EmirateItem(code: '', name: ''),
                  )
                  .code;
            });
            if (_selectedEmirateCode != null &&
                _selectedEmirateCode!.isNotEmpty) {
              await _fetchAreasForEmirate(_selectedEmirateCode!);
            }
          },
        ),
        const ResponsiveSpacing(mobile: 12),
        ModernDropdown(
          label: 'Area',
          icon: Icons.location_city_outlined,
          items: _areasList.map((a) => a.name).toList(),
          value: _selectedArea,
          isRequired: true,
          onChanged: (String? value) async {
            setState(() {
              _selectedArea = value;
              final area = _areasList.firstWhere(
                (a) => a.name == value,
                orElse: () => AreaItem(code: '', name: '', poBox: ''),
              );
              _selectedAreaCode = area.code;
            });
            if (_selectedAreaCode != null && _selectedAreaCode!.isNotEmpty) {
              await _fetchSubAreasForArea(_selectedAreaCode!);
            }
          },
        ),
        const ResponsiveSpacing(mobile: 12),
        if (_selectedAreaCode != null &&
            _selectedAreaCode!.isNotEmpty &&
            _hasSubArea)
          ModernDropdown(
            label: 'Sub Area',
            icon: Icons.map_outlined,
            items: _subAreasList.map((s) => s.name).toList(),
            value: _selectedSubArea,
            isRequired: false,
            onChanged: (String? value) {
              setState(() {
                _selectedSubArea = value;
                final sub = _subAreasList.firstWhere(
                  (s) => s.name == value,
                  orElse: () => SubAreaItem(code: '', name: '', poBox: ''),
                );
                _selectedSubAreaCode = sub.code;
                // If sub area selected, set PoBox from sub-area
                _poBoxController.text = sub.poBox;
              });
            },
          ),
        const ResponsiveSpacing(mobile: 12),
        ResponsiveTextField(
          label: 'PoBox',
          icon: Icons.mail_outline,
          controller: _poBoxController,
          isRequired: false,
          readOnly: true,
        ),
        const ResponsiveSpacing(mobile: 20),
        _buildPhotoUploadSection(),
        const ResponsiveSpacing(mobile: 20),
        _buildCertificateUploadSection(),
      ],
    );
  }

  Widget _buildPhotoUploadSection() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: const Color(0xFFF0F9FF),
        borderRadius: BorderRadius.circular(12),
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
                size: 24,
              ),
              const SizedBox(width: 12),
              Text(
                'Profile Photo',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: const Color(0xFF1E3A8A),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          FileUploadWidget(
            key: const Key('contractor_profile_photo'),
            label: 'Profile Photo',
            icon: Icons.camera_alt_outlined,
            allowedExtensions: const ['jpg', 'jpeg', 'png'],
            currentFilePath: _profilePhotoPath,
            enableServerUpload: false,
            onFileSelected: (file) {
              setState(() => _profilePhotoPath = file);
            },
          ),
          const SizedBox(height: 12),
          Text(
            'Upload a clear photo of yourself (JPG, PNG - Max 10MB)',
            style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
          ),
        ],
      ),
    );
  }

  Widget _buildCertificateUploadSection() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: const Color(0xFFF0F9FF),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFF3B82F6).withOpacity(0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.workspace_premium_outlined,
                color: const Color(0xFF3B82F6),
                size: 24,
              ),
              const SizedBox(width: 12),
              Text(
                'Contractor Certificate',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: const Color(0xFF1E3A8A),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          FileUploadWidget(
            key: const Key('contractor_certificate'),
            label: 'Contractor Certificate',
            icon: Icons.upload_file_outlined,
            allowedExtensions: const ['pdf', 'jpg', 'jpeg', 'png'],
            currentFilePath: _certificatePath,
            enableServerUpload: false,
            onFileSelected: (file) {
              setState(() => _certificatePath = file);
            },
          ),
          const SizedBox(height: 12),
          Text(
            'Upload your contractor certificate (PDF, JPG, PNG - Max 10MB)',
            style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
          ),
        ],
      ),
    );
  }

  Widget _buildEmiratesIdSection() {
    return ResponsiveSection(
      title: 'Emirates ID Verification',
      icon: Icons.credit_card_outlined,
      subtitle: 'Upload your Emirates ID for verification and auto-fill',
      children: [
        _buildIdUploadStatus(),
        const SizedBox(height: 24),
        Column(
          children: [
            _buildIdUploadCard(
              'Emirates ID Front',
              Icons.credit_card_outlined,
              'Upload front side',
              true,
            ),
            const SizedBox(height: 16),
            _buildIdUploadCard(
              'Emirates ID Back',
              Icons.credit_card_outlined,
              'Upload back side',
              false,
            ),
          ],
        ),
        const SizedBox(height: 24),
        _buildEmiratesIdForm(),
      ],
    );
  }

  Widget _buildIdUploadStatus() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [Colors.blue.shade50, Colors.blue.shade100],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.blue.shade200),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.blue.shade600,
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.info_outline,
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
                  'Emirates ID Verification',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: Colors.blue.shade800,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Upload both sides of your Emirates ID. We\'ll automatically extract and fill your personal information.',
                  style: TextStyle(fontSize: 13, color: Colors.blue.shade700),
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
    String subtitle,
    bool isFront,
  ) {
    final hasFile = isFront
        ? (_emiratesIdFrontFile != null)
        : (_emiratesIdBackFile != null);

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: hasFile ? Colors.green.shade50 : Colors.grey.shade50,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: hasFile ? Colors.green.shade300 : Colors.grey.shade300,
          width: 2,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
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
            allowedExtensions: const ['jpg', 'jpeg', 'png', 'pdf'],
            enableServerUpload: false,
            onFileSelected: (file) async {
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
          SizedBox(height: 8),
          if (isFront
              ? (_emiratesIdFrontFile != null)
              : (_emiratesIdBackFile != null))
            Align(
              alignment: Alignment.centerLeft,
              child: Text(
                'Uploaded',
                style: TextStyle(
                  color: Colors.green.shade700,
                  fontSize: 12,
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
        if (_isProcessingOcr) ...[
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.orange.shade50,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.orange.shade200),
            ),
            child: Row(
              children: [
                const CircularProgressIndicator(),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Processing Emirates ID...',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: Colors.orange.shade800,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Please wait while we extract information from your Emirates ID.',
                        style: TextStyle(
                          fontSize: 13,
                          color: Colors.orange.shade700,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),
        ],
        ResponsiveTextField(
          label: 'Emirates ID Number',
          icon: Icons.pin_outlined,
          controller: _emiratesIdController,
        ),
        const SizedBox(height: 20),
        ResponsiveTextField(
          label: 'Name of Holder',
          icon: Icons.person_outline_rounded,
          controller: _nameOfHolderController,
        ),
        const SizedBox(height: 20),
        ResponsiveRow(
          children: [
            ResponsiveTextField(
              label: 'Date of Birth',
              icon: Icons.cake_outlined,
              controller: _dobController,
            ),
            ResponsiveTextField(
              label: 'Nationality',
              icon: Icons.flag_outlined,
              controller: _nationalityController,
            ),
          ],
        ),
        const SizedBox(height: 20),
        ResponsiveRow(
          children: [
            ResponsiveTextField(
              label: 'Issue Date',
              icon: Icons.date_range_outlined,
              controller: _issueDateController,
            ),
            ResponsiveTextField(
              label: 'Expiry Date',
              icon: Icons.event_outlined,
              controller: _expiryDateController,
            ),
          ],
        ),
        const SizedBox(height: 20),
        ResponsiveRow(
          children: [
            ResponsiveTextField(
              label: 'Company Details',
              icon: Icons.business_outlined,
              controller: _companyDetailsController,
              isRequired: false,
            ),
            ResponsiveTextField(
              label: 'Occupation',
              icon: Icons.work_outline_rounded,
              controller: _occupationController,
              isRequired: false,
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildBusinessDetailsSection() {
    return ResponsiveSection(
      title: 'Business Information',
      icon: Icons.business_rounded,
      subtitle: 'Provide your business and licensing details',
      children: [
        _buildVatCertificateSection(),
        const ResponsiveSpacing(mobile: 24),
        _buildCommercialLicenseSection(),
      ],
    );
  }

  Widget _buildVatCertificateSection() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade200),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.03),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: const Color(0xFF1E3A8A).withOpacity(0.1),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.receipt_long_outlined,
                  color: Color(0xFF1E3A8A),
                  size: 20,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'VAT Certificate',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w600,
                        color: const Color(0xFF1E3A8A),
                      ),
                    ),
                    Text(
                      'Not mandatory for firms with turnover below 375,000 AED per annum',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey.shade600,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          FileUploadWidget(
            key: const Key('contractor_vat_certificate'),
            label: 'VAT Certificate Upload',
            icon: Icons.upload_file_outlined,
            allowedExtensions: const ['pdf', 'jpg', 'jpeg', 'png'],
            currentFilePath: _vatCertificatePath,
            enableServerUpload: false,
            onFileSelected: (file) async {
              if (file != null) {
                setState(() => _vatCertificatePath = file);

                final isPdf = file.toLowerCase().endsWith('.pdf');
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(
                      '${isPdf ? 'PDF' : 'Image'} uploaded. Processing...',
                    ),
                  ),
                );

                // Process the VAT certificate for OCR
                await _processVatCertificateOcr();
              }
            },
          ),
          const ResponsiveSpacing(mobile: 20),
          if (_isProcessingVatOcr) ...[
            const Center(
              child: Padding(
                padding: EdgeInsets.all(16.0),
                child: Column(
                  children: [
                    CircularProgressIndicator(),
                    SizedBox(height: 12),
                    Text('Processing VAT certificate...'),
                  ],
                ),
              ),
            ),
            const ResponsiveSpacing(mobile: 24),
          ],
          ResponsiveRow(
            children: [
              ResponsiveTextField(
                label: 'Firm Name',
                icon: Icons.business_outlined,
                controller: _firmNameController,
                isRequired: false,
              ),
              ResponsiveTextField(
                label: 'Tax Registration Number',
                icon: Icons.pin_outlined,
                controller: _taxNumberController,
                isRequired: false,
              ),
            ],
          ),
          const ResponsiveSpacing(mobile: 20),
          ResponsiveTextField(
            label: 'Registered Address',
            icon: Icons.home_outlined,
            controller: _registeredAddressController,
            isRequired: false,
          ),
          const ResponsiveSpacing(mobile: 20),
          ResponsiveDateField(
            label: 'Effective Date',
            icon: Icons.event_outlined,
            controller: _effectiveVatDateController,
            isRequired: false,
          ),
          if (_vatCertificatePath != null) ...[
            const ResponsiveSpacing(mobile: 16),
            ElevatedButton.icon(
              onPressed: () async {
                if (_vatCertificatePath != null) {
                  await _processVatCertificateOcr();
                }
              },
              icon: const Icon(Icons.refresh_rounded),
              label: const Text('Re-scan VAT Certificate'),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF1E3A8A),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildCommercialLicenseSection() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade200),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.03),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: const Color(0xFF1E3A8A).withOpacity(0.1),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.workspace_premium_outlined,
                  color: Color(0xFF1E3A8A),
                  size: 20,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Commercial License',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w600,
                        color: const Color(0xFF1E3A8A),
                      ),
                    ),
                    Text(
                      'Note: Each emirate has separate licensing authority. Different emirates require different licenses.',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey.shade600,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          FileUploadWidget(
            key: const Key('contractor_commercial_license'),
            label: 'Commercial License Upload',
            icon: Icons.upload_file_outlined,
            allowedExtensions: const ['pdf', 'jpg', 'jpeg', 'png'],
            currentFilePath: _commercialLicensePath,
            enableServerUpload: false,
            onFileSelected: (file) async {
              setState(() => _commercialLicensePath = file);
              if (file != null) {
                final isPdf = file.toLowerCase().endsWith('.pdf');
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(
                      '${isPdf ? 'PDF' : 'Image'} uploaded. Processing...',
                    ),
                  ),
                );
                await _processCommercialLicenceOcr();
              }
            },
          ),
          const ResponsiveSpacing(mobile: 20),
          if (_isProcessingCommercialLicenceOcr) ...[
            const Center(
              child: Padding(
                padding: EdgeInsets.all(16.0),
                child: Column(
                  children: [
                    CircularProgressIndicator(),
                    SizedBox(height: 12),
                    Text('Processing commercial licence...'),
                  ],
                ),
              ),
            ),
            const ResponsiveSpacing(mobile: 24),
          ],
          ResponsiveRow(
            children: [
              ResponsiveTextField(
                label: 'License Number',
                icon: Icons.pin_outlined,
                controller: _licenseNumberController,
                isRequired: false,
              ),
              ResponsiveTextField(
                label: 'Issuing Authority',
                icon: Icons.account_balance_outlined,
                controller: _issuingAuthorityController,
                isRequired: false,
              ),
            ],
          ),
          const ResponsiveSpacing(mobile: 20),
          ResponsiveRow(
            children: [
              ResponsiveTextField(
                label: 'License Type',
                icon: Icons.category_outlined,
                controller: _licenseTypeController,
                isRequired: false,
              ),
              ResponsiveTextField(
                label: 'Trade Name',
                icon: Icons.store_outlined,
                controller: _tradeNameController,
                isRequired: false,
              ),
            ],
          ),
          const ResponsiveSpacing(mobile: 20),
          ResponsiveTextField(
            label: 'Responsible Person',
            icon: Icons.person_outline_rounded,
            controller: _responsiblePersonController,
            isRequired: false,
          ),
          const ResponsiveSpacing(mobile: 20),
          ResponsiveRow(
            children: [
              ResponsiveDateField(
                label: 'Establishment Date',
                icon: Icons.event_outlined,
                controller: _establishmentDateController,
                isRequired: false,
              ),
              ResponsiveDateField(
                label: 'Expiry Date',
                icon: Icons.event_available_outlined,
                controller: _licenseExpiryDateController,
                isRequired: false,
              ),
            ],
          ),
          const ResponsiveSpacing(mobile: 20),
          ResponsiveDateField(
            label: 'Effective Registration Date',
            icon: Icons.event_outlined,
            controller: _effectiveRegDateController,
            isRequired: false,
          ),
          if (_commercialLicensePath != null) ...[
            const ResponsiveSpacing(mobile: 16),
            ElevatedButton.icon(
              onPressed: () async {
                if (_commercialLicensePath != null) {
                  await _processCommercialLicenceOcr();
                }
              },
              icon: const Icon(Icons.refresh_rounded),
              label: const Text('Re-scan Commercial License'),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF1E3A8A),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildBankDetailsSection() {
    return ResponsiveSection(
      title: 'Bank Details',
      icon: Icons.account_balance_outlined,
      subtitle: 'Optional but recommended for payments',
      isOptional: true,
      children: [
        ResponsiveInfoCard(
          icon: Icons.info_outline_rounded,
          title: 'Secure Bank Information',
          subtitle:
              'Your bank details are encrypted and securely stored. Upload a bank document to auto-fill details.',
          backgroundColor: Colors.grey.shade50,
          iconColor: Colors.grey.shade600,
          textColor: Colors.grey.shade700,
        ),
        const ResponsiveSpacing(mobile: 24),
        FileUploadWidget(
          key: const Key('contractor_bank_document'),
          label: 'Bank Document (Optional)',
          icon: Icons.attach_file_outlined,
          allowedExtensions: const ['jpg', 'jpeg', 'png', 'pdf'],
          currentFilePath: _bankDocumentPath,
          enableServerUpload: false,
          onFileSelected: (file) async {
            if (file != null) {
              setState(() {
                _bankDocumentPath = file;
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
        const ResponsiveSpacing(mobile: 24),
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
          const ResponsiveSpacing(mobile: 24),
        ],
        ResponsiveRow(
          children: [
            ResponsiveTextField(
              label: 'Account Holder Name',
              icon: Icons.person_outline_rounded,
              controller: _accountHolderController,
              isRequired: false,
            ),
            ResponsiveTextField(
              label: 'IBAN Number',
              icon: Icons.account_balance_wallet_outlined,
              controller: _ibanController,
              isRequired: false,
            ),
          ],
        ),
        const ResponsiveSpacing(mobile: 20),
        ResponsiveRow(
          children: [
            ResponsiveTextField(
              label: 'Bank Name',
              icon: Icons.business_outlined,
              controller: _bankNameController,
              isRequired: false,
            ),
            ResponsiveTextField(
              label: 'Branch Name',
              icon: Icons.location_on_outlined,
              controller: _branchNameController,
              isRequired: false,
            ),
          ],
        ),
        const ResponsiveSpacing(mobile: 20),
        ResponsiveTextField(
          label: 'Bank Address',
          icon: Icons.location_city_outlined,
          controller: _bankAddressController,
          isRequired: false,
        ),
        if (_bankDocumentPath != null) ...[
          const ResponsiveSpacing(mobile: 16),
          ElevatedButton.icon(
            onPressed: () async {
              if (_bankDocumentPath != null) {
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
                'Fill in all required fields marked with *. Upload your documents to auto-fill information. Upload bank documents to auto-fill bank details. Bank details are optional but recommended for faster payments.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: Colors.grey.shade600,
                  fontSize: 15,
                  height: 1.5,
                ),
              ),
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () => Navigator.of(context).pop(),
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
        '[ContractorRegistration] Using Hybrid OCR for Emirates ID (Gemini with ML Kit fallback)',
      );

      final result = await _hybridOcrService.extractEmiratesIdFields(
        frontImagePath: _emiratesIdFrontFile!,
        backImagePath: _emiratesIdBackFile!,
      );

      _updateFieldsFromResult(result);

      if (mounted) {
        AppSnackBar.showSuccess(context, 'Emirates ID fields autofilled');
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

  // OCR processing for bank document using Gemini first, ML Kit as fallback
  Future<void> _processBankDocumentOcr() async {
    if (_bankDocumentPath == null) return;

    setState(() {
      _isProcessingBankOcr = true;
    });

    try {
      debugPrint(
        '[ContractorRegistration] Using Hybrid OCR for Bank Details (Gemini with ML Kit fallback)',
      );

      final result = await _hybridOcrService.extractBankDetailsFields(
        bankDocumentPath: _bankDocumentPath!,
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

  // OCR processing for VAT certificate using Hybrid service (Gemini with ML Kit fallback)
  Future<void> _processVatCertificateOcr() async {
    if (_vatCertificatePath == null) return;

    setState(() {
      _isProcessingVatOcr = true;
    });

    try {
      debugPrint(
        '[ContractorRegistration] Using Hybrid OCR for VAT Certificate (Gemini with ML Kit fallback)',
      );

      final result = await _hybridOcrService.extractVatCertificateFields(
        vatCertificatePath: _vatCertificatePath!,
      );

      _updateVatFieldsFromResult(result);

      if (mounted) {
        AppSnackBar.showSuccess(
          context,
          'VAT certificate details autofilled with AI',
        );
      }
    } catch (e) {
      debugPrint('Error in VAT Certificate OCR: $e');
      if (mounted) {
        AppSnackBar.showError(
          context,
          'Error processing VAT certificate: ${e.toString()}',
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isProcessingVatOcr = false;
        });
      }
    }
  }

  // OCR processing for Commercial Licence with retry mechanism
  Future<void> _processCommercialLicenceOcr() async {
    if (_commercialLicensePath == null) return;

    setState(() => _isProcessingCommercialLicenceOcr = true);

    try {
      debugPrint(
        '[ContractorRegistration] Using Hybrid OCR for Commercial License (Gemini with ML Kit fallback)',
      );

      final result = await _hybridOcrService.extractCommercialLicenseFields(
        commercialLicensePath: _commercialLicensePath!,
      );

      // Update form fields with extracted data
      setState(() {
        if (result['licenseNumber'] != null &&
            result['licenseNumber']!.isNotEmpty) {
          _licenseNumberController.text = result['licenseNumber']!;
        }
        if (result['issuingAuthority'] != null &&
            result['issuingAuthority']!.isNotEmpty) {
          _issuingAuthorityController.text = result['issuingAuthority']!;
        }
        if (result['licenseType'] != null &&
            result['licenseType']!.isNotEmpty) {
          _licenseTypeController.text = result['licenseType']!;
        }
        if (result['tradeName'] != null && result['tradeName']!.isNotEmpty) {
          _tradeNameController.text = result['tradeName']!;
        }
        if (result['responsiblePerson'] != null &&
            result['responsiblePerson']!.isNotEmpty) {
          _responsiblePersonController.text = result['responsiblePerson']!;
        }
        if (result['establishmentDate'] != null &&
            result['establishmentDate']!.isNotEmpty) {
          _establishmentDateController.text = result['establishmentDate']!;
        }
        if (result['expiryDate'] != null && result['expiryDate']!.isNotEmpty) {
          _licenseExpiryDateController.text = result['expiryDate']!;
        }
        if (result['effectiveDate'] != null &&
            result['effectiveDate']!.isNotEmpty) {
          _effectiveRegDateController.text = result['effectiveDate']!;
        }
        if (result['licenseAddress'] != null &&
            result['licenseAddress']!.isNotEmpty) {
          _tradeLicenseController.text = result['licenseAddress']!;
        }
      });

      if (mounted) {
        AppSnackBar.showSuccess(
          context,
          'Commercial license processed successfully with AI',
        );
      }
    } catch (e) {
      debugPrint('Error in Commercial License OCR: $e');
      if (mounted) {
        AppSnackBar.showError(
          context,
          'Error processing commercial license: ${e.toString()}',
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isProcessingCommercialLicenceOcr = false);
      }
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

  // Helper to update VAT form fields from parsed results
  void _updateVatFieldsFromResult(Map<String, String?> result) {
    if (result['firmName'] != null && result['firmName']!.isNotEmpty) {
      _firmNameController.text = result['firmName']!;
    }

    if (result['taxNumber'] != null && result['taxNumber']!.isNotEmpty) {
      _taxNumberController.text = result['taxNumber']!;
    }

    if (result['registeredAddress'] != null &&
        result['registeredAddress']!.isNotEmpty) {
      _registeredAddressController.text = result['registeredAddress']!;
    }

    if (result['effectiveDate'] != null &&
        result['effectiveDate']!.isNotEmpty) {
      _effectiveVatDateController.text = result['effectiveDate']!;
    }
  }

  // Helper to update commercial licence form fields from parsed results
  // ignore: unused_element
  void _updateCommercialLicenceFieldsFromResult(Map<String, dynamic> result) {
    final licenceNumber = result['licenceNumber'];
    if (licenceNumber != null && licenceNumber.toString().isNotEmpty) {
      _licenseNumberController.text = licenceNumber.toString();
    }
    if (result['companyName'] != null && result['companyName']!.isNotEmpty) {
      _tradeNameController.text = result['companyName']!;
    }
    if (result['issueDate'] != null && result['issueDate']!.isNotEmpty) {
      _establishmentDateController.text = result['issueDate']!;
    }
    if (result['expiryDate'] != null && result['expiryDate']!.isNotEmpty) {
      _licenseExpiryDateController.text = result['expiryDate']!;
    }
    // Assuming the first partner/manager is the responsible person
    if (result['partners'] != null && result['partners']!.isNotEmpty) {
      _responsiblePersonController.text = result['partners']!
          .split(',')
          .first
          .trim();
    } else if (result['ownerName'] != null && result['ownerName']!.isNotEmpty) {
      _responsiblePersonController.text = result['ownerName']!;
    }
    // Legal Type (e.g., LLC) maps well to License Type field
    if (result['legalType'] != null && result['legalType']!.isNotEmpty) {
      _licenseTypeController.text = result['legalType']!;
    }
    // The issuing authority is not explicitly extracted, but can be inferred or left blank.
    // For KDU, 'Trakhees' is the authority, but this is not generic.
    // We will leave _issuingAuthorityController for manual entry.
  }

  /// Upload all selected files to server before registration
  /// Returns [true] if all files uploaded successfully, [false] if any failed or none selected
  Future<bool> _uploadFilesToServer() async {
    print('=== Starting contractor file upload to server ===');

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
      if (_certificatePath != null && _certificatePath!.isNotEmpty)
        DocumentType.contractorCertificate: _certificatePath!,
      if (_vatCertificatePath != null && _vatCertificatePath!.isNotEmpty)
        DocumentType.vatCertificate: _vatCertificatePath!,
      if (_commercialLicensePath != null && _commercialLicensePath!.isNotEmpty)
        DocumentType.commercialLicense: _commercialLicensePath!,
      if (_bankDocumentPath != null && _bankDocumentPath!.isNotEmpty)
        DocumentType.bankDocument: _bankDocumentPath!,
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
                return ContractorService.validateMobileNumber(value);
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

// ==========================================================
// START: Commercial Licence OCR Service
// ==========================================================

class CommercialLicenceOcrService {
  // Helper to check if a line is a label (contains only known field labels)
  bool _isLabelLine(String line) {
    final labels = [
      'license no',
      'licence no',
      'رقم الرخصة',
      'company name',
      'اسم الشركة',
      'business name',
      'الاسم التجارى',
      'issue date',
      'تاريخ الصدار',
      'expiry date',
      'تاريخ الانتهاء',
      'activity',
      'legal type',
      'owner name',
      'address',
      'po box',
      'phone',
      'mobile',
      'fax',
      'email',
      'partners',
      'dunsnumber',
      'dccinumber',
      'registerno',
      'mainlicenseno',
      'manager',
      'managerlo',
      'manager name',
      'role',
      'role / dal',
      'share',
      'share /aal',
      'nationality',
      'name',
      'licensing department',
      'economy and tourism',
      'ports, customs and free zone corporation',
      'license details',
      'license partners',
    ];
    final cleaned = line
        .replaceAll(RegExp(r'[^a-zA-Z0-9\u0600-\u06FF ]'), '')
        .trim();
    return labels.any((label) => cleaned == label || cleaned.startsWith(label));
  }

  // OCR processing with retry mechanism
  Future<void> processCommercialLicenceOcrWithRetry({
    required String licencePath,
    required Function(Map<String, dynamic>) onFieldsExtracted,
    required Function(String) onError,
    int maxRetries = 3,
  }) async {
    int attempts = 0;
    bool success = false;

    while (attempts < maxRetries && !success) {
      try {
        await processCommercialLicenceOcr(
          licencePath: licencePath,
          onFieldsExtracted: onFieldsExtracted,
        );
        success = true;
      } catch (e) {
        attempts++;
        if (attempts >= maxRetries) {
          onError('OCR failed after $maxRetries attempts: ${e.toString()}');
        } else {
          await Future.delayed(const Duration(seconds: 1));
        }
      }
    }
  }

  // OCR processing: runs text recognition on the commercial licence
  Future<void> processCommercialLicenceOcr({
    required String licencePath,
    required Function(Map<String, dynamic>) onFieldsExtracted,
  }) async {
    final extractedText = await processFile(licencePath);
    print('Commercial Licence OCR Text: $extractedText');
    final licenceDetails = parseCommercialLicenceDetails(extractedText);
    print('Parsed Commercial Licence Details: $licenceDetails');
    onFieldsExtracted(licenceDetails);
  }

  // Process a file (image or PDF) and return extracted text
  Future<String> processFile(String filePath) async {
    final file = File(filePath);
    final extension = file.path.toLowerCase().split('.').last;
    if (extension == 'pdf') {
      return await processPdf(file);
    } else {
      return await recognizeText(file);
    }
  }

  // Process PDF file: convert to images and extract text
  Future<String> processPdf(File pdfFile) async {
    try {
      final document = await PdfDocument.openFile(pdfFile.path);
      final allText = StringBuffer();
      for (int i = 1; i <= document.pagesCount; i++) {
        final page = await document.getPage(i);
        final pageImage = await page.render(
          width: page.width * 2,
          height: page.height * 2,
          format: PdfPageImageFormat.jpeg,
          backgroundColor: '#ffffff',
        );
        if (pageImage == null) continue;

        final tempDir = await getTemporaryDirectory();
        final tempImagePath =
            '${tempDir.path}/temp_commercial_licence_page_$i.jpg';
        final tempImageFile = File(tempImagePath);
        await tempImageFile.writeAsBytes(pageImage.bytes);

        final pageText = await recognizeText(tempImageFile);
        allText.writeln(pageText);

        await tempImageFile.delete();
        await page.close();
      }
      await document.close();
      return allText.toString();
    } catch (e) {
      print('Error processing PDF: $e');
      throw Exception('Failed to process PDF: ${e.toString()}');
    }
  }

  Future<String> recognizeText(File imageFile) async {
    final processedImage = await preprocessImage(imageFile);
    final inputImage = InputImage.fromFilePath(processedImage.path);
    final textRecognizer = TextRecognizer(script: TextRecognitionScript.latin);
    try {
      final recognisedText = await textRecognizer.processImage(inputImage);
      final buffer = StringBuffer();
      for (final block in recognisedText.blocks) {
        for (final line in block.lines) {
          buffer.writeln(line.text);
        }
        buffer.writeln();
      }
      return buffer.toString();
    } finally {
      textRecognizer.close();
    }
  }

  // Placeholder for image preprocessing
  Future<File> preprocessImage(File imageFile) async {
    // Optionally enhance image before OCR
    return imageFile;
  }

  // Parse commercial licence details from extracted text
  Map<String, dynamic> parseCommercialLicenceDetails(String text) {
    final result = <String, dynamic>{
      'companyName': null,
      'licenceNumber': null,
      'issueDate': null,
      'expiryDate': null,
      'activity': null,
      'legalType': null,
      'ownerName': null,
      'address': null,
      'poBox': null,
      'phone': null,
      'mobile': null,
      'fax': null,
      'email': null,
      'partners': null,
      'dunsNumber': null,
      'dcciNumber': null,
      'registerNo': null,
      'mainLicenseNo': null,
    };

    final lines = text
        .split('\n')
        .map((s) => s.trim())
        .where((s) => s.isNotEmpty)
        .toList();

    for (int i = 0; i < lines.length; i++) {
      final line = lines[i];
      final lower = line.toLowerCase();

      // Company Name
      if ((lower.contains('company name') ||
              lower.contains('اسم الشركة') ||
              lower.contains('business name') ||
              lower.contains('الاسم التجارى')) &&
          result['companyName'] == null) {
        if (i + 1 < lines.length) {
          final next = lines[i + 1].toLowerCase();
          if (!next.contains('company name') &&
              !next.contains('business name') &&
              !_isLabelLine(next)) {
            result['companyName'] = lines[i + 1];
            continue;
          }
        }
        final value = _extractValue(line);
        if (value != null && !_isLabelLine(value.toLowerCase())) {
          result['companyName'] = value;
        }
      }
      // License Number
      else if ((lower.contains('license no') ||
              lower.contains('licence no') ||
              lower.contains('رقم الرخصة')) &&
          result['licenceNumber'] == null) {
        String? value;
        if (i + 1 < lines.length) {
          final next = lines[i + 1].toLowerCase();
          if (_isNumeric(lines[i + 1]) && !_isLabelLine(next)) {
            value = lines[i + 1];
          }
        }
        value ??= _extractValue(line);
        if (value != null &&
            _isNumeric(value) &&
            !_isLabelLine(value.toLowerCase())) {
          result['licenceNumber'] = int.tryParse(value);
        } else if (value != null && !_isLabelLine(value.toLowerCase())) {
          result['licenceNumber'] = value;
        }
      }
      // Issue Date
      else if ((lower.contains('issue date') ||
              lower.contains('تاريخ الصدار')) &&
          result['issueDate'] == null) {
        if (i + 1 < lines.length) {
          final next = lines[i + 1].toLowerCase();
          if (_isDate(lines[i + 1]) && !_isLabelLine(next)) {
            result['issueDate'] = lines[i + 1];
            continue;
          }
        }
        final value = _extractValue(line);
        if (value != null &&
            _isDate(value) &&
            !_isLabelLine(value.toLowerCase())) {
          result['issueDate'] = value;
        }
      }
      // Legal Type
      else if ((lower.contains('legal type') ||
              lower.contains('الشكل القانوني')) &&
          result['legalType'] == null) {
        if (i + 1 < lines.length &&
            !lines[i + 1].toLowerCase().contains('legal type')) {
          result['legalType'] = lines[i + 1];
        } else {
          result['legalType'] = _extractValue(line);
        }
      }
      // Activities
      else if ((lower.contains('license activities') ||
              lower.contains('نشاط الرخصة التجارية')) &&
          result['activity'] == null) {
        final activities = <String>[];
        for (int j = i + 1; j < lines.length; j++) {
          if (lines[j].toLowerCase().contains('email') ||
              lines[j].toLowerCase().contains('address') ||
              lines[j].toLowerCase().contains('phone') ||
              lines[j].toLowerCase().contains('mobile') ||
              lines[j].toLowerCase().contains('fax') ||
              lines[j].toLowerCase().contains('p.o. box') ||
              lines[j].toLowerCase().contains('صندوق بريد') ||
              lines[j].toLowerCase().contains('العنوان') ||
              lines[j].toLowerCase().contains('partners') ||
              lines[j].toLowerCase().contains('الملحظات')) {
            break;
          }
          if (lines[j].isNotEmpty) {
            activities.add(lines[j]);
          }
        }
        result['activity'] = activities.join(', ');
      }
      // Address
      else if ((lower.contains('address') || lower.contains('العنوان')) &&
          result['address'] == null) {
        if (i + 1 < lines.length &&
            !lines[i + 1].toLowerCase().contains('address')) {
          result['address'] = lines[i + 1];
        } else {
          result['address'] = _extractValue(line);
        }
      }
      // PO Box
      else if ((lower.contains('p.o. box') || lower.contains('صندوق بريد')) &&
          result['poBox'] == null) {
        if (i + 1 < lines.length && _isNumeric(lines[i + 1])) {
          result['poBox'] = lines[i + 1];
        } else {
          result['poBox'] = _extractValue(line);
        }
      }
      // Phone
      else if ((lower.contains('phone') || lower.contains('تليفون')) &&
          result['phone'] == null &&
          !lower.contains('mobile')) {
        if (i + 1 < lines.length && _isPhoneNumber(lines[i + 1])) {
          result['phone'] = lines[i + 1];
        } else {
          result['phone'] = _extractValue(line);
        }
      }
      // Mobile
      else if ((lower.contains('mobile') || lower.contains('هاتف متحرك')) &&
          result['mobile'] == null) {
        if (i + 1 < lines.length && _isPhoneNumber(lines[i + 1])) {
          result['mobile'] = lines[i + 1];
        } else {
          result['mobile'] = _extractValue(line);
        }
      }
      // Fax
      else if ((lower.contains('fax') || lower.contains('فاكس')) &&
          result['fax'] == null) {
        if (i + 1 < lines.length && _isPhoneNumber(lines[i + 1])) {
          result['fax'] = lines[i + 1];
        } else {
          result['fax'] = _extractValue(line);
        }
      }
      // Email
      else if ((lower.contains('email') || lower.contains('البريد اللكترون')) &&
          result['email'] == null) {
        if (i + 1 < lines.length && _isEmail(lines[i + 1])) {
          result['email'] = lines[i + 1];
        } else {
          result['email'] = _extractValue(line);
        }
      }
      // DUNS Number
      else if ((lower.contains('d-u-n-s') || lower.contains('الرقم العالمي')) &&
          result['dunsNumber'] == null) {
        if (i + 1 < lines.length && _isNumeric(lines[i + 1])) {
          result['dunsNumber'] = lines[i + 1];
        } else {
          result['dunsNumber'] = _extractValue(line);
        }
      }
      // DCCI Number
      else if ((lower.contains('dcci no') || lower.contains('عضوية الغرفة')) &&
          result['dcciNumber'] == null) {
        if (i + 1 < lines.length && _isNumeric(lines[i + 1])) {
          result['dcciNumber'] = lines[i + 1];
        } else {
          result['dcciNumber'] = _extractValue(line);
        }
      }
      // Register Number
      else if ((lower.contains('register no') ||
              lower.contains('رقم السجل التجارى')) &&
          result['registerNo'] == null) {
        if (i + 1 < lines.length && _isNumeric(lines[i + 1])) {
          result['registerNo'] = lines[i + 1];
        } else {
          result['registerNo'] = _extractValue(line);
        }
      }
      // Main License Number
      else if ((lower.contains('main license no') ||
              lower.contains('رقم الرخصة الم')) &&
          result['mainLicenseNo'] == null) {
        if (i + 1 < lines.length && _isNumeric(lines[i + 1])) {
          result['mainLicenseNo'] = lines[i + 1];
        } else {
          result['mainLicenseNo'] = _extractValue(line);
        }
      }
      // Partners
      else if ((lower.contains('partners') || lower.contains('اصحاب الرخصة')) &&
          result['partners'] == null) {
        final partners = <String>[];
        for (int j = i + 1; j < lines.length; j++) {
          if (lines[j].toLowerCase().contains('remarks') ||
              lines[j].toLowerCase().contains('الملحظات')) {
            break;
          }
          if (lines[j].isNotEmpty) {
            partners.add(lines[j]);
          }
        }
        result['partners'] = partners.join(', ');
      }
    }

    return result;
  }

  // Helper to extract value after a colon or keyword
  String? _extractValue(String text) {
    if (text.contains(':')) {
      return text.split(':').skip(1).join(':').trim();
    }
    return text.trim();
  }

  // Helper to check if a string is numeric
  bool _isNumeric(String? s) {
    if (s == null || s.isEmpty) {
      return false;
    }
    return double.tryParse(s) != null;
  }

  // Helper to check if a string is a date
  bool _isDate(String? s) {
    if (s == null || s.isEmpty) {
      return false;
    }
    // Check for common date formats
    return RegExp(r'^\d{1,2}[/-]\d{1,2}[/-]\d{2,4}$').hasMatch(s);
  }

  // Helper to check if a line is a label (contains only known field labels)

  // Helper to extract value after a colon or keyword
  bool _isPhoneNumber(String? s) {
    if (s == null || s.isEmpty) {
      return false;
    }
    // Check for common phone number formats
    return RegExp(r'^[\d\s\-\+\(\)]+$').hasMatch(s) && s.length >= 7;
  }

  // Helper to check if a string is an email
  bool _isEmail(String? s) {
    if (s == null || s.isEmpty) {
      return false;
    }
    return RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$').hasMatch(s);
  }

  void dispose() {
    // Clean up any resources if necessary
  }
}
