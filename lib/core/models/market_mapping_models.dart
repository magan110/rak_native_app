/// Market Mapping Models
/// Models for competitor intelligence and market tracking

import 'package:equatable/equatable.dart';

// ============================================
// COMPETITOR
// ============================================

class Competitor extends Equatable {
  final String id;
  final String brandName;
  final String? logoUrl;
  final String? category;
  final String? marketShare;
  final List<CompetitorProduct> products;

  const Competitor({
    required this.id,
    required this.brandName,
    this.logoUrl,
    this.category,
    this.marketShare,
    this.products = const [],
  });

  factory Competitor.fromJson(Map<String, dynamic> json) {
    return Competitor(
      id: json['id'] as String,
      brandName: json['brandName'] as String,
      logoUrl: json['logoUrl'] as String?,
      category: json['category'] as String?,
      marketShare: json['marketShare'] as String?,
      products:
          (json['products'] as List<dynamic>?)
              ?.map(
                (p) => CompetitorProduct.fromJson(p as Map<String, dynamic>),
              )
              .toList() ??
          [],
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'brandName': brandName,
    'logoUrl': logoUrl,
    'category': category,
    'marketShare': marketShare,
    'products': products.map((p) => p.toJson()).toList(),
  };

  @override
  List<Object?> get props => [id, brandName];
}

class CompetitorProduct extends Equatable {
  final String id;
  final String name;
  final String? sku;
  final double price;
  final String? unit;
  final String? category;

  const CompetitorProduct({
    required this.id,
    required this.name,
    this.sku,
    required this.price,
    this.unit,
    this.category,
  });

  factory CompetitorProduct.fromJson(Map<String, dynamic> json) {
    return CompetitorProduct(
      id: json['id'] as String,
      name: json['name'] as String,
      sku: json['sku'] as String?,
      price: (json['price'] as num).toDouble(),
      unit: json['unit'] as String?,
      category: json['category'] as String?,
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'name': name,
    'sku': sku,
    'price': price,
    'unit': unit,
    'category': category,
  };

  @override
  List<Object?> get props => [id, name, price];
}

// ============================================
// PRICE ENTRY
// ============================================

class PriceEntry extends Equatable {
  final String id;
  final String competitorId;
  final String competitorName;
  final String productId;
  final String productName;
  final double price;
  final double? discountedPrice;
  final String? scheme;
  final DateTime capturedAt;
  final String? capturedBy;
  final double? latitude;
  final double? longitude;
  final String? location;

  const PriceEntry({
    required this.id,
    required this.competitorId,
    required this.competitorName,
    required this.productId,
    required this.productName,
    required this.price,
    this.discountedPrice,
    this.scheme,
    required this.capturedAt,
    this.capturedBy,
    this.latitude,
    this.longitude,
    this.location,
  });

  factory PriceEntry.fromJson(Map<String, dynamic> json) {
    return PriceEntry(
      id: json['id'] as String,
      competitorId: json['competitorId'] as String,
      competitorName: json['competitorName'] as String,
      productId: json['productId'] as String,
      productName: json['productName'] as String,
      price: (json['price'] as num).toDouble(),
      discountedPrice: json['discountedPrice'] != null
          ? (json['discountedPrice'] as num).toDouble()
          : null,
      scheme: json['scheme'] as String?,
      capturedAt: DateTime.parse(json['capturedAt'] as String),
      capturedBy: json['capturedBy'] as String?,
      latitude: json['latitude'] != null
          ? (json['latitude'] as num).toDouble()
          : null,
      longitude: json['longitude'] != null
          ? (json['longitude'] as num).toDouble()
          : null,
      location: json['location'] as String?,
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'competitorId': competitorId,
    'competitorName': competitorName,
    'productId': productId,
    'productName': productName,
    'price': price,
    'discountedPrice': discountedPrice,
    'scheme': scheme,
    'capturedAt': capturedAt.toIso8601String(),
    'capturedBy': capturedBy,
    'latitude': latitude,
    'longitude': longitude,
    'location': location,
  };

  @override
  List<Object?> get props => [id, competitorId, productId, price];
}

// ============================================
// NEW PRODUCT LAUNCH
// ============================================

class NewProductLaunch extends Equatable {
  final String id;
  final String competitorId;
  final String competitorName;
  final String productName;
  final String? description;
  final String? category;
  final double? price;
  final DateTime launchDate;
  final String? imageUrl;
  final String? reportedBy;
  final DateTime? reportedAt;

  const NewProductLaunch({
    required this.id,
    required this.competitorId,
    required this.competitorName,
    required this.productName,
    this.description,
    this.category,
    this.price,
    required this.launchDate,
    this.imageUrl,
    this.reportedBy,
    this.reportedAt,
  });

  factory NewProductLaunch.fromJson(Map<String, dynamic> json) {
    return NewProductLaunch(
      id: json['id'] as String,
      competitorId: json['competitorId'] as String,
      competitorName: json['competitorName'] as String,
      productName: json['productName'] as String,
      description: json['description'] as String?,
      category: json['category'] as String?,
      price: json['price'] != null ? (json['price'] as num).toDouble() : null,
      launchDate: DateTime.parse(json['launchDate'] as String),
      imageUrl: json['imageUrl'] as String?,
      reportedBy: json['reportedBy'] as String?,
      reportedAt: json['reportedAt'] != null
          ? DateTime.parse(json['reportedAt'] as String)
          : null,
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'competitorId': competitorId,
    'competitorName': competitorName,
    'productName': productName,
    'description': description,
    'category': category,
    'price': price,
    'launchDate': launchDate.toIso8601String(),
    'imageUrl': imageUrl,
    'reportedBy': reportedBy,
    'reportedAt': reportedAt?.toIso8601String(),
  };

  @override
  List<Object?> get props => [id, competitorId, productName];
}

// ============================================
// DISCOUNT ACTIVITY
// ============================================

enum DiscountType { flat, percentage, buyXGetY, combo, scheme }

class DiscountActivity extends Equatable {
  final String id;
  final String competitorId;
  final String competitorName;
  final String productName;
  final DiscountType type;
  final String description;
  final double? discountValue;
  final DateTime startDate;
  final DateTime? endDate;
  final String? capturedBy;
  final DateTime capturedAt;
  final String? location;

  const DiscountActivity({
    required this.id,
    required this.competitorId,
    required this.competitorName,
    required this.productName,
    required this.type,
    required this.description,
    this.discountValue,
    required this.startDate,
    this.endDate,
    this.capturedBy,
    required this.capturedAt,
    this.location,
  });

  bool get isActive {
    final now = DateTime.now();
    if (endDate == null) return now.isAfter(startDate);
    return now.isAfter(startDate) && now.isBefore(endDate!);
  }

  factory DiscountActivity.fromJson(Map<String, dynamic> json) {
    return DiscountActivity(
      id: json['id'] as String,
      competitorId: json['competitorId'] as String,
      competitorName: json['competitorName'] as String,
      productName: json['productName'] as String,
      type: DiscountType.values.firstWhere(
        (e) => e.name == json['type'],
        orElse: () => DiscountType.flat,
      ),
      description: json['description'] as String,
      discountValue: json['discountValue'] != null
          ? (json['discountValue'] as num).toDouble()
          : null,
      startDate: DateTime.parse(json['startDate'] as String),
      endDate: json['endDate'] != null
          ? DateTime.parse(json['endDate'] as String)
          : null,
      capturedBy: json['capturedBy'] as String?,
      capturedAt: DateTime.parse(json['capturedAt'] as String),
      location: json['location'] as String?,
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'competitorId': competitorId,
    'competitorName': competitorName,
    'productName': productName,
    'type': type.name,
    'description': description,
    'discountValue': discountValue,
    'startDate': startDate.toIso8601String(),
    'endDate': endDate?.toIso8601String(),
    'capturedBy': capturedBy,
    'capturedAt': capturedAt.toIso8601String(),
    'location': location,
  };

  @override
  List<Object?> get props => [id, competitorId, productName, type];
}

// ============================================
// MARKET INTELLIGENCE
// ============================================

enum IntelType { opportunity, threat, observation, trend }

class MarketIntelligence extends Equatable {
  final String id;
  final IntelType type;
  final String title;
  final String description;
  final String? competitorId;
  final String? competitorName;
  final double? latitude;
  final double? longitude;
  final String? location;
  final String? imageUrl;
  final String reportedBy;
  final DateTime reportedAt;
  final bool isVerified;

  const MarketIntelligence({
    required this.id,
    required this.type,
    required this.title,
    required this.description,
    this.competitorId,
    this.competitorName,
    this.latitude,
    this.longitude,
    this.location,
    this.imageUrl,
    required this.reportedBy,
    required this.reportedAt,
    this.isVerified = false,
  });

  factory MarketIntelligence.fromJson(Map<String, dynamic> json) {
    return MarketIntelligence(
      id: json['id'] as String,
      type: IntelType.values.firstWhere(
        (e) => e.name == json['type'],
        orElse: () => IntelType.observation,
      ),
      title: json['title'] as String,
      description: json['description'] as String,
      competitorId: json['competitorId'] as String?,
      competitorName: json['competitorName'] as String?,
      latitude: json['latitude'] != null
          ? (json['latitude'] as num).toDouble()
          : null,
      longitude: json['longitude'] != null
          ? (json['longitude'] as num).toDouble()
          : null,
      location: json['location'] as String?,
      imageUrl: json['imageUrl'] as String?,
      reportedBy: json['reportedBy'] as String,
      reportedAt: DateTime.parse(json['reportedAt'] as String),
      isVerified: json['isVerified'] as bool? ?? false,
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'type': type.name,
    'title': title,
    'description': description,
    'competitorId': competitorId,
    'competitorName': competitorName,
    'latitude': latitude,
    'longitude': longitude,
    'location': location,
    'imageUrl': imageUrl,
    'reportedBy': reportedBy,
    'reportedAt': reportedAt.toIso8601String(),
    'isVerified': isVerified,
  };

  @override
  List<Object?> get props => [id, type, title];
}

// ============================================
// CREATE REQUESTS
// ============================================

class CreatePriceEntryRequest {
  final String competitorId;
  final String productId;
  final double price;
  final double? discountedPrice;
  final String? scheme;
  final double? latitude;
  final double? longitude;

  const CreatePriceEntryRequest({
    required this.competitorId,
    required this.productId,
    required this.price,
    this.discountedPrice,
    this.scheme,
    this.latitude,
    this.longitude,
  });

  Map<String, dynamic> toJson() => {
    'competitorId': competitorId,
    'productId': productId,
    'price': price,
    'discountedPrice': discountedPrice,
    'scheme': scheme,
    'latitude': latitude,
    'longitude': longitude,
  };
}

class CreateMarketIntelRequest {
  final IntelType type;
  final String title;
  final String description;
  final String? competitorId;
  final double? latitude;
  final double? longitude;
  final String? imageUrl;

  const CreateMarketIntelRequest({
    required this.type,
    required this.title,
    required this.description,
    this.competitorId,
    this.latitude,
    this.longitude,
    this.imageUrl,
  });

  Map<String, dynamic> toJson() => {
    'type': type.name,
    'title': title,
    'description': description,
    'competitorId': competitorId,
    'latitude': latitude,
    'longitude': longitude,
    'imageUrl': imageUrl,
  };
}
