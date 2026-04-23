import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:rak_app/core/models/approval_models.dart';
import 'package:rak_app/core/services/approval_service.dart';
import 'package:rak_app/shared/widgets/custom_back_button.dart';
import 'package:rak_app/shared/widgets/document_viewer_widget.dart';

class RegistrationDetailsScreen extends StatefulWidget {
  final String? registrationId;

  const RegistrationDetailsScreen({super.key, this.registrationId});

  @override
  State<RegistrationDetailsScreen> createState() =>
      _RegistrationDetailsScreenState();
}

class _RegistrationDetailsScreenState extends State<RegistrationDetailsScreen>
    with TickerProviderStateMixin {
  late AnimationController _mainController;
  late AnimationController _fabController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;
  late Animation<double> _scaleAnimation;
  final List<AnimationController> _cardControllers = [];
  final List<Animation<double>> _cardAnimations = [];

  final ApprovalService _approvalService = ApprovalService();
  RegistrationDetails? _registrationData;
  bool _isLoading = false;
  String? _errorMessage;

  int _currentStep = 0; // 0 = Emirates ID, 1 = Other Details

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

    // Initialize card animations
    for (int i = 0; i < 4; i++) {
      final controller = AnimationController(
        duration: const Duration(milliseconds: 400),
        vsync: this,
      );
      final animation = CurvedAnimation(
        parent: controller,
        curve: Curves.easeOutCubic,
      );
      _cardControllers.add(controller);
      _cardAnimations.add(animation);

      // Stagger the card animations
      Future.delayed(Duration(milliseconds: 200 + (i * 100)), () {
        if (mounted) controller.forward();
      });
    }

    _mainController.forward();
    _fabController.forward();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_registrationData == null && !_isLoading && _errorMessage == null) {
      // Add a small delay to ensure route is fully established
      Future.delayed(const Duration(milliseconds: 100), () {
        if (mounted) {
          _loadRegistrationDetails();
        }
      });
    }
  }

  @override
  void dispose() {
    _mainController.dispose();
    _fabController.dispose();
    for (var controller in _cardControllers) {
      controller.dispose();
    }
    super.dispose();
  }

  void _loadRegistrationDetails() async {
    final identifier = widget.registrationId;
    if (identifier == null || identifier.isEmpty) {
      setState(() {
        _errorMessage = 'No registration data provided';
      });
      return;
    }

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      if (identifier.isEmpty) {
        throw Exception('No identifier provided');
      }

      print(
        'DEBUG: Looking up registration details for identifier: $identifier',
      );

      // Use the new dynamic lookup method
      final details = await _approvalService.getRegistrationDetailsByIdentifier(
        identifier,
      );

      print(
        'DEBUG: Successfully received details for: ${details.name} (ID: ${details.id})',
      );

      setState(() {
        _registrationData = details;
        _isLoading = false;

        // Set current step based on stage
        if (details.stage == 'EID_APPROVED') {
          _currentStep = 1; // Show other details
        } else if (details.stage == 'FINAL' || details.stage == 'REJECTED') {
          _currentStep = 1; // Show all details for completed registrations
        } else {
          _currentStep = 0; // Show Emirates ID step
        }
      });
    } catch (e) {
      print('DEBUG: Error loading details: $e');
      setState(() {
        _errorMessage = e.toString();
        _isLoading = false;
      });
    }
  }

  void _testApiWithSampleId() async {
    print('DEBUG: Testing API with sample identifier');
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      // Test with any identifier - could be name, mobile, email, or inflCode
      const testIdentifier =
          'John'; // Change this to any name, mobile, email, or inflCode from your DB
      print('DEBUG: Testing with identifier: $testIdentifier');

      final details = await _approvalService.getRegistrationDetailsByIdentifier(
        testIdentifier,
      );

      print(
        'DEBUG: Test successful! Received details: ${details.name} (ID: ${details.id})',
      );

      setState(() {
        _registrationData = details;
        _isLoading = false;
      });
    } catch (e) {
      print('DEBUG: Test failed with error: $e');
      setState(() {
        _errorMessage = 'Test failed: $e';
        _isLoading = false;
      });
    }
  }

  Future<void> _approveEmiratesId() async {
    if (_registrationData == null || _registrationData!.id.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('No registration ID available for approval'),
        ),
      );
      return;
    }

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Row(
          children: [
            SizedBox(
              width: 20,
              height: 20,
              child: CircularProgressIndicator(strokeWidth: 2),
            ),
            SizedBox(width: 16),
            Text('Approving Emirates ID...'),
          ],
        ),
        duration: Duration(seconds: 30),
      ),
    );

    try {
      final inflCode = await _approvalService.lookupInflCode(
        _registrationData!.id,
      );
      await _approvalService.approveEmiratesId(inflCode);

      ScaffoldMessenger.of(context).hideCurrentSnackBar();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Emirates ID approved successfully! Proceeding to next step...',
          ),
          backgroundColor: Colors.green,
          duration: Duration(seconds: 2),
        ),
      );

      // Move to next step after a brief delay
      await Future.delayed(const Duration(milliseconds: 500));

      // Reload details and move to step 2
      _loadRegistrationDetails();

      if (mounted) {
        setState(() {
          _currentStep = 1;
        });
      }
    } catch (e) {
      ScaffoldMessenger.of(context).hideCurrentSnackBar();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to approve Emirates ID: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Future<void> _approveFinal() async {
    if (_registrationData == null || _registrationData!.id.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('No registration ID available for approval'),
        ),
      );
      return;
    }

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Row(
          children: [
            SizedBox(
              width: 20,
              height: 20,
              child: CircularProgressIndicator(strokeWidth: 2),
            ),
            SizedBox(width: 16),
            Text('Approving final registration...'),
          ],
        ),
        duration: Duration(seconds: 30),
      ),
    );

    try {
      final inflCode = await _approvalService.lookupInflCode(
        _registrationData!.id,
      );
      await _approvalService.approveFinal(inflCode);

      ScaffoldMessenger.of(context).hideCurrentSnackBar();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('${_registrationData!.name} approved successfully'),
          backgroundColor: Colors.green,
        ),
      );

      // Navigate back to dashboard with refresh signal
      Navigator.pop(context, true);
    } catch (e) {
      ScaffoldMessenger.of(context).hideCurrentSnackBar();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to approve: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Future<void> _rejectRegistration(String reason) async {
    if (_registrationData == null || _registrationData!.id.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('No registration ID available for rejection'),
        ),
      );
      return;
    }

    // Show loading indicator
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Row(
          children: [
            SizedBox(
              width: 20,
              height: 20,
              child: CircularProgressIndicator(strokeWidth: 2),
            ),
            SizedBox(width: 16),
            Text('Rejecting registration...'),
          ],
        ),
        duration: Duration(seconds: 30),
      ),
    );

    try {
      // Get the inflCode for this item (same as approval dashboard)
      final inflCode = await _approvalService.lookupInflCode(
        _registrationData!.id,
      );

      // Reject the item using inflCode with reason
      await _approvalService.rejectItem(inflCode, reason: reason);

      // Hide loading and show success
      ScaffoldMessenger.of(context).hideCurrentSnackBar();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('${_registrationData!.name} rejected successfully'),
          backgroundColor: Colors.orange,
        ),
      );
      // Navigate back to dashboard with refresh signal
      Navigator.pop(context, true);
    } catch (e) {
      // Hide loading and show error
      ScaffoldMessenger.of(context).hideCurrentSnackBar();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to reject: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    // Set system UI overlay style
    SystemChrome.setSystemUIOverlayStyle(
      const SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: Brightness.dark,
        statusBarBrightness: Brightness.light,
      ),
    );

    return Scaffold(
      backgroundColor: Colors.grey.shade50,
      appBar: _buildModernAppBar(),
      body: FadeTransition(
        opacity: _fadeAnimation,
        child: SlideTransition(
          position: _slideAnimation,
          child: Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  Colors.cyan.shade50,
                  Colors.white,
                  Colors.grey.shade50,
                ],
              ),
            ),
            child: _buildContent(),
          ),
        ),
      ),
    );
  }

  Widget _buildContent() {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_errorMessage != null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.error_outline, size: 64.r, color: Colors.red.shade400),
            SizedBox(height: 16.h),
            Text(
              'Error loading data',
              style: TextStyle(
                color: Colors.red.shade700,
                fontSize: 18.sp,
                fontWeight: FontWeight.bold,
              ),
            ),
            SizedBox(height: 8.h),
            Padding(
              padding: EdgeInsets.symmetric(horizontal: 24.w),
              child: Text(
                _errorMessage!,
                style: TextStyle(color: Colors.red.shade600, fontSize: 14.sp),
                textAlign: TextAlign.center,
              ),
            ),
            SizedBox(height: 16.h),
            ElevatedButton(
              onPressed: _loadRegistrationDetails,
              child: const Text('Retry'),
            ),
          ],
        ),
      );
    }

    if (_registrationData == null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              'No registration data available',
              style: TextStyle(fontSize: 16.sp),
            ),
            SizedBox(height: 16.h),
            Text(
              'Registration ID: ${widget.registrationId}',
              style: TextStyle(fontSize: 14.sp, color: Colors.grey),
            ),
            SizedBox(height: 16.h),
            ElevatedButton(
              onPressed: _loadRegistrationDetails,
              child: const Text('Retry Load'),
            ),
            SizedBox(height: 8.h),
            ElevatedButton(
              onPressed: () => _testApiWithSampleId(),
              child: const Text('Test API with Sample ID'),
            ),
          ],
        ),
      );
    }

    return SingleChildScrollView(
      padding: EdgeInsets.all(16.w),
      child: ScaleTransition(
        scale: _scaleAnimation,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header with animation
            _buildAnimatedHeader(),
            SizedBox(height: 24.h),
            // Step Indicator
            _buildStepIndicator(),
            SizedBox(height: 24.h),
            // Step-based content
            if (_currentStep == 0) ...[
              // Step 1: Emirates ID Details
              _buildEmiratesIdSection(),
            ] else ...[
              // Step 2: Other Details
              _buildOtherDetailsSection(),
            ],
            SizedBox(height: 24.h),
            // Action Buttons
            _buildActionButtons(),
            SizedBox(height: 24.h),
          ],
        ),
      ),
    );
  }

  Widget _buildStepIndicator() {
    final stage = _registrationData?.stage ?? 'EID_PENDING';

    // Don't show step indicator if already approved or rejected
    if (stage == 'FINAL' || stage == 'REJECTED') {
      return const SizedBox.shrink();
    }

    return Container(
      padding: EdgeInsets.all(16.w),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12.r),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            blurRadius: 10.r,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Column(
        children: [
          Row(
            children: [
              // Step 1
              Expanded(
                child: GestureDetector(
                  onTap: () {
                    setState(() {
                      _currentStep = 0;
                    });
                  },
                  child: _buildStepItem(
                    stepNumber: 1,
                    title: 'Emirates ID',
                    isActive: _currentStep == 0,
                    isCompleted: _currentStep > 0 || stage == 'EID_APPROVED',
                  ),
                ),
              ),
              SizedBox(width: 16.w),
              // Connector
              Expanded(
                flex: 0,
                child: Container(
                  height: 2.h,
                  width: 40.w,
                  color: _currentStep > 0 || stage == 'EID_APPROVED'
                      ? Colors.green
                      : Colors.grey.shade300,
                ),
              ),
              SizedBox(width: 16.w),
              // Step 2
              Expanded(
                child: GestureDetector(
                  onTap: () {
                    setState(() {
                      _currentStep = 1;
                    });
                  },
                  child: _buildStepItem(
                    stepNumber: 2,
                    title: 'Other Details',
                    isActive: _currentStep == 1,
                    isCompleted: stage == 'FINAL',
                  ),
                ),
              ),
            ],
          ),
          SizedBox(height: 16.h),
          // Navigation buttons
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: _currentStep > 0
                      ? () {
                          setState(() {
                            _currentStep--;
                          });
                        }
                      : null,
                  icon: const Icon(Icons.arrow_back),
                  label: const Text('Previous'),
                  style: OutlinedButton.styleFrom(
                    padding: EdgeInsets.symmetric(vertical: 12.h),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8.r),
                    ),
                  ),
                ),
              ),
              SizedBox(width: 12.w),
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: _currentStep < 1
                      ? () {
                          setState(() {
                            _currentStep++;
                          });
                        }
                      : null,
                  icon: const Icon(Icons.arrow_forward),
                  label: const Text('Next'),
                  style: ElevatedButton.styleFrom(
                    padding: EdgeInsets.symmetric(vertical: 12.h),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8.r),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStepItem({
    required int stepNumber,
    required String title,
    required bool isActive,
    required bool isCompleted,
  }) {
    Color bgColor;
    Color textColor;
    Widget icon;

    if (isCompleted) {
      bgColor = Colors.green;
      textColor = Colors.white;
      icon = Icon(Icons.check, color: Colors.white, size: 16.r);
    } else if (isActive) {
      bgColor = Colors.blue;
      textColor = Colors.white;
      icon = Text(
        '$stepNumber',
        style: TextStyle(
          color: Colors.white,
          fontWeight: FontWeight.bold,
          fontSize: 14.sp,
        ),
      );
    } else {
      bgColor = Colors.grey.shade300;
      textColor = Colors.grey.shade600;
      icon = Text(
        '$stepNumber',
        style: TextStyle(
          color: Colors.grey.shade600,
          fontWeight: FontWeight.bold,
          fontSize: 14.sp,
        ),
      );
    }

    return Column(
      children: [
        Container(
          width: 32.r,
          height: 32.r,
          decoration: BoxDecoration(color: bgColor, shape: BoxShape.circle),
          child: Center(child: icon),
        ),
        SizedBox(height: 8.h),
        Text(
          title,
          style: TextStyle(
            fontSize: 12.sp,
            fontWeight: isActive ? FontWeight.bold : FontWeight.normal,
            color: textColor,
          ),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }

  Widget _buildEmiratesIdSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          padding: EdgeInsets.all(16.w),
          decoration: BoxDecoration(
            color: Colors.blue.shade50,
            borderRadius: BorderRadius.circular(12.r),
            border: Border.all(color: Colors.blue.shade200),
          ),
          child: Row(
            children: [
              Icon(Icons.credit_card, color: Colors.blue.shade700, size: 24.r),
              SizedBox(width: 12.w),
              Expanded(
                child: Text(
                  'Step 1: Review and Approve Emirates ID',
                  style: TextStyle(
                    fontSize: 14.sp,
                    fontWeight: FontWeight.bold,
                    color: Colors.blue.shade700,
                  ),
                ),
              ),
            ],
          ),
        ),
        SizedBox(height: 16.h),
        _buildBasicInfoCard(0),
        SizedBox(height: 16.h),
        _buildEmiratesIdCard(1),
        SizedBox(height: 16.h),
        _buildEmiratesIdDocumentsCard(),
      ],
    );
  }

  Widget _buildBasicInfoCard(int cardIndex) {
    if (_registrationData == null) {
      return const SizedBox.shrink();
    }

    return ScaleTransition(
      scale: _cardAnimations[cardIndex],
      child: Container(
        padding: EdgeInsets.all(16.w),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12.r),
          boxShadow: [
            BoxShadow(
              color: Colors.grey.withOpacity(0.1),
              blurRadius: 10.r,
              offset: const Offset(0, 5),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width: 36.r,
                  height: 36.r,
                  decoration: BoxDecoration(
                    color: Colors.cyan.withOpacity(0.1),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    Icons.info_rounded,
                    color: Colors.cyan.shade700,
                    size: 18.r,
                  ),
                ),
                SizedBox(width: 12.w),
                Text(
                  'Basic Information',
                  style: TextStyle(
                    fontSize: 16.sp,
                    fontWeight: FontWeight.bold,
                    color: Colors.black87,
                  ),
                ),
              ],
            ),
            SizedBox(height: 16.h),
            _buildInfoRow('Registration ID:', _registrationData!.id),
            _buildInfoRow('Full Name:', _registrationData!.fullName),
            _buildInfoRow('Type:', _registrationData!.type),
            _buildInfoRow('Mobile:', _registrationData!.mobile),
            _buildInfoRow('Submitted Date:', _registrationData!.submittedDate),
          ],
        ),
      ),
    );
  }

  Widget _buildEmiratesIdCard(int cardIndex) {
    if (_registrationData == null) {
      return const SizedBox.shrink();
    }

    final eid = _registrationData!.emiratesId;

    return ScaleTransition(
      scale: _cardAnimations[cardIndex],
      child: Container(
        padding: EdgeInsets.all(16.w),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12.r),
          boxShadow: [
            BoxShadow(
              color: Colors.grey.withOpacity(0.1),
              blurRadius: 10.r,
              offset: const Offset(0, 5),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width: 36.r,
                  height: 36.r,
                  decoration: BoxDecoration(
                    color: Colors.blue.withOpacity(0.1),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    Icons.credit_card,
                    color: Colors.blue.shade700,
                    size: 18.r,
                  ),
                ),
                SizedBox(width: 12.w),
                Text(
                  'Emirates ID Details',
                  style: TextStyle(
                    fontSize: 16.sp,
                    fontWeight: FontWeight.bold,
                    color: Colors.black87,
                  ),
                ),
              ],
            ),
            SizedBox(height: 16.h),
            _buildInfoRow('ID Number:', eid?.number ?? 'N/A'),
            _buildInfoRow('ID Holder:', eid?.idHolder ?? 'N/A'),
            _buildInfoRow('Nationality:', eid?.nationality ?? 'N/A'),
            _buildInfoRow('Employer:', eid?.employer ?? 'N/A'),
            _buildInfoRow('Issue Date:', eid?.issueDate ?? 'N/A'),
            _buildInfoRow('Expiry Date:', eid?.expiryDate ?? 'N/A'),
            _buildInfoRow('Occupation:', eid?.occupation ?? 'N/A'),
            _buildInfoRow('Emirate:', eid?.emirate ?? 'N/A'),
          ],
        ),
      ),
    );
  }

  Widget _buildOtherDetailsSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          padding: EdgeInsets.all(16.w),
          decoration: BoxDecoration(
            color: Colors.green.shade50,
            borderRadius: BorderRadius.circular(12.r),
            border: Border.all(color: Colors.green.shade200),
          ),
          child: Row(
            children: [
              Icon(
                Icons.check_circle,
                color: Colors.green.shade700,
                size: 24.r,
              ),
              SizedBox(width: 12.w),
              Expanded(
                child: Text(
                  'Step 2: Review and Approve Other Details',
                  style: TextStyle(
                    fontSize: 14.sp,
                    fontWeight: FontWeight.bold,
                    color: Colors.green.shade700,
                  ),
                ),
              ),
            ],
          ),
        ),
        SizedBox(height: 16.h),
        _buildPersonalDetailsCard(0),
        SizedBox(height: 16.h),
        _buildPersonalDocumentsCard(),
        SizedBox(height: 16.h),
        _buildBusinessDetailsCard(1),
        SizedBox(height: 16.h),
        _buildBusinessDocumentsCard(),
        SizedBox(height: 16.h),
        _buildBankDetailsCard(2),
        SizedBox(height: 16.h),
        _buildBankDocumentsCard(),
      ],
    );
  }

  PreferredSizeWidget _buildModernAppBar() {
    return AppBar(
      elevation: 0,
      backgroundColor: Colors.transparent,
      foregroundColor: Colors.cyan.shade800,
      systemOverlayStyle: const SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: Brightness.dark,
      ),
      leading: Navigator.of(context).canPop()
          ? Padding(
              padding: EdgeInsets.all(8.w),
              child: CustomBackButton(animated: false, size: 36.r),
            )
          : null,
      title: Text(
        'Registration Details',
        style: TextStyle(fontWeight: FontWeight.w600, fontSize: 20.sp),
      ),
      actions: [
        IconButton(
          icon: const Icon(Icons.refresh),
          onPressed: () {
            print('DEBUG: Manual refresh triggered');
            _loadRegistrationDetails();
          },
        ),
      ],
    );
  }

  Widget _buildAnimatedHeader() {
    if (_registrationData == null) {
      return const SizedBox.shrink();
    }

    final status = _registrationData!.status;
    final stage = _registrationData!.stage;

    final statusColor = status == 'Pending'
        ? Colors.orange
        : status == 'Approved'
        ? Colors.green
        : status == 'EID Approved'
        ? Colors.blue
        : Colors.red;

    String stageText = '';
    if (stage == 'EID_PENDING') {
      stageText = 'Awaiting Emirates ID Approval';
    } else if (stage == 'EID_APPROVED') {
      stageText = 'Emirates ID Approved - Awaiting Final';
    } else if (stage == 'FINAL') {
      stageText = 'Fully Approved';
    } else if (stage == 'REJECTED') {
      stageText = 'Rejected';
    }

    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(20.w),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [Colors.cyan.shade700, Colors.cyan.shade500],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16.r),
        boxShadow: [
          BoxShadow(
            color: Colors.cyan.withOpacity(0.2),
            blurRadius: 15.r,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    TweenAnimationBuilder<double>(
                      tween: Tween<double>(begin: 0, end: 1),
                      duration: const Duration(milliseconds: 800),
                      curve: Curves.easeOut,
                      builder: (context, value, child) {
                        return Transform.translate(
                          offset: Offset(0, 30 * (1 - value)),
                          child: Opacity(opacity: value, child: child),
                        );
                      },
                      child: Text(
                        'Registration Details',
                        style: TextStyle(
                          fontSize: 24.sp,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                    ),
                    SizedBox(height: 8.h),
                    Row(
                      children: [
                        TweenAnimationBuilder<double>(
                          tween: Tween<double>(begin: 0, end: 1),
                          duration: const Duration(milliseconds: 800),
                          curve: Curves.easeOut,
                          builder: (context, value, child) {
                            return Transform.translate(
                              offset: Offset(0, 30 * (1 - value)),
                              child: Opacity(opacity: value, child: child),
                            );
                          },
                          child: Text(
                            'ID: ${_registrationData!.id}',
                            style: TextStyle(
                              fontSize: 14.sp,
                              color: Colors.white70,
                            ),
                          ),
                        ),
                        SizedBox(width: 16.w),
                        Container(
                          padding: EdgeInsets.symmetric(
                            horizontal: 8.w,
                            vertical: 4.h,
                          ),
                          decoration: BoxDecoration(
                            color: statusColor.withOpacity(0.2),
                            borderRadius: BorderRadius.circular(12.r),
                          ),
                          child: Text(
                            status,
                            style: TextStyle(
                              fontSize: 12.sp,
                              fontWeight: FontWeight.bold,
                              color: statusColor,
                            ),
                          ),
                        ),
                      ],
                    ),
                    if (stageText.isNotEmpty) ...[
                      SizedBox(height: 8.h),
                      Container(
                        padding: EdgeInsets.symmetric(
                          horizontal: 10.w,
                          vertical: 6.h,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.2),
                          borderRadius: BorderRadius.circular(8.r),
                        ),
                        child: Text(
                          stageText,
                          style: TextStyle(
                            fontSize: 12.sp,
                            color: Colors.white,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              TweenAnimationBuilder<double>(
                tween: Tween<double>(begin: 0, end: 1),
                duration: const Duration(milliseconds: 800),
                curve: Curves.easeOut,
                builder: (context, value, child) {
                  return Transform.scale(scale: value, child: child);
                },
                child: Container(
                  width: 50.r,
                  height: 50.r,
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.2),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    _registrationData!.type == 'Contractor'
                        ? Icons.business_rounded
                        : Icons.format_paint_rounded,
                    color: Colors.white,
                    size: 24.r,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildPersonalDetailsCard(int cardIndex) {
    if (_registrationData == null) {
      return const SizedBox.shrink();
    }

    return ScaleTransition(
      scale: _cardAnimations[cardIndex],
      child: Container(
        padding: EdgeInsets.all(16.w),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12.r),
          boxShadow: [
            BoxShadow(
              color: Colors.grey.withOpacity(0.1),
              blurRadius: 10.r,
              offset: const Offset(0, 5),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width: 36.r,
                  height: 36.r,
                  decoration: BoxDecoration(
                    color: Colors.blue.withOpacity(0.1),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    Icons.person_rounded,
                    color: Colors.blue.shade700,
                    size: 18.r,
                  ),
                ),
                SizedBox(width: 12.w),
                Text(
                  'Personal Details',
                  style: TextStyle(
                    fontSize: 16.sp,
                    fontWeight: FontWeight.bold,
                    color: Colors.black87,
                  ),
                ),
              ],
            ),
            SizedBox(height: 16.h),
            _buildInfoRow('Full Name:', _registrationData!.fullName),
            _buildInfoRow('Address:', _registrationData!.address),
          ],
        ),
      ),
    );
  }

  Widget _buildBusinessDetailsCard(int cardIndex) {
    if (_registrationData == null) {
      return const SizedBox.shrink();
    }

    return ScaleTransition(
      scale: _cardAnimations[cardIndex],
      child: Container(
        padding: EdgeInsets.all(16.w),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12.r),
          boxShadow: [
            BoxShadow(
              color: Colors.grey.withOpacity(0.1),
              blurRadius: 10.r,
              offset: const Offset(0, 5),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width: 36.r,
                  height: 36.r,
                  decoration: BoxDecoration(
                    color: Colors.green.withOpacity(0.1),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    Icons.business_rounded,
                    color: Colors.green.shade700,
                    size: 18.r,
                  ),
                ),
                SizedBox(width: 12.w),
                Text(
                  'Business Details',
                  style: TextStyle(
                    fontSize: 16.sp,
                    fontWeight: FontWeight.bold,
                    color: Colors.black87,
                  ),
                ),
              ],
            ),
            SizedBox(height: 16.h),
            _buildInfoRow('Company Name:', _registrationData!.companyName),
            _buildInfoRow('License Number:', _registrationData!.licenseNumber),
          ],
        ),
      ),
    );
  }

  Widget _buildBankDetailsCard(int cardIndex) {
    if (_registrationData == null) {
      return const SizedBox.shrink();
    }

    return ScaleTransition(
      scale: _cardAnimations[cardIndex],
      child: Container(
        padding: EdgeInsets.all(16.w),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12.r),
          boxShadow: [
            BoxShadow(
              color: Colors.grey.withOpacity(0.1),
              blurRadius: 10.r,
              offset: const Offset(0, 5),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width: 36.r,
                  height: 36.r,
                  decoration: BoxDecoration(
                    color: Colors.purple.withOpacity(0.1),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    Icons.account_balance_rounded,
                    color: Colors.purple.shade700,
                    size: 18.r,
                  ),
                ),
                SizedBox(width: 12.w),
                Text(
                  'Bank Details',
                  style: TextStyle(
                    fontSize: 16.sp,
                    fontWeight: FontWeight.bold,
                    color: Colors.black87,
                  ),
                ),
              ],
            ),
            SizedBox(height: 16.h),
            _buildInfoRow('Account Holder:', _registrationData!.accountHolder),
            _buildInfoRow('IBAN:', _registrationData!.iban),
            _buildInfoRow('Bank Name:', _registrationData!.bankName),
            _buildInfoRow('Branch:', _registrationData!.branch),
          ],
        ),
      ),
    );
  }

  // Emirates ID Documents (Step 1)
  Widget _buildEmiratesIdDocumentsCard() {
    if (_registrationData == null) {
      return const SizedBox.shrink();
    }

    final documents = <DocumentItem>[];

    // Emirates ID documents
    if (_registrationData!.emiratesIdFront != null) {
      documents.add(
        DocumentItem(
          label: 'Emirates ID - Front',
          path: _registrationData!.emiratesIdFront,
          isNetworkImage: true,
        ),
      );
    }
    if (_registrationData!.emiratesIdBack != null) {
      documents.add(
        DocumentItem(
          label: 'Emirates ID - Back',
          path: _registrationData!.emiratesIdBack,
          isNetworkImage: true,
        ),
      );
    }

    if (documents.isEmpty) {
      return const SizedBox.shrink();
    }

    return DocumentViewerWidget(
      documents: documents,
      readOnly: true,
      padding: EdgeInsets.zero,
    );
  }

  // Personal Documents (Profile Photo)
  Widget _buildPersonalDocumentsCard() {
    if (_registrationData == null) {
      return const SizedBox.shrink();
    }

    final documents = <DocumentItem>[];

    // Profile photo
    if (_registrationData!.profilePhoto != null) {
      documents.add(
        DocumentItem(
          label: 'Profile Photo',
          path: _registrationData!.profilePhoto,
          isNetworkImage: true,
        ),
      );
    }

    if (documents.isEmpty) {
      return const SizedBox.shrink();
    }

    return DocumentViewerWidget(
      documents: documents,
      readOnly: true,
      padding: EdgeInsets.zero,
    );
  }

  // Business Documents (Contractor-specific)
  Widget _buildBusinessDocumentsCard() {
    if (_registrationData == null) {
      return const SizedBox.shrink();
    }

    // Only show for contractors
    if (!_registrationData!.type.toLowerCase().contains('contractor')) {
      return const SizedBox.shrink();
    }

    final documents = <DocumentItem>[];

    if (_registrationData!.contractorCertificate != null) {
      documents.add(
        DocumentItem(
          label: 'Contractor Certificate',
          path: _registrationData!.contractorCertificate,
          isNetworkImage: true,
        ),
      );
    }
    if (_registrationData!.vatCertificate != null) {
      documents.add(
        DocumentItem(
          label: 'VAT Certificate',
          path: _registrationData!.vatCertificate,
          isNetworkImage: true,
        ),
      );
    }
    if (_registrationData!.commercialLicense != null) {
      documents.add(
        DocumentItem(
          label: 'Commercial License',
          path: _registrationData!.commercialLicense,
          isNetworkImage: true,
        ),
      );
    }

    if (documents.isEmpty) {
      return const SizedBox.shrink();
    }

    return DocumentViewerWidget(
      documents: documents,
      readOnly: true,
      padding: EdgeInsets.zero,
    );
  }

  // Bank Documents
  Widget _buildBankDocumentsCard() {
    if (_registrationData == null) {
      return const SizedBox.shrink();
    }

    final documents = <DocumentItem>[];

    // Bank document
    if (_registrationData!.bankDocument != null) {
      documents.add(
        DocumentItem(
          label: 'Bank Document',
          path: _registrationData!.bankDocument,
          isNetworkImage: true,
        ),
      );
    }

    if (documents.isEmpty) {
      return const SizedBox.shrink();
    }

    return DocumentViewerWidget(
      documents: documents,
      readOnly: true,
      padding: EdgeInsets.zero,
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: EdgeInsets.only(bottom: 12.h),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 120.w,
            child: Text(
              label,
              style: TextStyle(
                fontSize: 14.sp,
                fontWeight: FontWeight.bold,
                color: Colors.grey.shade700,
              ),
            ),
          ),
          SizedBox(width: 8.w),
          Expanded(
            child: Text(
              value,
              style: TextStyle(fontSize: 14.sp, color: Colors.black87),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActionButtons() {
    if (_registrationData == null) return const SizedBox.shrink();

    final stage = _registrationData!.stage;
    final status = _registrationData!.status;

    // If already approved or rejected, show status only
    if (status == 'Approved' || status == 'Rejected') {
      return Container(
        padding: EdgeInsets.all(16.w),
        decoration: BoxDecoration(
          color: status == 'Approved'
              ? Colors.green.shade50
              : Colors.red.shade50,
          borderRadius: BorderRadius.circular(12.r),
          border: Border.all(
            color: status == 'Approved' ? Colors.green : Colors.red,
            width: 2,
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              status == 'Approved' ? Icons.check_circle : Icons.cancel,
              color: status == 'Approved' ? Colors.green : Colors.red,
              size: 24.r,
            ),
            SizedBox(width: 12.w),
            Text(
              'Registration ${status}',
              style: TextStyle(
                fontSize: 16.sp,
                fontWeight: FontWeight.bold,
                color: status == 'Approved'
                    ? Colors.green.shade700
                    : Colors.red.shade700,
              ),
            ),
          ],
        ),
      );
    }

    // Step-based approval buttons - only show when on the correct step for the current stage
    if (_currentStep == 0 && stage == 'EID_PENDING') {
      // Step 1: Approve Emirates ID (only when stage is EID_PENDING)
      return Row(
        children: [
          Expanded(
            flex: 2,
            child: ElevatedButton(
              onPressed: _approveEmiratesId,
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.blue,
                foregroundColor: Colors.white,
                elevation: 4,
                padding: EdgeInsets.symmetric(vertical: 16.h),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12.r),
                ),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.credit_card),
                  SizedBox(width: 8.w),
                  Text(
                    'Approve Emirates ID',
                    style: TextStyle(
                      fontSize: 15.sp,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),
          ),
          SizedBox(width: 12.w),
          Expanded(
            child: OutlinedButton(
              onPressed: () {
                _showRejectDialog(context);
              },
              style: OutlinedButton.styleFrom(
                foregroundColor: Colors.red,
                side: const BorderSide(color: Colors.red, width: 2),
                padding: EdgeInsets.symmetric(vertical: 16.h),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12.r),
                ),
              ),
              child: Text(
                'Reject',
                style: TextStyle(fontSize: 15.sp, fontWeight: FontWeight.bold),
              ),
            ),
          ),
        ],
      );
    } else if (_currentStep == 1 && stage == 'EID_APPROVED') {
      // Step 2: Final approval (only when stage is EID_APPROVED)
      return Row(
        children: [
          Expanded(
            flex: 2,
            child: ElevatedButton(
              onPressed: _approveFinal,
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.green,
                foregroundColor: Colors.white,
                elevation: 4,
                padding: EdgeInsets.symmetric(vertical: 16.h),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12.r),
                ),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.check_circle_rounded),
                  SizedBox(width: 8.w),
                  Text(
                    'Final Approval',
                    style: TextStyle(
                      fontSize: 15.sp,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),
          ),
          SizedBox(width: 12.w),
          Expanded(
            child: OutlinedButton(
              onPressed: () {
                _showRejectDialog(context);
              },
              style: OutlinedButton.styleFrom(
                foregroundColor: Colors.red,
                side: const BorderSide(color: Colors.red, width: 2),
                padding: EdgeInsets.symmetric(vertical: 16.h),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12.r),
                ),
              ),
              child: Text(
                'Reject',
                style: TextStyle(fontSize: 15.sp, fontWeight: FontWeight.bold),
              ),
            ),
          ),
        ],
      );
    } else if (_currentStep == 0 && stage == 'EID_APPROVED') {
      // Viewing Step 1 after it's already approved - show info message
      return Container(
        padding: EdgeInsets.all(16.w),
        decoration: BoxDecoration(
          color: Colors.blue.shade50,
          borderRadius: BorderRadius.circular(12.r),
          border: Border.all(color: Colors.blue.shade200),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.check_circle, color: Colors.blue.shade700, size: 20.r),
            SizedBox(width: 12.w),
            Text(
              'Emirates ID Already Approved',
              style: TextStyle(
                fontSize: 14.sp,
                fontWeight: FontWeight.bold,
                color: Colors.blue.shade700,
              ),
            ),
          ],
        ),
      );
    } else if (_currentStep == 1 && stage == 'EID_PENDING') {
      // Viewing Step 2 before Step 1 is approved - show info message
      return Container(
        padding: EdgeInsets.all(16.w),
        decoration: BoxDecoration(
          color: Colors.orange.shade50,
          borderRadius: BorderRadius.circular(12.r),
          border: Border.all(color: Colors.orange.shade200),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.info, color: Colors.orange.shade700, size: 20.r),
            SizedBox(width: 12.w),
            Expanded(
              child: Text(
                'Please approve Emirates ID first (Step 1)',
                style: TextStyle(
                  fontSize: 14.sp,
                  fontWeight: FontWeight.bold,
                  color: Colors.orange.shade700,
                ),
              ),
            ),
          ],
        ),
      );
    }

    // Default fallback
    return const SizedBox.shrink();
  }

  void _showRejectDialog(BuildContext context) {
    final TextEditingController commentController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) => Dialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16.r),
        ),
        child: Container(
          padding: EdgeInsets.all(24.w),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 60.r,
                height: 60.r,
                decoration: BoxDecoration(
                  color: Colors.red.withOpacity(0.1),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  Icons.cancel_rounded,
                  size: 30.r,
                  color: Colors.red,
                ),
              ),
              SizedBox(height: 16.h),
              Text(
                'Reject Registration',
                style: TextStyle(fontSize: 20.sp, fontWeight: FontWeight.bold),
              ),
              SizedBox(height: 16.h),
              Text(
                'Please provide a reason for rejection:',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 14.sp),
              ),
              SizedBox(height: 16.h),
              TextField(
                controller: commentController,
                decoration: InputDecoration(
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8.r),
                  ),
                  hintText: 'Enter rejection reason...',
                  contentPadding: EdgeInsets.all(12.w),
                ),
                maxLines: 3,
              ),
              SizedBox(height: 24.h),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () => Navigator.pop(context),
                      style: OutlinedButton.styleFrom(
                        padding: EdgeInsets.symmetric(vertical: 12.h),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8.r),
                        ),
                      ),
                      child: const Text('Cancel'),
                    ),
                  ),
                  SizedBox(width: 16.w),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () async {
                        Navigator.pop(context);
                        await _rejectRegistration(commentController.text);
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.red,
                        foregroundColor: Colors.white,
                        padding: EdgeInsets.symmetric(vertical: 12.h),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8.r),
                        ),
                      ),
                      child: const Text('Reject'),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
