/// Discount Tracking Screen
/// Track and view competitor discount activities

import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import '../../../../core/models/market_mapping_models.dart';
import '../../../../core/services/market_mapping_service.dart';

class DiscountTrackingScreen extends StatefulWidget {
  const DiscountTrackingScreen({super.key});

  @override
  State<DiscountTrackingScreen> createState() => _DiscountTrackingScreenState();
}

class _DiscountTrackingScreenState extends State<DiscountTrackingScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  List<DiscountActivity> _allDiscounts = [];
  List<DiscountActivity> _activeDiscounts = [];
  List<DiscountActivity> _expiredDiscounts = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _loadData();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);
    try {
      _allDiscounts = await MarketMappingService.getDiscountActivities();
      setState(() {
        _activeDiscounts = _allDiscounts.where((d) => d.isActive).toList();
        _expiredDiscounts = _allDiscounts.where((d) => !d.isActive).toList();
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
          'Discount Tracking',
          style: TextStyle(
            color: const Color(0xFF1E3A8A),
            fontSize: 18.sp,
            fontWeight: FontWeight.bold,
          ),
        ),
        bottom: TabBar(
          controller: _tabController,
          labelColor: const Color(0xFF1E3A8A),
          unselectedLabelColor: Colors.grey,
          indicatorColor: const Color(0xFF1E3A8A),
          tabs: [
            Tab(text: 'Active (${_activeDiscounts.length})'),
            Tab(text: 'Expired (${_expiredDiscounts.length})'),
          ],
        ),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : TabBarView(
              controller: _tabController,
              children: [
                _buildDiscountList(_activeDiscounts, true),
                _buildDiscountList(_expiredDiscounts, false),
              ],
            ),
    );
  }

  Widget _buildDiscountList(List<DiscountActivity> discounts, bool isActive) {
    if (discounts.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.local_offer_outlined,
              size: 64.sp,
              color: Colors.grey[400],
            ),
            SizedBox(height: 16.h),
            Text(
              isActive ? 'No active discounts' : 'No expired discounts',
              style: TextStyle(fontSize: 16.sp, color: Colors.grey[600]),
            ),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _loadData,
      child: ListView.builder(
        padding: EdgeInsets.all(16.w),
        itemCount: discounts.length,
        itemBuilder: (context, index) => _buildDiscountCard(discounts[index]),
      ),
    );
  }

  Widget _buildDiscountCard(DiscountActivity discount) {
    IconData typeIcon;
    Color typeColor;

    switch (discount.type) {
      case DiscountType.percentage:
        typeIcon = Icons.percent;
        typeColor = Colors.green;
        break;
      case DiscountType.flat:
        typeIcon = Icons.money_off;
        typeColor = Colors.blue;
        break;
      case DiscountType.buyXGetY:
        typeIcon = Icons.card_giftcard;
        typeColor = Colors.purple;
        break;
      case DiscountType.combo:
        typeIcon = Icons.inventory_2;
        typeColor = Colors.orange;
        break;
      case DiscountType.scheme:
        typeIcon = Icons.local_offer;
        typeColor = Colors.teal;
        break;
    }

    return Container(
      margin: EdgeInsets.only(bottom: 12.h),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12.r),
        border: Border(
          left: BorderSide(
            color: discount.isActive ? Colors.green : Colors.grey,
            width: 4.w,
          ),
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
                      Text(
                        discount.competitorName,
                        style: TextStyle(
                          fontSize: 12.sp,
                          color: const Color(0xFF1E3A8A),
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        discount.productName,
                        style: TextStyle(
                          fontSize: 14.sp,
                          fontWeight: FontWeight.w600,
                          color: const Color(0xFF1F2937),
                        ),
                      ),
                    ],
                  ),
                ),
                Container(
                  padding: EdgeInsets.symmetric(
                    horizontal: 10.w,
                    vertical: 4.h,
                  ),
                  decoration: BoxDecoration(
                    color: discount.isActive
                        ? Colors.green.withOpacity(0.1)
                        : Colors.grey.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12.r),
                  ),
                  child: Text(
                    discount.isActive ? 'ACTIVE' : 'EXPIRED',
                    style: TextStyle(
                      fontSize: 10.sp,
                      fontWeight: FontWeight.bold,
                      color: discount.isActive ? Colors.green : Colors.grey,
                    ),
                  ),
                ),
              ],
            ),
            SizedBox(height: 12.h),
            Container(
              width: double.infinity,
              padding: EdgeInsets.all(12.w),
              decoration: BoxDecoration(
                color: Colors.grey[50],
                borderRadius: BorderRadius.circular(8.r),
              ),
              child: Text(
                discount.description,
                style: TextStyle(
                  fontSize: 14.sp,
                  fontWeight: FontWeight.w600,
                  color: const Color(0xFF1F2937),
                ),
              ),
            ),
            SizedBox(height: 12.h),
            Row(
              children: [
                Icon(
                  Icons.calendar_today,
                  size: 14.sp,
                  color: Colors.grey[500],
                ),
                SizedBox(width: 4.w),
                Text(
                  '${DateFormat('dd MMM').format(discount.startDate)} - ${discount.endDate != null ? DateFormat('dd MMM').format(discount.endDate!) : 'Ongoing'}',
                  style: TextStyle(fontSize: 11.sp, color: Colors.grey[600]),
                ),
                const Spacer(),
                if (discount.location != null) ...[
                  Icon(Icons.location_on, size: 14.sp, color: Colors.grey[500]),
                  SizedBox(width: 4.w),
                  Text(
                    discount.location!,
                    style: TextStyle(fontSize: 11.sp, color: Colors.grey[600]),
                  ),
                ],
              ],
            ),
          ],
        ),
      ),
    );
  }
}
