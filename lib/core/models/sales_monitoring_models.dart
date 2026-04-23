/// Sales Monitoring Models
/// Models for route tracking, visits, and counter mapping

import 'package:equatable/equatable.dart';

// ============================================
// COUNTER / OUTLET
// ============================================

enum OutletType { retailer, dealer, distributor, wholesaler }

enum OutletStatus { active, inactive, prospect }

class Counter extends Equatable {
  final String id;
  final String name;
  final OutletType type;
  final OutletStatus status;
  final String? ownerName;
  final String? phone;
  final String address;
  final double? latitude;
  final double? longitude;
  final String? territory;
  final String? route;
  final DateTime? lastVisit;
  final int visitFrequencyDays;

  const Counter({
    required this.id,
    required this.name,
    required this.type,
    required this.status,
    this.ownerName,
    this.phone,
    required this.address,
    this.latitude,
    this.longitude,
    this.territory,
    this.route,
    this.lastVisit,
    this.visitFrequencyDays = 7,
  });

  bool get isDueForVisit {
    if (lastVisit == null) return true;
    return DateTime.now().difference(lastVisit!).inDays >= visitFrequencyDays;
  }

  factory Counter.fromJson(Map<String, dynamic> json) {
    return Counter(
      id: json['id'] as String,
      name: json['name'] as String,
      type: OutletType.values.firstWhere(
        (e) => e.name == json['type'],
        orElse: () => OutletType.retailer,
      ),
      status: OutletStatus.values.firstWhere(
        (e) => e.name == json['status'],
        orElse: () => OutletStatus.active,
      ),
      ownerName: json['ownerName'] as String?,
      phone: json['phone'] as String?,
      address: json['address'] as String,
      latitude: json['latitude'] != null
          ? (json['latitude'] as num).toDouble()
          : null,
      longitude: json['longitude'] != null
          ? (json['longitude'] as num).toDouble()
          : null,
      territory: json['territory'] as String?,
      route: json['route'] as String?,
      lastVisit: json['lastVisit'] != null
          ? DateTime.parse(json['lastVisit'] as String)
          : null,
      visitFrequencyDays: json['visitFrequencyDays'] as int? ?? 7,
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'name': name,
    'type': type.name,
    'status': status.name,
    'ownerName': ownerName,
    'phone': phone,
    'address': address,
    'latitude': latitude,
    'longitude': longitude,
    'territory': territory,
    'route': route,
    'lastVisit': lastVisit?.toIso8601String(),
    'visitFrequencyDays': visitFrequencyDays,
  };

  @override
  List<Object?> get props => [id, name];
}

// ============================================
// VISIT PLAN
// ============================================

enum VisitStatus { planned, inProgress, completed, missed, cancelled }

class DailyVisitPlan extends Equatable {
  final String id;
  final DateTime date;
  final String routeName;
  final List<PlannedVisit> visits;
  final int completedCount;
  final int totalCount;

  const DailyVisitPlan({
    required this.id,
    required this.date,
    required this.routeName,
    required this.visits,
    this.completedCount = 0,
    this.totalCount = 0,
  });

  double get completionRate => totalCount > 0 ? completedCount / totalCount : 0;

  factory DailyVisitPlan.fromJson(Map<String, dynamic> json) {
    return DailyVisitPlan(
      id: json['id'] as String,
      date: DateTime.parse(json['date'] as String),
      routeName: json['routeName'] as String,
      visits:
          (json['visits'] as List<dynamic>?)
              ?.map((v) => PlannedVisit.fromJson(v as Map<String, dynamic>))
              .toList() ??
          [],
      completedCount: json['completedCount'] as int? ?? 0,
      totalCount: json['totalCount'] as int? ?? 0,
    );
  }

  @override
  List<Object?> get props => [id, date];
}

class PlannedVisit extends Equatable {
  final String id;
  final String counterId;
  final String counterName;
  final String counterAddress;
  final int sequence;
  final VisitStatus status;
  final DateTime? scheduledTime;
  final DateTime? checkInTime;
  final DateTime? checkOutTime;
  final String? notes;
  final double? latitude;
  final double? longitude;

  const PlannedVisit({
    required this.id,
    required this.counterId,
    required this.counterName,
    required this.counterAddress,
    required this.sequence,
    required this.status,
    this.scheduledTime,
    this.checkInTime,
    this.checkOutTime,
    this.notes,
    this.latitude,
    this.longitude,
  });

  Duration? get visitDuration {
    if (checkInTime != null && checkOutTime != null) {
      return checkOutTime!.difference(checkInTime!);
    }
    return null;
  }

  factory PlannedVisit.fromJson(Map<String, dynamic> json) {
    return PlannedVisit(
      id: json['id'] as String,
      counterId: json['counterId'] as String,
      counterName: json['counterName'] as String,
      counterAddress: json['counterAddress'] as String,
      sequence: json['sequence'] as int,
      status: VisitStatus.values.firstWhere(
        (e) => e.name == json['status'],
        orElse: () => VisitStatus.planned,
      ),
      scheduledTime: json['scheduledTime'] != null
          ? DateTime.parse(json['scheduledTime'] as String)
          : null,
      checkInTime: json['checkInTime'] != null
          ? DateTime.parse(json['checkInTime'] as String)
          : null,
      checkOutTime: json['checkOutTime'] != null
          ? DateTime.parse(json['checkOutTime'] as String)
          : null,
      notes: json['notes'] as String?,
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
    'counterId': counterId,
    'counterName': counterName,
    'counterAddress': counterAddress,
    'sequence': sequence,
    'status': status.name,
    'scheduledTime': scheduledTime?.toIso8601String(),
    'checkInTime': checkInTime?.toIso8601String(),
    'checkOutTime': checkOutTime?.toIso8601String(),
    'notes': notes,
    'latitude': latitude,
    'longitude': longitude,
  };

  @override
  List<Object?> get props => [id, counterId, sequence];
}

// ============================================
// ROUTE
// ============================================

class SalesRoute extends Equatable {
  final String id;
  final String name;
  final String? territory;
  final int counterCount;
  final String? assignedTo;
  final List<String> visitDays;

  const SalesRoute({
    required this.id,
    required this.name,
    this.territory,
    required this.counterCount,
    this.assignedTo,
    this.visitDays = const [],
  });

  factory SalesRoute.fromJson(Map<String, dynamic> json) {
    return SalesRoute(
      id: json['id'] as String,
      name: json['name'] as String,
      territory: json['territory'] as String?,
      counterCount: json['counterCount'] as int,
      assignedTo: json['assignedTo'] as String?,
      visitDays:
          (json['visitDays'] as List<dynamic>?)
              ?.map((e) => e as String)
              .toList() ??
          [],
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'name': name,
    'territory': territory,
    'counterCount': counterCount,
    'assignedTo': assignedTo,
    'visitDays': visitDays,
  };

  @override
  List<Object?> get props => [id, name];
}

// ============================================
// VISIT EXECUTION
// ============================================

enum ActivityType { order, collection, complaint, feedback, display }

class VisitActivity extends Equatable {
  final String id;
  final String visitId;
  final ActivityType type;
  final String description;
  final double? amount;
  final DateTime createdAt;

  const VisitActivity({
    required this.id,
    required this.visitId,
    required this.type,
    required this.description,
    this.amount,
    required this.createdAt,
  });

  factory VisitActivity.fromJson(Map<String, dynamic> json) {
    return VisitActivity(
      id: json['id'] as String,
      visitId: json['visitId'] as String,
      type: ActivityType.values.firstWhere(
        (e) => e.name == json['type'],
        orElse: () => ActivityType.feedback,
      ),
      description: json['description'] as String,
      amount: json['amount'] != null
          ? (json['amount'] as num).toDouble()
          : null,
      createdAt: DateTime.parse(json['createdAt'] as String),
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'visitId': visitId,
    'type': type.name,
    'description': description,
    'amount': amount,
    'createdAt': createdAt.toIso8601String(),
  };

  @override
  List<Object?> get props => [id, visitId, type];
}

// ============================================
// ROUTE TRACKING
// ============================================

class RouteLocation extends Equatable {
  final double latitude;
  final double longitude;
  final DateTime timestamp;
  final double? accuracy;
  final double? speed;

  const RouteLocation({
    required this.latitude,
    required this.longitude,
    required this.timestamp,
    this.accuracy,
    this.speed,
  });

  factory RouteLocation.fromJson(Map<String, dynamic> json) {
    return RouteLocation(
      latitude: (json['latitude'] as num).toDouble(),
      longitude: (json['longitude'] as num).toDouble(),
      timestamp: DateTime.parse(json['timestamp'] as String),
      accuracy: json['accuracy'] != null
          ? (json['accuracy'] as num).toDouble()
          : null,
      speed: json['speed'] != null ? (json['speed'] as num).toDouble() : null,
    );
  }

  Map<String, dynamic> toJson() => {
    'latitude': latitude,
    'longitude': longitude,
    'timestamp': timestamp.toIso8601String(),
    'accuracy': accuracy,
    'speed': speed,
  };

  @override
  List<Object?> get props => [latitude, longitude, timestamp];
}

class DailyRouteTrack extends Equatable {
  final String id;
  final DateTime date;
  final String userId;
  final List<RouteLocation> locations;
  final double? totalDistance;
  final Duration? totalDuration;

  const DailyRouteTrack({
    required this.id,
    required this.date,
    required this.userId,
    this.locations = const [],
    this.totalDistance,
    this.totalDuration,
  });

  factory DailyRouteTrack.fromJson(Map<String, dynamic> json) {
    return DailyRouteTrack(
      id: json['id'] as String,
      date: DateTime.parse(json['date'] as String),
      userId: json['userId'] as String,
      locations:
          (json['locations'] as List<dynamic>?)
              ?.map((l) => RouteLocation.fromJson(l as Map<String, dynamic>))
              .toList() ??
          [],
      totalDistance: json['totalDistance'] != null
          ? (json['totalDistance'] as num).toDouble()
          : null,
      totalDuration: json['totalDuration'] != null
          ? Duration(seconds: json['totalDuration'] as int)
          : null,
    );
  }

  @override
  List<Object?> get props => [id, date, userId];
}
