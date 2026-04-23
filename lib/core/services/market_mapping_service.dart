/// Market Mapping Service
/// API service for competitor intelligence and market tracking

import 'package:flutter/foundation.dart';
import '../models/market_mapping_models.dart';

class MarketMappingService {
  // ============================================
  // COMPETITORS
  // ============================================

  static Future<List<Competitor>> getCompetitors() async {
    try {
      await Future.delayed(const Duration(milliseconds: 500));
      return _mockCompetitors;
    } catch (e) {
      debugPrint('Failed to fetch competitors: $e');
      return [];
    }
  }

  static Future<Competitor?> getCompetitor(String id) async {
    try {
      await Future.delayed(const Duration(milliseconds: 300));
      return _mockCompetitors.firstWhere((c) => c.id == id);
    } catch (e) {
      debugPrint('Failed to fetch competitor: $e');
      return null;
    }
  }

  // ============================================
  // PRICE ENTRIES
  // ============================================

  static Future<List<PriceEntry>> getPriceEntries({
    String? competitorId,
  }) async {
    try {
      await Future.delayed(const Duration(milliseconds: 500));
      if (competitorId != null) {
        return _mockPriceEntries
            .where((p) => p.competitorId == competitorId)
            .toList();
      }
      return _mockPriceEntries;
    } catch (e) {
      debugPrint('Failed to fetch price entries: $e');
      return [];
    }
  }

  static Future<PriceEntry?> createPriceEntry(
    CreatePriceEntryRequest request,
  ) async {
    try {
      await Future.delayed(const Duration(milliseconds: 600));

      final competitor = _mockCompetitors.firstWhere(
        (c) => c.id == request.competitorId,
      );

      final entry = PriceEntry(
        id: 'PE${DateTime.now().millisecondsSinceEpoch}',
        competitorId: request.competitorId,
        competitorName: competitor.brandName,
        productId: request.productId,
        productName: 'Product ${request.productId}',
        price: request.price,
        discountedPrice: request.discountedPrice,
        scheme: request.scheme,
        capturedAt: DateTime.now(),
        capturedBy: 'Current User',
        latitude: request.latitude,
        longitude: request.longitude,
      );

      _mockPriceEntries.insert(0, entry);
      return entry;
    } catch (e) {
      debugPrint('Failed to create price entry: $e');
      return null;
    }
  }

  // ============================================
  // NEW LAUNCHES
  // ============================================

  static Future<List<NewProductLaunch>> getNewLaunches() async {
    try {
      await Future.delayed(const Duration(milliseconds: 500));
      return _mockNewLaunches;
    } catch (e) {
      debugPrint('Failed to fetch new launches: $e');
      return [];
    }
  }

  // ============================================
  // DISCOUNT ACTIVITIES
  // ============================================

  static Future<List<DiscountActivity>> getDiscountActivities({
    bool activeOnly = false,
  }) async {
    try {
      await Future.delayed(const Duration(milliseconds: 500));
      if (activeOnly) {
        return _mockDiscounts.where((d) => d.isActive).toList();
      }
      return _mockDiscounts;
    } catch (e) {
      debugPrint('Failed to fetch discount activities: $e');
      return [];
    }
  }

  // ============================================
  // MARKET INTELLIGENCE
  // ============================================

  static Future<List<MarketIntelligence>> getMarketIntelligence({
    IntelType? type,
  }) async {
    try {
      await Future.delayed(const Duration(milliseconds: 500));
      if (type != null) {
        return _mockIntelligence.where((i) => i.type == type).toList();
      }
      return _mockIntelligence;
    } catch (e) {
      debugPrint('Failed to fetch market intelligence: $e');
      return [];
    }
  }

  static Future<MarketIntelligence?> createMarketIntel(
    CreateMarketIntelRequest request,
  ) async {
    try {
      await Future.delayed(const Duration(milliseconds: 600));

      String? competitorName;
      if (request.competitorId != null) {
        final competitor = _mockCompetitors.firstWhere(
          (c) => c.id == request.competitorId,
        );
        competitorName = competitor.brandName;
      }

      final intel = MarketIntelligence(
        id: 'MI${DateTime.now().millisecondsSinceEpoch}',
        type: request.type,
        title: request.title,
        description: request.description,
        competitorId: request.competitorId,
        competitorName: competitorName,
        latitude: request.latitude,
        longitude: request.longitude,
        imageUrl: request.imageUrl,
        reportedBy: 'Current User',
        reportedAt: DateTime.now(),
      );

      _mockIntelligence.insert(0, intel);
      return intel;
    } catch (e) {
      debugPrint('Failed to create market intel: $e');
      return null;
    }
  }
}

// ============================================
// MOCK DATA
// ============================================

final List<Competitor> _mockCompetitors = [
  Competitor(
    id: 'COMP001',
    brandName: 'Asian Paints',
    category: 'Premium',
    marketShare: '38%',
    products: [
      CompetitorProduct(
        id: 'AP001',
        name: 'Royale Luxury Emulsion',
        price: 4500,
        unit: '10L Bucket',
        category: 'Interior',
      ),
      CompetitorProduct(
        id: 'AP002',
        name: 'Apex Ultima',
        price: 3800,
        unit: '10L Bucket',
        category: 'Exterior',
      ),
    ],
  ),
  Competitor(
    id: 'COMP002',
    brandName: 'Berger Paints',
    category: 'Premium',
    marketShare: '22%',
    products: [
      CompetitorProduct(
        id: 'BP001',
        name: 'Silk Luxury Emulsion',
        price: 4200,
        unit: '10L Bucket',
        category: 'Interior',
      ),
    ],
  ),
  Competitor(
    id: 'COMP003',
    brandName: 'Nerolac',
    category: 'Mid-Range',
    marketShare: '18%',
    products: [
      CompetitorProduct(
        id: 'NP001',
        name: 'Beauty Smooth',
        price: 2800,
        unit: '10L Bucket',
        category: 'Interior',
      ),
    ],
  ),
  Competitor(
    id: 'COMP004',
    brandName: 'Dulux',
    category: 'Premium',
    marketShare: '12%',
    products: [
      CompetitorProduct(
        id: 'DX001',
        name: 'Velvet Touch',
        price: 4800,
        unit: '10L Bucket',
        category: 'Interior',
      ),
    ],
  ),
];

final List<PriceEntry> _mockPriceEntries = [
  PriceEntry(
    id: 'PE001',
    competitorId: 'COMP001',
    competitorName: 'Asian Paints',
    productId: 'AP001',
    productName: 'Royale Luxury Emulsion',
    price: 4500,
    discountedPrice: 4200,
    scheme: '10% Festival Discount',
    capturedAt: DateTime.now().subtract(const Duration(days: 2)),
    capturedBy: 'John Doe',
    location: 'Mumbai Central',
  ),
  PriceEntry(
    id: 'PE002',
    competitorId: 'COMP002',
    competitorName: 'Berger Paints',
    productId: 'BP001',
    productName: 'Silk Luxury Emulsion',
    price: 4200,
    capturedAt: DateTime.now().subtract(const Duration(days: 3)),
    capturedBy: 'Jane Smith',
    location: 'Delhi NCR',
  ),
  PriceEntry(
    id: 'PE003',
    competitorId: 'COMP003',
    competitorName: 'Nerolac',
    productId: 'NP001',
    productName: 'Beauty Smooth',
    price: 2800,
    discountedPrice: 2500,
    scheme: 'Buy 2 Get 1 Free',
    capturedAt: DateTime.now().subtract(const Duration(days: 1)),
    capturedBy: 'John Doe',
    location: 'Bangalore',
  ),
];

final List<NewProductLaunch> _mockNewLaunches = [
  NewProductLaunch(
    id: 'NL001',
    competitorId: 'COMP001',
    competitorName: 'Asian Paints',
    productName: 'Royale Health Shield',
    description: 'Anti-bacterial paint with silver ion technology',
    category: 'Interior',
    price: 5200,
    launchDate: DateTime.now().subtract(const Duration(days: 15)),
    reportedBy: 'Sales Team',
    reportedAt: DateTime.now().subtract(const Duration(days: 14)),
  ),
  NewProductLaunch(
    id: 'NL002',
    competitorId: 'COMP002',
    competitorName: 'Berger Paints',
    productName: 'WeatherCoat All Guard',
    description: 'All-weather exterior protection',
    category: 'Exterior',
    price: 4800,
    launchDate: DateTime.now().subtract(const Duration(days: 7)),
    reportedBy: 'Market Intel',
    reportedAt: DateTime.now().subtract(const Duration(days: 6)),
  ),
];

final List<DiscountActivity> _mockDiscounts = [
  DiscountActivity(
    id: 'DA001',
    competitorId: 'COMP001',
    competitorName: 'Asian Paints',
    productName: 'All Interior Products',
    type: DiscountType.percentage,
    description: '15% off on all interior paints',
    discountValue: 15,
    startDate: DateTime.now().subtract(const Duration(days: 5)),
    endDate: DateTime.now().add(const Duration(days: 10)),
    capturedBy: 'John Doe',
    capturedAt: DateTime.now().subtract(const Duration(days: 4)),
    location: 'Pan India',
  ),
  DiscountActivity(
    id: 'DA002',
    competitorId: 'COMP003',
    competitorName: 'Nerolac',
    productName: 'Beauty Smooth Range',
    type: DiscountType.buyXGetY,
    description: 'Buy 2 Buckets Get 1 Free',
    startDate: DateTime.now().subtract(const Duration(days: 3)),
    endDate: DateTime.now().add(const Duration(days: 20)),
    capturedBy: 'Jane Smith',
    capturedAt: DateTime.now().subtract(const Duration(days: 2)),
    location: 'South India',
  ),
  DiscountActivity(
    id: 'DA003',
    competitorId: 'COMP002',
    competitorName: 'Berger Paints',
    productName: 'Silk Range',
    type: DiscountType.flat,
    description: 'Flat ₹500 off per bucket',
    discountValue: 500,
    startDate: DateTime.now().subtract(const Duration(days: 10)),
    endDate: DateTime.now().subtract(const Duration(days: 2)),
    capturedBy: 'Sales Team',
    capturedAt: DateTime.now().subtract(const Duration(days: 9)),
    location: 'West India',
  ),
];

final List<MarketIntelligence> _mockIntelligence = [
  MarketIntelligence(
    id: 'MI001',
    type: IntelType.threat,
    title: 'Asian Paints New Dealer Network',
    description:
        'Asian Paints is expanding dealer network in Tier-2 cities with aggressive commission structure.',
    competitorId: 'COMP001',
    competitorName: 'Asian Paints',
    location: 'Maharashtra',
    reportedBy: 'Regional Manager',
    reportedAt: DateTime.now().subtract(const Duration(days: 3)),
    isVerified: true,
  ),
  MarketIntelligence(
    id: 'MI002',
    type: IntelType.opportunity,
    title: 'Berger Supply Issues',
    description:
        'Berger facing supply chain issues in Southern region. Dealers looking for alternatives.',
    competitorId: 'COMP002',
    competitorName: 'Berger Paints',
    location: 'Karnataka',
    reportedBy: 'Sales Officer',
    reportedAt: DateTime.now().subtract(const Duration(days: 1)),
    isVerified: false,
  ),
  MarketIntelligence(
    id: 'MI003',
    type: IntelType.trend,
    title: 'Eco-Friendly Paints Demand Rising',
    description:
        'Increasing demand for low-VOC and eco-friendly paint options in urban markets.',
    location: 'Metro Cities',
    reportedBy: 'Market Research',
    reportedAt: DateTime.now().subtract(const Duration(days: 5)),
    isVerified: true,
  ),
  MarketIntelligence(
    id: 'MI004',
    type: IntelType.observation,
    title: 'Nerolac Painter Program',
    description:
        'Nerolac running aggressive painter loyalty program with higher reward points.',
    competitorId: 'COMP003',
    competitorName: 'Nerolac',
    location: 'Gujarat',
    reportedBy: 'Field Team',
    reportedAt: DateTime.now().subtract(const Duration(days: 2)),
    isVerified: false,
  ),
];
