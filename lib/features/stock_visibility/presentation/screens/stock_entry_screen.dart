/// Stock Entry Screen
/// Screen for distributors/retailers to enter stock

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import '../../../../core/models/stock_models.dart';
import '../../../../core/services/stock_service.dart';

class StockEntryScreen extends StatefulWidget {
  const StockEntryScreen({super.key});

  @override
  State<StockEntryScreen> createState() => _StockEntryScreenState();
}

class _StockEntryScreenState extends State<StockEntryScreen> {
  List<StockLevel> _stockLevels = [];
  List<StockEntry> _recentEntries = [];
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
        StockService.getStockLevels(),
        StockService.getStockEntries(),
      ]);
      setState(() {
        _stockLevels = results[0] as List<StockLevel>;
        _recentEntries = results[1] as List<StockEntry>;
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
          'Stock Entry',
          style: TextStyle(
            color: const Color(0xFF1E3A8A),
            fontSize: 18.sp,
            fontWeight: FontWeight.bold,
          ),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.history, color: Color(0xFF1E3A8A)),
            onPressed: () => _showRecentEntries(),
            tooltip: 'Recent Entries',
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
                    _buildStockSummary(),
                    SizedBox(height: 20.h),
                    _buildStockLevelsSection(),
                  ],
                ),
              ),
            ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _showAddEntryDialog,
        backgroundColor: const Color(0xFF1E3A8A),
        icon: const Icon(Icons.add, color: Colors.white),
        label: const Text(
          'Add Stock Entry',
          style: TextStyle(color: Colors.white),
        ),
      ),
    );
  }

  Widget _buildStockSummary() {
    final totalProducts = _stockLevels.length;
    final lowStock = _stockLevels.where((s) => s.isLowStock).length;
    final healthy = _stockLevels.where((s) => s.isHealthy).length;

    return Container(
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
          Text(
            'Stock Overview',
            style: TextStyle(
              color: Colors.white,
              fontSize: 18.sp,
              fontWeight: FontWeight.bold,
            ),
          ),
          SizedBox(height: 16.h),
          Row(
            children: [
              Expanded(
                child: _buildSummaryCard(
                  'Total Products',
                  totalProducts.toString(),
                  Icons.inventory_2,
                  Colors.white.withOpacity(0.2),
                ),
              ),
              SizedBox(width: 12.w),
              Expanded(
                child: _buildSummaryCard(
                  'Low Stock',
                  lowStock.toString(),
                  Icons.warning_amber,
                  Colors.orange.withOpacity(0.3),
                ),
              ),
              SizedBox(width: 12.w),
              Expanded(
                child: _buildSummaryCard(
                  'Healthy',
                  healthy.toString(),
                  Icons.check_circle,
                  Colors.green.withOpacity(0.3),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSummaryCard(
    String label,
    String value,
    IconData icon,
    Color bgColor,
  ) {
    return Container(
      padding: EdgeInsets.all(12.w),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(12.r),
      ),
      child: Column(
        children: [
          Icon(icon, color: Colors.white, size: 24.sp),
          SizedBox(height: 8.h),
          Text(
            value,
            style: TextStyle(
              color: Colors.white,
              fontSize: 20.sp,
              fontWeight: FontWeight.bold,
            ),
          ),
          SizedBox(height: 4.h),
          Text(
            label,
            style: TextStyle(
              color: Colors.white.withOpacity(0.9),
              fontSize: 10.sp,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildStockLevelsSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Current Stock Levels',
              style: TextStyle(
                fontSize: 16.sp,
                fontWeight: FontWeight.bold,
                color: const Color(0xFF1F2937),
              ),
            ),
            TextButton.icon(
              onPressed: () => context.push('/aging-stock'),
              icon: Icon(Icons.timeline, size: 18.sp),
              label: const Text('Aging Report'),
            ),
          ],
        ),
        SizedBox(height: 12.h),
        ..._stockLevels.map((stock) => _buildStockLevelCard(stock)),
      ],
    );
  }

  Widget _buildStockLevelCard(StockLevel stock) {
    Color statusColor;
    String statusText;
    IconData statusIcon;

    if (stock.isLowStock) {
      statusColor = Colors.red;
      statusText = 'Low Stock';
      statusIcon = Icons.warning_amber;
    } else if (stock.isOverstock) {
      statusColor = Colors.orange;
      statusText = 'Overstock';
      statusIcon = Icons.inventory;
    } else {
      statusColor = Colors.green;
      statusText = 'Healthy';
      statusIcon = Icons.check_circle;
    }

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
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      stock.productName,
                      style: TextStyle(
                        fontSize: 14.sp,
                        fontWeight: FontWeight.bold,
                        color: const Color(0xFF1F2937),
                      ),
                    ),
                    if (stock.productSku != null)
                      Text(
                        stock.productSku!,
                        style: TextStyle(
                          fontSize: 12.sp,
                          color: Colors.grey[600],
                        ),
                      ),
                  ],
                ),
              ),
              Container(
                padding: EdgeInsets.symmetric(horizontal: 10.w, vertical: 4.h),
                decoration: BoxDecoration(
                  color: statusColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(20.r),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(statusIcon, size: 14.sp, color: statusColor),
                    SizedBox(width: 4.w),
                    Text(
                      statusText,
                      style: TextStyle(
                        fontSize: 11.sp,
                        color: statusColor,
                        fontWeight: FontWeight.w600,
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
              _buildStockInfo(
                'Current',
                '${stock.currentStock}',
                const Color(0xFF1E3A8A),
              ),
              SizedBox(width: 16.w),
              _buildStockInfo('Min', '${stock.minStock}', Colors.orange),
              SizedBox(width: 16.w),
              _buildStockInfo('Max', '${stock.maxStock}', Colors.green),
              const Spacer(),
              Text(
                stock.unit,
                style: TextStyle(
                  fontSize: 12.sp,
                  color: Colors.grey[600],
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
          SizedBox(height: 8.h),
          // Stock bar
          ClipRRect(
            borderRadius: BorderRadius.circular(4.r),
            child: LinearProgressIndicator(
              value: (stock.currentStock / stock.maxStock).clamp(0.0, 1.0),
              minHeight: 6.h,
              backgroundColor: Colors.grey[200],
              valueColor: AlwaysStoppedAnimation<Color>(statusColor),
            ),
          ),
          SizedBox(height: 8.h),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Last updated: ${DateFormat('dd MMM, hh:mm a').format(stock.lastUpdated)}',
                style: TextStyle(fontSize: 10.sp, color: Colors.grey[500]),
              ),
              TextButton(
                onPressed: () => _showQuickEntryDialog(stock),
                style: TextButton.styleFrom(
                  padding: EdgeInsets.symmetric(horizontal: 8.w),
                  minimumSize: Size.zero,
                  tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                ),
                child: Text('Quick Entry', style: TextStyle(fontSize: 12.sp)),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStockInfo(String label, String value, Color color) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(fontSize: 10.sp, color: Colors.grey[600]),
        ),
        Text(
          value,
          style: TextStyle(
            fontSize: 14.sp,
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
      ],
    );
  }

  void _showAddEntryDialog() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => _StockEntryForm(
        stockLevels: _stockLevels,
        onSubmit: (entry) async {
          final result = await StockService.createStockEntry(entry);
          if (result != null) {
            await _loadData();
            if (mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Stock entry added successfully')),
              );
            }
          }
        },
      ),
    );
  }

  void _showQuickEntryDialog(StockLevel stock) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => _StockEntryForm(
        stockLevels: _stockLevels,
        preselectedProductId: stock.productId,
        onSubmit: (entry) async {
          final result = await StockService.createStockEntry(entry);
          if (result != null) {
            await _loadData();
            if (mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Stock entry added successfully')),
              );
            }
          }
        },
      ),
    );
  }

  void _showRecentEntries() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
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
              child: Text(
                'Recent Stock Entries',
                style: TextStyle(
                  fontSize: 18.sp,
                  fontWeight: FontWeight.bold,
                  color: const Color(0xFF1F2937),
                ),
              ),
            ),
            Expanded(
              child: ListView.builder(
                padding: EdgeInsets.symmetric(horizontal: 16.w),
                itemCount: _recentEntries.length,
                itemBuilder: (context, index) {
                  final entry = _recentEntries[index];
                  return _buildEntryItem(entry);
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEntryItem(StockEntry entry) {
    IconData typeIcon;
    Color typeColor;
    String typeText;

    switch (entry.type) {
      case StockEntryType.receipt:
        typeIcon = Icons.add_circle;
        typeColor = Colors.green;
        typeText = 'Receipt';
        break;
      case StockEntryType.sale:
        typeIcon = Icons.remove_circle;
        typeColor = Colors.red;
        typeText = 'Sale';
        break;
      case StockEntryType.return_:
        typeIcon = Icons.undo;
        typeColor = Colors.orange;
        typeText = 'Return';
        break;
      case StockEntryType.adjustment:
        typeIcon = Icons.tune;
        typeColor = Colors.blue;
        typeText = 'Adjustment';
        break;
      case StockEntryType.opening:
        typeIcon = Icons.flag;
        typeColor = Colors.purple;
        typeText = 'Opening';
        break;
    }

    return Container(
      margin: EdgeInsets.only(bottom: 12.h),
      padding: EdgeInsets.all(12.w),
      decoration: BoxDecoration(
        color: Colors.grey[50],
        borderRadius: BorderRadius.circular(10.r),
        border: Border.all(color: Colors.grey[200]!),
      ),
      child: Row(
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
                  entry.productName,
                  style: TextStyle(
                    fontSize: 13.sp,
                    fontWeight: FontWeight.w600,
                    color: const Color(0xFF1F2937),
                  ),
                ),
                Text(
                  '$typeText • ${entry.remarks ?? ""}',
                  style: TextStyle(fontSize: 11.sp, color: Colors.grey[600]),
                ),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                '${entry.type == StockEntryType.sale ? "-" : "+"}${entry.quantity}',
                style: TextStyle(
                  fontSize: 14.sp,
                  fontWeight: FontWeight.bold,
                  color: typeColor,
                ),
              ),
              Text(
                DateFormat('dd MMM').format(entry.entryDate),
                style: TextStyle(fontSize: 10.sp, color: Colors.grey[500]),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

// ============================================
// STOCK ENTRY FORM
// ============================================

class _StockEntryForm extends StatefulWidget {
  final List<StockLevel> stockLevels;
  final String? preselectedProductId;
  final Function(CreateStockEntryRequest) onSubmit;

  const _StockEntryForm({
    required this.stockLevels,
    this.preselectedProductId,
    required this.onSubmit,
  });

  @override
  State<_StockEntryForm> createState() => _StockEntryFormState();
}

class _StockEntryFormState extends State<_StockEntryForm> {
  final _formKey = GlobalKey<FormState>();
  String? _selectedProductId;
  StockEntryType _selectedType = StockEntryType.receipt;
  final _quantityController = TextEditingController();
  final _batchController = TextEditingController();
  final _remarksController = TextEditingController();
  DateTime? _expiryDate;
  bool _isSubmitting = false;

  @override
  void initState() {
    super.initState();
    _selectedProductId = widget.preselectedProductId;
  }

  @override
  void dispose() {
    _quantityController.dispose();
    _batchController.dispose();
    _remarksController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      height: MediaQuery.of(context).size.height * 0.8,
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
                  'Add Stock Entry',
                  style: TextStyle(
                    fontSize: 18.sp,
                    fontWeight: FontWeight.bold,
                    color: const Color(0xFF1F2937),
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
                    // Product Dropdown
                    _buildLabel('Product'),
                    DropdownButtonFormField<String>(
                      value: _selectedProductId,
                      decoration: _inputDecoration('Select product'),
                      items: widget.stockLevels.map((s) {
                        return DropdownMenuItem(
                          value: s.productId,
                          child: Text(
                            s.productName,
                            overflow: TextOverflow.ellipsis,
                          ),
                        );
                      }).toList(),
                      onChanged: (value) =>
                          setState(() => _selectedProductId = value),
                      validator: (value) =>
                          value == null ? 'Please select a product' : null,
                    ),
                    SizedBox(height: 16.h),

                    // Entry Type
                    _buildLabel('Entry Type'),
                    DropdownButtonFormField<StockEntryType>(
                      value: _selectedType,
                      decoration: _inputDecoration('Select type'),
                      items: StockEntryType.values.map((t) {
                        String name = t.name;
                        if (t == StockEntryType.return_) name = 'Return';
                        return DropdownMenuItem(
                          value: t,
                          child: Text(
                            name[0].toUpperCase() + name.substring(1),
                          ),
                        );
                      }).toList(),
                      onChanged: (value) =>
                          setState(() => _selectedType = value!),
                    ),
                    SizedBox(height: 16.h),

                    // Quantity
                    _buildLabel('Quantity'),
                    TextFormField(
                      controller: _quantityController,
                      decoration: _inputDecoration('Enter quantity'),
                      keyboardType: TextInputType.number,
                      inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                      validator: (value) {
                        if (value == null || value.isEmpty)
                          return 'Please enter quantity';
                        if (int.tryParse(value) == null ||
                            int.parse(value) <= 0) {
                          return 'Enter a valid quantity';
                        }
                        return null;
                      },
                    ),
                    SizedBox(height: 16.h),

                    // Batch Number (optional)
                    _buildLabel('Batch Number (Optional)'),
                    TextFormField(
                      controller: _batchController,
                      decoration: _inputDecoration('Enter batch number'),
                    ),
                    SizedBox(height: 16.h),

                    // Expiry Date (optional)
                    _buildLabel('Expiry Date (Optional)'),
                    InkWell(
                      onTap: () async {
                        final date = await showDatePicker(
                          context: context,
                          initialDate: DateTime.now().add(
                            const Duration(days: 365),
                          ),
                          firstDate: DateTime.now(),
                          lastDate: DateTime.now().add(
                            const Duration(days: 3650),
                          ),
                        );
                        if (date != null) {
                          setState(() => _expiryDate = date);
                        }
                      },
                      child: InputDecorator(
                        decoration: _inputDecoration('Select expiry date'),
                        child: Text(
                          _expiryDate != null
                              ? DateFormat('dd MMM yyyy').format(_expiryDate!)
                              : 'Not set',
                          style: TextStyle(
                            color: _expiryDate != null
                                ? Colors.black
                                : Colors.grey,
                          ),
                        ),
                      ),
                    ),
                    SizedBox(height: 16.h),

                    // Remarks
                    _buildLabel('Remarks (Optional)'),
                    TextFormField(
                      controller: _remarksController,
                      decoration: _inputDecoration('Enter remarks'),
                      maxLines: 2,
                    ),
                    SizedBox(height: 24.h),

                    // Submit Button
                    SizedBox(
                      width: double.infinity,
                      height: 50.h,
                      child: ElevatedButton(
                        onPressed: _isSubmitting ? null : _submitEntry,
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
                                'Add Entry',
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

  void _submitEntry() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isSubmitting = true);

    final request = CreateStockEntryRequest(
      productId: _selectedProductId!,
      type: _selectedType,
      quantity: int.parse(_quantityController.text),
      batchNumber: _batchController.text.isNotEmpty
          ? _batchController.text
          : null,
      expiryDate: _expiryDate,
      remarks: _remarksController.text.isNotEmpty
          ? _remarksController.text
          : null,
    );

    widget.onSubmit(request);

    if (mounted) {
      Navigator.pop(context);
    }
  }
}
