/// Product Journey Service
/// Service for product journey tracking, batch management, and painter tagging

import 'package:flutter/foundation.dart';
import '../models/product_journey_models.dart';

class ProductJourneyService {
  // ============================================
  // PRODUCT JOURNEYS
  // ============================================

  static Future<List<ProductJourney>> getProductJourneys({
    JourneyStage? stage,
  }) async {
    try {
      await Future.delayed(const Duration(milliseconds: 500));
      if (stage != null) {
        return _mockJourneys.where((j) => j.currentStage == stage).toList();
      }
      return _mockJourneys;
    } catch (e) {
      debugPrint('Failed to fetch journeys: $e');
      return [];
    }
  }

  static Future<ProductJourney?> getJourneyByBatch(String batchNumber) async {
    try {
      await Future.delayed(const Duration(milliseconds: 300));
      return _mockJourneys.firstWhere((j) => j.batchNumber == batchNumber);
    } catch (e) {
      debugPrint('Failed to fetch journey: $e');
      return null;
    }
  }

  // ============================================
  // BATCHES
  // ============================================

  static Future<List<Batch>> getBatches({String? productId}) async {
    try {
      await Future.delayed(const Duration(milliseconds: 500));
      if (productId != null) {
        return _mockBatches.where((b) => b.productId == productId).toList();
      }
      return _mockBatches;
    } catch (e) {
      debugPrint('Failed to fetch batches: $e');
      return [];
    }
  }

  static Future<Batch?> getBatch(String batchNumber) async {
    try {
      await Future.delayed(const Duration(milliseconds: 300));
      return _mockBatches.firstWhere((b) => b.batchNumber == batchNumber);
    } catch (e) {
      debugPrint('Failed to fetch batch: $e');
      return null;
    }
  }

  // ============================================
  // PAINTER TAGS
  // ============================================

  static Future<List<PainterTag>> getPainterTags({String? painterId}) async {
    try {
      await Future.delayed(const Duration(milliseconds: 500));
      if (painterId != null) {
        return _mockPainterTags.where((t) => t.painterId == painterId).toList();
      }
      return _mockPainterTags;
    } catch (e) {
      debugPrint('Failed to fetch painter tags: $e');
      return [];
    }
  }

  static Future<PainterTag?> createPainterTag({
    required String painterId,
    required String painterName,
    required String productId,
    required String productName,
    required String batchNumber,
    String? projectName,
    String? projectLocation,
  }) async {
    try {
      await Future.delayed(const Duration(milliseconds: 600));

      final tag = PainterTag(
        id: 'TAG${DateTime.now().millisecondsSinceEpoch}',
        painterId: painterId,
        painterName: painterName,
        productId: productId,
        productName: productName,
        batchNumber: batchNumber,
        taggedAt: DateTime.now(),
        projectName: projectName,
        projectLocation: projectLocation,
        rewardPoints: 100,
      );

      _mockPainterTags.insert(0, tag);
      return tag;
    } catch (e) {
      debugPrint('Failed to create painter tag: $e');
      return null;
    }
  }
}

// ============================================
// MOCK DATA
// ============================================

final List<ProductJourney> _mockJourneys = [
  ProductJourney(
    id: 'JRN001',
    productId: 'PRD001',
    productName: 'RAK Premium Wall Putty',
    batchNumber: 'BATCH2024001',
    manufactureDate: DateTime.now().subtract(const Duration(days: 30)),
    expiryDate: DateTime.now().add(const Duration(days: 335)),
    currentStage: JourneyStage.retailer,
    events: [
      JourneyEvent(
        id: 'EVT001',
        stage: JourneyStage.manufacturing,
        description: 'Manufactured at Jaipur Plant',
        location: 'Jaipur, Rajasthan',
        handledBy: 'Production Team',
        timestamp: DateTime.now().subtract(const Duration(days: 30)),
      ),
      JourneyEvent(
        id: 'EVT002',
        stage: JourneyStage.warehouse,
        description: 'Received at Central Warehouse',
        location: 'Delhi Warehouse',
        handledBy: 'Warehouse Team',
        timestamp: DateTime.now().subtract(const Duration(days: 28)),
      ),
      JourneyEvent(
        id: 'EVT003',
        stage: JourneyStage.distributor,
        description: 'Dispatched to distributor',
        location: 'Mumbai',
        handledBy: 'Patel Distributors',
        timestamp: DateTime.now().subtract(const Duration(days: 20)),
      ),
      JourneyEvent(
        id: 'EVT004',
        stage: JourneyStage.retailer,
        description: 'Delivered to retail outlet',
        location: 'Sharma Paint House, Mumbai',
        handledBy: 'Delivery Team',
        timestamp: DateTime.now().subtract(const Duration(days: 10)),
      ),
    ],
  ),
  ProductJourney(
    id: 'JRN002',
    productId: 'PRD002',
    productName: 'RAK Exterior Emulsion',
    batchNumber: 'BATCH2024002',
    manufactureDate: DateTime.now().subtract(const Duration(days: 45)),
    expiryDate: DateTime.now().add(const Duration(days: 320)),
    currentStage: JourneyStage.endUser,
    painterTagged: 'Ramesh Kumar',
    endUserLocation: 'Andheri, Mumbai',
    events: [
      JourneyEvent(
        id: 'EVT005',
        stage: JourneyStage.manufacturing,
        description: 'Manufactured at Jaipur Plant',
        location: 'Jaipur, Rajasthan',
        timestamp: DateTime.now().subtract(const Duration(days: 45)),
      ),
      JourneyEvent(
        id: 'EVT006',
        stage: JourneyStage.warehouse,
        description: 'Central Warehouse',
        location: 'Delhi',
        timestamp: DateTime.now().subtract(const Duration(days: 42)),
      ),
      JourneyEvent(
        id: 'EVT007',
        stage: JourneyStage.distributor,
        description: 'Mumbai Distributor',
        location: 'Mumbai',
        timestamp: DateTime.now().subtract(const Duration(days: 35)),
      ),
      JourneyEvent(
        id: 'EVT008',
        stage: JourneyStage.dealer,
        description: 'Krishna Hardware',
        location: 'Mumbai',
        timestamp: DateTime.now().subtract(const Duration(days: 25)),
      ),
      JourneyEvent(
        id: 'EVT009',
        stage: JourneyStage.endUser,
        description: 'Applied by registered painter',
        location: 'Andheri, Mumbai',
        handledBy: 'Ramesh Kumar (Painter)',
        timestamp: DateTime.now().subtract(const Duration(days: 5)),
      ),
    ],
  ),
];

final List<Batch> _mockBatches = [
  Batch(
    id: 'BAT001',
    batchNumber: 'BATCH2024001',
    productId: 'PRD001',
    productName: 'RAK Premium Wall Putty',
    quantity: 500,
    manufactureDate: DateTime.now().subtract(const Duration(days: 30)),
    expiryDate: DateTime.now().add(const Duration(days: 335)),
    currentLocation: 'Mumbai',
    currentStage: JourneyStage.retailer,
    soldCount: 120,
    remainingCount: 380,
  ),
  Batch(
    id: 'BAT002',
    batchNumber: 'BATCH2024002',
    productId: 'PRD002',
    productName: 'RAK Exterior Emulsion',
    quantity: 300,
    manufactureDate: DateTime.now().subtract(const Duration(days: 45)),
    expiryDate: DateTime.now().add(const Duration(days: 320)),
    currentLocation: 'Delhi',
    currentStage: JourneyStage.distributor,
    soldCount: 200,
    remainingCount: 100,
  ),
  Batch(
    id: 'BAT003',
    batchNumber: 'BATCH2024003',
    productId: 'PRD003',
    productName: 'RAK Interior Primer',
    quantity: 400,
    manufactureDate: DateTime.now().subtract(const Duration(days: 15)),
    expiryDate: DateTime.now().add(const Duration(days: 350)),
    currentLocation: 'Jaipur Warehouse',
    currentStage: JourneyStage.warehouse,
    soldCount: 50,
    remainingCount: 350,
  ),
];

final List<PainterTag> _mockPainterTags = [
  PainterTag(
    id: 'TAG001',
    painterId: 'PTR001',
    painterName: 'Ramesh Kumar',
    painterPhone: '+91 9876543210',
    productId: 'PRD002',
    productName: 'RAK Exterior Emulsion',
    batchNumber: 'BATCH2024002',
    taggedAt: DateTime.now().subtract(const Duration(days: 5)),
    projectName: 'Sunshine Apartments',
    projectLocation: 'Andheri, Mumbai',
    rewardPoints: 100,
  ),
  PainterTag(
    id: 'TAG002',
    painterId: 'PTR002',
    painterName: 'Suresh Yadav',
    painterPhone: '+91 9876543211',
    productId: 'PRD001',
    productName: 'RAK Premium Wall Putty',
    batchNumber: 'BATCH2024001',
    taggedAt: DateTime.now().subtract(const Duration(days: 8)),
    projectName: 'Green Valley Villa',
    projectLocation: 'Bandra, Mumbai',
    rewardPoints: 100,
  ),
];
