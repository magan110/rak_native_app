import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:go_router/go_router.dart';
import 'package:rak_app/core/routes/route_names.dart';
import '../../../../../core/services/contractor_service.dart';
import '../../../../../core/models/contractor_models.dart';
import '../../../../../core/models/user_profile_models.dart';
import '../../../../../shared/widgets/custom_back_button.dart';
import '../../../../../shared/widgets/modern_dropdown.dart';
import '../../../../../shared/widgets/responsive_widgets.dart';

class ContractorUpdateScreen extends StatefulWidget {
  final String mobileNumber;
  final UserProfileData? userProfile;
  final List<String>? missingFields;
  final String? completionMessage;

  const ContractorUpdateScreen({
    super.key, 
    required this.mobileNumber,
    this.userProfile,
    this.missingFields,
    this.completionMessage,
  });

  @override
  State<ContractorUpdateScreen> createState() => _ContractorUpdateScreenState();
}

class _ContractorUpdateScreenState extends State<ContractorUpdateScreen>
    with TickerProviderStateMixin {
  late AnimationController _mainController;
  late AnimationController _fabController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;
  late Animation<double> _scaleAnimation;

  // Current step state (1 = Personal, 2 = Emirates ID, 3 = Business, 4 = Bank)
  int _currentStep = 1;

  // Form controllers for auto-fill
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

  // State flags
  bool _isSubmitting = false;
  bool _isLoading = true;

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

  Future<void> _loadExistingData() async {
    try {
      final response = await ContractorService.getContractorDetailsByMobile(
        widget.mobileNumber,
      );

      if (response.success && response.data != null) {
        final data = response.data!;
        setState(() {
          _selectedContractorType = data.contractorType;
          _firstNameController.text = data.firstName ?? '';
          _middleNameController.text = data.middleName ?? '';
          _lastNameController.text = data.lastName ?? '';
          _addressController.text = data.address ?? '';
          _selectedEmirate = data.emirates;
          _accountHolderController.text = data.accountHolderName ?? '';
          _ibanController.text = data.ibanNumber ?? '';
          _bankNameController.text = data.bankName ?? '';
          _branchNameController.text = data.branchName ?? '';
          _bankAddressController.text = data.bankAddress ?? '';
          _firmNameController.text = data.firmName ?? '';
          _registeredAddressController.text = data.vatAddress ?? '';
          _taxNumberController.text = data.taxRegistrationNumber ?? '';
          _licenseNumberController.text = data.licenseNumber ?? '';
          _selectedIssuingAuthority = data.issuingAuthority;
          _selectedLicenseType = data.licenseType;
          _establishmentDateController.text = data.establishmentDate ?? '';
          _licenseExpiryDateController.text = data.licenseExpiryDate ?? '';
          _tradeNameController.text = data.tradeName ?? '';
          _responsiblePersonController.text = data.responsiblePerson ?? '';
          _effectiveRegDateController.text = data.effectiveDate ?? '';
          _effectiveVatDateController.text = data.vatEffectiveDate ?? '';
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
                'Update Contractor Details',
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
              _buildProgressStep(3, 'Business', _currentStep >= 3),
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
        return 'Personal Details';
      case 2:
        return 'Emirates ID Details';
      case 3:
        return 'Business Information';
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
        currentSection = _buildPersonalDetailsSection();
        break;
      case 2:
        currentSection = _buildEmiratesIdSection();
        break;
      case 3:
        currentSection = _buildBusinessDetailsSection();
        break;
      case 4:
        currentSection = _buildBankDetailsSection();
        break;
      default:
        currentSection = _buildPersonalDetailsSection();
    }

    return Column(
      children: [
        currentSection,
        const SizedBox(height: 24),
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

        // Next/Update button
        Expanded(
          child: ElevatedButton(
            onPressed: _isSubmitting
                ? null
                : () {
                    if (_currentStep < 4) {
                      setState(() {
                        _currentStep++;
                      });
                    } else {
                      // Update form
                      _updateContractorDetails();
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
                  _currentStep < 4
                      ? 'Next'
                      : (_isSubmitting ? 'Updating...' : 'Update Details'),
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                if (!_isSubmitting || _currentStep < 4) ...[
                  const SizedBox(width: 8),
                  Icon(
                    _currentStep < 4
                        ? Icons.arrow_forward_rounded
                        : Icons.update_rounded,
                  ),
                ],
              ],
            ),
          ),
        ),
      ],
    );
  }

  void _updateContractorDetails() async {
    if (_isSubmitting) return;

    setState(() => _isSubmitting = true);
    final messenger = ScaffoldMessenger.of(context);

    // Build the update request from form fields
    final req = ContractorRegistrationRequest(
      contractorType: _selectedContractorType,
      firstName: _firstNameController.text.trim(),
      middleName: _middleNameController.text.trim(),
      lastName: _lastNameController.text.trim(),
      mobileNumber: ContractorService.formatMobileNumber(
        _mobileController.text,
      ),
      address: _addressController.text.trim(),
      area: '',
      emirates: _selectedEmirate ?? '',
      profilePhoto: '', // File uploads not implemented in update
      password: '', // Not updating password
      contractorCertificate: '', // File uploads not implemented in update
      accountHolderName: _accountHolderController.text.trim(),
      ibanNumber: ContractorService.formatIban(_ibanController.text),
      bankName: _bankNameController.text.trim(),
      branchName: _branchNameController.text.trim(),
      bankAddress: _bankAddressController.text.trim(),
      bankDocument: '', // File uploads not implemented in update
      vatCertificate: '', // File uploads not implemented in update
      firmName: _firmNameController.text.trim(),
      vatAddress: _registeredAddressController.text.trim(),
      taxRegistrationNumber: _taxNumberController.text.trim(),
      vatEffectiveDate: _effectiveVatDateController.text.trim(),
      licenseDocument: '', // File uploads not implemented in update
      licenseNumber: _licenseNumberController.text.trim(),
      issuingAuthority: _selectedIssuingAuthority ?? '',
      licenseType: _selectedLicenseType ?? '',
      establishmentDate: _establishmentDateController.text.trim(),
      licenseExpiryDate: _licenseExpiryDateController.text.trim(),
      tradeName: _tradeNameController.text.trim(),
      responsiblePerson: _responsiblePersonController.text.trim(),
      licenseAddress: _registeredAddressController.text.trim(),
      effectiveDate: _effectiveRegDateController.text.trim(),
    );

    // Show update progress
    final loading = SnackBar(
      content: Row(
        children: [
          const SizedBox(width: 4),
          const CircularProgressIndicator(),
          const SizedBox(width: 12),
          const Expanded(child: Text('Updating contractor details...')),
        ],
      ),
      behavior: SnackBarBehavior.floating,
    );
    messenger.showSnackBar(loading);

    try {
      final resp = await ContractorService.updateContractor(req);
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

        // Navigate back to previous screen after short delay
        await Future.delayed(const Duration(seconds: 1));
        if (mounted) {
          Navigator.of(context).pop(true); // Return true to indicate successful update
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
        ModernDropdown(
          label: 'Contractor Type',
          icon: Icons.business_center_outlined,
          items: const [
            'Individual Contractor',
            'Company Contractor',
            'Partnership',
            'LLC',
          ],
          value: _selectedContractorType,
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

  Widget _buildBusinessDetailsSection() {
    return ResponsiveSection(
      title: 'Business Information',
      icon: Icons.business_rounded,
      subtitle: 'Update your business details',
      children: [
        ResponsiveTextField(
          label: 'Firm Name',
          icon: Icons.business_outlined,
          controller: _firmNameController,
        ),
        const ResponsiveSpacing(mobile: 20),
        ResponsiveTextField(
          label: 'Registered Address',
          icon: Icons.location_on_outlined,
          controller: _registeredAddressController,
        ),
        const ResponsiveSpacing(mobile: 20),
        ResponsiveTextField(
          label: 'Tax Registration Number',
          icon: Icons.receipt_outlined,
          controller: _taxNumberController,
          hint: 'XXX-XXXXXXXXX-XXX',
          isRequired: false,
        ),
        const ResponsiveSpacing(mobile: 20),
        ResponsiveTextField(
          label: 'License Number',
          icon: Icons.card_membership_outlined,
          controller: _licenseNumberController,
        ),
        const ResponsiveSpacing(mobile: 20),
        ResponsiveRow(
          children: [
            ModernDropdown(
              label: 'Issuing Authority',
              icon: Icons.account_balance_outlined,
              items: const [
                'Dubai Municipality',
                'Abu Dhabi Municipality',
                'Sharjah Municipality',
                'Ajman Municipality',
                'RAK Municipality',
                'Fujairah Municipality',
                'UAQ Municipality',
              ],
              value: _selectedIssuingAuthority,
              onChanged: (String? value) {
                setState(() {
                  _selectedIssuingAuthority = value;
                });
              },
            ),
            ModernDropdown(
              label: 'License Type',
              icon: Icons.category_outlined,
              items: const [
                'Commercial',
                'Professional',
                'Industrial',
                'Tourism',
              ],
              value: _selectedLicenseType,
              onChanged: (String? value) {
                setState(() {
                  _selectedLicenseType = value;
                });
              },
            ),
          ],
        ),
        const ResponsiveSpacing(mobile: 20),
        ResponsiveRow(
          children: [
            ResponsiveTextField(
              label: 'Establishment Date',
              icon: Icons.calendar_today_outlined,
              controller: _establishmentDateController,
              keyboardType: TextInputType.datetime,
              hint: 'YYYY-MM-DD',
            ),
            ResponsiveTextField(
              label: 'License Expiry Date',
              icon: Icons.event_outlined,
              controller: _licenseExpiryDateController,
              keyboardType: TextInputType.datetime,
              hint: 'YYYY-MM-DD',
            ),
          ],
        ),
        const ResponsiveSpacing(mobile: 20),
        ResponsiveTextField(
          label: 'Trade Name',
          icon: Icons.store_outlined,
          controller: _tradeNameController,
        ),
        const ResponsiveSpacing(mobile: 20),
        ResponsiveTextField(
          label: 'Responsible Person',
          icon: Icons.person_pin_outlined,
          controller: _responsiblePersonController,
        ),
      ],
    );
  }

  Widget _buildBankDetailsSection() {
    return ResponsiveSection(
      title: 'Bank Details',
      icon: Icons.account_balance_rounded,
      subtitle: 'Update your banking information',
      children: [
        ResponsiveTextField(
          label: 'Account Holder Name',
          icon: Icons.person_outline_rounded,
          controller: _accountHolderController,
        ),
        const ResponsiveSpacing(mobile: 20),
        ResponsiveTextField(
          label: 'IBAN Number',
          icon: Icons.account_balance_outlined,
          controller: _ibanController,
          keyboardType: TextInputType.text,
          hint: 'AE070331234567890123456',
        ),
        const ResponsiveSpacing(mobile: 20),
        ResponsiveRow(
          children: [
            ResponsiveTextField(
              label: 'Bank Name',
              icon: Icons.account_balance_outlined,
              controller: _bankNameController,
            ),
            ResponsiveTextField(
              label: 'Branch Name',
              icon: Icons.location_on_outlined,
              controller: _branchNameController,
            ),
          ],
        ),
        const ResponsiveSpacing(mobile: 20),
        ResponsiveTextField(
          label: 'Bank Address',
          icon: Icons.home_outlined,
          controller: _bankAddressController,
        ),
      ],
    );
  }
}
