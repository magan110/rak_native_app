import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:go_router/go_router.dart';
import 'dart:io';
import 'package:google_mlkit_text_recognition/google_mlkit_text_recognition.dart';
import '../../../../../shared/widgets/custom_back_button.dart';
import '../../../../../shared/widgets/file_upload_widget.dart';
import '../../../../../shared/widgets/modern_dropdown.dart';
import '../../../../../shared/widgets/responsive_widgets.dart';

class PainterRegistrationScreen extends StatefulWidget {
  const PainterRegistrationScreen({super.key});

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

  // Current step state (1 = Personal, 2 = Emirates ID, 3 = Bank)
  int _currentStep = 1;

  // Form controllers
  final TextEditingController _firstNameController = TextEditingController();
  final TextEditingController _middleNameController = TextEditingController();
  final TextEditingController _lastNameController = TextEditingController();
  final TextEditingController _mobileController = TextEditingController();
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

  // File paths for Emirates ID images
  String? _emiratesIdFrontFile;
  String? _emiratesIdBackFile;

  // OCR processing flag
  bool _isProcessingOcr = false;

  String? _selectedEmirate;

  @override
  void initState() {
    super.initState();
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
  }

  @override
  void dispose() {
    _mainController.dispose();
    _fabController.dispose();
    _firstNameController.dispose();
    _middleNameController.dispose();
    _lastNameController.dispose();
    _mobileController.dispose();
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
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      body: CustomScrollView(
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
              _buildProgressStep(1, 'Personal', _currentStep >= 1),
              _buildProgressLine(_currentStep >= 2),
              _buildProgressStep(2, 'Emirates ID', _currentStep >= 2),
              _buildProgressLine(_currentStep >= 3),
              _buildProgressStep(3, 'Bank', _currentStep >= 3),
            ],
          ),
          SizedBox(height: 12.h),
          Text(
            'Step $_currentStep of 3: ${_getStepTitle()}',
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
        return 'Personal Details';
      case 2:
        return 'Emirates ID Verification';
      case 3:
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
        currentSection = _buildPersonalDetailsSection();
        break;
      case 2:
        currentSection = _buildEmiratesIdSection();
        break;
      case 3:
        currentSection = _buildBankDetailsSection();
        break;
      default:
        currentSection = _buildPersonalDetailsSection();
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
              if (_currentStep < 3) {
                setState(() {
                  _currentStep++;
                });
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
                  _currentStep < 3 ? 'Next' : 'Submit Registration',
                  style: TextStyle(
                    fontSize: 16.sp,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                SizedBox(width: 8.w),
                Icon(
                  _currentStep < 3
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
    // TODO: Implement form submission
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.check_circle, color: Colors.white),
            const SizedBox(width: 12),
            const Expanded(
              child: Text(
                'Registration submitted successfully!',
                style: TextStyle(color: Colors.white),
              ),
            ),
          ],
        ),
        backgroundColor: const Color(0xFF10B981),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
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
            ResponsiveTextField(
              label: 'Mobile Number',
              icon: Icons.phone_outlined,
              controller: _mobileController,
              isPhone: true,
            ),
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
          items: const [
            'Dubai',
            'Abu Dhabi',
            'Sharjah',
            'Ajman',
            'Umm Al Quwain',
            'Ras Al Khaimah',
            'Fujairah',
          ],
          value: _selectedEmirate,
          onChanged: (String? value) {
            setState(() {
              _selectedEmirate = value;
            });
          },
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
            onFileSelected: (file) {
              // Handle selected profile photo (e.g. store file or update state)
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
                  if (_emiratesIdFrontFile != null && _emiratesIdBackFile != null) {
                    await _processEmiratesIdOcrWithRetry();
                  } else {
                    if (mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Please upload both front and back images first')),
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
                  'Make sure all details are clearly visible and not blurry',
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

  Widget _buildIdUploadCard(String title, IconData icon, String subtitle, {required bool isFront}) {
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
            allowedExtensions: const ['jpg', 'jpeg', 'png'],
            onFileSelected: (file) async {
              // Store selected file path for later verification
              if (file != null) {
                setState(() {
                  if (isFront) {
                    _emiratesIdFrontFile = file;
                  } else {
                    _emiratesIdBackFile = file;
                  }
                });
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('Image uploaded')),
                );
                // If both sides uploaded, run OCR to autofill fields
                if (_emiratesIdFrontFile != null && _emiratesIdBackFile != null) {
                  await _processEmiratesIdOcrWithRetry();
                }
              }
            },
          ),
          SizedBox(height: 8.h),
          if (isFront ? (_emiratesIdFrontFile != null) : (_emiratesIdBackFile != null))
            Align(
              alignment: Alignment.centerLeft,
              child: Text(
                'Uploaded',
                style: TextStyle(color: Colors.green.shade700, fontSize: 12.sp, fontWeight: FontWeight.w600),
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
                      'Your bank details are encrypted and securely stored',
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
          onFileSelected: (file) {
            // Handle selected bank document file (no-op for now)
          },
        ),
        const SizedBox(height: 24),
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
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 16,
        ),
      ),
      keyboardType: isPhone ? TextInputType.phone : TextInputType.text,
      inputFormatters: isPhone
          ? [FilteringTextInputFormatter.digitsOnly]
          : null,
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
                'Fill in all required fields marked with *. Upload your Emirates ID to auto-fill information. Bank details are optional but recommended for faster payments.',
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

  // OCR processing with retry mechanism
  Future<void> _processEmiratesIdOcrWithRetry({int maxRetries = 3}) async {
    int attempts = 0;
    bool success = false;
    
    while (attempts < maxRetries && !success) {
      try {
        await _processEmiratesIdOcr();
        success = true;
      } catch (e) {
        attempts++;
        if (attempts >= maxRetries) {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text('OCR failed after $maxRetries attempts')),
            );
          }
        } else {
          // Wait a bit before retrying
          await Future.delayed(const Duration(seconds: 1));
        }
      }
    }
  }

  // OCR processing: runs text recognition on both images and updates controllers
  Future<void> _processEmiratesIdOcr() async {
    if (_isProcessingOcr) return;
    if (_emiratesIdFrontFile == null || _emiratesIdBackFile == null) return;

    setState(() {
      _isProcessingOcr = true;
    });

    try {
      final frontText = await _recognizeText(File(_emiratesIdFrontFile!));
      final backText = await _recognizeText(File(_emiratesIdBackFile!));

      // Debug logging
      print('Front OCR Text: $frontText');
      print('Back OCR Text: $backText');

      // First try MRZ parsing from back (most reliable)
      final mrzResult = _parseMrz(backText);
      print('MRZ Result: $mrzResult');
      if (mrzResult != null) {
        _updateFieldsFromResult(mrzResult);
      }

      // Then try to parse front image for readable fields
      final frontFields = _parseFrontText(frontText);
      print('Front Fields: $frontFields');
      _updateFieldsFromResult(frontFields, overwrite: mrzResult == null);

      // Parse back image for employer, occupation, and other fields
      final backFields = _parseBackText(backText);
      print('Back Fields: $backFields');
      _updateFieldsFromResult(backFields, overwrite: true);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Emirates ID fields autofilled')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('OCR failed: ${e.toString()}')),
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

  Future<String> _recognizeText(File imageFile) async {
    // Preprocess image for better OCR
    final processedImage = await _preprocessImage(imageFile);
    final inputImage = InputImage.fromFilePath(processedImage.path);
    final textRecognizer = TextRecognizer();
    
    try {
      final recognisedText = await textRecognizer.processImage(inputImage);
      return recognisedText.text;
    } finally {
      await textRecognizer.close();
    }
  }

  // Placeholder for image preprocessing
  Future<File> _preprocessImage(File imageFile) async {
    // You can use image package to enhance the image before OCR
    // For example: increase contrast, convert to grayscale, etc.
    // This is just a placeholder for the actual implementation
    return imageFile;
  }

  // Parse MRZ style text from back of Emirates ID
  Map<String, String?>? _parseMrz(String text) {
    final lines = text.split('\n').map((s) => s.trim()).where((s) => s.isNotEmpty).toList();
    if (lines.isEmpty) return null;

    // Emirates ID MRZ typically has 3 lines at the bottom
    // Look for lines with the pattern ID<ARE<...>
    final mrzLines = lines.where((l) => 
      l.contains('ID') && l.contains('ARE') && l.contains('<')
    ).toList();
    
    if (mrzLines.isEmpty) return null;
    
    // Get the last 3 lines which should be the MRZ
    final mrzStartIndex = lines.indexOf(mrzLines.first);
    if (mrzStartIndex + 2 >= lines.length) return null;
    
    final line1 = lines[mrzStartIndex];
    final line2 = lines[mrzStartIndex + 1];
    final line3 = lines[mrzStartIndex + 2];
    
    final result = <String, String?>{
      'id': null,
      'name': null,
      'nationality': null,
      'dob': null,
      'expiry': null,
    };
    
    // Line 1: ID<ARE<LASTNAME<<FIRSTNAME<MIDDLENAME
    if (line1.contains('ID') && line1.contains('ARE')) {
      // Extract ID number from line 2
      final idMatch = RegExp(r'([0-9]{3}-[0-9]{4}-[0-9]{7}-[0-9])').firstMatch(line2);
      if (idMatch != null) {
        result['id'] = idMatch.group(0);
      }
      
      // Extract name from line 1
      final nameParts = line1.split('<').where((p) => p.isNotEmpty).toList();
      if (nameParts.length >= 3) {
        // Emirates ID format: ID<ARE<LASTNAME<<FIRSTNAME<MIDDLENAME
        final lastName = nameParts[2].trim();
        final firstName = nameParts.length > 3 ? nameParts[3].trim() : '';
        final middleName = nameParts.length > 4 ? nameParts[4].trim() : '';
        
        result['name'] = '$firstName $middleName $lastName'.trim();
      }
      
      // Extract dates from line 3
      // Format: YYYYMMDD<<SEX<EXPIRY<<<<<
      final dobMatch = RegExp(r'([0-9]{7})').firstMatch(line3);
      if (dobMatch != null) {
        final dob = dobMatch.group(0)!;
        if (dob.length == 7) {
          // Format: YYMMDDc where c is check digit
          final yy = int.parse(dob.substring(0, 2));
          final mm = dob.substring(2, 4);
          final dd = dob.substring(4, 6);
          final year = (yy >= 0 && yy <= 30) ? (2000 + yy) : (1900 + yy);
          result['dob'] = '$dd/$mm/$year';
        }
      }
      
      // Extract expiry date
      final expiryMatch = RegExp(r'([0-9]{7})').allMatches(line3).toList();
      if (expiryMatch.length >= 2) {
        final expiry = expiryMatch[1].group(0)!;
        if (expiry.length == 7) {
          final yy = int.parse(expiry.substring(0, 2));
          final mm = expiry.substring(2, 4);
          final dd = expiry.substring(4, 6);
          final year = (yy >= 0 && yy <= 30) ? (2000 + yy) : (1900 + yy);
          result['expiry'] = '$dd/$mm/$year';
        }
      }
      
      // Nationality is ARE for UAE
      result['nationality'] = 'United Arab Emirates';
    }
    
    return result;
  }

  // Heuristics for front side text to find labeled fields
  Map<String, String?> _parseFrontText(String text) {
    final result = <String, String?>{
      'id': null,
      'name': null,
      'dob': null,
      'nationality': null,
      'issue': null,
      'expiry': null,
    };

    final lines = text.split('\n').map((s) => s.trim()).where((s) => s.isNotEmpty).toList();
    
    // Emirates ID has specific field labels
    for (int i = 0; i < lines.length; i++) {
      final line = lines[i];
      final lower = line.toLowerCase();

      // ID number with dashes
      final idPattern = RegExp(r'[0-9]{3}-[0-9]{4}-[0-9]{7}-[0-9]');
      final idMatch = idPattern.firstMatch(line);
      if (idMatch != null) {
        result['id'] = idMatch.group(0);
        continue;
      }

      // Check for field labels in both English and Arabic
      if (lower.contains('id number') || lower.contains('رقم الهوية')) {
        // ID might be on the same line or next line
        if (idMatch == null && i + 1 < lines.length) {
          final nextIdMatch = idPattern.firstMatch(lines[i + 1]);
          if (nextIdMatch != null) {
            result['id'] = nextIdMatch.group(0);
          }
        }
        continue;
      }

      // Name field
      if (lower.contains('name') || lower.contains('الاسم')) {
        if (line.contains(':')) {
          final parts = line.split(':');
          if (parts.length > 1) result['name'] = parts[1].trim();
        } else if (i + 1 < lines.length) {
          result['name'] = lines[i + 1];
        }
        continue;
      }

      // Date of birth
      if (lower.contains('date of birth') || lower.contains('تاريخ الميلاد')) {
        if (line.contains(':')) {
          final parts = line.split(':');
          if (parts.length > 1) {
            result['dob'] = _normalizeDate(parts[1].trim());
          }
        } else if (i + 1 < lines.length) {
          result['dob'] = _normalizeDate(lines[i + 1]);
        }
        continue;
      }

      // Nationality
      if (lower.contains('nationality') || lower.contains('الجنسية')) {
        String? natValue;
        if (line.contains(':')) {
          final parts = line.split(':');
          if (parts.length > 1) natValue = parts[1].trim();
        } else if (i + 1 < lines.length) {
          natValue = lines[i + 1].trim();
        }
        // Fix: If nationality contains 'india' (case-insensitive), set to 'India'
        if (natValue != null && natValue.toLowerCase().contains('india')) {
          result['nationality'] = 'India';
        } else if (natValue != null && natValue.isNotEmpty) {
          result['nationality'] = natValue;
        }
        continue;
      }

      // Issue date (ensure not to overwrite nationality)
      if ((lower.contains('issue') || lower.contains('إصدار')) && !lower.contains('nationality')) {
        if (line.contains(':')) {
          final parts = line.split(':');
          if (parts.length > 1) {
            result['issue'] = _normalizeDate(parts[1].trim());
          }
        } else if (i + 1 < lines.length) {
          result['issue'] = _normalizeDate(lines[i + 1]);
        }
        continue;
      }

      // Expiry date
      if (lower.contains('expiry') || lower.contains('انتهاء')) {
        if (line.contains(':')) {
          final parts = line.split(':');
          if (parts.length > 1) {
            result['expiry'] = _normalizeDate(parts[1].trim());
          }
        } else if (i + 1 < lines.length) {
          result['expiry'] = _normalizeDate(lines[i + 1]);
        }
        continue;
      }

      // Try to extract any date format
      final dateMatch = RegExp(r'\b\d{2}[\/\-]\d{2}[\/\-]\d{4}\b').firstMatch(line);
      if (dateMatch != null) {
        final date = _normalizeDate(dateMatch.group(0)!);
        // If we don't have dates yet, try to assign based on context
        if (result['dob'] == null && result['issue'] == null && result['expiry'] == null) {
          // First date is likely DOB
          result['dob'] = date;
        } else if (result['dob'] != null && result['issue'] == null && result['expiry'] == null) {
          // Second date is likely issue date
          result['issue'] = date;
        } else if (result['dob'] != null && result['issue'] != null && result['expiry'] == null) {
          // Third date is likely expiry date
          result['expiry'] = date;
        }
      }
    }

    return result;
  }

  // Parse back side text for employer, occupation, nationality, issue/expiry
  Map<String, String?> _parseBackText(String text) {
    final result = <String, String?>{
      'employer': null,
      'occupation': null,
      'nationality': null,
      'issue': null,
      'expiry': null,
    };

    final lines = text.split('\n').map((s) => s.trim()).where((s) => s.isNotEmpty).toList();
    
    // Arabic keywords mapping
    final arabicEmployerKeywords = ['صاحب العمل', 'الجهة', 'الشركة'];
    final arabicOccupationKeywords = ['المهنة', 'وظيفة', 'المسمى الوظيفي'];
    final arabicNationalityKeywords = ['الجنسية'];
    final arabicIssueKeywords = ['تاريخ الإصدار'];
    final arabicExpiryKeywords = ['تاريخ الانتهاء'];
    
    for (int i = 0; i < lines.length; i++) {
      final line = lines[i];
      final lower = line.toLowerCase();
      
      // Employer / Company
      if (lower.contains('employer') || lower.contains('company') || 
          arabicEmployerKeywords.any((k) => line.contains(k))) {
        if (line.contains(':')) {
          final parts = line.split(':');
          if (parts.length > 1) {
            result['employer'] = parts.sublist(1).join(':').trim();
          }
        } else if (i + 1 < lines.length) {
          result['employer'] = lines[i + 1];
        }
        continue;
      }
      
      // Occupation
      if (lower.contains('occupation') || lower.contains('profession') || 
          arabicOccupationKeywords.any((k) => line.contains(k))) {
        if (line.contains(':')) {
          final parts = line.split(':');
          if (parts.length > 1) {
            result['occupation'] = parts.sublist(1).join(':').trim();
          }
        } else if (i + 1 < lines.length) {
          result['occupation'] = lines[i + 1];
        }
        continue;
      }
      
      // Nationality
      if (lower.contains('nationality') || 
          arabicNationalityKeywords.any((k) => line.contains(k))) {
        if (line.contains(':')) {
          final parts = line.split(':');
          if (parts.length > 1) {
            result['nationality'] = parts[1].trim();
          }
        } else if (i + 1 < lines.length) {
          result['nationality'] = lines[i + 1];
        }
        continue;
      }
      
      // Issue date
      if (lower.contains('issue') || lower.contains('issued') || 
          arabicIssueKeywords.any((k) => line.contains(k))) {
        if (line.contains(':')) {
          final parts = line.split(':');
          if (parts.length > 1) {
            result['issue'] = _normalizeDate(parts[1].trim());
          }
        } else if (i + 1 < lines.length) {
          result['issue'] = _normalizeDate(lines[i + 1]);
        }
        continue;
      }
      
      // Expiry date
      if (lower.contains('expiry') || lower.contains('expire') || 
          arabicExpiryKeywords.any((k) => line.contains(k))) {
        if (line.contains(':')) {
          final parts = line.split(':');
          if (parts.length > 1) {
            result['expiry'] = _normalizeDate(parts[1].trim());
          }
        } else if (i + 1 < lines.length) {
          result['expiry'] = _normalizeDate(lines[i + 1]);
        }
        continue;
      }
      
      // Try to extract any date format
      final dateMatch = RegExp(r'\b\d{2}[\/\-]\d{2}[\/\-]\d{4}\b').firstMatch(line);
      if (dateMatch != null) {
        final date = _normalizeDate(dateMatch.group(0)!);
        // If we don't have dates yet, try to assign based on context
        if (result['issue'] == null && result['expiry'] == null) {
          // First date is likely issue date
          result['issue'] = date;
        } else if (result['issue'] != null && result['expiry'] == null) {
          // Second date is likely expiry date
          result['expiry'] = date;
        }
      }
    }
    
    return result;
  }

  // Helper to normalize date formats
  String _normalizeDate(String date) {
    // Convert dd-mm-yyyy or yyyy-mm-dd to dd/mm/yyyy
    if (date.contains('-')) {
      final parts = date.split('-');
      if (parts.length == 3) {
        // Check if it's yyyy-mm-dd
        if (parts[0].length == 4) {
          return '${parts[2]}/${parts[1]}/${parts[0]}';
        } else {
          // It's dd-mm-yyyy
          return '${parts[0]}/${parts[1]}/${parts[2]}';
        }
      }
    }
    return date;
  }

  // Helper to update form fields from parsed results
  void _updateFieldsFromResult(Map<String, String?> result, {bool overwrite = false}) {
    if (result['id'] != null && (overwrite || _emiratesIdController.text.isEmpty)) {
      if (_isValidEmiratesId(result['id']!)) {
        _emiratesIdController.text = result['id']!;
      }
    }
    
    if (result['name'] != null && (overwrite || _nameOfHolderController.text.isEmpty)) {
      _nameOfHolderController.text = result['name']!;
      
      // Try to split name into first, middle, last
      final nameParts = result['name']!.split(' ');
      if (nameParts.isNotEmpty && (overwrite || _firstNameController.text.isEmpty)) {
        _firstNameController.text = nameParts.first;
      }
      if (nameParts.length > 2 && (overwrite || _middleNameController.text.isEmpty)) {
        _middleNameController.text = nameParts.sublist(1, nameParts.length - 1).join(' ');
      }
      if (nameParts.length > 1 && (overwrite || _lastNameController.text.isEmpty)) {
        _lastNameController.text = nameParts.last;
      }
    }
    
    if (result['dob'] != null && (overwrite || _dobController.text.isEmpty)) {
      if (_isValidDate(result['dob']!)) {
        _dobController.text = result['dob']!;
      }
    }
    
    if (result['nationality'] != null && (overwrite || _nationalityController.text.isEmpty)) {
      _nationalityController.text = result['nationality']!;
    }
    
    if (result['issue'] != null && (overwrite || _issueDateController.text.isEmpty)) {
      if (_isValidDate(result['issue']!)) {
        _issueDateController.text = result['issue']!;
      }
    }
    
    if (result['expiry'] != null && (overwrite || _expiryDateController.text.isEmpty)) {
      if (_isValidDate(result['expiry']!)) {
        _expiryDateController.text = result['expiry']!;
      }
    }
    
    if (result['employer'] != null && (overwrite || _companyDetailsController.text.isEmpty)) {
      _companyDetailsController.text = result['employer']!;
    }
    
    if (result['occupation'] != null && (overwrite || _occupationController.text.isEmpty)) {
      _occupationController.text = result['occupation']!;
    }
  }

  // Validation helpers
  bool _isValidEmiratesId(String id) {
    // Emirates ID format: XXX-XXXX-XXXXXXX-X
    return RegExp(r'^[0-9]{3}-[0-9]{4}-[0-9]{7}-[0-9]$').hasMatch(id);
  }

  bool _isValidDate(String date) {
    // Check if date is in DD/MM/YYYY format and is a valid date
    try {
      final parts = date.split('/');
      if (parts.length != 3) return false;
      
      final day = int.parse(parts[0]);
      final month = int.parse(parts[1]);
      final year = int.parse(parts[2]);
      
      final dateObj = DateTime(year, month, day);
      return dateObj.day == day && dateObj.month == month && dateObj.year == year;
    } catch (e) {
      return false;
    }
  }
}