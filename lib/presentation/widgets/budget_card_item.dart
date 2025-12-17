import 'package:flutter/material.dart';
import '../../data/models/budget_model.dart';
import '../../utils/constants.dart';
import '../../utils/formatters.dart';

class BudgetCardItem extends StatelessWidget {
  final Budget budget;
  final double spent;
  final VoidCallback? onTap;

  const BudgetCardItem({
    super.key,
    required this.budget,
    required this.spent,
    this.onTap,
  });

  String _getPeriodLabel() {
    switch (budget.period.toLowerCase()) {
      case 'monthly':
        return 'MONTHLY';
      case 'weekly':
        return 'WEEKLY';
      case 'daily':
        return 'DAILY';
      default:
        return 'MONTHLY';
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    final cardColor = isDarkMode ? const Color(0xFF1E1E1E) : Colors.white;

    final remaining = budget.amount - spent;
    final exceeded = spent - budget.amount;
    final progress = budget.amount > 0
        ? (spent / budget.amount).clamp(0.0, 1.0)
        : 0.0;
    final isOverBudget = spent > budget.amount;

    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(AppPadding.lg),
        decoration: BoxDecoration(
          color: cardColor,
          borderRadius: BorderRadius.circular(AppBorderRadius.lg),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.05),
              blurRadius: 10,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            // Period Label and Warning
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  _getPeriodLabel(),
                  style: AppTextStyles.overline.copyWith(
                    fontSize: 11,
                    color: AppColors.textSecondary,
                  ),
                ),
                if (isOverBudget)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: AppColors.expense.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.warning_rounded,
                          size: 14,
                          color: AppColors.expense,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          'Over Budget!}',
                          style: TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.w600,
                            color: AppColors.expense,
                          ),
                        ),
                      ],
                    ),
                  ),
              ],
            ),
            const SizedBox(height: AppPadding.sm),

            // Budget Title
            Text(
              budget.title,
              style: AppTextStyles.subtitle.copyWith(
                fontWeight: FontWeight.w600,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: AppPadding.sm),

            // Remaining amount
            Text(
              isOverBudget
                  ? 'Over ${CurrencyFormatter.formatCurrency(exceeded.abs())}'
                  : 'Remain ${CurrencyFormatter.formatCurrency(remaining)}',
              style: AppTextStyles.body.copyWith(
                color: isOverBudget
                    ? AppColors.expense
                    : AppColors.textSecondary,
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(height: AppPadding.md),

            // Progress Bar
            Container(
              height: 8,
              decoration: BoxDecoration(
                color: AppColors.surfaceVariant,
                borderRadius: BorderRadius.circular(4),
              ),
              child: FractionallySizedBox(
                alignment: Alignment.centerLeft,
                widthFactor: progress,
                child: Container(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: isOverBudget
                          ? [AppColors.expense, const Color(0xFFE57373)]
                          : [AppColors.primary, AppColors.accentDark],
                      begin: Alignment.centerLeft,
                      end: Alignment.centerRight,
                    ),
                    borderRadius: BorderRadius.circular(4),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
