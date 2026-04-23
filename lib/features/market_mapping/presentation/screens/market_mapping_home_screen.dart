/// Market Mapping Home Screen
/// Dashboard for competitor intelligence and market tracking

import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/models/market_mapping_models.dart';
import '../../../../core/services/market_mapping_service.dart';

class MarketMappingHomeScreen extends StatefulWidget {
  const MarketMappingHomeScreen({super.key});

  @override
  State<MarketMappingHomeScreen> createState() =>
      _MarketMappingHomeScreenState();
}

class _MarketMappingHomeScreenState extends State<MarketMappingHomeScreen> {
  List<Competitor> _competitors = [];
  List<DiscountActivity> _activeDiscounts = [];
  List<NewProductLaunch> _newLaunches = [];
  List<MarketIntelligence> _recentIntel = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);
    try {
      final results = await Future.wait([
        MarketMappingService.getCompetitors(),
        MarketMappingService.getDiscountActivities(activeOnly: true),
        MarketMappingService.getNewLaunches(),
        MarketMappingService.getMarketIntelligence(),
      ]);
      setState(() {
        _competitors = results[0] as List<Competitor>;
        _activeDiscounts = results[1] as List<DiscountActivity>;
        _newLaunches = results[2] as List<NewProductLaunch>;
        _recentIntel = (results[3] as List<MarketIntelligence>)
            .take(3)
            .toList();
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Color(0xFF1E3A8A)),
          onPressed: () => context.pop(),
        ),
        title: Text(
          'Market Mapping',
          style: TextStyle(
            color: const Color(0xFF1E3A8A),
            fontSize: 18.sp,
            fontWeight: FontWeight.bold,
          ),
        ),
        actions: [
          IconButton(
            icon: const Icon(
              Icons.add_circle_outline,
              color: Color(0xFF1E3A8A),
            ),
            onPressed: () => _showAddIntelDialog(),
            tooltip: 'Add Intelligence',
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _loadData,
              child: SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: EdgeInsets.all(16.w),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildQuickActions(),
                    SizedBox(height: 20.h),
                    _buildCompetitorSection(),
                    SizedBox(height: 20.h),
                    _buildActiveDiscountsSection(),
                    SizedBox(height: 20.h),
                    _buildNewLaunchesSection(),
                    SizedBox(height: 20.h),
                    _buildMarketIntelSection(),
                    SizedBox(height: 80.h),
                  ],
                ),
              ),
            ),
    );
  }

  Widget _buildQuickActions() {
    return Row(
      children: [
        Expanded(
          child: _buildActionCard(
            'Competitor\nPricing',
            Icons.price_change,
            const Color(0xFF1E3A8A),
            () => context.push('/competitor-pricing'),
          ),
        ),
        SizedBox(width: 12.w),
        Expanded(
          child: _buildActionCard(
            'New\nLaunches',
            Icons.new_releases,
            const Color(0xFF059669),
            () => context.push('/new-launches'),
          ),
        ),
        SizedBox(width: 12.w),
        Expanded(
          child: _buildActionCard(
            'Discount\nTracking',
            Icons.local_offer,
            const Color(0xFFDC2626),
            () => context.push('/discount-tracking'),
          ),
        ),
        SizedBox(width: 12.w),
        Expanded(
          child: _buildActionCard(
            'Market\nIntel',
            Icons.insights,
            const Color(0xFF7C3AED),
            () => context.push('/market-intelligence'),
          ),
        ),
      ],
    );
  }

  Widget _buildActionCard(
    String title,
    IconData icon,
    Color color,
    VoidCallback onTap,
  ) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: EdgeInsets.all(12.w),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12.r),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 10,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          children: [
            Container(
              padding: EdgeInsets.all(10.w),
              decoration: BoxDecoration(
                color: color.withOpacity(0.1),
                borderRadius: BorderRadius.circular(10.r),
              ),
              child: Icon(icon, color: color, size: 24.sp),
            ),
            SizedBox(height: 8.h),
            Text(
              title,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 10.sp,
                fontWeight: FontWeight.w600,
                color: const Color(0xFF374151),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCompetitorSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Tracked Competitors',
          style: TextStyle(
            fontSize: 16.sp,
            fontWeight: FontWeight.bold,
            color: const Color(0xFF1F2937),
          ),
        ),
        SizedBox(height: 12.h),
        SizedBox(
          height: 100.h,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            itemCount: _competitors.length,
            itemBuilder: (context, index) {
              final competitor = _competitors[index];
              return _buildCompetitorCard(competitor);
            },
          ),
        ),
      ],
    );
  }

  Widget _buildCompetitorCard(Competitor competitor) {
    final colors = [
      const Color(0xFF1E3A8A),
      const Color(0xFFDC2626),
      const Color(0xFF059669),
      const Color(0xFFF59E0B),
    ];
    final color = colors[_competitors.indexOf(competitor) % colors.length];

    return Container(
      width: 120.w,
      margin: EdgeInsets.only(right: 12.w),
      padding: EdgeInsets.all(12.w),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12.r),
        border: Border.all(color: color.withOpacity(0.3)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          CircleAvatar(
            radius: 20.r,
            backgroundColor: color.withOpacity(0.1),
            child: Text(
              competitor.brandName[0],
              style: TextStyle(
                color: color,
                fontWeight: FontWeight.bold,
                fontSize: 16.sp,
              ),
            ),
          ),
          SizedBox(height: 8.h),
          Text(
            competitor.brandName,
            style: TextStyle(
              fontSize: 11.sp,
              fontWeight: FontWeight.w600,
              color: const Color(0xFF1F2937),
            ),
            textAlign: TextAlign.center,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          Text(
            competitor.marketShare ?? '',
            style: TextStyle(
              fontSize: 10.sp,
              color: color,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActiveDiscountsSection() {
    if (_activeDiscounts.isEmpty) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Active Competitor Discounts',
              style: TextStyle(
                fontSize: 16.sp,
                fontWeight: FontWeight.bold,
                color: const Color(0xFF1F2937),
              ),
            ),
            TextButton(
              onPressed: () => context.push('/discount-tracking'),
              child: const Text('View All'),
            ),
          ],
        ),
        SizedBox(height: 8.h),
        ..._activeDiscounts.take(2).map((d) => _buildDiscountCard(d)),
      ],
    );
  }

  Widget _buildDiscountCard(DiscountActivity discount) {
    return Container(
      margin: EdgeInsets.only(bottom: 10.h),
      padding: EdgeInsets.all(12.w),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12.r),
        border: Border(
          left: BorderSide(color: Colors.red, width: 4.w),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  discount.competitorName,
                  style: TextStyle(
                    fontSize: 12.sp,
                    fontWeight: FontWeight.bold,
                    color: const Color(0xFF1E3A8A),
                  ),
                ),
                SizedBox(height: 4.h),
                Text(
                  discount.description,
                  style: TextStyle(
                    fontSize: 13.sp,
                    fontWeight: FontWeight.w600,
                    color: const Color(0xFF1F2937),
                  ),
                ),
                Text(
                  discount.productName,
                  style: TextStyle(fontSize: 11.sp, color: Colors.grey[600]),
                ),
              ],
            ),
          ),
          Container(
            padding: EdgeInsets.symmetric(horizontal: 10.w, vertical: 6.h),
            decoration: BoxDecoration(
              color: Colors.red.withOpacity(0.1),
              borderRadius: BorderRadius.circular(20.r),
            ),
            child: Text(
              'ACTIVE',
              style: TextStyle(
                fontSize: 10.sp,
                color: Colors.red,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNewLaunchesSection() {
    if (_newLaunches.isEmpty) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Recent Product Launches',
              style: TextStyle(
                fontSize: 16.sp,
                fontWeight: FontWeight.bold,
                color: const Color(0xFF1F2937),
              ),
            ),
            TextButton(
              onPressed: () => context.push('/new-launches'),
              child: const Text('View All'),
            ),
          ],
        ),
        SizedBox(height: 8.h),
        ..._newLaunches.take(2).map((l) => _buildLaunchCard(l)),
      ],
    );
  }

  Widget _buildLaunchCard(NewProductLaunch launch) {
    return Container(
      margin: EdgeInsets.only(bottom: 10.h),
      padding: EdgeInsets.all(12.w),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12.r),
        border: Border(
          left: BorderSide(color: Colors.green, width: 4.w),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  launch.productName,
                  style: TextStyle(
                    fontSize: 14.sp,
                    fontWeight: FontWeight.bold,
                    color: const Color(0xFF1F2937),
                  ),
                ),
              ),
              Container(
                padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 4.h),
                decoration: BoxDecoration(
                  color: Colors.green.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8.r),
                ),
                child: Text(
                  'NEW',
                  style: TextStyle(
                    fontSize: 10.sp,
                    color: Colors.green,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
          SizedBox(height: 4.h),
          Text(
            'by ${launch.competitorName}',
            style: TextStyle(
              fontSize: 12.sp,
              color: const Color(0xFF1E3A8A),
              fontWeight: FontWeight.w500,
            ),
          ),
          if (launch.description != null) ...[
            SizedBox(height: 4.h),
            Text(
              launch.description!,
              style: TextStyle(fontSize: 11.sp, color: Colors.grey[600]),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildMarketIntelSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Market Intelligence',
              style: TextStyle(
                fontSize: 16.sp,
                fontWeight: FontWeight.bold,
                color: const Color(0xFF1F2937),
              ),
            ),
            TextButton(
              onPressed: () => context.push('/market-intelligence'),
              child: const Text('View All'),
            ),
          ],
        ),
        SizedBox(height: 8.h),
        ..._recentIntel.map((intel) => _buildIntelCard(intel)),
      ],
    );
  }

  Widget _buildIntelCard(MarketIntelligence intel) {
    Color typeColor;
    IconData typeIcon;

    switch (intel.type) {
      case IntelType.opportunity:
        typeColor = Colors.green;
        typeIcon = Icons.trending_up;
        break;
      case IntelType.threat:
        typeColor = Colors.red;
        typeIcon = Icons.warning;
        break;
      case IntelType.trend:
        typeColor = Colors.purple;
        typeIcon = Icons.show_chart;
        break;
      case IntelType.observation:
        typeColor = Colors.blue;
        typeIcon = Icons.visibility;
        break;
    }

    return Container(
      margin: EdgeInsets.only(bottom: 10.h),
      padding: EdgeInsets.all(12.w),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12.r),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: EdgeInsets.all(10.w),
            decoration: BoxDecoration(
              color: typeColor.withOpacity(0.1),
              borderRadius: BorderRadius.circular(10.r),
            ),
            child: Icon(typeIcon, color: typeColor, size: 20.sp),
          ),
          SizedBox(width: 12.w),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        intel.title,
                        style: TextStyle(
                          fontSize: 13.sp,
                          fontWeight: FontWeight.bold,
                          color: const Color(0xFF1F2937),
                        ),
                      ),
                    ),
                    if (intel.isVerified)
                      Icon(Icons.verified, color: Colors.green, size: 16.sp),
                  ],
                ),
                SizedBox(height: 4.h),
                Text(
                  intel.description,
                  style: TextStyle(fontSize: 11.sp, color: Colors.grey[600]),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  void _showAddIntelDialog() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => _AddIntelForm(
        competitors: _competitors,
        onSubmit: (request) async {
          final result = await MarketMappingService.createMarketIntel(request);
          if (result != null) {
            await _loadData();
            if (mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Intelligence added successfully'),
                ),
              );
            }
          }
        },
      ),
    );
  }
}

// ============================================
// ADD INTEL FORM
// ============================================

class _AddIntelForm extends StatefulWidget {
  final List<Competitor> competitors;
  final Function(CreateMarketIntelRequest) onSubmit;

  const _AddIntelForm({required this.competitors, required this.onSubmit});

  @override
  State<_AddIntelForm> createState() => _AddIntelFormState();
}

class _AddIntelFormState extends State<_AddIntelForm> {
  final _formKey = GlobalKey<FormState>();
  IntelType _selectedType = IntelType.observation;
  String? _selectedCompetitorId;
  final _titleController = TextEditingController();
  final _descriptionController = TextEditingController();
  bool _isSubmitting = false;

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      height: MediaQuery.of(context).size.height * 0.7,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(20.r)),
      ),
      child: Column(
        children: [
          Container(
            margin: EdgeInsets.only(top: 12.h),
            width: 40.w,
            height: 4.h,
            decoration: BoxDecoration(
              color: Colors.grey[300],
              borderRadius: BorderRadius.circular(2.r),
            ),
          ),
          Padding(
            padding: EdgeInsets.all(16.w),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Add Market Intelligence',
                  style: TextStyle(
                    fontSize: 18.sp,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.close),
                  onPressed: () => Navigator.pop(context),
                ),
              ],
            ),
          ),
          Expanded(
            child: Form(
              key: _formKey,
              child: SingleChildScrollView(
                padding: EdgeInsets.symmetric(horizontal: 16.w),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildLabel('Type'),
                    DropdownButtonFormField<IntelType>(
                      value: _selectedType,
                      decoration: _inputDecoration('Select type'),
                      items: IntelType.values.map((t) {
                        return DropdownMenuItem(
                          value: t,
                          child: Text(
                            t.name[0].toUpperCase() + t.name.substring(1),
                          ),
                        );
                      }).toList(),
                      onChanged: (v) => setState(() => _selectedType = v!),
                    ),
                    SizedBox(height: 16.h),

                    _buildLabel('Competitor (Optional)'),
                    DropdownButtonFormField<String>(
                      value: _selectedCompetitorId,
                      decoration: _inputDecoration('Select competitor'),
                      items: [
                        const DropdownMenuItem(
                          value: null,
                          child: Text('None'),
                        ),
                        ...widget.competitors.map(
                          (c) => DropdownMenuItem(
                            value: c.id,
                            child: Text(c.brandName),
                          ),
                        ),
                      ],
                      onChanged: (v) =>
                          setState(() => _selectedCompetitorId = v),
                    ),
                    SizedBox(height: 16.h),

                    _buildLabel('Title'),
                    TextFormField(
                      controller: _titleController,
                      decoration: _inputDecoration('Enter title'),
                      validator: (v) => v?.isEmpty == true ? 'Required' : null,
                    ),
                    SizedBox(height: 16.h),

                    _buildLabel('Description'),
                    TextFormField(
                      controller: _descriptionController,
                      decoration: _inputDecoration('Describe the intelligence'),
                      maxLines: 4,
                      validator: (v) => v?.isEmpty == true ? 'Required' : null,
                    ),
                    SizedBox(height: 24.h),

                    SizedBox(
                      width: double.infinity,
                      height: 50.h,
                      child: ElevatedButton(
                        onPressed: _isSubmitting ? null : _submit,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF1E3A8A),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12.r),
                          ),
                        ),
                        child: _isSubmitting
                            ? const CircularProgressIndicator(
                                color: Colors.white,
                              )
                            : Text(
                                'Submit',
                                style: TextStyle(
                                  fontSize: 16.sp,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.white,
                                ),
                              ),
                      ),
                    ),
                    SizedBox(height: 24.h),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLabel(String text) {
    return Padding(
      padding: EdgeInsets.only(bottom: 8.h),
      child: Text(
        text,
        style: TextStyle(
          fontSize: 13.sp,
          fontWeight: FontWeight.w600,
          color: const Color(0xFF374151),
        ),
      ),
    );
  }

  InputDecoration _inputDecoration(String hint) {
    return InputDecoration(
      hintText: hint,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10.r),
        borderSide: BorderSide(color: Colors.grey[300]!),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10.r),
        borderSide: BorderSide(color: Colors.grey[300]!),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10.r),
        borderSide: const BorderSide(color: Color(0xFF1E3A8A)),
      ),
      contentPadding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 14.h),
    );
  }

  void _submit() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isSubmitting = true);

    final request = CreateMarketIntelRequest(
      type: _selectedType,
      title: _titleController.text,
      description: _descriptionController.text,
      competitorId: _selectedCompetitorId,
    );

    widget.onSubmit(request);
    Navigator.pop(context);
  }
}
