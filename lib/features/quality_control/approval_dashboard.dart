import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;

// ============= MODELS =============

class ApprovalItem {
  final String id;
  final String name;
  final String type;
  final String date;
  final String status;
  final String avatar;

  ApprovalItem({
    required this.id,
    required this.name,
    required this.type,
    required this.date,
    required this.status,
    required this.avatar,
  });

  factory ApprovalItem.fromJson(Map<String, dynamic> json) {
    return ApprovalItem(
      id: json['id'] ?? '',
      name: json['name'] ?? '',
      type: json['type'] ?? 'Contractor',
      date: json['date'] ?? '',
      status: json['status'] ?? 'Pending',
      avatar: json['avatar'] ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'type': type,
      'date': date,
      'status': status,
      'avatar': avatar,
    };
  }
}

class ApprovalStats {
  final int totalPending;
  final int contractors;
  final int painters;
  final DateTime timestamp;

  ApprovalStats({
    required this.totalPending,
    required this.contractors,
    required this.painters,
    required this.timestamp,
  });

  factory ApprovalStats.fromJson(Map<String, dynamic> json) {
    return ApprovalStats(
      totalPending: json['totalPending'] ?? 0,
      contractors: json['contractors'] ?? 0,
      painters: json['painters'] ?? 0,
      timestamp: json['timestamp'] != null
          ? DateTime.parse(json['timestamp'])
          : DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'totalPending': totalPending,
      'contractors': contractors,
      'painters': painters,
      'timestamp': timestamp.toIso8601String(),
    };
  }
}

class ApprovalResponse {
  final bool success;
  final int page;
  final int pageSize;
  final int total;
  final List<ApprovalItem> items;

  ApprovalResponse({
    required this.success,
    required this.page,
    required this.pageSize,
    required this.total,
    required this.items,
  });

  factory ApprovalResponse.fromJson(Map<String, dynamic> json) {
    return ApprovalResponse(
      success: json['success'] ?? false,
      page: json['page'] ?? 1,
      pageSize: json['pageSize'] ?? 20,
      total: json['total'] ?? 0,
      items:
          (json['items'] as List<dynamic>?)
              ?.map((item) => ApprovalItem.fromJson(item))
              .toList() ??
          [],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'success': success,
      'page': page,
      'pageSize': pageSize,
      'total': total,
      'items': items.map((item) => item.toJson()).toList(),
    };
  }
}

class ApprovalActionRequest {
  final String inflCode;
  final String? actorId;

  ApprovalActionRequest({required this.inflCode, this.actorId});

  Map<String, dynamic> toJson() {
    return {'inflCode': inflCode, 'actorId': actorId};
  }
}

class RejectionActionRequest extends ApprovalActionRequest {
  final String? reason;

  RejectionActionRequest({required super.inflCode, super.actorId, this.reason});

  @override
  Map<String, dynamic> toJson() {
    return {'inflCode': inflCode, 'actorId': actorId, 'reason': reason};
  }
}

class ApprovalActionResponse {
  final bool success;
  final String message;
  final String? influencerCode;

  ApprovalActionResponse({
    required this.success,
    required this.message,
    this.influencerCode,
  });

  factory ApprovalActionResponse.fromJson(Map<String, dynamic> json) {
    return ApprovalActionResponse(
      success: json['success'] ?? false,
      message: json['message'] ?? '',
      influencerCode: json['influencerCode'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'success': success,
      'message': message,
      'influencerCode': influencerCode,
    };
  }
}

class RegistrationDetails {
  final bool success;
  final String id;
  final String name;
  final String type;
  final String mobile;
  final String email;
  final String submittedDate;
  final String status;
  final String fullName;
  final String address;
  final String reference;
  final String companyName;
  final String licenseNumber;
  final String trnNumber;
  final String accountHolder;
  final String iban;
  final String bankName;
  final String branch;
  final String avatar;

  RegistrationDetails({
    required this.success,
    required this.id,
    required this.name,
    required this.type,
    required this.mobile,
    required this.email,
    required this.submittedDate,
    required this.status,
    required this.fullName,
    required this.address,
    required this.reference,
    required this.companyName,
    required this.licenseNumber,
    required this.trnNumber,
    required this.accountHolder,
    required this.iban,
    required this.bankName,
    required this.branch,
    required this.avatar,
  });

  factory RegistrationDetails.fromJson(Map<String, dynamic> json) {
    return RegistrationDetails(
      success: json['success'] ?? false,
      id: json['id'] ?? '',
      name: json['name'] ?? '',
      type: json['type'] ?? '',
      mobile: json['mobile'] ?? '',
      email: json['email'] ?? '',
      submittedDate: json['submittedDate'] ?? '',
      status: json['status'] ?? '',
      fullName: json['fullName'] ?? '',
      address: json['address'] ?? '',
      reference: json['reference'] ?? '',
      companyName: json['companyName'] ?? '',
      licenseNumber: json['licenseNumber'] ?? '',
      trnNumber: json['trnNumber'] ?? '',
      accountHolder: json['accountHolder'] ?? '',
      iban: json['iban'] ?? '',
      bankName: json['bankName'] ?? '',
      branch: json['branch'] ?? '',
      avatar: json['avatar'] ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'success': success,
      'id': id,
      'name': name,
      'type': type,
      'mobile': mobile,
      'email': email,
      'submittedDate': submittedDate,
      'status': status,
      'fullName': fullName,
      'address': address,
      'reference': reference,
      'companyName': companyName,
      'licenseNumber': licenseNumber,
      'trnNumber': trnNumber,
      'accountHolder': accountHolder,
      'iban': iban,
      'bankName': bankName,
      'branch': branch,
      'avatar': avatar,
    };
  }
}

// ============= API SERVICE =============

class ApprovalService {
  static const String baseUrl = 'https://qa.birlawhite.com:55232';

  Future<ApprovalResponse> getPendingApprovals({
    String? search,
    String? type,
    int page = 1,
    int pageSize = 20,
    String? sort,
  }) async {
    try {
      final queryParams = <String, String>{
        'page': page.toString(),
        'pageSize': pageSize.toString(),
      };

      if (search != null && search.isNotEmpty) {
        queryParams['search'] = search;
      }
      if (type != null && type.isNotEmpty) {
        queryParams['type'] = type;
      }
      if (sort != null && sort.isNotEmpty) {
        queryParams['sort'] = sort;
      }

      final uri = Uri.parse(
        '$baseUrl/api/Approval/pending',
      ).replace(queryParameters: queryParams);

      final response = await http
          .get(
            uri,
            headers: {
              'Content-Type': 'application/json',
              'Accept': 'application/json',
            },
          )
          .timeout(const Duration(seconds: 30));

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        return ApprovalResponse.fromJson(data);
      } else {
        throw Exception(
          'Failed to load pending approvals: ${response.statusCode}',
        );
      }
    } catch (e) {
      throw Exception('Error fetching pending approvals: $e');
    }
  }

  Future<ApprovalStats> getApprovalStats() async {
    try {
      final uri = Uri.parse('$baseUrl/api/Approval/stats');

      final response = await http
          .get(
            uri,
            headers: {
              'Content-Type': 'application/json',
              'Accept': 'application/json',
            },
          )
          .timeout(const Duration(seconds: 30));

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        return ApprovalStats.fromJson(data);
      } else {
        throw Exception(
          'Failed to load approval stats: ${response.statusCode}',
        );
      }
    } catch (e) {
      throw Exception('Error fetching approval stats: $e');
    }
  }

  Future<ApprovalActionResponse> approveItem(
    String inflCode, {
    String? actorId,
  }) async {
    try {
      final request = ApprovalActionRequest(
        inflCode: inflCode,
        actorId: actorId,
      );

      final uri = Uri.parse('$baseUrl/api/Approval/approve');

      final response = await http
          .post(
            uri,
            headers: {
              'Content-Type': 'application/json',
              'Accept': 'application/json',
            },
            body: json.encode(request.toJson()),
          )
          .timeout(const Duration(seconds: 30));

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        return ApprovalActionResponse.fromJson(data);
      } else {
        throw Exception('Failed to approve item: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Error approving item: $e');
    }
  }

  Future<ApprovalActionResponse> rejectItem(
    String inflCode, {
    String? reason,
    String? actorId,
  }) async {
    try {
      final request = RejectionActionRequest(
        inflCode: inflCode,
        reason: reason,
        actorId: actorId,
      );

      final uri = Uri.parse('$baseUrl/api/Approval/reject');

      final response = await http
          .post(
            uri,
            headers: {
              'Content-Type': 'application/json',
              'Accept': 'application/json',
            },
            body: json.encode(request.toJson()),
          )
          .timeout(const Duration(seconds: 30));

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        return ApprovalActionResponse.fromJson(data);
      } else {
        throw Exception('Failed to reject item: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Error rejecting item: $e');
    }
  }

  Future<String> lookupInflCode(String identifier) async {
    try {
      final uri = Uri.parse('$baseUrl/api/Approval/lookup/$identifier');
      print('DEBUG API: Looking up inflCode for identifier: $identifier');
      print('DEBUG API: Lookup URL: $uri');

      final response = await http
          .get(
            uri,
            headers: {
              'Content-Type': 'application/json',
              'Accept': 'application/json',
            },
          )
          .timeout(const Duration(seconds: 30));

      print('DEBUG API: Lookup response status: ${response.statusCode}');
      print('DEBUG API: Lookup response body: ${response.body}');

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final inflCode = data['inflCode'] ?? '';
        print('DEBUG API: Found inflCode: $inflCode');
        return inflCode;
      } else if (response.statusCode == 404) {
        throw Exception('Person not found for identifier: $identifier');
      } else {
        throw Exception(
          'Failed to lookup inflCode: ${response.statusCode} - ${response.body}',
        );
      }
    } catch (e) {
      print('DEBUG API: Lookup exception: $e');
      throw Exception('Error looking up inflCode: $e');
    }
  }

  Future<RegistrationDetails> getRegistrationDetails(String inflCode) async {
    try {
      final uri = Uri.parse('$baseUrl/api/Approval/details/$inflCode');
      print('DEBUG API: Requesting URL: $uri');

      final response = await http
          .get(
            uri,
            headers: {
              'Content-Type': 'application/json',
              'Accept': 'application/json',
            },
          )
          .timeout(const Duration(seconds: 30));

      print('DEBUG API: Response status: ${response.statusCode}');
      print('DEBUG API: Response body: ${response.body}');

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        print('DEBUG API: Parsed data: $data');
        return RegistrationDetails.fromJson(data);
      } else if (response.statusCode == 404) {
        throw Exception(
          'Registration details not found for inflCode: $inflCode',
        );
      } else {
        throw Exception(
          'Failed to load registration details: ${response.statusCode} - ${response.body}',
        );
      }
    } catch (e) {
      print('DEBUG API: Exception occurred: $e');
      throw Exception('Error fetching registration details: $e');
    }
  }

  Future<RegistrationDetails> getRegistrationDetailsByIdentifier(
    String identifier,
  ) async {
    try {
      print('DEBUG: Getting details for identifier: $identifier');

      // First lookup the inflCode
      final inflCode = await lookupInflCode(identifier);

      // Then get the full details
      return await getRegistrationDetails(inflCode);
    } catch (e) {
      print('DEBUG: Error in getRegistrationDetailsByIdentifier: $e');
      rethrow;
    }
  }
}

// ============= UI COMPONENTS =============

class ModernDropdown extends StatelessWidget {
  final String label;
  final IconData icon;
  final List<String> items;
  final String value;
  final Function(String?) onChanged;

  const ModernDropdown({
    super.key,
    required this.label,
    required this.icon,
    required this.items,
    required this.value,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return DropdownButtonFormField<String>(
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: Icon(icon, size: 20.sp),
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
        fillColor: const Color(0xFFF8FAFC),
        contentPadding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 16.h),
      ),
      style: TextStyle(fontSize: 14.sp),
      value: value,
      items: items.map((String item) {
        return DropdownMenuItem<String>(
          value: item,
          child: Text(item, style: TextStyle(fontSize: 14.sp)),
        );
      }).toList(),
      onChanged: onChanged,
    );
  }
}

class ApprovalDashboardScreen extends StatefulWidget {
  const ApprovalDashboardScreen({super.key});

  @override
  State<ApprovalDashboardScreen> createState() =>
      _ApprovalDashboardScreenState();
}

class _ApprovalDashboardScreenState extends State<ApprovalDashboardScreen>
    with TickerProviderStateMixin {
  final ApprovalService _approvalService = ApprovalService();
  List<ApprovalItem> _pendingRegistrations = [];
  ApprovalStats? _stats;

  late AnimationController _mainController;
  late AnimationController _fabController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;
  late Animation<double> _scaleAnimation;
  final List<AnimationController> _cardControllers = [];
  final List<Animation<double>> _cardAnimations = [];
  final TextEditingController _searchController = TextEditingController();
  List<ApprovalItem> _filteredRegistrations = [];
  String _selectedFilter = 'All';
  bool _isLoading = false;
  String? _errorMessage;
  int _currentPage = 1;
  final int _pageSize = 20;
  bool _hasMore = true;

  @override
  void initState() {
    super.initState();
    _loadData();
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
    // Initialize card animations
    for (int i = 0; i < 3; i++) {
      final controller = AnimationController(
        duration: const Duration(milliseconds: 400),
        vsync: this,
      );
      final animation = CurvedAnimation(
        parent: controller,
        curve: Curves.easeOutCubic,
      );
      _cardControllers.add(controller);
      _cardAnimations.add(animation);
      // Stagger the card animations
      Future.delayed(Duration(milliseconds: 200 + (i * 100)), () {
        if (mounted) controller.forward();
      });
    }
    _mainController.forward();
    _fabController.forward();
  }

  Future<void> _loadData() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final statsResult = _approvalService.getApprovalStats();
      final pendingResult = _approvalService.getPendingApprovals(
        page: _currentPage,
        pageSize: _pageSize,
        search: _searchController.text.isEmpty ? null : _searchController.text,
        type: _selectedFilter == 'All' ? null : _selectedFilter,
      );

      final results = await Future.wait([statsResult, pendingResult]);
      _stats = results[0] as ApprovalStats;
      final response = results[1] as ApprovalResponse;

      setState(() {
        _pendingRegistrations = response.items;
        _filteredRegistrations = response.items;
        _hasMore = response.items.length == _pageSize;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _errorMessage = e.toString();
        _isLoading = false;
      });
    }
  }

  Future<void> _refreshData() async {
    _currentPage = 1;
    await _loadData();
  }

  Future<void> _approveItem(ApprovalItem item) async {
    try {
      // Get the inflCode for this item
      final inflCode = await _approvalService.lookupInflCode(item.id);

      // Approve the item
      await _approvalService.approveItem(inflCode);

      _refreshData();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('${item.name} approved successfully')),
      );
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Failed to approve: $e')));
    }
  }

  Future<void> _rejectItem(ApprovalItem item, String reason) async {
    try {
      // Get the inflCode for this item
      final inflCode = await _approvalService.lookupInflCode(item.id);

      // Reject the item with reason
      await _approvalService.rejectItem(inflCode, reason: reason);

      _refreshData();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('${item.name} rejected successfully')),
      );
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Failed to reject: $e')));
    }
  }

  @override
  void dispose() {
    _mainController.dispose();
    _fabController.dispose();
    _searchController.dispose();
    for (var controller in _cardControllers) {
      controller.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // Set system UI overlay style
    SystemChrome.setSystemUIOverlayStyle(
      const SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: Brightness.dark,
        statusBarBrightness: Brightness.light,
      ),
    );

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) {
        if (!didPop) {
          GoRouter.of(context).go('/home');
        }
      },
      child: Scaffold(
        backgroundColor: const Color(0xFFF8FAFC),
        appBar: _buildModernAppBar(),
        body: FadeTransition(
          opacity: _fadeAnimation,
          child: SlideTransition(
            position: _slideAnimation,
            child: Container(
              decoration: const BoxDecoration(color: Color(0xFFF8FAFC)),
              child: LayoutBuilder(
                builder: (context, constraints) {
                  final isMobile = constraints.maxWidth < 600;
                  final isTablet =
                      constraints.maxWidth >= 600 &&
                      constraints.maxWidth < 1200;
                  final isDesktop = constraints.maxWidth >= 1200;

                  return SingleChildScrollView(
                    padding: EdgeInsets.symmetric(
                      horizontal: isDesktop ? 48.w : (isTablet ? 32.w : 24.w),
                      vertical: 24.h,
                    ),
                    child: ScaleTransition(
                      scale: _scaleAnimation,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Header with animation
                          _buildAnimatedHeader(),
                          SizedBox(height: 32.h),
                          // Stats Cards
                          _buildStatsCards(isMobile, isTablet, isDesktop),
                          SizedBox(height: 32.h),
                          // Search and Filter
                          _buildSearchAndFilter(isMobile),
                          SizedBox(height: 32.h),
                          // Pending Registrations
                          _buildPendingRegistrations(isMobile),
                          SizedBox(height: 32.h),
                        ],
                      ),
                    ),
                  );
                },
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
      leading: Padding(
        padding: EdgeInsets.all(8.0.r),
        child: IconButton(
          icon: Icon(Icons.arrow_back_rounded, size: 24.sp),
          onPressed: () => GoRouter.of(context).go('/home'),
        ),
      ),
      title: Text(
        'Approval Dashboard',
        style: TextStyle(
          fontWeight: FontWeight.w600,
          fontSize: 20.sp,
          color: const Color(0xFF1E3A8A),
        ),
      ),
    );
  }

  Widget _buildAnimatedHeader() {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(32.r),
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
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Approval Dashboard',
            style: TextStyle(
              fontSize: 32.sp,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
          SizedBox(height: 12.h),
          Text(
            'Review and approve pending registrations',
            style: TextStyle(fontSize: 18.sp, color: Colors.white70),
          ),
        ],
      ),
    );
  }

  Widget _buildStatsCards(bool isMobile, bool isTablet, bool isDesktop) {
    if (_stats == null) {
      return const Center(child: CircularProgressIndicator());
    }

    final stats = [
      {
        'title': 'Total Pending',
        'value': _stats!.totalPending.toString(),
        'icon': Icons.hourglass_top_rounded,
        'color': Colors.blue,
        'change': '+5%',
        'isPositive': true,
      },
      {
        'title': 'Contractors',
        'value': _stats!.contractors.toString(),
        'icon': Icons.business_rounded,
        'color': Colors.blue,
        'change': '+3%',
        'isPositive': true,
      },
      {
        'title': 'Painters',
        'value': _stats!.painters.toString(),
        'icon': Icons.format_paint_rounded,
        'color': Colors.blue,
        'change': '+8%',
        'isPositive': true,
      },
    ];

    if (isMobile) {
      // Mobile layout - single column
      return Column(
        children: List.generate(stats.length, (index) {
          return Padding(
            padding: EdgeInsets.only(bottom: 16.h),
            child: _buildStatCard(
              stats[index]['title'] as String,
              stats[index]['value'] as String,
              stats[index]['icon'] as IconData,
              stats[index]['color'] as Color,
              stats[index]['change'] as String,
              stats[index]['isPositive'] as bool,
              _cardAnimations[index],
            ),
          );
        }),
      );
    } else if (isTablet) {
      // Tablet layout - 2x2 grid
      return GridView.builder(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 2,
          childAspectRatio: 1.2,
          crossAxisSpacing: 16.w,
          mainAxisSpacing: 16.h,
        ),
        itemCount: stats.length,
        itemBuilder: (context, index) {
          return _buildStatCard(
            stats[index]['title'] as String,
            stats[index]['value'] as String,
            stats[index]['icon'] as IconData,
            stats[index]['color'] as Color,
            stats[index]['change'] as String,
            stats[index]['isPositive'] as bool,
            _cardAnimations[index],
          );
        },
      );
    } else {
      // Desktop layout - single row
      return Row(
        children: List.generate(stats.length, (index) {
          return Expanded(
            child: Padding(
              padding: EdgeInsets.only(
                right: index < stats.length - 1 ? 16.w : 0,
              ),
              child: _buildStatCard(
                stats[index]['title'] as String,
                stats[index]['value'] as String,
                stats[index]['icon'] as IconData,
                stats[index]['color'] as Color,
                stats[index]['change'] as String,
                stats[index]['isPositive'] as bool,
                _cardAnimations[index],
              ),
            ),
          );
        }),
      );
    }
  }

  Widget _buildStatCard(
    String title,
    String value,
    IconData icon,
    Color color,
    String change,
    bool isPositive,
    Animation<double> animation,
  ) {
    return ScaleTransition(
      scale: animation,
      child: Container(
        padding: EdgeInsets.all(20.r),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16.r),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.04),
              blurRadius: 16.r,
              offset: Offset(0, 4.h),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Container(
                  width: 48.w,
                  height: 48.h,
                  decoration: BoxDecoration(
                    color: color.withOpacity(0.1),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(icon, color: color, size: 24.sp),
                ),
                Container(
                  padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 4.h),
                  decoration: BoxDecoration(
                    color: isPositive
                        ? Colors.green.withOpacity(0.1)
                        : Colors.red.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12.r),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        isPositive
                            ? Icons.trending_up_rounded
                            : Icons.trending_down_rounded,
                        color: isPositive ? Colors.green : Colors.red,
                        size: 14.sp,
                      ),
                      SizedBox(width: 4.w),
                      Text(
                        change,
                        style: TextStyle(
                          fontSize: 12.sp,
                          fontWeight: FontWeight.bold,
                          color: isPositive ? Colors.green : Colors.red,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            SizedBox(height: 16.h),
            Text(
              title,
              style: TextStyle(fontSize: 16.sp, color: Colors.grey.shade600),
            ),
            SizedBox(height: 8.h),
            Text(
              value,
              style: TextStyle(
                fontSize: 28.sp,
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSearchAndFilter(bool isMobile) {
    return _buildModernSection(
      title: 'Search & Filter',
      icon: Icons.search_rounded,
      children: [
        if (isMobile)
          Column(
            children: [
              TextField(
                controller: _searchController,
                style: TextStyle(fontSize: 14.sp),
                decoration: InputDecoration(
                  labelText: 'Search registrations',
                  labelStyle: TextStyle(fontSize: 14.sp),
                  prefixIcon: Icon(Icons.search_rounded, size: 20.sp),
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
                    borderSide: BorderSide(
                      color: const Color(0xFF1E3A8A),
                      width: 2.w,
                    ),
                  ),
                  filled: true,
                  fillColor: const Color(0xFFF8FAFC),
                  contentPadding: EdgeInsets.symmetric(
                    horizontal: 16.w,
                    vertical: 16.h,
                  ),
                ),
                onChanged: _filterRegistrations,
              ),
              SizedBox(height: 16.h),
              ModernDropdown(
                label: 'Filter by type',
                icon: Icons.filter_list,
                items: [
                  'All',
                  'Maintenance Contractor',
                  'Petty contractors',
                  'Painter',
                ],
                value: _selectedFilter,
                onChanged: (value) {
                  setState(() {
                    _selectedFilter = value!;
                    _performSearch(_searchController.text);
                  });
                },
              ),
            ],
          )
        else
          Row(
            children: [
              Expanded(
                flex: 3,
                child: TextField(
                  controller: _searchController,
                  style: TextStyle(fontSize: 14.sp),
                  decoration: InputDecoration(
                    labelText: 'Search registrations',
                    labelStyle: TextStyle(fontSize: 14.sp),
                    prefixIcon: Icon(Icons.search_rounded, size: 20.sp),
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
                      borderSide: BorderSide(
                        color: const Color(0xFF1E3A8A),
                        width: 2.w,
                      ),
                    ),
                    filled: true,
                    fillColor: const Color(0xFFF8FAFC),
                    contentPadding: EdgeInsets.symmetric(
                      horizontal: 16.w,
                      vertical: 16.h,
                    ),
                  ),
                  onChanged: _filterRegistrations,
                ),
              ),
              SizedBox(width: 16.w),
              Expanded(
                flex: 2,
                child: ModernDropdown(
                  label: 'Filter by type',
                  icon: Icons.filter_list,
                  items: [
                    'All',
                    'Maintenance Contractor',
                    'Petty contractors',
                    'Painter',
                  ],
                  value: _selectedFilter,
                  onChanged: (value) {
                    setState(() {
                      _selectedFilter = value!;
                      _performSearch(_searchController.text);
                    });
                  },
                ),
              ),
            ],
          ),
      ],
    );
  }

  Widget _buildPendingRegistrations(bool isMobile) {
    return _buildModernSection(
      title: 'Pending Registrations',
      icon: Icons.pending_actions_rounded,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Expanded(
              child: Text(
                'Registrations awaiting approval',
                style: TextStyle(fontSize: 16.sp, color: Colors.grey),
              ),
            ),
            Flexible(
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    '${_filteredRegistrations.length} items',
                    style: TextStyle(
                      fontSize: 16.sp,
                      color: Colors.grey.shade600,
                    ),
                  ),
                  SizedBox(width: 8.w),
                  IconButton(
                    icon: const Icon(Icons.refresh),
                    onPressed: _isLoading ? null : _refreshData,
                  ),
                ],
              ),
            ),
          ],
        ),
        SizedBox(height: 16.h),
        if (_isLoading)
          Center(
            child: Padding(
              padding: EdgeInsets.all(32.0.r),
              child: const CircularProgressIndicator(),
            ),
          )
        else if (_errorMessage != null)
          Container(
            height: 200,
            decoration: BoxDecoration(
              color: const Color(0xFFFEF2F2),
              borderRadius: BorderRadius.circular(12.r),
              border: Border.all(color: Colors.red.shade200),
            ),
            child: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.error_outline,
                    size: 64.sp,
                    color: Colors.red.shade400,
                  ),
                  SizedBox(height: 16.h),
                  Text(
                    'Error loading data',
                    style: TextStyle(
                      color: Colors.red.shade700,
                      fontSize: 16.sp,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  SizedBox(height: 8.h),
                  Text(
                    _errorMessage!,
                    style: TextStyle(
                      color: Colors.red.shade600,
                      fontSize: 14.sp,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  SizedBox(height: 16.h),
                  ElevatedButton(
                    onPressed: _refreshData,
                    child: const Text('Retry'),
                  ),
                ],
              ),
            ),
          )
        else if (_filteredRegistrations.isEmpty)
          Container(
            height: 200,
            decoration: BoxDecoration(
              color: const Color(0xFFF8FAFC),
              borderRadius: BorderRadius.circular(12.r),
              border: Border.all(color: Colors.grey.shade200),
            ),
            child: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.search_off_rounded,
                    size: 64.sp,
                    color: Colors.grey,
                  ),
                  SizedBox(height: 16.h),
                  Text(
                    'No registrations found',
                    style: TextStyle(color: Colors.grey, fontSize: 16.sp),
                  ),
                ],
              ),
            ),
          )
        else
          ListView.separated(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: _filteredRegistrations.length,
            separatorBuilder: (context, index) => const Divider(),
            itemBuilder: (context, index) {
              final registration = _filteredRegistrations[index];
              return _buildRegistrationTile(registration);
            },
          ),
      ],
    );
  }

  Widget _buildRegistrationTile(ApprovalItem registration) {
    return ListTile(
      contentPadding: EdgeInsets.zero,
      leading: CircleAvatar(
        backgroundColor: const Color(0xFF1E3A8A).withOpacity(0.1),
        child: Text(
          registration.avatar,
          style: TextStyle(
            color: const Color(0xFF1E3A8A),
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
      title: Text(
        registration.name,
        style: TextStyle(fontSize: 16.sp, fontWeight: FontWeight.w500),
        overflow: TextOverflow.ellipsis,
      ),
      subtitle: Text(
        '${registration.type} • ${registration.date}',
        style: TextStyle(fontSize: 14.sp, color: Colors.grey.shade600),
        overflow: TextOverflow.ellipsis,
      ),
      trailing: SizedBox(
        width: 120.w, // Fixed width to prevent overflow
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Flexible(
              child: Container(
                padding: EdgeInsets.symmetric(horizontal: 6.w, vertical: 2.h),
                decoration: BoxDecoration(
                  color: Colors.orange.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8.r),
                ),
                child: Text(
                  registration.status,
                  style: TextStyle(
                    color: Colors.orange,
                    fontSize: 10.sp,
                    fontWeight: FontWeight.bold,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ),
            SizedBox(width: 4.w),
            PopupMenuButton<String>(
              icon: Icon(Icons.more_vert, color: Colors.grey.shade400),
              onSelected: (value) async {
                if (value == 'approve') {
                  await _approveItem(registration);
                } else if (value == 'reject') {
                  _showRejectDialog(registration);
                }
              },
              itemBuilder: (context) => [
                PopupMenuItem(
                  value: 'approve',
                  child: Row(
                    children: [
                      const Icon(Icons.check, color: Colors.green),
                      SizedBox(width: 8.w),
                      const Text('Approve'),
                    ],
                  ),
                ),
                PopupMenuItem(
                  value: 'reject',
                  child: Row(
                    children: [
                      const Icon(Icons.close, color: Colors.red),
                      SizedBox(width: 8.w),
                      const Text('Reject'),
                    ],
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
      onTap: () async {
        // Navigate to details screen using GoRouter
        final result = await context.push('/registration-details/${registration.id}');
        // If result is true, it means an approval/rejection occurred, so refresh
        if (result == true) {
          _refreshData();
        }
      },
    );
  }

  void _showRejectDialog(ApprovalItem item) {
    final reasonController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Reject ${item.name}'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Please provide a reason for rejection:'),
            SizedBox(height: 16.h),
            TextField(
              controller: reasonController,
              maxLines: 3,
              decoration: const InputDecoration(
                hintText: 'Enter rejection reason...',
                border: OutlineInputBorder(),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.of(context).pop();
              _rejectItem(item, reasonController.text);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
            ),
            child: const Text('Reject'),
          ),
        ],
      ),
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
            color: Colors.black.withOpacity(0.04),
            blurRadius: 16.r,
            offset: Offset(0, 4.h),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Section Header
          Container(
            padding: EdgeInsets.all(24.r),
            decoration: BoxDecoration(
              color: const Color(0xFFF8FAFC),
              borderRadius: BorderRadius.vertical(top: Radius.circular(16.r)),
            ),
            child: Row(
              children: [
                Container(
                  width: 48.w,
                  height: 48.h,
                  decoration: BoxDecoration(
                    color: const Color(0xFF1E3A8A).withOpacity(0.1),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    icon,
                    color: const Color(0xFF1E3A8A),
                    size: 24.sp,
                  ),
                ),
                SizedBox(width: 16.w),
                Expanded(
                  child: Text(
                    title,
                    style: TextStyle(
                      fontSize: 20.sp,
                      fontWeight: FontWeight.bold,
                      color: const Color(0xFF1F2937),
                    ),
                  ),
                ),
              ],
            ),
          ),
          // Section Content
          Padding(
            padding: EdgeInsets.all(24.r),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: children,
            ),
          ),
        ],
      ),
    );
  }

  void _filterRegistrations(String query) {
    if (query.isEmpty && _selectedFilter == 'All') {
      _loadData();
      return;
    }

    _performSearch(query);
  }

  void _performSearch(String query) async {
    setState(() {
      _isLoading = true;
    });

    try {
      final response = await _approvalService.getPendingApprovals(
        page: 1,
        pageSize: _pageSize,
        search: query.isEmpty ? null : query,
        type: _selectedFilter == 'All' ? null : _selectedFilter,
      );

      setState(() {
        _filteredRegistrations = response.items;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _errorMessage = e.toString();
        _isLoading = false;
      });
    }
  }
}
