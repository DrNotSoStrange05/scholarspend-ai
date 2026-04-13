import 'dart:math';
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../providers/transaction_provider.dart';
import '../theme/app_theme.dart';

// ── Category color map ──────────────────────────────────────
const _catColors = {
  'food':          Color(0xFFFF6584),
  'transport':     Color(0xFF6C63FF),
  'entertainment': Color(0xFF00E5CC),
  'education':     Color(0xFFFFB347),
  'health':        Color(0xFF4CAF50),
  'shopping':      Color(0xFFFF8A65),
  'utilities':     Color(0xFF42A5F5),
  'subscription':  Color(0xFFAB47BC),
  'transfer':      Color(0xFF78909C),
  'other':         Color(0xFF546E7A),
};

class SpendingChart extends StatelessWidget {
  const SpendingChart({super.key});

  @override
  Widget build(BuildContext context) {
    final forecast = context.watch<TransactionProvider>().forecast;
    if (forecast == null || forecast.spendingBreakdown.isEmpty) {
      return const SizedBox(
        height: 200,
        child: Center(child: Text('No spending data yet')),
      );
    }

    final sections = forecast.spendingBreakdown.map((b) {
      final color = _catColors[b.category] ?? AppTheme.primary;
      return PieChartSectionData(
        value: b.totalSpent,
        color: color,
        radius: 60,
        title: b.percentageOfTotal >= 8
            ? '${b.percentageOfTotal.toStringAsFixed(0)}%'
            : '',
        titleStyle: const TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.bold,
          color: Colors.white,
        ),
      );
    }).toList();

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Row(
          children: [
            // ── Pie Chart ────────────────────────────────────
            SizedBox(
              height: 160,
              width: 160,
              child: PieChart(PieChartData(
                sections: sections,
                centerSpaceRadius: 36,
                sectionsSpace: 3,
              )),
            ),
            const SizedBox(width: 20),
            // ── Legend ───────────────────────────────────────
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: forecast.spendingBreakdown.take(6).map((b) {
                  final color = _catColors[b.category] ?? AppTheme.primary;
                  return Padding(
                    padding: const EdgeInsets.symmetric(vertical: 3),
                    child: Row(
                      children: [
                        Container(
                          width: 10,
                          height: 10,
                          decoration: BoxDecoration(
                            color: color,
                            borderRadius: BorderRadius.circular(3),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            b.category.toUpperCase(),
                            style: const TextStyle(
                                color: AppTheme.textSecondary,
                                fontSize: 11,
                                letterSpacing: 0.8),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        Text(
                          '₹${NumberFormat('#,##0').format(b.totalSpent)}',
                          style: const TextStyle(
                              color: AppTheme.textPrimary,
                              fontSize: 12,
                              fontWeight: FontWeight.w600),
                        ),
                      ],
                    ),
                  );
                }).toList(),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
