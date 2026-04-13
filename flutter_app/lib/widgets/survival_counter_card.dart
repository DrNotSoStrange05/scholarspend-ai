import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../providers/transaction_provider.dart';
import '../theme/app_theme.dart';

/// The hero widget — shows "X Days of Survival" with animated color shifts.
class SurvivalCounterCard extends StatelessWidget {
  const SurvivalCounterCard({super.key});

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<TransactionProvider>();
    final days = provider.daysOfSurvival;
    final status = provider.survivalStatus;
    final crashDate = provider.forecast?.predictedCrashDate;

    final Color statusColor = switch (status) {
      'safe'    => AppTheme.success,
      'warning' => AppTheme.warning,
      _         => AppTheme.danger,
    };

    final String emoji = switch (status) {
      'safe'    => '💚',
      'warning' => '⚠️',
      _         => '🚨',
    };

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 28),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            statusColor.withOpacity(0.18),
            AppTheme.card,
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: statusColor.withOpacity(0.4), width: 1.5),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '$emoji SURVIVAL COUNTER',
            style: TextStyle(
              color: statusColor,
              fontSize: 11,
              fontWeight: FontWeight.w700,
              letterSpacing: 1.6,
            ),
          ),
          const SizedBox(height: 8),
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                days.toStringAsFixed(0),
                style: TextStyle(
                  fontSize: 72,
                  fontWeight: FontWeight.w900,
                  color: statusColor,
                  height: 1,
                ),
              ),
              const Padding(
                padding: EdgeInsets.only(bottom: 10, left: 6),
                child: Text(
                  'days',
                  style: TextStyle(
                      color: AppTheme.textSecondary,
                      fontSize: 20,
                      fontWeight: FontWeight.w500),
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          if (crashDate != null)
            Text(
              'Balance hits ₹0 around ${DateFormat('d MMM yyyy').format(crashDate)}',
              style: const TextStyle(color: AppTheme.textSecondary, fontSize: 13),
            ),
        ],
      ),
    );
  }
}
