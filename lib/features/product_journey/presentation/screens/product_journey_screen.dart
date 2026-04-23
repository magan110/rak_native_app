/// Product Journey Screen
/// View end-to-end product journey with tracking timeline

import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import '../../../../core/models/product_journey_models.dart';
import '../../../../core/services/product_journey_service.dart';

class ProductJourneyScreen extends StatefulWidget {
  const ProductJourneyScreen({super.key});

  @override
  State<ProductJourneyScreen> createState() => _ProductJourneyScreenState();
}

class _ProductJourneyScreenState extends State<ProductJourneyScreen> {
  List<ProductJourney> _journeys = [];
  List<Batch> _batches = [];
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
        ProductJourneyService.getProductJourneys(),
        ProductJourneyService.getBatches(),
      ]);
      setState(() {
        _journeys = results[0] as List<ProductJourney>;
        _batches = results[1] as List<Batch>;
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
          'Product Journey',
          style: TextStyle(
            color: const Color(0xFF1E3A8A),
            fontSize: 18.sp,
            fontWeight: FontWeight.bold,
          ),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.qr_code_scanner, color: Color(0xFF1E3A8A)),
            onPressed: _scanBatch,
            tooltip: 'Scan Batch',
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
                    _buildSearchBar(),
                    SizedBox(height: 20.h),
                    _buildBatchOverview(),
                    SizedBox(height: 20.h),
                    _buildJourneyList(),
                    SizedBox(height: 80.h),
                  ],
                ),
              ),
            ),
    );
  }

  Widget _buildSearchBar() {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 12.h),
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
      child: Row(
        children: [
          Icon(Icons.search, color: Colors.grey[400]),
          SizedBox(width: 12.w),
          Expanded(
            child: Text(
              'Search by batch number, product...',
              style: TextStyle(color: Colors.grey[500], fontSize: 14.sp),
            ),
          ),
          Container(
            padding: EdgeInsets.all(8.w),
            decoration: BoxDecoration(
              color: const Color(0xFF1E3A8A).withOpacity(0.1),
              borderRadius: BorderRadius.circular(8.r),
            ),
            child: Icon(
              Icons.filter_list,
              color: const Color(0xFF1E3A8A),
              size: 20.sp,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBatchOverview() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Active Batches',
          style: TextStyle(
            fontSize: 16.sp,
            fontWeight: FontWeight.bold,
            color: const Color(0xFF1F2937),
          ),
        ),
        SizedBox(height: 12.h),
        SizedBox(
          height: 140.h,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            itemCount: _batches.length,
            itemBuilder: (context, index) => _buildBatchCard(_batches[index]),
          ),
        ),
      ],
    );
  }

  Widget _buildBatchCard(Batch batch) {
    final stageColors = {
      JourneyStage.manufacturing: Colors.grey,
      JourneyStage.warehouse: Colors.blue,
      JourneyStage.distributor: Colors.purple,
      JourneyStage.dealer: Colors.orange,
      JourneyStage.retailer: Colors.green,
      JourneyStage.endUser: Colors.teal,
    };
    final color = stageColors[batch.currentStage] ?? Colors.grey;

    return Container(
      width: 200.w,
      margin: EdgeInsets.only(right: 12.w),
      padding: EdgeInsets.all(16.w),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12.r),
        border: Border(
          top: BorderSide(color: color, width: 4.w),
        ),
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
          Text(
            batch.batchNumber,
            style: TextStyle(
              fontSize: 13.sp,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
          SizedBox(height: 4.h),
          Text(
            batch.productName,
            style: TextStyle(fontSize: 12.sp, color: const Color(0xFF1F2937)),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          const Spacer(),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Sold',
                    style: TextStyle(fontSize: 10.sp, color: Colors.grey[500]),
                  ),
                  Text(
                    '${batch.soldCount}/${batch.quantity}',
                    style: TextStyle(
                      fontSize: 14.sp,
                      fontWeight: FontWeight.bold,
                      color: const Color(0xFF1F2937),
                    ),
                  ),
                ],
              ),
              Container(
                padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 4.h),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8.r),
                ),
                child: Text(
                  batch.currentStage.name.toUpperCase(),
                  style: TextStyle(
                    fontSize: 9.sp,
                    color: color,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildJourneyList() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Product Journeys',
          style: TextStyle(
            fontSize: 16.sp,
            fontWeight: FontWeight.bold,
            color: const Color(0xFF1F2937),
          ),
        ),
        SizedBox(height: 12.h),
        ..._journeys.map((j) => _buildJourneyCard(j)),
      ],
    );
  }

  Widget _buildJourneyCard(ProductJourney journey) {
    final stageColors = {
      JourneyStage.manufacturing: Colors.grey,
      JourneyStage.warehouse: Colors.blue,
      JourneyStage.distributor: Colors.purple,
      JourneyStage.dealer: Colors.orange,
      JourneyStage.retailer: Colors.green,
      JourneyStage.endUser: Colors.teal,
    };
    final color = stageColors[journey.currentStage] ?? Colors.grey;

    return GestureDetector(
      onTap: () => _showJourneyTimeline(journey),
      child: Container(
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
                  padding: EdgeInsets.all(10.w),
                  decoration: BoxDecoration(
                    color: color.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(10.r),
                  ),
                  child: Icon(Icons.local_shipping, color: color, size: 24.sp),
                ),
                SizedBox(width: 12.w),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        journey.productName,
                        style: TextStyle(
                          fontSize: 14.sp,
                          fontWeight: FontWeight.bold,
                          color: const Color(0xFF1F2937),
                        ),
                      ),
                      Text(
                        journey.batchNumber,
                        style: TextStyle(
                          fontSize: 12.sp,
                          color: const Color(0xFF1E3A8A),
                        ),
                      ),
                    ],
                  ),
                ),
                if (journey.isComplete)
                  Container(
                    padding: EdgeInsets.symmetric(
                      horizontal: 10.w,
                      vertical: 4.h,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.green.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12.r),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.check_circle,
                          size: 14.sp,
                          color: Colors.green,
                        ),
                        SizedBox(width: 4.w),
                        Text(
                          'COMPLETE',
                          style: TextStyle(
                            fontSize: 10.sp,
                            color: Colors.green,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ),
              ],
            ),
            SizedBox(height: 16.h),
            _buildJourneyProgress(journey),
            SizedBox(height: 12.h),
            Row(
              children: [
                Icon(
                  Icons.calendar_today,
                  size: 14.sp,
                  color: Colors.grey[400],
                ),
                SizedBox(width: 4.w),
                Text(
                  'Mfg: ${DateFormat('dd MMM yyyy').format(journey.manufactureDate)}',
                  style: TextStyle(fontSize: 11.sp, color: Colors.grey[600]),
                ),
                const Spacer(),
                Icon(
                  Icons.arrow_forward,
                  size: 16.sp,
                  color: const Color(0xFF1E3A8A),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildJourneyProgress(ProductJourney journey) {
    final stages = JourneyStage.values;
    final currentIndex = stages.indexOf(journey.currentStage);

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: List.generate(stages.length, (index) {
        final isCompleted = index <= currentIndex;
        final isCurrent = index == currentIndex;

        return Expanded(
          child: Row(
            children: [
              Column(
                children: [
                  Container(
                    width: 20.w,
                    height: 20.w,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: isCompleted
                          ? (isCurrent ? const Color(0xFF1E3A8A) : Colors.green)
                          : Colors.grey[300],
                      border: isCurrent
                          ? Border.all(color: const Color(0xFF1E3A8A), width: 3)
                          : null,
                    ),
                    child: isCompleted && !isCurrent
                        ? Icon(Icons.check, size: 12.sp, color: Colors.white)
                        : null,
                  ),
                  SizedBox(height: 4.h),
                  Text(
                    _getStageLabel(stages[index]),
                    style: TextStyle(
                      fontSize: 7.sp,
                      color: isCompleted
                          ? const Color(0xFF1F2937)
                          : Colors.grey[400],
                    ),
                  ),
                ],
              ),
              if (index < stages.length - 1)
                Expanded(
                  child: Container(
                    height: 2.h,
                    color: index < currentIndex
                        ? Colors.green
                        : Colors.grey[300],
                  ),
                ),
            ],
          ),
        );
      }),
    );
  }

  String _getStageLabel(JourneyStage stage) {
    switch (stage) {
      case JourneyStage.manufacturing:
        return 'MFG';
      case JourneyStage.warehouse:
        return 'WHOUSE';
      case JourneyStage.distributor:
        return 'DIST';
      case JourneyStage.dealer:
        return 'DEALER';
      case JourneyStage.retailer:
        return 'RETAIL';
      case JourneyStage.endUser:
        return 'USER';
    }
  }

  void _showJourneyTimeline(ProductJourney journey) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        height: MediaQuery.of(context).size.height * 0.75,
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
                children: [
                  Text(
                    'Journey Timeline',
                    style: TextStyle(
                      fontSize: 18.sp,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const Spacer(),
                  IconButton(
                    icon: const Icon(Icons.close),
                    onPressed: () => Navigator.pop(context),
                  ),
                ],
              ),
            ),
            Divider(height: 1, color: Colors.grey[200]),
            Expanded(
              child: ListView.builder(
                padding: EdgeInsets.all(16.w),
                itemCount: journey.events.length,
                itemBuilder: (context, index) {
                  final event = journey.events[index];
                  final isLast = index == journey.events.length - 1;
                  return _buildTimelineItem(event, isLast);
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTimelineItem(JourneyEvent event, bool isLast) {
    final stageColors = {
      JourneyStage.manufacturing: Colors.grey,
      JourneyStage.warehouse: Colors.blue,
      JourneyStage.distributor: Colors.purple,
      JourneyStage.dealer: Colors.orange,
      JourneyStage.retailer: Colors.green,
      JourneyStage.endUser: Colors.teal,
    };
    final color = stageColors[event.stage] ?? Colors.grey;

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Column(
          children: [
            Container(
              width: 12.w,
              height: 12.w,
              decoration: BoxDecoration(shape: BoxShape.circle, color: color),
            ),
            if (!isLast)
              Container(width: 2.w, height: 60.h, color: Colors.grey[300]),
          ],
        ),
        SizedBox(width: 12.w),
        Expanded(
          child: Container(
            margin: EdgeInsets.only(bottom: 16.h),
            padding: EdgeInsets.all(12.w),
            decoration: BoxDecoration(
              color: color.withOpacity(0.05),
              borderRadius: BorderRadius.circular(10.r),
              border: Border.all(color: color.withOpacity(0.2)),
            ),
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
                        color: color.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(4.r),
                      ),
                      child: Text(
                        event.stage.name.toUpperCase(),
                        style: TextStyle(
                          fontSize: 9.sp,
                          color: color,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    const Spacer(),
                    Text(
                      DateFormat('dd MMM, hh:mm a').format(event.timestamp),
                      style: TextStyle(
                        fontSize: 10.sp,
                        color: Colors.grey[500],
                      ),
                    ),
                  ],
                ),
                SizedBox(height: 8.h),
                Text(
                  event.description,
                  style: TextStyle(
                    fontSize: 13.sp,
                    fontWeight: FontWeight.w600,
                    color: const Color(0xFF1F2937),
                  ),
                ),
                if (event.location != null) ...[
                  SizedBox(height: 4.h),
                  Row(
                    children: [
                      Icon(
                        Icons.location_on,
                        size: 12.sp,
                        color: Colors.grey[400],
                      ),
                      SizedBox(width: 4.w),
                      Text(
                        event.location!,
                        style: TextStyle(
                          fontSize: 11.sp,
                          color: Colors.grey[600],
                        ),
                      ),
                    ],
                  ),
                ],
                if (event.handledBy != null) ...[
                  SizedBox(height: 4.h),
                  Row(
                    children: [
                      Icon(Icons.person, size: 12.sp, color: Colors.grey[400]),
                      SizedBox(width: 4.w),
                      Text(
                        event.handledBy!,
                        style: TextStyle(
                          fontSize: 11.sp,
                          color: Colors.grey[600],
                        ),
                      ),
                    ],
                  ),
                ],
              ],
            ),
          ),
        ),
      ],
    );
  }

  void _scanBatch() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Batch scanner - Coming soon')),
    );
  }
}
