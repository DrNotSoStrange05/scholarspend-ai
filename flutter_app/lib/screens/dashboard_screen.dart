import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../providers/transaction_provider.dart';
import '../providers/auth_provider.dart';
import '../theme/app_theme.dart';
import '../widgets/survival_counter_card.dart';
import '../widgets/spending_chart.dart';
import '../widgets/crash_alert_banner.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final authProvider = context.read<AuthProvider>();
      if (authProvider.userId != null) {
        final provider = context.read<TransactionProvider>();
        provider.loadData(authProvider.userId!);
        provider.startSmsListener(authProvider.userId!);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final authProvider = context.watch<AuthProvider>();
    final provider = context.watch<TransactionProvider>();

    if (authProvider.userId == null) {
      return const Scaffold(
        body: Center(child: Text('Please login first')),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: Text('👋 ${authProvider.userName ?? "Scholar"}'),
        actions: [
          IconButton(
            icon: const Icon(Icons.add),
            tooltip: 'Add Transaction',
            onPressed: () => Navigator.pushNamed(context, '/add-transaction'),
          ),
          IconButton(
            icon: const Icon(Icons.receipt_long_outlined),
            tooltip: 'Transaction Ledger',
            onPressed: () => Navigator.pushNamed(context, '/ledger'),
          ),
          IconButton(
            icon: const Icon(Icons.bar_chart),
            tooltip: 'Financial Stats',
            onPressed: () => Navigator.pushNamed(context, '/stats'),
          ),
          IconButton(
            icon: const Icon(Icons.logout),
            tooltip: 'Logout',
            onPressed: () {
              context.read<AuthProvider>().logout();
            },
          ),
        ],
      ),
      body: provider.isLoading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: () => provider.loadData(authProvider.userId!),
              color: AppTheme.primary,
              child: ListView(
                padding: const EdgeInsets.all(20),
                children: [
                  // ── Crash alert (only shows if days < 7) ──────
                  if (provider.survivalStatus == 'danger')
                    const CrashAlertBanner(),

                  const SizedBox(height: 16),

                  // ── Survival counter ──────────────────────────
                  const SurvivalCounterCard(),

                  const SizedBox(height: 20),

                  // ── Stats row ─────────────────────────────────
                  Row(
                    children: [
                      _StatChip(
                        label: 'BALANCE',
                        value: '₹${_fmt(provider.currentBalance)}',
                        color: AppTheme.accent,
                      ),
                      const SizedBox(width: 12),
                      _StatChip(
                        label: 'AVG DAILY',
                        value: '₹${_fmt(provider.avgDailySpend)}',
                        color: AppTheme.warning,
                      ),
                    ],
                  ),

                  const SizedBox(height: 24),

                  // ── Spending breakdown chart ───────────────────
                  const Text(
                    'SPENDING BREAKDOWN',
                    style: TextStyle(
                      color: AppTheme.textSecondary,
                      fontSize: 11,
                      letterSpacing: 1.4,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 12),
                  const SpendingChart(),

                  const SizedBox(height: 24),

                  // ── Recent transactions (top 5 preview) ───────
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'RECENT',
                        style: TextStyle(
                          color: AppTheme.textSecondary,
                          fontSize: 11,
                          letterSpacing: 1.4,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      GestureDetector(
                        onTap: () => Navigator.pushNamed(context, '/ledger'),
                        child: const Text(
                          'See all',
                          style: TextStyle(color: AppTheme.primary, fontSize: 13),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  ...provider.transactions
                      .take(5)
                      .map((t) => _TxnRow(txn: t)),
                ],
              ),
            ),
    );
  }

  String _fmt(double v) => NumberFormat('#,##0.00').format(v);
}

class _StatChip extends StatelessWidget {
  final String label;
  final String value;
  final Color color;
  const _StatChip({required this.label, required this.value, required this.color});

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          color: AppTheme.card,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: color.withOpacity(0.3), width: 1),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(label,
                style: const TextStyle(
                    color: AppTheme.textSecondary, fontSize: 10, letterSpacing: 1.2)),
            const SizedBox(height: 6),
            Text(value,
                style: TextStyle(
                    color: color, fontSize: 20, fontWeight: FontWeight.w800)),
          ],
        ),
      ),
    );
  }
}

class _TxnRow extends StatelessWidget {
  final dynamic txn;
  const _TxnRow({required this.txn});

  @override
  Widget build(BuildContext context) {
    final isDebit = txn.isDebit;
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 4),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: AppTheme.card,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          // Category icon
          Container(
            width: 36, height: 36,
            decoration: BoxDecoration(
              color: (isDebit ? AppTheme.danger : AppTheme.success).withOpacity(0.12),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(
              isDebit ? Icons.arrow_upward : Icons.arrow_downward,
              color: isDebit ? AppTheme.danger : AppTheme.success,
              size: 16,
            ),
          ),
          const SizedBox(width: 12),
          // Merchant + category
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(txn.merchant ?? txn.category,
                    style: const TextStyle(color: AppTheme.textPrimary, fontSize: 14)),
                Text(DateFormat('dd MMM, h:mm a').format(txn.transactedAt),
                    style: const TextStyle(color: AppTheme.textSecondary, fontSize: 12)),
              ],
            ),
          ),
          // Amount
          Text(
            '${isDebit ? '-' : '+'}₹${txn.amount.toStringAsFixed(0)}',
            style: TextStyle(
              color: isDebit ? AppTheme.danger : AppTheme.success,
              fontWeight: FontWeight.w700,
              fontSize: 15,
            ),
          ),
        ],
      ),
    );
  }
}
