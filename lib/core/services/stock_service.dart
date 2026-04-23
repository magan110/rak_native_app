/// Stock Visibility Service
/// API service for stock entry, stock levels, and aging reports

import 'package:flutter/foundation.dart';
import '../models/stock_models.dart';

class StockService {
  // ============================================
  // STOCK LEVELS
  // ============================================

  /// Get all stock levels
  static Future<List<StockLevel>> getStockLevels() async {
    try {
      await Future.delayed(const Duration(milliseconds: 500));
      return _mockStockLevels;
    } catch (e) {
      debugPrint('Failed to fetch stock levels: $e');
      return [];
    }
  }

  /// Get stock level for a specific product
  static Future<StockLevel?> getStockLevel(String productId) async {
    try {
      await Future.delayed(const Duration(milliseconds: 300));
      return _mockStockLevels.firstWhere((s) => s.productId == productId);
    } catch (e) {
      debugPrint('Failed to fetch stock level: $e');
      return null;
    }
  }

  /// Get low stock items
  static Future<List<StockLevel>> getLowStockItems() async {
    try {
      await Future.delayed(const Duration(milliseconds: 400));
      return _mockStockLevels.where((s) => s.isLowStock).toList();
    } catch (e) {
      debugPrint('Failed to fetch low stock items: $e');
      return [];
    }
  }

  // ============================================
  // STOCK ENTRIES
  // ============================================

  /// Get stock entries with optional filters
  static Future<List<StockEntry>> getStockEntries({
    String? productId,
    StockEntryType? type,
    DateTime? fromDate,
    DateTime? toDate,
  }) async {
    try {
      await Future.delayed(const Duration(milliseconds: 500));

      var entries = _mockStockEntries;

      if (productId != null) {
        entries = entries.where((e) => e.productId == productId).toList();
      }
      if (type != null) {
        entries = entries.where((e) => e.type == type).toList();
      }
      if (fromDate != null) {
        entries = entries.where((e) => e.entryDate.isAfter(fromDate)).toList();
      }
      if (toDate != null) {
        entries = entries.where((e) => e.entryDate.isBefore(toDate)).toList();
      }

      return entries;
    } catch (e) {
      debugPrint('Failed to fetch stock entries: $e');
      return [];
    }
  }

  /// Create a new stock entry
  static Future<StockEntry?> createStockEntry(
    CreateStockEntryRequest request,
  ) async {
    try {
      await Future.delayed(const Duration(milliseconds: 600));

      // Find product name from mock products
      final productName = _getProductName(request.productId);

      final entry = StockEntry(
        id: 'STK${DateTime.now().millisecondsSinceEpoch}',
        productId: request.productId,
        productName: productName,
        type: request.type,
        quantity: request.quantity,
        entryDate: DateTime.now(),
        batchNumber: request.batchNumber,
        expiryDate: request.expiryDate,
        remarks: request.remarks,
        createdBy: 'Current User',
      );

      _mockStockEntries.insert(0, entry);

      // Update stock level
      _updateStockLevel(request.productId, request.type, request.quantity);

      return entry;
    } catch (e) {
      debugPrint('Failed to create stock entry: $e');
      return null;
    }
  }

  // ============================================
  // AGING STOCK REPORT
  // ============================================

  /// Get aging stock summary
  static Future<AgingStockSummary> getAgingStockSummary() async {
    try {
      await Future.delayed(const Duration(milliseconds: 400));
      return _mockAgingSummary;
    } catch (e) {
      debugPrint('Failed to fetch aging summary: $e');
      return const AgingStockSummary();
    }
  }

  /// Get aging stock items
  static Future<List<AgingStockItem>> getAgingStockItems({
    AgingCategory? category,
  }) async {
    try {
      await Future.delayed(const Duration(milliseconds: 500));

      if (category != null) {
        return _mockAgingItems.where((i) => i.category == category).toList();
      }
      return _mockAgingItems;
    } catch (e) {
      debugPrint('Failed to fetch aging items: $e');
      return [];
    }
  }

  /// Get expired stock items
  static Future<List<AgingStockItem>> getExpiredStock() async {
    return getAgingStockItems(category: AgingCategory.expired);
  }

  /// Get near-expiry stock items
  static Future<List<AgingStockItem>> getNearExpiryStock() async {
    return getAgingStockItems(category: AgingCategory.nearExpiry);
  }

  // ============================================
  // HELPER METHODS
  // ============================================

  static String _getProductName(String productId) {
    // This would normally come from the product catalog
    final products = {
      'PRD001': 'RAK Premium Wall Putty',
      'PRD002': 'RAK White Cement Putty',
      'PRD003': 'RAK Interior Primer',
      'PRD004': 'RAK Exterior Primer',
      'PRD005': 'RAK Luxury Emulsion',
      'PRD006': 'RAK Weathershield',
      'PRD007': 'RAK Waterproof Coating',
    };
    return products[productId] ?? 'Unknown Product';
  }

  static void _updateStockLevel(
    String productId,
    StockEntryType type,
    int qty,
  ) {
    final index = _mockStockLevels.indexWhere((s) => s.productId == productId);
    if (index >= 0) {
      final current = _mockStockLevels[index];
      int newQty = current.currentStock;

      switch (type) {
        case StockEntryType.receipt:
        case StockEntryType.return_:
          newQty += qty;
          break;
        case StockEntryType.sale:
          newQty -= qty;
          break;
        case StockEntryType.adjustment:
          newQty = qty; // Direct set
          break;
        case StockEntryType.opening:
          newQty = qty;
          break;
      }

      _mockStockLevels[index] = StockLevel(
        productId: current.productId,
        productName: current.productName,
        productSku: current.productSku,
        categoryName: current.categoryName,
        currentStock: newQty,
        minStock: current.minStock,
        maxStock: current.maxStock,
        unit: current.unit,
        lastUpdated: DateTime.now(),
        batches: current.batches,
      );
    }
  }
}

// ============================================
// MOCK DATA
// ============================================

final List<StockLevel> _mockStockLevels = [
  StockLevel(
    productId: 'PRD001',
    productName: 'RAK Premium Wall Putty',
    productSku: 'RAK-WP-001',
    categoryName: 'Wall Putty',
    currentStock: 45,
    minStock: 20,
    maxStock: 200,
    unit: 'Bags',
    lastUpdated: DateTime.now().subtract(const Duration(hours: 2)),
    batches: [
      BatchStock(
        batchNumber: 'WP-2024-001',
        quantity: 25,
        manufacturingDate: DateTime.now().subtract(const Duration(days: 60)),
        expiryDate: DateTime.now().add(const Duration(days: 300)),
      ),
      BatchStock(
        batchNumber: 'WP-2024-002',
        quantity: 20,
        manufacturingDate: DateTime.now().subtract(const Duration(days: 30)),
        expiryDate: DateTime.now().add(const Duration(days: 330)),
      ),
    ],
  ),
  StockLevel(
    productId: 'PRD002',
    productName: 'RAK White Cement Putty',
    productSku: 'RAK-WP-002',
    categoryName: 'Wall Putty',
    currentStock: 12,
    minStock: 15,
    maxStock: 150,
    unit: 'Bags',
    lastUpdated: DateTime.now().subtract(const Duration(hours: 5)),
    batches: [
      BatchStock(
        batchNumber: 'WC-2024-001',
        quantity: 12,
        manufacturingDate: DateTime.now().subtract(const Duration(days: 45)),
        expiryDate: DateTime.now().add(const Duration(days: 320)),
      ),
    ],
  ),
  StockLevel(
    productId: 'PRD003',
    productName: 'RAK Interior Primer',
    productSku: 'RAK-PR-001',
    categoryName: 'Primers',
    currentStock: 28,
    minStock: 10,
    maxStock: 100,
    unit: 'Buckets',
    lastUpdated: DateTime.now().subtract(const Duration(hours: 1)),
    batches: [
      BatchStock(
        batchNumber: 'IP-2024-001',
        quantity: 28,
        manufacturingDate: DateTime.now().subtract(const Duration(days: 30)),
        expiryDate: DateTime.now().add(const Duration(days: 700)),
      ),
    ],
  ),
  StockLevel(
    productId: 'PRD005',
    productName: 'RAK Luxury Emulsion',
    productSku: 'RAK-PT-001',
    categoryName: 'Paints',
    currentStock: 35,
    minStock: 15,
    maxStock: 120,
    unit: 'Buckets',
    lastUpdated: DateTime.now().subtract(const Duration(hours: 3)),
    batches: [
      BatchStock(
        batchNumber: 'LE-2024-001',
        quantity: 20,
        manufacturingDate: DateTime.now().subtract(const Duration(days: 90)),
        expiryDate: DateTime.now().add(
          const Duration(days: 25),
        ), // Near expiry!
      ),
      BatchStock(
        batchNumber: 'LE-2024-002',
        quantity: 15,
        manufacturingDate: DateTime.now().subtract(const Duration(days: 15)),
        expiryDate: DateTime.now().add(const Duration(days: 720)),
      ),
    ],
  ),
  StockLevel(
    productId: 'PRD007',
    productName: 'RAK Waterproof Coating',
    productSku: 'RAK-WF-001',
    categoryName: 'Waterproofing',
    currentStock: 8,
    minStock: 10,
    maxStock: 80,
    unit: 'Buckets',
    lastUpdated: DateTime.now().subtract(const Duration(days: 1)),
    batches: [
      BatchStock(
        batchNumber: 'WF-2023-010',
        quantity: 8,
        manufacturingDate: DateTime.now().subtract(const Duration(days: 180)),
        expiryDate: DateTime.now().add(const Duration(days: 60)), // Aging
      ),
    ],
  ),
];

final List<StockEntry> _mockStockEntries = [
  StockEntry(
    id: 'STK001',
    productId: 'PRD001',
    productName: 'RAK Premium Wall Putty',
    productSku: 'RAK-WP-001',
    type: StockEntryType.receipt,
    quantity: 50,
    entryDate: DateTime.now().subtract(const Duration(days: 5)),
    batchNumber: 'WP-2024-002',
    remarks: 'Stock replenishment',
    createdBy: 'John Doe',
  ),
  StockEntry(
    id: 'STK002',
    productId: 'PRD001',
    productName: 'RAK Premium Wall Putty',
    productSku: 'RAK-WP-001',
    type: StockEntryType.sale,
    quantity: 25,
    entryDate: DateTime.now().subtract(const Duration(days: 3)),
    remarks: 'Order ORD-2024-001',
    createdBy: 'John Doe',
  ),
  StockEntry(
    id: 'STK003',
    productId: 'PRD005',
    productName: 'RAK Luxury Emulsion',
    productSku: 'RAK-PT-001',
    type: StockEntryType.receipt,
    quantity: 30,
    entryDate: DateTime.now().subtract(const Duration(days: 2)),
    batchNumber: 'LE-2024-002',
    remarks: 'New batch received',
    createdBy: 'Jane Smith',
  ),
  StockEntry(
    id: 'STK004',
    productId: 'PRD007',
    productName: 'RAK Waterproof Coating',
    productSku: 'RAK-WF-001',
    type: StockEntryType.sale,
    quantity: 5,
    entryDate: DateTime.now().subtract(const Duration(days: 1)),
    remarks: 'Order ORD-2024-003',
    createdBy: 'John Doe',
  ),
];

const AgingStockSummary _mockAgingSummary = AgingStockSummary(
  totalItems: 5,
  freshCount: 2,
  agingCount: 1,
  nearExpiryCount: 1,
  expiredCount: 0,
  totalValue: 125000,
  atRiskValue: 35000,
);

final List<AgingStockItem> _mockAgingItems = [
  AgingStockItem(
    productId: 'PRD005',
    productName: 'RAK Luxury Emulsion',
    productSku: 'RAK-PT-001',
    batchNumber: 'LE-2024-001',
    quantity: 20,
    expiryDate: DateTime.now().add(const Duration(days: 25)),
    daysToExpiry: 25,
    category: AgingCategory.nearExpiry,
    stockValue: 50000,
  ),
  AgingStockItem(
    productId: 'PRD007',
    productName: 'RAK Waterproof Coating',
    productSku: 'RAK-WF-001',
    batchNumber: 'WF-2023-010',
    quantity: 8,
    expiryDate: DateTime.now().add(const Duration(days: 60)),
    daysToExpiry: 60,
    category: AgingCategory.aging,
    stockValue: 14400,
  ),
  AgingStockItem(
    productId: 'PRD001',
    productName: 'RAK Premium Wall Putty',
    productSku: 'RAK-WP-001',
    batchNumber: 'WP-2024-001',
    quantity: 25,
    expiryDate: DateTime.now().add(const Duration(days: 300)),
    daysToExpiry: 300,
    category: AgingCategory.fresh,
    stockValue: 11250,
  ),
  AgingStockItem(
    productId: 'PRD003',
    productName: 'RAK Interior Primer',
    productSku: 'RAK-PR-001',
    batchNumber: 'IP-2024-001',
    quantity: 28,
    expiryDate: DateTime.now().add(const Duration(days: 700)),
    daysToExpiry: 700,
    category: AgingCategory.fresh,
    stockValue: 33600,
  ),
];
