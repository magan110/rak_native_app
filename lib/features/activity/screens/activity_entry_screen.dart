import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:rak_app/core/models/activity_models.dart';
import 'package:rak_app/core/services/activity_service.dart';
import 'package:rak_app/core/services/auth_service.dart';
// Using legacy AuthManager for now; avoid provider imports until
// the app is wrapped with ChangeNotifierProvider<AuthProvider>.
import 'package:rak_app/core/services/image_upload_service.dart';
import 'package:rak_app/core/utils/snackbar_utils.dart';
import 'package:rak_app/core/services/location_service.dart';
import 'package:rak_app/shared/widgets/custom_back_button.dart';
import 'package:rak_app/shared/widgets/responsive_widgets.dart';
import 'package:rak_app/shared/widgets/modern_dropdown.dart';

class ActivityEntryScreen extends StatefulWidget {
  const ActivityEntryScreen({super.key});

  @override
  State<ActivityEntryScreen> createState() => _ActivityEntryScreenState();
}

class _ActivityEntryScreenState extends State<ActivityEntryScreen>
    with TickerProviderStateMixin {
  late AnimationController _mainController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;
  late Animation<double> _scaleAnimation;

  final _formKey = GlobalKey<FormState>();
  final ScrollController _scrollController = ScrollController();

  // Current step (1 = Activity Details, 2 = Participants, 3 = Gift & Submit)
  int _currentStep = 1;

  // ---------- Controllers ----------
  final TextEditingController _actvNameController = TextEditingController();
  final TextEditingController _meetDateController = TextEditingController();
  final TextEditingController _meetVenuController = TextEditingController();
  final TextEditingController _venuAddrController = TextEditingController();
  final TextEditingController _actvCityController = TextEditingController();
  final TextEditingController _districtController = TextEditingController();
  final TextEditingController _pinCodeController = TextEditingController();
  final TextEditingController _remarkController = TextEditingController();
  final TextEditingController _mobileController = TextEditingController();
  final TextEditingController _giftQntyController = TextEditingController();
  final TextEditingController _giftByWhController = TextEditingController();
  final TextEditingController _amtSpendController = TextEditingController();
  final TextEditingController _latitudeController = TextEditingController();
  final TextEditingController _longitudeController = TextEditingController();

  // ---------- State ----------
  String? _selectedArea;
  String? _selectedActType;
  String _giftDist = 'N';
  bool _isLoading = false;

  List<AreaItem> _areaList = [];
  List<String> _selectedProducts = [];
  String? _tempDocuNumb;

  List<String> _imagePaths = [];

  final List<_ParticipantRow> _participantRows = [_ParticipantRow()];

  final Map<String, String> _actTypeMap = {
    'Painter Meet': '01',
    'Contractor Meet': '02',
    'Retailer Meet': '03',
    'Counter Meet': '04',
    'Architect Meet': '05',
  };

  final List<String> _productList = ['Tile Adhesive', 'WC'];

  // ---------- Lifecycle ----------
  @override
  void initState() {
    super.initState();
    _loadAreas();
    _captureLocation();

    _mainController = AnimationController(
      duration: const Duration(milliseconds: 1000),
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
  }

  Future<void> _captureLocation() async {
    try {
      final position = await LocationService.getCurrentLocation();
      if (position != null && mounted) {
        setState(() {
          _latitudeController.text = position.latitude.toStringAsFixed(6);
          _longitudeController.text = position.longitude.toStringAsFixed(6);
        });
      }
    } catch (e) {
      debugPrint('Failed to capture location: $e');
    }
  }

  Future<void> _loadAreas() async {
    try {
      final list = await ActivityService.getAreas();
      if (mounted) {
        setState(() {
          _areaList = list;
        });
      }
    } catch (e) {
      _showMsg('Failed to load areas: $e');
    }
  }

  @override
  void dispose() {
    _scrollController.dispose();
    _mainController.dispose();
    _actvNameController.dispose();
    _meetDateController.dispose();
    _meetVenuController.dispose();
    _venuAddrController.dispose();
    _actvCityController.dispose();
    _districtController.dispose();
    _pinCodeController.dispose();
    _remarkController.dispose();
    _mobileController.dispose();
    _giftQntyController.dispose();
    _giftByWhController.dispose();
    _amtSpendController.dispose();
    _latitudeController.dispose();
    _longitudeController.dispose();

    for (final row in _participantRows) {
      row.dispose();
    }

    super.dispose();
  }

  // ---------- Participant helpers ----------
  void _addParticipantRow() {
    setState(() {
      _participantRows.add(_ParticipantRow());
    });
  }

  void _removeParticipantRow(int index) {
    if (_participantRows.length == 1) return;
    setState(() {
      _participantRows.removeAt(index);
    });
  }

  // ---------- Date picker ----------
  Future<void> _pickDate() async {
    final date = await showDatePicker(
      context: context,
      firstDate: DateTime(2024),
      lastDate: DateTime(2100),
      initialDate: DateTime.now(),
    );

    if (date != null) {
      _meetDateController.text =
          '${date.year.toString().padLeft(4, '0')}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
    }
  }

  // ---------- Image upload ----------
  Future<bool> _uploadImagesFirst() async {
    if (_imagePaths.isEmpty) return true;

    final currentUser = AuthManager.currentUser;
    final createId = currentUser?.userID ?? currentUser?.emplName ?? 'SYSTEM';

    final now = DateTime.now().millisecondsSinceEpoch.toString();
    _tempDocuNumb = 'TMP$now';

    final Map<String, String> filePathsByType = {};
    for (int i = 0; i < _imagePaths.length; i++) {
      filePathsByType['activityImg$i'] = _imagePaths[i];
    }

    final results = await ImageUploadService.uploadMultipleImages(
      filePathsByType: filePathsByType,
      firstName: 'ACT',
      lastName: 'ENTRY',
      mobile: _mobileController.text.trim().isEmpty
          ? '000000000000'
          : _mobileController.text.trim(),
      createId: createId,
    );

    bool allOk = true;
    results.forEach((key, value) {
      if (!value.success) {
        allOk = false;
      }
    });

    return allOk;
  }

  // ---------- Submit ----------
  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    if (_selectedArea == null || _selectedArea!.isEmpty) {
      _showMsg('Please select emirate/area');
      return;
    }
    if (_selectedActType == null || _selectedActType!.isEmpty) {
      _showMsg('Please select activity type');
      return;
    }
    if (_participantRows.isEmpty) {
      _showMsg('Please add at least one participant');
      return;
    }

    setState(() => _isLoading = true);

    try {
      final uploadOk = await _uploadImagesFirst();
      if (!uploadOk) {
        _showMsg('Image upload failed');
        setState(() => _isLoading = false);
        return;
      }

      final participants = _participantRows.map((e) {
        return ActivityParticipant(
          attnType: e.attnType,
          attnCode: e.attnCodeController.text.trim(),
          partName: e.partNameController.text.trim(),
          partMobl: ActivityService.formatMobile12(e.partMoblController.text),
          kycStsFl: e.kycStsFl,
          giftQnty: int.tryParse(e.giftQntyController.text.trim()),
          giftItem: e.giftItemController.text.trim(),
        );
      }).toList();

      final currentUser = AuthManager.currentUser;
      final loginId = currentUser?.userID ?? currentUser?.emplName ?? 'SYSTEM';

      final req = ActivityEntryRequest(
        loginId: loginId,
        areaCode: _selectedArea!,
        actvName: _actvNameController.text.trim(),
        caaActTy: _selectedActType!,
        caaObjTy: '',
        meetDate: _meetDateController.text.trim(),
        meetVenu: _meetVenuController.text.trim(),
        venuAddr: _venuAddrController.text.trim(),
        actvCity: _actvCityController.text.trim(),
        district: _districtController.text.trim(),
        pinCodeN: _pinCodeController.text.trim(),
        actvRmrk: _remarkController.text.trim(),
        mobileNo: ActivityService.formatMobile12(_mobileController.text),
        latitude: _latitudeController.text.trim(),
        longitude: _longitudeController.text.trim(),
        giftDist: _giftDist,
        giftQnty: int.tryParse(_giftQntyController.text.trim()),
        giftByWh: _giftByWhController.text.trim(),
        amtSpend: double.tryParse(_amtSpendController.text.trim()),
        claimLnk: '',
        statFlag: 'N',
        noOfEnqu: 0,
        noOfVist: 0,
        empPrsLs: '',
        tempDocuNumb: _tempDocuNumb ?? '',
        prodList: _selectedProducts,
        participants: participants,
      );

      final resp = await ActivityService.submitActivity(req);

      if (resp.success) {
        _showMsg('Saved successfully. Doc No: ${resp.docuNumb}');
      } else {
        _showMsg(resp.message);
      }
    } catch (e) {
      _showMsg('Error: $e');
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  void _showMsg(String msg) {
    if (!mounted) return;
    final lower = msg.toLowerCase();
    if (lower.startsWith('error') || lower.contains('error')) {
      AppSnackBar.showError(context, msg);
    } else if (lower.contains('saved') || lower.contains('success')) {
      AppSnackBar.showSuccess(context, msg);
    } else {
      AppSnackBar.showInfo(context, msg);
    }
  }

  // =====================================================================
  //  BUILD
  // =====================================================================
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Form(
              key: _formKey,
              child: CustomScrollView(
                controller: _scrollController,
                slivers: [
                  // -------- Gradient Sliver App Bar --------
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
                        'Activity Entry',
                        style: TextStyle(
                          fontSize: 16.sp,
                          fontWeight: FontWeight.w600,
                          color: Colors.white,
                          shadows: [
                            Shadow(
                              offset: Offset(0, 2.h),
                              blurRadius: 4.0,
                              color: const Color(0x40000000),
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
                              Icons.event_note_rounded,
                              size: 100.sp,
                              color: Colors.white.withOpacity(0.2),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),

                  // -------- Body --------
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
                                _buildCurrentStep(),
                                SizedBox(height: 24.h),
                                _buildNavigationButtons(),
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
            ),
    );
  }

  // =====================================================================
  //  PROGRESS INDICATOR
  // =====================================================================
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
              _buildProgressStep(1, 'Details', _currentStep >= 1),
              _buildProgressLine(_currentStep >= 2),
              _buildProgressStep(2, 'Participants', _currentStep >= 2),
              _buildProgressLine(_currentStep >= 3),
              _buildProgressStep(3, 'Gift & Submit', _currentStep >= 3),
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
        return 'Activity Details';
      case 2:
        return 'Participants';
      case 3:
        return 'Gift & Financials';
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

  // =====================================================================
  //  STEP ROUTER
  // =====================================================================
  Widget _buildCurrentStep() {
    switch (_currentStep) {
      case 1:
        return _buildActivityDetailsSection();
      case 2:
        return _buildParticipantsSection();
      case 3:
        return _buildGiftAndFinancialsSection();
      default:
        return _buildActivityDetailsSection();
    }
  }

  // =====================================================================
  //  STEP 1 — Activity Details
  // =====================================================================
  Widget _buildActivityDetailsSection() {
    return ResponsiveSection(
      title: 'Activity Details',
      icon: Icons.event_note_rounded,
      subtitle: 'Enter the activity information',
      children: [
        ResponsiveTextField(
          label: 'Activity Name',
          icon: Icons.label_outline_rounded,
          controller: _actvNameController,
          validator: (v) => (v == null || v.trim().isEmpty) ? 'Required' : null,
        ),
        const ResponsiveSpacing(mobile: 20),

        // Activity Type
        ModernDropdown(
          label: 'Activity Type',
          icon: Icons.category_outlined,
          isRequired: true,
          items: _actTypeMap.keys.toList(),
          value: _selectedActType != null
              ? _actTypeMap.entries
                    .where((e) => e.value == _selectedActType)
                    .map((e) => e.key)
                    .cast<String?>()
                    .firstWhere((_) => true, orElse: () => null)
              : null,
          onChanged: (val) {
            if (val != null) {
              setState(() {
                _selectedActType = _actTypeMap[val];
              });
            }
          },
        ),
        const ResponsiveSpacing(mobile: 20),

        // Emirate / Area
        ModernDropdown(
          label: 'Emirate / Area',
          icon: Icons.public_outlined,
          isRequired: true,
          items: _areaList.map((e) => e.desc).toList(),
          value: _selectedArea != null
              ? _areaList
                    .where((e) => e.code == _selectedArea)
                    .map((e) => e.desc)
                    .cast<String?>()
                    .firstWhere((_) => true, orElse: () => null)
              : null,
          onChanged: (val) {
            if (val != null) {
              final area = _areaList.firstWhere((e) => e.desc == val);
              setState(() {
                _selectedArea = area.code;
              });
            }
          },
        ),
        const ResponsiveSpacing(mobile: 20),

        // Date
        ResponsiveDateField(
          label: 'Activity Date',
          controller: _meetDateController,
          isRequired: true,
          onTap: _pickDate,
          validator: (v) => (v == null || v.isEmpty) ? 'Required' : null,
        ),
        const ResponsiveSpacing(mobile: 20),

        ResponsiveRow(
          children: [
            ResponsiveTextField(
              label: 'Venue / Location',
              icon: Icons.location_on_outlined,
              controller: _meetVenuController,
              validator: (v) =>
                  (v == null || v.trim().isEmpty) ? 'Required' : null,
            ),
            ResponsiveTextField(
              label: 'Venue Address',
              icon: Icons.home_outlined,
              controller: _venuAddrController,
              isRequired: false,
            ),
          ],
        ),
        const ResponsiveSpacing(mobile: 20),

        ResponsiveRow(
          children: [
            ResponsiveTextField(
              label: 'City',
              icon: Icons.location_city_outlined,
              controller: _actvCityController,
              validator: (v) =>
                  (v == null || v.trim().isEmpty) ? 'Required' : null,
            ),
            ResponsiveTextField(
              label: 'District',
              icon: Icons.map_outlined,
              controller: _districtController,
              isRequired: false,
            ),
          ],
        ),
        const ResponsiveSpacing(mobile: 20),

        ResponsiveRow(
          children: [
            ResponsiveTextField(
              label: 'Pin Code',
              icon: Icons.pin_drop_outlined,
              controller: _pinCodeController,
              keyboardType: TextInputType.number,
              isRequired: false,
            ),
            ResponsiveTextField(
              label: 'Mobile Number',
              icon: Icons.phone_outlined,
              controller: _mobileController,
              keyboardType: TextInputType.phone,
              isRequired: false,
              inputFormatters: [
                FilteringTextInputFormatter.allow(RegExp(r'[0-9+]')),
              ],
            ),
          ],
        ),
        const ResponsiveSpacing(mobile: 20),

        ResponsiveRow(
          children: [
            ResponsiveTextField(
              label: 'Latitude',
              icon: Icons.explore_outlined,
              controller: _latitudeController,
              keyboardType: const TextInputType.numberWithOptions(
                decimal: true,
              ),
              isRequired: false,
            ),
            ResponsiveTextField(
              label: 'Longitude',
              icon: Icons.explore_outlined,
              controller: _longitudeController,
              keyboardType: const TextInputType.numberWithOptions(
                decimal: true,
              ),
              isRequired: false,
            ),
          ],
        ),
        const ResponsiveSpacing(mobile: 20),

        // Products Covered
        _buildProductsCoveredCard(),
      ],
    );
  }

  Widget _buildProductsCoveredCard() {
    return Container(
      padding: EdgeInsets.all(16.w),
      decoration: BoxDecoration(
        color: const Color(0xFFF0F9FF),
        borderRadius: BorderRadius.circular(12.r),
        border: Border.all(color: const Color(0xFF3B82F6).withOpacity(0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.inventory_2_outlined,
                color: const Color(0xFF3B82F6),
                size: 24.sp,
              ),
              SizedBox(width: 12.w),
              Text(
                'Products Covered',
                style: TextStyle(
                  fontSize: 16.sp,
                  fontWeight: FontWeight.w600,
                  color: const Color(0xFF1E3A8A),
                ),
              ),
            ],
          ),
          SizedBox(height: 8.h),
          ..._productList.map((item) {
            return CheckboxListTile(
              value: _selectedProducts.contains(item),
              title: Text(
                item,
                style: TextStyle(fontSize: 14.sp, color: Colors.black87),
              ),
              activeColor: const Color(0xFF1E3A8A),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8.r),
              ),
              onChanged: (val) {
                setState(() {
                  if (val == true) {
                    _selectedProducts.add(item);
                  } else {
                    _selectedProducts.remove(item);
                  }
                });
              },
            );
          }),
        ],
      ),
    );
  }

  // =====================================================================
  //  STEP 2 — Participants
  // =====================================================================
  Widget _buildParticipantsSection() {
    return ResponsiveSection(
      title: 'Participants',
      icon: Icons.groups_rounded,
      subtitle: 'Add the attendees for this activity',
      children: [
        ...List.generate(_participantRows.length, (index) {
          final row = _participantRows[index];
          return _buildParticipantCard(row, index);
        }),
        SizedBox(height: 12.h),
        SizedBox(
          width: double.infinity,
          child: OutlinedButton.icon(
            onPressed: _addParticipantRow,
            icon: const Icon(Icons.add_rounded),
            label: Text(
              'Add Participant',
              style: TextStyle(fontSize: 14.sp, fontWeight: FontWeight.w600),
            ),
            style: OutlinedButton.styleFrom(
              foregroundColor: const Color(0xFF1E3A8A),
              side: const BorderSide(color: Color(0xFF1E3A8A), width: 1.5),
              padding: EdgeInsets.symmetric(vertical: 14.h),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12.r),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildParticipantCard(_ParticipantRow row, int index) {
    return Container(
      margin: EdgeInsets.only(bottom: 16.h),
      padding: EdgeInsets.all(16.w),
      decoration: BoxDecoration(
        color: Colors.grey.shade50,
        borderRadius: BorderRadius.circular(12.r),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Column(
        children: [
          // Header row
          Row(
            children: [
              Container(
                width: 32.w,
                height: 32.h,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: const Color(0xFF1E3A8A).withOpacity(0.1),
                ),
                child: Center(
                  child: Text(
                    '${index + 1}',
                    style: TextStyle(
                      fontSize: 14.sp,
                      fontWeight: FontWeight.bold,
                      color: const Color(0xFF1E3A8A),
                    ),
                  ),
                ),
              ),
              SizedBox(width: 12.w),
              Text(
                'Participant ${index + 1}',
                style: TextStyle(
                  fontSize: 15.sp,
                  fontWeight: FontWeight.w600,
                  color: Colors.black87,
                ),
              ),
              const Spacer(),
              if (_participantRows.length > 1)
                IconButton(
                  onPressed: () => _removeParticipantRow(index),
                  icon: const Icon(
                    Icons.delete_outline_rounded,
                    color: Colors.red,
                  ),
                  tooltip: 'Remove',
                ),
            ],
          ),
          SizedBox(height: 16.h),

          // Participant Type
          ModernDropdown(
            label: 'Participant Type',
            icon: Icons.person_outline_rounded,
            isRequired: true,
            items: const [
              'Painter',
              'Contractor',
              'Retailer',
              'Tile Applicator',
              'Architect',
              'Other',
            ],
            value: _getParticipantTypeLabel(row.attnType),
            onChanged: (val) {
              setState(() {
                row.attnType = _getParticipantTypeCode(val ?? 'Painter');
              });
            },
          ),
          const ResponsiveSpacing(mobile: 16),

          ResponsiveRow(
            children: [
              ResponsiveTextField(
                label: 'Code',
                icon: Icons.tag_rounded,
                controller: row.attnCodeController,
                isRequired: false,
              ),
              ResponsiveTextField(
                label: 'Name',
                icon: Icons.person_outline_rounded,
                controller: row.partNameController,
                isRequired: false,
              ),
            ],
          ),
          const ResponsiveSpacing(mobile: 16),

          ResponsiveTextField(
            label: 'Mobile Number',
            icon: Icons.phone_outlined,
            controller: row.partMoblController,
            keyboardType: TextInputType.phone,
            isRequired: false,
            inputFormatters: [
              FilteringTextInputFormatter.allow(RegExp(r'[0-9+]')),
            ],
          ),
          const ResponsiveSpacing(mobile: 16),

          ModernDropdown(
            label: 'KYC Status',
            icon: Icons.verified_user_outlined,
            items: const ['No', 'Partial', 'Full'],
            value: _getKycLabel(row.kycStsFl),
            onChanged: (val) {
              setState(() {
                row.kycStsFl = _getKycCode(val ?? 'No');
              });
            },
          ),
          const ResponsiveSpacing(mobile: 16),

          ResponsiveRow(
            children: [
              ResponsiveTextField(
                label: 'Gift Quantity',
                icon: Icons.card_giftcard_outlined,
                controller: row.giftQntyController,
                keyboardType: TextInputType.number,
                isRequired: false,
              ),
              ResponsiveTextField(
                label: 'Gift Item',
                icon: Icons.redeem_outlined,
                controller: row.giftItemController,
                isRequired: false,
              ),
            ],
          ),
        ],
      ),
    );
  }

  // =====================================================================
  //  STEP 3 — Gift & Financials
  // =====================================================================
  Widget _buildGiftAndFinancialsSection() {
    return ResponsiveSection(
      title: 'Gift & Financials',
      icon: Icons.card_giftcard_rounded,
      subtitle: 'Gift distribution and spending details',
      children: [
        ModernDropdown(
          label: 'Gift Distributed',
          icon: Icons.card_giftcard_outlined,
          isRequired: true,
          items: const ['Yes', 'No'],
          value: _giftDist == 'Y' ? 'Yes' : 'No',
          onChanged: (val) {
            setState(() {
              _giftDist = val == 'Yes' ? 'Y' : 'N';
            });
          },
        ),
        const ResponsiveSpacing(mobile: 20),

        ResponsiveRow(
          children: [
            ResponsiveTextField(
              label: 'Total Gift Quantity',
              icon: Icons.format_list_numbered_rounded,
              controller: _giftQntyController,
              keyboardType: TextInputType.number,
              isRequired: false,
            ),
            ResponsiveTextField(
              label: 'Gift Purchased By',
              icon: Icons.shopping_bag_outlined,
              controller: _giftByWhController,
              isRequired: false,
            ),
          ],
        ),
        const ResponsiveSpacing(mobile: 20),

        ResponsiveTextField(
          label: 'Amount Spent',
          icon: Icons.attach_money_rounded,
          controller: _amtSpendController,
          keyboardType: const TextInputType.numberWithOptions(decimal: true),
          isRequired: false,
        ),
        const ResponsiveSpacing(mobile: 20),

        ResponsiveTextField(
          label: 'Remarks',
          icon: Icons.notes_rounded,
          controller: _remarkController,
          maxLines: 3,
          isRequired: false,
        ),
      ],
    );
  }

  // =====================================================================
  //  NAVIGATION BUTTONS
  // =====================================================================
  Widget _buildNavigationButtons() {
    return Row(
      children: [
        // Previous button
        if (_currentStep > 1)
          Expanded(
            child: OutlinedButton(
              onPressed: () {
                setState(() {
                  _currentStep--;
                });
                _scrollController.animateTo(
                  0,
                  duration: const Duration(milliseconds: 300),
                  curve: Curves.easeOut,
                );
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

        // Next / Submit button
        Expanded(
          child: ElevatedButton(
            onPressed: () {
              if (_currentStep < 3) {
                // Validate step 1 before advancing
                if (_currentStep == 1) {
                  if (_selectedActType == null || _selectedActType!.isEmpty) {
                    _showMsg('Please select an activity type');
                    return;
                  }
                  if (_selectedArea == null || _selectedArea!.isEmpty) {
                    _showMsg('Please select emirate/area');
                    return;
                  }
                }
                setState(() {
                  _currentStep++;
                });
                _scrollController.animateTo(
                  0,
                  duration: const Duration(milliseconds: 300),
                  curve: Curves.easeOut,
                );
              } else {
                _submit();
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
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  _currentStep < 3 ? 'Next' : 'Final Submit',
                  style: TextStyle(
                    fontSize: 16.sp,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                SizedBox(width: 8.w),
                Icon(
                  _currentStep < 3
                      ? Icons.arrow_forward_rounded
                      : Icons.check_circle_rounded,
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  // =====================================================================
  //  HELPERS
  // =====================================================================
  String _getParticipantTypeLabel(String code) {
    switch (code) {
      case 'P':
        return 'Painter';
      case 'C':
        return 'Contractor';
      case 'R':
        return 'Retailer';
      case 'T':
        return 'Tile Applicator';
      case 'A':
        return 'Architect';
      case 'O':
        return 'Other';
      default:
        return 'Painter';
    }
  }

  String _getParticipantTypeCode(String label) {
    switch (label) {
      case 'Painter':
        return 'P';
      case 'Contractor':
        return 'C';
      case 'Retailer':
        return 'R';
      case 'Tile Applicator':
        return 'T';
      case 'Architect':
        return 'A';
      case 'Other':
        return 'O';
      default:
        return 'P';
    }
  }

  String _getKycLabel(String code) {
    switch (code) {
      case 'N':
        return 'No';
      case 'P':
        return 'Partial';
      case 'F':
        return 'Full';
      default:
        return 'No';
    }
  }

  String _getKycCode(String label) {
    switch (label) {
      case 'No':
        return 'N';
      case 'Partial':
        return 'P';
      case 'Full':
        return 'F';
      default:
        return 'N';
    }
  }
}

// =====================================================================
//  PARTICIPANT ROW MODEL
// =====================================================================
class _ParticipantRow {
  String attnType = 'P';
  String kycStsFl = 'N';

  final TextEditingController attnCodeController = TextEditingController();
  final TextEditingController partNameController = TextEditingController();
  final TextEditingController partMoblController = TextEditingController();
  final TextEditingController giftQntyController = TextEditingController();
  final TextEditingController giftItemController = TextEditingController();

  void dispose() {
    attnCodeController.dispose();
    partNameController.dispose();
    partMoblController.dispose();
    giftQntyController.dispose();
    giftItemController.dispose();
  }
}
