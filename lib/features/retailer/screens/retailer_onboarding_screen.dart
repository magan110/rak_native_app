import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:geolocator/geolocator.dart';
import 'package:go_router/go_router.dart';
import 'package:rak_app/core/services/location_service.dart';
import 'package:rak_app/core/utils/snackbar_utils.dart';
import 'package:rak_app/shared/widgets/file_upload_widget.dart';
import 'package:rak_app/shared/widgets/custom_back_button.dart';

// Retailer Onboarding native screen (converted from web code)

class RetailerOnboardingScreen extends StatefulWidget {
  const RetailerOnboardingScreen({super.key});

  @override
  State<RetailerOnboardingScreen> createState() =>
      _RetailerOnboardingScreenState();
}

class _RetailerOnboardingScreenState extends State<RetailerOnboardingScreen>
    with TickerProviderStateMixin {
  final _formKey = GlobalKey<FormState>();
  bool _isSubmitting = false;
  bool _isGettingLocation = false;

  // File placeholders
  String? _tradeLicenseFile;
  String? _vatFile;
  String? _bankFile;
  String? _shopImage;

  // Controllers
  final _firmNameController = TextEditingController();
  final _taxRegController = TextEditingController();
  final _licenseNumberController = TextEditingController();
  final _bankNameController = TextEditingController();
  final _ibanController = TextEditingController();
  final _latitudeController = TextEditingController();
  final _longitudeController = TextEditingController();

  late AnimationController _animController;
  late Animation<double> _fadeAnim;

  @override
  void initState() {
    super.initState();
    _animController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 700),
    );
    _fadeAnim = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(parent: _animController, curve: Curves.easeOut));
    _animController.forward();

    // Auto-fill location on load
    _initLocation();
  }

  Future<void> _initLocation() async {
    setState(() => _isGettingLocation = true);
    try {
      Position? position = await LocationService.getCurrentLocation();
      if (position != null && mounted) {
        _latitudeController.text = position.latitude.toStringAsFixed(6);
        _longitudeController.text = position.longitude.toStringAsFixed(6);
      }
    } catch (e) {
      print('Error getting location: $e');
    } finally {
      if (mounted) setState(() => _isGettingLocation = false);
    }
  }

  @override
  void dispose() {
    _animController.dispose();
    _firmNameController.dispose();
    _taxRegController.dispose();
    _licenseNumberController.dispose();
    _bankNameController.dispose();
    _ibanController.dispose();
    _latitudeController.dispose();
    _longitudeController.dispose();
    super.dispose();
  }

  void _showSnack(String msg) {
    if (!mounted) return;
    AppSnackBar.showInfo(context, msg);
  }

  Future<void> _submit() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;
    setState(() => _isSubmitting = true);
    await Future.delayed(const Duration(seconds: 1));
    _showSnack('Retailer onboarding submitted (stub)');
    if (mounted) setState(() => _isSubmitting = false);
  }

  PreferredSizeWidget _buildModernAppBar() {
    return AppBar(
      elevation: 0,
      backgroundColor: Colors.transparent,
      foregroundColor: Colors.blue.shade800,
      systemOverlayStyle: const SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: Brightness.dark,
      ),
      leading: CustomBackButton(onPressed: () => context.pop()),
      title: const Text(
        'Retailer Onboarding',
        style: TextStyle(fontWeight: FontWeight.w600, fontSize: 20),
      ),
      actions: [
        IconButton(
          icon: const Icon(Icons.help_outline_rounded),
          onPressed: _showHelpDialog,
        ),
      ],
    );
  }

  Widget _buildAnimatedHeader() {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(30.w),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [Colors.blue.shade700, Colors.blue.shade500],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20.r),
        boxShadow: [
          BoxShadow(
            color: Colors.blue.withOpacity(0.2),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Welcome!',
            style: TextStyle(
              fontSize: 32.sp,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
          SizedBox(height: 8.h),
          Text(
            'Complete your retailer registration',
            style: TextStyle(fontSize: 16.sp, color: Colors.white70),
          ),
        ],
      ),
    );
  }

  Widget _buildModernSection({
    required String title,
    required IconData icon,
    required List<Widget> children,
    bool isOptional = false,
  }) {
    return Container(
      margin: EdgeInsets.only(bottom: 24.h),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16.r),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            blurRadius: 10,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: EdgeInsets.all(20.w),
            decoration: BoxDecoration(
              color: Colors.blue.shade50,
              borderRadius: BorderRadius.vertical(top: Radius.circular(16.r)),
            ),
            child: Row(
              children: [
                Container(
                  width: 48.w,
                  height: 48.w,
                  decoration: BoxDecoration(
                    color: Colors.blue,
                    shape: BoxShape.circle,
                  ),
                  child: Icon(icon, color: Colors.white, size: 24.w),
                ),
                SizedBox(width: 16.w),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: TextStyle(
                          fontSize: 18.sp,
                          fontWeight: FontWeight.bold,
                          color: Colors.blue.shade800,
                        ),
                      ),
                      if (isOptional)
                        Text(
                          'Optional',
                          style: TextStyle(
                            fontSize: 12.sp,
                            color: Colors.grey.shade500,
                          ),
                        ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          Padding(
            padding: EdgeInsets.all(20.w),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: children,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildModernTextField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    bool isRequired = true,
    Widget? suffix,
  }) {
    return TextFormField(
      controller: controller,
      decoration: InputDecoration(
        labelText: isRequired ? '$label *' : label,
        prefixIcon: Icon(icon, color: Colors.grey.shade600),
        suffixIcon: suffix,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12.r),
          borderSide: BorderSide(color: Colors.grey.shade300),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12.r),
          borderSide: BorderSide(color: Colors.grey.shade300),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12.r),
          borderSide: BorderSide(color: Colors.blue, width: 2),
        ),
        filled: true,
        fillColor: Colors.grey.shade50,
        contentPadding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 16.h),
      ),
      validator: isRequired
          ? (v) => v == null || v.isEmpty ? 'Required' : null
          : null,
    );
  }

  Widget _buildModernDateField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    required BuildContext context,
    bool isRequired = true,
  }) {
    return TextFormField(
      controller: controller,
      readOnly: true,
      decoration: InputDecoration(
        labelText: isRequired ? '$label *' : label,
        prefixIcon: Icon(icon, color: Colors.grey.shade600),
        suffixIcon: const Icon(
          Icons.calendar_today_rounded,
          color: Colors.grey,
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12.r),
          borderSide: BorderSide(color: Colors.grey.shade300),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12.r),
          borderSide: BorderSide(color: Colors.grey.shade300),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12.r),
          borderSide: BorderSide(color: Colors.blue, width: 2),
        ),
        filled: true,
        fillColor: Colors.grey.shade50,
        contentPadding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 16.h),
      ),
      onTap: () async {
        final date = await showDatePicker(
          context: context,
          initialDate: DateTime.now(),
          firstDate: DateTime(1900),
          lastDate: DateTime(2100),
          builder: (context, child) => Theme(
            data: Theme.of(context).copyWith(
              colorScheme: const ColorScheme.light(primary: Colors.blue),
            ),
            child: child!,
          ),
        );
        if (date != null && mounted) {
          controller.text = date.toString().split(' ').first;
        }
      },
      validator: isRequired
          ? (v) => v == null || v.isEmpty ? 'Required' : null
          : null,
    );
  }

  void _showHelpDialog() {
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
              Icon(Icons.help_outline_rounded, size: 48.w, color: Colors.blue),
              SizedBox(height: 16.h),
              Text(
                'Registration Help',
                style: TextStyle(fontSize: 20.sp, fontWeight: FontWeight.bold),
              ),
              SizedBox(height: 16.h),
              Text(
                'Fill in all required fields marked with *.\nVAT Registration is required only if your firm\'s Annual Turnover exceeds AED 375,000.',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 14.sp),
              ),
              SizedBox(height: 24.h),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('Got it'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey.shade50,
      appBar: _buildModernAppBar(),
      body: FadeTransition(
        opacity: _fadeAnim,
        child: SingleChildScrollView(
          padding: EdgeInsets.symmetric(horizontal: 20.w, vertical: 20.h),
          child: Center(
            child: ConstrainedBox(
              constraints: BoxConstraints(maxWidth: 600.w),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildAnimatedHeader(),
                    SizedBox(height: 32.h),

                    _buildModernSection(
                      title: 'Trade License Details',
                      icon: Icons.assignment_rounded,
                      children: [
                        _buildModernTextField(
                          controller: _licenseNumberController,
                          label: 'License Number',
                          icon: Icons.confirmation_number,
                        ),
                        SizedBox(height: 16.h),
                        FileUploadWidget(
                          label: 'Upload Trade License',
                          icon: Icons.assignment,
                          allowedExtensions: ['pdf', 'jpg', 'jpeg', 'png'],
                          maxSizeInMB: 10.0,
                          currentFilePath: _tradeLicenseFile,
                          onFileSelected: (path) {
                            setState(() => _tradeLicenseFile = path);
                            if (path != null)
                              _showSnack('Trade license selected');
                          },
                        ),
                        SizedBox(height: 12.h),
                        Container(
                          padding: EdgeInsets.all(12.w),
                          decoration: BoxDecoration(
                            color: Colors.green.shade50,
                            borderRadius: BorderRadius.circular(8.r),
                            border: Border.all(color: Colors.green.shade200),
                          ),
                          child: Row(
                            children: [
                              Icon(
                                Icons.auto_fix_high,
                                color: Colors.green.shade700,
                              ),
                              SizedBox(width: 8.w),
                              Expanded(
                                child: Text(
                                  'Upload your trade license document for verification.',
                                  style: TextStyle(
                                    fontSize: 12.sp,
                                    color: Colors.green.shade700,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),

                    _buildModernSection(
                      title: 'VAT Registration',
                      icon: Icons.receipt_long,
                      isOptional: true,
                      children: [
                        _buildModernTextField(
                          controller: _taxRegController,
                          label: 'Tax Registration Number',
                          icon: Icons.numbers,
                        ),
                        SizedBox(height: 16.h),
                        _buildModernTextField(
                          controller: _firmNameController,
                          label: 'Firm Name',
                          icon: Icons.business,
                        ),
                        SizedBox(height: 16.h),
                        FileUploadWidget(
                          label: 'VAT Certificate',
                          icon: Icons.receipt_long,
                          allowedExtensions: ['pdf', 'jpg', 'jpeg', 'png'],
                          maxSizeInMB: 10.0,
                          currentFilePath: _vatFile,
                          onFileSelected: (path) {
                            setState(() => _vatFile = path);
                          },
                        ),
                        SizedBox(height: 12.h),
                        Container(
                          padding: EdgeInsets.all(12.w),
                          decoration: BoxDecoration(
                            color: Colors.orange.shade50,
                            borderRadius: BorderRadius.circular(8.r),
                            border: Border.all(color: Colors.orange.shade200),
                          ),
                          child: Row(
                            children: [
                              Icon(
                                Icons.info_outline,
                                color: Colors.orange.shade700,
                              ),
                              SizedBox(width: 8.w),
                              Expanded(
                                child: Text(
                                  'Required only if annual turnover exceeds AED 375,000.',
                                  style: TextStyle(fontSize: 12.sp),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),

                    _buildModernSection(
                      title: 'Bank Details',
                      icon: Icons.account_balance_outlined,
                      isOptional: true,
                      children: [
                        _buildModernTextField(
                          controller: _bankNameController,
                          label: 'Bank Name',
                          icon: Icons.account_balance,
                          isRequired: false,
                        ),
                        SizedBox(height: 16.h),
                        _buildModernTextField(
                          controller: _ibanController,
                          label: 'IBAN',
                          icon: Icons.account_balance_wallet_outlined,
                          isRequired: false,
                        ),
                        SizedBox(height: 16.h),
                        FileUploadWidget(
                          label: 'Bank Statement',
                          icon: Icons.attach_file,
                          allowedExtensions: ['pdf', 'jpg', 'jpeg', 'png'],
                          maxSizeInMB: 10.0,
                          currentFilePath: _bankFile,
                          onFileSelected: (path) =>
                              setState(() => _bankFile = path),
                        ),
                        SizedBox(height: 12.h),
                        Container(
                          padding: EdgeInsets.all(12.w),
                          decoration: BoxDecoration(
                            color: Colors.green.shade50,
                            borderRadius: BorderRadius.circular(8.r),
                            border: Border.all(color: Colors.green.shade200),
                          ),
                          child: Row(
                            children: [
                              Icon(
                                Icons.info_outline,
                                color: Colors.green.shade700,
                              ),
                              SizedBox(width: 8.w),
                              Expanded(
                                child: Text(
                                  'Upload your bank statement for verification.',
                                  style: TextStyle(fontSize: 12.sp),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),

                    _buildModernSection(
                      title: 'Location',
                      icon: Icons.location_on_outlined,
                      isOptional: true,
                      children: [
                        _buildModernTextField(
                          controller: _latitudeController,
                          label: 'Latitude',
                          icon: Icons.my_location,
                          isRequired: false,
                          suffix: IconButton(
                            tooltip: 'Refresh location',
                            icon: const Icon(Icons.gps_fixed),
                            onPressed: _isGettingLocation
                                ? null
                                : () async {
                                    HapticFeedback.selectionClick();
                                    await _initLocation();
                                  },
                          ),
                        ),
                        SizedBox(height: 16.h),
                        _buildModernTextField(
                          controller: _longitudeController,
                          label: 'Longitude',
                          icon: Icons.my_location,
                          isRequired: false,
                          suffix: IconButton(
                            tooltip: 'Refresh location',
                            icon: const Icon(Icons.gps_fixed),
                            onPressed: _isGettingLocation
                                ? null
                                : () async {
                                    HapticFeedback.selectionClick();
                                    await _initLocation();
                                  },
                          ),
                        ),
                        SizedBox(height: 8.h),
                        Row(
                          children: [
                            Icon(
                              Icons.info_outline,
                              size: 16.w,
                              color: Colors.grey,
                            ),
                            SizedBox(width: 6.w),
                            Expanded(
                              child: Text(
                                _isGettingLocation
                                    ? 'Fetching GPS…'
                                    : (_latitudeController.text.isEmpty ||
                                          _longitudeController.text.isEmpty)
                                    ? 'Tap the GPS icon if fields are empty.'
                                    : 'Coordinates captured from your device GPS.',
                                style: TextStyle(
                                  fontSize: 12.sp,
                                  color: Colors.grey.shade700,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),

                    _buildModernSection(
                      title: 'Shop Image',
                      icon: Icons.storefront,
                      isOptional: true,
                      children: [
                        FileUploadWidget(
                          label: 'Shop Front Image',
                          icon: Icons.camera_alt,
                          allowedExtensions: ['jpg', 'jpeg', 'png'],
                          maxSizeInMB: 15.0,
                          currentFilePath: _shopImage,
                          onFileSelected: (path) =>
                              setState(() => _shopImage = path),
                        ),
                        SizedBox(height: 16.h),
                        Container(
                          padding: EdgeInsets.all(12.w),
                          decoration: BoxDecoration(
                            color: Colors.green.shade50,
                            borderRadius: BorderRadius.circular(8.r),
                            border: Border.all(color: Colors.green.shade200),
                          ),
                          child: Row(
                            children: [
                              Icon(
                                Icons.info_outline,
                                color: Colors.green.shade700,
                              ),
                              SizedBox(width: 8.w),
                              Expanded(
                                child: Text(
                                  'Upload a clear image of your shop front for verification purposes.',
                                  style: TextStyle(fontSize: 12.sp),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),

                    SizedBox(height: 32.h),
                    SizedBox(
                      width: double.infinity,
                      height: 52.h,
                      child: ElevatedButton(
                        onPressed: _isSubmitting ? null : _submit,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.blue.shade700,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12.r),
                          ),
                        ),
                        child: _isSubmitting
                            ? const CircularProgressIndicator(
                                color: Colors.white,
                              )
                            : Text(
                                'Submit Registration',
                                style: TextStyle(
                                  fontSize: 16.sp,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                      ),
                    ),
                    SizedBox(height: 30.h),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
