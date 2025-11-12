/// Models for Dashboard endpoints: /stats, /trends, /recent
library;

class DashboardStats {
  final String start; // yyyy-MM-dd
  final String end; // yyyy-MM-dd
  final int totalRegistrations;
  final int contractors;
  final int painters;
  final int pending;

  DashboardStats({
    required this.start,
    required this.end,
    required this.totalRegistrations,
    required this.contractors,
    required this.painters,
    required this.pending,
  });

  factory DashboardStats.fromJson(Map<String, dynamic> json) {
    return DashboardStats(
      start: json['start'] as String? ?? '',
      end: json['end'] as String? ?? '',
      totalRegistrations: (json['totalRegistrations'] ?? 0) as int,
      contractors: (json['contractors'] ?? 0) as int,
      painters: (json['painters'] ?? 0) as int,
      pending: (json['pending'] ?? 0) as int,
    );
  }
}

class TrendPoint {
  final String date; // yyyy-MM-dd
  final int total;
  final int contractors;
  final int painters;
  final int approved;
  final int pending;
  final int rejected;

  TrendPoint({
    required this.date,
    required this.total,
    required this.contractors,
    required this.painters,
    required this.approved,
    required this.pending,
    required this.rejected,
  });

  factory TrendPoint.fromJson(Map<String, dynamic> json) {
    return TrendPoint(
      date: json['date'] as String? ?? '',
      total: (json['total'] ?? 0) as int,
      contractors: (json['contractors'] ?? 0) as int,
      painters: (json['painters'] ?? 0) as int,
      approved: (json['approved'] ?? 0) as int,
      pending: (json['pending'] ?? 0) as int,
      rejected: (json['rejected'] ?? 0) as int,
    );
  }
}

class TrendsResponse {
  final String start; // yyyy-MM-dd
  final String end; // yyyy-MM-dd
  final List<TrendPoint> data;

  TrendsResponse({required this.start, required this.end, required this.data});

  factory TrendsResponse.fromJson(Map<String, dynamic> json) {
    final list = (json['data'] as List<dynamic>? ?? [])
        .map((e) => TrendPoint.fromJson(e as Map<String, dynamic>))
        .toList();
    return TrendsResponse(
      start: json['start'] as String? ?? '',
      end: json['end'] as String? ?? '',
      data: list,
    );
  }
}

class RecentItem {
  final String name;
  final String type;
  final String status;
  final String date; // yyyy-MM-dd
  final String avatar; // 2 letters

  RecentItem({
    required this.name,
    required this.type,
    required this.status,
    required this.date,
    required this.avatar,
  });

  factory RecentItem.fromJson(Map<String, dynamic> json) {
    return RecentItem(
      name: json['name'] as String? ?? '',
      type: json['type'] as String? ?? '',
      status: json['status'] as String? ?? '',
      date: json['date'] as String? ?? '',
      avatar: json['avatar'] as String? ?? '',
    );
  }
}

class RecentResponse {
  final List<RecentItem> items;

  RecentResponse({required this.items});

  factory RecentResponse.fromJson(Map<String, dynamic> json) {
    final list = (json['items'] as List<dynamic>? ?? [])
        .map((e) => RecentItem.fromJson(e as Map<String, dynamic>))
        .toList();
    return RecentResponse(items: list);
  }
}
