/// Trade Partner Journey Models
/// Models for ordering, ledger, schemes, and grievance management

import 'package:equatable/equatable.dart';

// ============================================
// PRODUCT MODELS
// ============================================

/// Product category for organizing products
class ProductCategory extends Equatable {
  final String id;
  final String name;
  final String? iconUrl;
  final int productCount;

  const ProductCategory({
    required this.id,
    required this.name,
    this.iconUrl,
    this.productCount = 0,
  });

  factory ProductCategory.fromJson(Map<String, dynamic> json) {
    return ProductCategory(
      id: json['id']?.toString() ?? '',
      name: json['name']?.toString() ?? '',
      iconUrl: json['iconUrl']?.toString(),
      productCount: int.tryParse(json['productCount']?.toString() ?? '0') ?? 0,
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'name': name,
    'iconUrl': iconUrl,
    'productCount': productCount,
  };

  @override
  List<Object?> get props => [id, name, iconUrl, productCount];
}

/// Product model for catalog
class Product extends Equatable {
  final String id;
  final String name;
  final String? description;
  final String? categoryId;
  final String? categoryName;
  final double price;
  final double? mrp;
  final String unit;
  final String? imageUrl;
  final bool isAvailable;
  final int? stockQuantity;
  final String? sku;

  const Product({
    required this.id,
    required this.name,
    this.description,
    this.categoryId,
    this.categoryName,
    required this.price,
    this.mrp,
    this.unit = 'Pcs',
    this.imageUrl,
    this.isAvailable = true,
    this.stockQuantity,
    this.sku,
  });

  factory Product.fromJson(Map<String, dynamic> json) {
    return Product(
      id: json['id']?.toString() ?? '',
      name: json['name']?.toString() ?? '',
      description: json['description']?.toString(),
      categoryId: json['categoryId']?.toString(),
      categoryName: json['categoryName']?.toString(),
      price: double.tryParse(json['price']?.toString() ?? '0') ?? 0.0,
      mrp: double.tryParse(json['mrp']?.toString() ?? ''),
      unit: json['unit']?.toString() ?? 'Pcs',
      imageUrl: json['imageUrl']?.toString(),
      isAvailable: json['isAvailable'] == true || json['isAvailable'] == 1,
      stockQuantity: int.tryParse(json['stockQuantity']?.toString() ?? ''),
      sku: json['sku']?.toString(),
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'name': name,
    'description': description,
    'categoryId': categoryId,
    'categoryName': categoryName,
    'price': price,
    'mrp': mrp,
    'unit': unit,
    'imageUrl': imageUrl,
    'isAvailable': isAvailable,
    'stockQuantity': stockQuantity,
    'sku': sku,
  };

  @override
  List<Object?> get props => [id, name, price, unit, isAvailable];
}

// ============================================
// ORDER MODELS
// ============================================

/// Order status enum
enum OrderStatus {
  placed,
  approved,
  dispatched,
  delivered,
  cancelled;

  String get displayName {
    switch (this) {
      case OrderStatus.placed:
        return 'Placed';
      case OrderStatus.approved:
        return 'Approved';
      case OrderStatus.dispatched:
        return 'Dispatched';
      case OrderStatus.delivered:
        return 'Delivered';
      case OrderStatus.cancelled:
        return 'Cancelled';
    }
  }

  static OrderStatus fromString(String? status) {
    switch (status?.toLowerCase()) {
      case 'placed':
        return OrderStatus.placed;
      case 'approved':
        return OrderStatus.approved;
      case 'dispatched':
        return OrderStatus.dispatched;
      case 'delivered':
        return OrderStatus.delivered;
      case 'cancelled':
        return OrderStatus.cancelled;
      default:
        return OrderStatus.placed;
    }
  }
}

/// Individual order line item
class OrderItem extends Equatable {
  final String productId;
  final String productName;
  final int quantity;
  final double unitPrice;
  final double totalPrice;
  final String? unit;

  const OrderItem({
    required this.productId,
    required this.productName,
    required this.quantity,
    required this.unitPrice,
    required this.totalPrice,
    this.unit,
  });

  factory OrderItem.fromJson(Map<String, dynamic> json) {
    final qty = int.tryParse(json['quantity']?.toString() ?? '0') ?? 0;
    final price = double.tryParse(json['unitPrice']?.toString() ?? '0') ?? 0.0;
    return OrderItem(
      productId: json['productId']?.toString() ?? '',
      productName: json['productName']?.toString() ?? '',
      quantity: qty,
      unitPrice: price,
      totalPrice:
          double.tryParse(json['totalPrice']?.toString() ?? '') ??
          (qty * price),
      unit: json['unit']?.toString(),
    );
  }

  Map<String, dynamic> toJson() => {
    'productId': productId,
    'productName': productName,
    'quantity': quantity,
    'unitPrice': unitPrice,
    'totalPrice': totalPrice,
    'unit': unit,
  };

  @override
  List<Object?> get props => [productId, quantity, unitPrice];
}

/// Order model
class Order extends Equatable {
  final String id;
  final String? orderNumber;
  final DateTime orderDate;
  final OrderStatus status;
  final List<OrderItem> items;
  final double totalAmount;
  final double? discountAmount;
  final double? taxAmount;
  final double netAmount;
  final String? remarks;
  final String? customerId;
  final String? customerName;
  final DateTime? expectedDeliveryDate;
  final DateTime? deliveredDate;
  final String? invoiceNumber;
  final String? lrNumber;

  const Order({
    required this.id,
    this.orderNumber,
    required this.orderDate,
    required this.status,
    required this.items,
    required this.totalAmount,
    this.discountAmount,
    this.taxAmount,
    required this.netAmount,
    this.remarks,
    this.customerId,
    this.customerName,
    this.expectedDeliveryDate,
    this.deliveredDate,
    this.invoiceNumber,
    this.lrNumber,
  });

  factory Order.fromJson(Map<String, dynamic> json) {
    return Order(
      id: json['id']?.toString() ?? '',
      orderNumber: json['orderNumber']?.toString(),
      orderDate:
          DateTime.tryParse(json['orderDate']?.toString() ?? '') ??
          DateTime.now(),
      status: OrderStatus.fromString(json['status']?.toString()),
      items: (json['items'] as List? ?? [])
          .map((item) => OrderItem.fromJson(item as Map<String, dynamic>))
          .toList(),
      totalAmount:
          double.tryParse(json['totalAmount']?.toString() ?? '0') ?? 0.0,
      discountAmount: double.tryParse(json['discountAmount']?.toString() ?? ''),
      taxAmount: double.tryParse(json['taxAmount']?.toString() ?? ''),
      netAmount: double.tryParse(json['netAmount']?.toString() ?? '0') ?? 0.0,
      remarks: json['remarks']?.toString(),
      customerId: json['customerId']?.toString(),
      customerName: json['customerName']?.toString(),
      expectedDeliveryDate: DateTime.tryParse(
        json['expectedDeliveryDate']?.toString() ?? '',
      ),
      deliveredDate: DateTime.tryParse(json['deliveredDate']?.toString() ?? ''),
      invoiceNumber: json['invoiceNumber']?.toString(),
      lrNumber: json['lrNumber']?.toString(),
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'orderNumber': orderNumber,
    'orderDate': orderDate.toIso8601String(),
    'status': status.name,
    'items': items.map((item) => item.toJson()).toList(),
    'totalAmount': totalAmount,
    'discountAmount': discountAmount,
    'taxAmount': taxAmount,
    'netAmount': netAmount,
    'remarks': remarks,
    'customerId': customerId,
    'customerName': customerName,
    'expectedDeliveryDate': expectedDeliveryDate?.toIso8601String(),
    'deliveredDate': deliveredDate?.toIso8601String(),
    'invoiceNumber': invoiceNumber,
    'lrNumber': lrNumber,
  };

  @override
  List<Object?> get props => [id, orderNumber, status, netAmount];
}

// ============================================
// LEDGER MODELS
// ============================================

/// Ledger entry type
enum LedgerEntryType {
  invoice,
  payment,
  creditNote,
  debitNote,
  adjustment;

  String get displayName {
    switch (this) {
      case LedgerEntryType.invoice:
        return 'Invoice';
      case LedgerEntryType.payment:
        return 'Payment';
      case LedgerEntryType.creditNote:
        return 'Credit Note';
      case LedgerEntryType.debitNote:
        return 'Debit Note';
      case LedgerEntryType.adjustment:
        return 'Adjustment';
    }
  }

  static LedgerEntryType fromString(String? type) {
    switch (type?.toLowerCase()) {
      case 'invoice':
        return LedgerEntryType.invoice;
      case 'payment':
        return LedgerEntryType.payment;
      case 'creditnote':
      case 'credit_note':
        return LedgerEntryType.creditNote;
      case 'debitnote':
      case 'debit_note':
        return LedgerEntryType.debitNote;
      case 'adjustment':
        return LedgerEntryType.adjustment;
      default:
        return LedgerEntryType.invoice;
    }
  }
}

/// Ledger entry model
class LedgerEntry extends Equatable {
  final String id;
  final DateTime date;
  final LedgerEntryType type;
  final String? referenceNumber;
  final String? description;
  final double debitAmount;
  final double creditAmount;
  final double balance;
  final DateTime? dueDate;
  final bool isOverdue;

  const LedgerEntry({
    required this.id,
    required this.date,
    required this.type,
    this.referenceNumber,
    this.description,
    this.debitAmount = 0.0,
    this.creditAmount = 0.0,
    required this.balance,
    this.dueDate,
    this.isOverdue = false,
  });

  factory LedgerEntry.fromJson(Map<String, dynamic> json) {
    final dueDate = DateTime.tryParse(json['dueDate']?.toString() ?? '');
    return LedgerEntry(
      id: json['id']?.toString() ?? '',
      date: DateTime.tryParse(json['date']?.toString() ?? '') ?? DateTime.now(),
      type: LedgerEntryType.fromString(json['type']?.toString()),
      referenceNumber: json['referenceNumber']?.toString(),
      description: json['description']?.toString(),
      debitAmount:
          double.tryParse(json['debitAmount']?.toString() ?? '0') ?? 0.0,
      creditAmount:
          double.tryParse(json['creditAmount']?.toString() ?? '0') ?? 0.0,
      balance: double.tryParse(json['balance']?.toString() ?? '0') ?? 0.0,
      dueDate: dueDate,
      isOverdue: dueDate != null && dueDate.isBefore(DateTime.now()),
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'date': date.toIso8601String(),
    'type': type.name,
    'referenceNumber': referenceNumber,
    'description': description,
    'debitAmount': debitAmount,
    'creditAmount': creditAmount,
    'balance': balance,
    'dueDate': dueDate?.toIso8601String(),
    'isOverdue': isOverdue,
  };

  @override
  List<Object?> get props => [id, date, type, balance];
}

/// Ledger summary model
class LedgerSummary extends Equatable {
  final double totalOutstanding;
  final double overdueAmount;
  final double creditLimit;
  final double availableCredit;
  final int totalInvoices;
  final int overdueInvoices;
  final DateTime? lastPaymentDate;
  final double? lastPaymentAmount;

  const LedgerSummary({
    this.totalOutstanding = 0.0,
    this.overdueAmount = 0.0,
    this.creditLimit = 0.0,
    this.availableCredit = 0.0,
    this.totalInvoices = 0,
    this.overdueInvoices = 0,
    this.lastPaymentDate,
    this.lastPaymentAmount,
  });

  factory LedgerSummary.fromJson(Map<String, dynamic> json) {
    return LedgerSummary(
      totalOutstanding:
          double.tryParse(json['totalOutstanding']?.toString() ?? '0') ?? 0.0,
      overdueAmount:
          double.tryParse(json['overdueAmount']?.toString() ?? '0') ?? 0.0,
      creditLimit:
          double.tryParse(json['creditLimit']?.toString() ?? '0') ?? 0.0,
      availableCredit:
          double.tryParse(json['availableCredit']?.toString() ?? '0') ?? 0.0,
      totalInvoices:
          int.tryParse(json['totalInvoices']?.toString() ?? '0') ?? 0,
      overdueInvoices:
          int.tryParse(json['overdueInvoices']?.toString() ?? '0') ?? 0,
      lastPaymentDate: DateTime.tryParse(
        json['lastPaymentDate']?.toString() ?? '',
      ),
      lastPaymentAmount: double.tryParse(
        json['lastPaymentAmount']?.toString() ?? '',
      ),
    );
  }

  @override
  List<Object?> get props => [totalOutstanding, overdueAmount, creditLimit];
}

// ============================================
// SCHEME MODELS
// ============================================

/// Scheme type
enum SchemeType {
  discount,
  cashback,
  gift,
  bonus,
  combo;

  String get displayName {
    switch (this) {
      case SchemeType.discount:
        return 'Discount';
      case SchemeType.cashback:
        return 'Cashback';
      case SchemeType.gift:
        return 'Gift';
      case SchemeType.bonus:
        return 'Bonus';
      case SchemeType.combo:
        return 'Combo';
    }
  }

  static SchemeType fromString(String? type) {
    switch (type?.toLowerCase()) {
      case 'discount':
        return SchemeType.discount;
      case 'cashback':
        return SchemeType.cashback;
      case 'gift':
        return SchemeType.gift;
      case 'bonus':
        return SchemeType.bonus;
      case 'combo':
        return SchemeType.combo;
      default:
        return SchemeType.discount;
    }
  }
}

/// Scheme model
class Scheme extends Equatable {
  final String id;
  final String name;
  final String? description;
  final SchemeType type;
  final DateTime startDate;
  final DateTime endDate;
  final bool isActive;
  final double? minOrderValue;
  final double? discountPercentage;
  final double? discountAmount;
  final String? giftDescription;
  final List<String>? applicableProductIds;
  final double? earnedBenefit;
  final double? pendingBenefit;
  final bool isEligible;

  const Scheme({
    required this.id,
    required this.name,
    this.description,
    required this.type,
    required this.startDate,
    required this.endDate,
    this.isActive = true,
    this.minOrderValue,
    this.discountPercentage,
    this.discountAmount,
    this.giftDescription,
    this.applicableProductIds,
    this.earnedBenefit,
    this.pendingBenefit,
    this.isEligible = true,
  });

  bool get isExpired => endDate.isBefore(DateTime.now());

  factory Scheme.fromJson(Map<String, dynamic> json) {
    return Scheme(
      id: json['id']?.toString() ?? '',
      name: json['name']?.toString() ?? '',
      description: json['description']?.toString(),
      type: SchemeType.fromString(json['type']?.toString()),
      startDate:
          DateTime.tryParse(json['startDate']?.toString() ?? '') ??
          DateTime.now(),
      endDate:
          DateTime.tryParse(json['endDate']?.toString() ?? '') ??
          DateTime.now().add(const Duration(days: 30)),
      isActive: json['isActive'] == true || json['isActive'] == 1,
      minOrderValue: double.tryParse(json['minOrderValue']?.toString() ?? ''),
      discountPercentage: double.tryParse(
        json['discountPercentage']?.toString() ?? '',
      ),
      discountAmount: double.tryParse(json['discountAmount']?.toString() ?? ''),
      giftDescription: json['giftDescription']?.toString(),
      applicableProductIds: (json['applicableProductIds'] as List?)
          ?.map((e) => e.toString())
          .toList(),
      earnedBenefit: double.tryParse(json['earnedBenefit']?.toString() ?? ''),
      pendingBenefit: double.tryParse(json['pendingBenefit']?.toString() ?? ''),
      isEligible: json['isEligible'] != false && json['isEligible'] != 0,
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'name': name,
    'description': description,
    'type': type.name,
    'startDate': startDate.toIso8601String(),
    'endDate': endDate.toIso8601String(),
    'isActive': isActive,
    'minOrderValue': minOrderValue,
    'discountPercentage': discountPercentage,
    'discountAmount': discountAmount,
    'giftDescription': giftDescription,
    'applicableProductIds': applicableProductIds,
    'earnedBenefit': earnedBenefit,
    'pendingBenefit': pendingBenefit,
    'isEligible': isEligible,
  };

  @override
  List<Object?> get props => [id, name, type, isActive];
}

// ============================================
// GRIEVANCE MODELS
// ============================================

/// Grievance category
enum GrievanceCategory {
  product,
  delivery,
  payment,
  service,
  other;

  String get displayName {
    switch (this) {
      case GrievanceCategory.product:
        return 'Product Issue';
      case GrievanceCategory.delivery:
        return 'Delivery Issue';
      case GrievanceCategory.payment:
        return 'Payment Issue';
      case GrievanceCategory.service:
        return 'Service Issue';
      case GrievanceCategory.other:
        return 'Other';
    }
  }

  static GrievanceCategory fromString(String? category) {
    switch (category?.toLowerCase()) {
      case 'product':
        return GrievanceCategory.product;
      case 'delivery':
        return GrievanceCategory.delivery;
      case 'payment':
        return GrievanceCategory.payment;
      case 'service':
        return GrievanceCategory.service;
      case 'other':
        return GrievanceCategory.other;
      default:
        return GrievanceCategory.other;
    }
  }
}

/// Grievance status
enum GrievanceStatus {
  open,
  inProgress,
  resolved,
  closed;

  String get displayName {
    switch (this) {
      case GrievanceStatus.open:
        return 'Open';
      case GrievanceStatus.inProgress:
        return 'In Progress';
      case GrievanceStatus.resolved:
        return 'Resolved';
      case GrievanceStatus.closed:
        return 'Closed';
    }
  }

  static GrievanceStatus fromString(String? status) {
    switch (status?.toLowerCase()) {
      case 'open':
        return GrievanceStatus.open;
      case 'inprogress':
      case 'in_progress':
        return GrievanceStatus.inProgress;
      case 'resolved':
        return GrievanceStatus.resolved;
      case 'closed':
        return GrievanceStatus.closed;
      default:
        return GrievanceStatus.open;
    }
  }
}

/// Grievance model
class Grievance extends Equatable {
  final String id;
  final String? ticketNumber;
  final GrievanceCategory category;
  final String subject;
  final String description;
  final GrievanceStatus status;
  final DateTime createdDate;
  final DateTime? resolvedDate;
  final String? resolution;
  final List<String>? attachmentUrls;
  final String? orderId;
  final String? invoiceNumber;
  final int? slaHours;
  final bool isSlaBreached;

  const Grievance({
    required this.id,
    this.ticketNumber,
    required this.category,
    required this.subject,
    required this.description,
    required this.status,
    required this.createdDate,
    this.resolvedDate,
    this.resolution,
    this.attachmentUrls,
    this.orderId,
    this.invoiceNumber,
    this.slaHours,
    this.isSlaBreached = false,
  });

  factory Grievance.fromJson(Map<String, dynamic> json) {
    return Grievance(
      id: json['id']?.toString() ?? '',
      ticketNumber: json['ticketNumber']?.toString(),
      category: GrievanceCategory.fromString(json['category']?.toString()),
      subject: json['subject']?.toString() ?? '',
      description: json['description']?.toString() ?? '',
      status: GrievanceStatus.fromString(json['status']?.toString()),
      createdDate:
          DateTime.tryParse(json['createdDate']?.toString() ?? '') ??
          DateTime.now(),
      resolvedDate: DateTime.tryParse(json['resolvedDate']?.toString() ?? ''),
      resolution: json['resolution']?.toString(),
      attachmentUrls: (json['attachmentUrls'] as List?)
          ?.map((e) => e.toString())
          .toList(),
      orderId: json['orderId']?.toString(),
      invoiceNumber: json['invoiceNumber']?.toString(),
      slaHours: int.tryParse(json['slaHours']?.toString() ?? ''),
      isSlaBreached:
          json['isSlaBreached'] == true || json['isSlaBreached'] == 1,
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'ticketNumber': ticketNumber,
    'category': category.name,
    'subject': subject,
    'description': description,
    'status': status.name,
    'createdDate': createdDate.toIso8601String(),
    'resolvedDate': resolvedDate?.toIso8601String(),
    'resolution': resolution,
    'attachmentUrls': attachmentUrls,
    'orderId': orderId,
    'invoiceNumber': invoiceNumber,
    'slaHours': slaHours,
    'isSlaBreached': isSlaBreached,
  };

  @override
  List<Object?> get props => [id, ticketNumber, category, status];
}

/// Create grievance request
class CreateGrievanceRequest {
  final GrievanceCategory category;
  final String subject;
  final String description;
  final String? orderId;
  final String? invoiceNumber;
  final List<String>? attachmentPaths;

  const CreateGrievanceRequest({
    required this.category,
    required this.subject,
    required this.description,
    this.orderId,
    this.invoiceNumber,
    this.attachmentPaths,
  });

  Map<String, dynamic> toJson() => {
    'category': category.name,
    'subject': subject,
    'description': description,
    'orderId': orderId,
    'invoiceNumber': invoiceNumber,
  };
}

// ============================================
// CART MODEL (for ordering flow)
// ============================================

/// Cart item for placing orders
class CartItem {
  final Product product;
  int quantity;

  CartItem({required this.product, this.quantity = 1});

  double get totalPrice => product.price * quantity;

  OrderItem toOrderItem() {
    return OrderItem(
      productId: product.id,
      productName: product.name,
      quantity: quantity,
      unitPrice: product.price,
      totalPrice: totalPrice,
      unit: product.unit,
    );
  }
}
