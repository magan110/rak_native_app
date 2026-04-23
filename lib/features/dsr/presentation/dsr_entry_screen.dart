import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:intl/intl.dart';
import 'package:go_router/go_router.dart';
import 'package:path/path.dart' as path;
import 'package:rak_app/core/models/dsr_models.dart';
import 'package:rak_app/core/services/auth_service.dart';
import 'package:rak_app/core/services/dsr_service.dart';
import 'package:rak_app/core/services/image_upload_service.dart';
import 'package:rak_app/shared/widgets/custom_back_button.dart';
import 'package:rak_app/shared/widgets/file_upload_widget.dart';
import 'package:rak_app/shared/widgets/modern_dropdown.dart';
import 'package:rak_app/shared/widgets/responsive_widgets.dart';

class DsrEntryScreen extends StatefulWidget {
  final String loginId;

  const DsrEntryScreen({super.key, required this.loginId});

  @override
  State<DsrEntryScreen> createState() => _DsrEntryScreenState();
}

class _DsrEntryScreenState extends State<DsrEntryScreen>
    with TickerProviderStateMixin {
  late AnimationController _mainController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;
  late Animation<double> _scaleAnimation;

  final ScrollController _scrollController = ScrollController();
  bool _loading = false;
  int _currentStep = 1;

  String _procType = 'A';
  String? _selectedDocuNumb;
  String? _selectedDsrParam;
  String? _selectedAreaCode;
  String? _selectedEmirateCode;
  String? _selectedSubAreaCode;
  String? _selectedSubAreaName;
  String? _selectedPartyType;
  String? _selectedAttachmentType;

  List<DsrOptionItem> _activities = [];
  List<DsrOptionItem> _areas = [];
  List<Map<String, dynamic>> _areasRaw = [];
  List<Map<String, dynamic>> _subAreasRaw = [];
  List<DsrOptionItem> _emirates = [];
  bool _hasSubAreas = false;
  List<DsrOptionItem> _partyTypes = [];
  List<DsrOptionItem> _products = [];
  List<DsrOptionItem> _documentTypes = [];
  List<DsrOptionItem> _giftTypes = [];
  List<DsrDocumentSummary> _documents = [];

  DsrTemplate? _template;
  DsrParty? _selectedParty;

  final TextEditingController _submissionDateCtrl = TextEditingController();
  final TextEditingController _reportDateCtrl = TextEditingController();
  final TextEditingController _partySearchCtrl = TextEditingController();

  final Map<String, TextEditingController> _ctrl = {
    'dsrRem01': TextEditingController(),
    'dsrRem02': TextEditingController(),
    'dsrRem03': TextEditingController(),
    'dsrRem04': TextEditingController(),
    'dsrRem05': TextEditingController(),
    'dsrRem06': TextEditingController(),
    'dsrRem07': TextEditingController(),
    'dsrRem08': TextEditingController(),
    'dsrRem09': TextEditingController(),
    'mrktName': TextEditingController(),
    'pendIsue': TextEditingController(),
    'pndIsuDt': TextEditingController(),
    'isuDetal': TextEditingController(),
    'ordExDat': TextEditingController(),
    'district': TextEditingController(),
    'pinCodeN': TextEditingController(),
    'cityName': TextEditingController(),
    'cstBisTy': TextEditingController(),
    'locaCapr': TextEditingController(),
    'geoLatit': TextEditingController(),
    'geoLongt': TextEditingController(),
    'ltLgDist': TextEditingController(),
    'prtDsCnt': TextEditingController(),
    'isTilRtl': TextEditingController(),
    'tileStck': TextEditingController(),
    // White Cement Availability Slab
    'wcRakQty': TextEditingController(text: '0'),
    'wcJkQty': TextEditingController(text: '0'),
    'wcNcfQty': TextEditingController(text: '0'),
    'wcIranName': TextEditingController(),
    'wcIranQty': TextEditingController(text: '0'),
    // BW Stock – WCP
    'bwWcp5kg': TextEditingController(text: '0'),
    'bwWcp20kg': TextEditingController(text: '0'),
    // BW Stock – Tile Adhesive
    'bwTaGp': TextEditingController(text: '0'),
    'bwTaTx1': TextEditingController(text: '0'),
    'bwTaTx2': TextEditingController(text: '0'),
    'bwTaTx3': TextEditingController(text: '0'),
    // Avg movement
    'jkAvgWcc': TextEditingController(text: '0'),
    'jkAvgWcp': TextEditingController(text: '0'),
    'asAvgWcc': TextEditingController(text: '0'),
    'asAvgWcp': TextEditingController(text: '0'),
    'otAvgWcc': TextEditingController(text: '0'),
    'otAvgWcp': TextEditingController(text: '0'),
    'slWcVlum': TextEditingController(),
    'slWpVlum': TextEditingController(),
    // Last bill date
    'lastBillDate': TextEditingController(),
    // Competition activity
    'competitionDesc': TextEditingController(),
  };

  List<DsrClassicRow> _classicRows = [DsrClassicRow()];
  List<DsrClassicRow> _marketMappingRows = [];
  List<DsrNewVisitOrderRow> _orderRows = [DsrNewVisitOrderRow()];
  List<DsrMarketPriceRow> _marketPriceRows = [DsrMarketPriceRow()];
  List<DsrGiftRow> _giftRows = [DsrGiftRow()];
  List<LocalDsrAttachment> _attachments = [];

  final Map<String, List<DsrSkuItem>> _skuCache = {};

  String get _authAreaCode => AuthManager.getUserAreaCode().trim();

  String get _deptCode => AuthManager.getUserDeptCode().trim();

  String get _effectiveAreaCode {
    final selected = (_selectedAreaCode ?? '').trim();
    if (selected.isNotEmpty) return selected;
    // Always read fresh from AuthManager in case it was populated after init
    return AuthManager.getUserAreaCode().trim();
  }

  @override
  void initState() {
    super.initState();
    _mainController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );
    _fadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(_mainController);
    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 0.08),
      end: Offset.zero,
    ).animate(_mainController);
    _scaleAnimation = Tween<double>(begin: 0.97, end: 1.0).animate(
      CurvedAnimation(
        parent: _mainController,
        curve: const Interval(0.2, 1, curve: Curves.easeOutCubic),
      ),
    );
    _mainController.forward();
    final authArea = AuthManager.getUserAreaCode().trim();
    _selectedAreaCode = authArea.isEmpty ? null : authArea;
    _submissionDateCtrl.text = DsrService.todayDmy();
    _reportDateCtrl.text = DsrService.todayDmy();
    _loadInitial();
  }

  @override
  void dispose() {
    _mainController.dispose();
    _scrollController.dispose();
    _submissionDateCtrl.dispose();
    _reportDateCtrl.dispose();
    _partySearchCtrl.dispose();
    for (final c in _ctrl.values) {
      c.dispose();
    }
    super.dispose();
  }

  Future<void> _loadInitial() async {
    setState(() => _loading = true);
    try {
      final dept = _deptCode;
      if (dept.isEmpty) {
        _toast('Department code not found. Please re-login.');
      }
      // Load standard lists and emirates; keep legacy areas for compatibility
      final results = await Future.wait([
        DsrService.getActivities(dept),
        DsrService.getAreas(widget.loginId), // legacy area loader
        DsrService.getPartyTypes(),
        DsrService.getProducts(),
        DsrService.getDocumentTypes(),
        DsrService.getGiftTypes(),
        DsrService.getEmiratesList(),
      ]);

      _activities = results[0] as List<DsrOptionItem>;
      _areas = results[1] as List<DsrOptionItem>;
      _partyTypes = results[2] as List<DsrOptionItem>;
      _products = results[3] as List<DsrOptionItem>;
      _documentTypes = results[4] as List<DsrOptionItem>;
      _giftTypes = results[5] as List<DsrOptionItem>;
      _emirates = results[6] as List<DsrOptionItem>;

      // If user had preselected emirate, fetch full area objects
      if (_selectedEmirateCode != null && _selectedEmirateCode!.isNotEmpty) {
        await _fetchAreasForEmirate(_selectedEmirateCode!);
      }
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _fetchAreasForEmirate(String emirateCode) async {
    try {
      final raw = await DsrService.getAreasListRaw(emirateCode);
      if (!mounted) return;
      setState(() {
        _areasRaw = raw;
        _areas = raw
            .map((m) => DsrOptionItem.fromJson(Map<String, dynamic>.from(m)))
            .toList();
        _subAreasRaw = [];
        _hasSubAreas = false;
        _selectedSubAreaCode = null;
        _selectedSubAreaName = null;
      });
    } catch (_) {}
  }

  Future<void> _fetchSubAreasForArea(String areaCode) async {
    try {
      final raw = await DsrService.getSubAreasRaw(areaCode);
      if (!mounted) return;
      final list = (raw['data'] as List<dynamic>).cast<Map<String, dynamic>>();
      setState(() {
        _subAreasRaw = list;
        _hasSubAreas = (raw['hasSubArea'] == true) || list.isNotEmpty;
        if (!_hasSubAreas) {
          _selectedSubAreaCode = null;
          _selectedSubAreaName = null;
          final sel = _areasRaw.firstWhere(
            (a) => (a['code'] ?? '') == areaCode,
            orElse: () => <String, dynamic>{},
          );
          final po = sel['pobox'] ?? '';
          if (po != null && po.toString().isNotEmpty) {
            _ctrl['pinCodeN']!.text = po.toString();
          }
        } else {
          _ctrl['pinCodeN']!.clear();
        }
      });
    } catch (_) {}
  }

  Future<void> _loadTemplate() async {
    if (_selectedDsrParam == null || _selectedDsrParam!.isEmpty) return;

    setState(() => _loading = true);
    try {
      _template = await DsrService.getTemplate(
        dsrParam: _selectedDsrParam!,
        deptCode: _deptCode,
      );

      _documents = await DsrService.getDocuments(
        loginId: widget.loginId,
        dsrParam: _selectedDsrParam!,
      );

      if (_template?.isClassic == true) {
        if (_classicRows.isEmpty) {
          _classicRows = [DsrClassicRow()];
        }
      } else if (_template?.isNewVisit == true) {
        if (_orderRows.isEmpty) {
          _orderRows = [DsrNewVisitOrderRow()];
        }
        if (_marketPriceRows.isEmpty) {
          _marketPriceRows = [DsrMarketPriceRow()];
        }
        if (_giftRows.isEmpty) {
          _giftRows = [DsrGiftRow()];
        }
      }
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _loadDocumentDetail(String docuNumb) async {
    setState(() => _loading = true);
    try {
      final data = await DsrService.getDetail(
        docuNumb: docuNumb,
        loginId: widget.loginId,
      );

      if (data == null) {
        _toast('Unable to load document');
        return;
      }

      final header = Map<String, dynamic>.from(data['header'] ?? {});
      _selectedDocuNumb = (header['docuNumb'] ?? '').toString();
      _selectedDsrParam = (header['dsrParam'] ?? '').toString();
      _selectedPartyType = DsrService.resolvePartyTypeForEdit(
        cusRtlFl: (header['cusRtlFl'] ?? '').toString(),
        cuRtType: (header['cuRtType'] ?? '').toString(),
      );
      // Restore zone/emirate -> area -> subarea chain in sequence
      final restoredZone = (header['zoneCode'] ?? header['ZoneCode'] ?? '')
          .toString();
      final restoredArea = (header['areaCode'] ?? header['AreaCode'] ?? '')
          .toString();
      final restoredSub = (header['subArCod'] ?? header['SubArCod'] ?? '')
          .toString();
      _selectedEmirateCode = restoredZone.isEmpty ? null : restoredZone;

      _reportDateCtrl.text = (header['docuDate'] ?? DsrService.todayDmy())
          .toString();

      _ctrl['ordExDat']!.text = (header['ordExDat'] ?? '').toString();
      _ctrl['dsrRem01']!.text = (header['dsrRem01'] ?? '').toString();
      _ctrl['dsrRem02']!.text = (header['dsrRem02'] ?? '').toString();
      _ctrl['dsrRem03']!.text = (header['dsrRem03'] ?? '').toString();
      _ctrl['dsrRem04']!.text = (header['dsrRem04'] ?? '').toString();
      _ctrl['dsrRem05']!.text = (header['dsrRem05'] ?? '').toString();
      _ctrl['dsrRem06']!.text = (header['dsrRem06'] ?? '').toString();
      _ctrl['dsrRem07']!.text = (header['dsrRem07'] ?? '').toString();
      _ctrl['dsrRem08']!.text = (header['dsrRem08'] ?? '').toString();
      _ctrl['dsrRem09']!.text = (header['dsrRem09'] ?? '').toString();

      _ctrl['district']!.text = (header['district'] ?? '').toString();
      _ctrl['pinCodeN']!.text = (header['pinCodeN'] ?? '').toString();
      _ctrl['cityName']!.text = (header['cityName'] ?? '').toString();
      _ctrl['cstBisTy']!.text = (header['cstBisTy'] ?? '').toString();
      _ctrl['locaCapr']!.text = (header['locaCapr'] ?? '').toString();
      _ctrl['geoLatit']!.text = (header['latitute'] ?? '').toString();
      _ctrl['geoLongt']!.text = (header['lgtitute'] ?? '').toString();
      _ctrl['ltLgDist']!.text = (header['ltLgDist'] ?? '').toString();
      _ctrl['isTilRtl']!.text = (header['isTilRtl'] ?? '').toString();
      _ctrl['tileStck']!.text = (header['tileStck'] ?? '0').toString();

      _ctrl['mrktName']!.text = (header['dsrRem01'] ?? '').toString();
      _ctrl['pendIsue']!.text = (header['dsrRem02'] ?? '').toString();
      _ctrl['pndIsuDt']!.text = (header['dsrRem03'] ?? '').toString();
      _ctrl['isuDetal']!.text = (header['dsrRem04'] ?? '').toString();
      // rem06/rem07 carry lastBillDate & competitionDesc for New Visit mode
      _ctrl['lastBillDate']!.text = (header['dsrRem06'] ?? '').toString();
      _ctrl['competitionDesc']!.text = (header['dsrRem07'] ?? '').toString();
      _ctrl['prtDsCnt']!.text = (header['dsrRem08'] ?? '').toString();

      _partySearchCtrl.text = (header['cusRtlCd'] ?? '').toString();
      _selectedParty = DsrParty(
        code: (header['cusRtlCd'] ?? '').toString(),
        name: (header['cusRtlCd'] ?? '').toString(),
        mobileNo: '',
        locaCapr: (header['locaCapr'] ?? '').toString(),
        district: (header['district'] ?? '').toString(),
        pinCodeN: (header['pinCodeN'] ?? '').toString(),
        cityName: (header['cityName'] ?? '').toString(),
        latitute: (header['latitute'] ?? '').toString(),
        lgtitute: (header['lgtitute'] ?? '').toString(),
        kycVerFl: '',
        mrktName: '',
      );

      await _loadTemplate();

      // Fetch areas for restored emirate then restore area/subarea selections
      if (_selectedEmirateCode != null && _selectedEmirateCode!.isNotEmpty) {
        await _fetchAreasForEmirate(_selectedEmirateCode!);
      }

      if (restoredArea.isNotEmpty) {
        setState(() {
          _selectedAreaCode = restoredArea;
        });
        await _fetchSubAreasForArea(restoredArea);
      }

      if (restoredSub.isNotEmpty) {
        // find matching normalized subarea
        final found = _subAreasRaw.firstWhere(
          (s) => (s['code'] ?? '') == restoredSub,
          orElse: () => <String, dynamic>{},
        );
        if (found.isNotEmpty) {
          setState(() {
            _selectedSubAreaCode = (found['code'] ?? '').toString();
            _selectedSubAreaName = (found['name'] ?? '').toString();
            final po = (found['pobox'] ?? '').toString();
            if (po.isNotEmpty) _ctrl['pinCodeN']!.text = po;
            if ((_selectedSubAreaName ?? '').isNotEmpty) {
              _ctrl['cityName']!.text = _selectedSubAreaName!;
            }
          });
        }
      } else {
        // no sub-area; if area present, restore pin/city from area
        if (_selectedAreaCode != null && _selectedAreaCode!.isNotEmpty) {
          final a = _areasRaw.firstWhere(
            (a) => (a['code'] ?? '') == _selectedAreaCode,
            orElse: () => <String, dynamic>{},
          );
          if (a.isNotEmpty) {
            final po = (a['pobox'] ?? '').toString();
            if (po.isNotEmpty) _ctrl['pinCodeN']!.text = po;
            final aname = (a['name'] ?? '').toString();
            if (aname.isNotEmpty) _ctrl['cityName']!.text = aname;
          }
        }
      }

      _classicRows = ((data['classicRows'] ?? []) as List)
          .map((e) => DsrClassicRow.fromJson(Map<String, dynamic>.from(e)))
          .toList();

      _marketMappingRows = ((data['metricRows'] ?? []) as List)
          .map((e) => DsrClassicRow.fromJson(Map<String, dynamic>.from(e)))
          .toList();

      _orderRows = ((data['orderRows'] ?? []) as List)
          .map(
            (e) => DsrNewVisitOrderRow.fromJson(Map<String, dynamic>.from(e)),
          )
          .toList();

      _marketPriceRows = ((data['marketPriceRows'] ?? []) as List)
          .map((e) => DsrMarketPriceRow.fromJson(Map<String, dynamic>.from(e)))
          .toList();

      _giftRows = ((data['giftRows'] ?? []) as List)
          .map((e) => DsrGiftRow.fromJson(Map<String, dynamic>.from(e)))
          .toList();

      final loadedAttachments = ((data['attachments'] ?? []) as List).map((e) {
        final m = Map<String, dynamic>.from(e);
        return LocalDsrAttachment(
          attFilTy: (m['attFilTy'] ?? '').toString(),
          filePath: (m['fileName'] ?? '').toString(),
          tempDocuNumb: (m['atchNmId'] ?? '').toString(),
        );
      }).toList();
      final competitionAttachment = loadedAttachments
          .where((e) => e.attFilTy == 'COMP')
          .firstOrNull;
      _attachments = loadedAttachments
          .where((e) => e.attFilTy != 'COMP')
          .toList();
      _selectedAttachmentType = _attachments.firstOrNull?.attFilTy;
      _competitionImagePath = competitionAttachment?.filePath;
      _competitionImageAtchNmId = competitionAttachment?.tempDocuNumb;

      _applyNewVisitFixedMetricsFromMetricRows();
      if (_classicRows.isEmpty) _classicRows = [DsrClassicRow()];
      if (_orderRows.isEmpty) _orderRows = [DsrNewVisitOrderRow()];
      if (_marketPriceRows.isEmpty) _marketPriceRows = [DsrMarketPriceRow()];
      if (_giftRows.isEmpty) _giftRows = [DsrGiftRow()];
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  void _applyNewVisitFixedMetricsFromMetricRows() {
    for (final row in _marketMappingRows) {
      if (row.mrktData == '01') {
        // WC Availability Slab – RAK/JK/NCF stored in prodQnty/projQnty/prodQtyV
        _ctrl['wcRakQty']!.text = row.prodQnty;
        _ctrl['wcJkQty']!.text = row.projQnty;
        _ctrl['wcNcfQty']!.text = row.prodQtyV;
        // Iranian cement stored in actnRemk as 'Iranian:<name>:<qty>'
        final parts = row.actnRemk.split(':');
        if (parts.length >= 3) {
          _ctrl['wcIranName']!.text = parts[1].trim();
          _ctrl['wcIranQty']!.text = parts[2].trim();
        }
      } else if (row.mrktData == '02') {
        // BW Stock: WCP 5kg/20kg in prodQnty/projQnty; Tile GP in prodQtyV
        // TX1/TX2/TX3 stored in actnRemk as 'TX1:<v>,TX2:<v>,TX3:<v>'
        _ctrl['bwWcp5kg']!.text = row.prodQnty;
        _ctrl['bwWcp20kg']!.text = row.projQnty;
        _ctrl['bwTaGp']!.text = row.prodQtyV;
        for (final seg in row.actnRemk.split(',')) {
          final kv = seg.split(':');
          if (kv.length == 2) {
            final key = kv[0].trim().toUpperCase();
            final val = kv[1].trim();
            if (key == 'TX1') _ctrl['bwTaTx1']!.text = val;
            if (key == 'TX2') _ctrl['bwTaTx2']!.text = val;
            if (key == 'TX3') _ctrl['bwTaTx3']!.text = val;
          }
        }
      } else if (row.mrktData == '04') {
        final remark = row.actnRemk.toLowerCase();
        if (remark.contains('jk')) {
          _ctrl['jkAvgWcc']!.text = row.prodQnty;
          _ctrl['jkAvgWcp']!.text = row.projQnty;
        } else if (remark.contains('asian')) {
          _ctrl['asAvgWcc']!.text = row.prodQnty;
          _ctrl['asAvgWcp']!.text = row.projQnty;
        } else {
          _ctrl['otAvgWcc']!.text = row.prodQnty;
          _ctrl['otAvgWcp']!.text = row.projQnty;
        }
      }
    }
  }

  Future<void> _searchParty() async {
    if (_selectedPartyType == null || _selectedPartyType!.isEmpty) {
      _toast('Please select Purchaser / Retailer Type');
      return;
    }
    if (_selectedAreaCode == null || _selectedAreaCode!.isEmpty) {
      _toast('Please select Area Code');
      return;
    }

    final rows = await DsrService.searchParty(
      partyType: _selectedPartyType!,
      areaCode: _selectedAreaCode!,
      subArCod: _selectedSubAreaCode ?? '',
      search: _partySearchCtrl.text.trim(),
    );

    if (!mounted) return;

    if (rows.isEmpty) {
      _toast('No record found');
      return;
    }

    final selected = await showDialog<DsrParty>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Select Party'),
        content: SizedBox(
          width: 600,
          child: ListView.builder(
            shrinkWrap: true,
            itemCount: rows.length,
            itemBuilder: (_, index) {
              final item = rows[index];
              return ListTile(
                title: Text(item.name),
                subtitle: Text('${item.code} • ${item.mobileNo}'),
                onTap: () => Navigator.pop(context, item),
              );
            },
          ),
        ),
      ),
    );

    if (selected == null) return;

    setState(() {
      _selectedParty = selected;
      _partySearchCtrl.text = selected.code;
      _ctrl['locaCapr']!.text = selected.locaCapr;
      _ctrl['district']!.text = selected.district;
      _ctrl['pinCodeN']!.text = selected.pinCodeN;
      _ctrl['cityName']!.text = selected.cityName;
      // Market name: auto-fill once and then lock (one-time entry)
      if (_ctrl['mrktName']!.text.isEmpty) {
        _ctrl['mrktName']!.text = selected.mrktName;
        _mrktNameLocked = true;
      }
    });
  }

  Future<void> _pickReportDate() async {
    final now = DateTime.now();
    DateTime initial = now;
    try {
      initial = DateFormat('dd/MM/yyyy').parseStrict(_reportDateCtrl.text);
    } catch (_) {}
    final selected = await showDatePicker(
      context: context,
      initialDate: initial,
      firstDate: now.subtract(const Duration(days: 3)),
      lastDate: now,
    );
    if (selected != null) {
      _reportDateCtrl.text = DateFormat('dd/MM/yyyy').format(selected);
      setState(() {});
    }
  }

  Future<void> _pickGenericDate(TextEditingController controller) async {
    final now = DateTime.now();
    DateTime initial = now;
    try {
      if (controller.text.isNotEmpty) {
        initial = DateFormat('dd/MM/yyyy').parseStrict(controller.text);
      }
    } catch (_) {}
    final selected = await showDatePicker(
      context: context,
      initialDate: initial,
      firstDate: now.subtract(const Duration(days: 365)),
      lastDate: now.add(const Duration(days: 365)),
    );
    if (selected != null) {
      controller.text = DateFormat('dd/MM/yyyy').format(selected);
      setState(() {});
    }
  }

  bool _validate() {
    if (_selectedDsrParam == null || _selectedDsrParam!.isEmpty) {
      _toast('Please select Activity Type');
      return false;
    }

    if (_isDocumentSelectionRequired &&
        (_selectedDocuNumb == null || _selectedDocuNumb!.isEmpty)) {
      _toast('Please select Document No');
      return false;
    }

    if (_isCustomerSelectionRequired) {
      if (_selectedPartyType == null || _selectedPartyType!.isEmpty) {
        _toast('Please select Purchaser / Retailer Type');
        return false;
      }
      if (_selectedAreaCode == null || _selectedAreaCode!.isEmpty) {
        _toast('Please select Area Code');
        return false;
      }
      if (_partySearchCtrl.text.trim().isEmpty) {
        _toast('Please select Code');
        return false;
      }
    }

    for (final field in _template?.fields ?? <DsrFieldConfig>[]) {
      if (_isDynamicFieldRequired(field) &&
          _ctrl[field.key]!.text.trim().isEmpty) {
        _toast('Please enter ${field.label}');
        return false;
      }
    }

    if (_isPinSectionRequired) {
      if (_ctrl['pinCodeN']!.text.trim().isEmpty) {
        _toast('Pin Code is required');
        return false;
      }
      // district and city are compatibility-only and sent as empty strings
    }

    if (_requiresClassicDetailRows) {
      final populatedRows = _classicRows.asMap().entries.where(
        (entry) => _hasClassicRowContent(entry.value),
      );

      if (populatedRows.isEmpty) {
        _toast('Please add at least one detail row');
        return false;
      }

      for (final entry in populatedRows) {
        final rowNumber = entry.key + 1;
        final row = entry.value;

        if (_template?.productGridRequired == true) {
          if (row.repoCatg.trim().isEmpty) {
            _toast('Please select Product in detail row $rowNumber');
            return false;
          }
          if (row.prodQnty.trim().isEmpty) {
            _toast('Please enter New Order Qty in detail row $rowNumber');
            return false;
          }
        }

        if (_template?.projectQtyRequired == true &&
            row.projQnty.trim().isEmpty) {
          _toast('Please enter Projection Qty in detail row $rowNumber');
          return false;
        }

        if (_template?.actionGridRequired == true &&
            row.actnRemk.trim().isEmpty) {
          _toast('Please enter Action Remark in detail row $rowNumber');
          return false;
        }
      }
    }

    if (_requiresOrderRows) {
      final populatedRows = _orderRows.asMap().entries.where(
        (entry) => _hasOrderRowContent(entry.value),
      );

      if (populatedRows.isEmpty) {
        _toast('Please add at least one order row');
        return false;
      }

      for (final entry in populatedRows) {
        final rowNumber = entry.key + 1;
        final row = entry.value;

        if (row.repoCatg.trim().isEmpty) {
          _toast('Please select Product in order row $rowNumber');
          return false;
        }
        if (row.catgPack.trim().isEmpty) {
          _toast('Please select Product SKU in order row $rowNumber');
          return false;
        }
        if (row.prodQnty.trim().isEmpty) {
          _toast('Please enter Qty in Bags in order row $rowNumber');
          return false;
        }
      }
    }

    return true;
  }

  bool _validateStep(int step) {
    if (step == 1) {
      if (_selectedDsrParam == null || _selectedDsrParam!.isEmpty) {
        _toast('Please select Activity Type');
        return false;
      }

      if (_procType != 'A' &&
          (_selectedDocuNumb == null || _selectedDocuNumb!.isEmpty)) {
        _toast('Please select Document No');
        return false;
      }

      if (_template == null) {
        _toast('Please wait for activity details to load');
        return false;
      }

      return true;
    }

    if (step == 2) {
      return _validate();
    }

    return true;
  }

  Future<void> _submit(String submMthd) async {
    if (!_validate()) return;

    // Determine Area/Zone based on whether customer selection is required.
    String selectedAreaCode;
    String zoneCodeForSave;
    if (_isCustomerSelectionRequired) {
      // Customer selection flow: require explicit selections
      selectedAreaCode = _selectedAreaCode?.trim() ?? '';
      if (selectedAreaCode.isEmpty) {
        _toast('Please select Area');
        return;
      }
      zoneCodeForSave = _selectedEmirateCode?.trim() ?? '';
      if (zoneCodeForSave.isEmpty) {
        _toast('Please select Emirate');
        return;
      }
      if (selectedAreaCode.length != 3) {
        _toast('Area code must be 3 characters');
        return;
      }
    } else {
      // Non-customer flows: prefer explicit selected area, else fallback to effective area
      selectedAreaCode =
          (_selectedAreaCode != null && _selectedAreaCode!.trim().isNotEmpty)
          ? _selectedAreaCode!.trim()
          : _effectiveAreaCode;
      zoneCodeForSave = _selectedEmirateCode?.trim() ?? '';
      if (selectedAreaCode.isNotEmpty && selectedAreaCode.length != 3) {
        _toast('Area code must be 3 characters');
        return;
      }
    }

    // Resolve login id from auth manager if widget.loginId is empty
    final currentUser = AuthManager.currentUser;
    final resolvedLoginId =
        (currentUser?.userID ?? currentUser?.emplName ?? widget.loginId).trim();
    if (resolvedLoginId.isEmpty) {
      _toast('Login ID is required');
      return;
    }

    setState(() => _loading = true);
    try {
      final isNewVisit = _template?.isNewVisit == true;

      // ── Map field controllers to dsrRem slots ──────────────────────────
      // New Visit uses custom-keyed controllers (mrktName, pendIsue…) that
      // the backend stores in dsrRem01–04. Classic uses dsrRem01… directly.
      final String rem01 = isNewVisit
          ? _ctrl['mrktName']!.text.trim()
          : _ctrl['dsrRem01']!.text.trim();
      final String rem02 = isNewVisit
          ? _ctrl['pendIsue']!.text.trim()
          : _ctrl['dsrRem02']!.text.trim();
      final String rem03 = isNewVisit
          ? _ctrl['pndIsuDt']!.text.trim()
          : _ctrl['dsrRem03']!.text.trim();
      final String rem04 = isNewVisit
          ? _ctrl['isuDetal']!.text.trim()
          : _ctrl['dsrRem04']!.text.trim();
      final String rem05 = _ctrl['dsrRem05']!.text.trim();
      // rem06/rem07 carry lastBillDate & competitionDesc for New Visit
      final String rem06 = isNewVisit
          ? _ctrl['lastBillDate']!.text.trim()
          : _ctrl['dsrRem06']!.text.trim();
      final String rem07 = isNewVisit
          ? _ctrl['competitionDesc']!.text.trim()
          : _ctrl['dsrRem07']!.text.trim();
      final String rem08 = _ctrl['dsrRem08']!.text.trim();
      final String rem09 = _ctrl['dsrRem09']!.text.trim();

      // ── Build combined market-metric rows ──────────────────────────────
      final List<DsrClassicRow> allMetricRows = [];

      if (isNewVisit) {
        // mrktData='01' — White Cement Availability Slab
        allMetricRows.add(
          DsrClassicRow(
            repoCatg: '',
            catgPack: '',
            prodQnty: _ctrl['wcRakQty']!.text.trim(),
            projQnty: _ctrl['wcJkQty']!.text.trim(),
            prodQtyV: _ctrl['wcNcfQty']!.text.trim(),
            actnRemk:
                'Iranian:${_ctrl['wcIranName']!.text.trim()}:${_ctrl['wcIranQty']!.text.trim()}',
            mrktData: '01',
          ),
        );

        // mrktData='02' — BW Stock Availability
        allMetricRows.add(
          DsrClassicRow(
            repoCatg: '',
            catgPack: '',
            prodQnty: _ctrl['bwWcp5kg']!.text.trim(),
            projQnty: _ctrl['bwWcp20kg']!.text.trim(),
            prodQtyV: _ctrl['bwTaGp']!.text.trim(),
            actnRemk:
                'TX1:${_ctrl['bwTaTx1']!.text.trim()},TX2:${_ctrl['bwTaTx2']!.text.trim()},TX3:${_ctrl['bwTaTx3']!.text.trim()}',
            mrktData: '02',
          ),
        );

        // mrktData='04' — Last 3-month average (one row per competitor)
        allMetricRows.add(
          DsrClassicRow(
            repoCatg: '',
            catgPack: '',
            prodQnty: _ctrl['jkAvgWcc']!.text.trim(),
            projQnty: _ctrl['jkAvgWcp']!.text.trim(),
            actnRemk: 'JK',
            mrktData: '04',
          ),
        );
        allMetricRows.add(
          DsrClassicRow(
            repoCatg: '',
            catgPack: '',
            prodQnty: _ctrl['asAvgWcc']!.text.trim(),
            projQnty: _ctrl['asAvgWcp']!.text.trim(),
            actnRemk: 'Asian',
            mrktData: '04',
          ),
        );
        allMetricRows.add(
          DsrClassicRow(
            repoCatg: '',
            catgPack: '',
            prodQnty: _ctrl['otAvgWcc']!.text.trim(),
            projQnty: _ctrl['otAvgWcp']!.text.trim(),
            actnRemk: 'Other',
            mrktData: '04',
          ),
        );

        // mrktData='05' — Order booked rows
        for (final row in _orderRows) {
          if (row.repoCatg.trim().isEmpty && row.catgPack.trim().isEmpty) {
            continue;
          }
          allMetricRows.add(
            DsrClassicRow(
              repoCatg: row.repoCatg,
              catgPack: row.catgPack,
              prodQnty: row.prodQnty,
              projQnty: row.projQnty,
              mrktData: '05',
            ),
          );
        }

        // mrktData='06' — Market price rows
        for (final row in _marketPriceRows) {
          if (row.brandCode.trim().isEmpty) continue;
          allMetricRows.add(
            DsrClassicRow(
              repoCatg: row.brandCode,
              catgPack: row.skuCode,
              prodQnty: row.bPrice,
              projQnty: row.cPrice,
              mrktData: '06',
            ),
          );
        }
      } else {
        // Classic: existing _marketMappingRows are already tagged with mrktData
        allMetricRows.addAll(_marketMappingRows);
      }

      final uploadedAttachments = await _prepareAttachmentsForSave();
      if (uploadedAttachments == null) {
        return;
      }

      // Determine Zone/Area/Sub selection for save
      final zoneCode = zoneCodeForSave;
      final subArCodForSave = _selectedSubAreaCode?.trim() ?? '';

      // Debug prints to help diagnose backend doc number generation issues
      print(
        'DSR SAVE DEBUG -> zoneCode=$zoneCode, areaCode=$selectedAreaCode, subArCod=$subArCodForSave, effectiveArea=$_effectiveAreaCode, loginId=$resolvedLoginId',
      );

      // CityName: prefer selected sub-area name, fallback to selected area name
      String cityForSave = _ctrl['cityName']!.text.trim();
      if ((_selectedSubAreaName ?? '').isNotEmpty) {
        cityForSave = _selectedSubAreaName!;
      } else if (cityForSave.isEmpty && (selectedAreaCode).isNotEmpty) {
        final a = _areasRaw.firstWhere(
          (a) => (a['code'] ?? '') == selectedAreaCode,
          orElse: () => <String, dynamic>{},
        );
        if (a.isNotEmpty) cityForSave = (a['name'] ?? '').toString();
      }

      final req = DsrSaveRequest(
        procType: _procType,
        formMode: _template?.formMode ?? 'classic',
        docuNumb: _selectedDocuNumb,
        loginId: resolvedLoginId,
        deptCode: _deptCode,
        docuDate: _reportDateCtrl.text.trim(),
        ordExDat: _ctrl['ordExDat']!.text.trim(),
        dsrParam: _selectedDsrParam ?? '',
        cusRtlFl: _selectedPartyType ?? '',
        zoneCode: zoneCode,
        areaCode: selectedAreaCode,
        cusRtlCd: _partySearchCtrl.text.trim(),
        cuRtType: DsrService.inferCuRtType(_selectedPartyType ?? ''),
        dsrRem01: rem01,
        dsrRem02: rem02,
        dsrRem03: rem03,
        dsrRem04: rem04,
        dsrRem05: rem05,
        dsrRem06: rem06,
        dsrRem07: rem07,
        dsrRem08: rem08,
        dsrRem09: rem09,
        dsrRem10: '',
        // District is compatibility-only for backend; keep empty unless needed
        district: '',
        pinCodeN: _ctrl['pinCodeN']!.text.trim(),
        cityName: cityForSave,
        subArCod: subArCodForSave,
        cstBisTy: _ctrl['cstBisTy']!.text.trim(),
        isTilRtl: _ctrl['isTilRtl']!.text.trim(),
        tileStck: _ctrl['tileStck']!.text.trim(),
        locaCapr: _ctrl['locaCapr']!.text.trim(),
        geoLatit: _ctrl['geoLatit']!.text.trim(),
        geoLongt: _ctrl['geoLongt']!.text.trim(),
        ltLgDist: _ctrl['ltLgDist']!.text.trim(),
        classicRows: _classicRows,
        marketMappingRows: allMetricRows,
        attachments: uploadedAttachments
            .map(
              (e) => DsrAttachmentRef(
                tempDocuNumb: e.tempDocuNumb,
                attFilTy: e.attFilTy,
                fileName: e.filePath,
              ),
            )
            .toList(),
      );

      final res = await DsrService.saveDsr(req);

      if (!mounted) return;

      if (!res.success) {
        _toast(res.message.isNotEmpty ? res.message : res.error);
        return;
      }

      _toast('Saved successfully. Doc No: ${res.docuNumb}');

      if (submMthd == 'E') {
        Navigator.pop(context, true);
      } else {
        _resetForm();
      }
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  void _resetForm() {
    _procType = 'A';
    _currentStep = 1;
    _selectedDocuNumb = null;
    _selectedDsrParam = null;
    _selectedAreaCode = _authAreaCode.isEmpty ? null : _authAreaCode;
    _selectedPartyType = null;
    _selectedAttachmentType = null;
    _selectedParty = null;
    _mrktNameLocked = false;
    _competitionImagePath = null;
    _competitionImageAtchNmId = null;
    _template = null;
    _documents = [];

    _submissionDateCtrl.text = DsrService.todayDmy();
    _reportDateCtrl.text = DsrService.todayDmy();
    _partySearchCtrl.clear();

    for (final c in _ctrl.values) {
      c.clear();
    }

    _ctrl['wcRakQty']!.text = '0';
    _ctrl['wcJkQty']!.text = '0';
    _ctrl['wcNcfQty']!.text = '0';
    _ctrl['wcIranQty']!.text = '0';
    _ctrl['bwWcp5kg']!.text = '0';
    _ctrl['bwWcp20kg']!.text = '0';
    _ctrl['bwTaGp']!.text = '0';
    _ctrl['bwTaTx1']!.text = '0';
    _ctrl['bwTaTx2']!.text = '0';
    _ctrl['bwTaTx3']!.text = '0';
    _ctrl['jkAvgWcc']!.text = '0';
    _ctrl['jkAvgWcp']!.text = '0';
    _ctrl['asAvgWcc']!.text = '0';
    _ctrl['asAvgWcp']!.text = '0';
    _ctrl['otAvgWcc']!.text = '0';
    _ctrl['otAvgWcp']!.text = '0';

    _classicRows = [DsrClassicRow()];
    _marketMappingRows = [];
    _orderRows = [DsrNewVisitOrderRow()];
    _marketPriceRows = [DsrMarketPriceRow()];
    _giftRows = [DsrGiftRow()];
    _attachments = [];

    setState(() {});
  }

  void _toast(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
  }

  bool _looksLikeLocalAttachmentValue(String value) {
    final normalized = value.trim();
    if (normalized.isEmpty) return false;

    return normalized.contains('/') ||
        normalized.contains('\\') ||
        normalized.startsWith('content:') ||
        normalized.startsWith('file:') ||
        normalized.startsWith('data:');
  }

  bool _needsAttachmentUpload(LocalDsrAttachment attachment) {
    final uploadKey = attachment.tempDocuNumb.trim();
    final fileValue = attachment.filePath.trim();

    return uploadKey.isEmpty ||
        uploadKey == fileValue ||
        _looksLikeLocalAttachmentValue(uploadKey) ||
        _looksLikeLocalAttachmentValue(fileValue);
  }

  String _sanitizeAttachmentSegment(String value) {
    final collapsed = value
        .trim()
        .replaceAll(RegExp(r'[^A-Za-z0-9]+'), '_')
        .replaceAll(RegExp(r'_+'), '_')
        .replaceAll(RegExp(r'^_+|_+$'), '');
    return collapsed.isEmpty ? 'NA' : collapsed;
  }

  String _buildAttachmentUploadKey({
    required String attFilTy,
    required int index,
  }) {
    final loginId = _sanitizeAttachmentSegment(widget.loginId);
    final dsrParam = _sanitizeAttachmentSegment(_selectedDsrParam ?? 'NA');
    final docRef = _sanitizeAttachmentSegment(_selectedDocuNumb ?? 'NEW');
    final type = _sanitizeAttachmentSegment(
      attFilTy.isEmpty ? 'DOC' : attFilTy,
    );
    final timestamp = DateTime.now().microsecondsSinceEpoch;

    return 'DSR_${loginId}_${dsrParam}_${docRef}_${type}_${timestamp}_$index';
  }

  Future<List<LocalDsrAttachment>?> _prepareAttachmentsForSave() async {
    final pendingAttachments = <LocalDsrAttachment>[
      ..._attachments,
      if (_competitionImagePath != null &&
          _competitionImagePath!.trim().isNotEmpty)
        LocalDsrAttachment(
          attFilTy: 'COMP',
          filePath: _competitionImagePath!.trim(),
          tempDocuNumb: (_competitionImageAtchNmId ?? _competitionImagePath!)
              .trim(),
        ),
    ];

    if (pendingAttachments.isEmpty) {
      return const <LocalDsrAttachment>[];
    }

    final currentUser = AuthManager.currentUser;
    final resolvedCreateId =
        (currentUser?.userID ?? currentUser?.emplName ?? widget.loginId).trim();
    final createId = resolvedCreateId.isEmpty ? 'SYSTEM' : resolvedCreateId;

    final uploadedAttachments = <LocalDsrAttachment>[];
    var didUploadNewFiles = false;

    for (var index = 0; index < pendingAttachments.length; index++) {
      final attachment = pendingAttachments[index];

      if (!_needsAttachmentUpload(attachment)) {
        uploadedAttachments.add(attachment);
        continue;
      }

      final uploadKey = _buildAttachmentUploadKey(
        attFilTy: attachment.attFilTy,
        index: index + 1,
      );
      final response = await ImageUploadService.uploadImage(
        filePath: attachment.filePath,
        attFilKy: uploadKey,
        attFilTy: attachment.attFilTy.isEmpty ? 'DOC' : attachment.attFilTy,
        createId: createId,
      );

      if (!response.success) {
        _toast(
          response.message.isNotEmpty
              ? 'Failed to upload ${attachment.attFilTy}: ${response.message}'
              : 'Failed to upload attachment.',
        );
        return null;
      }

      uploadedAttachments.add(
        LocalDsrAttachment(
          attFilTy: attachment.attFilTy,
          filePath: (response.fileName ?? path.basename(attachment.filePath))
              .trim(),
          tempDocuNumb: (response.attFilKy ?? uploadKey).trim(),
        ),
      );
      didUploadNewFiles = true;
    }

    if (!didUploadNewFiles || !mounted) {
      return uploadedAttachments;
    }

    final supportingAttachments = uploadedAttachments
        .where((e) => e.attFilTy != 'COMP')
        .toList();
    final competitionAttachment = uploadedAttachments
        .where((e) => e.attFilTy == 'COMP')
        .firstOrNull;

    setState(() {
      _attachments = supportingAttachments;
      _selectedAttachmentType = supportingAttachments.firstOrNull?.attFilTy;
      _competitionImagePath = competitionAttachment?.filePath;
      _competitionImageAtchNmId = competitionAttachment?.tempDocuNumb;
    });

    return uploadedAttachments;
  }

  Widget _buildDropdown({
    required String label,
    required String? value,
    required List<String> items,
    required ValueChanged<String?> onChanged,
    bool isRequired = false,
  }) {
    return ModernDropdown(
      label: label,
      value: (value != null && items.contains(value)) ? value : null,
      items: items,
      onChanged: onChanged,
      isRequired: isRequired,
    );
  }

  List<String> _sanitizeOptions(List<String> items) {
    final seen = <String>{};
    final out = <String>[];
    for (final raw in items) {
      final s = (raw ?? '').toString().trim();
      if (s.isEmpty) continue;
      if (seen.add(s)) out.add(s);
    }
    return out;
  }

  Widget _buildText({
    required TextEditingController controller,
    required String label,
    int maxLines = 1,
    bool readOnly = false,
    VoidCallback? onTap,
    bool isRequired = false,
    TextInputType? keyboardType,
  }) {
    return ResponsiveTextField(
      controller: controller,
      label: label,
      maxLines: maxLines,
      readOnly: readOnly,
      onTap: onTap,
      isRequired: isRequired,
      keyboardType: keyboardType,
    );
  }

  bool get _isDocumentSelectionRequired => _procType != 'A';

  bool get _isCustomerSelectionRequired =>
      _template?.customerSelectionRequired == true;

  bool get _isPinSectionRequired => _template?.pinCodeRequired == true;

  bool _templateHasField(String key) {
    return (_template?.fields ?? const <DsrFieldConfig>[]).any(
      (field) => field.key.toLowerCase() == key.toLowerCase(),
    );
  }

  bool _shouldShowManualPinField(String key) {
    return _isPinSectionRequired && !_templateHasField(key);
  }

  // Only show the manual pin entry (moved to Party Details).
  // District and City are now compatibility-only and sent as empty strings.
  bool get _showsManualPinSection => _shouldShowManualPinField('pinCodeN');

  bool get _requiresClassicDetailRows =>
      _template?.isClassic == true &&
      _procType != 'D' &&
      ((_template?.productGridRequired ?? false) ||
          (_template?.actionGridRequired ?? false));

  bool get _requiresOrderRows =>
      _template?.isNewVisit == true && _procType != 'D';

  bool _isImplicitlyRequiredField(String key) {
    if (!_isPinSectionRequired) {
      return false;
    }
    // Only pinCodeN is required now; district and city are compatibility-only
    return key == 'pinCodeN';
  }

  bool _isDynamicFieldRequired(DsrFieldConfig field) {
    return field.requiredField || _isImplicitlyRequiredField(field.key);
  }

  bool _hasClassicRowContent(DsrClassicRow row) {
    return row.repoCatg.trim().isNotEmpty ||
        row.catgPack.trim().isNotEmpty ||
        row.prodQnty.trim().isNotEmpty ||
        row.projQnty.trim().isNotEmpty ||
        row.actnRemk.trim().isNotEmpty ||
        row.targetDt.trim().isNotEmpty;
  }

  bool _hasOrderRowContent(DsrNewVisitOrderRow row) {
    return row.repoCatg.trim().isNotEmpty ||
        row.catgPack.trim().isNotEmpty ||
        row.prodQnty.trim().isNotEmpty;
  }

  Future<void> _ensureSkusLoaded(String repoCatg) async {
    if (repoCatg.trim().isEmpty || _skuCache.containsKey(repoCatg)) {
      return;
    }

    _skuCache[repoCatg] = await DsrService.getSkus(repoCatg);
  }

  String _skuDisplayLabel(DsrSkuItem sku) {
    final code = sku.code.trim();
    final name = sku.name.trim();

    if (code.isEmpty) return name;
    if (name.isEmpty) return code;

    final normalizedCode = code.toLowerCase().replaceAll(RegExp(r'\s+'), '');
    final normalizedName = name.toLowerCase().replaceAll(RegExp(r'\s+'), '');

    if (normalizedCode == normalizedName) {
      return name;
    }

    return '$code - $name';
  }

  // ── Activity label overrides ─────────────────────────────────────────────
  static const _activityRenames = <String, String>{
    'BTL Activity': 'Promotional Meetings',
    'Painter Training Program': 'Applicator Training Program',
    'Other BTL Activity': 'Other Activity',
    'Phone Call with Builder/Stockist': 'Phone Call / Unregistered Purchase',
  };

  // Activities to completely hide from the dropdown
  static const _hiddenActivities = <String>{
    'Internal Meetings',
    'Review Meetings',
    'Visit to Check Sampling at Site',
    'Unregistered Purchase', // merged into Phone Call option above
  };

  // Extra local activities injected after API list
  static final _extraActivities = <DsrOptionItem>[
    const DsrOptionItem(code: 'SV', name: 'Site Visit'),
    const DsrOptionItem(code: 'COV', name: 'Contractor Office Visit'),
  ];

  // Party types to hide in Purchaser Type dropdown
  static const _hiddenPartyTypeNames = <String>{
    'Direct Dealer',
    'Rural Stockist',
    'Rural Retailer',
    'Authorised Dealer',
    'UBS',
  };

  // BTL sub-option renames
  static const _btlSubRenames = <String, String>{
    'Rural Retailer Meet': '', // empty string = hidden
    'Painter Training Program': 'Applicator Training Program',
    'Other BTL Activity': 'Other Activity',
  };

  // Extra BTL sub-options
  static const _extraBtlOptions = <String>[
    'Tile Applicator Meet',
    'Contractors Meet',
  ];

  bool _mrktNameLocked = false;
  String? _competitionImagePath;
  String? _competitionImageAtchNmId;

  /// Returns the display-ready activity list (renamed + filtered + extras).
  List<DsrOptionItem> get _visibleActivities {
    final seen = <String>{};
    final result = <DsrOptionItem>[];
    for (final a in _activities) {
      if (_hiddenActivities.contains(a.name)) continue;
      final displayName = _activityRenames[a.name] ?? a.name;
      if (seen.contains(displayName)) continue; // dedup merged items
      seen.add(displayName);
      result.add(DsrOptionItem(code: a.code, name: displayName));
    }
    for (final extra in _extraActivities) {
      if (!seen.contains(extra.name)) result.add(extra);
    }
    return result;
  }

  Widget _buildBasicSection() {
    final visibleActs = _visibleActivities;
    final activityNames = visibleActs.map((e) => e.name).toList();
    // Resolve display name for the currently-selected code
    final rawSelected = _activities
        .where((e) => e.code == _selectedDsrParam)
        .firstOrNull;
    final selectedActivityName = rawSelected == null
        ? _extraActivities
              .where((e) => e.code == _selectedDsrParam)
              .firstOrNull
              ?.name
        : (_activityRenames[rawSelected.name] ?? rawSelected.name);

    final documentItems = _documents
        .map((e) => '${e.docuNumb} - ${e.activityName}')
        .toList();

    final selectedDocItem = _documents
        .where((e) => e.docuNumb == _selectedDocuNumb)
        .map((e) => '${e.docuNumb} - ${e.activityName}')
        .firstOrNull;

    return ResponsiveSection(
      title: 'DSR Setup',
      icon: Icons.assignment_outlined,
      subtitle: 'Choose the process, activity, and document context',
      children: [
        _buildDropdown(
          label: 'Process Type',
          value: _procType == 'A'
              ? 'Add'
              : _procType == 'U'
              ? 'Update'
              : 'Delete',
          items: const ['Add', 'Update', 'Delete'],
          onChanged: (v) {
            setState(() {
              _procType = v == 'Update'
                  ? 'U'
                  : v == 'Delete'
                  ? 'D'
                  : 'A';
              _selectedDocuNumb = null;
            });
          },
        ),
        const SizedBox(height: 12),
        if (_procType != 'A')
          _buildDropdown(
            label: 'Document No',
            value: selectedDocItem,
            items: documentItems,
            isRequired: _isDocumentSelectionRequired,
            onChanged: (v) async {
              if (v == null) return;
              final doc = _documents
                  .where((e) => '${e.docuNumb} - ${e.activityName}' == v)
                  .firstOrNull;
              if (doc == null) return;
              await _loadDocumentDetail(doc.docuNumb);
            },
          ),
        if (_procType != 'A') const SizedBox(height: 12),
        _buildText(
          controller: _submissionDateCtrl,
          label: 'Submission Date',
          readOnly: true,
        ),
        const SizedBox(height: 12),
        _buildText(
          controller: _reportDateCtrl,
          label: 'Report Date',
          readOnly: true,
          onTap: _pickReportDate,
        ),
        const SizedBox(height: 12),
        _buildDropdown(
          label: 'Activity Type',
          value: selectedActivityName,
          items: activityNames,
          isRequired: true,
          onChanged: (v) async {
            // Check visible list first (includes extras + renamed)
            final a = _visibleActivities.where((e) => e.name == v).firstOrNull;
            setState(() {
              _selectedDsrParam = a?.code;
              _selectedDocuNumb = null;
              _template = null;
            });
            await _loadTemplate();
          },
        ),
      ],
    );
  }

  bool get _isPersonalVisit {
    final raw = _activities
        .where((e) => e.code == _selectedDsrParam)
        .firstOrNull;
    return raw != null &&
        (raw.name == 'Personal Visit' || raw.name == 'New Visit');
  }

  List<DsrOptionItem> get _partTypeOptions {
    if (_isPersonalVisit) {
      return _partyTypes
          .where((p) => !_hiddenPartyTypeNames.contains(p.name))
          .toList();
    }
    return _partyTypes;
  }

  Widget _buildPartySection() {
    if (_template == null) return const SizedBox.shrink();

    // Filter hidden party types
    final filteredPartyTypes = _partTypeOptions;
    final partyTypeNames = filteredPartyTypes.map((e) => e.name).toList();
    final selectedPartyTypeName = filteredPartyTypes
        .where((e) => e.code == _selectedPartyType)
        .map((e) => e.name)
        .firstOrNull;

    final areaItems = _sanitizeOptions(
      _areas.map((e) => (e.name.isNotEmpty ? e.name : e.code)).toList(),
    );
    final selectedArea = _areas
        .where((e) => e.code == _selectedAreaCode)
        .map((e) => (e.name.isNotEmpty ? e.name : e.code))
        .firstOrNull;
    final emirateItems = _sanitizeOptions(
      _emirates.map((e) => (e.name.isNotEmpty ? e.name : e.code)).toList(),
    );
    final selectedEmirate = _emirates
        .where((e) => e.code == _selectedEmirateCode)
        .map((e) => (e.name.isNotEmpty ? e.name : e.code))
        .firstOrNull;
    final subAreaItems = _sanitizeOptions(
      _subAreasRaw
          .map(
            (m) => ((m['name'] ?? '').toString().isNotEmpty
                ? (m['name'] ?? '').toString()
                : (m['code'] ?? '').toString()),
          )
          .toList(),
    );
    final selectedSubArea = _subAreasRaw
        .where(
          (m) => (m['code'] ?? '').toString() == (_selectedSubAreaCode ?? ''),
        )
        .map(
          (m) => ((m['name'] ?? '').toString().isNotEmpty
              ? (m['name'] ?? '').toString()
              : (m['code'] ?? '').toString()),
        )
        .firstOrNull;

    return ResponsiveSection(
      title: 'Party Details',
      icon: Icons.storefront_outlined,
      subtitle:
          'Search and attach the relevant retailer, dealer, or contractor',
      children: [
        if (_template!.customerSelectionRequired) ...[
          _buildDropdown(
            label: 'Purchaser / Retailer Type',
            value: selectedPartyTypeName,
            items: partyTypeNames,
            isRequired: _isCustomerSelectionRequired,
            onChanged: (v) {
              final item = filteredPartyTypes
                  .where((e) => e.name == v)
                  .firstOrNull;
              setState(() {
                _selectedPartyType = item?.code;
                _selectedParty = null;
                _partySearchCtrl.clear();
              });
            },
          ),
          const SizedBox(height: 12),
          // Emirate selection (drives areas list)
          if (_emirates.isNotEmpty) ...[
            _buildDropdown(
              label: 'Emirate',
              value: selectedEmirate,
              items: emirateItems,
              onChanged: (v) async {
                final item = _emirates
                    .where((e) => e.name == v || e.code == v)
                    .firstOrNull;
                setState(() {
                  _selectedEmirateCode = item?.code;
                  _selectedAreaCode = null;
                  _selectedSubAreaCode = null;
                  _selectedSubAreaName = null;
                });
                if (item != null) await _fetchAreasForEmirate(item.code);
              },
            ),
            const SizedBox(height: 12),
          ],
          _buildDropdown(
            label: 'Area Code',
            value: selectedArea,
            items: areaItems,
            isRequired: _isCustomerSelectionRequired,
            onChanged: (v) {
              final item = _areas
                  .where((e) => e.name == v || e.code == v)
                  .firstOrNull;
              setState(() {
                _selectedAreaCode = item?.code;
                _selectedSubAreaCode = null;
                _selectedSubAreaName = null;
              });
              if (item != null) _fetchSubAreasForArea(item.code);
            },
          ),
          const SizedBox(height: 12),
          if (_hasSubAreas) ...[
            _buildDropdown(
              label: 'Sub Area',
              value: selectedSubArea,
              items: subAreaItems,
              onChanged: (v) {
                final selName = (v ?? '').toString();
                final sel = _subAreasRaw
                    .where(
                      (m) =>
                          (m['name'] ?? '').toString() == selName ||
                          (m['code'] ?? '').toString() == selName,
                    )
                    .firstOrNull;
                setState(() {
                  _selectedSubAreaCode = sel?['code']?.toString();
                  _selectedSubAreaName = sel?['name']?.toString();
                });
                final po = sel == null ? '' : (sel['pobox'] ?? '');
                if (po != null && po.toString().isNotEmpty) {
                  _ctrl['pinCodeN']!.text = po.toString();
                }
              },
            ),
            const SizedBox(height: 12),
          ],
          const SizedBox(height: 12),
          TextFormField(
            controller: _partySearchCtrl,
            decoration: InputDecoration(
              labelText: _isCustomerSelectionRequired ? 'Code *' : 'Code',
              hintText: 'Enter party code',
              border: const OutlineInputBorder(),
              suffixIcon: IconButton(
                icon: const Icon(Icons.search),
                onPressed: _searchParty,
              ),
            ),
          ),
          const SizedBox(height: 12),
          // Moved Pin Code to Party Details (district and city removed)
          if (_shouldShowManualPinField('pinCodeN'))
            _buildText(
              controller: _ctrl['pinCodeN']!,
              label: 'Pin Code',
              isRequired: _isPinSectionRequired,
              keyboardType: TextInputType.number,
            ),
          if (_selectedParty != null) ...[
            const SizedBox(height: 12),
            ListTile(
              tileColor: Colors.blue.shade50,
              title: Text(_selectedParty!.name),
              subtitle: Text(_selectedParty!.code),
            ),
          ],
          // Current / Actual Location
          if (_ctrl['geoLatit']!.text.isNotEmpty ||
              _ctrl['geoLongt']!.text.isNotEmpty) ...[
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              decoration: BoxDecoration(
                color: Colors.teal.shade50,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: Colors.teal.shade200),
              ),
              child: Row(
                children: [
                  const Icon(
                    Icons.location_on_outlined,
                    color: Colors.teal,
                    size: 18,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Current Location  Lat: ${_ctrl['geoLatit']!.text}  |  Long: ${_ctrl['geoLongt']!.text}',
                      style: const TextStyle(fontSize: 13, color: Colors.teal),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ],
    );
  }

  Widget _buildPinLocationSection() {
    if (!_showsManualPinSection) {
      return const SizedBox.shrink();
    }

    return ResponsiveSection(
      title: 'Address Details',
      icon: Icons.location_city_outlined,
      subtitle:
          'Enter the pin code, district, and city needed for this activity.',
      children: [
        if (_shouldShowManualPinField('pinCodeN') ||
            _shouldShowManualPinField('district'))
          ResponsiveRow(
            children: [
              if (_shouldShowManualPinField('pinCodeN'))
                _buildText(
                  controller: _ctrl['pinCodeN']!,
                  label: 'Pin Code',
                  isRequired: true,
                  keyboardType: TextInputType.number,
                ),
              if (_shouldShowManualPinField('district'))
                _buildText(
                  controller: _ctrl['district']!,
                  label: 'District',
                  isRequired: true,
                ),
            ],
          ),
        if ((_shouldShowManualPinField('pinCodeN') ||
                _shouldShowManualPinField('district')) &&
            _shouldShowManualPinField('cityName'))
          const SizedBox(height: 12),
        if (_shouldShowManualPinField('cityName'))
          _buildText(
            controller: _ctrl['cityName']!,
            label: 'City',
            isRequired: true,
          ),
      ],
    );
  }

  /// Returns display-ready options for a BTL-type field by applying renames
  /// and injecting extra options.
  List<DsrOptionItem> _btlOptions(List<DsrOptionItem> raw) {
    final result = <DsrOptionItem>[];
    for (final o in raw) {
      final rename = _btlSubRenames[o.name];
      if (rename == null) {
        result.add(o); // unchanged
      } else if (rename.isNotEmpty) {
        result.add(DsrOptionItem(code: o.code, name: rename));
      }
      // empty rename → skip (hidden)
    }
    // Add extra options only if they don't already exist
    final existing = result.map((e) => e.name).toSet();
    for (final name in _extraBtlOptions) {
      if (!existing.contains(name)) {
        result.add(
          DsrOptionItem(
            code: name.toUpperCase().replaceAll(' ', '_'),
            name: name,
          ),
        );
      }
    }
    return result;
  }

  /// True when the template's activity is BTL/Promotional Meetings
  bool get _isBtlActivity {
    final raw = _activities
        .where((e) => e.code == _selectedDsrParam)
        .firstOrNull;
    return raw != null &&
        (raw.name == 'BTL Activity' || raw.name == 'Promotional Meetings');
  }

  Widget _buildDynamicFields() {
    if (_template == null) return const SizedBox.shrink();

    // Filter out any field labelled 'Display Contest'
    final fields = _template!.fields
        .where((f) => !f.label.toLowerCase().contains('display contest'))
        .toList();

    return ResponsiveSection(
      title: 'Activity Details',
      icon: Icons.edit_note_outlined,
      subtitle: 'Fill the activity-specific remarks and selections',
      children: fields.map((field) {
        final controller = _ctrl[field.key]!;
        if (field.type == 'select') {
          // Apply BTL sub-option transforms when applicable
          final options = _isBtlActivity
              ? _btlOptions(field.options)
              : field.options;
          // Remove 'Participation of Display Contest' from options
          final filteredOptions = options
              .where((o) => !o.name.toLowerCase().contains('display contest'))
              .toList();
          final optionNames = filteredOptions
              .map((e) => e.name)
              .toSet()
              .toList();
          final selectedName = filteredOptions
              .where((e) => e.code == controller.text)
              .map((e) => e.name)
              .firstOrNull;

          return Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: _buildDropdown(
              label: field.label,
              value: selectedName,
              items: optionNames,
              isRequired: _isDynamicFieldRequired(field),
              onChanged: (v) {
                final item = filteredOptions
                    .where((e) => e.name == v)
                    .firstOrNull;
                setState(() => controller.text = item?.code ?? '');
              },
            ),
          );
        }

        // Market Name field: read-only once locked
        final isMarketName = field.key == 'mrktName';
        return Padding(
          padding: const EdgeInsets.only(bottom: 12),
          child: _buildText(
            controller: controller,
            label: field.label,
            maxLines: field.type == 'textarea' ? 3 : 1,
            isRequired: _isDynamicFieldRequired(field),
            readOnly: field.type == 'date' || (isMarketName && _mrktNameLocked),
            onTap: field.type == 'date'
                ? () => _pickGenericDate(controller)
                : null,
          ),
        );
      }).toList(),
    );
  }

  Widget _buildClassicRowsSection() {
    if (_template?.isClassic != true) return const SizedBox.shrink();
    if (!(_template?.productGridRequired == true ||
        _template?.actionGridRequired == true)) {
      return const SizedBox.shrink();
    }

    return ResponsiveSection(
      title: _requiresClassicDetailRows ? 'Detail Rows *' : 'Detail Rows',
      icon: Icons.view_list_outlined,
      subtitle: _requiresClassicDetailRows
          ? 'Capture product quantities, actions, and target dates. At least one row is required.'
          : 'Capture product quantities, actions, and target dates',
      children: [
        ...List.generate(_classicRows.length, (index) {
          final row = _classicRows[index];
          final productNames = _products.map((e) => e.name).toList();
          final selectedProductName = _products
              .where((e) => e.code == row.repoCatg)
              .map((e) => e.name)
              .firstOrNull;
          final skuItems = _skuCache[row.repoCatg] ?? [];
          final skuNames = skuItems.map(_skuDisplayLabel).toList();
          final selectedSkuName = skuItems
              .where((e) => e.code == row.catgPack)
              .map(_skuDisplayLabel)
              .firstOrNull;

          return Container(
            margin: const EdgeInsets.only(bottom: 12),
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              border: Border.all(color: Colors.grey.shade300),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Column(
              children: [
                Row(
                  children: [
                    Expanded(child: Text('Row ${index + 1}')),
                    if (_classicRows.length > 1)
                      IconButton(
                        onPressed: () =>
                            setState(() => _classicRows.removeAt(index)),
                        icon: const Icon(Icons.delete),
                      ),
                  ],
                ),
                _buildDropdown(
                  label: 'Product',
                  value: selectedProductName,
                  items: productNames,
                  isRequired: _template?.productGridRequired == true,
                  onChanged: (v) async {
                    final item = _products
                        .where((e) => e.name == v)
                        .firstOrNull;
                    row.repoCatg = item?.code ?? '';
                    row.catgPack = '';
                    await _ensureSkusLoaded(row.repoCatg);
                    setState(() {});
                  },
                ),
                const SizedBox(height: 8),
                if (skuItems.isNotEmpty)
                  _buildDropdown(
                    label: 'Pack / SKU',
                    value: selectedSkuName,
                    items: skuNames,
                    onChanged: (v) {
                      final sku = skuItems
                          .where((e) => _skuDisplayLabel(e) == v)
                          .firstOrNull;
                      setState(() => row.catgPack = sku?.code ?? '');
                    },
                  )
                else
                  _inlineInitialField(
                    label: 'Pack / SKU',
                    initial: row.catgPack,
                    onChanged: (v) => row.catgPack = v,
                  ),
                const SizedBox(height: 8),
                _inlineInitialField(
                  label: 'New Order Qty',
                  initial: row.prodQnty,
                  isRequired: _template?.productGridRequired == true,
                  onChanged: (v) => row.prodQnty = v,
                ),
                if (_template?.projectQtyRequired == true) ...[
                  const SizedBox(height: 8),
                  _inlineInitialField(
                    label: 'Projection Qty',
                    initial: row.projQnty,
                    isRequired: true,
                    onChanged: (v) => row.projQnty = v,
                  ),
                ],
                const SizedBox(height: 8),
                _inlineInitialField(
                  label: 'Action Remark',
                  initial: row.actnRemk,
                  maxLines: 2,
                  isRequired: _template?.actionGridRequired == true,
                  onChanged: (v) => row.actnRemk = v,
                ),
                const SizedBox(height: 8),
                _buildText(
                  controller: TextEditingController(text: row.targetDt),
                  label: 'Target Date (dd/MM/yyyy)',
                  readOnly: true,
                  onTap: () async {
                    final now = DateTime.now();
                    DateTime initial = now;
                    try {
                      if (row.targetDt.isNotEmpty) {
                        initial = DateFormat(
                          'dd/MM/yyyy',
                        ).parseStrict(row.targetDt);
                      }
                    } catch (_) {}
                    final selected = await showDatePicker(
                      context: context,
                      initialDate: initial,
                      firstDate: now.subtract(const Duration(days: 365)),
                      lastDate: now.add(const Duration(days: 365)),
                    );
                    if (selected != null) {
                      setState(
                        () => row.targetDt = DateFormat(
                          'dd/MM/yyyy',
                        ).format(selected),
                      );
                    }
                  },
                ),
              ],
            ),
          );
        }),
        ElevatedButton(
          onPressed: () => setState(() => _classicRows.add(DsrClassicRow())),
          child: const Text('Add Row'),
        ),
      ],
    );
  }

  Widget _buildNewVisitMetricsSection() {
    if (_template == null) return const SizedBox.shrink();
    if (_template!.isNewVisit != true &&
        _template!.showStockAvailabilitySection != true &&
        _template!.showCompetitorAvgSection != true) {
      return const SizedBox.shrink();
    }

    return ResponsiveSection(
      title: 'Market Metrics',
      icon: Icons.analytics_outlined,
      subtitle:
          'Track white cement availability, BW stock, and average movement',
      children: [
        if (!_isPersonalVisit) ...[
          // ── White Cement Availability Slab ────────────────────────────────
          const Align(
            alignment: Alignment.centerLeft,
            child: Text(
              'White Cement Availability Slab',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
            ),
          ),
          const SizedBox(height: 8),
          _wcBrandRow('RAK White', _ctrl['wcRakQty']!),
          _wcBrandRow('JK White', _ctrl['wcJkQty']!),
          _wcBrandRow('NCF White', _ctrl['wcNcfQty']!),
          // Iranian White: name box + qty
          Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: Row(
              children: [
                const SizedBox(
                  width: 120,
                  child: Text('Iranian White', style: TextStyle(fontSize: 13)),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: _buildText(
                    controller: _ctrl['wcIranName']!,
                    label: 'Brand Name',
                  ),
                ),
                const SizedBox(width: 8),
                SizedBox(
                  width: 96,
                  child: _buildText(
                    controller: _ctrl['wcIranQty']!,
                    label: 'Qty (MT)',
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          // ── BW Stock Availability ─────────────────────────────────────────
          const Align(
            alignment: Alignment.centerLeft,
            child: Text(
              'Birla White Product Availability',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
            ),
          ),
          const SizedBox(height: 8),
          const Align(
            alignment: Alignment.centerLeft,
            child: Text(
              'Birla White Wall Care Putty',
              style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
            ),
          ),
          const SizedBox(height: 6),
          ResponsiveRow(
            children: [
              _buildText(controller: _ctrl['bwWcp5kg']!, label: '5 KG'),
              _buildText(controller: _ctrl['bwWcp20kg']!, label: '20 KG'),
            ],
          ),
          const SizedBox(height: 8),
          const Align(
            alignment: Alignment.centerLeft,
            child: Text(
              'Tile Adhesive (20 KG)',
              style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
            ),
          ),
          const SizedBox(height: 6),
          ResponsiveRow(
            children: [
              _buildText(controller: _ctrl['bwTaGp']!, label: '20 KG - GP'),
              _buildText(controller: _ctrl['bwTaTx1']!, label: '20 KG - TX1'),
            ],
          ),
          const SizedBox(height: 6),
          ResponsiveRow(
            children: [
              _buildText(controller: _ctrl['bwTaTx2']!, label: '20 KG - TX2'),
              _buildText(controller: _ctrl['bwTaTx3']!, label: '20 KG - TX3'),
            ],
          ),
          const SizedBox(height: 16),
        ],
        // ── Last Bill Date ────────────────────────────────────────────────
        const Align(
          alignment: Alignment.centerLeft,
          child: Text(
            'Last Bill Date',
            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
          ),
        ),
        const SizedBox(height: 8),
        _buildText(
          controller: _ctrl['lastBillDate']!,
          label: 'Last Bill Date (dd/MM/yyyy)',
          readOnly: true,
          onTap: _pickLastBillDate,
        ),
        const SizedBox(height: 16),
        // ── Last 3 Months Average Sale ────────────────────────────────────
        const Align(
          alignment: Alignment.centerLeft,
          child: Text(
            'Last 3 Months Average Sale (Product Wise)',
            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
          ),
        ),
        const SizedBox(height: 12),
        _avgRow('JK', _ctrl['jkAvgWcc']!, _ctrl['jkAvgWcp']!),
        _avgRow('Asian', _ctrl['asAvgWcc']!, _ctrl['asAvgWcp']!),
        _avgRow('Other', _ctrl['otAvgWcc']!, _ctrl['otAvgWcp']!),
      ],
    );
  }

  Widget _wcBrandRow(String brand, TextEditingController qtyCtrl) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        children: [
          SizedBox(
            width: 120,
            child: Text(brand, style: const TextStyle(fontSize: 13)),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: _buildText(controller: qtyCtrl, label: 'Qty (MT)'),
          ),
        ],
      ),
    );
  }

  Widget _avgRow(
    String title,
    TextEditingController wc,
    TextEditingController wcp,
  ) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: ResponsiveRow(
        children: [
          Container(
            alignment: Alignment.centerLeft,
            padding: const EdgeInsets.only(top: 14),
            child: Text(title),
          ),
          _buildText(controller: wc, label: 'WC'),
          _buildText(controller: wcp, label: 'WCP'),
        ],
      ),
    );
  }

  Future<void> _pickLastBillDate() async {
    final now = DateTime.now();
    DateTime initial = now;
    try {
      initial = DateFormat(
        'dd/MM/yyyy',
      ).parseStrict(_ctrl['lastBillDate']!.text);
    } catch (_) {}
    final selected = await showDatePicker(
      context: context,
      initialDate: initial,
      firstDate: now.subtract(const Duration(days: 730)),
      lastDate: now,
    );
    if (selected != null) {
      _ctrl['lastBillDate']!.text = DateFormat('dd/MM/yyyy').format(selected);
      setState(() {});
    }
  }

  Widget _buildNewVisitOrderSection() {
    if (_template?.showOrderBookedSection != true)
      return const SizedBox.shrink();

    return ResponsiveSection(
      title: _requiresOrderRows ? 'Order Booking *' : 'Order Booking',
      icon: Icons.shopping_cart_outlined,
      subtitle: _requiresOrderRows
          ? 'Add products, SKUs, and booked quantities for the visit. At least one row is required.'
          : 'Add products, SKUs, and booked quantities for the visit',
      children: [
        ...List.generate(_orderRows.length, (index) {
          final row = _orderRows[index];
          final productNames = _products.map((e) => e.name).toList();
          final selectedProductName = _products
              .where((e) => e.code == row.repoCatg)
              .map((e) => e.name)
              .firstOrNull;

          final skuItems = _skuCache[row.repoCatg] ?? [];
          final skuNames = skuItems.map(_skuDisplayLabel).toList();
          final selectedSku = skuItems
              .where((e) => e.code == row.catgPack)
              .map(_skuDisplayLabel)
              .firstOrNull;

          return Container(
            margin: const EdgeInsets.only(bottom: 12),
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              border: Border.all(color: Colors.grey.shade300),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Column(
              children: [
                Row(
                  children: [
                    Expanded(child: Text('Order Row ${index + 1}')),
                    if (_orderRows.length > 1)
                      IconButton(
                        onPressed: () =>
                            setState(() => _orderRows.removeAt(index)),
                        icon: const Icon(Icons.delete),
                      ),
                  ],
                ),
                _buildDropdown(
                  label: 'Product',
                  value: selectedProductName,
                  items: productNames,
                  isRequired: _requiresOrderRows,
                  onChanged: (v) async {
                    final item = _products
                        .where((e) => e.name == v)
                        .firstOrNull;
                    row.repoCatg = item?.code ?? '';
                    row.catgPack = '';
                    await _ensureSkusLoaded(row.repoCatg);
                    setState(() {});
                  },
                ),
                const SizedBox(height: 8),
                _buildDropdown(
                  label: 'Product SKU',
                  value: selectedSku,
                  items: skuNames,
                  isRequired: _requiresOrderRows,
                  onChanged: (v) {
                    final sku = skuItems
                        .where((e) => _skuDisplayLabel(e) == v)
                        .firstOrNull;
                    if (sku != null) {
                      row.catgPack = sku.code;
                      if (sku.bagsPerTon > 0) {
                        final bags = double.tryParse(row.prodQnty) ?? 0;
                        row.projQnty = (bags / sku.bagsPerTon).toStringAsFixed(
                          2,
                        );
                      } else {
                        row.projQnty = '0.00';
                      }
                    } else {
                      row.catgPack = '';
                    }
                    setState(() {});
                  },
                ),
                const SizedBox(height: 8),
                _inlineInitialField(
                  label: 'Qty in Bags',
                  initial: row.prodQnty,
                  isRequired: _requiresOrderRows,
                  onChanged: (v) {
                    row.prodQnty = v;
                    final sku = skuItems
                        .where((e) => e.code == row.catgPack)
                        .firstOrNull;
                    if (sku != null && sku.bagsPerTon > 0) {
                      final bags = double.tryParse(v) ?? 0;
                      row.projQnty = (bags / sku.bagsPerTon).toStringAsFixed(2);
                    }
                    setState(() {});
                  },
                ),
                const SizedBox(height: 8),
                _buildText(
                  controller: TextEditingController(text: row.projQnty),
                  label: 'Qty in MT',
                  readOnly: true,
                ),
              ],
            ),
          );
        }),
        ElevatedButton(
          onPressed: () =>
              setState(() => _orderRows.add(DsrNewVisitOrderRow())),
          child: const Text('Add Order Row'),
        ),
      ],
    );
  }

  Widget _buildMarketPriceSection() {
    if (_template?.showMarketPriceSection != true)
      return const SizedBox.shrink();

    const brands = <String, String>{
      'BW': 'Birla White',
      'JK': 'JK',
      'AP': 'Asian Paint',
      'BG': 'Berger',
      'Ot': 'Other',
    };

    return ResponsiveSection(
      title: 'Market Price Mapping',
      icon: Icons.price_change_outlined,
      subtitle: 'Record highest-selling SKU and pricing by brand',
      children: [
        ...List.generate(_marketPriceRows.length, (index) {
          final row = _marketPriceRows[index];

          return Container(
            margin: const EdgeInsets.only(bottom: 12),
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              border: Border.all(color: Colors.grey.shade300),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Column(
              children: [
                Row(
                  children: [
                    Expanded(child: Text('Price Row ${index + 1}')),
                    if (_marketPriceRows.length > 1)
                      IconButton(
                        onPressed: () =>
                            setState(() => _marketPriceRows.removeAt(index)),
                        icon: const Icon(Icons.delete),
                      ),
                  ],
                ),
                _buildDropdown(
                  label: 'Brand',
                  value: brands[row.brandCode],
                  items: brands.values.toList(),
                  onChanged: (v) {
                    final code = brands.entries
                        .where((e) => e.value == v)
                        .map((e) => e.key)
                        .firstOrNull;
                    setState(() => row.brandCode = code ?? '');
                  },
                ),
                const SizedBox(height: 8),
                _inlineInitialField(
                  label: 'SKU Code',
                  initial: row.skuCode,
                  onChanged: (v) => row.skuCode = v,
                ),
                const SizedBox(height: 8),
                _inlineInitialField(
                  label: 'Price B',
                  initial: row.bPrice,
                  onChanged: (v) => row.bPrice = v,
                ),
                const SizedBox(height: 8),
                _inlineInitialField(
                  label: 'Price C',
                  initial: row.cPrice,
                  onChanged: (v) => row.cPrice = v,
                ),
              ],
            ),
          );
        }),
        ElevatedButton(
          onPressed: () =>
              setState(() => _marketPriceRows.add(DsrMarketPriceRow())),
          child: const Text('Add Market Price Row'),
        ),
      ],
    );
  }

  Widget _buildGiftSection() {
    if (_template?.showGiftSection != true) return const SizedBox.shrink();

    final giftNames = _giftTypes.map((e) => e.name).toList();

    return ResponsiveSection(
      title: 'Gift Distribution',
      icon: Icons.card_giftcard_outlined,
      subtitle: 'Capture gift items and issued quantity',
      children: [
        ...List.generate(_giftRows.length, (index) {
          final row = _giftRows[index];
          final selectedName = _giftTypes
              .where((e) => e.code == row.mrtlCode)
              .map((e) => e.name)
              .firstOrNull;

          return Container(
            margin: const EdgeInsets.only(bottom: 12),
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              border: Border.all(color: Colors.grey.shade300),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Column(
              children: [
                Row(
                  children: [
                    Expanded(child: Text('Gift Row ${index + 1}')),
                    if (_giftRows.length > 1)
                      IconButton(
                        onPressed: () =>
                            setState(() => _giftRows.removeAt(index)),
                        icon: const Icon(Icons.delete),
                      ),
                  ],
                ),
                _buildDropdown(
                  label: 'Gift Type',
                  value: selectedName,
                  items: giftNames,
                  onChanged: (v) {
                    final item = _giftTypes
                        .where((e) => e.name == v)
                        .firstOrNull;
                    setState(() => row.mrtlCode = item?.code ?? '');
                  },
                ),
                const SizedBox(height: 8),
                _inlineInitialField(
                  label: 'Quantity',
                  initial: row.isueQnty,
                  onChanged: (v) => row.isueQnty = v,
                ),
              ],
            ),
          );
        }),
        ElevatedButton(
          onPressed: () => setState(() => _giftRows.add(DsrGiftRow())),
          child: const Text('Add Gift Row'),
        ),
      ],
    );
  }

  Widget _buildCompetitionActivitySection() {
    if (_template == null) return const SizedBox.shrink();
    if (_template!.isNewVisit != true &&
        _template!.showStockAvailabilitySection != true &&
        _template!.showCompetitorAvgSection != true) {
      return const SizedBox.shrink();
    }
    return ResponsiveSection(
      title: 'Competition Activity',
      icon: Icons.emoji_events_outlined,
      subtitle: 'Record competitor activities observed during the visit',
      children: [
        FileUploadWidget(
          label: 'Upload Competition Image',
          icon: Icons.camera_alt_outlined,
          isRequired: false,
          allowedExtensions: const ['jpg', 'jpeg', 'png'],
          currentFilePath: _competitionImagePath,
          onFileSelected: (path) => setState(() {
            _competitionImagePath = path;
            _competitionImageAtchNmId = null;
          }),
        ),
        const SizedBox(height: 12),
        TextFormField(
          controller: _ctrl['competitionDesc']!,
          maxLines: 4,
          decoration: InputDecoration(
            labelText: 'Brief Description',
            hintText: 'Describe the competitor activity observed…',
            filled: true,
            fillColor: Colors.grey[50],
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: Colors.grey[300]!),
            ),
            focusedBorder: const OutlineInputBorder(
              borderRadius: BorderRadius.all(Radius.circular(12)),
              borderSide: BorderSide(color: Color(0xFF3B82F6), width: 2),
            ),
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 16,
              vertical: 16,
            ),
          ),
        ),
      ],
    );
  }

  LocalDsrAttachment? get _primaryAttachment =>
      _attachments.isEmpty ? null : _attachments.first;

  String? get _selectedAttachmentTypeCode {
    final code = (_selectedAttachmentType ?? _primaryAttachment?.attFilTy ?? '')
        .trim();
    if (code.isNotEmpty) return code;
    return _documentTypes.firstOrNull?.code;
  }

  String? get _selectedAttachmentPath {
    final path = _primaryAttachment?.filePath ?? '';
    return path.isEmpty ? null : path;
  }

  void _setPrimaryAttachment({String? filePath, String? attFilTy}) {
    final existing = _primaryAttachment;
    final nextType =
        (attFilTy ??
                _selectedAttachmentType ??
                existing?.attFilTy ??
                _documentTypes.firstOrNull?.code ??
                '')
            .trim();
    final nextPath = (filePath ?? existing?.filePath ?? '').trim();
    _selectedAttachmentType = nextType.isEmpty ? null : nextType;

    if (nextPath.isEmpty) {
      _attachments = [];
      return;
    }

    final nextUploadKey = nextPath == existing?.filePath
        ? (existing?.tempDocuNumb ?? nextPath).trim()
        : nextPath;

    _attachments = [
      LocalDsrAttachment(
        attFilTy: nextType,
        filePath: nextPath,
        tempDocuNumb: nextUploadKey,
      ),
    ];
  }

  Widget _buildSupportingDocumentSection() {
    return ResponsiveSection(
      title: 'Upload Supporting Document',
      icon: Icons.upload_file_outlined,
      subtitle: 'Use the same document upload flow as retailer registration',
      children: [
        FileUploadWidget(
          label: 'Supporting Document',
          icon: Icons.attach_file_rounded,
          isRequired: false,
          allowedExtensions: const ['jpg', 'jpeg', 'png', 'pdf'],
          currentFilePath: _selectedAttachmentPath,
          onFileSelected: (path) {
            setState(() {
              _setPrimaryAttachment(filePath: path);
            });
          },
        ),
      ],
    );
  }

  Widget _inlineInitialField({
    required String label,
    required String initial,
    required ValueChanged<String> onChanged,
    int maxLines = 1,
    bool isRequired = false,
  }) {
    return TextFormField(
      initialValue: initial,
      maxLines: maxLines,
      onChanged: onChanged,
      decoration: InputDecoration(
        labelText: isRequired ? '$label *' : label,
        filled: true,
        fillColor: Colors.grey[50],
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Colors.grey[300]!),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Colors.grey[300]!),
        ),
        focusedBorder: const OutlineInputBorder(
          borderRadius: BorderRadius.all(Radius.circular(12)),
          borderSide: BorderSide(color: Color(0xFF3B82F6), width: 2),
        ),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 16,
        ),
      ),
    );
  }

  Widget _buildHeaderInfo() {
    final activityName = _activities
        .where((e) => e.code == _selectedDsrParam)
        .map((e) => e.name)
        .firstOrNull;

    return ResponsiveInfoCard(
      title: activityName == null || activityName.isEmpty
          ? 'Set up your daily sales report'
          : 'Working on $activityName',
      subtitle:
          'Login ID: ${widget.loginId}  |  Department: ${_deptCode}  |  Area: ${_effectiveAreaCode.isEmpty ? 'N/A' : _effectiveAreaCode}  |  Mode: ${_procType == 'A'
              ? 'Add'
              : _procType == 'U'
              ? 'Update'
              : 'Delete'}',
      icon: Icons.fact_check_outlined,
      color: const Color(0xFF1E3A8A),
      backgroundColor: const Color(0xFFEFF6FF),
      iconColor: const Color(0xFF1E3A8A),
    );
  }

  String _getStepTitle() {
    switch (_currentStep) {
      case 1:
        return 'DSR Setup';
      case 2:
        return 'Basic Details';
      case 3:
        return 'Supporting Document';
      default:
        return 'DSR Setup';
    }
  }

  Widget _buildProgressLine(bool isActive) {
    return Expanded(
      child: Container(
        height: 3,
        margin: EdgeInsets.symmetric(horizontal: 8.w),
        decoration: BoxDecoration(
          color: isActive ? const Color(0xFF3B82F6) : Colors.grey.shade300,
          borderRadius: BorderRadius.circular(2),
        ),
      ),
    );
  }

  Widget _buildProgressStep(int step, String label, bool isActive) {
    return Column(
      children: [
        AnimatedContainer(
          duration: const Duration(milliseconds: 250),
          width: 36.w,
          height: 36.h,
          decoration: BoxDecoration(
            color: isActive ? const Color(0xFF1E3A8A) : Colors.white,
            shape: BoxShape.circle,
            border: Border.all(
              color: isActive ? const Color(0xFF1E3A8A) : Colors.grey.shade300,
              width: 2,
            ),
          ),
          child: Center(
            child: Text(
              '$step',
              style: TextStyle(
                color: isActive ? Colors.white : Colors.grey.shade600,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ),
        SizedBox(height: 8.h),
        Text(
          label,
          style: TextStyle(
            fontSize: 12.sp,
            fontWeight: FontWeight.w600,
            color: isActive ? const Color(0xFF1E3A8A) : Colors.grey.shade600,
          ),
        ),
      ],
    );
  }

  Widget _buildProgressIndicator() {
    return ResponsiveSection(
      title: 'Progress',
      icon: Icons.timeline_outlined,
      subtitle: 'Step $_currentStep of 3: ${_getStepTitle()}',
      children: [
        Row(
          children: [
            _buildProgressStep(1, 'Setup', _currentStep >= 1),
            _buildProgressLine(_currentStep >= 2),
            _buildProgressStep(2, 'Details', _currentStep >= 2),
            _buildProgressLine(_currentStep >= 3),
            _buildProgressStep(3, 'Document', _currentStep >= 3),
          ],
        ),
      ],
    );
  }

  Widget _buildCurrentStepContent() {
    switch (_currentStep) {
      case 1:
        return _buildBasicSection();
      case 2:
        return Column(
          children: [
            _buildPartySection(),
            SizedBox(height: 16.h),
            _buildDynamicFields(),
            SizedBox(height: 16.h),
            _buildClassicRowsSection(),
            SizedBox(height: 16.h),
            _buildNewVisitMetricsSection(),
            SizedBox(height: 16.h),
            _buildNewVisitOrderSection(),
            SizedBox(height: 16.h),
            _buildMarketPriceSection(),
            SizedBox(height: 16.h),
            _buildGiftSection(),
            SizedBox(height: 16.h),
            _buildCompetitionActivitySection(),
          ],
        );
      case 3:
        return _buildSupportingDocumentSection();
      default:
        return _buildBasicSection();
    }
  }

  Widget _buildNavigationButtons() {
    return Row(
      children: [
        ElevatedButton(
          onPressed: _loading ? null : _resetForm,
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.white,
            foregroundColor: const Color(0xFF1E3A8A),
            elevation: 0,
            side: const BorderSide(color: Color(0xFF1E3A8A), width: 1.5),
            padding: EdgeInsets.symmetric(vertical: 16.h, horizontal: 18.w),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12.r),
            ),
          ),
          child: const Text('Reset'),
        ),
        if (_currentStep > 1) SizedBox(width: 12.w),
        if (_currentStep > 1)
          Expanded(
            child: OutlinedButton(
              onPressed: _loading
                  ? null
                  : () {
                      setState(() => _currentStep--);
                      _scrollController.animateTo(
                        0,
                        duration: const Duration(milliseconds: 300),
                        curve: Curves.easeOut,
                      );
                    },
              style: OutlinedButton.styleFrom(
                foregroundColor: const Color(0xFF1E3A8A),
                side: const BorderSide(color: Color(0xFF1E3A8A), width: 1.5),
                padding: EdgeInsets.symmetric(vertical: 16.h),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12.r),
                ),
              ),
              child: const Text('Previous'),
            ),
          ),
        SizedBox(width: 12.w),
        Expanded(
          child: ElevatedButton(
            onPressed: _loading
                ? null
                : () {
                    if (_currentStep < 3) {
                      if (_validateStep(_currentStep)) {
                        setState(() => _currentStep++);
                        _scrollController.animateTo(
                          0,
                          duration: const Duration(milliseconds: 300),
                          curve: Curves.easeOut,
                        );
                      }
                    } else {
                      _submit('E');
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
            child: _loading && _currentStep == 3
                ? const SizedBox(
                    height: 20,
                    width: 20,
                    child: CircularProgressIndicator(
                      color: Colors.white,
                      strokeWidth: 2,
                    ),
                  )
                : Text(
                    _currentStep < 3 ? 'Next' : 'Submit DSR',
                    style: TextStyle(
                      fontSize: 16.sp,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      body: _loading && _activities.isEmpty
          ? const Center(child: CircularProgressIndicator())
          : CustomScrollView(
              controller: _scrollController,
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
                            onPressed: () => context.pop(),
                          ),
                        )
                      : null,
                  flexibleSpace: FlexibleSpaceBar(
                    title: Text(
                      'DSR Entry',
                      style: TextStyle(
                        fontSize: 16.sp,
                        fontWeight: FontWeight.w600,
                        color: Colors.white,
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
                          right: 24.w,
                          top: 64.h,
                          child: Icon(
                            Icons.description_outlined,
                            size: 96.sp,
                            color: Colors.white.withOpacity(0.18),
                          ),
                        ),
                      ],
                    ),
                  ),
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
                              _buildHeaderInfo(),
                              SizedBox(height: 16.h),
                              _buildProgressIndicator(),
                              SizedBox(height: 16.h),
                              _buildCurrentStepContent(),
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
    );
  }
}

extension<T> on Iterable<T> {
  T? get firstOrNull {
    final it = iterator;
    if (it.moveNext()) return it.current;
    return null;
  }
}
