/// Stock Visibility Models
/// Models for stock entry, stock levels, and aging reports

import 'package:equatable/equatable.dart';

// ============================================
// STOCK ENTRY
// ============================================

enum StockEntryType { opening, receipt, sale, return_, adjustment }

class StockEntry extends Equatable {
  final String id;
  final String productId;
  final String productName;
  final String? productSku;
  final StockEntryType type;
  final int quantity;
  final DateTime entryDate;
  final String? batchNumber;
  final DateTime? expiryDate;
  final String? remarks;
  final String? createdBy;

  const StockEntry({
    required this.id,
    required this.productId,
    required this.productName,
    this.productSku,
    required this.type,
    required this.quantity,
    required this.entryDate,
    this.batchNumber,
    this.expiryDate,
    this.remarks,
    this.createdBy,
  });

  factory StockEntry.fromJson(Map<String, dynamic> json) {
    return StockEntry(
      id: json['id'] as String,
      productId: json['productId'] as String,
      productName: json['productName'] as String,
      productSku: json['productSku'] as String?,
      type: StockEntryType.values.firstWhere(
        (e) => e.name == json['type'],
        orElse: () => StockEntryType.adjustment,
      ),
      quantity: json['quantity'] as int,
      entryDate: DateTime.parse(json['entryDate'] as String),
      batchNumber: json['batchNumber'] as String?,
      expiryDate: json['expiryDate'] != null
          ? DateTime.parse(json['expiryDate'] as String)
          : null,
      remarks: json['remarks'] as String?,
      createdBy: json['createdBy'] as String?,
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'productId': productId,
    'productName': productName,
    'productSku': productSku,
    'type': type.name,
    'quantity': quantity,
    'entryDate': entryDate.toIso8601String(),
    'batchNumber': batchNumber,
    'expiryDate': expiryDate?.toIso8601String(),
    'remarks': remarks,
    'createdBy': createdBy,
  };

  @override
  List<Object?> get props => [id, productId, type, quantity, entryDate];
}

// ============================================
// STOCK LEVEL
// ============================================

class StockLevel extends Equatable {
  final String productId;
  final String productName;
  final String? productSku;
  final String? categoryName;
  final int currentStock;
  final int minStock;
  final int maxStock;
  final String unit;
  final DateTime lastUpdated;
  final List<BatchStock> batches;

  const StockLevel({
    required this.productId,
    required this.productName,
    this.productSku,
    this.categoryName,
    required this.currentStock,
    this.minStock = 0,
    this.maxStock = 999999,
    this.unit = 'Units',
    required this.lastUpdated,
    this.batches = const [],
  });

  bool get isLowStock => currentStock <= minStock;
  bool get isOverstock => currentStock >= maxStock;
  bool get isHealthy => !isLowStock && !isOverstock;

  factory StockLevel.fromJson(Map<String, dynamic> json) {
    return StockLevel(
      productId: json['productId'] as String,
      productName: json['productName'] as String,
      productSku: json['productSku'] as String?,
      categoryName: json['categoryName'] as String?,
      currentStock: json['currentStock'] as int,
      minStock: json['minStock'] as int? ?? 0,
      maxStock: json['maxStock'] as int? ?? 999999,
      unit: json['unit'] as String? ?? 'Units',
      lastUpdated: DateTime.parse(json['lastUpdated'] as String),
      batches:
          (json['batches'] as List<dynamic>?)
              ?.map((b) => BatchStock.fromJson(b as Map<String, dynamic>))
              .toList() ??
          [],
    );
  }

  Map<String, dynamic> toJson() => {
    'productId': productId,
    'productName': productName,
    'productSku': productSku,
    'categoryName': categoryName,
    'currentStock': currentStock,
    'minStock': minStock,
    'maxStock': maxStock,
    'unit': unit,
    'lastUpdated': lastUpdated.toIso8601String(),
    'batches': batches.map((b) => b.toJson()).toList(),
  };

  @override
  List<Object?> get props => [productId, currentStock, lastUpdated];
}

// ============================================
// BATCH STOCK
// ============================================

class BatchStock extends Equatable {
  final String batchNumber;
  final int quantity;
  final DateTime? manufacturingDate;
  final DateTime? expiryDate;

  const BatchStock({
    required this.batchNumber,
    required this.quantity,
    this.manufacturingDate,
    this.expiryDate,
  });

  int get daysToExpiry => expiryDate != null
      ? expiryDate!.difference(DateTime.now()).inDays
      : 999999;

  bool get isExpired => daysToExpiry < 0;
  bool get isNearExpiry => daysToExpiry >= 0 && daysToExpiry <= 30;
  bool get isAgingStock => daysToExpiry >= 31 && daysToExpiry <= 90;

  factory BatchStock.fromJson(Map<String, dynamic> json) {
    return BatchStock(
      batchNumber: json['batchNumber'] as String,
      quantity: json['quantity'] as int,
      manufacturingDate: json['manufacturingDate'] != null
          ? DateTime.parse(json['manufacturingDate'] as String)
          : null,
      expiryDate: json['expiryDate'] != null
          ? DateTime.parse(json['expiryDate'] as String)
          : null,
    );
  }

  Map<String, dynamic> toJson() => {
    'batchNumber': batchNumber,
    'quantity': quantity,
    'manufacturingDate': manufacturingDate?.toIso8601String(),
    'expiryDate': expiryDate?.toIso8601String(),
  };

  @override
  List<Object?> get props => [batchNumber, quantity, expiryDate];
}

// ============================================
// AGING STOCK REPORT
// ============================================

enum AgingCategory { fresh, aging, nearExpiry, expired }

class AgingStockItem extends Equatable {
  final String productId;
  final String productName;
  final String? productSku;
  final String batchNumber;
  final int quantity;
  final DateTime? expiryDate;
  final int daysToExpiry;
  final AgingCategory category;
  final double stockValue;

  const AgingStockItem({
    required this.productId,
    required this.productName,
    this.productSku,
    required this.batchNumber,
    required this.quantity,
    this.expiryDate,
    required this.daysToExpiry,
    required this.category,
    this.stockValue = 0,
  });

  factory AgingStockItem.fromJson(Map<String, dynamic> json) {
    final days = json['daysToExpiry'] as int;
    AgingCategory cat;
    if (days < 0) {
      cat = AgingCategory.expired;
    } else if (days <= 30) {
      cat = AgingCategory.nearExpiry;
    } else if (days <= 90) {
      cat = AgingCategory.aging;
    } else {
      cat = AgingCategory.fresh;
    }

    return AgingStockItem(
      productId: json['productId'] as String,
      productName: json['productName'] as String,
      productSku: json['productSku'] as String?,
      batchNumber: json['batchNumber'] as String,
      quantity: json['quantity'] as int,
      expiryDate: json['expiryDate'] != null
          ? DateTime.parse(json['expiryDate'] as String)
          : null,
      daysToExpiry: days,
      category: cat,
      stockValue: (json['stockValue'] as num?)?.toDouble() ?? 0,
    );
  }

  Map<String, dynamic> toJson() => {
    'productId': productId,
    'productName': productName,
    'productSku': productSku,
    'batchNumber': batchNumber,
    'quantity': quantity,
    'expiryDate': expiryDate?.toIso8601String(),
    'daysToExpiry': daysToExpiry,
    'category': category.name,
    'stockValue': stockValue,
  };

  @override
  List<Object?> get props => [productId, batchNumber, daysToExpiry];
}

class AgingStockSummary extends Equatable {
  final int totalItems;
  final int freshCount;
  final int agingCount;
  final int nearExpiryCount;
  final int expiredCount;
  final double totalValue;
  final double atRiskValue;

  const AgingStockSummary({
    this.totalItems = 0,
    this.freshCount = 0,
    this.agingCount = 0,
    this.nearExpiryCount = 0,
    this.expiredCount = 0,
    this.totalValue = 0,
    this.atRiskValue = 0,
  });

  factory AgingStockSummary.fromJson(Map<String, dynamic> json) {
    return AgingStockSummary(
      totalItems: json['totalItems'] as int? ?? 0,
      freshCount: json['freshCount'] as int? ?? 0,
      agingCount: json['agingCount'] as int? ?? 0,
      nearExpiryCount: json['nearExpiryCount'] as int? ?? 0,
      expiredCount: json['expiredCount'] as int? ?? 0,
      totalValue: (json['totalValue'] as num?)?.toDouble() ?? 0,
      atRiskValue: (json['atRiskValue'] as num?)?.toDouble() ?? 0,
    );
  }

  @override
  List<Object?> get props => [
    totalItems,
    freshCount,
    agingCount,
    nearExpiryCount,
    expiredCount,
  ];
}

// ============================================
// STOCK ENTRY REQUEST
// ============================================

class CreateStockEntryRequest {
  final String productId;
  final StockEntryType type;
  final int quantity;
  final String? batchNumber;
  final DateTime? expiryDate;
  final String? remarks;

  const CreateStockEntryRequest({
    required this.productId,
    required this.type,
    required this.quantity,
    this.batchNumber,
    this.expiryDate,
    this.remarks,
  });

  Map<String, dynamic> toJson() => {
    'productId': productId,
    'type': type.name,
    'quantity': quantity,
    'batchNumber': batchNumber,
    'expiryDate': expiryDate?.toIso8601String(),
    'remarks': remarks,
  };
}
