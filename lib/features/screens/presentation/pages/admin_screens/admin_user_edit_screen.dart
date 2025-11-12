import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:go_router/go_router.dart';
import 'package:rak_app/core/models/admin_user_models.dart';
import 'package:rak_app/core/services/admin_user_service.dart';
import 'package:rak_app/shared/widgets/user_search_widget.dart';

/// Admin User Edit Screen for managing user details by registration ID
class AdminUserEditScreen extends StatefulWidget {
  const AdminUserEditScreen({super.key});

  @override
  State<AdminUserEditScreen> createState() => _AdminUserEditScreenState();
}

class _AdminUserEditScreenState extends State<AdminUserEditScreen> {
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  final TextEditingController _searchController = TextEditingController();
  
  // Form controllers for all fields
  final Map<String, TextEditingController> _controllers = {};
  
  AdminUserData? _currentUser;
  bool _isLoading = false;
  bool _isUpdating = false;
  bool _hasSearched = false;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _initializeControllers();
  }

  void _initializeControllers() {
    // Initialize all possible field controllers
    final fields = [
      'firstName', 'middleName', 'lastName', 'contName',
      'address1', 'address2', 'address3', 'city', 'district', 'pincode',
      'emirates', 'email', 'mobileNumber',
      'accountHolderName', 'ibanNumber', 'bankName', 'branchName', 
      'bankAddress', 'bankAccountNo', 'bankIFSC',
      'firmName', 'vatAddress', 'taxRegistrationNumber', 'vatEffectiveDate',
      'licenseNumber', 'issuingAuthority', 'licenseType', 'establishmentDate',
      'licenseExpiryDate', 'tradeName', 'responsiblePerson', 'licenseAddress',
      'effectiveDate', 'emiratesIdNumber', 'idName', 'nationality', 'employer',
      'issueDate', 'expiryDate', 'occupation',
      'areaCode', 'inflType', 'reference', 'contractorType'
    ];
    
    for (final field in fields) {
      _controllers[field] = TextEditingController();
    }
  }

  @override
  void dispose() {
    _searchController.dispose();
    for (final controller in _controllers.values) {
      controller.dispose();
    }
    super.dispose();
  }

  Future<void> _searchUser([String? inflCode]) async {
    final searchCode = inflCode ?? _searchController.text.trim();
    
    if (!AdminUserService.isValidInflCode(searchCode)) {
      setState(() {
        _errorMessage = 'Please enter a valid registration ID';
        _hasSearched = true;
        _currentUser = null;
      });
      return;
    }

    setState(() {
      _isLoading = true;
      _errorMessage = null;
      _hasSearched = true;
    });

    try {
      final response = await AdminUserService.getUserByInflCode(searchCode);
      
      if (response.success && response.data != null) {
        setState(() {
          _currentUser = response.data;
          _errorMessage = null;
        });
        _populateForm();
      } else {
        setState(() {
          _currentUser = null;
          _errorMessage = response.message ?? 'User not found';
        });
      }
    } catch (e) {
      setState(() {
        _currentUser = null;
        _errorMessage = 'Error searching user: ${e.toString()}';
      });
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  void _onUserSelected(String inflCode) {
    _searchUser(inflCode);
  }

  void _populateForm() {
    if (_currentUser == null) return;
    
    final user = _currentUser!;
    
    // Helper function to clean values
    String cleanValue(String? value) {
      if (value == null || value.trim().isEmpty || value == '{}' || value == 'null') {
        return '';
      }
      return value.trim();
    }
    
    _controllers['firstName']?.text = cleanValue(user.firstName);
    _controllers['middleName']?.text = cleanValue(user.middleName);
    _controllers['lastName']?.text = cleanValue(user.lastName);
    _controllers['contName']?.text = cleanValue(user.contName);
    
    _controllers['address1']?.text = cleanValue(user.address1);
    _controllers['address2']?.text = cleanValue(user.address2);
    _controllers['address3']?.text = cleanValue(user.address3);
    _controllers['city']?.text = cleanValue(user.city);
    _controllers['district']?.text = cleanValue(user.district);
    _controllers['pincode']?.text = cleanValue(user.pincode);
    _controllers['emirates']?.text = cleanValue(user.emirates);
    _controllers['email']?.text = cleanValue(user.email);
    _controllers['mobileNumber']?.text = cleanValue(user.mobileNumber);
    
    _controllers['accountHolderName']?.text = cleanValue(user.accountHolderName);
    _controllers['ibanNumber']?.text = cleanValue(user.ibanNumber);
    _controllers['bankName']?.text = cleanValue(user.bankName);
    _controllers['branchName']?.text = cleanValue(user.branchName);
    _controllers['bankAddress']?.text = cleanValue(user.bankAddress);
    _controllers['bankAccountNo']?.text = cleanValue(user.bankAccountNo);
    _controllers['bankIFSC']?.text = cleanValue(user.bankIFSC);
    
    _controllers['firmName']?.text = cleanValue(user.firmName);
    _controllers['vatAddress']?.text = cleanValue(user.vatAddress);
    _controllers['taxRegistrationNumber']?.text = cleanValue(user.taxRegistrationNumber);
    _controllers['vatEffectiveDate']?.text = cleanValue(user.vatEffectiveDate);
    
    _controllers['licenseNumber']?.text = cleanValue(user.licenseNumber);
    _controllers['issuingAuthority']?.text = cleanValue(user.issuingAuthority);
    _controllers['licenseType']?.text = cleanValue(user.licenseType);
    _controllers['establishmentDate']?.text = cleanValue(user.establishmentDate);
    _controllers['licenseExpiryDate']?.text = cleanValue(user.licenseExpiryDate);
    _controllers['tradeName']?.text = cleanValue(user.tradeName);
    _controllers['responsiblePerson']?.text = cleanValue(user.responsiblePerson);
    _controllers['licenseAddress']?.text = cleanValue(user.licenseAddress);
    _controllers['effectiveDate']?.text = cleanValue(user.effectiveDate);
    
    _controllers['emiratesIdNumber']?.text = cleanValue(user.emiratesIdNumber);
    _controllers['idName']?.text = cleanValue(user.idHolder ?? user.idName);
    _controllers['nationality']?.text = cleanValue(user.nationality);
    _controllers['employer']?.text = cleanValue(user.employer);
    _controllers['issueDate']?.text = cleanValue(user.issueDate);
    _controllers['expiryDate']?.text = cleanValue(user.expiryDate);
    _controllers['occupation']?.text = cleanValue(user.occupation);
    
    _controllers['areaCode']?.text = cleanValue(user.areaCode);
    _controllers['inflType']?.text = cleanValue(user.inflType);
    _controllers['reference']?.text = cleanValue(user.reference);
    _controllers['contractorType']?.text = cleanValue(user.contractorType);
  }

  void _showUpdateData() {
    if (_currentUser == null) return;

    // Helper function to get non-empty value or null
    String? getValueOrNull(String key) {
      final value = _controllers[key]?.text.trim();
      if (value == null || value.isEmpty || value == '{}' || value == 'null') {
        return null;
      }
      return value;
    }

    // Create updated user data from form
    final updatedUser = AdminUserData(
      inflCode: _currentUser!.inflCode,
      firstName: getValueOrNull('firstName'),
      middleName: getValueOrNull('middleName'),
      lastName: getValueOrNull('lastName'),
      contName: getValueOrNull('contName'),
      address1: getValueOrNull('address1'),
      address2: getValueOrNull('address2'),
      address3: getValueOrNull('address3'),
      city: getValueOrNull('city'),
      district: getValueOrNull('district'),
      pincode: getValueOrNull('pincode'),
      emirates: getValueOrNull('emirates'),
      email: getValueOrNull('email'),
      mobileNumber: getValueOrNull('mobileNumber'),
      accountHolderName: getValueOrNull('accountHolderName'),
      ibanNumber: getValueOrNull('ibanNumber'),
      bankName: getValueOrNull('bankName'),
      branchName: getValueOrNull('branchName'),
      bankAddress: getValueOrNull('bankAddress'),
      bankAccountNo: getValueOrNull('bankAccountNo'),
      bankIFSC: getValueOrNull('bankIFSC'),
      firmName: getValueOrNull('firmName'),
      vatAddress: getValueOrNull('vatAddress'),
      taxRegistrationNumber: getValueOrNull('taxRegistrationNumber'),
      vatEffectiveDate: getValueOrNull('vatEffectiveDate'),
      licenseNumber: getValueOrNull('licenseNumber'),
      issuingAuthority: getValueOrNull('issuingAuthority'),
      licenseType: getValueOrNull('licenseType'),
      establishmentDate: getValueOrNull('establishmentDate'),
      licenseExpiryDate: getValueOrNull('licenseExpiryDate'),
      tradeName: getValueOrNull('tradeName'),
      responsiblePerson: getValueOrNull('responsiblePerson'),
      licenseAddress: getValueOrNull('licenseAddress'),
      effectiveDate: getValueOrNull('effectiveDate'),
      emiratesIdNumber: getValueOrNull('emiratesIdNumber'),
      idName: getValueOrNull('idName'),
      nationality: getValueOrNull('nationality'),
      employer: getValueOrNull('employer'),
      issueDate: getValueOrNull('issueDate'),
      expiryDate: getValueOrNull('expiryDate'),
      occupation: getValueOrNull('occupation'),
      areaCode: getValueOrNull('areaCode'),
      inflType: getValueOrNull('inflType'),
      reference: getValueOrNull('reference'),
      contractorType: getValueOrNull('contractorType'),
    );

    final updateData = updatedUser.toUpdateJson();
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Debug: Update Data'),
        content: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text('Registration ID: ${_currentUser!.inflCode}'),
              const SizedBox(height: 16),
              Text('Fields to update (${updateData.length}):'),
              const SizedBox(height: 8),
              ...updateData.entries.map((entry) => 
                Padding(
                  padding: const EdgeInsets.only(bottom: 4),
                  child: Text('${entry.key}: ${entry.value}'),
                ),
              ),
              if (updateData.isEmpty) 
                const Text('No fields to update (all empty or unchanged)'),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  Future<void> _updateUser() async {
    if (_currentUser == null || !_formKey.currentState!.validate()) return;

    setState(() {
      _isUpdating = true;
      _errorMessage = null;
    });

    try {
      // Helper function to get non-empty value or null
      String? getValueOrNull(String key) {
        final value = _controllers[key]?.text.trim();
        if (value == null || value.isEmpty || value == '{}' || value == 'null') {
          return null;
        }
        return value;
      }

      // Create updated user data from form
      final updatedUser = AdminUserData(
        inflCode: _currentUser!.inflCode,
        firstName: getValueOrNull('firstName'),
        middleName: getValueOrNull('middleName'),
        lastName: getValueOrNull('lastName'),
        contName: getValueOrNull('contName'),
        address1: getValueOrNull('address1'),
        address2: getValueOrNull('address2'),
        address3: getValueOrNull('address3'),
        city: getValueOrNull('city'),
        district: getValueOrNull('district'),
        pincode: getValueOrNull('pincode'),
        emirates: getValueOrNull('emirates'),
        email: getValueOrNull('email'),
        mobileNumber: getValueOrNull('mobileNumber'),
        accountHolderName: getValueOrNull('accountHolderName'),
        ibanNumber: getValueOrNull('ibanNumber'),
        bankName: getValueOrNull('bankName'),
        branchName: getValueOrNull('branchName'),
        bankAddress: getValueOrNull('bankAddress'),
        bankAccountNo: getValueOrNull('bankAccountNo'),
        bankIFSC: getValueOrNull('bankIFSC'),
        firmName: getValueOrNull('firmName'),
        vatAddress: getValueOrNull('vatAddress'),
        taxRegistrationNumber: getValueOrNull('taxRegistrationNumber'),
        vatEffectiveDate: getValueOrNull('vatEffectiveDate'),
        licenseNumber: getValueOrNull('licenseNumber'),
        issuingAuthority: getValueOrNull('issuingAuthority'),
        licenseType: getValueOrNull('licenseType'),
        establishmentDate: getValueOrNull('establishmentDate'),
        licenseExpiryDate: getValueOrNull('licenseExpiryDate'),
        tradeName: getValueOrNull('tradeName'),
        responsiblePerson: getValueOrNull('responsiblePerson'),
        licenseAddress: getValueOrNull('licenseAddress'),
        effectiveDate: getValueOrNull('effectiveDate'),
        emiratesIdNumber: getValueOrNull('emiratesIdNumber'),
        idName: getValueOrNull('idName'),
        nationality: getValueOrNull('nationality'),
        employer: getValueOrNull('employer'),
        issueDate: getValueOrNull('issueDate'),
        expiryDate: getValueOrNull('expiryDate'),
        occupation: getValueOrNull('occupation'),
        areaCode: getValueOrNull('areaCode'),
        inflType: getValueOrNull('inflType'),
        reference: getValueOrNull('reference'),
        contractorType: getValueOrNull('contractorType'),
      );

      print('DEBUG: Update data being sent: ${updatedUser.toUpdateJson()}'); // Debug log

      final response = await AdminUserService.updateUserByInflCode(
        _currentUser!.inflCode!,
        updatedUser,
      );

      if (response.success) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(response.message ?? 'User updated successfully'),
              backgroundColor: Colors.green,
              duration: const Duration(seconds: 3),
            ),
          );
          
          // Refresh user data to show updated values
          await _searchUser();
        }
      } else {
        setState(() {
          _errorMessage = response.message ?? 'Failed to update user';
        });
        
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(response.message ?? 'Failed to update user'),
              backgroundColor: Colors.red,
              duration: const Duration(seconds: 5),
            ),
          );
        }
      }
    } catch (e) {
      setState(() {
        _errorMessage = 'Error updating user: ${e.toString()}';
      });
    } finally {
      setState(() {
        _isUpdating = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Theme(
      data: Theme.of(context).copyWith(
        // Ensure proper text field theming
        inputDecorationTheme: InputDecorationTheme(
          filled: true,
          fillColor: Colors.white,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8.r),
            borderSide: BorderSide(color: Colors.grey[300]!),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8.r),
            borderSide: BorderSide(color: Colors.grey[300]!),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8.r),
            borderSide: const BorderSide(color: Color(0xFF3B82F6), width: 2),
          ),
        ),
        // Ensure proper text theme
        textTheme: Theme.of(context).textTheme.copyWith(
          bodyLarge: const TextStyle(color: Color(0xFF1F2937)),
          bodyMedium: const TextStyle(color: Color(0xFF1F2937)),
        ),
      ),
      child: Scaffold(
        backgroundColor: const Color(0xFFF8FAFC),
        appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        title: const Text(
          'Admin User Management',
          style: TextStyle(
            color: Color(0xFF1E3A8A),
            fontWeight: FontWeight.bold,
          ),
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Color(0xFF1E3A8A)),
          onPressed: () => context.pop(),
        ),
      ),
      body: Column(
        children: [
          // Search Section
          Container(
            padding: EdgeInsets.all(16.w),
            color: Colors.white,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Search User by Name',
                  style: TextStyle(
                    fontSize: 16.sp,
                    fontWeight: FontWeight.w600,
                    color: const Color(0xFF1F2937),
                  ),
                ),
                SizedBox(height: 12.h),
                UserSearchWidget(
                  controller: _searchController,
                  onUserSelected: _onUserSelected,
                  hintText: 'Search by Name (First, Middle, Last, or ID Holder)',
                  includeInactive: false,
                  isLoading: _isLoading,
                ),
                SizedBox(height: 8.h),
                Text(
                  'Search by any name field, contact name, or Registration ID',
                  style: TextStyle(
                    fontSize: 12.sp,
                    color: Colors.grey[600],
                  ),
                ),
              ],
            ),
          ),
          
          // Content Section
          Expanded(
            child: _buildContent(),
          ),
        ],
      ),
    ),
    );
  }

  Widget _buildContent() {
    if (!_hasSearched) {
      return _buildEmptyState();
    }
    
    if (_isLoading) {
      return const Center(
        child: CircularProgressIndicator(),
      );
    }
    
    if (_errorMessage != null) {
      return _buildErrorState();
    }
    
    if (_currentUser == null) {
      return _buildNotFoundState();
    }
    
    return _buildUserForm();
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.search,
            size: 64.sp,
            color: Colors.grey[400],
          ),
          SizedBox(height: 16.h),
          Text(
            'Enter a Registration ID to search for user',
            style: TextStyle(
              fontSize: 16.sp,
              color: Colors.grey[600],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildErrorState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.error_outline,
            size: 64.sp,
            color: Colors.red[400],
          ),
          SizedBox(height: 16.h),
          Text(
            _errorMessage!,
            style: TextStyle(
              fontSize: 16.sp,
              color: Colors.red[600],
            ),
            textAlign: TextAlign.center,
          ),
          SizedBox(height: 16.h),
          ElevatedButton(
            onPressed: _searchUser,
            child: const Text('Retry'),
          ),
        ],
      ),
    );
  }

  Widget _buildNotFoundState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.person_off,
            size: 64.sp,
            color: Colors.grey[400],
          ),
          SizedBox(height: 16.h),
          Text(
            'No user found with this Registration ID',
            style: TextStyle(
              fontSize: 16.sp,
              color: Colors.grey[600],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildUserForm() {
    return SingleChildScrollView(
      padding: EdgeInsets.all(16.w),
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // User Info Header
            _buildUserInfoHeader(),
            SizedBox(height: 24.h),
            
            // Personal Information
            _buildSection('Personal Information', [
              _buildTextField('First Name', 'firstName', required: true),
              _buildTextField('Middle Name', 'middleName'),
              _buildTextField('Last Name', 'lastName', required: true),
              _buildTextField('Contact Name', 'contName'),
            ]),
            
            // Address Information
            _buildSection('Address Information', [
              _buildTextField('Address Line 1', 'address1'),
              _buildTextField('Address Line 2', 'address2'),
              _buildTextField('Address Line 3', 'address3'),
              _buildTextField('City', 'city'),
              _buildTextField('District', 'district'),
              _buildTextField('Pincode', 'pincode'),
              _buildTextField('Emirates', 'emirates'),
              _buildTextField('Email', 'email', keyboardType: TextInputType.emailAddress),
              _buildTextField('Mobile Number', 'mobileNumber', keyboardType: TextInputType.phone),
            ]),
            
            // Bank Information
            _buildSection('Bank Information', [
              _buildTextField('Account Holder Name', 'accountHolderName'),
              _buildTextField('IBAN Number', 'ibanNumber'),
              _buildTextField('Bank Name', 'bankName'),
              _buildTextField('Branch Name', 'branchName'),
              _buildTextField('Bank Address', 'bankAddress'),
              _buildTextField('Bank Account No', 'bankAccountNo'),
              _buildTextField('Bank IFSC', 'bankIFSC'),
            ]),
            
            // VAT Information
            _buildSection('VAT Information', [
              _buildTextField('Firm Name', 'firmName'),
              _buildTextField('VAT Address', 'vatAddress'),
              _buildTextField('Tax Registration Number', 'taxRegistrationNumber'),
              _buildTextField('VAT Effective Date', 'vatEffectiveDate'),
            ]),
            
            // License Information
            _buildSection('License Information', [
              _buildTextField('License Number', 'licenseNumber'),
              _buildTextField('Issuing Authority', 'issuingAuthority'),
              _buildTextField('License Type', 'licenseType'),
              _buildTextField('Establishment Date', 'establishmentDate'),
              _buildTextField('License Expiry Date', 'licenseExpiryDate'),
              _buildTextField('Trade Name', 'tradeName'),
              _buildTextField('Responsible Person', 'responsiblePerson'),
              _buildTextField('License Address', 'licenseAddress'),
              _buildTextField('Effective Date', 'effectiveDate'),
            ]),
            
            // ID/KYC Information
            _buildSection('ID/KYC Information', [
              _buildTextField('Emirates ID Number', 'emiratesIdNumber'),
              _buildTextField('ID Holder Name', 'idName'),
              _buildTextField('Nationality', 'nationality'),
              _buildTextField('Employer', 'employer'),
              _buildTextField('Issue Date', 'issueDate'),
              _buildTextField('Expiry Date', 'expiryDate'),
              _buildTextField('Occupation', 'occupation'),
            ]),
            
            // Additional Information
            _buildSection('Additional Information', [
              _buildTextField('Area Code', 'areaCode'),
              _buildTextField('User Type', 'inflType'),
              _buildTextField('Reference', 'reference'),
              _buildTextField('Contractor Type', 'contractorType'),
            ]),
            
            SizedBox(height: 32.h),
            
            // Debug Button (for testing)
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () => _showUpdateData(),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF6B7280),
                  foregroundColor: Colors.white,
                  padding: EdgeInsets.symmetric(vertical: 12.h),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8.r),
                  ),
                ),
                child: Text(
                  'Debug: Show Update Data',
                  style: TextStyle(
                    fontSize: 14.sp,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ),
            
            SizedBox(height: 16.h),
            
            // Update Button
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _isUpdating ? null : _updateUser,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF10B981),
                  foregroundColor: Colors.white,
                  padding: EdgeInsets.symmetric(vertical: 16.h),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8.r),
                  ),
                ),
                child: _isUpdating
                    ? SizedBox(
                        width: 20.w,
                        height: 20.h,
                        child: const CircularProgressIndicator(
                          strokeWidth: 2,
                          valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                        ),
                      )
                    : Text(
                        'Update User Details',
                        style: TextStyle(
                          fontSize: 16.sp,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
              ),
            ),
            
            SizedBox(height: 32.h),
          ],
        ),
      ),
    );
  }

  Widget _buildUserInfoHeader() {
    return Container(
      padding: EdgeInsets.all(16.w),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12.r),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 5.r,
            offset: Offset(0, 2.h),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 60.w,
            height: 60.h,
            decoration: BoxDecoration(
              color: const Color(0xFF3B82F6).withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(30.r),
            ),
            child: Icon(
              _currentUser!.isPainter ? Icons.brush : Icons.business,
              color: const Color(0xFF3B82F6),
              size: 30.sp,
            ),
          ),
          SizedBox(width: 16.w),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _currentUser!.fullName.isNotEmpty 
                      ? _currentUser!.fullName 
                      : 'No Name',
                  style: TextStyle(
                    fontSize: 18.sp,
                    fontWeight: FontWeight.bold,
                    color: const Color(0xFF1F2937),
                  ),
                ),
                SizedBox(height: 4.h),
                Text(
                  'ID: ${_currentUser!.inflCode}',
                  style: TextStyle(
                    fontSize: 14.sp,
                    color: Colors.grey[600],
                  ),
                ),
                SizedBox(height: 4.h),
                Container(
                  padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 4.h),
                  decoration: BoxDecoration(
                    color: _currentUser!.isPainter 
                        ? const Color(0xFF10B981).withValues(alpha: 0.1)
                        : const Color(0xFFF59E0B).withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(12.r),
                  ),
                  child: Text(
                    _currentUser!.userTypeDisplay,
                    style: TextStyle(
                      fontSize: 12.sp,
                      fontWeight: FontWeight.w600,
                      color: _currentUser!.isPainter 
                          ? const Color(0xFF10B981)
                          : const Color(0xFFF59E0B),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSection(String title, List<Widget> fields) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: TextStyle(
            fontSize: 18.sp,
            fontWeight: FontWeight.bold,
            color: const Color(0xFF1F2937),
          ),
        ),
        SizedBox(height: 16.h),
        Container(
          padding: EdgeInsets.all(16.w),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12.r),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.05),
                blurRadius: 5.r,
                offset: Offset(0, 2.h),
              ),
            ],
          ),
          child: Column(
            children: fields,
          ),
        ),
        SizedBox(height: 24.h),
      ],
    );
  }

  Widget _buildTextField(
    String label,
    String key, {
    bool required = false,
    TextInputType? keyboardType,
  }) {
    return Padding(
      padding: EdgeInsets.only(bottom: 16.h),
      child: TextFormField(
        controller: _controllers[key],
        keyboardType: keyboardType,
        style: const TextStyle(
          color: Color(0xFF1F2937), // Ensure text color is dark
          fontSize: 16,
        ),
        decoration: InputDecoration(
          labelText: required ? '$label *' : label,
          labelStyle: TextStyle(
            color: Colors.grey[600],
            fontSize: 14,
          ),
          filled: true,
          fillColor: Colors.white, // Explicit white background
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8.r),
            borderSide: BorderSide(color: Colors.grey[300]!),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8.r),
            borderSide: BorderSide(color: Colors.grey[300]!),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8.r),
            borderSide: const BorderSide(color: Color(0xFF3B82F6), width: 2),
          ),
          errorBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8.r),
            borderSide: const BorderSide(color: Colors.red),
          ),
          focusedErrorBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8.r),
            borderSide: const BorderSide(color: Colors.red, width: 2),
          ),
          contentPadding: EdgeInsets.symmetric(
            horizontal: 16.w,
            vertical: 16.h,
          ),
        ),
        validator: required
            ? (value) {
                if (value == null || value.trim().isEmpty) {
                  return '$label is required';
                }
                return null;
              }
            : null,
      ),
    );
  }
}