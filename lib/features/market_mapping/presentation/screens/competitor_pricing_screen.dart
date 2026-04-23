/// Competitor Pricing Screen
/// View and capture competitor product prices

import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import '../../../../core/models/market_mapping_models.dart';
import '../../../../core/services/market_mapping_service.dart';

class CompetitorPricingScreen extends StatefulWidget {
  const CompetitorPricingScreen({super.key});

  @override
  State<CompetitorPricingScreen> createState() =>
      _CompetitorPricingScreenState();
}

class _CompetitorPricingScreenState extends State<CompetitorPricingScreen> {
  List<Competitor> _competitors = [];
  List<PriceEntry> _priceEntries = [];
  String? _selectedCompetitorId;
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
        MarketMappingService.getPriceEntries(
          competitorId: _selectedCompetitorId,
        ),
      ]);
      setState(() {
        _competitors = results[0] as List<Competitor>;
        _priceEntries = results[1] as List<PriceEntry>;
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
          'Competitor Pricing',
          style: TextStyle(
            color: const Color(0xFF1E3A8A),
            fontSize: 18.sp,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Column(
              children: [
                _buildCompetitorFilter(),
                Expanded(
                  child: RefreshIndicator(
                    onRefresh: _loadData,
                    child: _priceEntries.isEmpty
                        ? _buildEmptyState()
                        : ListView.builder(
                            padding: EdgeInsets.all(16.w),
                            itemCount: _priceEntries.length,
                            itemBuilder: (context, index) {
                              return _buildPriceCard(_priceEntries[index]);
                            },
                          ),
                  ),
                ),
              ],
            ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _showAddPriceDialog,
        backgroundColor: const Color(0xFF1E3A8A),
        icon: const Icon(Icons.add, color: Colors.white),
        label: const Text(
          'Capture Price',
          style: TextStyle(color: Colors.white),
        ),
      ),
    );
  }

  Widget _buildCompetitorFilter() {
    return Container(
      color: Colors.white,
      padding: EdgeInsets.all(16.w),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          children: [
            _buildFilterChip('All', _selectedCompetitorId == null, () {
              setState(() => _selectedCompetitorId = null);
              _loadData();
            }),
            SizedBox(width: 8.w),
            ..._competitors.map(
              (c) => Padding(
                padding: EdgeInsets.only(right: 8.w),
                child: _buildFilterChip(
                  c.brandName,
                  _selectedCompetitorId == c.id,
                  () {
                    setState(() => _selectedCompetitorId = c.id);
                    _loadData();
                  },
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFilterChip(String label, bool isSelected, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 8.h),
        decoration: BoxDecoration(
          color: isSelected ? const Color(0xFF1E3A8A) : Colors.grey[100],
          borderRadius: BorderRadius.circular(20.r),
          border: Border.all(
            color: isSelected ? const Color(0xFF1E3A8A) : Colors.grey[300]!,
          ),
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
          Icon(
            Icons.price_change_outlined,
            size: 64.sp,
            color: Colors.grey[400],
          ),
          SizedBox(height: 16.h),
          Text(
            'No price entries yet',
            style: TextStyle(fontSize: 16.sp, color: Colors.grey[600]),
          ),
          SizedBox(height: 8.h),
          Text(
            'Capture competitor prices',
            style: TextStyle(fontSize: 12.sp, color: Colors.grey[500]),
          ),
        ],
      ),
    );
  }

  Widget _buildPriceCard(PriceEntry entry) {
    final hasDiscount = entry.discountedPrice != null;

    return Container(
      margin: EdgeInsets.only(bottom: 12.h),
      padding: EdgeInsets.all(16.w),
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
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 4.h),
                decoration: BoxDecoration(
                  color: const Color(0xFF1E3A8A).withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8.r),
                ),
                child: Text(
                  entry.competitorName,
                  style: TextStyle(
                    fontSize: 11.sp,
                    color: const Color(0xFF1E3A8A),
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              const Spacer(),
              Text(
                DateFormat('dd MMM, hh:mm a').format(entry.capturedAt),
                style: TextStyle(fontSize: 10.sp, color: Colors.grey[500]),
              ),
            ],
          ),
          SizedBox(height: 12.h),
          Text(
            entry.productName,
            style: TextStyle(
              fontSize: 14.sp,
              fontWeight: FontWeight.bold,
              color: const Color(0xFF1F2937),
            ),
          ),
          SizedBox(height: 8.h),
          Row(
            children: [
              if (hasDiscount) ...[
                Text(
                  '₹${entry.price.toStringAsFixed(0)}',
                  style: TextStyle(
                    fontSize: 14.sp,
                    color: Colors.grey[500],
                    decoration: TextDecoration.lineThrough,
                  ),
                ),
                SizedBox(width: 8.w),
                Text(
                  '₹${entry.discountedPrice!.toStringAsFixed(0)}',
                  style: TextStyle(
                    fontSize: 18.sp,
                    fontWeight: FontWeight.bold,
                    color: Colors.green,
                  ),
                ),
              ] else
                Text(
                  '₹${entry.price.toStringAsFixed(0)}',
                  style: TextStyle(
                    fontSize: 18.sp,
                    fontWeight: FontWeight.bold,
                    color: const Color(0xFF1F2937),
                  ),
                ),
            ],
          ),
          if (entry.scheme != null) ...[
            SizedBox(height: 8.h),
            Container(
              padding: EdgeInsets.symmetric(horizontal: 10.w, vertical: 6.h),
              decoration: BoxDecoration(
                color: Colors.orange.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8.r),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.local_offer, size: 14.sp, color: Colors.orange),
                  SizedBox(width: 4.w),
                  Text(
                    entry.scheme!,
                    style: TextStyle(
                      fontSize: 11.sp,
                      color: Colors.orange[700],
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),
          ],
          if (entry.location != null) ...[
            SizedBox(height: 8.h),
            Row(
              children: [
                Icon(Icons.location_on, size: 14.sp, color: Colors.grey[400]),
                SizedBox(width: 4.w),
                Text(
                  entry.location!,
                  style: TextStyle(fontSize: 11.sp, color: Colors.grey[500]),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  void _showAddPriceDialog() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Price capture form - Coming soon')),
    );
  }
}
