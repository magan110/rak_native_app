import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:file_picker/file_picker.dart';
import 'user_list_models.dart';
import 'user_list_service.dart';
import '../../core/services/hybrid_ocr_service.dart';
import '../../core/services/emirates_id_ocr_service.dart';
import '../../core/services/auth_service.dart';
import '../../core/utils/snackbar_utils.dart';
import '../../core/utils/uae_phone_utils.dart';
import '../../shared/widgets/file_upload_widget.dart';

class UserEditScreen extends StatefulWidget {
  final UserItem user;

  const UserEditScreen({super.key, required this.user});

  @override
  State<UserEditScreen> createState() => _UserEditScreenState();
}

class _UserEditScreenState extends State<UserEditScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  // Personal Details Controllers
  late TextEditingController _contractorTypeController;
  late TextEditingController _firstNameController;
  late TextEditingController _middleNameController;
  late TextEditingController _lastNameController;
  late TextEditingController _mobileController;
  late TextEditingController _emailController;
  late TextEditingController _addressController;
  late TextEditingController _areaController;
  late TextEditingController _emiratesController;

  // Emirates ID Controllers
  late TextEditingController _emiratesIdController;
  late TextEditingController _idNameController;
  late TextEditingController _dateOfBirthController;
  late TextEditingController _nationalityController;
  late TextEditingController _companyDetailsController; // Employer
  late TextEditingController _issueDateController;
  late TextEditingController _expiryDateController;
  late TextEditingController _occupationController;

  // Bank Details Controllers
  late TextEditingController _accountHolderController;
  late TextEditingController _ibanController;
  late TextEditingController _bankNameController;
  late TextEditingController _branchNameController;
  late TextEditingController _bankAddressController;

  // Contractor License Controllers
  late TextEditingController _licenseNumberController;
  late TextEditingController _issuingAuthorityController;
  late TextEditingController _licenseTypeController;
  late TextEditingController _establishmentDateController;
  late TextEditingController _licenseExpiryDateController;
  late TextEditingController _tradeNameController;
  late TextEditingController _responsiblePersonController;
  late TextEditingController _licenseAddressController;
  late TextEditingController _effectiveDateController;

  // VAT Controllers (Contractor)
  late TextEditingController _firmNameController;
  late TextEditingController _vatAddressController;
  late TextEditingController _taxRegistrationController;
  late TextEditingController _vatEffectiveDateController;

  late String _status;
  bool _isLoadingDetails = true;
  String? _userType; // Will be determined from API

  // File upload paths
  String? _emiratesIdFrontFile;
  String? _emiratesIdBackFile;
  String? _bankDocumentPath;
  String? _vatCertificatePath;
  String? _commercialLicensePath;

  // Hybrid OCR service (Gemini with ML Kit fallback)
  final _hybridOcrService = HybridOcrService();

  // Legacy OCR service for validation methods
  final _ocrService = EmiratesIdOcrService();

  bool _isProcessingOcr = false;
  bool _isProcessingBankOcr = false;
  bool _isProcessingVatOcr = false;
  bool _isProcessingCommercialLicenceOcr = false;

  @override
  void initState() {
    super.initState();
    // Initialize with default type from widget, will be updated when API loads
    _userType = widget.user.type;
    _tabController = TabController(length: _getTabCount(), vsync: this);
    _initializeControllers();
    _loadUserDetails();
  }

  int _getTabCount() {
    final type = (_userType ?? widget.user.type).toUpperCase().trim();
    // Type codes: "MA" or "PE" for Contractor, "PN" for Painter
    // Also handle display names "Contractor" and "Painter"
    if (type == 'CONTRACTOR' || type == 'MA' || type == 'PE') {
      return 5; // Contractor has 5 tabs (Personal, Emirates ID, Bank, License, VAT)
    }
    return 3; // Painter has 3 tabs (Personal, Emirates ID, Bank)
  }

  String _getUserTypeDisplayName() {
    final type = (_userType ?? widget.user.type).toUpperCase().trim();
    if (type == 'CONTRACTOR' || type == 'MA' || type == 'PE') {
      return 'Contractor';
    }
    return 'Painter';
  }

  Future<void> _loadUserDetails() async {
    setState(() {
      _isLoadingDetails = true;
    });

    try {
      final service = UserListService();
      final details = await service.getUserById(widget.user.id);

      setState(() {
        _userType = details.type;
        _isLoadingDetails = false;
      });

      // Update tab controller if type changed
      if (_tabController.length != _getTabCount()) {
        _tabController.dispose();
        _tabController = TabController(length: _getTabCount(), vsync: this);
      }

      // Update controllers with loaded data
      _updateControllersFromDetails(details);
    } catch (e) {
      setState(() {
        _isLoadingDetails = false;
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error loading user details: ${e.toString()}'),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 5),
          ),
        );
      }
    }
  }

  void _updateControllersFromDetails(UserDetailDto details) {
    // Helper function to clean empty strings and handle nulls
    String cleanValue(String? value) {
      if (value == null || value.trim().isEmpty) return '';
      return value.trim();
    }

    // Personal Details
    _contractorTypeController.text = cleanValue(details.contractorType);
    _firstNameController.text = cleanValue(details.firstName);
    _middleNameController.text = cleanValue(details.middleName);
    _lastNameController.text = cleanValue(details.lastName);
    _mobileController.text = cleanValue(details.mobileNumber) != ''
        ? cleanValue(details.mobileNumber)
        : widget.user.mobile;
    _emailController.text = widget.user.email; // Email not in details DTO
    _addressController.text = cleanValue(details.address);
    _areaController.text = cleanValue(details.area);
    _emiratesController.text = cleanValue(details.emirates);

    // Emirates ID
    _emiratesIdController.text = cleanValue(details.emiratesIdNumber) != ''
        ? cleanValue(details.emiratesIdNumber)
        : widget.user.emiratesId;
    _idNameController.text = cleanValue(details.idName) != ''
        ? cleanValue(details.idName)
        : widget.user.name;
    // Clean date format - remove time portion if present
    String cleanDate(String? date) {
      if (date == null || date.trim().isEmpty) return '';
      // Remove time portion like " 12:00:00 AM"
      return date.split(' ')[0].trim();
    }

    _dateOfBirthController.text = cleanDate(details.dateOfBirth);
    _nationalityController.text = cleanValue(details.nationality);
    _companyDetailsController.text = cleanValue(details.companyDetails) != ''
        ? cleanValue(details.companyDetails)
        : (widget.user.companyName ?? '');
    _issueDateController.text = cleanDate(details.issueDate);
    _expiryDateController.text = cleanDate(details.expiryDate);
    _occupationController.text = cleanValue(details.occupation);

    // Bank Details
    _accountHolderController.text = cleanValue(details.accountHolderName) != ''
        ? cleanValue(details.accountHolderName)
        : widget.user.name;
    _ibanController.text = cleanValue(details.ibanNumber);
    _bankNameController.text = cleanValue(details.bankName);
    _branchNameController.text = cleanValue(details.branchName);
    _bankAddressController.text = cleanValue(details.bankAddress);

    // Contractor License
    _licenseNumberController.text = cleanValue(details.licenseNumber) != ''
        ? cleanValue(details.licenseNumber)
        : (widget.user.licenseNumber ?? '');
    _issuingAuthorityController.text = cleanValue(details.issuingAuthority);
    _licenseTypeController.text = cleanValue(details.licenseType);
    _establishmentDateController.text = cleanDate(details.establishmentDate);
    _licenseExpiryDateController.text = cleanDate(details.licenseExpiryDate);
    _tradeNameController.text = cleanValue(details.tradeName) != ''
        ? cleanValue(details.tradeName)
        : (widget.user.companyName ?? '');
    _responsiblePersonController.text =
        cleanValue(details.responsiblePerson) != ''
        ? cleanValue(details.responsiblePerson)
        : widget.user.name;
    _licenseAddressController.text = cleanValue(details.licenseAddress);
    _effectiveDateController.text = cleanDate(details.effectiveDate);

    // VAT
    _firmNameController.text = cleanValue(details.firmName) != ''
        ? cleanValue(details.firmName)
        : (widget.user.companyName ?? '');
    _vatAddressController.text = cleanValue(details.vatAddress);
    _taxRegistrationController.text = cleanValue(details.taxRegistrationNumber);
    _vatEffectiveDateController.text = cleanDate(details.vatEffectiveDate);

    _status = details.status ?? widget.user.status;
  }

  void _initializeControllers() {
    // Initialize with widget data first, will be updated when API loads
    final nameParts = widget.user.name.split(' ');
    _contractorTypeController = TextEditingController(text: '');
    _firstNameController = TextEditingController(
      text: nameParts.isNotEmpty ? nameParts[0] : '',
    );
    _middleNameController = TextEditingController(
      text: nameParts.length > 2 ? nameParts[1] : '',
    );
    _lastNameController = TextEditingController(
      text: nameParts.length > 1 ? nameParts.last : '',
    );
    _mobileController = TextEditingController(text: widget.user.mobile);
    _emailController = TextEditingController(text: widget.user.email);
    _addressController = TextEditingController(text: '');
    _areaController = TextEditingController(text: '');
    _emiratesController = TextEditingController(text: '');

    // Emirates ID
    _emiratesIdController = TextEditingController(text: widget.user.emiratesId);
    _idNameController = TextEditingController(text: widget.user.name);
    _dateOfBirthController = TextEditingController(text: '');
    _nationalityController = TextEditingController(text: '');
    _companyDetailsController = TextEditingController(
      text: widget.user.companyName ?? '',
    );
    _issueDateController = TextEditingController(text: '');
    _expiryDateController = TextEditingController(text: '');
    _occupationController = TextEditingController(text: widget.user.type);

    // Bank Details
    _accountHolderController = TextEditingController(text: widget.user.name);
    _ibanController = TextEditingController(text: '');
    _bankNameController = TextEditingController(text: '');
    _branchNameController = TextEditingController(text: '');
    _bankAddressController = TextEditingController(text: '');

    // Contractor License
    _licenseNumberController = TextEditingController(
      text: widget.user.licenseNumber ?? '',
    );
    _issuingAuthorityController = TextEditingController(text: '');
    _licenseTypeController = TextEditingController(text: '');
    _establishmentDateController = TextEditingController(text: '');
    _licenseExpiryDateController = TextEditingController(text: '');
    _tradeNameController = TextEditingController(
      text: widget.user.companyName ?? '',
    );
    _responsiblePersonController = TextEditingController(
      text: widget.user.name,
    );
    _licenseAddressController = TextEditingController(text: '');
    _effectiveDateController = TextEditingController(text: '');

    // VAT
    _firmNameController = TextEditingController(
      text: widget.user.companyName ?? '',
    );
    _vatAddressController = TextEditingController(text: '');
    _taxRegistrationController = TextEditingController(text: '');
    _vatEffectiveDateController = TextEditingController(text: '');

    _status = widget.user.status;
  }

  // OCR Methods using Hybrid Service (Gemini with ML Kit fallback)
  Future<void> _scanEmiratesId() async {
    try {
      // Pick front image
      final frontResult = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['jpg', 'jpeg', 'png', 'pdf'],
        dialogTitle: 'Select Emirates ID Front',
      );

      if (frontResult == null || frontResult.files.single.path == null) return;

      // Pick back image
      final backResult = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['jpg', 'jpeg', 'png', 'pdf'],
        dialogTitle: 'Select Emirates ID Back',
      );

      if (backResult == null || backResult.files.single.path == null) return;

      setState(() {
        _isProcessingOcr = true;
        _emiratesIdFrontFile = frontResult.files.single.path;
        _emiratesIdBackFile = backResult.files.single.path;
      });

      try {
        debugPrint(
          '[UserManagement] Using Hybrid OCR for Emirates ID (Gemini with ML Kit fallback)',
        );

        final result = await _hybridOcrService.extractEmiratesIdFields(
          frontImagePath: frontResult.files.single.path!,
          backImagePath: backResult.files.single.path!,
        );

        _updateEmiratesIdFieldsFromResult(result);

        if (mounted) {
          _showSnackBar(
            'Emirates ID fields autofilled successfully!',
            isError: false,
          );
        }
      } catch (e) {
        debugPrint('Error in Emirates ID OCR: $e');
        if (mounted) {
          _showSnackBar(
            'Error processing Emirates ID: ${e.toString()}',
            isError: true,
          );
        }
      } finally {
        if (mounted) {
          setState(() {
            _isProcessingOcr = false;
          });
        }
      }
    } catch (e) {
      setState(() => _isProcessingOcr = false);
      _showSnackBar(
        'Error selecting Emirates ID files: ${e.toString()}',
        isError: true,
      );
    }
  }

  // Auto-process Emirates ID OCR when both files are uploaded
  Future<void> _processEmiratesIdOcrWithRetry() async {
    if (_emiratesIdFrontFile == null || _emiratesIdBackFile == null) return;

    setState(() {
      _isProcessingOcr = true;
    });

    try {
      debugPrint(
        '[UserManagement] Auto-processing Emirates ID OCR (Gemini with ML Kit fallback)',
      );

      final result = await _hybridOcrService.extractEmiratesIdFields(
        frontImagePath: _emiratesIdFrontFile!,
        backImagePath: _emiratesIdBackFile!,
      );

      _updateEmiratesIdFieldsFromResult(result);

      if (mounted) {
        _showSnackBar(
          'Emirates ID fields autofilled automatically!',
          isError: false,
        );
      }
    } catch (e) {
      debugPrint('Error in auto Emirates ID OCR: $e');
      if (mounted) {
        _showSnackBar(
          'Auto-fill failed. Use "Scan Emirates ID" button to retry.',
          isError: true,
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isProcessingOcr = false;
        });
      }
    }
  }

  // Helper to update Emirates ID form fields from parsed results with validation
  void _updateEmiratesIdFieldsFromResult(Map<String, String?> result) {
    if (result['id'] != null && _ocrService.isValidEmiratesId(result['id']!)) {
      _emiratesIdController.text = result['id']!;
    }

    if (result['name'] != null && result['name']!.isNotEmpty) {
      _idNameController.text = result['name']!;

      // Try to split name into first, middle, last - only if current fields are empty
      if (_firstNameController.text.isEmpty) {
        final nameParts = result['name']!.split(' ');
        if (nameParts.isNotEmpty) {
          _firstNameController.text = nameParts.first;
        }
        if (nameParts.length > 2) {
          _middleNameController.text = nameParts
              .sublist(1, nameParts.length - 1)
              .join(' ');
        }
        if (nameParts.length > 1) {
          _lastNameController.text = nameParts.last;
        }
      }
    }

    if (result['dob'] != null && result['dob']!.isNotEmpty) {
      if (_ocrService.isValidDate(result['dob']!)) {
        _dateOfBirthController.text = result['dob']!;
      }
    }

    if (result['nationality'] != null && result['nationality']!.isNotEmpty) {
      _nationalityController.text = result['nationality']!;
    }

    if (result['issue'] != null && result['issue']!.isNotEmpty) {
      if (_ocrService.isValidDate(result['issue']!)) {
        _issueDateController.text = result['issue']!;
      }
    }

    if (result['expiry'] != null && result['expiry']!.isNotEmpty) {
      if (_ocrService.isValidDate(result['expiry']!)) {
        _expiryDateController.text = result['expiry']!;
      }
    }

    if (result['employer'] != null && result['employer']!.isNotEmpty) {
      _companyDetailsController.text = result['employer']!;
    }

    if (result['occupation'] != null && result['occupation']!.isNotEmpty) {
      _occupationController.text = result['occupation']!;
    }
  }

  Future<void> _scanBankDetails() async {
    try {
      final result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['jpg', 'jpeg', 'png', 'pdf'],
        dialogTitle: 'Select Bank Document',
      );

      if (result == null || result.files.single.path == null) return;

      setState(() {
        _isProcessingBankOcr = true;
        _bankDocumentPath = result.files.single.path;
      });

      try {
        debugPrint(
          '[UserManagement] Using Hybrid OCR for Bank Details (Gemini with ML Kit fallback)',
        );

        final fields = await _hybridOcrService.extractBankDetailsFields(
          bankDocumentPath: result.files.single.path!,
        );

        _updateBankDetailsFieldsFromResult(fields);

        if (mounted) {
          _showSnackBar(
            'Bank details autofilled successfully!',
            isError: false,
          );
        }
      } catch (e) {
        debugPrint('Error in Bank Details OCR: $e');
        if (mounted) {
          _showSnackBar(
            'Error processing bank document: ${e.toString()}',
            isError: true,
          );
        }
      } finally {
        if (mounted) {
          setState(() {
            _isProcessingBankOcr = false;
          });
        }
      }
    } catch (e) {
      setState(() => _isProcessingBankOcr = false);
      _showSnackBar(
        'Error selecting bank document: ${e.toString()}',
        isError: true,
      );
    }
  }

  // Auto-process Bank Document OCR when file is uploaded
  Future<void> _processBankDocumentOcr() async {
    if (_bankDocumentPath == null) return;

    setState(() {
      _isProcessingBankOcr = true;
    });

    try {
      debugPrint(
        '[UserManagement] Auto-processing Bank Document OCR (Gemini with ML Kit fallback)',
      );

      final fields = await _hybridOcrService.extractBankDetailsFields(
        bankDocumentPath: _bankDocumentPath!,
      );

      _updateBankDetailsFieldsFromResult(fields);

      if (mounted) {
        _showSnackBar('Bank details autofilled automatically!', isError: false);
      }
    } catch (e) {
      debugPrint('Error in auto Bank Document OCR: $e');
      if (mounted) {
        _showSnackBar(
          'Auto-fill failed. Use "Scan Bank Doc" button to retry.',
          isError: true,
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isProcessingBankOcr = false;
        });
      }
    }
  }

  // Helper to update bank details form fields from parsed results
  void _updateBankDetailsFieldsFromResult(Map<String, String?> fields) {
    if (fields['accountHolder'] != null &&
        fields['accountHolder']!.isNotEmpty) {
      _accountHolderController.text = fields['accountHolder']!;
    }
    if (fields['iban'] != null && fields['iban']!.isNotEmpty) {
      _ibanController.text = fields['iban']!;
    }
    if (fields['bankName'] != null && fields['bankName']!.isNotEmpty) {
      _bankNameController.text = fields['bankName']!;
    }
    if (fields['branchName'] != null && fields['branchName']!.isNotEmpty) {
      _branchNameController.text = fields['branchName']!;
    }
    if (fields['bankAddress'] != null && fields['bankAddress']!.isNotEmpty) {
      _bankAddressController.text = fields['bankAddress']!;
    }
  }

  Future<void> _scanVatCertificate() async {
    try {
      final result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['jpg', 'jpeg', 'png', 'pdf'],
        dialogTitle: 'Select VAT Certificate',
      );

      if (result == null || result.files.single.path == null) return;

      setState(() {
        _isProcessingVatOcr = true;
        _vatCertificatePath = result.files.single.path;
      });

      try {
        debugPrint(
          '[UserManagement] Using Hybrid OCR for VAT Certificate (Gemini with ML Kit fallback)',
        );

        final fields = await _hybridOcrService.extractVatCertificateFields(
          vatCertificatePath: result.files.single.path!,
        );

        _updateVatCertificateFieldsFromResult(fields);

        if (mounted) {
          _showSnackBar(
            'VAT certificate autofilled successfully!',
            isError: false,
          );
        }
      } catch (e) {
        debugPrint('Error in VAT Certificate OCR: $e');
        if (mounted) {
          _showSnackBar(
            'Error processing VAT certificate: ${e.toString()}',
            isError: true,
          );
        }
      } finally {
        if (mounted) {
          setState(() {
            _isProcessingVatOcr = false;
          });
        }
      }
    } catch (e) {
      setState(() => _isProcessingVatOcr = false);
      _showSnackBar(
        'Error selecting VAT certificate: ${e.toString()}',
        isError: true,
      );
    }
  }

  // Auto-process VAT Certificate OCR when file is uploaded
  Future<void> _processVatCertificateOcr() async {
    if (_vatCertificatePath == null) return;

    setState(() {
      _isProcessingVatOcr = true;
    });

    try {
      debugPrint(
        '[UserManagement] Auto-processing VAT Certificate OCR (Gemini with ML Kit fallback)',
      );

      final fields = await _hybridOcrService.extractVatCertificateFields(
        vatCertificatePath: _vatCertificatePath!,
      );

      _updateVatCertificateFieldsFromResult(fields);

      if (mounted) {
        _showSnackBar(
          'VAT certificate autofilled automatically!',
          isError: false,
        );
      }
    } catch (e) {
      debugPrint('Error in auto VAT Certificate OCR: $e');
      if (mounted) {
        _showSnackBar(
          'Auto-fill failed. Use "Scan VAT Cert" button to retry.',
          isError: true,
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isProcessingVatOcr = false;
        });
      }
    }
  }

  // Helper to update VAT certificate form fields from parsed results
  void _updateVatCertificateFieldsFromResult(Map<String, String?> fields) {
    if (fields['firmName'] != null && fields['firmName']!.isNotEmpty) {
      _firmNameController.text = fields['firmName']!;
    }
    if (fields['taxNumber'] != null && fields['taxNumber']!.isNotEmpty) {
      _taxRegistrationController.text = fields['taxNumber']!;
    }
    if (fields['registeredAddress'] != null &&
        fields['registeredAddress']!.isNotEmpty) {
      _vatAddressController.text = fields['registeredAddress']!;
    }
    if (fields['effectiveDate'] != null &&
        fields['effectiveDate']!.isNotEmpty) {
      _vatEffectiveDateController.text = fields['effectiveDate']!;
    }
  }

  Future<void> _scanCommercialLicense() async {
    try {
      final result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['jpg', 'jpeg', 'png', 'pdf'],
        dialogTitle: 'Select Commercial License',
      );

      if (result == null || result.files.single.path == null) return;

      setState(() {
        _isProcessingCommercialLicenceOcr = true;
        _commercialLicensePath = result.files.single.path;
      });

      try {
        debugPrint(
          '[UserManagement] Using Hybrid OCR for Commercial License (Gemini with ML Kit fallback)',
        );

        final fields = await _hybridOcrService.extractCommercialLicenseFields(
          commercialLicensePath: result.files.single.path!,
        );

        _updateCommercialLicenseFieldsFromResult(fields);

        if (mounted) {
          _showSnackBar(
            'Commercial license autofilled successfully!',
            isError: false,
          );
        }
      } catch (e) {
        debugPrint('Error in Commercial License OCR: $e');
        if (mounted) {
          _showSnackBar(
            'Error processing commercial license: ${e.toString()}',
            isError: true,
          );
        }
      } finally {
        if (mounted) {
          setState(() {
            _isProcessingCommercialLicenceOcr = false;
          });
        }
      }
    } catch (e) {
      setState(() => _isProcessingCommercialLicenceOcr = false);
      _showSnackBar(
        'Error selecting commercial license: ${e.toString()}',
        isError: true,
      );
    }
  }

  // Auto-process Commercial License OCR when file is uploaded
  Future<void> _processCommercialLicenseOcr() async {
    if (_commercialLicensePath == null) return;

    setState(() {
      _isProcessingCommercialLicenceOcr = true;
    });

    try {
      debugPrint(
        '[UserManagement] Auto-processing Commercial License OCR (Gemini with ML Kit fallback)',
      );

      final fields = await _hybridOcrService.extractCommercialLicenseFields(
        commercialLicensePath: _commercialLicensePath!,
      );

      _updateCommercialLicenseFieldsFromResult(fields);

      if (mounted) {
        _showSnackBar(
          'Commercial license autofilled automatically!',
          isError: false,
        );
      }
    } catch (e) {
      debugPrint('Error in auto Commercial License OCR: $e');
      if (mounted) {
        _showSnackBar(
          'Auto-fill failed. Use "Scan License" button to retry.',
          isError: true,
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isProcessingCommercialLicenceOcr = false;
        });
      }
    }
  }

  // Helper to update commercial license form fields from parsed results
  void _updateCommercialLicenseFieldsFromResult(Map<String, String?> fields) {
    if (fields['licenseNumber'] != null &&
        fields['licenseNumber']!.isNotEmpty) {
      _licenseNumberController.text = fields['licenseNumber']!;
    }
    if (fields['tradeName'] != null && fields['tradeName']!.isNotEmpty) {
      _tradeNameController.text = fields['tradeName']!;
    }
    if (fields['licenseType'] != null && fields['licenseType']!.isNotEmpty) {
      _licenseTypeController.text = fields['licenseType']!;
    }
    if (fields['issuingAuthority'] != null &&
        fields['issuingAuthority']!.isNotEmpty) {
      _issuingAuthorityController.text = fields['issuingAuthority']!;
    }
    if (fields['issueDate'] != null && fields['issueDate']!.isNotEmpty) {
      if (_ocrService.isValidDate(fields['issueDate']!)) {
        _establishmentDateController.text = fields['issueDate']!;
      }
    }
    if (fields['expiryDate'] != null && fields['expiryDate']!.isNotEmpty) {
      if (_ocrService.isValidDate(fields['expiryDate']!)) {
        _licenseExpiryDateController.text = fields['expiryDate']!;
      }
    }
    if (fields['address'] != null && fields['address']!.isNotEmpty) {
      _licenseAddressController.text = fields['address']!;
    }
    if (fields['responsiblePerson'] != null &&
        fields['responsiblePerson']!.isNotEmpty) {
      _responsiblePersonController.text = fields['responsiblePerson']!;
    }
  }

  void _showSnackBar(String message, {required bool isError}) {
    if (!mounted) return;
    if (isError) {
      AppSnackBar.showError(context, message);
    } else {
      AppSnackBar.showSuccess(context, message);
    }
  }

  @override
  void dispose() {
    _tabController.dispose();
    _contractorTypeController.dispose();
    _firstNameController.dispose();
    _middleNameController.dispose();
    _lastNameController.dispose();
    _mobileController.dispose();
    _emailController.dispose();
    _addressController.dispose();
    _areaController.dispose();
    _emiratesController.dispose();
    _emiratesIdController.dispose();
    _idNameController.dispose();
    _dateOfBirthController.dispose();
    _nationalityController.dispose();
    _companyDetailsController.dispose();
    _issueDateController.dispose();
    _expiryDateController.dispose();
    _occupationController.dispose();
    _accountHolderController.dispose();
    _ibanController.dispose();
    _bankNameController.dispose();
    _branchNameController.dispose();
    _bankAddressController.dispose();
    _licenseNumberController.dispose();
    _issuingAuthorityController.dispose();
    _licenseTypeController.dispose();
    _establishmentDateController.dispose();
    _licenseExpiryDateController.dispose();
    _tradeNameController.dispose();
    _responsiblePersonController.dispose();
    _licenseAddressController.dispose();
    _effectiveDateController.dispose();
    _firmNameController.dispose();
    _vatAddressController.dispose();
    _taxRegistrationController.dispose();
    _vatEffectiveDateController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: _buildAppBar(),
      body: Column(
        children: [
          _buildHeader(),
          _buildTabBar(),
          Expanded(
            child: _isLoadingDetails
                ? const Center(child: CircularProgressIndicator())
                : TabBarView(
                    controller: _tabController,
                    children: _getTabCount() == 5
                        ? [
                            _buildPersonalDetailsTab(),
                            _buildEmiratesIdTab(),
                            _buildBankDetailsTab(),
                            _buildLicenseTab(),
                            _buildVATTab(),
                          ]
                        : [
                            _buildPersonalDetailsTab(),
                            _buildEmiratesIdTab(),
                            _buildBankDetailsTab(),
                          ],
                  ),
          ),
          _buildBottomActions(),
        ],
      ),
    );
  }

  PreferredSizeWidget _buildAppBar() {
    return AppBar(
      elevation: 0,
      backgroundColor: Colors.white,
      foregroundColor: const Color(0xFF1E3A8A),
      leading: IconButton(
        icon: Icon(Icons.arrow_back_rounded, size: 24.sp),
        onPressed: () => Navigator.pop(context),
      ),
      title: Text(
        'Edit ${_getUserTypeDisplayName()}',
        style: TextStyle(
          fontWeight: FontWeight.w600,
          fontSize: 20.sp,
          color: const Color(0xFF1E3A8A),
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      width: double.infinity,
      margin: EdgeInsets.all(16.r),
      padding: EdgeInsets.all(20.r),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF1E3A8A), Color(0xFF3B82F6)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16.r),
        boxShadow: [
          BoxShadow(
            color: Colors.blue.withOpacity(0.15),
            blurRadius: 20.r,
            offset: Offset(0, 8.h),
          ),
        ],
      ),
      child: Row(
        children: [
          CircleAvatar(
            radius: 32.r,
            backgroundColor: Colors.white,
            child: Icon(
              _getTabCount() == 5
                  ? Icons.business_rounded
                  : Icons.format_paint_rounded,
              size: 32.sp,
              color: const Color(0xFF1E3A8A),
            ),
          ),
          SizedBox(width: 16.w),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  widget.user.name,
                  style: TextStyle(
                    fontSize: 18.sp,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                SizedBox(height: 4.h),
                Text(
                  'ID: ${widget.user.registrationId}',
                  style: TextStyle(fontSize: 13.sp, color: Colors.white70),
                ),
              ],
            ),
          ),
          Container(
            padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 6.h),
            decoration: BoxDecoration(
              color: _status == 'Active'
                  ? Colors.green.withOpacity(0.2)
                  : Colors.red.withOpacity(0.2),
              borderRadius: BorderRadius.circular(8.r),
              border: Border.all(
                color: _status == 'Active' ? Colors.green : Colors.red,
                width: 1.5,
              ),
            ),
            child: Text(
              _status,
              style: TextStyle(
                fontSize: 12.sp,
                fontWeight: FontWeight.w600,
                color: Colors.white,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTabBar() {
    return Container(
      margin: EdgeInsets.symmetric(horizontal: 16.w),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12.r),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 8.r,
            offset: Offset(0, 2.h),
          ),
        ],
      ),
      child: TabBar(
        controller: _tabController,
        isScrollable: true,
        labelColor: const Color(0xFF1E3A8A),
        unselectedLabelColor: Colors.grey.shade600,
        indicatorColor: const Color(0xFF1E3A8A),
        indicatorWeight: 3,
        labelStyle: TextStyle(fontSize: 14.sp, fontWeight: FontWeight.w600),
        unselectedLabelStyle: TextStyle(
          fontSize: 14.sp,
          fontWeight: FontWeight.w500,
        ),
        tabs: _getTabCount() == 5
            ? [
                Tab(text: 'Personal'),
                Tab(text: 'Emirates ID'),
                Tab(text: 'Bank'),
                Tab(text: 'License'),
                Tab(text: 'VAT'),
              ]
            : [
                Tab(text: 'Personal'),
                Tab(text: 'Emirates ID'),
                Tab(text: 'Bank'),
              ],
      ),
    );
  }

  Widget _buildPersonalDetailsTab() {
    return SingleChildScrollView(
      padding: EdgeInsets.all(16.r),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildSectionTitle('Personal Information'),
          SizedBox(height: 16.h),
          if (_getTabCount() == 5) ...[
            _buildTextField(
              'Contractor Type',
              _contractorTypeController,
              Icons.category,
            ),
            SizedBox(height: 16.h),
          ],
          _buildTextField('First Name *', _firstNameController, Icons.person),
          SizedBox(height: 16.h),
          _buildTextField(
            'Middle Name',
            _middleNameController,
            Icons.person_outline,
          ),
          SizedBox(height: 16.h),
          _buildTextField('Last Name *', _lastNameController, Icons.person),
          SizedBox(height: 16.h),
          _buildTextField(
            'Mobile Number *',
            _mobileController,
            Icons.phone,
            keyboardType: TextInputType.phone,
          ),
          SizedBox(height: 16.h),
          _buildTextField(
            'Emirates *',
            _emiratesController,
            Icons.location_city,
          ),
          SizedBox(height: 24.h),
          _buildSectionTitle('Status'),
          SizedBox(height: 12.h),
          Row(
            children: [
              _buildStatusChip('Active'),
              SizedBox(width: 12.w),
              _buildStatusChip('Inactive'),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildEmiratesIdTab() {
    return SingleChildScrollView(
      padding: EdgeInsets.all(16.r),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [_buildSectionTitle('Emirates ID Details')],
          ),
          SizedBox(height: 16.h),
          FileUploadWidget(
            key: const Key('user_emirates_id_front'),
            label: 'Emirates ID Front',
            icon: Icons.credit_card,
            allowedExtensions: const ['jpg', 'jpeg', 'png', 'pdf'],
            currentFilePath: _emiratesIdFrontFile,
            enableServerUpload: false,
            onFileSelected: (file) async {
              setState(() => _emiratesIdFrontFile = file);
              if (file != null) {
                final isPdf = file.toLowerCase().endsWith('.pdf');
                _showSnackBar(
                  '${isPdf ? 'PDF' : 'Image'} uploaded for Emirates ID Front',
                  isError: false,
                );
                // If both sides uploaded, run OCR to autofill fields
                if (_emiratesIdFrontFile != null &&
                    _emiratesIdBackFile != null) {
                  await _processEmiratesIdOcrWithRetry();
                }
              }
            },
          ),
          SizedBox(height: 16.h),
          FileUploadWidget(
            key: const Key('user_emirates_id_back'),
            label: 'Emirates ID Back',
            icon: Icons.credit_card,
            allowedExtensions: const ['jpg', 'jpeg', 'png', 'pdf'],
            currentFilePath: _emiratesIdBackFile,
            enableServerUpload: false,
            onFileSelected: (file) async {
              setState(() => _emiratesIdBackFile = file);
              if (file != null) {
                final isPdf = file.toLowerCase().endsWith('.pdf');
                _showSnackBar(
                  '${isPdf ? 'PDF' : 'Image'} uploaded for Emirates ID Back',
                  isError: false,
                );
                // If both sides uploaded, run OCR to autofill fields
                if (_emiratesIdFrontFile != null &&
                    _emiratesIdBackFile != null) {
                  await _processEmiratesIdOcrWithRetry();
                }
              }
            },
          ),
          SizedBox(height: 16.h),
          _buildTextField(
            'Emirates ID Number *',
            _emiratesIdController,
            Icons.credit_card,
          ),
          SizedBox(height: 16.h),
          _buildTextField('Name on ID *', _idNameController, Icons.badge),
          SizedBox(height: 16.h),
          _buildDateField('Date of Birth', _dateOfBirthController, Icons.cake),
          SizedBox(height: 16.h),
          _buildTextField('Nationality *', _nationalityController, Icons.flag),
          SizedBox(height: 16.h),
          _buildTextField(
            'Company Details (Employer) *',
            _companyDetailsController,
            Icons.business,
          ),
          SizedBox(height: 16.h),
          _buildDateField(
            'Issue Date *',
            _issueDateController,
            Icons.calendar_today,
          ),
          SizedBox(height: 16.h),
          _buildDateField('Expiry Date *', _expiryDateController, Icons.event),
          SizedBox(height: 16.h),
          _buildTextField('Occupation', _occupationController, Icons.work),
        ],
      ),
    );
  }

  Widget _buildBankDetailsTab() {
    return SingleChildScrollView(
      padding: EdgeInsets.all(16.r),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [_buildSectionTitle('Bank Account Details')],
          ),
          SizedBox(height: 16.h),
          FileUploadWidget(
            key: const Key('user_bank_document'),
            label: 'Bank Document',
            icon: Icons.account_balance,
            allowedExtensions: const ['jpg', 'jpeg', 'png', 'pdf'],
            currentFilePath: _bankDocumentPath,
            enableServerUpload: false,
            onFileSelected: (file) async {
              setState(() => _bankDocumentPath = file);
              if (file != null) {
                final isPdf = file.toLowerCase().endsWith('.pdf');
                _showSnackBar(
                  '${isPdf ? 'PDF' : 'Image'} uploaded for Bank Document',
                  isError: false,
                );
                // Auto-process bank document OCR
                await _processBankDocumentOcr();
              }
            },
          ),
          SizedBox(height: 16.h),
          _buildTextField(
            'Account Holder Name',
            _accountHolderController,
            Icons.account_circle,
          ),
          SizedBox(height: 16.h),
          _buildTextField(
            'IBAN Number',
            _ibanController,
            Icons.account_balance,
          ),
          SizedBox(height: 16.h),
          _buildTextField(
            'Bank Name',
            _bankNameController,
            Icons.account_balance_wallet,
          ),
          SizedBox(height: 16.h),
          _buildTextField(
            'Branch Name',
            _branchNameController,
            Icons.location_city,
          ),
          SizedBox(height: 16.h),
          _buildTextField(
            'Bank Address',
            _bankAddressController,
            Icons.location_on,
            maxLines: 3,
          ),
        ],
      ),
    );
  }

  Widget _buildLicenseTab() {
    return SingleChildScrollView(
      padding: EdgeInsets.all(16.r),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [_buildSectionTitle('Commercial License')],
          ),
          SizedBox(height: 16.h),
          FileUploadWidget(
            key: const Key('user_commercial_license'),
            label: 'Commercial License',
            icon: Icons.business_center,
            allowedExtensions: const ['jpg', 'jpeg', 'png', 'pdf'],
            currentFilePath: _commercialLicensePath,
            enableServerUpload: false,
            onFileSelected: (file) async {
              setState(() => _commercialLicensePath = file);
              if (file != null) {
                final isPdf = file.toLowerCase().endsWith('.pdf');
                _showSnackBar(
                  '${isPdf ? 'PDF' : 'Image'} uploaded for Commercial License',
                  isError: false,
                );
                // Auto-process commercial license OCR
                await _processCommercialLicenseOcr();
              }
            },
          ),
          SizedBox(height: 16.h),
          _buildTextField(
            'License Number *',
            _licenseNumberController,
            Icons.description,
          ),
          SizedBox(height: 16.h),
          _buildTextField(
            'Issuing Authority',
            _issuingAuthorityController,
            Icons.gavel,
          ),
          SizedBox(height: 16.h),
          _buildTextField(
            'License Type',
            _licenseTypeController,
            Icons.category,
          ),
          SizedBox(height: 16.h),
          _buildDateField(
            'Establishment Date',
            _establishmentDateController,
            Icons.calendar_today,
          ),
          SizedBox(height: 16.h),
          _buildDateField(
            'License Expiry Date',
            _licenseExpiryDateController,
            Icons.event,
          ),
          SizedBox(height: 16.h),
          _buildTextField('Trade Name', _tradeNameController, Icons.store),
          SizedBox(height: 16.h),
          _buildTextField(
            'Responsible Person',
            _responsiblePersonController,
            Icons.person_pin,
          ),
          SizedBox(height: 16.h),
          _buildTextField(
            'License Address',
            _licenseAddressController,
            Icons.location_on,
            maxLines: 3,
          ),
          SizedBox(height: 16.h),
          _buildDateField(
            'Effective Date',
            _effectiveDateController,
            Icons.calendar_month,
          ),
        ],
      ),
    );
  }

  Widget _buildVATTab() {
    return SingleChildScrollView(
      padding: EdgeInsets.all(16.r),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [_buildSectionTitle('VAT Certificate')],
          ),
          SizedBox(height: 8.h),
          Container(
            padding: EdgeInsets.all(12.r),
            decoration: BoxDecoration(
              color: Colors.blue.shade50,
              borderRadius: BorderRadius.circular(8.r),
              border: Border.all(color: Colors.blue.shade200),
            ),
            child: Row(
              children: [
                Icon(
                  Icons.info_outline,
                  color: Colors.blue.shade700,
                  size: 20.sp,
                ),
                SizedBox(width: 8.w),
                Expanded(
                  child: Text(
                    'Non-mandatory for turnover below 375,000 AED',
                    style: TextStyle(
                      fontSize: 12.sp,
                      color: Colors.blue.shade700,
                      fontStyle: FontStyle.italic,
                    ),
                  ),
                ),
              ],
            ),
          ),
          SizedBox(height: 16.h),
          FileUploadWidget(
            key: const Key('user_vat_certificate'),
            label: 'VAT Certificate',
            icon: Icons.receipt_long,
            allowedExtensions: const ['jpg', 'jpeg', 'png', 'pdf'],
            currentFilePath: _vatCertificatePath,
            enableServerUpload: false,
            isRequired: false,
            onFileSelected: (file) async {
              setState(() => _vatCertificatePath = file);
              if (file != null) {
                final isPdf = file.toLowerCase().endsWith('.pdf');
                _showSnackBar(
                  '${isPdf ? 'PDF' : 'Image'} uploaded for VAT Certificate',
                  isError: false,
                );
                // Auto-process VAT certificate OCR
                await _processVatCertificateOcr();
              }
            },
          ),
          SizedBox(height: 16.h),
          _buildTextField(
            'Firm Name',
            _firmNameController,
            Icons.business_center,
          ),
          SizedBox(height: 16.h),
          _buildTextField(
            'VAT Registered Address',
            _vatAddressController,
            Icons.location_on,
            maxLines: 3,
          ),
          SizedBox(height: 16.h),
          _buildTextField(
            'Tax Registration Number (TRN)',
            _taxRegistrationController,
            Icons.numbers,
          ),
          SizedBox(height: 8.h),
          Text(
            'Format: XXX-XXXXXXXXX-XXX (15 digits)',
            style: TextStyle(fontSize: 11.sp, color: Colors.grey.shade600),
          ),
          SizedBox(height: 16.h),
          _buildDateField(
            'VAT Effective Date',
            _vatEffectiveDateController,
            Icons.calendar_today,
          ),
        ],
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Text(
      title,
      style: TextStyle(
        fontSize: 16.sp,
        fontWeight: FontWeight.bold,
        color: const Color(0xFF1E3A8A),
      ),
    );
  }

  Widget _buildTextField(
    String label,
    TextEditingController controller,
    IconData icon, {
    TextInputType keyboardType = TextInputType.text,
    int maxLines = 1,
  }) {
    final bool useUaePhoneField = UaePhoneUtils.isPhoneField(
      keyboardType: keyboardType,
    );
    return TextField(
      controller: controller,
      keyboardType: keyboardType,
      inputFormatters: useUaePhoneField
          ? UaePhoneUtils.inputFormatters()
          : null,
      maxLines: maxLines,
      decoration: InputDecoration(
        labelText: label,
        labelStyle: TextStyle(fontSize: 14.sp, color: Colors.grey.shade600),
        prefixIcon: Icon(icon, size: 20.sp, color: const Color(0xFF1E3A8A)),
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
          borderSide: BorderSide(color: const Color(0xFF1E3A8A), width: 2.w),
        ),
        filled: true,
        fillColor: Colors.white,
        contentPadding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 16.h),
      ),
    );
  }

  Widget _buildDateField(
    String label,
    TextEditingController controller,
    IconData icon,
  ) {
    return TextField(
      controller: controller,
      readOnly: true,
      decoration: InputDecoration(
        labelText: label,
        labelStyle: TextStyle(fontSize: 14.sp, color: Colors.grey.shade600),
        prefixIcon: Icon(icon, size: 20.sp, color: const Color(0xFF1E3A8A)),
        suffixIcon: Icon(
          Icons.calendar_today_rounded,
          size: 18.sp,
          color: Colors.grey.shade600,
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
          borderSide: BorderSide(color: const Color(0xFF1E3A8A), width: 2.w),
        ),
        filled: true,
        fillColor: Colors.white,
        contentPadding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 16.h),
      ),
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
          controller.text =
              '${date.day.toString().padLeft(2, '0')}/${date.month.toString().padLeft(2, '0')}/${date.year}';
        }
      },
    );
  }

  Widget _buildStatusChip(String status) {
    final isSelected = _status == status;
    return Expanded(
      child: GestureDetector(
        onTap: () => setState(() => _status = status),
        child: Container(
          padding: EdgeInsets.symmetric(vertical: 12.h),
          decoration: BoxDecoration(
            color: isSelected
                ? (status == 'Active' ? Colors.green : Colors.red)
                : Colors.white,
            borderRadius: BorderRadius.circular(12.r),
            border: Border.all(
              color: isSelected
                  ? (status == 'Active' ? Colors.green : Colors.red)
                  : Colors.grey.shade300,
              width: 2.w,
            ),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                status == 'Active' ? Icons.check_circle : Icons.cancel,
                color: isSelected ? Colors.white : Colors.grey.shade600,
                size: 20.sp,
              ),
              SizedBox(width: 8.w),
              Text(
                status,
                style: TextStyle(
                  color: isSelected ? Colors.white : Colors.grey.shade600,
                  fontWeight: FontWeight.w600,
                  fontSize: 14.sp,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildBottomActions() {
    return Container(
      padding: EdgeInsets.all(16.r),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10.r,
            offset: Offset(0, -2.h),
          ),
        ],
      ),
      child: Row(
        children: [
          Expanded(
            child: OutlinedButton(
              onPressed: () => Navigator.pop(context),
              style: OutlinedButton.styleFrom(
                padding: EdgeInsets.symmetric(vertical: 16.h),
                side: BorderSide(color: Colors.grey.shade300, width: 2.w),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12.r),
                ),
              ),
              child: Text(
                'Cancel',
                style: TextStyle(
                  fontSize: 16.sp,
                  fontWeight: FontWeight.w600,
                  color: Colors.grey.shade700,
                ),
              ),
            ),
          ),
          SizedBox(width: 16.w),
          Expanded(
            flex: 2,
            child: ElevatedButton(
              onPressed: _saveChanges,
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF1E3A8A),
                padding: EdgeInsets.symmetric(vertical: 16.h),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12.r),
                ),
                elevation: 2,
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.save, size: 20.sp, color: Colors.white),
                  SizedBox(width: 8.w),
                  Text(
                    'Save Changes',
                    style: TextStyle(
                      fontSize: 16.sp,
                      fontWeight: FontWeight.w600,
                      color: Colors.white,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _saveChanges() async {
    // Show loading indicator
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => Center(
        child: Container(
          padding: EdgeInsets.all(24.r),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12.r),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              CircularProgressIndicator(),
              SizedBox(height: 16.h),
              Text('Saving changes...'),
            ],
          ),
        ),
      ),
    );

    try {
      final service = UserListService();

      // Get current logged-in user's ID for loginId field
      final currentUser = AuthManager.currentUser;
      final loginId = currentUser?.userID ?? currentUser?.emplName ?? 'SYSTEM';

      // Create update request
      final request = UserUpdateRequest(
        status: _status,
        contractorType: _contractorTypeController.text.isEmpty
            ? null
            : _contractorTypeController.text,
        firstName: _firstNameController.text,
        middleName: _middleNameController.text.isEmpty
            ? null
            : _middleNameController.text,
        lastName: _lastNameController.text,
        mobileNumber: _mobileController.text,
        address: _addressController.text,
        area: _areaController.text.isEmpty ? null : _areaController.text,
        emirates: _emiratesController.text,
        emiratesIdNumber: _emiratesIdController.text,
        idName: _idNameController.text,
        dateOfBirth: _dateOfBirthController.text.isEmpty
            ? null
            : _dateOfBirthController.text,
        nationality: _nationalityController.text,
        companyDetails: _companyDetailsController.text,
        issueDate: _issueDateController.text,
        expiryDate: _expiryDateController.text,
        occupation: _occupationController.text.isEmpty
            ? null
            : _occupationController.text,
        accountHolderName: _accountHolderController.text,
        ibanNumber: _ibanController.text,
        bankName: _bankNameController.text,
        branchName: _branchNameController.text,
        bankAddress: _bankAddressController.text.isEmpty
            ? null
            : _bankAddressController.text,
        licenseNumber: _licenseNumberController.text.isEmpty
            ? null
            : _licenseNumberController.text,
        issuingAuthority: _issuingAuthorityController.text.isEmpty
            ? null
            : _issuingAuthorityController.text,
        licenseType: _licenseTypeController.text.isEmpty
            ? null
            : _licenseTypeController.text,
        establishmentDate: _establishmentDateController.text.isEmpty
            ? null
            : _establishmentDateController.text,
        licenseExpiryDate: _licenseExpiryDateController.text.isEmpty
            ? null
            : _licenseExpiryDateController.text,
        tradeName: _tradeNameController.text.isEmpty
            ? null
            : _tradeNameController.text,
        responsiblePerson: _responsiblePersonController.text.isEmpty
            ? null
            : _responsiblePersonController.text,
        licenseAddress: _licenseAddressController.text.isEmpty
            ? null
            : _licenseAddressController.text,
        effectiveDate: _effectiveDateController.text.isEmpty
            ? null
            : _effectiveDateController.text,
        firmName: _firmNameController.text.isEmpty
            ? null
            : _firmNameController.text,
        vatAddress: _vatAddressController.text.isEmpty
            ? null
            : _vatAddressController.text,
        taxRegistrationNumber: _taxRegistrationController.text.isEmpty
            ? null
            : _taxRegistrationController.text,
        vatEffectiveDate: _vatEffectiveDateController.text.isEmpty
            ? null
            : _vatEffectiveDateController.text,
        loginId: loginId,
      );

      final success = await service.updateUser(widget.user.id, request);

      // Close loading dialog
      if (mounted) Navigator.pop(context);

      if (success) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Row(
                children: [
                  Icon(Icons.check_circle, color: Colors.white),
                  SizedBox(width: 12.w),
                  Text('Changes saved successfully!'),
                ],
              ),
              backgroundColor: Colors.green,
              behavior: SnackBarBehavior.floating,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8.r),
              ),
            ),
          );
          Navigator.pop(context, true); // Return true to indicate success
        }
      } else {
        throw Exception('Update failed');
      }
    } catch (e) {
      // Close loading dialog
      if (mounted) Navigator.pop(context);

      // Show error
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                Icon(Icons.error, color: Colors.white),
                SizedBox(width: 12.w),
                Expanded(child: Text('Error: ${e.toString()}')),
              ],
            ),
            backgroundColor: Colors.red,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8.r),
            ),
            duration: Duration(seconds: 5),
          ),
        );
      }
    }
  }
}
