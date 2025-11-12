import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:rak_app/core/models/approval_models.dart';
import 'package:rak_app/core/services/approval_service.dart';
import 'package:rak_app/core/theme/theme.dart';
import 'package:rak_app/shared/widgets/custom_back_button.dart';

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

  Future<void> _approveRegistration() async {
    if (_registrationData == null || _registrationData!.id.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('No registration ID available for approval'),
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
            Text('Approving registration...'),
          ],
        ),
        duration: Duration(seconds: 30),
      ),
    );

    try {
      // Get the inflCode for this item (same as approval dashboard)
      final inflCode = await _approvalService.lookupInflCode(_registrationData!.id);
      
      // Approve the item using inflCode
      await _approvalService.approveItem(inflCode);
      
      // Hide loading and show success
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
      // Hide loading and show error
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
      final inflCode = await _approvalService.lookupInflCode(_registrationData!.id);
      
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
            // Registration Information Card
            _buildRegistrationInfoCard(0),
            SizedBox(height: 16.h),
            // Personal Details Card
            _buildPersonalDetailsCard(1),
            SizedBox(height: 16.h),
            // Business Details Card
            _buildBusinessDetailsCard(2),
            SizedBox(height: 16.h),
            // Bank Details Card
            _buildBankDetailsCard(3),
            SizedBox(height: 24.h),
            // Action Buttons
            _buildActionButtons(),
            SizedBox(height: 24.h),
          ],
        ),
      ),
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

    final statusColor = _registrationData!.status == 'Pending'
        ? Colors.orange
        : _registrationData!.status == 'Approved'
        ? Colors.green
        : Colors.red;

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
                            _registrationData!.status,
                            style: TextStyle(
                              fontSize: 12.sp,
                              fontWeight: FontWeight.bold,
                              color: statusColor,
                            ),
                          ),
                        ),
                      ],
                    ),
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

  Widget _buildRegistrationInfoCard(int cardIndex) {
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
                  'Registration Information',
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
            _buildInfoRow('Name:', _registrationData!.name),
            _buildInfoRow('Type:', _registrationData!.type),
            _buildInfoRow('Mobile:', _registrationData!.mobile),
            _buildInfoRow('Submitted Date:', _registrationData!.submittedDate),
            _buildInfoRow('Status:', _registrationData!.status),
          ],
        ),
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
    return Row(
      children: [
        Expanded(
          child: ElevatedButton(
            onPressed: () {
              _showApproveDialog(context);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.green,
              foregroundColor: Colors.white,
              elevation: 4,
              padding: EdgeInsets.symmetric(vertical: 12.h),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8.r),
              ),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.check_circle_rounded),
                SizedBox(width: 8.w),
                Text(
                  'Approve',
                  style: TextStyle(
                    fontSize: 14.sp,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
        ),
        SizedBox(width: 16.w),
        Expanded(
          child: ElevatedButton(
            onPressed: () {
              _showRejectDialog(context);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
              elevation: 4,
              padding: EdgeInsets.symmetric(vertical: 12.h),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8.r),
              ),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.cancel_rounded),
                SizedBox(width: 8.w),
                Text(
                  'Reject',
                  style: TextStyle(
                    fontSize: 14.sp,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  void _showApproveDialog(BuildContext context) {
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
                  color: Colors.green.withOpacity(0.1),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  Icons.check_circle_rounded,
                  size: 30.r,
                  color: Colors.green,
                ),
              ),
              SizedBox(height: 16.h),
              Text(
                'Approve Registration',
                style: TextStyle(fontSize: 20.sp, fontWeight: FontWeight.bold),
              ),
              SizedBox(height: 16.h),
              Text(
                'Are you sure you want to approve this registration?',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 14.sp),
              ),
              SizedBox(height: 8.h),
              Container(
                padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 8.h),
                decoration: BoxDecoration(
                  color: Colors.green.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12.r),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.star_rounded, color: Colors.amber, size: 16.r),
                    SizedBox(width: 4.w),
                    Flexible(
                      child: Text(
                        '100 bonus points will be awarded upon approval.',
                        style: TextStyle(
                          fontSize: 12.sp,
                          fontWeight: FontWeight.w500,
                          color: const Color.fromARGB(255, 19, 149, 255),
                        ),
                      ),
                    ),
                  ],
                ),
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
                      child: Text('Cancel', style: AppTheme.body),
                    ),
                  ),
                  SizedBox(width: 16.w),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () async {
                        Navigator.pop(context);
                        await _approveRegistration();
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.green,
                        foregroundColor: Colors.white,
                        padding: EdgeInsets.symmetric(vertical: 12.h),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8.r),
                        ),
                      ),
                      child: Text(
                        'Approve',
                        style: AppTheme.success.copyWith(color: Colors.white),
                      ),
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
