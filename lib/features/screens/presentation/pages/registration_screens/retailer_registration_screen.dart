import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:go_router/go_router.dart';
import '../../../../../shared/widgets/custom_back_button.dart';
import '../../../../../shared/widgets/file_upload_widget.dart';
import 'dart:async';
import 'package:shared_preferences/shared_preferences.dart';

// NOTE: The original web code used JS interop for geolocation. For native
// platforms we will fetch location via a simple placeholder method that reads
// saved values from SharedPreferences (the project already stores last coords
// from other flows). Integrate a geolocation plugin later if needed.

class RetailerRegistrationScreen extends StatefulWidget {
  const RetailerRegistrationScreen({super.key});

  @override
  State<RetailerRegistrationScreen> createState() =>
      _RetailerRegistrationScreenState();
}

class _RetailerRegistrationScreenState extends State<RetailerRegistrationScreen>
    with TickerProviderStateMixin {
  late AnimationController _mainController;
  late AnimationController _fabController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;
  late Animation<double> _scaleAnimation;

  final _formKey = GlobalKey<FormState>();
  bool _isSubmitting = false;
  bool _isGettingLocation = false;

  // File paths
  String? _licenseImage;
  String? _vatCertificateImage;
  String? _bankStatementImage;
  String? _shopImage;

  // OCR/progress placeholders (kept minimal for now)
  // These are intentionally omitted until integrated with OCR services to avoid
  // unused-field lints.

  // Controllers
  final firmNameController = TextEditingController();
  final taxRegNumberController = TextEditingController();
  final registeredAddressController = TextEditingController();
  final effectiveDateController = TextEditingController();
  final licenseNumberController = TextEditingController();
  final issuingAuthorityController = TextEditingController();
  final establishmentDateController = TextEditingController();
  final expiryDateController = TextEditingController();
  final tradeNameController = TextEditingController();
  final responsiblePersonController = TextEditingController();
  final accountNameController = TextEditingController();
  final ibanController = TextEditingController();
  final bankNameController = TextEditingController();
  final branchNameController = TextEditingController();
  final branchAddressController = TextEditingController();
  final latitudeController = TextEditingController();
  final longitudeController = TextEditingController();

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

    // Try to load last saved coords from SharedPreferences
    _initLocation();
  }

  @override
  void dispose() {
    _mainController.dispose();
    _fabController.dispose();
    firmNameController.dispose();
    taxRegNumberController.dispose();
    registeredAddressController.dispose();
    effectiveDateController.dispose();
    licenseNumberController.dispose();
    issuingAuthorityController.dispose();
    establishmentDateController.dispose();
    expiryDateController.dispose();
    tradeNameController.dispose();
    responsiblePersonController.dispose();
    accountNameController.dispose();
    ibanController.dispose();
    bankNameController.dispose();
    branchNameController.dispose();
    branchAddressController.dispose();
    latitudeController.dispose();
    longitudeController.dispose();
    super.dispose();
  }

  Future<void> _initLocation() async {
    setState(() => _isGettingLocation = true);
    try {
      final prefs = await SharedPreferences.getInstance();
      final lastLat = prefs.getString('lastLat');
      final lastLng = prefs.getString('lastLng');
      if (lastLat != null && lastLng != null && mounted) {
        latitudeController.text = double.parse(lastLat).toStringAsFixed(6);
        longitudeController.text = double.parse(lastLng).toStringAsFixed(6);
      }
    } catch (e) {
      // ignore
    } finally {
      if (mounted) setState(() => _isGettingLocation = false);
    }
  }

  void _toast(String msg) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(msg), behavior: SnackBarBehavior.floating),
    );
  }

  Future<void> _saveData() async {
    setState(() => _isSubmitting = true);
    await Future.delayed(const Duration(seconds: 1));
    // TODO: call RetailerOnboardingService.registerRetailer
    _toast('Registration submitted (stub)');
    if (mounted) setState(() => _isSubmitting = false);
  }

  void _submitForm() async {
    if (_formKey.currentState?.validate() ?? false) {
      await _saveData();
    }
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
      leading: CustomBackButton(
        onPressed: () => context.pop(),
      ),
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

  void _showHelpDialog() {
    showDialog(
      context: context,
      builder: (context) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        child: Container(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(
                Icons.help_outline_rounded,
                size: 48,
                color: Colors.blue,
              ),
              const SizedBox(height: 16),
              const Text(
                'Registration Help',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 16),
              const Text(
                'Fill in all required fields marked with *.',
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 24),
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

  Widget _buildModernTextField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    bool isRequired = true,
    String? Function(String?)? validator,
    Widget? suffix,
  }) {
    return TextFormField(
      controller: controller,
      decoration: InputDecoration(
        labelText: isRequired ? '$label *' : label,
        prefixIcon: Icon(icon, color: Colors.grey.shade600),
        suffixIcon: suffix,
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
        filled: true,
        fillColor: Colors.grey.shade50,
      ),
      validator: validator,
    );
  }

  Widget _buildAnimatedSubmitButton() {
    return SizedBox(
      width: double.infinity,
      height: 56,
      child: ElevatedButton(
        onPressed: _isSubmitting ? null : _submitForm,
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.blue.shade700,
          foregroundColor: Colors.white,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        ),
        child: _isSubmitting
            ? const CircularProgressIndicator(color: Colors.white)
            : const Text('Submit Registration'),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey.shade50,
      appBar: _buildModernAppBar(),
      body: FadeTransition(
        opacity: _fadeAnimation,
        child: SlideTransition(
          position: _slideAnimation,
          child: SingleChildScrollView(
            padding: EdgeInsets.symmetric(horizontal: 24.w, vertical: 24.h),
            child: Center(
              child: ConstrainedBox(
                constraints: BoxConstraints(maxWidth: 1000.w),
                child: ScaleTransition(
                  scale: _scaleAnimation,
                  child: Form(
                    key: _formKey,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.all(20),
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              colors: [Colors.blue.shade700, Colors.blue.shade500],
                            ),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: const [
                              Text('Welcome!', style: TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.bold)),
                              SizedBox(height: 8),
                              Text('Complete your retailer registration', style: TextStyle(color: Colors.white70)),
                            ],
                          ),
                        ),
                        const SizedBox(height: 24),
                        // Sections (simplified from provided web code)
                        _buildSection(
                          title: 'Trade License Details',
                          icon: Icons.assignment_rounded,
                          children: [
                            _buildModernTextField(controller: licenseNumberController, label: 'License Number', icon: Icons.confirmation_number, validator: (v) => v == null || v.isEmpty ? 'Please enter license' : null),
                            const SizedBox(height: 12),
                            _buildModernTextField(controller: issuingAuthorityController, label: 'Issuing Authority', icon: Icons.account_balance),
                            const SizedBox(height: 12),
                            _buildModernTextField(controller: tradeNameController, label: 'Trade Name', icon: Icons.store),
                            const SizedBox(height: 12),
                            FileUploadWidget(
                              label: 'Trade License Document',
                              icon: Icons.assignment,
                              allowedExtensions: ['pdf', 'jpg', 'jpeg', 'png'],
                              maxSizeInMB: 10.0,
                              currentFilePath: _licenseImage,
                              onFileSelected: (filePath) async {
                                setState(() {
                                  _licenseImage = filePath;
                                });
                                if (filePath != null) _toast('Trade license uploaded');
                              },
                            ),
                          ],
                        ),
                        const SizedBox(height: 20),
                        _buildSection(
                          title: 'VAT Registration Details',
                          icon: Icons.receipt_long,
                          children: [
                            _buildModernTextField(controller: taxRegNumberController, label: 'Tax Registration Number', icon: Icons.numbers),
                            const SizedBox(height: 12),
                            _buildModernTextField(controller: firmNameController, label: 'Firm Name', icon: Icons.business),
                            const SizedBox(height: 12),
                            FileUploadWidget(
                              label: 'VAT Registration Certificate',
                              icon: Icons.receipt_long,
                              allowedExtensions: ['pdf', 'jpg', 'jpeg', 'png'],
                              maxSizeInMB: 10.0,
                              currentFilePath: _vatCertificateImage,
                              onFileSelected: (filePath) async {
                                setState(() {
                                  _vatCertificateImage = filePath;
                                });
                              },
                            ),
                          ],
                        ),
                        const SizedBox(height: 20),
                        _buildSection(
                          title: 'Bank Details',
                          icon: Icons.account_balance_outlined,
                          children: [
                            _buildModernTextField(controller: accountNameController, label: 'Account Holder Name', icon: Icons.person_outline_rounded, isRequired: false),
                            const SizedBox(height: 12),
                            _buildModernTextField(controller: ibanController, label: 'IBAN Number', icon: Icons.account_balance_wallet_outlined, isRequired: false),
                            const SizedBox(height: 12),
                            FileUploadWidget(
                              label: 'Bank Statement or Certificate',
                              icon: Icons.account_balance,
                              allowedExtensions: ['pdf', 'jpg', 'jpeg', 'png'],
                              maxSizeInMB: 10.0,
                              currentFilePath: _bankStatementImage,
                              onFileSelected: (filePath) async {
                                setState(() {
                                  _bankStatementImage = filePath;
                                });
                              },
                            ),
                          ],
                        ),
                        const SizedBox(height: 20),
                        _buildSection(
                          title: 'Location Details',
                          icon: Icons.location_on_outlined,
                          children: [
                            _buildModernTextField(controller: latitudeController, label: 'Latitude', icon: Icons.my_location, isRequired: false, validator: (v) => null, suffix: IconButton(icon: const Icon(Icons.gps_fixed), onPressed: _isGettingLocation ? null : () async { await _initLocation(); })),
                            const SizedBox(height: 12),
                            _buildModernTextField(controller: longitudeController, label: 'Longitude', icon: Icons.my_location, isRequired: false, validator: (v) => null, suffix: IconButton(icon: const Icon(Icons.gps_fixed), onPressed: _isGettingLocation ? null : () async { await _initLocation(); })),
                          ],
                        ),
                        const SizedBox(height: 20),
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
                              onFileSelected: (filePath) {
                                setState(() {
                                  _shopImage = filePath;
                                });
                              },
                            ),
                          ],
                        ),
                        const SizedBox(height: 24),
                        _buildAnimatedSubmitButton(),
                        const SizedBox(height: 48),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSection({required String title, required IconData icon, required List<Widget> children}) {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.03), blurRadius: 8)],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.blue.shade50,
              borderRadius: const BorderRadius.vertical(top: Radius.circular(12)),
            ),
            child: Row(
              children: [
                Container(width: 40, height: 40, decoration: const BoxDecoration(color: Colors.blue, shape: BoxShape.circle), child: Icon(icon, color: Colors.white)),
                const SizedBox(width: 12),
                Expanded(child: Text(title, style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.blue.shade800))),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: children),
          ),
        ],
      ),
    );
  }
}
