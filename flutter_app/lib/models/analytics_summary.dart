/// AnalyticsSummary — mirrors AnalyticsSummaryResponse from the backend.
class AnalyticsSummary {
  final int userId;
  final double totalSpentCurrentMonth;
  final Map<String, double> categoryBreakdown;
  final List<BalanceTrend> balanceTrend;

  const AnalyticsSummary({
    required this.userId,
    required this.totalSpentCurrentMonth,
    required this.categoryBreakdown,
    required this.balanceTrend,
  });

  factory AnalyticsSummary.fromJson(Map<String, dynamic> json) =>
      AnalyticsSummary(
        userId: json['user_id'] as int,
        totalSpentCurrentMonth:
            (json['total_spent_current_month'] as num).toDouble(),
        categoryBreakdown: Map<String, double>.from(
          (json['category_breakdown'] as Map<String, dynamic>)
              .map((k, v) => MapEntry(k, (v as num).toDouble())),
        ),
        balanceTrend: (json['balance_trend'] as List<dynamic>)
            .map((e) => BalanceTrend.fromJson(e as Map<String, dynamic>))
            .toList(),
      );
}

class BalanceTrend {
  final String date;
  final double total;

  const BalanceTrend({required this.date, required this.total});

  factory BalanceTrend.fromJson(Map<String, dynamic> json) => BalanceTrend(
        date: json['date'] as String,
        total: (json['total'] as num).toDouble(),
      );
}
