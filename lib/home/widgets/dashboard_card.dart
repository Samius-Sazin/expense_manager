import 'package:flutter/material.dart';

class DashboardCard extends StatelessWidget {
  final String currency;
  final double totalMonthlyExpense;
  final double todayExpense;

  const DashboardCard({
    super.key,
    required this.currency,
    required this.totalMonthlyExpense,
    required this.todayExpense,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    const gradientColors = [Color(0xFF4CAF50), Color(0xFF2196F3)];

    return Material(
      elevation: 2,
      shadowColor: colorScheme.shadow.withValues(alpha: 0.06),
      borderRadius: BorderRadius.circular(16),
      child: Container(
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            colors: gradientColors,
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(16),
        ),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Expanded(
                child: _StatItem(
                  value: '$currency ${totalMonthlyExpense.toStringAsFixed(2)}',
                  label: 'Monthly Expense',
                  textColor: Colors.white,
                  mutedColor: Colors.white.withValues(alpha: 0.85),
                ),
              ),
              Container(
                width: 1,
                height: 48,
                color: Colors.white.withValues(alpha: 0.35),
              ),
              Expanded(
                child: _StatItem(
                  value: '$currency ${todayExpense.toStringAsFixed(2)}',
                  label: 'Today\'s Expense',
                  textColor: Colors.white,
                  mutedColor: Colors.white.withValues(alpha: 0.85),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _StatItem extends StatelessWidget {
  final String value;
  final String label;
  final Color textColor;
  final Color mutedColor;

  const _StatItem({
    required this.value,
    required this.label,
    required this.textColor,
    required this.mutedColor,
  });

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Text(
            value,
            textAlign: TextAlign.center,
            style: textTheme.titleMedium?.copyWith(
              fontSize: 18,
              fontWeight: FontWeight.w800,
              color: textColor,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            label,
            textAlign: TextAlign.center,
            style: textTheme.bodySmall?.copyWith(
              color: mutedColor,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
}
