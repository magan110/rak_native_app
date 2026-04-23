/// Counter Mapping Screen
/// View and manage counters/outlets

import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/models/sales_monitoring_models.dart';
import '../../../../core/services/sales_monitoring_service.dart';

class CounterMappingScreen extends StatefulWidget {
  const CounterMappingScreen({super.key});

  @override
  State<CounterMappingScreen> createState() => _CounterMappingScreenState();
}

class _CounterMappingScreenState extends State<CounterMappingScreen> {
  List<Counter> _counters = [];
  List<SalesRoute> _routes = [];
  String? _selectedRoute;
  bool _isLoading = true;
  bool _showDueOnly = false;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);
    try {
      final results = await Future.wait([
        _showDueOnly
            ? SalesMonitoringService.getCountersDueForVisit()
            : SalesMonitoringService.getCounters(route: _selectedRoute),
        SalesMonitoringService.getRoutes(),
      ]);
      setState(() {
        _counters = results[0] as List<Counter>;
        _routes = results[1] as List<SalesRoute>;
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
          'Counter Mapping',
          style: TextStyle(
            color: const Color(0xFF1E3A8A),
            fontSize: 18.sp,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
      body: Column(
        children: [
          _buildFilters(),
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _counters.isEmpty
                ? _buildEmptyState()
                : RefreshIndicator(
                    onRefresh: _loadData,
                    child: ListView.builder(
                      padding: EdgeInsets.all(16.w),
                      itemCount: _counters.length,
                      itemBuilder: (context, index) =>
                          _buildCounterCard(_counters[index]),
                    ),
                  ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _addCounter,
        backgroundColor: const Color(0xFF1E3A8A),
        icon: const Icon(Icons.add, color: Colors.white),
        label: const Text('Add Counter', style: TextStyle(color: Colors.white)),
      ),
    );
  }

  Widget _buildFilters() {
    return Container(
      color: Colors.white,
      padding: EdgeInsets.all(16.w),
      child: Column(
        children: [
          Row(
            children: [
              Expanded(
                child: DropdownButtonFormField<String>(
                  value: _selectedRoute,
                  decoration: InputDecoration(
                    labelText: 'Filter by Route',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10.r),
                    ),
                    contentPadding: EdgeInsets.symmetric(
                      horizontal: 12.w,
                      vertical: 10.h,
                    ),
                    isDense: true,
                  ),
                  items: [
                    const DropdownMenuItem(
                      value: null,
                      child: Text('All Routes'),
                    ),
                    ..._routes.map(
                      (r) => DropdownMenuItem(value: r.id, child: Text(r.name)),
                    ),
                  ],
                  onChanged: (v) {
                    setState(() => _selectedRoute = v);
                    _loadData();
                  },
                ),
              ),
              SizedBox(width: 12.w),
              FilterChip(
                label: const Text('Due for Visit'),
                selected: _showDueOnly,
                onSelected: (v) {
                  setState(() => _showDueOnly = v);
                  _loadData();
                },
                selectedColor: const Color(0xFF1E3A8A).withOpacity(0.2),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.store_outlined, size: 64.sp, color: Colors.grey[400]),
          SizedBox(height: 16.h),
          Text(
            'No counters found',
            style: TextStyle(fontSize: 16.sp, color: Colors.grey[600]),
          ),
        ],
      ),
    );
  }

  Widget _buildCounterCard(Counter counter) {
    Color typeColor;
    switch (counter.type) {
      case OutletType.retailer:
        typeColor = Colors.blue;
        break;
      case OutletType.dealer:
        typeColor = Colors.green;
        break;
      case OutletType.distributor:
        typeColor = Colors.purple;
        break;
      case OutletType.wholesaler:
        typeColor = Colors.orange;
        break;
    }

    return Container(
      margin: EdgeInsets.only(bottom: 12.h),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12.r),
        border: counter.isDueForVisit
            ? Border.all(color: Colors.red.withOpacity(0.5), width: 2)
            : null,
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
                CircleAvatar(
                  radius: 22.r,
                  backgroundColor: typeColor.withOpacity(0.1),
                  child: Icon(Icons.store, color: typeColor, size: 22.sp),
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
                              counter.name,
                              style: TextStyle(
                                fontSize: 14.sp,
                                fontWeight: FontWeight.bold,
                                color: const Color(0xFF1F2937),
                              ),
                            ),
                          ),
                          Container(
                            padding: EdgeInsets.symmetric(
                              horizontal: 8.w,
                              vertical: 2.h,
                            ),
                            decoration: BoxDecoration(
                              color: typeColor.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(8.r),
                            ),
                            child: Text(
                              counter.type.name.toUpperCase(),
                              style: TextStyle(
                                fontSize: 9.sp,
                                color: typeColor,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ],
                      ),
                      if (counter.ownerName != null)
                        Text(
                          counter.ownerName!,
                          style: TextStyle(
                            fontSize: 12.sp,
                            color: Colors.grey[600],
                          ),
                        ),
                    ],
                  ),
                ),
              ],
            ),
            SizedBox(height: 12.h),
            Row(
              children: [
                Icon(Icons.location_on, size: 14.sp, color: Colors.grey[400]),
                SizedBox(width: 4.w),
                Expanded(
                  child: Text(
                    counter.address,
                    style: TextStyle(fontSize: 11.sp, color: Colors.grey[600]),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
            SizedBox(height: 8.h),
            Row(
              children: [
                if (counter.phone != null) ...[
                  Icon(Icons.phone, size: 14.sp, color: Colors.grey[400]),
                  SizedBox(width: 4.w),
                  Text(
                    counter.phone!,
                    style: TextStyle(fontSize: 11.sp, color: Colors.grey[600]),
                  ),
                  SizedBox(width: 16.w),
                ],
                if (counter.route != null) ...[
                  Icon(Icons.route, size: 14.sp, color: Colors.grey[400]),
                  SizedBox(width: 4.w),
                  Text(
                    counter.route!,
                    style: TextStyle(fontSize: 11.sp, color: Colors.grey[600]),
                  ),
                ],
              ],
            ),
            SizedBox(height: 8.h),
            Divider(color: Colors.grey[200]),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                if (counter.isDueForVisit)
                  Container(
                    padding: EdgeInsets.symmetric(
                      horizontal: 8.w,
                      vertical: 4.h,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.red.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8.r),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.warning_amber,
                          size: 12.sp,
                          color: Colors.red,
                        ),
                        SizedBox(width: 4.w),
                        Text(
                          'Due for Visit',
                          style: TextStyle(
                            fontSize: 10.sp,
                            color: Colors.red,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  )
                else
                  Text(
                    'Last visit: ${counter.lastVisit != null ? "${DateTime.now().difference(counter.lastVisit!).inDays} days ago" : "Never"}',
                    style: TextStyle(fontSize: 11.sp, color: Colors.grey[500]),
                  ),
                Row(
                  children: [
                    IconButton(
                      icon: Icon(Icons.phone, color: Colors.green, size: 20.sp),
                      onPressed: () {},
                      constraints: const BoxConstraints(),
                      padding: EdgeInsets.all(8.w),
                    ),
                    IconButton(
                      icon: Icon(
                        Icons.directions,
                        color: Colors.blue,
                        size: 20.sp,
                      ),
                      onPressed: () {},
                      constraints: const BoxConstraints(),
                      padding: EdgeInsets.all(8.w),
                    ),
                  ],
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  void _addCounter() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Add counter form - Coming soon')),
    );
  }
}
