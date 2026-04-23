import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import '../../shared/widgets/modern_dropdown.dart';
import '../../shared/widgets/file_upload_widget.dart';
import '../../core/models/sampling_drive_models.dart';
import '../../core/services/sampling_execution_service.dart';
import '../../core/services/contractor_service.dart';
import '../../core/models/contractor_models.dart';
import '../../core/utils/uae_phone_utils.dart';

class SampleExecutionEntryScreen extends StatefulWidget {
  const SampleExecutionEntryScreen({super.key});

  @override
  State<SampleExecutionEntryScreen> createState() =>
      _SampleExecutionEntryScreenState();
}

class _SampleExecutionEntryScreenState extends State<SampleExecutionEntryScreen>
    with TickerProviderStateMixin {
  final _formKey = GlobalKey<FormState>();
  String? _photoImage;

  // Controllers
  final retailerController = TextEditingController();
  final retailerCodeController = TextEditingController();
  final distributorController = TextEditingController();
  final dateController = TextEditingController();
  final painterController = TextEditingController();
  final phoneController = TextEditingController();
  final qtyController = TextEditingController();
  final missedQtyController = TextEditingController();
  final siteAdController = TextEditingController();
  final remarksController = TextEditingController();
  final reimbursementModeController = TextEditingController();
  final reimbursementAmtController = TextEditingController();
  final searchRetailerCodeController = TextEditingController();
  final startDateController = TextEditingController();
  final endDateController = TextEditingController();
  final emiratesController = TextEditingController();
  final samplDateController = TextEditingController();
  final prodController = TextEditingController();

  bool _isReimbursementEditable = true;
  List<SamplingDriveEntry> allRetailerEntries = [];
  List<SamplingDriveEntry> filteredRetailerEntries = [];

  bool _isSubmitting = false;
  bool _isSearching = false;
  bool _isLoadingInitialData = false;
  String? _searchError;

  // Emirates dropdown data
  List<EmirateItem> _emirates = [];
  List<String> _emirateDescriptions = [];
  EmirateItem? _selectedEmirate;

  // Animation controllers
  late AnimationController _mainController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;

  final ScrollController _horizontalScrollController = ScrollController();

  @override
  void initState() {
    super.initState();

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
    _loadEmirates();
    _loadInitialData();
  }

  Future<void> _loadEmirates() async {
    try {
      final emirates = await ContractorService.getEmiratesList();
      setState(() {
        _emirates = emirates;
        _emirateDescriptions = emirates.map((e) => e.desc).toList();
      });
    } catch (e) {
      setState(() {
        _emirates = [
          EmirateItem(code: 'DUB', desc: 'Dubai'),
          EmirateItem(code: 'ABD', desc: 'Abu Dhabi'),
          EmirateItem(code: 'SHJ', desc: 'Sharjah'),
          EmirateItem(code: 'AJM', desc: 'Ajman'),
          EmirateItem(code: 'UAQ', desc: 'Umm Al Quwain'),
          EmirateItem(code: 'RAK', desc: 'Ras Al Khaimah'),
          EmirateItem(code: 'FUJ', desc: 'Fujairah'),
        ];
        _emirateDescriptions = _emirates.map((e) => e.desc).toList();
      });
    }
  }

  Future<void> _loadInitialData() async {
    setState(() {
      _isLoadingInitialData = true;
      _searchError = null;
    });

    try {
      final result = await SamplingExecutionService.getTop100WithFallback();
      if (result['success'] == true) {
        final entries = result['data'] as List<SamplingDriveEntry>;
        setState(() {
          allRetailerEntries = entries;
          filteredRetailerEntries = entries;
          _isLoadingInitialData = false;
        });
      } else {
        setState(() {
          _searchError = result['error'] ?? 'Failed to load initial data';
          _isLoadingInitialData = false;
        });
      }
    } catch (e) {
      setState(() {
        _searchError = 'Failed to load initial data: $e';
        _isLoadingInitialData = false;
      });
    }
  }

  @override
  void dispose() {
    _mainController.dispose();
    retailerController.dispose();
    retailerCodeController.dispose();
    distributorController.dispose();
    dateController.dispose();
    painterController.dispose();
    phoneController.dispose();
    qtyController.dispose();
    missedQtyController.dispose();
    siteAdController.dispose();
    remarksController.dispose();
    reimbursementModeController.dispose();
    reimbursementAmtController.dispose();
    searchRetailerCodeController.dispose();
    startDateController.dispose();
    endDateController.dispose();
    emiratesController.dispose();
    samplDateController.dispose();
    prodController.dispose();
    _horizontalScrollController.dispose();
    super.dispose();
  }

  void populateControllers(SamplingDriveEntry entry) {
    retailerController.text = entry.retailerName;
    retailerCodeController.text = entry.retailerCode;
    distributorController.text = entry.distributorName;
    dateController.text =
        "${entry.distributionDate.year}-${entry.distributionDate.month.toString().padLeft(2, '0')}-${entry.distributionDate.day.toString().padLeft(2, '0')}";
    painterController.text = entry.painterName;
    phoneController.text = entry.painterMobile;
    qtyController.text = entry.qtyDistributedKg.toStringAsFixed(1);
    missedQtyController.text = entry.missedQtyKg.toStringAsFixed(1);
    reimbursementModeController.text = entry.reimbursementMode;
    reimbursementAmtController.text = entry.reimbursementAmountAED
        .toStringAsFixed(1);
  }

  void _performSearch() async {
    final searchText = searchRetailerCodeController.text.trim();
    final startDate = startDateController.text.trim();
    final endDate = endDateController.text.trim();

    if (searchText.isEmpty && startDate.isEmpty && endDate.isEmpty) {
      setState(() {
        filteredRetailerEntries = allRetailerEntries;
      });
      return;
    }

    setState(() {
      _isSearching = true;
      _searchError = null;
    });

    try {
      List<SamplingDriveEntry> filtered = allRetailerEntries.where((entry) {
        bool matchesText = true;
        bool matchesDate = true;

        if (searchText.isNotEmpty) {
          final searchLower = searchText.toLowerCase();
          matchesText =
              entry.retailerCode.toLowerCase().contains(searchLower) ||
              entry.retailerName.toLowerCase().contains(searchLower) ||
              entry.painterName.toLowerCase().contains(searchLower);
        }

        if (startDate.isNotEmpty || endDate.isNotEmpty) {
          final entryDate = entry.distributionDate;
          if (startDate.isNotEmpty) {
            final start = DateTime.tryParse(startDate);
            if (start != null && entryDate.isBefore(start)) {
              matchesDate = false;
            }
          }
          if (endDate.isNotEmpty) {
            final end = DateTime.tryParse(endDate);
            if (end != null &&
                entryDate.isAfter(end.add(const Duration(days: 1)))) {
              matchesDate = false;
            }
          }
        }

        return matchesText && matchesDate;
      }).toList();

      setState(() {
        filteredRetailerEntries = filtered;
        _isSearching = false;
      });

      if (filtered.isEmpty && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('No entries found for the given criteria'),
            backgroundColor: Colors.orange,
          ),
        );
      }
    } catch (e) {
      setState(() {
        _searchError = 'Filter error: $e';
        _isSearching = false;
      });
    }
  }

  void _submitForm() async {
    if (_formKey.currentState!.validate()) {
      // Validate required fields
      if (_selectedEmirate == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Please select an Emirate'),
            backgroundColor: Colors.red,
          ),
        );
        return;
      }

      setState(() => _isSubmitting = true);

      try {
        // Parse sample date if provided
        DateTime? sampleDate;
        if (samplDateController.text.isNotEmpty) {
          sampleDate = DateTime.tryParse(samplDateController.text);
        }

        // Create request object
        final request = SamplingDriveRequest(
          retailerName: retailerController.text.trim(),
          retailerCode: retailerCodeController.text.trim(),
          distributorName: distributorController.text.trim(),
          emirates: _selectedEmirate!.code,
          distributionDate: dateController.text.trim(),
          painterName: painterController.text.trim(),
          painterMobile: phoneController.text.trim(),
          qtyDistributedKg: double.tryParse(qtyController.text) ?? 0.0,
          siteAddress: siteAdController.text.trim(),
          sampleDate: sampleDate,
          product: prodController.text.trim(),
          photoImage: _photoImage,
          reimbursementMode: reimbursementModeController.text.trim(),
          reimbursementAmountAED:
              double.tryParse(reimbursementAmtController.text) ?? 0.0,
          sampleCancelFlag: 'S',
        );

        // Submit to API
        final response = await SamplingExecutionService.submitSamplingExecution(
          request,
        );

        if (response['success'] == true) {
          if (mounted) {
            final message = response['message'] ?? 'Saved successfully';
            final docNum = response['docuNumb'];

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
                        docNum != null ? '$message (Doc: $docNum)' : message,
                      ),
                    ),
                  ],
                ),
                backgroundColor: Colors.green,
                behavior: SnackBarBehavior.floating,
                duration: const Duration(seconds: 4),
              ),
            );

            // Reload data after successful submission
            _loadInitialData();
          }
        } else {
          if (mounted) {
            // Handle both 'message' and 'error' keys from response
            final errorMsg =
                response['message'] ??
                response['error'] ??
                'Unknown error occurred';

            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Row(
                  children: [
                    const Icon(Icons.error, color: Colors.white, size: 20),
                    const SizedBox(width: 8),
                    Expanded(child: Text(errorMsg)),
                  ],
                ),
                backgroundColor: Colors.red,
                behavior: SnackBarBehavior.floating,
                duration: const Duration(seconds: 4),
              ),
            );
          }
        }
      } catch (e, stackTrace) {
        print('[SAMPLE_EXEC_SCREEN] Exception during submit: $e');
        print('[SAMPLE_EXEC_SCREEN] Stack trace: $stackTrace');

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
      body: SafeArea(
        child: Form(
          key: _formKey,
          child: FadeTransition(
            opacity: _fadeAnimation,
            child: SlideTransition(
              position: _slideAnimation,
              child: SingleChildScrollView(
                padding: EdgeInsets.symmetric(horizontal: 20.w, vertical: 20.h),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildAnimatedHeader(),
                    SizedBox(height: 24.h),
                    _buildSearchSection(),
                    SizedBox(height: 24.h),
                    if (_isLoadingInitialData) ...[
                      _buildLoadingState(),
                      SizedBox(height: 24.h),
                    ] else if (filteredRetailerEntries.isNotEmpty) ...[
                      _buildEntriesCount(),
                      SizedBox(height: 16.h),
                      _buildDataTable(),
                      SizedBox(height: 20.h),
                    ] else if (_searchError != null) ...[
                      _buildErrorState(),
                      SizedBox(height: 24.h),
                    ] else if (allRetailerEntries.isNotEmpty) ...[
                      _buildNoResultsState(),
                      SizedBox(height: 24.h),
                    ] else ...[
                      _buildEmptyState(),
                      SizedBox(height: 24.h),
                    ],
                    SizedBox(height: 24.h),
                    _buildFormSections(),
                    SizedBox(height: 32.h),
                    _buildSubmitButton(),
                    SizedBox(height: 32.h),
                  ],
                ),
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
        'Sample Execution Entry',
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
            'Sample Execution Entry',
            style: TextStyle(
              fontSize: 24.sp,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
          SizedBox(height: 8.h),
          Text(
            'Enter sample execution details',
            style: TextStyle(fontSize: 14.sp, color: Colors.white70),
          ),
        ],
      ),
    );
  }

  Widget _buildSearchSection() {
    return _buildModernSection(
      title: 'Search Sampling Entries',
      icon: Icons.search,
      children: [
        _buildModernTextField(
          controller: searchRetailerCodeController,
          label: 'Retailer Code / Name / Painter Name',
          icon: Icons.search,
          isRequired: false,
        ),
        SizedBox(height: 16.h),
        _buildModernDateField(
          controller: startDateController,
          label: 'Start Date',
          icon: Icons.calendar_today,
          isRequired: false,
        ),
        SizedBox(height: 16.h),
        _buildModernDateField(
          controller: endDateController,
          label: 'End Date',
          icon: Icons.calendar_today,
          isRequired: false,
        ),
        SizedBox(height: 8.h),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            TextButton.icon(
              onPressed: () {
                searchRetailerCodeController.clear();
                startDateController.clear();
                endDateController.clear();
                setState(() {
                  filteredRetailerEntries = allRetailerEntries;
                });
              },
              icon: const Icon(Icons.clear_all),
              label: const Text('Clear All'),
            ),
            TextButton.icon(
              onPressed: () {
                startDateController.clear();
                endDateController.clear();
              },
              icon: const Icon(Icons.clear),
              label: const Text('Clear Dates'),
            ),
          ],
        ),
        SizedBox(height: 16.h),
        SizedBox(
          width: double.infinity,
          child: ElevatedButton.icon(
            onPressed: _isSearching ? null : _performSearch,
            icon: _isSearching
                ? SizedBox(
                    width: 16.w,
                    height: 16.h,
                    child: const CircularProgressIndicator(
                      strokeWidth: 2,
                      color: Colors.white,
                    ),
                  )
                : const Icon(Icons.search),
            label: Text(_isSearching ? 'Searching...' : 'Search'),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF1E3A8A),
              foregroundColor: Colors.white,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildLoadingState() {
    return Container(
      padding: EdgeInsets.all(32.w),
      decoration: BoxDecoration(
        color: Colors.blue.shade50,
        borderRadius: BorderRadius.circular(12.r),
        border: Border.all(color: Colors.blue.shade200),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          SizedBox(
            width: 24.w,
            height: 24.h,
            child: const CircularProgressIndicator(strokeWidth: 2),
          ),
          SizedBox(width: 16.w),
          Text('Loading top 100 entries...', style: TextStyle(fontSize: 14.sp)),
        ],
      ),
    );
  }

  Widget _buildEntriesCount() {
    return Container(
      padding: EdgeInsets.all(12.w),
      decoration: BoxDecoration(
        color: Colors.green.shade50,
        borderRadius: BorderRadius.circular(8.r),
        border: Border.all(color: Colors.green.shade200),
      ),
      child: Row(
        children: [
          Icon(Icons.info_outline, color: Colors.green.shade600, size: 18.sp),
          SizedBox(width: 8.w),
          Text(
            'Showing ${filteredRetailerEntries.length} of ${allRetailerEntries.length} entries',
            style: TextStyle(
              color: Colors.green.shade700,
              fontWeight: FontWeight.w500,
              fontSize: 13.sp,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildErrorState() {
    return Container(
      padding: EdgeInsets.all(20.w),
      decoration: BoxDecoration(
        color: Colors.red.shade50,
        borderRadius: BorderRadius.circular(12.r),
        border: Border.all(color: Colors.red.shade200),
      ),
      child: Row(
        children: [
          Icon(Icons.error_outline, color: Colors.red.shade600, size: 20.sp),
          SizedBox(width: 12.w),
          Expanded(
            child: Text(
              'Error: $_searchError',
              style: TextStyle(color: Colors.red.shade700, fontSize: 13.sp),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNoResultsState() {
    return Container(
      padding: EdgeInsets.all(20.w),
      decoration: BoxDecoration(
        color: Colors.orange.shade50,
        borderRadius: BorderRadius.circular(12.r),
        border: Border.all(color: Colors.orange.shade200),
      ),
      child: Row(
        children: [
          Icon(Icons.search_off, color: Colors.orange.shade600, size: 20.sp),
          SizedBox(width: 12.w),
          Expanded(
            child: Text(
              'No entries match your search criteria. Try different search terms.',
              style: TextStyle(fontSize: 13.sp),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Container(
      padding: EdgeInsets.all(20.w),
      decoration: BoxDecoration(
        color: Colors.grey.shade50,
        borderRadius: BorderRadius.circular(12.r),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Row(
        children: [
          Icon(Icons.inbox_outlined, color: Colors.grey.shade600, size: 20.sp),
          SizedBox(width: 12.w),
          Expanded(
            child: Text(
              'No sampling entries available.',
              style: TextStyle(fontSize: 13.sp),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDataTable() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12.r),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 16.r,
            offset: Offset(0, 4.h),
          ),
        ],
      ),
      child: Scrollbar(
        controller: _horizontalScrollController,
        thumbVisibility: true,
        child: SingleChildScrollView(
          controller: _horizontalScrollController,
          scrollDirection: Axis.horizontal,
          child: DataTable(
            showCheckboxColumn: false,
            headingRowColor: MaterialStateProperty.all(const Color(0xFF1E3A8A)),
            headingTextStyle: TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.bold,
              fontSize: 11.sp,
            ),
            dataTextStyle: TextStyle(fontSize: 10.sp),
            columns: const [
              DataColumn(label: Text("Retailer")),
              DataColumn(label: Text("Code")),
              DataColumn(label: Text("Distributor")),
              DataColumn(label: Text("Emirates")),
              DataColumn(label: Text("Date")),
              DataColumn(label: Text("Painter")),
              DataColumn(label: Text("Mobile")),
              DataColumn(label: Text("Distributed (Kg)")),
            ],
            rows: filteredRetailerEntries.map((entry) {
              return DataRow(
                cells: [
                  DataCell(Text(entry.retailerName)),
                  DataCell(Text(entry.retailerCode)),
                  DataCell(Text(entry.distributorName)),
                  DataCell(Text(entry.emirates)),
                  DataCell(
                    Text(
                      "${entry.distributionDate.year}-${entry.distributionDate.month.toString().padLeft(2, '0')}-${entry.distributionDate.day.toString().padLeft(2, '0')}",
                    ),
                  ),
                  DataCell(Text(entry.painterName)),
                  DataCell(Text(entry.painterMobile)),
                  DataCell(Text(entry.qtyDistributedKg.toStringAsFixed(1))),
                ],
                onSelectChanged: (_) {
                  populateControllers(entry);
                  final match = _emirates.firstWhere(
                    (e) => e.code == entry.emirates || e.desc == entry.emirates,
                    orElse: () => _emirates.isNotEmpty
                        ? _emirates.first
                        : EmirateItem(
                            code: entry.emirates,
                            desc: entry.emirates,
                          ),
                  );
                  setState(() {
                    _selectedEmirate = match;
                    emiratesController.text = match.desc;
                  });
                },
              );
            }).toList(),
          ),
        ),
      ),
    );
  }

  Widget _buildFormSections() {
    return Column(
      children: [
        _buildModernSection(
          title: 'Sample Material Distribution',
          icon: Icons.inventory_2_outlined,
          children: [
            _buildModernTextField(
              controller: retailerController,
              label: 'Retailer Name',
              icon: Icons.storefront,
            ),
            SizedBox(height: 16.h),
            _buildModernTextField(
              controller: retailerCodeController,
              label: 'Retailer Code',
              icon: Icons.qr_code_outlined,
            ),
            SizedBox(height: 16.h),
            _buildModernTextField(
              controller: distributorController,
              label: 'Concern Distributor',
              icon: Icons.business_outlined,
            ),
            SizedBox(height: 16.h),
            ModernDropdown(
              label: 'Emirates',
              icon: Icons.location_on_outlined,
              items: _emirateDescriptions,
              value: _selectedEmirate?.desc,
              onChanged: (value) {
                if (value != null) {
                  setState(() {
                    _selectedEmirate = _emirates.firstWhere(
                      (e) => e.desc == value,
                      orElse: () => _emirates.first,
                    );
                    emiratesController.text = _selectedEmirate!.desc;
                  });
                }
              },
            ),
            SizedBox(height: 16.h),
            _buildModernDateField(
              controller: dateController,
              label: 'Date of Distribution',
              icon: Icons.calendar_today_outlined,
            ),
          ],
        ),
        SizedBox(height: 20.h),
        _buildModernSection(
          title: 'Execution Details',
          icon: Icons.engineering_outlined,
          children: [
            _buildModernTextField(
              controller: painterController,
              label: 'Painter/Contractor Name',
              icon: Icons.person_outline_rounded,
            ),
            SizedBox(height: 16.h),
            _buildModernTextField(
              controller: phoneController,
              label: 'Contact Number',
              icon: Icons.phone_outlined,
              isPhone: true,
            ),
            SizedBox(height: 16.h),
            _buildModernTextField(
              controller: qtyController,
              label: 'Material Qty Distributed (Kg)',
              icon: Icons.inventory_outlined,
              isNumeric: true,
            ),
            SizedBox(height: 16.h),
            _buildModernTextField(
              controller: siteAdController,
              label: 'Site Address',
              icon: Icons.location_on_outlined,
              isRequired: false,
            ),
          ],
        ),
        SizedBox(height: 20.h),
        _buildModernSection(
          title: 'Sample Proof',
          icon: Icons.photo_camera_outlined,
          children: [
            _buildModernDateField(
              controller: samplDateController,
              label: 'Sample Date',
              icon: Icons.calendar_today_outlined,
              isRequired: false,
            ),
            SizedBox(height: 16.h),
            ModernDropdown(
              label: 'Product',
              icon: Icons.palette_outlined,
              items: const ['Wallcare Putty'],
              value: prodController.text.isEmpty ? null : prodController.text,
              onChanged: (value) {
                setState(() {
                  prodController.text = value ?? '';
                });
              },
            ),
            SizedBox(height: 16.h),
            FileUploadWidget(
              label: 'Sample Photograph',
              icon: Icons.camera_alt_outlined,
              onFileSelected: (value) {
                setState(() => _photoImage = value);
              },
              allowedExtensions: const ['jpg', 'jpeg', 'png'],
              maxSizeInMB: 10.0,
              currentFilePath: _photoImage,
              formType: 'sampling',
            ),
          ],
        ),
        SizedBox(height: 20.h),
        _buildModernSection(
          title: 'Reimbursement',
          icon: Icons.payments_outlined,
          children: [
            ModernDropdown(
              label: 'Reimbursement Mode',
              icon: Icons.monetization_on_outlined,
              items: const ['0 AED (No Reimbursement)', 'Max 150 AED'],
              value: reimbursementModeController.text.isEmpty
                  ? null
                  : reimbursementModeController.text,
              onChanged: (String? value) {
                setState(() {
                  reimbursementModeController.text = value ?? '';
                  if (value != null) {
                    if (value.contains('Max 150 AED')) {
                      reimbursementAmtController.text = '150';
                      _isReimbursementEditable = true;
                    } else if (value.contains('0')) {
                      reimbursementAmtController.text = '0';
                      _isReimbursementEditable = false;
                    }
                  }
                });
              },
            ),
            SizedBox(height: 16.h),
            _buildReimbursementTextField(),
          ],
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
    bool isNumeric = false,
    bool isRequired = true,
  }) {
    final bool useUaePhoneField = UaePhoneUtils.isPhoneField(isPhone: isPhone);
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
      keyboardType: isPhone
          ? TextInputType.phone
          : isNumeric
          ? TextInputType.number
          : TextInputType.text,
      inputFormatters: useUaePhoneField
          ? UaePhoneUtils.inputFormatters()
          : null,
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

  Widget _buildReimbursementTextField() {
    return TextFormField(
      controller: reimbursementAmtController,
      enabled: _isReimbursementEditable,
      decoration: InputDecoration(
        labelText: 'Amount Reimbursed *',
        prefixIcon: Icon(
          Icons.attach_money_outlined,
          color: _isReimbursementEditable
              ? Colors.grey.shade600
              : Colors.grey.shade400,
          size: 20.sp,
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12.r),
          borderSide: BorderSide(color: Colors.grey.shade300),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12.r),
          borderSide: BorderSide(color: Colors.grey.shade300),
        ),
        disabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12.r),
          borderSide: BorderSide(color: Colors.grey.shade200),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12.r),
          borderSide: const BorderSide(color: Color(0xFF1E3A8A), width: 2),
        ),
        filled: true,
        fillColor: _isReimbursementEditable
            ? const Color(0xFFF8FAFC)
            : Colors.grey.shade100,
        contentPadding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 16.h),
      ),
      keyboardType: TextInputType.number,
      inputFormatters: [
        FilteringTextInputFormatter.allow(RegExp(r'^\d*\.?\d*')),
        if (_isReimbursementEditable &&
            reimbursementModeController.text.contains('Max 150 AED'))
          FilteringTextInputFormatter.allow(
            RegExp(r'^(?:[0-9]|[1-9][0-9]|1[0-4][0-9]|150)(?:\.\d*)?$'),
          ),
      ],
      onChanged: (value) {
        if (_isReimbursementEditable &&
            reimbursementModeController.text.contains('Max 150 AED')) {
          final numValue = double.tryParse(value);
          if (numValue != null && numValue > 150) {
            reimbursementAmtController.text = '150';
            reimbursementAmtController.selection = TextSelection.fromPosition(
              TextPosition(offset: reimbursementAmtController.text.length),
            );
          }
        }
      },
      validator: (value) {
        if (value == null || value.trim().isEmpty) {
          return 'Please enter amount reimbursed';
        }
        final numValue = double.tryParse(value);
        if (numValue == null) {
          return 'Please enter a valid number';
        }
        if (reimbursementModeController.text.contains('Max 150 AED') &&
            numValue > 150) {
          return 'Amount cannot exceed 150 AED';
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
            : Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.save, size: 18.sp),
                  SizedBox(width: 8.w),
                  Text(
                    'Submit',
                    style: TextStyle(
                      fontSize: 16.sp,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                ],
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
                'Sampling Drive Help',
                style: TextStyle(
                  fontSize: 18.sp,
                  fontWeight: FontWeight.bold,
                  color: const Color(0xFF1F2937),
                ),
              ),
              SizedBox(height: 16.h),
              Text(
                'Fill in all required fields marked with *. '
                'Reimbursement amount will be auto-filled based on the selected mode.',
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
