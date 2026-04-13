class AnalyticsSummary {
  final int userId;
  final double totalSpentCurrentMonth;
  final Map<String, double> categoryBreakdown;
  final List<BalanceTrendPoint> balanceTrend;

  AnalyticsSummary({
    required this.userId,
    required this.totalSpentCurrentMonth,
    required this.categoryBreakdown,
    required this.balanceTrend,
  });

  factory AnalyticsSummary.fromJson(Map<String, dynamic> json) {
    return AnalyticsSummary(
      userId: json['user_id'] ?? 0,
      totalSpentCurrentMonth: (json['total_spent_current_month'] ?? 0.0).toDouble(),
      categoryBreakdown: Map<String, double>.from(
        (json['category_breakdown'] as Map?)?.cast<String, dynamic>().map(
              (k, v) => MapEntry(k, (v as num).toDouble()),
            ) ??
            {},
      ),
      balanceTrend: (json['balance_trend'] as List?)
              ?.map((e) => BalanceTrendPoint.fromJson(e))
              .toList() ??
          [],
    );
  }
}

class BalanceTrendPoint {
  final String date;
  final double total;

  BalanceTrendPoint({
    required this.date,
    required this.total,
  });

  factory BalanceTrendPoint.fromJson(Map<String, dynamic> json) {
    return BalanceTrendPoint(
      date: json['date'] ?? '',
      total: (json['total'] ?? 0.0).toDouble(),
    );
  }
}
