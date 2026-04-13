/// SurvivalForecast model — mirrors SurvivalForecastResponse from the backend.
class SurvivalForecast {
  final int userId;
  final double currentBalance;
  final String currency;
  final double avgDailySpend;
  final double daysOfSurvival;
  final DateTime? predictedCrashDate;
  final double monthlySubscriptionCost;
  final List<SpendingBreakdown> spendingBreakdown;

  const SurvivalForecast({
    required this.userId,
    required this.currentBalance,
    required this.currency,
    required this.avgDailySpend,
    required this.daysOfSurvival,
    this.predictedCrashDate,
    required this.monthlySubscriptionCost,
    required this.spendingBreakdown,
  });

  factory SurvivalForecast.fromJson(Map<String, dynamic> json) => SurvivalForecast(
        userId: json['user_id'] as int,
        currentBalance: (json['current_balance'] as num).toDouble(),
        currency: json['currency'] as String,
        avgDailySpend: (json['avg_daily_spend'] as num).toDouble(),
        daysOfSurvival: (json['days_of_survival'] as num).toDouble(),
        predictedCrashDate: json['predicted_crash_date'] != null
            ? DateTime.parse(json['predicted_crash_date'] as String)
            : null,
        monthlySubscriptionCost:
            (json['monthly_subscription_cost'] as num).toDouble(),
        spendingBreakdown: (json['spending_breakdown'] as List<dynamic>)
            .map((e) => SpendingBreakdown.fromJson(e as Map<String, dynamic>))
            .toList(),
      );
}

class SpendingBreakdown {
  final String category;
  final double totalSpent;
  final int transactionCount;
  final double percentageOfTotal;

  const SpendingBreakdown({
    required this.category,
    required this.totalSpent,
    required this.transactionCount,
    required this.percentageOfTotal,
  });

  factory SpendingBreakdown.fromJson(Map<String, dynamic> json) => SpendingBreakdown(
        category: json['category'] as String,
        totalSpent: (json['total_spent'] as num).toDouble(),
        transactionCount: json['transaction_count'] as int,
        percentageOfTotal: (json['percentage_of_total'] as num).toDouble(),
      );
}
