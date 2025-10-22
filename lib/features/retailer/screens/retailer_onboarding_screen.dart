import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:rak_app/shared/widgets/file_upload_widget.dart';
import 'package:rak_app/shared/widgets/custom_back_button.dart';

// Retailer Onboarding native screen (converted from web code)
class RetailerOnboardingScreen extends StatefulWidget {
  const RetailerOnboardingScreen({super.key});

  @override
  State<RetailerOnboardingScreen> createState() => _RetailerOnboardingScreenState();
}

class _RetailerOnboardingScreenState extends State<RetailerOnboardingScreen> with TickerProviderStateMixin {
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
    _animController = AnimationController(vsync: this, duration: const Duration(milliseconds: 700));
    _fadeAnim = Tween<double>(begin: 0.0, end: 1.0).animate(CurvedAnimation(parent: _animController, curve: Curves.easeOut));
    _animController.forward();
    _loadLastLocation();
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

  Future<void> _loadLastLocation() async {
    setState(() => _isGettingLocation = true);
    try {
      final prefs = await SharedPreferences.getInstance();
      final lat = prefs.getString('lastLat');
      final lng = prefs.getString('lastLng');
      if (lat != null && lng != null && mounted) {
        _latitudeController.text = double.parse(lat).toStringAsFixed(6);
        _longitudeController.text = double.parse(lng).toStringAsFixed(6);
      }
    } catch (_) {}
    if (mounted) setState(() => _isGettingLocation = false);
  }

  void _showSnack(String msg) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg), behavior: SnackBarBehavior.floating));
  }

  Future<void> _submit() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;
    setState(() => _isSubmitting = true);
    await Future.delayed(const Duration(seconds: 1));
    // TODO: wire up RetailerOnboardingService.registerRetailer
    _showSnack('Retailer onboarding submitted (stub)');
    if (mounted) setState(() => _isSubmitting = false);
  }

  PreferredSizeWidget _buildAppBar() {
    return AppBar(
      elevation: 0,
      backgroundColor: Colors.transparent,
      leading: CustomBackButton(onPressed: () => context.pop()),
      title: const Text('Retailer Onboarding', style: TextStyle(fontWeight: FontWeight.w600)),
      systemOverlayStyle: const SystemUiOverlayStyle(statusBarColor: Colors.transparent, statusBarIconBrightness: Brightness.dark),
    );
  }

  Widget _buildTextField({required TextEditingController controller, required String label, IconData? icon, bool requiredField = true, Widget? suffix}) {
    return TextFormField(
      controller: controller,
      decoration: InputDecoration(
        labelText: requiredField ? '$label *' : label,
        prefixIcon: icon != null ? Icon(icon, color: Colors.grey[600]) : null,
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12.r)),
        filled: true,
        fillColor: Colors.grey.shade50,
        suffixIcon: suffix,
      ),
      validator: requiredField ? (v) => v == null || v.isEmpty ? 'Required' : null : null,
    );
  }

  Widget _buildSection({required String title, required IconData icon, required List<Widget> children}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(icon, color: Colors.blue.shade700, size: 18.sp),
            SizedBox(width: 8.w),
            Text(title, style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14.sp)),
          ],
        ),
        SizedBox(height: 8.h),
        ...children,
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey.shade50,
      appBar: _buildAppBar(),
      body: FadeTransition(
        opacity: _fadeAnim,
        child: SingleChildScrollView(
          padding: EdgeInsets.symmetric(horizontal: 20.w, vertical: 20.h),
          child: Center(
            child: ConstrainedBox(
              constraints: BoxConstraints(maxWidth: 1000.w),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      width: double.infinity,
                      padding: EdgeInsets.all(16.w),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(colors: [Colors.blue.shade700, Colors.blue.shade500]),
                        borderRadius: BorderRadius.circular(12.r),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Welcome!', style: TextStyle(color: Colors.white, fontSize: 20.sp, fontWeight: FontWeight.bold)),
                          SizedBox(height: 6.h),
                          Text('Complete your retailer registration', style: TextStyle(color: Colors.white70, fontSize: 12.sp)),
                        ],
                      ),
                    ),
                    SizedBox(height: 20.h),

                    _buildSection(
                      title: 'Trade License',
                      icon: Icons.assignment_rounded,
                      children: [
                        _buildTextField(controller: _licenseNumberController, label: 'License Number', icon: Icons.confirmation_number),
                        SizedBox(height: 10.h),
                        FileUploadWidget(
                          label: 'Upload Trade License',
                          icon: Icons.assignment,
                          allowedExtensions: ['pdf', 'jpg', 'jpeg', 'png'],
                          maxSizeInMB: 10.0,
                          currentFilePath: _tradeLicenseFile,
                          onFileSelected: (path) {
                            setState(() => _tradeLicenseFile = path);
                            if (path != null) _showSnack('Trade license selected');
                          },
                        ),
                      ],
                    ),

                    SizedBox(height: 16.h),
                    _buildSection(
                      title: 'VAT Registration',
                      icon: Icons.receipt_long,
                      children: [
                        _buildTextField(controller: _taxRegController, label: 'Tax Registration Number', icon: Icons.numbers),
                        SizedBox(height: 10.h),
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
                      ],
                    ),

                    SizedBox(height: 16.h),
                    _buildSection(
                      title: 'Bank Details',
                      icon: Icons.account_balance,
                      children: [
                        _buildTextField(controller: _bankNameController, label: 'Bank Name', icon: Icons.account_balance),
                        SizedBox(height: 10.h),
                        _buildTextField(controller: _ibanController, label: 'IBAN', icon: Icons.account_balance_wallet_outlined, requiredField: false),
                        SizedBox(height: 10.h),
                        FileUploadWidget(
                          label: 'Bank Statement',
                          icon: Icons.attach_file,
                          allowedExtensions: ['pdf', 'jpg', 'jpeg', 'png'],
                          maxSizeInMB: 10.0,
                          currentFilePath: _bankFile,
                          onFileSelected: (path) => setState(() => _bankFile = path),
                        ),
                      ],
                    ),

                    SizedBox(height: 16.h),
                    _buildSection(
                      title: 'Location',
                      icon: Icons.location_on_outlined,
                      children: [
                        _buildTextField(
                          controller: _latitudeController,
                          label: 'Latitude',
                          icon: Icons.my_location,
                          requiredField: false,
                          suffix: IconButton(icon: Icon(Icons.gps_fixed), onPressed: _isGettingLocation ? null : () async => await _loadLastLocation()),
                        ),
                        SizedBox(height: 10.h),
                        _buildTextField(
                          controller: _longitudeController,
                          label: 'Longitude',
                          icon: Icons.my_location,
                          requiredField: false,
                          suffix: IconButton(icon: Icon(Icons.gps_fixed), onPressed: _isGettingLocation ? null : () async => await _loadLastLocation()),
                        ),
                      ],
                    ),

                    SizedBox(height: 16.h),
                    _buildSection(
                      title: 'Shop Image',
                      icon: Icons.storefront,
                      children: [
                        FileUploadWidget(
                          label: 'Shop Front Image',
                          icon: Icons.camera_alt,
                          allowedExtensions: ['jpg', 'jpeg', 'png'],
                          maxSizeInMB: 15.0,
                          currentFilePath: _shopImage,
                          onFileSelected: (path) => setState(() => _shopImage = path),
                        ),
                      ],
                    ),

                    SizedBox(height: 22.h),
                    SizedBox(
                      width: double.infinity,
                      height: 52.h,
                      child: ElevatedButton(
                        onPressed: _isSubmitting ? null : _submit,
                        style: ElevatedButton.styleFrom(backgroundColor: Colors.blue.shade700, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12.r))),
                        child: _isSubmitting ? const CircularProgressIndicator(color: Colors.white) : Text('Submit Registration', style: TextStyle(fontSize: 16.sp, fontWeight: FontWeight.w600)),
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
