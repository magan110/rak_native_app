import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:go_router/go_router.dart';
import 'package:geolocator/geolocator.dart';

import '../../../../../shared/widgets/custom_back_button.dart';
import '../../../../../shared/widgets/file_upload_widget.dart';
import '../../../../../shared/widgets/modern_dropdown.dart';
import '../../../../../shared/widgets/responsive_widgets.dart';

import '../../../../../core/models/retailer_registration_models.dart';
import '../../../../../core/services/bank_details_ocr_service.dart';
import '../../../../../core/services/emirates_id_ocr_service.dart';
import '../../../../../core/services/hybrid_ocr_service.dart';
import '../../../../../core/services/retailer_registration_service.dart';
import '../../../../../core/services/image_upload_service.dart';
import '../../../../../core/services/auth_service.dart';
import 'package:rak_app/core/services/location_service.dart';
import 'package:rak_app/core/utils/snackbar_utils.dart';

class RetailerRegistrationScreen extends StatefulWidget {
  const RetailerRegistrationScreen({super.key});

  @override
  State<RetailerRegistrationScreen> createState() =>
      _RetailerRegistrationScreenState();
}

class _RetailerRegistrationScreenState extends State<RetailerRegistrationScreen>
    with TickerProviderStateMixin {
  late AnimationController _mainController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;
  late Animation<double> _scaleAnimation;

  final ScrollController _scrollController = ScrollController();

  bool _isSubmitting = false;
  bool _isGettingLocation = false;
  bool _isLoadingDetails = false;
  bool _isProcessingBankOcr = false;
  bool _isProcessingEmiratesIdOcr = false;
  int _currentStep = 1;

  // --- Step 1: Business Identity & Tax ---
  String? _processType = 'Add';
  final retailerCodeController = TextEditingController();
  final firmNameController = TextEditingController();
  final contNameController = TextEditingController();
  final trnNumberController = TextEditingController();
  final tradeLicenceController = TextEditingController();
  String? _counterType;
  final businessDetailsController = TextEditingController();
  final emiratesIdController = TextEditingController();
  String? _emiratesIdImage;
  String? _trnDocumentImage;

  // --- Step 2: Contact & Location ---
  final mobileController = TextEditingController();
  final emailController = TextEditingController();
  String? _selectedEmirateCode;
  String? _selectedAreaName;
  String? _selectedAreaCode;
  String? _selectedSubAreaName;
  String? _selectedSubAreaCode;
  final poBoxController = TextEditingController();
  final addressController = TextEditingController();
  final latitudeController = TextEditingController();
  final longitudeController = TextEditingController();
  final branchDetailsController = TextEditingController();

  // --- Step 3: Bank Details ---
  final accountHolderNameController = TextEditingController();
  final bankNameController = TextEditingController();
  final accountNumberController = TextEditingController();
  final ibanNumberController = TextEditingController();
  String? _bankChequeImage;

  List<Map<String, String>> _emiratesList = [];
  // areas belong to an emirate
  List<Map<String, String>> _areasList = [];
  // sub-areas belong to an area
  List<Map<String, String>> _subAreasList = [];
  bool _hasSubAreas = false;
  final HybridOcrService _hybridOcrService = HybridOcrService();
  final BankDetailsOcrService _bankOcrService = BankDetailsOcrService();
  final EmiratesIdOcrService _emiratesIdOcrService = EmiratesIdOcrService();

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
      begin: const Offset(0, 0.1),
      end: Offset.zero,
    ).animate(_mainController);

    _scaleAnimation = Tween<double>(begin: 0.95, end: 1.0).animate(
      CurvedAnimation(
        parent: _mainController,
        curve: const Interval(0.3, 0.8, curve: Curves.easeOutCubic),
      ),
    );

    _mainController.forward();
    _loadEmirates();
    _initLocation();
  }

  @override
  void dispose() {
    _mainController.dispose();
    _scrollController.dispose();

    retailerCodeController.dispose();
    firmNameController.dispose();
    contNameController.dispose();
    trnNumberController.dispose();
    tradeLicenceController.dispose();
    businessDetailsController.dispose();
    emiratesIdController.dispose();
    mobileController.dispose();
    emailController.dispose();
    poBoxController.dispose();
    addressController.dispose();
    latitudeController.dispose();
    longitudeController.dispose();
    branchDetailsController.dispose();
    accountHolderNameController.dispose();
    bankNameController.dispose();
    accountNumberController.dispose();
    ibanNumberController.dispose();

    super.dispose();
  }

  void _toast(String msg) {
    if (!mounted) return;
    AppSnackBar.showInfo(context, msg);
  }

  String? _getEmirateNameFromCode(String? code) {
    if (code == null || code.isEmpty) return null;
    for (final item in _emiratesList) {
      if (item['code'] == code) {
        return item['name'];
      }
    }
    return null;
  }

  String? _getEmirateCodeFromName(String? name) {
    if (name == null || name.isEmpty) return null;
    for (final item in _emiratesList) {
      if (item['name'] == name) {
        return item['code'];
      }
    }
    return null;
  }

  Future<void> _loadEmirates() async {
    final data = await RetailerOnboardingService.getEmiratesList();
    if (!mounted) return;

    setState(() {
      _emiratesList = data;
      if (_selectedEmirateCode != null &&
          !_emiratesList.any((e) => e["code"] == _selectedEmirateCode)) {
        _selectedEmirateCode = null;
      }
    });

    debugPrint('Loaded emirates: $_emiratesList');
    if (data.isEmpty) {
      _toast('Emirates not loaded from backend');
    }
  }

  Future<void> _fetchDistricts(
    String emirateCode, {
    bool silent = false,
  }) async {
    setState(() {
      _areasList = [];
    });

    final data = await RetailerOnboardingService.getAreasList(emirateCode);
    if (!mounted) return;

    setState(() {
      _areasList = data;
      // clear sub-areas when areas change
      _subAreasList = [];
      _hasSubAreas = false;
      _selectedSubAreaName = null;
      _selectedSubAreaCode = null;
      // reset selected area code when list refreshes
      if (_selectedAreaName != null &&
          !_areasList.any((e) => e['name'] == _selectedAreaName)) {
        _selectedAreaName = null;
        _selectedAreaCode = null;
      }
    });

    debugPrint('Loaded areas for $emirateCode: $_areasList');
    if (data.isEmpty && !silent) {
      // Try a quick fallback: some backends expect the emirate name instead of code.
      final emirateName = _getEmirateNameFromCode(emirateCode);
      if (emirateName != null && emirateName.isNotEmpty) {
        debugPrint(
          'No districts for code $emirateCode — retrying with name $emirateName',
        );
        final retry = await RetailerOnboardingService.getAreasList(emirateName);
        if (!mounted) return;
        if (retry.isNotEmpty) {
          setState(() => _areasList = retry);
          debugPrint(
            'Fallback succeeded: loaded areas for name $emirateName: $_areasList',
          );
          return;
        }
      }

      _toast('No areas found for $emirateCode (backend returned 0).');
      debugPrint(
        'Hint: call /api/Retailer/areas?emirateCode=$emirateCode to inspect backend response',
      );
    }
  }

  Future<void> _fetchSubAreas(String areaCode, {bool silent = false}) async {
    setState(() {
      _subAreasList = []; // Reset sub-areas list
      _hasSubAreas = false;
    });

    final result = await RetailerOnboardingService.getSubAreasList(areaCode);
    if (!mounted) return;

    setState(() {
      _subAreasList = result.data;
      _hasSubAreas = result.hasSubArea;
      // if previously selected subarea no longer present, clear it
      if (_selectedSubAreaName != null &&
          !_subAreasList.any((a) => a['name'] == _selectedSubAreaName)) {
        _selectedSubAreaName = null;
        _selectedSubAreaCode = null;
      }
    });

    debugPrint(
      'Loaded sub-areas for $areaCode: $_subAreasList (hasSub=${result.hasSubArea})',
    );
    if ((result.data.isEmpty || !result.hasSubArea) && !silent) {
      // if no sub-areas found, try to auto-fill Place Code from selected area
      final sel = _areasList.firstWhere(
        (d) =>
            (d['name'] ?? '') == _selectedAreaName ||
            (d['code'] ?? '') == areaCode,
        orElse: () => <String, String>{},
      );
      final areaPoBox = sel['pobox'] ?? '';
      if (areaPoBox.isNotEmpty) {
        poBoxController.text = areaPoBox;
      }
      _toast('No sub-areas found for selected area');
    }
  }

  Future<void> _fetchRetailerDetails() async {
    final code = retailerCodeController.text.trim();
    if (code.isEmpty) {
      _toast('Please enter a Retailer Code');
      return;
    }

    setState(() => _isLoadingDetails = true);

    final details = await RetailerOnboardingService.getRetailerDetails(code);

    if (!mounted) return;
    setState(() => _isLoadingDetails = false);

    if (details == null) {
      _toast('Retailer not found or error fetching details');
      return;
    }

    firmNameController.text = details.firmName ?? '';
    contNameController.text = details.contName ?? '';
    trnNumberController.text =
        RetailerOnboardingService.formatTaxRegistrationNumber(
          details.trnNumber ?? '',
        );
    tradeLicenceController.text = details.tradeLicence ?? '';

    if (details.counterType == '01' || details.counterType == 'Paint') {
      _counterType = 'Paint';
    } else if (details.counterType == '02' ||
        details.counterType == 'Non-Paint') {
      _counterType = 'Non-Paint';
    } else {
      _counterType = null;
    }

    businessDetailsController.text = details.businessDetails ?? '';
    emiratesIdController.text = RetailerOnboardingService.formatEmiratesId(
      details.emiratesId ?? '',
    );

    mobileController.text = _mobileNumberForDisplay(details.mobileNumber);
    emailController.text = details.email ?? '';
    poBoxController.text = details.poBox ?? '';
    addressController.text = details.fullAddress ?? '';
    latitudeController.text = details.latitude ?? '';
    longitudeController.text = details.longitude ?? '';
    branchDetailsController.text = details.branchDetails ?? '';

    accountHolderNameController.text = details.accountHolderName ?? '';
    bankNameController.text = details.bankName ?? '';
    accountNumberController.text = details.accountNumber ?? '';
    ibanNumberController.text = details.ibanNumber ?? '';

    final emirateCode = details.emirateCode;
    final areaCode = details.areaCode;
    final areaName = details.areaName;
    final subAreaCode = details.subAreaCode;
    final subAreaName = details.subAreaName;

    if (emirateCode != null && emirateCode.isNotEmpty) {
      // load areas for emirate
      await _fetchDistricts(emirateCode, silent: true);
      if (!mounted) return;
    }

    // select area by code if available
    if (areaCode != null && areaCode.isNotEmpty) {
      final sel = _areasList.firstWhere(
        (a) => (a['code'] ?? '') == areaCode,
        orElse: () => <String, String>{},
      );
      if (sel.isNotEmpty) {
        setState(() {
          _selectedAreaCode = sel['code'];
          _selectedAreaName = sel['name'];
        });
        // load subareas for the selected area
        await _fetchSubAreas(areaCode, silent: true);
        if (!mounted) return;
      }
    }

    // select subarea if present
    if (subAreaCode != null && subAreaCode.isNotEmpty) {
      final sub = _subAreasList.firstWhere(
        (s) => (s['code'] ?? '') == subAreaCode,
        orElse: () => <String, String>{},
      );
      if (sub.isNotEmpty) {
        setState(() {
          _selectedSubAreaCode = sub['code'];
          _selectedSubAreaName = sub['name'];
          final po = sub['pobox'] ?? '';
          if (po.isNotEmpty) poBoxController.text = po;
        });
      }
    } else {
      // if no subarea, ensure poBox is filled from area
      if ((poBoxController.text ?? '').isEmpty && _selectedAreaCode != null) {
        final sel = _areasList.firstWhere(
          (a) => (a['code'] ?? '') == _selectedAreaCode,
          orElse: () => <String, String>{},
        );
        final areaPo = sel['pobox'] ?? '';
        if (areaPo.isNotEmpty) poBoxController.text = areaPo;
      }
    }

    setState(() {
      _selectedEmirateCode = emirateCode;
    });

    _toast('Details loaded successfully');
  }

  Future<void> _initLocation() async {
    setState(() => _isGettingLocation = true);
    try {
      final Position? position = await LocationService.getCurrentLocation();
      if (position != null && mounted) {
        latitudeController.text = position.latitude.toStringAsFixed(6);
        longitudeController.text = position.longitude.toStringAsFixed(6);
      }
    } catch (_) {
      // intentionally ignored
    } finally {
      if (mounted) setState(() => _isGettingLocation = false);
    }
  }

  String _mobileNumberForDisplay(String? mobileNumber) {
    final digits = (mobileNumber ?? '').replaceAll(RegExp(r'\D'), '');

    if (digits.startsWith('00971') && digits.length >= 14) {
      return digits.substring(5, 14);
    }

    if (digits.startsWith('971') && digits.length >= 12) {
      return digits.substring(3, 12);
    }

    if (digits.startsWith('05') && digits.length >= 10) {
      return digits.substring(1, 10);
    }

    if (digits.startsWith('5') && digits.length >= 9) {
      return digits.substring(0, 9);
    }

    return digits.length > 9 ? digits.substring(digits.length - 9) : digits;
  }

  void _updateBankFieldsFromResult(Map<String, String?> result) {
    final accountHolder = result['accountHolder']?.trim();
    if (accountHolder != null && accountHolder.isNotEmpty) {
      accountHolderNameController.text = accountHolder;
    }

    final bankName = result['bankName']?.trim();
    if (bankName != null && bankName.isNotEmpty) {
      bankNameController.text = bankName;
    }

    final iban = result['iban']?.trim();
    if (iban != null && iban.isNotEmpty) {
      final formattedIban = RetailerOnboardingService.formatIban(iban);
      if (_bankOcrService.isValidIban(formattedIban)) {
        ibanNumberController.text = formattedIban;
      }
    }
  }

  Future<void> _processEmiratesIdOcr() async {
    if (_emiratesIdImage == null || _emiratesIdImage!.isEmpty) return;

    setState(() => _isProcessingEmiratesIdOcr = true);

    try {
      final result = await _hybridOcrService.extractEmiratesIdFields(
        frontImagePath: _emiratesIdImage!,
        backImagePath: _emiratesIdImage!,
      );

      final id = result['id']?.trim();
      if (id != null && id.isNotEmpty) {
        final digits = RetailerOnboardingService.formatEmiratesId(id);
        if (digits.length == 15) {
          emiratesIdController.text = digits;
        } else if (_emiratesIdOcrService.isValidEmiratesId(id)) {
          emiratesIdController.text =
              RetailerOnboardingService.formatEmiratesId(id);
        }
      }

      if (!mounted) return;
      if (id != null && id.isNotEmpty) {
        AppSnackBar.showSuccess(context, 'Emirates ID autofilled with AI');
      } else {
        AppSnackBar.showWarning(
          context,
          'Could not extract Emirates ID — please enter manually',
        );
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error processing Emirates ID: ${e.toString()}'),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      if (mounted) setState(() => _isProcessingEmiratesIdOcr = false);
    }
  }

  Future<void> _processBankChequeOcr() async {
    if (_bankChequeImage == null || _bankChequeImage!.isEmpty) return;

    setState(() => _isProcessingBankOcr = true);

    try {
      final result = await _hybridOcrService.extractBankDetailsFields(
        bankDocumentPath: _bankChequeImage!,
      );

      _updateBankFieldsFromResult(result);

      if (!mounted) return;
      AppSnackBar.showSuccess(context, 'Bank details autofilled with AI');
    } catch (e) {
      if (!mounted) return;
      AppSnackBar.showError(
        context,
        'Error processing bank document: ${e.toString()}',
      );
    } finally {
      if (mounted) {
        setState(() => _isProcessingBankOcr = false);
      }
    }
  }

  bool _validateStep(int step) {
    if (step == 1) {
      final firmErr = RetailerOnboardingService.validateFirmName(
        firmNameController.text,
      );
      if (firmErr != null) {
        _toast(firmErr);
        return false;
      }

      final trnErr = RetailerOnboardingService.validateTaxRegistrationNumber(
        trnNumberController.text,
      );
      if (trnErr != null) {
        _toast(trnErr);
        return false;
      }

      final emiratesIdErr = RetailerOnboardingService.validateEmiratesId(
        emiratesIdController.text,
      );
      if (emiratesIdErr != null) {
        _toast(emiratesIdErr);
        return false;
      }

      final tradeErr = RetailerOnboardingService.validateTradeLicence(
        tradeLicenceController.text,
      );
      if (tradeErr != null) {
        _toast(tradeErr);
        return false;
      }

      if (_counterType == null || _counterType!.isEmpty) {
        _toast('Please select Counter Type');
        return false;
      }

      return true;
    }

    if (step == 2) {
      final mobileErr = RetailerOnboardingService.validateMobileNumber(
        mobileController.text,
      );
      if (mobileErr != null) {
        _toast(mobileErr);
        return false;
      }

      final emailErr = RetailerOnboardingService.validateEmail(
        emailController.text,
      );
      if (emailErr != null) {
        _toast(emailErr);
        return false;
      }

      if (_selectedEmirateCode == null || _selectedEmirateCode!.isEmpty) {
        _toast('Please select Emirate');
        return false;
      }
      if (_selectedAreaName == null || _selectedAreaName!.isEmpty) {
        _toast('Please select Area');
        return false;
      }

      if (_hasSubAreas &&
          (_selectedSubAreaName == null || _selectedSubAreaName!.isEmpty)) {
        _toast('Please select Sub-area');
        return false;
      }

      final addrErr = RetailerOnboardingService.validateAddress(
        addressController.text,
      );
      if (addrErr != null) {
        _toast(addrErr);
        return false;
      }

      return true;
    }

    if (step == 3) {
      final bankNameErr = RetailerOnboardingService.validateBankName(
        bankNameController.text,
      );
      if (bankNameErr != null) {
        _toast(bankNameErr);
        return false;
      }

      final accHolderErr = RetailerOnboardingService.validateAccountHolderName(
        accountHolderNameController.text,
      );
      if (accHolderErr != null) {
        _toast(accHolderErr);
        return false;
      }

      final accNoErr = RetailerOnboardingService.validateAccountNumber(
        accountNumberController.text,
      );
      if (accNoErr != null) {
        _toast(accNoErr);
        return false;
      }

      final ibanErr = RetailerOnboardingService.validateIban(
        ibanNumberController.text,
      );
      if (ibanErr != null) {
        _toast(ibanErr);
        return false;
      }

      return true;
    }

    return true;
  }

  Future<String?> _submitJsonData() async {
    final currentUser = AuthManager.currentUser;
    final loginId = (currentUser?.userID ?? currentUser?.emplName ?? 'SYSTEM')
        .toString()
        .trim();

    final normalizedMobile = RetailerOnboardingService.normalizeMobileNumber(
      mobileController.text.trim(),
    );

    // Resolve area and sub-area codes from selected names
    String? resolvedAreaCode = _selectedAreaCode;
    String? resolvedSubAreaCode = _selectedSubAreaCode;
    // If codes not set, try to resolve from lists by name
    if ((resolvedAreaCode == null || resolvedAreaCode!.isEmpty) &&
        _selectedAreaName != null &&
        _selectedAreaName!.isNotEmpty) {
      final area = _areasList.firstWhere(
        (d) => (d['name'] ?? '') == _selectedAreaName,
        orElse: () => <String, String>{},
      );
      resolvedAreaCode = area['code'];
    }

    if ((resolvedSubAreaCode == null || resolvedSubAreaCode!.isEmpty) &&
        _selectedSubAreaName != null &&
        _selectedSubAreaName!.isNotEmpty) {
      final sub = _subAreasList.firstWhere(
        (a) => (a['name'] ?? '') == _selectedSubAreaName,
        orElse: () => <String, String>{},
      );
      resolvedSubAreaCode = sub['code'];
    }

    final request = RetailerOnboardingRequest(
      processType: _processType,
      loginId: loginId,
      firmName: firmNameController.text.trim(),
      contName: contNameController.text.trim(),
      trnNumber: RetailerOnboardingService.formatTaxRegistrationNumber(
        trnNumberController.text.trim(),
      ),
      tradeLicence: tradeLicenceController.text.trim(),
      counterType: _counterType == 'Paint' ? '01' : '02',
      businessDetails: businessDetailsController.text.trim(),
      mobileNumber: normalizedMobile,
      email: emailController.text.trim(),
      emirateCode: _selectedEmirateCode,
      areaCode: resolvedAreaCode,
      subAreaCode: resolvedSubAreaCode,
      areaName: _selectedAreaName,
      subAreaName: _selectedSubAreaName,
      poBox: poBoxController.text.trim(),
      fullAddress: addressController.text.trim(),
      latitude: latitudeController.text.trim(),
      longitude: longitudeController.text.trim(),
      branchDetails: branchDetailsController.text.trim(),
      emiratesId: RetailerOnboardingService.formatEmiratesId(
        emiratesIdController.text.trim(),
      ),
      bankName: bankNameController.text.trim(),
      accountHolderName: accountHolderNameController.text.trim(),
      accountNumber: accountNumberController.text.trim(),
      ibanNumber: RetailerOnboardingService.formatIban(
        ibanNumberController.text.trim(),
      ),
    );

    try {
      late RetailerOnboardingResponse response;

      if (_processType == 'Update') {
        final code = retailerCodeController.text.trim();
        if (code.isEmpty) {
          _toast('Retailer Code is required for Update');
          return null;
        }
        response = await RetailerOnboardingService.updateRetailer(
          code,
          request,
        );
      } else {
        response = await RetailerOnboardingService.registerRetailer(request);
      }

      if (response.success) {
        return response.retailerCode ?? retailerCodeController.text.trim();
      }

      _toast(
        response.message.isNotEmpty ? response.message : 'Submission Failed',
      );
      return null;
    } catch (_) {
      _toast('Network Error. Please try again.');
      return null;
    }
  }

  Future<bool> _uploadFilesToServer(String retailerCode) async {
    final firmName = firmNameController.text.trim();
    final mobile = RetailerOnboardingService.normalizeMobileNumber(
      mobileController.text.trim(),
    );

    final filePathsByType = <String, String>{
      if (_trnDocumentImage != null && _trnDocumentImage!.isNotEmpty)
        DocumentType.trnDocument: _trnDocumentImage!,
      if (_bankChequeImage != null && _bankChequeImage!.isNotEmpty)
        DocumentType.bankCheque: _bankChequeImage!,
    };

    if (filePathsByType.isEmpty) {
      return true;
    }

    final currentUser = AuthManager.currentUser;
    final createId = (currentUser?.userID ?? currentUser?.emplName ?? 'SYSTEM')
        .toString()
        .trim();

    final results = await ImageUploadService.uploadMultipleImages(
      filePathsByType: filePathsByType,
      firstName: firmName.isEmpty ? retailerCode : firmName,
      lastName: retailerCode,
      mobile: mobile,
      createId: createId,
    );

    int failCount = 0;
    String firstError = '';

    results.forEach((_, response) {
      if (!response.success) {
        failCount++;
        if (firstError.isEmpty) {
          firstError = response.message;
        }
      }
    });

    if (failCount > 0 && mounted) {
      await showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: const Row(
            children: [
              Icon(Icons.warning_amber_rounded, color: Colors.orange),
              SizedBox(width: 8),
              Text('Retailer Created'),
            ],
          ),
          content: Text(
            'Retailer was saved successfully, but $failCount document(s) failed to upload.\n\nDetails: $firstError',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('OK'),
            ),
          ],
        ),
      );
      return false;
    }

    return true;
  }

  Future<void> _submitForm() async {
    if (!_validateStep(1)) {
      setState(() => _currentStep = 1);
      return;
    }
    if (!_validateStep(2)) {
      setState(() => _currentStep = 2);
      return;
    }
    if (!_validateStep(3)) {
      setState(() => _currentStep = 3);
      return;
    }

    setState(() => _isSubmitting = true);

    try {
      _toast('Registering retailer...');
      final retailerCode = await _submitJsonData();

      if (retailerCode == null || retailerCode.isEmpty) {
        return;
      }

      final hasFiles =
          (_trnDocumentImage != null && _trnDocumentImage!.isNotEmpty) ||
          (_bankChequeImage != null && _bankChequeImage!.isNotEmpty);

      if (hasFiles) {
        _toast('Uploading documents...');
        await _uploadFilesToServer(retailerCode);
      }

      _toast('Registration Complete! Retailer Code: $retailerCode');
      if (mounted) context.pop();
    } finally {
      if (mounted) {
        setState(() => _isSubmitting = false);
      }
    }
  }

  String _getStepTitle() {
    switch (_currentStep) {
      case 1:
        return 'Identity';
      case 2:
        return 'Location';
      case 3:
        return 'Bank';
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
              _buildProgressStep(1, 'Identity', _currentStep >= 1),
              _buildProgressLine(_currentStep >= 2),
              _buildProgressStep(2, 'Location', _currentStep >= 2),
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

  Widget _buildIdentitySection() {
    return ResponsiveSection(
      title: 'Business Identity',
      icon: Icons.business,
      subtitle: 'Provide your basic business details',
      children: [
        ModernDropdown(
          label: 'Process Type',
          icon: Icons.settings,
          items: const ['Add', 'Update'],
          value: _processType,
          isRequired: true,
          onChanged: (val) {
            setState(() {
              _processType = val;
              if (val == 'Add') {
                retailerCodeController.clear();
              }
            });
          },
        ),
        if (_processType == 'Update') ...[
          const ResponsiveSpacing(mobile: 16),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: ResponsiveTextField(
                  controller: retailerCodeController,
                  label: 'Retailer Code',
                  icon: Icons.storefront,
                  isRequired: true,
                ),
              ),
              SizedBox(width: 8.w),
              SizedBox(
                height: 56.h,
                child: ElevatedButton.icon(
                  onPressed: _isLoadingDetails ? null : _fetchRetailerDetails,
                  icon: _isLoadingDetails
                      ? SizedBox(
                          width: 20.w,
                          height: 20.h,
                          child: const CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        )
                      : const Icon(Icons.search),
                  label: const Text('Fetch'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF1E3A8A),
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12.r),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
        const ResponsiveSpacing(mobile: 16),
        ResponsiveRow(
          children: [
            ResponsiveTextField(
              controller: firmNameController,
              label: 'Firm Name',
              icon: Icons.business,
            ),
            ResponsiveTextField(
              controller: contNameController,
              label: 'Contact Person Name',
              icon: Icons.person_outline,
              isRequired: false,
            ),
            ResponsiveTextField(
              controller: mobileController,
              label: 'Mobile Number',
              icon: Icons.phone,
              keyboardType: TextInputType.phone,
              prefixText: '+971 ',
              hint: '501234567',
              inputFormatters: [
                FilteringTextInputFormatter.digitsOnly,
                LengthLimitingTextInputFormatter(9),
              ],
            ),
          ],
        ),
        const ResponsiveSpacing(mobile: 16),
        ResponsiveRow(
          children: [
            ResponsiveTextField(
              controller: trnNumberController,
              label: 'TRN Number',
              icon: Icons.receipt_long,
              keyboardType: TextInputType.number,
              inputFormatters: [
                FilteringTextInputFormatter.digitsOnly,
                LengthLimitingTextInputFormatter(15),
              ],
              isRequired: false,
            ),
            ResponsiveTextField(
              controller: tradeLicenceController,
              label: 'Trade Licence Number',
              icon: Icons.badge,
              isRequired: false,
            ),
          ],
        ),
        const ResponsiveSpacing(mobile: 16),
        FileUploadWidget(
          label: 'Upload TRN Document',
          icon: Icons.upload_file,
          allowedExtensions: const ['jpg', 'png', 'pdf'],
          currentFilePath: _trnDocumentImage,
          onFileSelected: (path) => setState(() => _trnDocumentImage = path),
        ),
        const ResponsiveSpacing(mobile: 16),
        ResponsiveRow(
          children: [
            ModernDropdown(
              label: 'Counter Type',
              icon: Icons.category,
              items: const ['Paint', 'Non-Paint'],
              value: _counterType,
              isRequired: true,
              onChanged: (val) => setState(() => _counterType = val),
            ),
            ResponsiveTextField(
              controller: businessDetailsController,
              label: 'Business Details',
              icon: Icons.info_outline,
              isRequired: false,
            ),
          ],
        ),
        const ResponsiveSpacing(mobile: 16),
        FileUploadWidget(
          label: 'Upload Emirates ID',
          icon: Icons.badge_outlined,
          allowedExtensions: const ['jpg', 'jpeg', 'png', 'pdf'],
          currentFilePath: _emiratesIdImage,
          onFileSelected: (path) async {
            setState(() => _emiratesIdImage = path);
            if (path == null || path.isEmpty || !mounted) return;
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Processing Emirates ID...')),
            );
            await _processEmiratesIdOcr();
          },
        ),
        if (_isProcessingEmiratesIdOcr) ...[
          const ResponsiveSpacing(mobile: 12),
          Row(
            children: [
              SizedBox(
                width: 16.w,
                height: 16.h,
                child: const CircularProgressIndicator(strokeWidth: 2),
              ),
              SizedBox(width: 8.w),
              Text(
                'Scanning Emirates ID...',
                style: TextStyle(fontSize: 12.sp, color: Colors.grey.shade700),
              ),
            ],
          ),
        ],
        const ResponsiveSpacing(mobile: 16),
        ResponsiveTextField(
          controller: emiratesIdController,
          label: 'Emirates ID',
          icon: Icons.badge_outlined,
          keyboardType: TextInputType.number,
          inputFormatters: [
            FilteringTextInputFormatter.digitsOnly,
            LengthLimitingTextInputFormatter(15),
          ],
          isRequired: false,
        ),
        if (_emiratesIdImage != null && _emiratesIdImage!.isNotEmpty) ...[
          const ResponsiveSpacing(mobile: 8),
          Align(
            alignment: Alignment.centerLeft,
            child: TextButton.icon(
              onPressed: _isProcessingEmiratesIdOcr
                  ? null
                  : _processEmiratesIdOcr,
              icon: const Icon(Icons.refresh_rounded, size: 16),
              label: const Text('Re-scan Emirates ID'),
              style: TextButton.styleFrom(
                foregroundColor: const Color(0xFF1E3A8A),
              ),
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildLocationSection() {
    final selectedEmirateName = _getEmirateNameFromCode(_selectedEmirateCode);

    return ResponsiveSection(
      title: 'Contact & Location',
      icon: Icons.location_on_outlined,
      subtitle: 'How can we reach you?',
      children: [
        ResponsiveRow(
          children: [
            ResponsiveTextField(
              controller: emailController,
              label: 'Email ID',
              icon: Icons.email,
              keyboardType: TextInputType.emailAddress,
              isRequired: false,
            ),
          ],
        ),
        const ResponsiveSpacing(mobile: 16),
        ResponsiveRow(
          children: [
            ModernDropdown(
              label: 'Emirate *',
              icon: Icons.location_city,
              value: selectedEmirateName,
              items: _emiratesList.map((e) => e["name"] as String).toList(),
              isRequired: true,
              onChanged: (selectedName) {
                final code = _getEmirateCodeFromName(selectedName);
                if (code != null) {
                  setState(() {
                    _selectedEmirateCode = code;
                    // clear area + subarea selections
                    _selectedAreaName = null;
                    _selectedAreaCode = null;
                    _areasList = [];
                    _selectedSubAreaName = null;
                    _selectedSubAreaCode = null;
                    _subAreasList = [];
                    _hasSubAreas = false;
                    poBoxController.clear();
                  });
                  _fetchDistricts(code); // fetch areas for emirate
                }
              },
            ),
            ModernDropdown(
              label: 'Area *',
              icon: Icons.map,
              value: _selectedAreaName,
              items: _areasList.map((d) => d["name"] as String).toList(),
              isRequired: true,
              onChanged: (val) {
                if (val != null) {
                  setState(() {
                    _selectedAreaName = val;
                    _selectedSubAreaName = null;
                    _subAreasList = [];
                    _hasSubAreas = false;
                    poBoxController.clear();
                  });

                  // Use the selected area's code to fetch sub-areas
                  final sel = _areasList.firstWhere(
                    (d) => (d['name'] ?? '') == val,
                    orElse: () => <String, String>{},
                  );
                  final areaCode = sel['code'] ?? '';
                  _selectedAreaCode = areaCode.isNotEmpty ? areaCode : null;
                  if (areaCode.isNotEmpty) {
                    _fetchSubAreas(areaCode);
                  }
                }
              },
            ),
          ],
        ),
        const ResponsiveSpacing(mobile: 16),
        // Show sub-area dropdown only when the backend returns items
        if (_hasSubAreas && _subAreasList.isNotEmpty)
          ModernDropdown(
            label: 'Sub-area *',
            icon: Icons.location_on,
            value: _selectedSubAreaName,
            items: _subAreasList.map((e) => e['name'] ?? '').toList(),
            isRequired: true,
            onChanged: (val) {
              setState(() {
                _selectedSubAreaName = val;
                // find and set subarea code
                final match = _subAreasList.firstWhere(
                  (e) => (e['name'] ?? '') == (val ?? ''),
                  orElse: () => <String, String>{},
                );
                _selectedSubAreaCode = match['code'];
              });

              // Auto-fill PO Box from selected sub-area
              if (val != null && val.isNotEmpty) {
                final match = _subAreasList.firstWhere(
                  (e) => (e['name'] ?? '') == val,
                  orElse: () => <String, String>{},
                );
                final poBox = match['pobox'] ?? '';
                if (poBox.isNotEmpty) {
                  poBoxController.text = poBox;
                }
              }
            },
          ),
        const ResponsiveSpacing(mobile: 16),
        ResponsiveRow(
          children: [
            ResponsiveTextField(
              controller: poBoxController,
              label: 'Place Code',
              icon: Icons.markunread_mailbox,
              isRequired: false,
            ),
            ResponsiveTextField(
              controller: addressController,
              label: 'Full Address',
              icon: Icons.location_on,
            ),
          ],
        ),
        const ResponsiveSpacing(mobile: 16),
        ResponsiveRow(
          children: [
            ResponsiveTextField(
              controller: latitudeController,
              label: 'Latitude',
              icon: Icons.gps_fixed,
              isRequired: false,
            ),
            ResponsiveTextField(
              controller: longitudeController,
              label: 'Longitude',
              icon: Icons.gps_fixed,
              isRequired: false,
            ),
          ],
        ),
        const ResponsiveSpacing(mobile: 16),
        ResponsiveTextField(
          controller: branchDetailsController,
          label: 'Branch Details',
          icon: Icons.store,
          isRequired: false,
        ),
        if (_isGettingLocation) ...[
          SizedBox(height: 12.h),
          Row(
            children: [
              SizedBox(
                height: 16.h,
                width: 16.w,
                child: const CircularProgressIndicator(strokeWidth: 2),
              ),
              SizedBox(width: 8.w),
              Text(
                'Fetching current location...',
                style: TextStyle(fontSize: 12.sp, color: Colors.grey.shade700),
              ),
            ],
          ),
        ],
      ],
    );
  }

  Widget _buildBankSection() {
    return ResponsiveSection(
      title: 'Bank Details',
      icon: Icons.account_balance,
      subtitle: 'Upload cheque copy to auto-fill bank particulars',
      children: [
        FileUploadWidget(
          label: 'Upload Cheque Copy',
          icon: Icons.image,
          allowedExtensions: const ['jpg', 'png', 'pdf'],
          currentFilePath: _bankChequeImage,
          onFileSelected: (path) async {
            setState(() => _bankChequeImage = path);

            if (path == null || path.isEmpty || !mounted) return;

            final isPdf = path.toLowerCase().endsWith('.pdf');
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(
                  '${isPdf ? 'PDF' : 'Image'} uploaded. Processing...',
                ),
              ),
            );

            await _processBankChequeOcr();
          },
        ),
        if (_isProcessingBankOcr) ...[
          const ResponsiveSpacing(mobile: 16),
          const Center(
            child: Padding(
              padding: EdgeInsets.all(16),
              child: Column(
                children: [
                  CircularProgressIndicator(),
                  SizedBox(height: 12),
                  Text('Processing bank document...'),
                ],
              ),
            ),
          ),
        ],
        const ResponsiveSpacing(mobile: 16),
        ResponsiveRow(
          children: [
            ResponsiveTextField(
              controller: accountHolderNameController,
              label: 'Account Holder Name',
              icon: Icons.person_outline,
              isRequired: false,
            ),
            ResponsiveTextField(
              controller: bankNameController,
              label: 'Bank Name',
              icon: Icons.account_balance,
              isRequired: false,
            ),
          ],
        ),
        const ResponsiveSpacing(mobile: 16),
        ResponsiveRow(
          children: [
            ResponsiveTextField(
              controller: accountNumberController,
              label: 'Account Number',
              icon: Icons.numbers,
              keyboardType: TextInputType.text,
              isRequired: false,
            ),
            ResponsiveTextField(
              controller: ibanNumberController,
              label: 'IBAN Number',
              icon: Icons.credit_card,
              isRequired: false,
            ),
          ],
        ),
        if (_bankChequeImage != null && _bankChequeImage!.isNotEmpty) ...[
          const ResponsiveSpacing(mobile: 16),
          Align(
            alignment: Alignment.centerLeft,
            child: ElevatedButton.icon(
              onPressed: _isProcessingBankOcr ? null : _processBankChequeOcr,
              icon: const Icon(Icons.refresh_rounded),
              label: const Text('Re-scan Bank Document'),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF1E3A8A),
                foregroundColor: Colors.white,
              ),
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildDesktopLayout() {
    Widget currentSection;
    switch (_currentStep) {
      case 1:
        currentSection = _buildIdentitySection();
        break;
      case 2:
        currentSection = _buildLocationSection();
        break;
      case 3:
        currentSection = _buildBankSection();
        break;
      default:
        currentSection = _buildIdentitySection();
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
        if (_currentStep > 1)
          Expanded(
            child: OutlinedButton(
              onPressed: () {
                setState(() => _currentStep--);
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
        Expanded(
          child: ElevatedButton(
            onPressed: _isSubmitting
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
                      _submitForm();
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
            child: _isSubmitting && _currentStep == 3
                ? const SizedBox(
                    height: 20,
                    width: 20,
                    child: CircularProgressIndicator(
                      color: Colors.white,
                      strokeWidth: 2,
                    ),
                  )
                : Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        _currentStep < 3 ? 'Next' : 'Submit Registration',
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      body: CustomScrollView(
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
                'Retailer Registration',
                style: TextStyle(
                  fontSize: 16.sp,
                  fontWeight: FontWeight.w600,
                  color: Colors.white,
                  shadows: const [
                    Shadow(
                      offset: Offset(0, 2),
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
                      Icons.store,
                      size: 100.sp,
                      color: Colors.white.withOpacity(0.2),
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
}
