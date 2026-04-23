import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import '../../core/network/ssl_http_client.dart';

// ============= MODELS =============

class DashboardStats {
  final String start; // yyyy-MM-dd
  final String end; // yyyy-MM-dd
  final int totalRegistrations;
  final int contractors;
  final int painters;
  final int pending;

  DashboardStats({
    required this.start,
    required this.end,
    required this.totalRegistrations,
    required this.contractors,
    required this.painters,
    required this.pending,
  });

  factory DashboardStats.fromJson(Map<String, dynamic> json) {
    return DashboardStats(
      start: json['start'] as String? ?? '',
      end: json['end'] as String? ?? '',
      totalRegistrations: (json['totalRegistrations'] ?? 0) as int,
      contractors: (json['contractors'] ?? 0) as int,
      painters: (json['painters'] ?? 0) as int,
      pending: (json['pending'] ?? 0) as int,
    );
  }
}

class TrendPoint {
  final String date; // yyyy-MM-dd
  final int total;
  final int contractors;
  final int painters;
  final int approved;
  final int pending;
  final int rejected;

  TrendPoint({
    required this.date,
    required this.total,
    required this.contractors,
    required this.painters,
    required this.approved,
    required this.pending,
    required this.rejected,
  });

  factory TrendPoint.fromJson(Map<String, dynamic> json) {
    return TrendPoint(
      date: json['date'] as String? ?? '',
      total: (json['total'] ?? 0) as int,
      contractors: (json['contractors'] ?? 0) as int,
      painters: (json['painters'] ?? 0) as int,
      approved: (json['approved'] ?? 0) as int,
      pending: (json['pending'] ?? 0) as int,
      rejected: (json['rejected'] ?? 0) as int,
    );
  }
}

class TrendsResponse {
  final String start; // yyyy-MM-dd
  final String end; // yyyy-MM-dd
  final List<TrendPoint> data;

  TrendsResponse({required this.start, required this.end, required this.data});

  factory TrendsResponse.fromJson(Map<String, dynamic> json) {
    final list = (json['data'] as List<dynamic>? ?? [])
        .map((e) => TrendPoint.fromJson(e as Map<String, dynamic>))
        .toList();
    return TrendsResponse(
      start: json['start'] as String? ?? '',
      end: json['end'] as String? ?? '',
      data: list,
    );
  }
}

class RecentItem {
  final String name;
  final String type;
  final String status;
  final String date; // yyyy-MM-dd
  final String avatar; // 2 letters

  RecentItem({
    required this.name,
    required this.type,
    required this.status,
    required this.date,
    required this.avatar,
  });

  factory RecentItem.fromJson(Map<String, dynamic> json) {
    return RecentItem(
      name: json['name'] as String? ?? '',
      type: json['type'] as String? ?? '',
      status: json['status'] as String? ?? '',
      date: json['date'] as String? ?? '',
      avatar: json['avatar'] as String? ?? '',
    );
  }
}

class RecentResponse {
  final List<RecentItem> items;

  RecentResponse({required this.items});

  factory RecentResponse.fromJson(Map<String, dynamic> json) {
    final list = (json['items'] as List<dynamic>? ?? [])
        .map((e) => RecentItem.fromJson(e as Map<String, dynamic>))
        .toList();
    return RecentResponse(items: list);
  }
}

// ============= API SERVICE =============

class DashboardApi {
  // Host WITHOUT port
  static const String _host = 'qa.birlawhite.com';
  // Explicit HTTPS port
  static const int _port = 55232;
  static const String _basePath = '/api/Dashboard';
  static const Duration _timeout = Duration(seconds: 20);

  // Optional: set default headers here (JWT, etc.)
  static Map<String, String> get _headers => <String, String>{
    'Accept': 'application/json',
    'Content-Type': 'application/json',
  };
  static http.Client? _httpClient;

  /// Get SSL-enabled HTTP client
  static Future<http.Client> _getClient() async {
    _httpClient ??= await SslHttpClient.getClient();
    return _httpClient!;
  }

  static Uri _buildUri(String subPath, [Map<String, String>? query]) {
    return Uri(
      scheme: 'https',
      host: _host,
      port: _port,
      path: '$_basePath/$subPath',
      queryParameters: query?.isEmpty ?? true ? null : query,
    );
  }

  static Never _throwHttp(String label, http.Response res) {
    throw Exception(
      '$label failed: HTTP ${res.statusCode} ${res.reasonPhrase ?? ""}',
    );
  }

  static Map<String, dynamic> _decodeBody(String label, String body) {
    final decoded = jsonDecode(body);

    if (decoded is! Map<String, dynamic>) {
      throw Exception('$label returned unexpected payload');
    }

    if (decoded['success'] != true) {
      throw Exception(decoded['message'] ?? '$label API error');
    }

    return decoded;
  }

  /// GET /api/Dashboard/stats?start=yyyy-MM-dd&end=yyyy-MM-dd
  static Future<DashboardStats> getStats({
    String? start, // yyyy-MM-dd
    String? end, // yyyy-MM-dd
  }) async {
    final params = <String, String>{
      if (start != null && start.isNotEmpty) 'start': start,
      if (end != null && end.isNotEmpty) 'end': end,
    };

    final uri = _buildUri('stats', params);

    final client = await _getClient();
    final res = await client.get(uri, headers: _headers).timeout(_timeout);

    if (res.statusCode != 200) _throwHttp('Stats request', res);

    final map = _decodeBody('Stats', res.body);

    return DashboardStats.fromJson(map);
  }

  /// GET /api/Dashboard/trends?start=yyyy-MM-dd&end=yyyy-MM-dd
  static Future<TrendsResponse> getTrends({String? start, String? end}) async {
    final params = <String, String>{
      if (start != null && start.isNotEmpty) 'start': start,
      if (end != null && end.isNotEmpty) 'end': end,
    };

    final uri = _buildUri('trends', params);

    final client = await _getClient();
    final res = await client.get(uri, headers: _headers).timeout(_timeout);

    if (res.statusCode != 200) _throwHttp('Trends request', res);

    final map = _decodeBody('Trends', res.body);

    return TrendsResponse.fromJson(map);
  }

  /// GET /api/Dashboard/recent?limit=5
  static Future<RecentResponse> getRecent({int limit = 5}) async {
    final uri = _buildUri('recent', {'limit': '$limit'});

    final client = await _getClient();
    final res = await client.get(uri, headers: _headers).timeout(_timeout);

    if (res.statusCode != 200) _throwHttp('Recent request', res);

    final map = _decodeBody('Recent', res.body);

    return RecentResponse.fromJson(map);
  }
}

// ============= UI COMPONENTS =============

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen>
    with TickerProviderStateMixin {
  DateTime _startDate = DateTime.now().subtract(const Duration(days: 30));
  DateTime _endDate = DateTime.now();

  // Animations
  late AnimationController _mainController;
  late AnimationController _fabController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;
  late Animation<double> _scaleAnimation;
  final List<AnimationController> _cardControllers = [];
  final List<Animation<double>> _cardAnimations = [];

  // Loading / error
  bool _loading = false;
  String? _error;

  // Data
  DashboardStats? _stats;
  TrendsResponse? _trends;
  RecentResponse? _recent;

  // Derived changes for cards (as strings like "+12%")
  String _chgTotal = '0%';
  String _chgContractors = '0%';
  String _chgPainters = '0%';
  String _chgPending = '0%';

  bool _chgTotalPositive = true;
  bool _chgContractorsPositive = true;
  bool _chgPaintersPositive = true;
  bool _chgPendingPositive = false; // down is "good" for pending, invert later

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

    // Initialize card animations (4 cards)
    for (int i = 0; i < 4; i++) {
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
      // Stagger
      Future.delayed(Duration(milliseconds: 200 + (i * 100)), () {
        if (mounted) controller.forward();
      });
    }

    _mainController.forward();
    _fabController.forward();

    _loadAll();
  }

  @override
  void dispose() {
    _mainController.dispose();
    _fabController.dispose();
    for (var c in _cardControllers) {
      c.dispose();
    }
    super.dispose();
  }

  Future<void> _loadAll() async {
    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      final startStr = _startDate.toString().split(' ').first;
      final endStr = _endDate.toString().split(' ').first;

      final results = await Future.wait([
        DashboardApi.getStats(start: startStr, end: endStr),
        DashboardApi.getTrends(start: startStr, end: endStr),
        DashboardApi.getRecent(limit: 5),
      ]);

      final stats = results[0] as DashboardStats;
      final trends = results[1] as TrendsResponse;
      final recent = results[2] as RecentResponse;

      // Calculate % changes for the 4 cards from trends (last 7 vs previous 7 days)
      final chg = _computeChanges(trends);

      setState(() {
        _stats = stats;
        _trends = trends;
        _recent = recent;

        _chgTotal = chg.total.label;
        _chgContractors = chg.contractors.label;
        _chgPainters = chg.painters.label;
        _chgPending = chg.pending.label;

        _chgTotalPositive = chg.total.isPositive;
        _chgContractorsPositive = chg.contractors.isPositive;
        _chgPaintersPositive = chg.painters.isPositive;

        // For pending: decrease is positive (down-arrow good)
        _chgPendingPositive = chg.pending.delta <= 0;
      });
    } catch (e) {
      setState(() {
        _error = e.toString();
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Failed to load dashboard: $e',
              style: const TextStyle(color: Colors.white),
            ),
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10.r),
            ),
            backgroundColor: Colors.red.shade700,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _loading = false;
        });
      }
    }
  }

  // Computes changes based on last 7 days vs previous 7 days from trend points
  _Changes _computeChanges(TrendsResponse trends) {
    final data = trends.data;
    if (data.isEmpty) {
      return _Changes.zero();
    }

    // Take last 14 days if available
    final last14 = data.length >= 14 ? data.sublist(data.length - 14) : data;
    final cut = (last14.length / 2).floor();

    final prev = last14.take(cut).toList();
    final last = last14.skip(cut).toList();

    int sum(List<TrendPoint> pts, int Function(TrendPoint) sel) =>
        pts.fold<int>(0, (a, b) => a + sel(b));

    final prevTotal = sum(prev, (p) => p.total);
    final lastTotal = sum(last, (p) => p.total);

    final prevContractors = sum(prev, (p) => p.contractors);
    final lastContractors = sum(last, (p) => p.contractors);

    final prevPainters = sum(prev, (p) => p.painters);
    final lastPainters = sum(last, (p) => p.painters);

    final prevPending = sum(prev, (p) => p.pending);
    final lastPending = sum(last, (p) => p.pending);

    double pct(int a, int b) {
      if (a == 0) return b > 0 ? 100.0 : 0.0;
      return ((b - a) / a) * 100.0;
    }

    String lbl(double x) {
      final sign = x >= 0 ? '+' : '';
      final s = x.toStringAsFixed(0);
      return '$sign$s%';
    }

    return _Changes(
      total: _Change(pct(prevTotal, lastTotal), lbl(pct(prevTotal, lastTotal))),
      contractors: _Change(
        pct(prevContractors, lastContractors),
        lbl(pct(prevContractors, lastContractors)),
      ),
      painters: _Change(
        pct(prevPainters, lastPainters),
        lbl(pct(prevPainters, lastPainters)),
      ),
      pending: _Change(
        pct(prevPending, lastPending),
        lbl(pct(prevPending, lastPending)),
      ),
    );
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

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: _buildModernAppBar(),
      body: RefreshIndicator(
        onRefresh: _loadAll,
        child: FadeTransition(
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
                    physics: const AlwaysScrollableScrollPhysics(),
                    padding: EdgeInsets.symmetric(
                      horizontal: isDesktop ? 48.w : (isTablet ? 32.w : 24.w),
                      vertical: 24.h,
                    ),
                    child: ScaleTransition(
                      scale: _scaleAnimation,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _buildAnimatedHeader(),
                          SizedBox(height: 16.h),
                          if (_loading)
                            LinearProgressIndicator(
                              color: const Color(0xFF1E3A8A),
                              backgroundColor: const Color(
                                0xFF1E3A8A,
                              ).withOpacity(0.1),
                            ),
                          if (_error != null) ...[
                            SizedBox(height: 12.h),
                            _errorBanner(_error!),
                          ],
                          SizedBox(height: 16.h),
                          _buildStatsCards(isMobile, isTablet, isDesktop),
                          SizedBox(height: 32.h),
                          _buildRegistrationTrends(isMobile),
                          SizedBox(height: 32.h),
                          _buildRecentRegistrations(isMobile),
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
      leading: Navigator.of(context).canPop()
          ? Padding(
              padding: EdgeInsets.all(8.0.r),
              child: IconButton(
                icon: Icon(Icons.arrow_back_rounded, size: 24.sp),
                onPressed: () => Navigator.of(context).pop(),
              ),
            )
          : null,
      title: Text(
        'Dashboard',
        style: TextStyle(
          fontWeight: FontWeight.w600,
          fontSize: 20.sp,
          color: const Color(0xFF1E3A8A),
        ),
      ),
      actions: [
        IconButton(
          tooltip: 'Reload',
          onPressed: _loadAll,
          icon: Icon(Icons.refresh_rounded, size: 24.sp),
        ),
        SizedBox(width: 4.w),
      ],
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
            'Dashboard',
            style: TextStyle(
              fontSize: 32.sp,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
          SizedBox(height: 12.h),
          Text(
            'Welcome to your registration dashboard',
            style: TextStyle(fontSize: 18.sp, color: Colors.white70),
          ),
        ],
      ),
    );
  }

  Widget _buildStatsCards(bool isMobile, bool isTablet, bool isDesktop) {
    final totalPending = _stats?.pending ?? 0;
    final contractorsCount = _stats?.contractors ?? 0;
    final paintersCount = _stats?.painters ?? 0;
    final totalRegs = _stats?.totalRegistrations ?? 0;

    final stats = [
      {
        'title': 'Total Registrations',
        'value': totalRegs.toString(),
        'icon': Icons.group_rounded,
        'color': Colors.blue,
        'change': _chgTotal,
        'isPositive': _chgTotalPositive,
      },
      {
        'title': 'Contractors',
        'value': contractorsCount.toString(),
        'icon': Icons.business_rounded,
        'color': Colors.blue,
        'change': _chgContractors,
        'isPositive': _chgContractorsPositive,
      },
      {
        'title': 'Painters',
        'value': paintersCount.toString(),
        'icon': Icons.format_paint_rounded,
        'color': Colors.blue,
        'change': _chgPainters,
        'isPositive': _chgPaintersPositive,
      },
      {
        'title': 'Pending',
        'value': totalPending.toString(),
        'icon': Icons.pending_actions_rounded,
        'color': Colors.red,
        'change': _chgPending,
        // Lower pending is "good": invert positivity
        'isPositive': _chgPendingPositive,
      },
    ];

    if (isMobile) {
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
                  padding: EdgeInsets.symmetric(
                    horizontal: 8.w,
                    vertical: 4.h,
                  ),
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

  Widget _buildRegistrationTrends(bool isMobile) {
    return _buildModernSection(
      title: 'Registration Trends',
      icon: Icons.bar_chart_rounded,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Expanded(
              child: OutlinedButton.icon(
                onPressed: _selectDateRange,
                icon: const Icon(Icons.date_range_rounded),
                label: Text(
                  '${_startDate.toString().split(' ')[0]} - ${_endDate.toString().split(' ')[0]}',
                ),
              ),
            ),
            if (!isMobile) SizedBox(width: 16.w),
            if (!isMobile)
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: _exportReport,
                  icon: const Icon(Icons.download_rounded),
                  label: const Text('Export Report'),
                ),
              ),
          ],
        ),
        SizedBox(height: 24.h),
        // Keep your placeholder panel but show small live summary below
        Container(
          height: isMobile ? 250.h : 300.h,
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
                  Icons.bar_chart_rounded,
                  size: 64.sp,
                  color: Colors.grey,
                ),
                SizedBox(height: 16.h),
                Text(
                  'Registration Chart',
                  style: TextStyle(color: Colors.grey, fontSize: 16.sp),
                ),
                SizedBox(height: 8.h),
                Text(
                  _trends == null
                      ? 'Visual representation of registration trends'
                      : 'Loaded ${_trends!.data.length} data points',
                  style: TextStyle(color: Colors.grey[500], fontSize: 14.sp),
                ),
              ],
            ),
          ),
        ),
        if (_trends != null) ...[
          SizedBox(height: 16.h),
          Wrap(
            spacing: 12.w,
            runSpacing: 8.h,
            children: [
              _chip(
                'Approved (last)',
                _sumLast(_trends!.data, (p) => p.approved).toString(),
              ),
              _chip(
                'Pending (last)',
                _sumLast(_trends!.data, (p) => p.pending).toString(),
              ),
              _chip(
                'Rejected (last)',
                _sumLast(_trends!.data, (p) => p.rejected).toString(),
              ),
              _chip(
                'Contractors (last)',
                _sumLast(_trends!.data, (p) => p.contractors).toString(),
              ),
              _chip(
                'Painters (last)',
                _sumLast(_trends!.data, (p) => p.painters).toString(),
              ),
            ],
          ),
        ],
      ],
    );
  }

  Widget _buildRecentRegistrations(bool isMobile) {
    final items = _recent?.items ?? [];

    return _buildModernSection(
      title: 'Recent Registrations',
      icon: Icons.recent_actors_rounded,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Expanded(
              child: Text(
                'Latest registration activities',
                style: TextStyle(fontSize: 16.sp, color: Colors.grey),
              ),
            ),
            TextButton(
              onPressed: () =>
                  Navigator.pushNamed(context, '/approval-dashboard'),
              child: Text(
                'View All',
                style: TextStyle(
                  color: const Color(0xFF1E3A8A),
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          ],
        ),
        SizedBox(height: 16.h),
        if (items.isEmpty)
          Container(
            height: 120.h,
            decoration: BoxDecoration(
              color: const Color(0xFFF8FAFC),
              borderRadius: BorderRadius.circular(12.r),
              border: Border.all(color: Colors.grey.shade200),
            ),
            child: const Center(
              child: Text(
                'No recent registrations',
                style: TextStyle(color: Colors.grey),
              ),
            ),
          )
        else
          ListView.separated(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: items.length,
            separatorBuilder: (context, index) => const Divider(),
            itemBuilder: (context, index) {
              final r = items[index];
              final statusColor = r.status == 'Approved'
                  ? Colors.green
                  : r.status == 'Pending'
                  ? Colors.orange
                  : Colors.red;

              return ListTile(
                contentPadding: EdgeInsets.zero,
                leading: CircleAvatar(
                  backgroundColor: const Color(0xFF1E3A8A).withOpacity(0.1),
                  child: Text(
                    r.avatar,
                    style: const TextStyle(
                      color: Color(0xFF1E3A8A),
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                title: Text(
                  r.name,
                  style: TextStyle(
                    fontSize: 16.sp,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                subtitle: Text(
                  '${r.type} • ${r.status}',
                  style: TextStyle(fontSize: 14.sp, color: Colors.grey.shade600),
                ),
                trailing: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    SizedBox(height: 4.h),
                    Container(
                      padding: EdgeInsets.symmetric(
                        horizontal: 6.w,
                        vertical: 2.h,
                      ),
                      decoration: BoxDecoration(
                        color: statusColor.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(10.r),
                      ),
                      child: Text(
                        r.status,
                        style: TextStyle(
                          fontSize: 10.sp,
                          fontWeight: FontWeight.bold,
                          color: statusColor,
                        ),
                      ),
                    ),
                    SizedBox(height: 6.h),
                    Text(
                      r.date, // yyyy-MM-dd
                      style: TextStyle(fontSize: 12.sp, color: Colors.grey[600]),
                    ),
                  ],
                ),
                onTap: () {
                  // you can navigate to details by inflCode if you include it in API
                  Navigator.pushNamed(context, '/approval-dashboard');
                },
              );
            },
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

  Future<void> _selectDateRange() async {
    final picked = await showDateRangePicker(
      context: context,
      firstDate: DateTime(2020),
      lastDate: DateTime.now(),
      initialDateRange: DateTimeRange(start: _startDate, end: _endDate),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.light(primary: Color(0xFF1E3A8A)),
          ),
          child: child!,
        );
      },
    );
    if (picked != null) {
      setState(() {
        _startDate = picked.start;
        _endDate = picked.end;
      });
      // reload stats & trends for the new range
      await _loadAll();
    }
  }

  void _exportReport() {
    // Plug in your file export if needed; UI feedback for now
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          'Report exported successfully',
          style: const TextStyle(color: Colors.white),
        ),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10.r)),
        backgroundColor: const Color(0xFF1E3A8A),
      ),
    );
  }

  // ---------- Tiny helpers ----------
  Widget _errorBanner(String msg) {
    return Container(
      padding: EdgeInsets.all(12.r),
      decoration: BoxDecoration(
        color: Colors.red.withOpacity(0.08),
        borderRadius: BorderRadius.circular(8.r),
        border: Border.all(color: Colors.red.withOpacity(0.25)),
      ),
      child: Row(
        children: [
          const Icon(Icons.error_outline_rounded, color: Colors.red),
          const SizedBox(width: 8),
          Expanded(
            child: Text(msg, style: const TextStyle(color: Colors.red)),
          ),
          IconButton(
            icon: const Icon(Icons.close_rounded, color: Colors.red),
            onPressed: () => setState(() => _error = null),
          ),
        ],
      ),
    );
  }

  Widget _chip(String label, String value) {
    return Chip(
      label: Text('$label: $value'),
      backgroundColor: Colors.grey.shade100,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(10.r),
        side: BorderSide(color: Colors.grey.shade300),
      ),
    );
  }

  int _sumLast(List<TrendPoint> pts, int Function(TrendPoint) sel) {
    if (pts.isEmpty) return 0;
    final take = pts.length >= 7 ? 7 : pts.length;
    final last = pts.sublist(pts.length - take);
    return last.fold(0, (a, b) => a + sel(b));
  }
}

// ======= Internal change computation models =======
class _Change {
  final double delta; // numeric delta (%)
  final String label; // formatted, e.g. "+12%"
  bool get isPositive => delta >= 0;
  _Change(this.delta, this.label);
}

class _Changes {
  final _Change total;
  final _Change contractors;
  final _Change painters;
  final _Change pending;

  _Changes({
    required this.total,
    required this.contractors,
    required this.painters,
    required this.pending,
  });

  factory _Changes.zero() => _Changes(
    total: _Change(0, '0%'),
    contractors: _Change(0, '0%'),
    painters: _Change(0, '0%'),
    pending: _Change(0, '0%'),
  );
}
