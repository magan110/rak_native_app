import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:go_router/go_router.dart';
import 'package:rak_app/core/routes/route_names.dart';

import '../../../../../core/services/painter_service.dart';
import '../../../../../core/models/painter_models.dart';
import '../../../../../core/models/user_profile_models.dart';
import '../../../../../shared/widgets/custom_back_button.dart';
import '../../../../../shared/widgets/responsive_widgets.dart';
import '../../../../../shared/widgets/modern_dropdown.dart';

class PainterUpdateScreen extends StatefulWidget {
  final String mobileNumber;
  final UserProfileData? userProfile;
  final List<String>? missingFields;
  final String? completionMessage;

  const PainterUpdateScreen({
    super.key, 
    required this.mobileNumber,
    this.userProfile,
    this.missingFields,
    this.completionMessage,
  });

  @override
  State<PainterUpdateScreen> createState() => _PainterUpdateScreenState();
}

class _PainterUpdateScreenState extends State<PainterUpdateScreen>
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

  // State flags
  bool _isSubmitting = false;
  bool _isLoading = true;

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

    // Set mobile number (read-only)
    _mobileController.text = widget.mobileNumber;

    // Load existing data
    _loadExistingData();
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

  Future<void> _loadExistingData() async {
    try {
      final response = await PainterService.getPainterDetails(
        widget.mobileNumber,
      );

      if (response.success && response.data != null) {
        final data = response.data!;
        setState(() {
          _firstNameController.text = data.firstName ?? '';
          _middleNameController.text = data.middleName ?? '';
          _lastNameController.text = data.lastName ?? '';
          _addressController.text = data.address ?? '';
          _emiratesIdController.text = data.emiratesIdNumber ?? '';
          _nameOfHolderController.text = data.idName ?? '';
          _dobController.text = data.dateOfBirth ?? '';
          _nationalityController.text = data.nationality ?? '';
          _companyDetailsController.text = data.companyDetails ?? '';
          _issueDateController.text = data.issueDate ?? '';
          _expiryDateController.text = data.expiryDate ?? '';
          _occupationController.text = data.occupation ?? '';
          _accountHolderController.text = data.accountHolderName ?? '';
          _ibanController.text = data.ibanNumber ?? '';
          _bankNameController.text = data.bankName ?? '';
          _branchNameController.text = data.branchName ?? '';
          _bankAddressController.text = data.bankAddress ?? '';
          _selectedEmirate = data.emirates;
          // Note: reference field can be added to UI if needed
          _isLoading = false;
        });
      } else {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              response.message.isNotEmpty
                  ? response.message
                  : 'Failed to load data',
            ),
            backgroundColor: Colors.red,
          ),
        );
      }
    } catch (e) {
      setState(() => _isLoading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error loading data: ${e.toString()}'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Scaffold(
        backgroundColor: const Color(0xFFF8FAFC),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

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
                'Update Painter Details',
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
                      Icons.edit_rounded,
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
        return 'Emirates ID Details';
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

        // Next/Update button
        Expanded(
          child: ElevatedButton(
            onPressed: _isSubmitting
                ? null
                : () {
                    if (_currentStep < 3) {
                      setState(() {
                        _currentStep++;
                      });
                    } else {
                      // Update form
                      _handleUpdate();
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
            child: _isSubmitting
                ? SizedBox(
                    width: 20.w,
                    height: 20.h,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                    ),
                  )
                : Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        _currentStep < 3 ? 'Next' : 'Update Details',
                        style: TextStyle(
                          fontSize: 16.sp,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      SizedBox(width: 8.w),
                      Icon(
                        _currentStep < 3
                            ? Icons.arrow_forward_rounded
                            : Icons.update_rounded,
                      ),
                    ],
                  ),
          ),
        ),
      ],
    );
  }

  void _handleUpdate() async {
    if (_isSubmitting) return;

    // Basic validations
    final firstNameErr = PainterService.validateName(
      _firstNameController.text,
      'First name',
    );
    if (firstNameErr != null) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(firstNameErr)));
      return;
    }

    final lastNameErr = PainterService.validateName(
      _lastNameController.text,
      'Last name',
    );
    if (lastNameErr != null) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(lastNameErr)));
      return;
    }

    final emiratesErr = PainterService.validateEmiratesId(
      _emiratesIdController.text,
    );
    if (emiratesErr != null) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(emiratesErr)));
      return;
    }

    setState(() => _isSubmitting = true);
    final messenger = ScaffoldMessenger.of(context);

    // Build the update request from form fields
    final req = PainterRegistrationRequest(
      firstName: _firstNameController.text.trim(),
      middleName: _middleNameController.text.trim(),
      lastName: _lastNameController.text.trim(),
      mobileNumber: PainterService.formatMobileNumber(_mobileController.text),
      address: _addressController.text.trim(),
      area: '',
      emirates: _selectedEmirate ?? '',
      reference: '', // Can be added to UI if needed
      password: '', // Not updating password
      emiratesIdNumber: _emiratesIdController.text.trim(),
      idName: _nameOfHolderController.text.trim(),
      dateOfBirth: _dobController.text.trim(),
      nationality: _nationalityController.text.trim(),
      companyDetails: _companyDetailsController.text.trim(),
      issueDate: _issueDateController.text.trim(),
      expiryDate: _expiryDateController.text.trim(),
      occupation: _occupationController.text.trim(),
      accountHolderName: _accountHolderController.text.trim(),
      ibanNumber: PainterService.formatIban(_ibanController.text),
      bankName: _bankNameController.text.trim(),
      branchName: _branchNameController.text.trim(),
      bankAddress: _bankAddressController.text.trim(),
    );

    // Show update progress
    final loading = SnackBar(
      content: Row(
        children: [
          const SizedBox(width: 4),
          const CircularProgressIndicator(),
          const SizedBox(width: 12),
          const Expanded(child: Text('Updating painter details...')),
        ],
      ),
      behavior: SnackBarBehavior.floating,
    );
    messenger.showSnackBar(loading);

    try {
      final resp = await PainterService.updatePainter(req);
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
                        : 'Details updated successfully',
                  ),
                ),
              ],
            ),
            backgroundColor: const Color(0xFF10B981),
            behavior: SnackBarBehavior.floating,
          ),
        );

        // Navigate back to painter home
        await Future.delayed(const Duration(seconds: 1));
        if (mounted) {
          context.go('/painter-home');
        }
      } else {
        messenger.showSnackBar(
          SnackBar(
            content: Text(
              resp.message.isNotEmpty ? resp.message : 'Update failed',
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
          content: Text('Update failed: ${e.toString()}'),
          backgroundColor: Colors.redAccent,
          behavior: SnackBarBehavior.floating,
        ),
      );
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  void _showHelpDialog() {
    showDialog(
      context: context,
      builder: (context) => Dialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20.r),
        ),
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
                'Update Help',
                style: TextStyle(
                  fontSize: 20.sp,
                  fontWeight: FontWeight.bold,
                  color: Colors.black87,
                ),
              ),
              SizedBox(height: 12.h),
              Text(
                'Update your registration details carefully. Make sure all information is accurate before submitting.',
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

  Widget _buildPersonalDetailsSection() {
    return ResponsiveSection(
      title: 'Personal Details',
      icon: Icons.person_rounded,
      subtitle: 'Update your personal information',
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
      ],
    );
  }

  Widget _buildMobileNumberField() {
    return ResponsiveTextField(
      label: 'Mobile Number',
      icon: Icons.phone_outlined,
      controller: _mobileController,
      keyboardType: TextInputType.phone,
      readOnly: true, // Read-only for updates
      hint: '+971 ${_mobileController.text}',
    );
  }

  Widget _buildEmiratesIdSection() {
    return ResponsiveSection(
      title: 'Emirates ID Details',
      icon: Icons.credit_card_rounded,
      subtitle: 'Update your Emirates ID information',
      children: [
        ResponsiveTextField(
          label: 'Emirates ID Number',
          icon: Icons.credit_card_outlined,
          controller: _emiratesIdController,
          keyboardType: TextInputType.number,
        ),
        const ResponsiveSpacing(mobile: 20),
        ResponsiveTextField(
          label: 'Name on ID',
          icon: Icons.person_outline_rounded,
          controller: _nameOfHolderController,
        ),
        const ResponsiveSpacing(mobile: 20),
        ResponsiveRow(
          children: [
            ResponsiveTextField(
              label: 'Date of Birth',
              icon: Icons.calendar_today_outlined,
              controller: _dobController,
              keyboardType: TextInputType.datetime,
              hint: 'YYYY-MM-DD',
            ),
            ResponsiveTextField(
              label: 'Nationality',
              icon: Icons.flag_outlined,
              controller: _nationalityController,
            ),
          ],
        ),
        const ResponsiveSpacing(mobile: 20),
        ResponsiveTextField(
          label: 'Company Details',
          icon: Icons.business_outlined,
          controller: _companyDetailsController,
        ),
        const ResponsiveSpacing(mobile: 20),
        ResponsiveRow(
          children: [
            ResponsiveTextField(
              label: 'Issue Date',
              icon: Icons.calendar_today_outlined,
              controller: _issueDateController,
              keyboardType: TextInputType.datetime,
              hint: 'YYYY-MM-DD',
            ),
            ResponsiveTextField(
              label: 'Expiry Date',
              icon: Icons.event_outlined,
              controller: _expiryDateController,
              keyboardType: TextInputType.datetime,
              hint: 'YYYY-MM-DD',
            ),
          ],
        ),
        const ResponsiveSpacing(mobile: 20),
        ResponsiveTextField(
          label: 'Occupation',
          icon: Icons.work_outline_rounded,
          controller: _occupationController,
        ),
      ],
    );
  }

  Widget _buildBankDetailsSection() {
    return ResponsiveSection(
      title: 'Bank Details',
      icon: Icons.account_balance_rounded,
      subtitle: 'Update your banking information (Optional)',
      children: [
        ResponsiveTextField(
          label: 'Account Holder Name',
          icon: Icons.person_outline_rounded,
          controller: _accountHolderController,
          isRequired: false,
        ),
        const ResponsiveSpacing(mobile: 20),
        ResponsiveTextField(
          label: 'IBAN Number',
          icon: Icons.account_balance_outlined,
          controller: _ibanController,
          keyboardType: TextInputType.text,
          hint: 'AE070331234567890123456',
          isRequired: false,
        ),
        const ResponsiveSpacing(mobile: 20),
        ResponsiveRow(
          children: [
            ResponsiveTextField(
              label: 'Bank Name',
              icon: Icons.account_balance_outlined,
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
          icon: Icons.home_outlined,
          controller: _bankAddressController,
          isRequired: false,
        ),
      ],
    );
  }
}
