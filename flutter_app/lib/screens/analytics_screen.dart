import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';

import '../providers/analytics_provider.dart';
import '../theme/app_theme.dart';
import '../models/analytics_summary.dart';

// Inline chart to avoid heavy fl_chart import complications in the widget file
import 'package:fl_chart/fl_chart.dart';

class AnalyticsScreen extends StatefulWidget {
  const AnalyticsScreen({super.key});

  @override
  State<AnalyticsScreen> createState() => _AnalyticsScreenState();
}

class _AnalyticsScreenState extends State<AnalyticsScreen> {
  static const int _userId = 1;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<AnalyticsProvider>().loadSummary(_userId);
    });
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<AnalyticsProvider>();
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textPrimary   = isDark ? AppTheme.textPrimary   : const Color(0xFF1A1A2E);
    final textSecondary = isDark ? AppTheme.textSecondary : const Color(0xFF666688);
    final cardColor     = isDark ? AppTheme.card          : Colors.white;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Analytics'),
      ),
      body: provider.isLoading
          ? const Center(child: CircularProgressIndicator())
          : provider.summary == null
              ? _EmptyState(error: provider.error)
              : RefreshIndicator(
                  onRefresh: () =>
                      context.read<AnalyticsProvider>().loadSummary(_userId),
                  child: ListView(
                    padding: const EdgeInsets.all(20),
                    children: [
                      // ── Monthly Spent Hero ─────────────────────────
                      _SectionLabel('THIS MONTH', textSecondary),
                      const SizedBox(height: 8),
                      _MonthlyCard(
                        summary: provider.summary!,
                        cardColor: cardColor,
                        textPrimary: textPrimary,
                        textSecondary: textSecondary,
                      ),
                      const SizedBox(height: 28),

                      // ── Pie Chart ─────────────────────────────────
                      _SectionLabel('CATEGORY BREAKDOWN', textSecondary),
                      const SizedBox(height: 12),
                      _CategoryPieChart(
                        breakdown: provider.summary!.categoryBreakdown,
                        cardColor: cardColor,
                        textPrimary: textPrimary,
                        textSecondary: textSecondary,
                      ),
                      const SizedBox(height: 28),

                      // ── Bar Chart ─────────────────────────────────
                      _SectionLabel('7-DAY SPEND TREND', textSecondary),
                      const SizedBox(height: 12),
                      _BalanceTrendChart(
                        trend: provider.summary!.balanceTrend,
                        cardColor: cardColor,
                        textPrimary: textPrimary,
                        textSecondary: textSecondary,
                      ),
                      const SizedBox(height: 20),
                    ],
                  ),
                ),
    );
  }
}

// ───────────────────────────── Helpers ──────────────────────────────────────

class _SectionLabel extends StatelessWidget {
  final String label;
  final Color color;
  const _SectionLabel(this.label, this.color);

  @override
  Widget build(BuildContext context) => Text(
        label,
        style: TextStyle(
          color: color,
          fontSize: 11,
          letterSpacing: 1.4,
          fontWeight: FontWeight.w600,
        ),
      );
}

class _MonthlyCard extends StatelessWidget {
  final AnalyticsSummary summary;
  final Color cardColor;
  final Color textPrimary;
  final Color textSecondary;

  const _MonthlyCard({
    required this.summary,
    required this.cardColor,
    required this.textPrimary,
    required this.textSecondary,
  });

  @override
  Widget build(BuildContext context) {
    final fmt = NumberFormat('#,##0.00');
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF6C63FF), Color(0xFF4C46C9)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: AppTheme.primary.withOpacity(0.4),
            blurRadius: 16,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Total Spent',
            style: TextStyle(
              color: Colors.white.withOpacity(0.8),
              fontSize: 13,
              letterSpacing: 0.5,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            '₹${fmt.format(summary.totalSpentCurrentMonth)}',
            style: const TextStyle(
              color: Colors.white,
              fontSize: 36,
              fontWeight: FontWeight.w800,
              letterSpacing: -1,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            DateFormat('MMMM yyyy').format(DateTime.now()),
            style: TextStyle(
              color: Colors.white.withOpacity(0.7),
              fontSize: 13,
            ),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────── Pie Chart ─────────────────────────────────────────

const _categoryColors = [
  Color(0xFF6C63FF),
  Color(0xFF00E5CC),
  Color(0xFFFFB347),
  Color(0xFFFF4F6D),
  Color(0xFF4CAF50),
  Color(0xFF2196F3),
  Color(0xFFFF9800),
  Color(0xFF9C27B0),
  Color(0xFF00BCD4),
  Color(0xFF795548),
];

class _CategoryPieChart extends StatefulWidget {
  final Map<String, double> breakdown;
  final Color cardColor;
  final Color textPrimary;
  final Color textSecondary;

  const _CategoryPieChart({
    required this.breakdown,
    required this.cardColor,
    required this.textPrimary,
    required this.textSecondary,
  });

  @override
  State<_CategoryPieChart> createState() => _CategoryPieChartState();
}

class _CategoryPieChartState extends State<_CategoryPieChart> {
  int _touchedIndex = -1;

  @override
  Widget build(BuildContext context) {
    final entries = widget.breakdown.entries.toList();
    if (entries.isEmpty) {
      return Container(
        height: 200,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: widget.cardColor,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Text('No spending data yet',
            style: TextStyle(color: widget.textSecondary)),
      );
    }

    final total = entries.fold(0.0, (s, e) => s + e.value);
    final sections = entries.asMap().entries.map((entry) {
      final i = entry.key;
      final e = entry.value;
      final isTouched = i == _touchedIndex;
      final radius = isTouched ? 70.0 : 60.0;
      return PieChartSectionData(
        color: _categoryColors[i % _categoryColors.length],
        value: e.value,
        title: isTouched ? '${(e.value / total * 100).toStringAsFixed(1)}%' : '',
        radius: radius,
        titleStyle: const TextStyle(
          color: Colors.white,
          fontSize: 12,
          fontWeight: FontWeight.w700,
        ),
      );
    }).toList();

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: widget.cardColor,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        children: [
          SizedBox(
            height: 200,
            child: PieChart(
              PieChartData(
                sections: sections,
                centerSpaceRadius: 40,
                sectionsSpace: 3,
                pieTouchData: PieTouchData(
                  touchCallback: (event, response) {
                    setState(() {
                      if (!event.isInterestedForInteractions ||
                          response == null ||
                          response.touchedSection == null) {
                        _touchedIndex = -1;
                        return;
                      }
                      _touchedIndex =
                          response.touchedSection!.touchedSectionIndex;
                    });
                  },
                ),
              ),
            ),
          ),
          const SizedBox(height: 16),
          // Legend
          Wrap(
            spacing: 16,
            runSpacing: 8,
            children: entries.asMap().entries.map((entry) {
              final i = entry.key;
              final e = entry.value;
              return Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 10,
                    height: 10,
                    decoration: BoxDecoration(
                      color: _categoryColors[i % _categoryColors.length],
                      shape: BoxShape.circle,
                    ),
                  ),
                  const SizedBox(width: 6),
                  Text(
                    '${e.key[0].toUpperCase()}${e.key.substring(1)}',
                    style: TextStyle(
                      color: widget.textSecondary,
                      fontSize: 12,
                    ),
                  ),
                ],
              );
            }).toList(),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────── Bar Chart ─────────────────────────────────────────

class _BalanceTrendChart extends StatelessWidget {
  final List<BalanceTrend> trend;
  final Color cardColor;
  final Color textPrimary;
  final Color textSecondary;

  const _BalanceTrendChart({
    required this.trend,
    required this.cardColor,
    required this.textPrimary,
    required this.textSecondary,
  });

  @override
  Widget build(BuildContext context) {
    if (trend.isEmpty) {
      return Container(
        height: 200,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: cardColor,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Text('No trend data yet',
            style: TextStyle(color: textSecondary)),
      );
    }

    final maxVal = trend.fold(0.0, (m, t) => t.total > m ? t.total : m);

    final bars = trend.asMap().entries.map((entry) {
      final i = entry.key;
      final t = entry.value;
      return BarChartGroupData(
        x: i,
        barRods: [
          BarChartRodData(
            toY: t.total,
            gradient: const LinearGradient(
              colors: [Color(0xFF6C63FF), Color(0xFF00E5CC)],
              begin: Alignment.bottomCenter,
              end: Alignment.topCenter,
            ),
            width: 18,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(6)),
          ),
        ],
      );
    }).toList();

    // Short day labels from date strings
    String shortDay(String dateStr) {
      final d = DateTime.tryParse(dateStr);
      if (d == null) return '';
      return DateFormat('E').format(d); // Mon, Tue, …
    }

    return Container(
      padding: const EdgeInsets.fromLTRB(8, 16, 16, 8),
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(16),
      ),
      child: SizedBox(
        height: 200,
        child: BarChart(
          BarChartData(
            maxY: maxVal * 1.2,
            gridData: FlGridData(
              show: true,
              drawVerticalLine: false,
              getDrawingHorizontalLine: (v) => FlLine(
                color: textSecondary.withOpacity(0.15),
                strokeWidth: 1,
              ),
            ),
            borderData: FlBorderData(show: false),
            titlesData: FlTitlesData(
              bottomTitles: AxisTitles(
                sideTitles: SideTitles(
                  showTitles: true,
                  reservedSize: 28,
                  getTitlesWidget: (value, meta) {
                    final i = value.toInt();
                    if (i < 0 || i >= trend.length) return const SizedBox();
                    return Padding(
                      padding: const EdgeInsets.only(top: 6),
                      child: Text(
                        shortDay(trend[i].date),
                        style: TextStyle(color: textSecondary, fontSize: 11),
                      ),
                    );
                  },
                ),
              ),
              leftTitles: AxisTitles(
                sideTitles: SideTitles(
                  showTitles: true,
                  reservedSize: 48,
                  getTitlesWidget: (value, meta) => Text(
                    '₹${(value / 1000).toStringAsFixed(1)}k',
                    style: TextStyle(color: textSecondary, fontSize: 10),
                  ),
                ),
              ),
              topTitles: const AxisTitles(
                  sideTitles: SideTitles(showTitles: false)),
              rightTitles: const AxisTitles(
                  sideTitles: SideTitles(showTitles: false)),
            ),
            barGroups: bars,
          ),
        ),
      ),
    );
  }
}

// ─────────────────────── Empty State ───────────────────────────────────────

class _EmptyState extends StatelessWidget {
  final String? error;
  const _EmptyState({this.error});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.bar_chart_outlined,
                size: 64, color: AppTheme.textSecondary.withOpacity(0.4)),
            const SizedBox(height: 16),
            Text(
              error ?? 'No analytics data available yet.\nStart adding transactions!',
              textAlign: TextAlign.center,
              style:
                  const TextStyle(color: AppTheme.textSecondary, fontSize: 14),
            ),
          ],
        ),
      ),
    );
  }
}
