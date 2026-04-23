/// Product Journey Tracking Models
/// Models for end-to-end product journey and batch tracking

import 'package:equatable/equatable.dart';

// ============================================
// PRODUCT JOURNEY
// ============================================

enum JourneyStage {
  manufacturing,
  warehouse,
  distributor,
  dealer,
  retailer,
  endUser,
}

class ProductJourney extends Equatable {
  final String id;
  final String productId;
  final String productName;
  final String batchNumber;
  final DateTime manufactureDate;
  final DateTime? expiryDate;
  final JourneyStage currentStage;
  final List<JourneyEvent> events;
  final String? painterTagged;
  final String? endUserLocation;

  const ProductJourney({
    required this.id,
    required this.productId,
    required this.productName,
    required this.batchNumber,
    required this.manufactureDate,
    this.expiryDate,
    required this.currentStage,
    this.events = const [],
    this.painterTagged,
    this.endUserLocation,
  });

  bool get isComplete => currentStage == JourneyStage.endUser;

  factory ProductJourney.fromJson(Map<String, dynamic> json) {
    return ProductJourney(
      id: json['id'] as String,
      productId: json['productId'] as String,
      productName: json['productName'] as String,
      batchNumber: json['batchNumber'] as String,
      manufactureDate: DateTime.parse(json['manufactureDate'] as String),
      expiryDate: json['expiryDate'] != null
          ? DateTime.parse(json['expiryDate'] as String)
          : null,
      currentStage: JourneyStage.values.firstWhere(
        (e) => e.name == json['currentStage'],
        orElse: () => JourneyStage.manufacturing,
      ),
      events:
          (json['events'] as List<dynamic>?)
              ?.map((e) => JourneyEvent.fromJson(e as Map<String, dynamic>))
              .toList() ??
          [],
      painterTagged: json['painterTagged'] as String?,
      endUserLocation: json['endUserLocation'] as String?,
    );
  }

  @override
  List<Object?> get props => [id, productId, batchNumber];
}

class JourneyEvent extends Equatable {
  final String id;
  final JourneyStage stage;
  final String description;
  final String? location;
  final String? handledBy;
  final DateTime timestamp;
  final double? latitude;
  final double? longitude;

  const JourneyEvent({
    required this.id,
    required this.stage,
    required this.description,
    this.location,
    this.handledBy,
    required this.timestamp,
    this.latitude,
    this.longitude,
  });

  factory JourneyEvent.fromJson(Map<String, dynamic> json) {
    return JourneyEvent(
      id: json['id'] as String,
      stage: JourneyStage.values.firstWhere(
        (e) => e.name == json['stage'],
        orElse: () => JourneyStage.manufacturing,
      ),
      description: json['description'] as String,
      location: json['location'] as String?,
      handledBy: json['handledBy'] as String?,
      timestamp: DateTime.parse(json['timestamp'] as String),
      latitude: json['latitude'] != null
          ? (json['latitude'] as num).toDouble()
          : null,
      longitude: json['longitude'] != null
          ? (json['longitude'] as num).toDouble()
          : null,
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'stage': stage.name,
    'description': description,
    'location': location,
    'handledBy': handledBy,
    'timestamp': timestamp.toIso8601String(),
    'latitude': latitude,
    'longitude': longitude,
  };

  @override
  List<Object?> get props => [id, stage, timestamp];
}

// ============================================
// BATCH TRACKING
// ============================================

class Batch extends Equatable {
  final String id;
  final String batchNumber;
  final String productId;
  final String productName;
  final int quantity;
  final DateTime manufactureDate;
  final DateTime? expiryDate;
  final String? currentLocation;
  final JourneyStage currentStage;
  final int soldCount;
  final int remainingCount;

  const Batch({
    required this.id,
    required this.batchNumber,
    required this.productId,
    required this.productName,
    required this.quantity,
    required this.manufactureDate,
    this.expiryDate,
    this.currentLocation,
    required this.currentStage,
    this.soldCount = 0,
    this.remainingCount = 0,
  });

  double get sellThroughRate => quantity > 0 ? soldCount / quantity : 0;

  factory Batch.fromJson(Map<String, dynamic> json) {
    return Batch(
      id: json['id'] as String,
      batchNumber: json['batchNumber'] as String,
      productId: json['productId'] as String,
      productName: json['productName'] as String,
      quantity: json['quantity'] as int,
      manufactureDate: DateTime.parse(json['manufactureDate'] as String),
      expiryDate: json['expiryDate'] != null
          ? DateTime.parse(json['expiryDate'] as String)
          : null,
      currentLocation: json['currentLocation'] as String?,
      currentStage: JourneyStage.values.firstWhere(
        (e) => e.name == json['currentStage'],
        orElse: () => JourneyStage.manufacturing,
      ),
      soldCount: json['soldCount'] as int? ?? 0,
      remainingCount: json['remainingCount'] as int? ?? 0,
    );
  }

  @override
  List<Object?> get props => [id, batchNumber, productId];
}

// ============================================
// PAINTER TAGGING
// ============================================

class PainterTag extends Equatable {
  final String id;
  final String painterId;
  final String painterName;
  final String? painterPhone;
  final String productId;
  final String productName;
  final String batchNumber;
  final DateTime taggedAt;
  final String? projectName;
  final String? projectLocation;
  final int? rewardPoints;

  const PainterTag({
    required this.id,
    required this.painterId,
    required this.painterName,
    this.painterPhone,
    required this.productId,
    required this.productName,
    required this.batchNumber,
    required this.taggedAt,
    this.projectName,
    this.projectLocation,
    this.rewardPoints,
  });

  factory PainterTag.fromJson(Map<String, dynamic> json) {
    return PainterTag(
      id: json['id'] as String,
      painterId: json['painterId'] as String,
      painterName: json['painterName'] as String,
      painterPhone: json['painterPhone'] as String?,
      productId: json['productId'] as String,
      productName: json['productName'] as String,
      batchNumber: json['batchNumber'] as String,
      taggedAt: DateTime.parse(json['taggedAt'] as String),
      projectName: json['projectName'] as String?,
      projectLocation: json['projectLocation'] as String?,
      rewardPoints: json['rewardPoints'] as int?,
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'painterId': painterId,
    'painterName': painterName,
    'painterPhone': painterPhone,
    'productId': productId,
    'productName': productName,
    'batchNumber': batchNumber,
    'taggedAt': taggedAt.toIso8601String(),
    'projectName': projectName,
    'projectLocation': projectLocation,
    'rewardPoints': rewardPoints,
  };

  @override
  List<Object?> get props => [id, painterId, productId, batchNumber];
}
