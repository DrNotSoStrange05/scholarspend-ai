import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../providers/transaction_provider.dart';
import '../theme/app_theme.dart';

class LedgerScreen extends StatelessWidget {
  const LedgerScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<TransactionProvider>();
    final txns = provider.transactions;

    return Scaffold(
      appBar: AppBar(title: const Text('Transaction Ledger')),
      body: txns.isEmpty
          ? const Center(
              child: Text(
                'No transactions yet.\nBank SMS alerts will appear here automatically.',
                textAlign: TextAlign.center,
                style: TextStyle(color: AppTheme.textSecondary),
              ),
            )
          : ListView.separated(
              padding: const EdgeInsets.all(16),
              itemCount: txns.length,
              separatorBuilder: (_, __) => const SizedBox(height: 8),
              itemBuilder: (context, i) {
                final t = txns[i];
                final isDebit = t.isDebit;
                final color = isDebit ? AppTheme.danger : AppTheme.success;

                return Container(
                  decoration: BoxDecoration(
                    color: AppTheme.card,
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: ListTile(
                    contentPadding:
                        const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    leading: CircleAvatar(
                      backgroundColor: color.withOpacity(0.15),
                      child: Icon(
                        isDebit ? Icons.arrow_upward : Icons.arrow_downward,
                        color: color,
                        size: 18,
                      ),
                    ),
                    title: Text(
                      t.merchant ?? t.category.toUpperCase(),
                      style: const TextStyle(
                          color: AppTheme.textPrimary,
                          fontWeight: FontWeight.w600),
                    ),
                    subtitle: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const SizedBox(height: 2),
                        Text(
                          DateFormat('dd MMM yyyy, h:mm a').format(t.transactedAt),
                          style: const TextStyle(
                              color: AppTheme.textSecondary, fontSize: 12),
                        ),
                        if (t.bankName != null)
                          Text(
                            '${t.bankName}${t.accountLast4 != null ? ' ••••${t.accountLast4}' : ''}',
                            style: const TextStyle(
                                color: AppTheme.textSecondary, fontSize: 11),
                          ),
                        // Category chip
                        const SizedBox(height: 4),
                        Chip(
                          label: Text(
                            t.category.toUpperCase(),
                            style: const TextStyle(fontSize: 9, letterSpacing: 0.8),
                          ),
                          padding: EdgeInsets.zero,
                          materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                          backgroundColor: AppTheme.primary.withOpacity(0.15),
                          labelStyle: const TextStyle(color: AppTheme.primary),
                          side: BorderSide.none,
                        ),
                      ],
                    ),
                    trailing: Text(
                      '${isDebit ? '-' : '+'}₹${NumberFormat('#,##0.00').format(t.amount)}',
                      style: TextStyle(
                        color: color,
                        fontWeight: FontWeight.w800,
                        fontSize: 15,
                      ),
                    ),
                    // Expand to show raw SMS on tap
                    onTap: t.rawText != null
                        ? () => _showSmsDetail(context, t.rawText!)
                        : null,
                  ),
                );
              },
            ),
    );
  }

  void _showSmsDetail(BuildContext context, String rawText) {
    showModalBottomSheet(
      context: context,
      backgroundColor: AppTheme.surface,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (_) => Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'RAW SMS',
              style: TextStyle(
                  color: AppTheme.textSecondary,
                  fontSize: 11,
                  letterSpacing: 1.4),
            ),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: AppTheme.card,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(rawText,
                  style: const TextStyle(
                      color: AppTheme.textPrimary, fontSize: 13, height: 1.5)),
            ),
          ],
        ),
      ),
    );
  }
}
