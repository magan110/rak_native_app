/// Sales Monitoring Service
/// Service for counter mapping, visits, and route tracking

import 'package:flutter/foundation.dart';
import '../models/sales_monitoring_models.dart';

class SalesMonitoringService {
  // ============================================
  // COUNTERS
  // ============================================

  static Future<List<Counter>> getCounters({String? route}) async {
    try {
      await Future.delayed(const Duration(milliseconds: 500));
      if (route != null) {
        return _mockCounters.where((c) => c.route == route).toList();
      }
      return _mockCounters;
    } catch (e) {
      debugPrint('Failed to fetch counters: $e');
      return [];
    }
  }

  static Future<List<Counter>> getCountersDueForVisit() async {
    try {
      await Future.delayed(const Duration(milliseconds: 300));
      return _mockCounters.where((c) => c.isDueForVisit).toList();
    } catch (e) {
      debugPrint('Failed to fetch due counters: $e');
      return [];
    }
  }

  // ============================================
  // ROUTES
  // ============================================

  static Future<List<SalesRoute>> getRoutes() async {
    try {
      await Future.delayed(const Duration(milliseconds: 400));
      return _mockRoutes;
    } catch (e) {
      debugPrint('Failed to fetch routes: $e');
      return [];
    }
  }

  // ============================================
  // VISIT PLANS
  // ============================================

  static Future<DailyVisitPlan?> getTodayVisitPlan() async {
    try {
      await Future.delayed(const Duration(milliseconds: 500));
      return _mockTodayPlan;
    } catch (e) {
      debugPrint('Failed to fetch today plan: $e');
      return null;
    }
  }

  static Future<List<DailyVisitPlan>> getVisitPlans({
    DateTime? startDate,
    DateTime? endDate,
  }) async {
    try {
      await Future.delayed(const Duration(milliseconds: 500));
      return [_mockTodayPlan];
    } catch (e) {
      debugPrint('Failed to fetch visit plans: $e');
      return [];
    }
  }

  // ============================================
  // VISIT EXECUTION
  // ============================================

  static Future<PlannedVisit?> checkInVisit(
    String visitId,
    double lat,
    double lng,
  ) async {
    try {
      await Future.delayed(const Duration(milliseconds: 600));

      final index = _mockTodayPlan.visits.indexWhere((v) => v.id == visitId);
      if (index >= 0) {
        final visit = _mockTodayPlan.visits[index];
        final updated = PlannedVisit(
          id: visit.id,
          counterId: visit.counterId,
          counterName: visit.counterName,
          counterAddress: visit.counterAddress,
          sequence: visit.sequence,
          status: VisitStatus.inProgress,
          scheduledTime: visit.scheduledTime,
          checkInTime: DateTime.now(),
          latitude: lat,
          longitude: lng,
        );
        _mockTodayPlan.visits[index] = updated;
        return updated;
      }
      return null;
    } catch (e) {
      debugPrint('Failed to check in: $e');
      return null;
    }
  }

  static Future<PlannedVisit?> checkOutVisit(
    String visitId,
    String? notes,
  ) async {
    try {
      await Future.delayed(const Duration(milliseconds: 600));

      final index = _mockTodayPlan.visits.indexWhere((v) => v.id == visitId);
      if (index >= 0) {
        final visit = _mockTodayPlan.visits[index];
        final updated = PlannedVisit(
          id: visit.id,
          counterId: visit.counterId,
          counterName: visit.counterName,
          counterAddress: visit.counterAddress,
          sequence: visit.sequence,
          status: VisitStatus.completed,
          scheduledTime: visit.scheduledTime,
          checkInTime: visit.checkInTime,
          checkOutTime: DateTime.now(),
          notes: notes,
          latitude: visit.latitude,
          longitude: visit.longitude,
        );
        _mockTodayPlan.visits[index] = updated;
        return updated;
      }
      return null;
    } catch (e) {
      debugPrint('Failed to check out: $e');
      return null;
    }
  }

  // ============================================
  // ROUTE TRACKING
  // ============================================

  static Future<DailyRouteTrack?> getTodayRouteTrack() async {
    try {
      await Future.delayed(const Duration(milliseconds: 300));
      return _mockRouteTrack;
    } catch (e) {
      debugPrint('Failed to fetch route track: $e');
      return null;
    }
  }

  static Future<void> addLocationPoint(double lat, double lng) async {
    try {
      final location = RouteLocation(
        latitude: lat,
        longitude: lng,
        timestamp: DateTime.now(),
      );
      _mockRouteTrack.locations.add(location);
    } catch (e) {
      debugPrint('Failed to add location: $e');
    }
  }
}

// ============================================
// MOCK DATA
// ============================================

final List<Counter> _mockCounters = [
  Counter(
    id: 'CNT001',
    name: 'Sharma Paint House',
    type: OutletType.retailer,
    status: OutletStatus.active,
    ownerName: 'Rajesh Sharma',
    phone: '+91 9876543210',
    address: '123, MG Road, Mumbai - 400001',
    latitude: 19.0760,
    longitude: 72.8777,
    territory: 'Mumbai Central',
    route: 'Route A',
    lastVisit: DateTime.now().subtract(const Duration(days: 8)),
    visitFrequencyDays: 7,
  ),
  Counter(
    id: 'CNT002',
    name: 'Krishna Hardware',
    type: OutletType.dealer,
    status: OutletStatus.active,
    ownerName: 'Krishna Murthy',
    phone: '+91 9876543211',
    address: '456, Station Road, Mumbai - 400002',
    latitude: 19.0825,
    longitude: 72.8850,
    territory: 'Mumbai Central',
    route: 'Route A',
    lastVisit: DateTime.now().subtract(const Duration(days: 3)),
    visitFrequencyDays: 7,
  ),
  Counter(
    id: 'CNT003',
    name: 'Patel Paints & Colors',
    type: OutletType.retailer,
    status: OutletStatus.active,
    ownerName: 'Jayesh Patel',
    phone: '+91 9876543212',
    address: '789, Hill Road, Bandra - 400050',
    latitude: 19.0596,
    longitude: 72.8295,
    territory: 'Bandra',
    route: 'Route B',
    lastVisit: DateTime.now().subtract(const Duration(days: 10)),
    visitFrequencyDays: 7,
  ),
  Counter(
    id: 'CNT004',
    name: 'Gupta Building Materials',
    type: OutletType.wholesaler,
    status: OutletStatus.active,
    ownerName: 'Suresh Gupta',
    phone: '+91 9876543213',
    address: '321, Link Road, Andheri - 400053',
    latitude: 19.1136,
    longitude: 72.8697,
    territory: 'Andheri',
    route: 'Route C',
    lastVisit: DateTime.now().subtract(const Duration(days: 5)),
    visitFrequencyDays: 14,
  ),
];

final List<SalesRoute> _mockRoutes = [
  SalesRoute(
    id: 'RT001',
    name: 'Route A - Mumbai Central',
    territory: 'Mumbai Central',
    counterCount: 12,
    assignedTo: 'Current User',
    visitDays: ['Monday', 'Wednesday', 'Friday'],
  ),
  SalesRoute(
    id: 'RT002',
    name: 'Route B - Bandra',
    territory: 'Bandra',
    counterCount: 8,
    assignedTo: 'Current User',
    visitDays: ['Tuesday', 'Thursday'],
  ),
  SalesRoute(
    id: 'RT003',
    name: 'Route C - Andheri',
    territory: 'Andheri',
    counterCount: 15,
    assignedTo: 'Current User',
    visitDays: ['Saturday'],
  ),
];

DailyVisitPlan _mockTodayPlan = DailyVisitPlan(
  id: 'VP001',
  date: DateTime.now(),
  routeName: 'Route A - Mumbai Central',
  visits: [
    PlannedVisit(
      id: 'VST001',
      counterId: 'CNT001',
      counterName: 'Sharma Paint House',
      counterAddress: '123, MG Road, Mumbai - 400001',
      sequence: 1,
      status: VisitStatus.completed,
      scheduledTime: DateTime.now().copyWith(hour: 9, minute: 0),
      checkInTime: DateTime.now().copyWith(hour: 9, minute: 5),
      checkOutTime: DateTime.now().copyWith(hour: 9, minute: 45),
      notes: 'Order placed for 20 buckets',
    ),
    PlannedVisit(
      id: 'VST002',
      counterId: 'CNT002',
      counterName: 'Krishna Hardware',
      counterAddress: '456, Station Road, Mumbai - 400002',
      sequence: 2,
      status: VisitStatus.inProgress,
      scheduledTime: DateTime.now().copyWith(hour: 10, minute: 0),
      checkInTime: DateTime.now().copyWith(hour: 10, minute: 10),
    ),
    PlannedVisit(
      id: 'VST003',
      counterId: 'CNT003',
      counterName: 'Patel Paints & Colors',
      counterAddress: '789, Hill Road, Bandra - 400050',
      sequence: 3,
      status: VisitStatus.planned,
      scheduledTime: DateTime.now().copyWith(hour: 11, minute: 0),
    ),
    PlannedVisit(
      id: 'VST004',
      counterId: 'CNT004',
      counterName: 'Gupta Building Materials',
      counterAddress: '321, Link Road, Andheri - 400053',
      sequence: 4,
      status: VisitStatus.planned,
      scheduledTime: DateTime.now().copyWith(hour: 12, minute: 0),
    ),
  ],
  completedCount: 1,
  totalCount: 4,
);

DailyRouteTrack _mockRouteTrack = DailyRouteTrack(
  id: 'TRK001',
  date: DateTime.now(),
  userId: 'user001',
  locations: [
    RouteLocation(
      latitude: 19.0760,
      longitude: 72.8777,
      timestamp: DateTime.now().subtract(const Duration(hours: 2)),
    ),
    RouteLocation(
      latitude: 19.0780,
      longitude: 72.8790,
      timestamp: DateTime.now().subtract(const Duration(hours: 1, minutes: 45)),
    ),
    RouteLocation(
      latitude: 19.0825,
      longitude: 72.8850,
      timestamp: DateTime.now().subtract(const Duration(hours: 1)),
    ),
  ],
  totalDistance: 5.2,
  totalDuration: const Duration(hours: 2),
);
