import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../providers/transaction_provider.dart';
import '../theme/app_theme.dart';

/// Red flashing banner shown when daysOfSurvival < 7.
class CrashAlertBanner extends StatelessWidget {
  const CrashAlertBanner({super.key});

  @override
  Widget build(BuildContext context) {
    final flood = context.watch<TransactionProvider>();
    final crashDate = flood.forecast?.predictedCrashDate;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        color: AppTheme.danger.withOpacity(0.15),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppTheme.danger, width: 1.5),
      ),
      child: Row(
        children: [
          const Icon(Icons.warning_amber_rounded,
              color: AppTheme.danger, size: 28),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  '🚨 CRASH ALERT',
                  style: TextStyle(
                    color: AppTheme.danger,
                    fontWeight: FontWeight.w800,
                    fontSize: 13,
                    letterSpacing: 1.2,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  crashDate != null
                      ? 'Predicted zero balance: ${DateFormat('d MMM, yyyy').format(crashDate)}'
                      : 'Your balance is critically low! Reduce spending now.',
                  style: const TextStyle(
                      color: AppTheme.textSecondary, fontSize: 12.5),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
