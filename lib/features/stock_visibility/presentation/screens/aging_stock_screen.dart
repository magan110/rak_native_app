/// Aging Stock Report Screen
/// Screen to view aging stock with expiry tracking

import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import '../../../../core/models/stock_models.dart';
import '../../../../core/services/stock_service.dart';

class AgingStockScreen extends StatefulWidget {
  const AgingStockScreen({super.key});

  @override
  State<AgingStockScreen> createState() => _AgingStockScreenState();
}

class _AgingStockScreenState extends State<AgingStockScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  AgingStockSummary _summary = const AgingStockSummary();
  List<AgingStockItem> _allItems = [];
  List<AgingStockItem> _filteredItems = [];
  bool _isLoading = true;
  AgingCategory? _selectedCategory;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
    _tabController.addListener(_onTabChanged);
    _loadData();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  void _onTabChanged() {
    if (!_tabController.indexIsChanging) {
      setState(() {
        switch (_tabController.index) {
          case 0:
            _selectedCategory = null;
            break;
          case 1:
            _selectedCategory = AgingCategory.nearExpiry;
            break;
          case 2:
            _selectedCategory = AgingCategory.aging;
            break;
          case 3:
            _selectedCategory = AgingCategory.expired;
            break;
        }
        _filterItems();
      });
    }
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);
    try {
      final results = await Future.wait([
        StockService.getAgingStockSummary(),
        StockService.getAgingStockItems(),
      ]);
      setState(() {
        _summary = results[0] as AgingStockSummary;
        _allItems = results[1] as List<AgingStockItem>;
        _filterItems();
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
    }
  }

  void _filterItems() {
    if (_selectedCategory == null) {
      _filteredItems = _allItems;
    } else {
      _filteredItems = _allItems
          .where((i) => i.category == _selectedCategory)
          .toList();
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
          'Aging Stock Report',
          style: TextStyle(
            color: const Color(0xFF1E3A8A),
            fontSize: 18.sp,
            fontWeight: FontWeight.bold,
          ),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.download, color: Color(0xFF1E3A8A)),
            onPressed: _downloadReport,
            tooltip: 'Download Report',
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _loadData,
              child: Column(
                children: [
                  _buildSummarySection(),
                  _buildTabBar(),
                  Expanded(child: _buildItemsList()),
                ],
              ),
            ),
    );
  }

  Widget _buildSummarySection() {
    return Container(
      margin: EdgeInsets.all(16.w),
      padding: EdgeInsets.all(16.w),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF1E3A8A), Color(0xFF3B82F6)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16.r),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF1E3A8A).withOpacity(0.3),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Stock Aging Summary',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 16.sp,
                  fontWeight: FontWeight.bold,
                ),
              ),
              Container(
                padding: EdgeInsets.symmetric(horizontal: 10.w, vertical: 4.h),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(20.r),
                ),
                child: Text(
                  '${_summary.totalItems} Items',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 12.sp,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
          SizedBox(height: 16.h),
          Row(
            children: [
              Expanded(
                child: _buildCategoryIndicator(
                  'Fresh',
                  _summary.freshCount,
                  Colors.green,
                ),
              ),
              Expanded(
                child: _buildCategoryIndicator(
                  'Aging',
                  _summary.agingCount,
                  Colors.orange,
                ),
              ),
              Expanded(
                child: _buildCategoryIndicator(
                  'Near Expiry',
                  _summary.nearExpiryCount,
                  Colors.red,
                ),
              ),
              Expanded(
                child: _buildCategoryIndicator(
                  'Expired',
                  _summary.expiredCount,
                  Colors.grey,
                ),
              ),
            ],
          ),
          SizedBox(height: 16.h),
          Divider(color: Colors.white.withOpacity(0.3)),
          SizedBox(height: 12.h),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Total Stock Value',
                    style: TextStyle(
                      color: Colors.white.withOpacity(0.8),
                      fontSize: 12.sp,
                    ),
                  ),
                  Text(
                    '₹ ${NumberFormat('#,##,###').format(_summary.totalValue)}',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 18.sp,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    'At Risk Value',
                    style: TextStyle(
                      color: Colors.white.withOpacity(0.8),
                      fontSize: 12.sp,
                    ),
                  ),
                  Text(
                    '₹ ${NumberFormat('#,##,###').format(_summary.atRiskValue)}',
                    style: TextStyle(
                      color: Colors.red[200],
                      fontSize: 18.sp,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildCategoryIndicator(String label, int count, Color color) {
    return Column(
      children: [
        Container(
          padding: EdgeInsets.all(8.w),
          decoration: BoxDecoration(
            color: color.withOpacity(0.2),
            shape: BoxShape.circle,
          ),
          child: Text(
            count.toString(),
            style: TextStyle(
              color: Colors.white,
              fontSize: 14.sp,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
        SizedBox(height: 4.h),
        Text(
          label,
          style: TextStyle(
            color: Colors.white.withOpacity(0.9),
            fontSize: 10.sp,
          ),
        ),
      ],
    );
  }

  Widget _buildTabBar() {
    return Container(
      color: Colors.white,
      child: TabBar(
        controller: _tabController,
        labelColor: const Color(0xFF1E3A8A),
        unselectedLabelColor: Colors.grey[600],
        indicatorColor: const Color(0xFF1E3A8A),
        indicatorWeight: 3,
        labelStyle: TextStyle(fontSize: 12.sp, fontWeight: FontWeight.w600),
        tabs: [
          Tab(text: 'All (${_allItems.length})'),
          Tab(
            text:
                'Near Expiry (${_allItems.where((i) => i.category == AgingCategory.nearExpiry).length})',
          ),
          Tab(
            text:
                'Aging (${_allItems.where((i) => i.category == AgingCategory.aging).length})',
          ),
          Tab(
            text:
                'Expired (${_allItems.where((i) => i.category == AgingCategory.expired).length})',
          ),
        ],
      ),
    );
  }

  Widget _buildItemsList() {
    if (_filteredItems.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.inventory_2_outlined,
              size: 64.sp,
              color: Colors.grey[400],
            ),
            SizedBox(height: 16.h),
            Text(
              'No items in this category',
              style: TextStyle(fontSize: 16.sp, color: Colors.grey[600]),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: EdgeInsets.all(16.w),
      itemCount: _filteredItems.length,
      itemBuilder: (context, index) {
        return _buildAgingItemCard(_filteredItems[index]);
      },
    );
  }

  Widget _buildAgingItemCard(AgingStockItem item) {
    Color categoryColor;
    String categoryLabel;
    IconData categoryIcon;

    switch (item.category) {
      case AgingCategory.fresh:
        categoryColor = Colors.green;
        categoryLabel = 'Fresh';
        categoryIcon = Icons.check_circle;
        break;
      case AgingCategory.aging:
        categoryColor = Colors.orange;
        categoryLabel = 'Aging';
        categoryIcon = Icons.hourglass_empty;
        break;
      case AgingCategory.nearExpiry:
        categoryColor = Colors.red;
        categoryLabel = 'Near Expiry';
        categoryIcon = Icons.warning_amber;
        break;
      case AgingCategory.expired:
        categoryColor = Colors.grey;
        categoryLabel = 'Expired';
        categoryIcon = Icons.block;
        break;
    }

    return Container(
      margin: EdgeInsets.only(bottom: 12.h),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12.r),
        border: Border(
          left: BorderSide(color: categoryColor, width: 4.w),
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
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        item.productName,
                        style: TextStyle(
                          fontSize: 14.sp,
                          fontWeight: FontWeight.bold,
                          color: const Color(0xFF1F2937),
                        ),
                      ),
                      SizedBox(height: 4.h),
                      Text(
                        'Batch: ${item.batchNumber}',
                        style: TextStyle(
                          fontSize: 12.sp,
                          color: Colors.grey[600],
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
                    color: categoryColor.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(20.r),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(categoryIcon, size: 14.sp, color: categoryColor),
                      SizedBox(width: 4.w),
                      Text(
                        categoryLabel,
                        style: TextStyle(
                          fontSize: 11.sp,
                          color: categoryColor,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            SizedBox(height: 12.h),
            Container(
              padding: EdgeInsets.all(12.w),
              decoration: BoxDecoration(
                color: Colors.grey[50],
                borderRadius: BorderRadius.circular(8.r),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  _buildInfoColumn(
                    'Quantity',
                    item.quantity.toString(),
                    Icons.inventory_2,
                  ),
                  Container(width: 1, height: 40.h, color: Colors.grey[300]),
                  _buildInfoColumn(
                    'Expiry Date',
                    item.expiryDate != null
                        ? DateFormat('dd MMM yyyy').format(item.expiryDate!)
                        : 'N/A',
                    Icons.event,
                  ),
                  Container(width: 1, height: 40.h, color: Colors.grey[300]),
                  _buildInfoColumn(
                    'Days Left',
                    item.daysToExpiry >= 0 ? '${item.daysToExpiry}' : 'Expired',
                    Icons.schedule,
                    valueColor: categoryColor,
                  ),
                ],
              ),
            ),
            SizedBox(height: 12.h),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Stock Value: ₹ ${NumberFormat('#,##,###').format(item.stockValue)}',
                  style: TextStyle(
                    fontSize: 13.sp,
                    fontWeight: FontWeight.w600,
                    color: const Color(0xFF1E3A8A),
                  ),
                ),
                if (item.category == AgingCategory.nearExpiry ||
                    item.category == AgingCategory.expired)
                  TextButton.icon(
                    onPressed: () => _showActionDialog(item),
                    icon: Icon(Icons.flash_on, size: 16.sp),
                    label: const Text('Take Action'),
                    style: TextButton.styleFrom(
                      foregroundColor: Colors.red,
                      padding: EdgeInsets.symmetric(horizontal: 8.w),
                    ),
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoColumn(
    String label,
    String value,
    IconData icon, {
    Color? valueColor,
  }) {
    return Column(
      children: [
        Icon(icon, size: 16.sp, color: Colors.grey[500]),
        SizedBox(height: 4.h),
        Text(
          value,
          style: TextStyle(
            fontSize: 12.sp,
            fontWeight: FontWeight.bold,
            color: valueColor ?? const Color(0xFF1F2937),
          ),
        ),
        Text(
          label,
          style: TextStyle(fontSize: 10.sp, color: Colors.grey[500]),
        ),
      ],
    );
  }

  void _showActionDialog(AgingStockItem item) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(
          'Take Action',
          style: TextStyle(fontSize: 18.sp, fontWeight: FontWeight.bold),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              item.productName,
              style: TextStyle(fontSize: 14.sp, fontWeight: FontWeight.w600),
            ),
            Text(
              'Batch: ${item.batchNumber}',
              style: TextStyle(fontSize: 12.sp, color: Colors.grey[600]),
            ),
            SizedBox(height: 16.h),
            Text(
              'What action would you like to take?',
              style: TextStyle(fontSize: 13.sp),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Clearance sale initiated')),
              );
            },
            child: const Text('Clearance Sale'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Return request initiated')),
              );
            },
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Return/Write-off'),
          ),
        ],
      ),
    );
  }

  void _downloadReport() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Downloading aging stock report...'),
        duration: Duration(seconds: 2),
      ),
    );
  }
}
