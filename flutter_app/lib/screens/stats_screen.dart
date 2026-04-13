import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:fl_chart/fl_chart.dart';

import '../providers/auth_provider.dart';
import '../providers/transaction_provider.dart';
import '../providers/analytics_provider.dart';
import '../theme/app_theme.dart';

class StatsScreen extends StatefulWidget {
  const StatsScreen({super.key});

  @override
  State<StatsScreen> createState() => _StatsScreenState();
}

class _StatsScreenState extends State<StatsScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final authProvider = context.read<AuthProvider>();
      if (authProvider.userId != null) {
        context.read<TransactionProvider>().loadData(authProvider.userId!);
        context.read<AnalyticsProvider>().loadSummary(authProvider.userId!);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final authProvider = context.watch<AuthProvider>();
    final txnProvider = context.watch<TransactionProvider>();
    final analyticsProvider = context.watch<AnalyticsProvider>();

    if (authProvider.userId == null) {
      return const Scaffold(
        body: Center(child: Text('Please login first')),
      );
    }

    if (txnProvider.isLoading || analyticsProvider.isLoading) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    return DefaultTabController(
      length: 4,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('📊 Financial Stats'),
          centerTitle: true,
          bottom: const TabBar(
            tabs: [
              Tab(text: '💰 Total Spent'),
              Tab(text: '📈 Monthly'),
              Tab(text: '🏆 Rankings'),
              Tab(text: '💎 Savings'),
            ],
          ),
        ),
        body: txnProvider.isLoading || analyticsProvider.isLoading
            ? const Center(child: CircularProgressIndicator())
            : TabBarView(
                children: [
                  // Tab 1: Total Spent
                  _TotalSpentTab(provider: txnProvider),

                  // Tab 2: Monthly Analytics
                  _MonthlyTab(analyticsProvider: analyticsProvider),

                  // Tab 3: Leaderboard/Rankings
                  _LeaderboardTab(provider: txnProvider),

                  // Tab 4: Monthly Savings
                  _SavingsTab(provider: txnProvider),
                ],
              ),
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════
// Tab 1: Total Spent
// ═══════════════════════════════════════════════════════════════════════════

class _TotalSpentTab extends StatelessWidget {
  final TransactionProvider provider;

  const _TotalSpentTab({required this.provider});

  @override
  Widget build(BuildContext context) {
    final totalSpent =
        provider.transactions.fold<double>(0, (sum, t) => sum + (t.amount < 0 ? t.amount.abs() : 0));
    final totalReceived =
        provider.transactions.fold<double>(0, (sum, t) => sum + (t.amount > 0 ? t.amount : 0));

    // Group by category
    final categorySpending = <String, double>{};
    for (final txn in provider.transactions) {
      if (txn.amount < 0) {
        final category = txn.category;
        categorySpending[category] = (categorySpending[category] ?? 0) + txn.amount.abs();
      }
    }

    final sortedCategories = categorySpending.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        // Total Spent Card
        Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [Colors.red.shade700, Colors.red.shade900],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(16),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                '🔴 Total Spent',
                style: TextStyle(color: Colors.white70, fontSize: 14),
              ),
              const SizedBox(height: 8),
              Text(
                '₹${totalSpent.toStringAsFixed(2)}',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 36,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),

        // Total Received Card
        Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [Colors.green.shade700, Colors.green.shade900],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(16),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                '🟢 Total Received',
                style: TextStyle(color: Colors.white70, fontSize: 14),
              ),
              const SizedBox(height: 8),
              Text(
                '₹${totalReceived.toStringAsFixed(2)}',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 36,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 24),

        // Category Breakdown
        const Text(
          'BREAKDOWN BY CATEGORY',
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.bold,
            color: AppTheme.textSecondary,
            letterSpacing: 1.2,
          ),
        ),
        const SizedBox(height: 12),
        ...sortedCategories.map((entry) {
          final percentage = (entry.value / totalSpent * 100).toStringAsFixed(1);
          return Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      entry.key,
                      style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
                    ),
                    Text(
                      '₹${entry.value.toStringAsFixed(2)} ($percentage%)',
                      style: const TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.bold,
                        color: AppTheme.primary,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                ClipRRect(
                  borderRadius: BorderRadius.circular(4),
                  child: LinearProgressIndicator(
                    value: entry.value / totalSpent,
                    minHeight: 8,
                    backgroundColor: AppTheme.card,
                    valueColor: AlwaysStoppedAnimation<Color>(
                      _getCategoryColor(entry.key),
                    ),
                  ),
                ),
              ],
            ),
          );
        }),
      ],
    );
  }

  Color _getCategoryColor(String category) {
    final colors = {
      'Food': Colors.orange,
      'Transport': Colors.blue,
      'Entertainment': Colors.purple,
      'Education': Colors.teal,
      'Shopping': Colors.pink,
      'Utilities': Colors.amber,
      'Health': Colors.red,
      'Other': Colors.grey,
    };
    return colors[category] ?? Colors.grey;
  }
}

// ═══════════════════════════════════════════════════════════════════════════
// Tab 2: Monthly Analytics
// ═══════════════════════════════════════════════════════════════════════════

class _MonthlyTab extends StatelessWidget {
  final AnalyticsProvider analyticsProvider;

  const _MonthlyTab({required this.analyticsProvider});

  @override
  Widget build(BuildContext context) {
    final summary = analyticsProvider.summary;
    if (summary == null) {
      return const Center(child: Text('No analytics data available'));
    }

    final currentMonth = DateFormat('MMMM yyyy').format(DateTime.now());

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        // Month Header
        Text(
          currentMonth,
          style: const TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: AppTheme.textPrimary,
          ),
        ),
        const SizedBox(height: 16),

        // Monthly Totals
        Row(
          children: [
            Expanded(
              child: _StatCard(
                title: 'TOTAL SPENT',
                value: '₹${summary.totalSpentCurrentMonth.toStringAsFixed(2)}',
                icon: '💸',
                color: Colors.red,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _StatCard(
                title: 'AVG PER DAY',
                value: '₹${(summary.totalSpentCurrentMonth / 30).toStringAsFixed(2)}',
                icon: '📊',
                color: Colors.orange,
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),

        Row(
          children: [
            Expanded(
              child: _StatCard(
                title: 'DAYS REMAINING',
                value: '${DateTime.now().daysInMonth - DateTime.now().day}',
                icon: '📅',
                color: Colors.blue,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _StatCard(
                title: 'TOP CATEGORY',
                value: summary.categoryBreakdown.isNotEmpty
                    ? summary.categoryBreakdown.entries
                        .reduce((a, b) => a.value > b.value ? a : b)
                        .key
                    : 'N/A',
                icon: '🏆',
                color: Colors.purple,
              ),
            ),
          ],
        ),
        const SizedBox(height: 24),

        // 7-Day Trend Chart
        const Text(
          '7-DAY SPENDING TREND',
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.bold,
            color: AppTheme.textSecondary,
            letterSpacing: 1.2,
          ),
        ),
        const SizedBox(height: 12),
        Container(
          height: 200,
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: AppTheme.card,
            borderRadius: BorderRadius.circular(12),
          ),
          child: LineChart(
            LineChartData(
              gridData: const FlGridData(show: false),
              titlesData: const FlTitlesData(show: false),
              borderData: FlBorderData(show: false),
              lineBarsData: [
                LineChartBarData(
                  spots: List.generate(
                    summary.balanceTrend.length,
                    (i) => FlSpot(i.toDouble(), summary.balanceTrend[i].total),
                  ),
                  isCurved: true,
                  color: AppTheme.primary,
                  dotData: const FlDotData(show: true),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════
// Tab 3: Leaderboard/Rankings
// ═══════════════════════════════════════════════════════════════════════════

class _LeaderboardTab extends StatelessWidget {
  final TransactionProvider provider;

  const _LeaderboardTab({required this.provider});

  @override
  Widget build(BuildContext context) {
    // Group transactions by category and count/amount
    final categoryStats = <String, Map<String, dynamic>>{};

    for (final txn in provider.transactions) {
      final category = txn.category;
      if (!categoryStats.containsKey(category)) {
        categoryStats[category] = {'count': 0, 'total': 0.0};
      }
      if (txn.amount < 0) {
        categoryStats[category]!['count']++;
        categoryStats[category]!['total'] += txn.amount.abs();
      }
    }

    final sortedCategories = categoryStats.entries.toList()
      ..sort((a, b) => (b.value['total'] as double).compareTo(a.value['total'] as double));

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        const Text(
          '🏆 SPENDING LEADERBOARD',
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.bold,
            color: AppTheme.textSecondary,
            letterSpacing: 1.2,
          ),
        ),
        const SizedBox(height: 16),
        ...List.generate(sortedCategories.length, (index) {
          final entry = sortedCategories[index];
          final medal = index == 0 ? '🥇' : index == 1 ? '🥈' : index == 2 ? '🥉' : '${index + 1}.';

          return Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppTheme.card,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: index < 3 ? AppTheme.primary : Colors.transparent,
                  width: index < 3 ? 2 : 0,
                ),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '$medal ${entry.key}',
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '${entry.value['count']} transactions',
                        style: const TextStyle(
                          fontSize: 12,
                          color: AppTheme.textSecondary,
                        ),
                      ),
                    ],
                  ),
                  Text(
                    '₹${(entry.value['total'] as double).toStringAsFixed(2)}',
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: AppTheme.primary,
                    ),
                  ),
                ],
              ),
            ),
          );
        }),
      ],
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════
// Tab 4: Monthly Savings
// ═══════════════════════════════════════════════════════════════════════════

class _SavingsTab extends StatelessWidget {
  final TransactionProvider provider;

  const _SavingsTab({required this.provider});

  @override
  Widget build(BuildContext context) {
    final totalReceived =
        provider.transactions.fold<double>(0, (sum, t) => sum + (t.amount > 0 ? t.amount : 0));
    final totalSpent =
        provider.transactions.fold<double>(0, (sum, t) => sum + (t.amount < 0 ? t.amount.abs() : 0));
    final netSavings = totalReceived - totalSpent;
    final savingsPercentage = totalReceived > 0 ? (netSavings / totalReceived * 100) : 0.0;

    // Group by month
    final monthlyData = <String, Map<String, double>>{};
    for (final txn in provider.transactions) {
      final monthKey = DateFormat('MMM yyyy').format(txn.transactedAt);
      if (!monthlyData.containsKey(monthKey)) {
        monthlyData[monthKey] = {'received': 0.0, 'spent': 0.0};
      }
      if (txn.amount > 0) {
        monthlyData[monthKey]!['received'] = (monthlyData[monthKey]!['received'] ?? 0) + txn.amount;
      } else {
        monthlyData[monthKey]!['spent'] =
            (monthlyData[monthKey]!['spent'] ?? 0) + txn.amount.abs();
      }
    }

    final sortedMonths = monthlyData.entries.toList()
      ..sort((a, b) => b.key.compareTo(a.key));

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        // Savings Overview
        Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [Colors.teal.shade700, Colors.teal.shade900],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(16),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                '💎 Net Savings',
                style: TextStyle(color: Colors.white70, fontSize: 14),
              ),
              const SizedBox(height: 12),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '₹${netSavings.toStringAsFixed(2)}',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 32,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '${savingsPercentage.toStringAsFixed(1)}% of income',
                        style: const TextStyle(color: Colors.white70, fontSize: 13),
                      ),
                    ],
                  ),
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      savingsPercentage > 0 ? '📈' : '📉',
                      style: const TextStyle(fontSize: 28),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
        const SizedBox(height: 24),

        // Monthly Breakdown
        const Text(
          'MONTHLY BREAKDOWN',
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.bold,
            color: AppTheme.textSecondary,
            letterSpacing: 1.2,
          ),
        ),
        const SizedBox(height: 12),
        ...sortedMonths.map((entry) {
          final received = entry.value['received'] ?? 0.0;
          final spent = entry.value['spent'] ?? 0.0;
          final savings = received - spent;

          return Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppTheme.card,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    entry.key,
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      _MiniStat('Income', '₹${received.toStringAsFixed(2)}', Colors.green),
                      _MiniStat('Spent', '₹${spent.toStringAsFixed(2)}', Colors.red),
                      _MiniStat(
                        'Saved',
                        '₹${savings.toStringAsFixed(2)}',
                        savings > 0 ? Colors.teal : Colors.orange,
                      ),
                    ],
                  ),
                ],
              ),
            ),
          );
        }),
      ],
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════
// Helpers
// ═══════════════════════════════════════════════════════════════════════════

class _StatCard extends StatelessWidget {
  final String title;
  final String value;
  final String icon;
  final Color color;

  const _StatCard({
    required this.title,
    required this.value,
    required this.icon,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        border: Border.all(color: color.withOpacity(0.3)),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '$icon $title',
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w600,
              color: color,
              letterSpacing: 0.5,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            value,
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: AppTheme.textPrimary,
            ),
          ),
        ],
      ),
    );
  }
}

class _MiniStat extends StatelessWidget {
  final String label;
  final String value;
  final Color color;

  const _MiniStat(this.label, this.value, this.color);

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(fontSize: 11, color: AppTheme.textSecondary),
        ),
        const SizedBox(height: 4),
        Text(
          value,
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
      ],
    );
  }
}

extension on DateTime {
  int get daysInMonth {
    return DateTime(year, month + 1, 0).day;
  }
}
