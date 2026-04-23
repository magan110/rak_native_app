import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../shared/widgets/modern_dropdown.dart';
import '../../core/models/sample_distribution_models.dart';
import '../../core/services/sample_distribution_service.dart';
import '../../core/utils/uae_phone_utils.dart';

class SampleDistributionEntryScreen extends StatefulWidget {
  const SampleDistributionEntryScreen({super.key});

  @override
  State<SampleDistributionEntryScreen> createState() =>
      _SampleDistributionEntryScreenState();
}

class _SampleDistributionEntryScreenState
    extends State<SampleDistributionEntryScreen>
    with TickerProviderStateMixin {
  // Controllers
  final emirateController = TextEditingController();
  final retailerNameController = TextEditingController();
  final retailerCodeController = TextEditingController();
  final distributorController = TextEditingController();
  final painterNameController = TextEditingController();
  final painterMobileController = TextEditingController();
  final materialQtyController = TextEditingController();
  final distributionDateController = TextEditingController();

  List<SupplyChainEntry> currentEntries = [];
  List<AreaItem> _emirates = [];
  AreaItem? _selectedEmirate;

  // Animation controllers
  late AnimationController _mainController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;

  bool _isSubmitting = false;
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();

  @override
  void initState() {
    super.initState();
    _loadEmirates();

    // Initialize animations
    _mainController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );

    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _mainController,
        curve: const Interval(0.0, 0.5, curve: Curves.easeOut),
      ),
    );

    _slideAnimation =
        Tween<Offset>(begin: const Offset(0, 0.2), end: Offset.zero).animate(
          CurvedAnimation(
            parent: _mainController,
            curve: const Interval(0.2, 0.7, curve: Curves.easeOutCubic),
          ),
        );

    _mainController.forward();
  }

  Future<void> _loadEmirates() async {
    try {
      final areas = await SampleDistributionService.getAreas(onlyActive: true);
      setState(() {
        _emirates = areas;
      });
    } catch (e) {
      setState(() {
        _emirates = [
          AreaItem(code: 'DUB', desc: 'Dubai'),
          AreaItem(code: 'ABD', desc: 'Abu Dhabi'),
          AreaItem(code: 'SHJ', desc: 'Sharjah'),
          AreaItem(code: 'AJM', desc: 'Ajman'),
          AreaItem(code: 'UAQ', desc: 'Umm Al Quwain'),
          AreaItem(code: 'RAK', desc: 'Ras Al Khaimah'),
          AreaItem(code: 'FUJ', desc: 'Fujairah'),
        ];
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error loading areas: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  void dispose() {
    _mainController.dispose();
    emirateController.dispose();
    retailerNameController.dispose();
    retailerCodeController.dispose();
    distributorController.dispose();
    painterNameController.dispose();
    painterMobileController.dispose();
    materialQtyController.dispose();
    distributionDateController.dispose();
    super.dispose();
  }

  void _submitForm() async {
    if (_formKey.currentState!.validate()) {
      setState(() => _isSubmitting = true);

      try {
        final prefs = await SharedPreferences.getInstance();

        // Create request object
        final request = SampleDistributionRequest(
          emirate: _selectedEmirate?.code ?? emirateController.text,
          retailerName: retailerNameController.text,
          retailerCode: retailerCodeController.text.isEmpty
              ? null
              : retailerCodeController.text,
          distributor: distributorController.text,
          painterName: painterNameController.text,
          painterMobile: painterMobileController.text.isEmpty
              ? null
              : painterMobileController.text,
          materialQty: materialQtyController.text.isEmpty
              ? null
              : materialQtyController.text,
          distributionDate: distributionDateController.text,
        );

        // Submit to API
        final response =
            await SampleDistributionService.submitSampleDistribution(request);

        if (response.success) {
          // Save to local storage on success
          await prefs.setString('Emirate', emirateController.text);
          await prefs.setString('retailerName', retailerNameController.text);
          await prefs.setString('retailerCode', retailerCodeController.text);
          await prefs.setString('distributor', distributorController.text);
          await prefs.setString('painterName', painterNameController.text);
          await prefs.setString('painterMobile', painterMobileController.text);
          await prefs.setString('materialQty', materialQtyController.text);
          await prefs.setString(
            'distributionDate',
            distributionDateController.text,
          );

          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Row(
                  children: [
                    const Icon(
                      Icons.check_circle,
                      color: Colors.white,
                      size: 20,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        '${response.message}${response.docuNumb != null ? ' (Doc: ${response.docuNumb})' : ''}',
                      ),
                    ),
                  ],
                ),
                backgroundColor: Colors.green,
                behavior: SnackBarBehavior.floating,
                duration: const Duration(seconds: 4),
              ),
            );
          }
        } else {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Row(
                  children: [
                    const Icon(Icons.error, color: Colors.white, size: 20),
                    const SizedBox(width: 8),
                    Expanded(child: Text(response.message)),
                  ],
                ),
                backgroundColor: Colors.red,
                behavior: SnackBarBehavior.floating,
                duration: const Duration(seconds: 4),
              ),
            );
          }
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Row(
                children: [
                  const Icon(Icons.warning, color: Colors.white, size: 20),
                  const SizedBox(width: 8),
                  Expanded(child: Text('Error saving data: ${e.toString()}')),
                ],
              ),
              backgroundColor: Colors.orange,
              behavior: SnackBarBehavior.floating,
              duration: const Duration(seconds: 4),
            ),
          );
        }
      } finally {
        if (mounted) {
          setState(() => _isSubmitting = false);
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: _buildModernAppBar(),
      body: FadeTransition(
        opacity: _fadeAnimation,
        child: SlideTransition(
          position: _slideAnimation,
          child: SingleChildScrollView(
            padding: EdgeInsets.symmetric(horizontal: 20.w, vertical: 20.h),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildAnimatedHeader(),
                  SizedBox(height: 24.h),
                  _buildRetailerSection(),
                  SizedBox(height: 20.h),
                  _buildDistributionSection(),
                  SizedBox(height: 32.h),
                  if (currentEntries.isNotEmpty) _buildSupplyChainTable(),
                  SizedBox(height: 20.h),
                  _buildSubmitButton(),
                  SizedBox(height: 32.h),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  PreferredSizeWidget _buildModernAppBar() {
    return AppBar(
      elevation: 0,
      backgroundColor: Colors.white,
      foregroundColor: const Color(0xFF1E3A8A),
      systemOverlayStyle: const SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: Brightness.dark,
      ),
      leading: Navigator.of(context).canPop()
          ? IconButton(
              icon: const Icon(Icons.arrow_back, color: Color(0xFF1E3A8A)),
              onPressed: () => Navigator.of(context).pop(),
            )
          : null,
      title: Text(
        'Sample Distribution',
        style: TextStyle(
          fontWeight: FontWeight.w600,
          fontSize: 18.sp,
          color: const Color(0xFF1E3A8A),
        ),
      ),
      actions: [
        IconButton(
          icon: const Icon(
            Icons.help_outline_rounded,
            color: Color(0xFF1E3A8A),
          ),
          onPressed: () => _showHelpDialog(),
        ),
      ],
    );
  }

  Widget _buildAnimatedHeader() {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(24.w),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF1E3A8A), Color(0xFF3B82F6)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16.r),
        boxShadow: [
          BoxShadow(
            color: Colors.blue.withValues(alpha: 0.15),
            blurRadius: 20.r,
            offset: Offset(0, 8.h),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Sample Distribution Entry',
            style: TextStyle(
              fontSize: 24.sp,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
          SizedBox(height: 8.h),
          Text(
            'Enter sample distribution details',
            style: TextStyle(fontSize: 14.sp, color: Colors.white70),
          ),
        ],
      ),
    );
  }

  Widget _buildRetailerSection() {
    return _buildModernSection(
      title: 'Retailer Details',
      icon: Icons.store_rounded,
      children: [
        ModernDropdown(
          label: 'Emirate',
          icon: Icons.location_on_outlined,
          items: _emirates.map((e) => e.desc).toList(),
          value: _selectedEmirate?.desc,
          onChanged: (value) {
            if (value != null) {
              setState(() {
                _selectedEmirate = _emirates.firstWhere(
                  (e) => e.desc == value,
                  orElse: () => _emirates.first,
                );
                emirateController.text = _selectedEmirate!.desc;
              });
            }
          },
          isRequired: true,
        ),
        SizedBox(height: 16.h),
        _buildModernTextField(
          controller: retailerNameController,
          label: 'Retailer Name',
          icon: Icons.store_outlined,
        ),
        SizedBox(height: 16.h),
        _buildModernTextField(
          controller: retailerCodeController,
          label: 'Retailer Code',
          icon: Icons.qr_code_outlined,
          isRequired: false,
        ),
        SizedBox(height: 16.h),
        _buildModernTextField(
          controller: distributorController,
          label: 'Concern Distributor',
          icon: Icons.business_outlined,
        ),
      ],
    );
  }

  Widget _buildDistributionSection() {
    return _buildModernSection(
      title: 'Distribution Details',
      icon: Icons.local_shipping_outlined,
      children: [
        _buildModernTextField(
          controller: painterNameController,
          label: 'Name of Painter / Contractor',
          icon: Icons.person_outline_rounded,
        ),
        SizedBox(height: 16.h),
        _buildModernTextField(
          controller: painterMobileController,
          label: 'Mobile no Painter / Contractor',
          icon: Icons.phone_outlined,
          isPhone: true,
          isRequired: false,
        ),
        SizedBox(height: 16.h),
        _buildModernTextField(
          controller: materialQtyController,
          label: 'Total Distribution Amount in Kg',
          icon: Icons.scale_outlined,
          keyboardType: const TextInputType.numberWithOptions(decimal: true),
          inputFormatters: [
            FilteringTextInputFormatter.allow(RegExp(r'^\d*\.?\d*')),
          ],
          isRequired: false,
        ),
        SizedBox(height: 16.h),
        _buildModernDateField(
          controller: distributionDateController,
          label: 'Date of distribution',
          icon: Icons.event_available_outlined,
        ),
      ],
    );
  }

  Widget _buildModernSection({
    required String title,
    required IconData icon,
    required List<Widget> children,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16.r),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 16.r,
            offset: Offset(0, 4.h),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: EdgeInsets.all(16.w),
            decoration: BoxDecoration(
              color: const Color(0xFFF8FAFC),
              borderRadius: BorderRadius.vertical(top: Radius.circular(16.r)),
            ),
            child: Row(
              children: [
                Container(
                  width: 40.w,
                  height: 40.h,
                  decoration: BoxDecoration(
                    color: const Color(0xFF1E3A8A).withValues(alpha: 0.1),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    icon,
                    color: const Color(0xFF1E3A8A),
                    size: 20.sp,
                  ),
                ),
                SizedBox(width: 12.w),
                Expanded(
                  child: Text(
                    title,
                    style: TextStyle(
                      fontSize: 16.sp,
                      fontWeight: FontWeight.bold,
                      color: const Color(0xFF1F2937),
                    ),
                  ),
                ),
              ],
            ),
          ),
          Padding(
            padding: EdgeInsets.all(16.w),
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
    bool isPhone = false,
    bool isRequired = true,
    TextInputType? keyboardType,
    List<TextInputFormatter>? inputFormatters,
  }) {
    final bool useUaePhoneField = UaePhoneUtils.isPhoneField(
      keyboardType: keyboardType,
      isPhone: isPhone,
    );
    return TextFormField(
      controller: controller,
      decoration: InputDecoration(
        labelText: isRequired ? '$label *' : label,
        prefixIcon: Icon(icon, color: Colors.grey.shade600, size: 20.sp),
        prefixText: useUaePhoneField ? UaePhoneUtils.countryPrefix : null,
        hintText: useUaePhoneField ? UaePhoneUtils.localHint : null,
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
          borderSide: const BorderSide(color: Color(0xFF1E3A8A), width: 2),
        ),
        filled: true,
        fillColor: const Color(0xFFF8FAFC),
        contentPadding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 16.h),
      ),
      keyboardType:
          keyboardType ?? (isPhone ? TextInputType.phone : TextInputType.text),
      inputFormatters: useUaePhoneField
          ? UaePhoneUtils.inputFormatters(additional: inputFormatters)
          : inputFormatters,
      validator: (value) {
        if (isRequired && (value == null || value.trim().isEmpty)) {
          return 'Please enter $label';
        }
        if (useUaePhoneField) {
          final error = UaePhoneUtils.validate(value, required: isRequired);
          if (error != null) {
            return error;
          }
        }
        return null;
      },
    );
  }

  Widget _buildModernDateField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    bool isRequired = true,
  }) {
    return TextFormField(
      controller: controller,
      decoration: InputDecoration(
        labelText: isRequired ? '$label *' : label,
        prefixIcon: Icon(icon, color: Colors.grey.shade600, size: 20.sp),
        suffixIcon: Icon(
          Icons.calendar_today_rounded,
          color: Colors.grey,
          size: 18.sp,
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
          borderSide: const BorderSide(color: Color(0xFF1E3A8A), width: 2),
        ),
        filled: true,
        fillColor: const Color(0xFFF8FAFC),
        contentPadding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 16.h),
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
        if (date != null) {
          controller.text = date.toString().split(' ')[0];
        }
      },
      validator: (value) {
        if (isRequired && (value == null || value.isEmpty)) {
          return 'Please enter $label';
        }
        return null;
      },
    );
  }

  Widget _buildSubmitButton() {
    return SizedBox(
      width: double.infinity,
      height: 50.h,
      child: ElevatedButton(
        onPressed: _isSubmitting ? null : _submitForm,
        style: ElevatedButton.styleFrom(
          backgroundColor: const Color(0xFF1E3A8A),
          foregroundColor: Colors.white,
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12.r),
          ),
        ),
        child: _isSubmitting
            ? Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  SizedBox(
                    width: 20.w,
                    height: 20.h,
                    child: const CircularProgressIndicator(
                      strokeWidth: 2,
                      color: Colors.white,
                    ),
                  ),
                  SizedBox(width: 12.w),
                  Text(
                    'Submitting...',
                    style: TextStyle(color: Colors.white, fontSize: 14.sp),
                  ),
                ],
              )
            : Text(
                'Submit Distribution',
                style: TextStyle(
                  fontSize: 16.sp,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
      ),
    );
  }

  Widget _buildSupplyChainTable() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16.r),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 16.r,
            offset: Offset(0, 4.h),
          ),
        ],
      ),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: DataTable(
          headingRowColor: MaterialStateProperty.all(const Color(0xFF1E3A8A)),
          headingTextStyle: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
            fontSize: 12.sp,
          ),
          dataTextStyle: TextStyle(fontSize: 11.sp),
          columns: const [
            DataColumn(label: Text("Retailer")),
            DataColumn(label: Text("Code")),
            DataColumn(label: Text("Distributor")),
            DataColumn(label: Text("Painter")),
            DataColumn(label: Text("Mobile")),
            DataColumn(label: Text("Distributed (Kg)")),
            DataColumn(label: Text("Total Received (Kg)")),
            DataColumn(label: Text("Remaining (Kg)")),
          ],
          rows: currentEntries.map((entry) {
            return DataRow(
              cells: [
                DataCell(Text(entry.retailerName)),
                DataCell(Text(entry.retailerCode)),
                DataCell(Text(entry.distributorName)),
                DataCell(Text(entry.painterName)),
                DataCell(Text(entry.painterMobile)),
                DataCell(Text(entry.qtyDistributed.toString())),
                DataCell(Text(entry.totalReceived.toString())),
                DataCell(Text(entry.remaining.toString())),
              ],
            );
          }).toList(),
        ),
      ),
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
              Icon(
                Icons.help_outline_rounded,
                size: 48.sp,
                color: const Color(0xFF1E3A8A),
              ),
              SizedBox(height: 16.h),
              Text(
                'Distribution Help',
                style: TextStyle(
                  fontSize: 18.sp,
                  fontWeight: FontWeight.bold,
                  color: const Color(0xFF1F2937),
                ),
              ),
              SizedBox(height: 16.h),
              Text(
                'Fill in all required fields marked with *. '
                'Ensure all distribution details are accurate before submission.',
                textAlign: TextAlign.center,
                style: TextStyle(color: Colors.grey.shade600, fontSize: 14.sp),
              ),
              SizedBox(height: 24.h),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () => Navigator.pop(context),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF1E3A8A),
                    foregroundColor: Colors.white,
                  ),
                  child: const Text(
                    'Got it',
                    style: TextStyle(color: Colors.white),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
