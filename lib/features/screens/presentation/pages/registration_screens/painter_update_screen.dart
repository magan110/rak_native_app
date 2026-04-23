import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:go_router/go_router.dart';
import 'package:rak_app/core/routes/route_names.dart';

import '../../../../../core/services/painter_service.dart';
import '../../../../../core/services/auth_service.dart';
import '../../../../../core/models/painter_models.dart';
import '../../../../../core/models/user_profile_models.dart';
import '../../../../../core/models/auth_models.dart';
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
    _poBoxController.dispose();
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
      // 1. Load master emirates first
      try {
        _emiratesList = await PainterService.getEmiratesList();
      } catch (_) {
        _emiratesList = [];
      }

      // 2. If userProfile contains inflCode, prefer fetching full details from backend
      final inflCode = widget.userProfile?.inflCode;
      PainterDetails? details;

      if (inflCode != null && inflCode.isNotEmpty) {
        final resp = await PainterService.getPainterDetailsByCode(inflCode);
        if (resp.success && resp.data != null) {
          details = resp.data!;
        }
      }

      // 3. If backend details not available, fall back to widget.userProfile
      if (details == null && widget.userProfile != null) {
        final p = widget.userProfile!;
        details = PainterDetails(
          firstName: p.firstName,
          middleName: p.middleName,
          lastName: p.lastName,
          mobileNumber: p.mobileNumber,
          address: p.address,
          emirates: p.emirates,
          area: p.areaCode, // areaCode may be present here
          emiratesIdNumber: p.emiratesIdNumber,
          idName: p.idName,
          dateOfBirth: p.dateOfBirth,
          nationality: p.nationality,
          companyDetails: p.companyDetails,
          issueDate: p.issueDate,
          expiryDate: p.expiryDate,
          occupation: p.occupation,
          accountHolderName: p.accountHolderName,
          ibanNumber: p.ibanNumber,
          bankName: p.bankName,
          branchName: p.branchName,
          bankAddress: p.bankAddress,
        );
      }

      // 4. Populate UI fields if we have details
      if (details != null) {
        setState(() {
          _firstNameController.text = details!.firstName ?? '';
          _middleNameController.text = details!.middleName ?? '';
          _lastNameController.text = details!.lastName ?? '';
          _addressController.text = details!.address ?? '';
          _emiratesIdController.text = details!.emiratesIdNumber ?? '';
          _nameOfHolderController.text = details!.idName ?? '';
          _dobController.text = details!.dateOfBirth ?? '';
          _nationalityController.text = details!.nationality ?? '';
          _companyDetailsController.text = details!.companyDetails ?? '';
          _issueDateController.text = details!.issueDate ?? '';
          _expiryDateController.text = details!.expiryDate ?? '';
          _occupationController.text = details!.occupation ?? '';
          _accountHolderController.text = details!.accountHolderName ?? '';
          _ibanController.text = details!.ibanNumber ?? '';
          _bankNameController.text = details!.bankName ?? '';
          _branchNameController.text = details!.branchName ?? '';
          _bankAddressController.text = details!.bankAddress ?? '';
          _selectedEmirate = details!.emirates;
        });

        // 5. Try to resolve emirate code from loaded emirates
        if (_selectedEmirate != null && _emiratesList.isNotEmpty) {
          final foundEmirate = _emiratesList.firstWhere(
            (e) => e.name == _selectedEmirate || e.id == _selectedEmirate,
            orElse: () => EmirateItem(id: '', name: ''),
          );
          if (foundEmirate.id.isNotEmpty) {
            _selectedEmirateCode = foundEmirate.id;
            try {
              _areasList = await PainterService.getAreasListByEmirate(
                _selectedEmirateCode!,
              );
            } catch (_) {
              _areasList = [];
            }
          }
        }

        // 6. Resolve area/sub-area selection using details.area (try code then name)
        final areaValue = details.area;
        if (areaValue != null &&
            areaValue.isNotEmpty &&
            _areasList.isNotEmpty) {
          final foundArea = _areasList.firstWhere(
            (a) => a.code == areaValue || a.name == areaValue,
            orElse: () => AreaItem(code: '', name: '', poBox: ''),
          );
          if (foundArea.code.isNotEmpty) {
            _selectedAreaCode = foundArea.code;
            _selectedAreaName = foundArea.name;
            // load subareas
            try {
              final res = await PainterService.getSubAreasListByArea(
                _selectedAreaCode!,
              );
              _hasSubArea = res['hasSubArea'] == true;
              _subAreasList = (res['data'] as List<SubAreaItem>?) ?? [];
              if (_hasSubArea) {
                // try to match sub-area by name/code if returned in details.reference or similar
                // PainterDetails currently doesn't include subArea; skip unless found
              } else {
                // if no subareas, set poBox from area
                _poBoxController.text = foundArea.poBox;
              }
            } catch (_) {
              _hasSubArea = false;
              _subAreasList = [];
            }
          }
        }
      }

      setState(() => _isLoading = false);
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
      emirateCode: _selectedEmirateCode,
      emirates: _selectedEmirate ?? '',
      areaCode: _selectedAreaCode,
      areaName: _selectedAreaName,
      subAreaCode: _selectedSubAreaCode,
      subAreaName: _selectedSubAreaName,
      poBox: _poBoxController.text.trim(),
      reference: '', // Can be added to UI if needed
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

    // Ensure we have inflCode to call update endpoint
    final inflCode = widget.userProfile?.inflCode;
    if (inflCode == null || inflCode.isEmpty) {
      messenger.showSnackBar(
        const SnackBar(
          content: Text('Unable to determine influencer code for update'),
        ),
      );
      setState(() => _isSubmitting = false);
      return;
    }

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
      final resp = await PainterService.updatePainter(inflCode, req);
      messenger.hideCurrentSnackBar();

      if (resp.success) {
        // Update AuthManager with new user name
        final currentUser = AuthManager.currentUser;
        if (currentUser != null) {
          final fullName = '${req.firstName} ${req.middleName} ${req.lastName}'
              .trim()
              .replaceAll(RegExp(r'\s+'), ' ');
          final updatedUser = UserData(
            emplName: fullName,
            areaCode: (req.emirates != null && req.emirates!.isNotEmpty)
                ? req.emirates!
                : currentUser.areaCode,
            deptCode: currentUser.deptCode,
            roles: currentUser.roles,
            pages: currentUser.pages,
            userID: currentUser.userID,
            appRegId: currentUser.appRegId,
          );
          AuthManager.setUser(updatedUser);
        }

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
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('Failed loading areas: ${e.toString()}'),
                  ),
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
                    final area = _areasList.firstWhere(
                      (a) => a.code == _selectedAreaCode,
                      orElse: () => AreaItem(code: '', name: '', poBox: ''),
                    );
                    _poBoxController.text = area.poBox;
                  }
                });
              } catch (e) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('Failed loading sub-areas: ${e.toString()}'),
                  ),
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
