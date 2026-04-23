/// Trade Partner Journey Service
/// API service for product ordering, ledger, schemes, and grievance management

import 'package:flutter/foundation.dart';
import '../models/trade_partner_models.dart';

class TradePartnerService {
  // ============================================
  // PRODUCT CATALOG
  // ============================================

  /// Fetch product categories
  static Future<List<ProductCategory>> getCategories() async {
    try {
      // TODO: Replace with actual API call when backend is ready
      await Future.delayed(const Duration(milliseconds: 500));
      return _mockCategories;
    } catch (e) {
      debugPrint('Failed to fetch categories: $e');
      return [];
    }
  }

  /// Fetch products by category
  static Future<List<Product>> getProducts({String? categoryId}) async {
    try {
      // TODO: Replace with actual API call when backend is ready
      await Future.delayed(const Duration(milliseconds: 500));
      if (categoryId != null) {
        return _mockProducts.where((p) => p.categoryId == categoryId).toList();
      }
      return _mockProducts;
    } catch (e) {
      debugPrint('Failed to fetch products: $e');
      return [];
    }
  }

  /// Search products
  static Future<List<Product>> searchProducts(String query) async {
    try {
      await Future.delayed(const Duration(milliseconds: 300));
      final lowerQuery = query.toLowerCase();
      return _mockProducts
          .where(
            (p) =>
                p.name.toLowerCase().contains(lowerQuery) ||
                (p.description?.toLowerCase().contains(lowerQuery) ?? false) ||
                (p.sku?.toLowerCase().contains(lowerQuery) ?? false),
          )
          .toList();
    } catch (e) {
      debugPrint('Failed to search products: $e');
      return [];
    }
  }

  // ============================================
  // ORDERS
  // ============================================

  /// Place a new order
  static Future<Order?> placeOrder({
    required List<CartItem> cartItems,
    String? remarks,
  }) async {
    try {
      await Future.delayed(const Duration(milliseconds: 800));

      // Create mock order
      final items = cartItems.map((item) => item.toOrderItem()).toList();
      final totalAmount = items.fold<double>(
        0,
        (sum, item) => sum + item.totalPrice,
      );

      final order = Order(
        id: 'ORD${DateTime.now().millisecondsSinceEpoch}',
        orderNumber:
            'RAK-${DateTime.now().year}-${(_mockOrders.length + 1).toString().padLeft(5, '0')}',
        orderDate: DateTime.now(),
        status: OrderStatus.placed,
        items: items,
        totalAmount: totalAmount,
        netAmount: totalAmount,
        remarks: remarks,
      );

      _mockOrders.insert(0, order);
      return order;
    } catch (e) {
      debugPrint('Failed to place order: $e');
      return null;
    }
  }

  /// Get order history
  static Future<List<Order>> getOrders({OrderStatus? status}) async {
    try {
      await Future.delayed(const Duration(milliseconds: 500));

      if (status != null) {
        return _mockOrders.where((o) => o.status == status).toList();
      }
      return _mockOrders;
    } catch (e) {
      debugPrint('Failed to fetch orders: $e');
      return [];
    }
  }

  /// Get single order details
  static Future<Order?> getOrderDetails(String orderId) async {
    try {
      await Future.delayed(const Duration(milliseconds: 300));
      return _mockOrders.firstWhere((o) => o.id == orderId);
    } catch (e) {
      debugPrint('Failed to fetch order details: $e');
      return null;
    }
  }

  // ============================================
  // LEDGER
  // ============================================

  /// Get ledger summary
  static Future<LedgerSummary> getLedgerSummary() async {
    try {
      await Future.delayed(const Duration(milliseconds: 500));
      return _mockLedgerSummary;
    } catch (e) {
      debugPrint('Failed to fetch ledger summary: $e');
      return const LedgerSummary();
    }
  }

  /// Get ledger entries
  static Future<List<LedgerEntry>> getLedgerEntries({
    DateTime? fromDate,
    DateTime? toDate,
  }) async {
    try {
      await Future.delayed(const Duration(milliseconds: 500));

      var entries = _mockLedgerEntries;
      if (fromDate != null) {
        entries = entries.where((e) => e.date.isAfter(fromDate)).toList();
      }
      if (toDate != null) {
        entries = entries.where((e) => e.date.isBefore(toDate)).toList();
      }
      return entries;
    } catch (e) {
      debugPrint('Failed to fetch ledger entries: $e');
      return [];
    }
  }

  /// Get statement of account
  static Future<List<LedgerEntry>> getStatementOfAccount({
    required DateTime fromDate,
    required DateTime toDate,
  }) async {
    return getLedgerEntries(fromDate: fromDate, toDate: toDate);
  }

  // ============================================
  // SCHEMES
  // ============================================

  /// Get active schemes
  static Future<List<Scheme>> getActiveSchemes() async {
    try {
      await Future.delayed(const Duration(milliseconds: 500));
      return _mockSchemes.where((s) => s.isActive && !s.isExpired).toList();
    } catch (e) {
      debugPrint('Failed to fetch schemes: $e');
      return [];
    }
  }

  /// Get all schemes (including expired)
  static Future<List<Scheme>> getAllSchemes() async {
    try {
      await Future.delayed(const Duration(milliseconds: 500));
      return _mockSchemes;
    } catch (e) {
      debugPrint('Failed to fetch all schemes: $e');
      return [];
    }
  }

  // ============================================
  // GRIEVANCE
  // ============================================

  /// Submit a new grievance
  static Future<Grievance?> submitGrievance(
    CreateGrievanceRequest request,
  ) async {
    try {
      await Future.delayed(const Duration(milliseconds: 800));

      final grievance = Grievance(
        id: 'GRV${DateTime.now().millisecondsSinceEpoch}',
        ticketNumber:
            'TKT-${DateTime.now().year}-${(_mockGrievances.length + 1).toString().padLeft(4, '0')}',
        category: request.category,
        subject: request.subject,
        description: request.description,
        status: GrievanceStatus.open,
        createdDate: DateTime.now(),
        orderId: request.orderId,
        invoiceNumber: request.invoiceNumber,
        slaHours: 48,
      );

      _mockGrievances.insert(0, grievance);
      return grievance;
    } catch (e) {
      debugPrint('Failed to submit grievance: $e');
      return null;
    }
  }

  /// Get grievances
  static Future<List<Grievance>> getGrievances({
    GrievanceStatus? status,
  }) async {
    try {
      await Future.delayed(const Duration(milliseconds: 500));

      if (status != null) {
        return _mockGrievances.where((g) => g.status == status).toList();
      }
      return _mockGrievances;
    } catch (e) {
      debugPrint('Failed to fetch grievances: $e');
      return [];
    }
  }

  /// Get grievance details
  static Future<Grievance?> getGrievanceDetails(String grievanceId) async {
    try {
      await Future.delayed(const Duration(milliseconds: 300));
      return _mockGrievances.firstWhere((g) => g.id == grievanceId);
    } catch (e) {
      debugPrint('Failed to fetch grievance details: $e');
      return null;
    }
  }
}

// ============================================
// MOCK DATA
// ============================================

final List<ProductCategory> _mockCategories = [
  const ProductCategory(id: 'CAT001', name: 'Wall Putty', productCount: 5),
  const ProductCategory(id: 'CAT002', name: 'Primers', productCount: 4),
  const ProductCategory(id: 'CAT003', name: 'Paints', productCount: 8),
  const ProductCategory(id: 'CAT004', name: 'Waterproofing', productCount: 3),
  const ProductCategory(id: 'CAT005', name: 'Textures', productCount: 6),
];

final List<Product> _mockProducts = [
  // Wall Putty
  const Product(
    id: 'PRD001',
    name: 'RAK Premium Wall Putty',
    description: 'High-quality wall putty for smooth finish',
    categoryId: 'CAT001',
    categoryName: 'Wall Putty',
    price: 450.00,
    mrp: 500.00,
    unit: 'Bag (40kg)',
    isAvailable: true,
    stockQuantity: 100,
    sku: 'RAK-WP-001',
  ),
  const Product(
    id: 'PRD002',
    name: 'RAK White Cement Putty',
    description: 'White cement based wall putty',
    categoryId: 'CAT001',
    categoryName: 'Wall Putty',
    price: 380.00,
    mrp: 420.00,
    unit: 'Bag (20kg)',
    isAvailable: true,
    stockQuantity: 150,
    sku: 'RAK-WP-002',
  ),
  // Primers
  const Product(
    id: 'PRD003',
    name: 'RAK Interior Primer',
    description: 'Water-based interior primer',
    categoryId: 'CAT002',
    categoryName: 'Primers',
    price: 1200.00,
    mrp: 1400.00,
    unit: 'Bucket (20L)',
    isAvailable: true,
    stockQuantity: 50,
    sku: 'RAK-PR-001',
  ),
  const Product(
    id: 'PRD004',
    name: 'RAK Exterior Primer',
    description: 'Weather-resistant exterior primer',
    categoryId: 'CAT002',
    categoryName: 'Primers',
    price: 1500.00,
    mrp: 1700.00,
    unit: 'Bucket (20L)',
    isAvailable: true,
    stockQuantity: 45,
    sku: 'RAK-PR-002',
  ),
  // Paints
  const Product(
    id: 'PRD005',
    name: 'RAK Luxury Emulsion',
    description: 'Premium interior emulsion paint',
    categoryId: 'CAT003',
    categoryName: 'Paints',
    price: 2500.00,
    mrp: 2800.00,
    unit: 'Bucket (20L)',
    isAvailable: true,
    stockQuantity: 80,
    sku: 'RAK-PT-001',
  ),
  const Product(
    id: 'PRD006',
    name: 'RAK Weathershield',
    description: 'Exterior weather-resistant paint',
    categoryId: 'CAT003',
    categoryName: 'Paints',
    price: 3200.00,
    mrp: 3500.00,
    unit: 'Bucket (20L)',
    isAvailable: true,
    stockQuantity: 60,
    sku: 'RAK-PT-002',
  ),
  // Waterproofing
  const Product(
    id: 'PRD007',
    name: 'RAK Waterproof Coating',
    description: 'Flexible waterproof coating for roofs and walls',
    categoryId: 'CAT004',
    categoryName: 'Waterproofing',
    price: 1800.00,
    mrp: 2000.00,
    unit: 'Bucket (10L)',
    isAvailable: true,
    stockQuantity: 40,
    sku: 'RAK-WF-001',
  ),
];

final List<Order> _mockOrders = [
  Order(
    id: 'ORD001',
    orderNumber: 'RAK-2024-00001',
    orderDate: DateTime.now().subtract(const Duration(days: 5)),
    status: OrderStatus.delivered,
    items: const [
      OrderItem(
        productId: 'PRD001',
        productName: 'RAK Premium Wall Putty',
        quantity: 10,
        unitPrice: 450,
        totalPrice: 4500,
      ),
      OrderItem(
        productId: 'PRD003',
        productName: 'RAK Interior Primer',
        quantity: 5,
        unitPrice: 1200,
        totalPrice: 6000,
      ),
    ],
    totalAmount: 10500,
    netAmount: 10500,
    invoiceNumber: 'INV-2024-00001',
    deliveredDate: DateTime.now().subtract(const Duration(days: 2)),
  ),
  Order(
    id: 'ORD002',
    orderNumber: 'RAK-2024-00002',
    orderDate: DateTime.now().subtract(const Duration(days: 2)),
    status: OrderStatus.dispatched,
    items: const [
      OrderItem(
        productId: 'PRD005',
        productName: 'RAK Luxury Emulsion',
        quantity: 8,
        unitPrice: 2500,
        totalPrice: 20000,
      ),
    ],
    totalAmount: 20000,
    netAmount: 20000,
    expectedDeliveryDate: DateTime.now().add(const Duration(days: 1)),
    lrNumber: 'LR-78901',
  ),
  Order(
    id: 'ORD003',
    orderNumber: 'RAK-2024-00003',
    orderDate: DateTime.now().subtract(const Duration(days: 1)),
    status: OrderStatus.approved,
    items: const [
      OrderItem(
        productId: 'PRD007',
        productName: 'RAK Waterproof Coating',
        quantity: 15,
        unitPrice: 1800,
        totalPrice: 27000,
      ),
    ],
    totalAmount: 27000,
    netAmount: 27000,
  ),
];

const LedgerSummary _mockLedgerSummary = LedgerSummary(
  totalOutstanding: 45500.00,
  overdueAmount: 10500.00,
  creditLimit: 100000.00,
  availableCredit: 54500.00,
  totalInvoices: 5,
  overdueInvoices: 1,
);

final List<LedgerEntry> _mockLedgerEntries = [
  LedgerEntry(
    id: 'LED001',
    date: DateTime.now().subtract(const Duration(days: 30)),
    type: LedgerEntryType.invoice,
    referenceNumber: 'INV-2024-00001',
    description: 'Order RAK-2024-00001',
    debitAmount: 10500,
    creditAmount: 0,
    balance: 10500,
    dueDate: DateTime.now().subtract(const Duration(days: 5)),
  ),
  LedgerEntry(
    id: 'LED002',
    date: DateTime.now().subtract(const Duration(days: 20)),
    type: LedgerEntryType.invoice,
    referenceNumber: 'INV-2024-00002',
    description: 'Order RAK-2024-00002',
    debitAmount: 20000,
    creditAmount: 0,
    balance: 30500,
    dueDate: DateTime.now().add(const Duration(days: 10)),
  ),
  LedgerEntry(
    id: 'LED003',
    date: DateTime.now().subtract(const Duration(days: 15)),
    type: LedgerEntryType.payment,
    referenceNumber: 'PAY-001',
    description: 'Online Payment',
    debitAmount: 0,
    creditAmount: 15000,
    balance: 15500,
  ),
  LedgerEntry(
    id: 'LED004',
    date: DateTime.now().subtract(const Duration(days: 5)),
    type: LedgerEntryType.invoice,
    referenceNumber: 'INV-2024-00003',
    description: 'Order RAK-2024-00003',
    debitAmount: 30000,
    creditAmount: 0,
    balance: 45500,
    dueDate: DateTime.now().add(const Duration(days: 25)),
  ),
];

final List<Scheme> _mockSchemes = [
  Scheme(
    id: 'SCH001',
    name: 'Monsoon Bonanza',
    description: 'Get 10% discount on all waterproofing products',
    type: SchemeType.discount,
    startDate: DateTime.now().subtract(const Duration(days: 10)),
    endDate: DateTime.now().add(const Duration(days: 20)),
    isActive: true,
    discountPercentage: 10,
    applicableProductIds: const ['PRD007'],
    earnedBenefit: 1800,
    pendingBenefit: 0,
    isEligible: true,
  ),
  Scheme(
    id: 'SCH002',
    name: 'Paint Fest 2024',
    description: 'Buy 10 buckets of paint and get 1 free',
    type: SchemeType.bonus,
    startDate: DateTime.now().subtract(const Duration(days: 5)),
    endDate: DateTime.now().add(const Duration(days: 25)),
    isActive: true,
    minOrderValue: 25000,
    giftDescription: '1 Bucket of RAK Luxury Emulsion FREE',
    applicableProductIds: const ['PRD005', 'PRD006'],
    earnedBenefit: 0,
    pendingBenefit: 2500,
    isEligible: true,
  ),
  Scheme(
    id: 'SCH003',
    name: 'Cashback Offer',
    description: 'Get 5% cashback on orders above AED 50,000',
    type: SchemeType.cashback,
    startDate: DateTime.now(),
    endDate: DateTime.now().add(const Duration(days: 30)),
    isActive: true,
    minOrderValue: 50000,
    discountPercentage: 5,
    earnedBenefit: 0,
    pendingBenefit: 0,
    isEligible: false,
  ),
];

final List<Grievance> _mockGrievances = [
  Grievance(
    id: 'GRV001',
    ticketNumber: 'TKT-2024-0001',
    category: GrievanceCategory.delivery,
    subject: 'Delayed delivery',
    description:
        'Order was supposed to be delivered 2 days ago but still pending',
    status: GrievanceStatus.inProgress,
    createdDate: DateTime.now().subtract(const Duration(days: 3)),
    orderId: 'ORD002',
    slaHours: 48,
  ),
  Grievance(
    id: 'GRV002',
    ticketNumber: 'TKT-2024-0002',
    category: GrievanceCategory.product,
    subject: 'Damaged product received',
    description: 'Two bags of wall putty were damaged during transit',
    status: GrievanceStatus.resolved,
    createdDate: DateTime.now().subtract(const Duration(days: 10)),
    resolvedDate: DateTime.now().subtract(const Duration(days: 7)),
    resolution: 'Replacement sent. Credit note issued for damaged goods.',
    invoiceNumber: 'INV-2024-00001',
    slaHours: 48,
  ),
];
