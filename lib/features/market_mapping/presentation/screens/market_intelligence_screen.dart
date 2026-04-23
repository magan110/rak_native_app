/// Market Intelligence Screen
/// View and manage geo-tagged market intelligence

import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import '../../../../core/models/market_mapping_models.dart';
import '../../../../core/services/market_mapping_service.dart';

class MarketIntelligenceScreen extends StatefulWidget {
  const MarketIntelligenceScreen({super.key});

  @override
  State<MarketIntelligenceScreen> createState() =>
      _MarketIntelligenceScreenState();
}

class _MarketIntelligenceScreenState extends State<MarketIntelligenceScreen> {
  List<MarketIntelligence> _intelligence = [];
  IntelType? _selectedType;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);
    try {
      _intelligence = await MarketMappingService.getMarketIntelligence(
        type: _selectedType,
      );
      setState(() => _isLoading = false);
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
          'Market Intelligence',
          style: TextStyle(
            color: const Color(0xFF1E3A8A),
            fontSize: 18.sp,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
      body: Column(
        children: [
          _buildFilterChips(),
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _intelligence.isEmpty
                ? _buildEmptyState()
                : RefreshIndicator(
                    onRefresh: _loadData,
                    child: ListView.builder(
                      padding: EdgeInsets.all(16.w),
                      itemCount: _intelligence.length,
                      itemBuilder: (context, index) =>
                          _buildIntelCard(_intelligence[index]),
                    ),
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildFilterChips() {
    return Container(
      color: Colors.white,
      padding: EdgeInsets.all(16.w),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          children: [
            _buildChip('All', _selectedType == null, () {
              setState(() => _selectedType = null);
              _loadData();
            }),
            SizedBox(width: 8.w),
            _buildChip(
              'Opportunities',
              _selectedType == IntelType.opportunity,
              () {
                setState(() => _selectedType = IntelType.opportunity);
                _loadData();
              },
              Colors.green,
            ),
            SizedBox(width: 8.w),
            _buildChip('Threats', _selectedType == IntelType.threat, () {
              setState(() => _selectedType = IntelType.threat);
              _loadData();
            }, Colors.red),
            SizedBox(width: 8.w),
            _buildChip('Trends', _selectedType == IntelType.trend, () {
              setState(() => _selectedType = IntelType.trend);
              _loadData();
            }, Colors.purple),
            SizedBox(width: 8.w),
            _buildChip(
              'Observations',
              _selectedType == IntelType.observation,
              () {
                setState(() => _selectedType = IntelType.observation);
                _loadData();
              },
              Colors.blue,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildChip(
    String label,
    bool isSelected,
    VoidCallback onTap, [
    Color? color,
  ]) {
    final chipColor = color ?? const Color(0xFF1E3A8A);
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: EdgeInsets.symmetric(horizontal: 14.w, vertical: 8.h),
        decoration: BoxDecoration(
          color: isSelected ? chipColor : Colors.grey[100],
          borderRadius: BorderRadius.circular(20.r),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 12.sp,
            color: isSelected ? Colors.white : Colors.grey[700],
            fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
          ),
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.insights_outlined, size: 64.sp, color: Colors.grey[400]),
          SizedBox(height: 16.h),
          Text(
            'No intelligence reports',
            style: TextStyle(fontSize: 16.sp, color: Colors.grey[600]),
          ),
        ],
      ),
    );
  }

  Widget _buildIntelCard(MarketIntelligence intel) {
    Color typeColor;
    IconData typeIcon;
    String typeLabel;

    switch (intel.type) {
      case IntelType.opportunity:
        typeColor = Colors.green;
        typeIcon = Icons.trending_up;
        typeLabel = 'OPPORTUNITY';
        break;
      case IntelType.threat:
        typeColor = Colors.red;
        typeIcon = Icons.warning;
        typeLabel = 'THREAT';
        break;
      case IntelType.trend:
        typeColor = Colors.purple;
        typeIcon = Icons.show_chart;
        typeLabel = 'TREND';
        break;
      case IntelType.observation:
        typeColor = Colors.blue;
        typeIcon = Icons.visibility;
        typeLabel = 'OBSERVATION';
        break;
    }

    return Container(
      margin: EdgeInsets.only(bottom: 12.h),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12.r),
        border: Border(
          left: BorderSide(color: typeColor, width: 4.w),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Padding(
        padding: EdgeInsets.all(16.w),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: EdgeInsets.all(8.w),
                  decoration: BoxDecoration(
                    color: typeColor.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8.r),
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
                          Container(
                            padding: EdgeInsets.symmetric(
                              horizontal: 6.w,
                              vertical: 2.h,
                            ),
                            decoration: BoxDecoration(
                              color: typeColor.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(4.r),
                            ),
                            child: Text(
                              typeLabel,
                              style: TextStyle(
                                fontSize: 9.sp,
                                color: typeColor,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                          if (intel.isVerified) ...[
                            SizedBox(width: 8.w),
                            Icon(
                              Icons.verified,
                              size: 14.sp,
                              color: Colors.green,
                            ),
                            SizedBox(width: 2.w),
                            Text(
                              'Verified',
                              style: TextStyle(
                                fontSize: 10.sp,
                                color: Colors.green,
                              ),
                            ),
                          ],
                        ],
                      ),
                      SizedBox(height: 4.h),
                      Text(
                        intel.title,
                        style: TextStyle(
                          fontSize: 14.sp,
                          fontWeight: FontWeight.bold,
                          color: const Color(0xFF1F2937),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            SizedBox(height: 12.h),
            Text(
              intel.description,
              style: TextStyle(
                fontSize: 13.sp,
                color: Colors.grey[700],
                height: 1.4,
              ),
            ),
            if (intel.competitorName != null) ...[
              SizedBox(height: 12.h),
              Row(
                children: [
                  Icon(Icons.business, size: 14.sp, color: Colors.grey[400]),
                  SizedBox(width: 4.w),
                  Text(
                    intel.competitorName!,
                    style: TextStyle(
                      fontSize: 12.sp,
                      color: const Color(0xFF1E3A8A),
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ],
            SizedBox(height: 12.h),
            Divider(color: Colors.grey[200]),
            SizedBox(height: 8.h),
            Row(
              children: [
                if (intel.location != null) ...[
                  Icon(Icons.location_on, size: 14.sp, color: Colors.grey[400]),
                  SizedBox(width: 4.w),
                  Text(
                    intel.location!,
                    style: TextStyle(fontSize: 11.sp, color: Colors.grey[500]),
                  ),
                  SizedBox(width: 16.w),
                ],
                Icon(Icons.person, size: 14.sp, color: Colors.grey[400]),
                SizedBox(width: 4.w),
                Text(
                  intel.reportedBy,
                  style: TextStyle(fontSize: 11.sp, color: Colors.grey[500]),
                ),
                const Spacer(),
                Text(
                  DateFormat('dd MMM').format(intel.reportedAt),
                  style: TextStyle(fontSize: 11.sp, color: Colors.grey[500]),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
