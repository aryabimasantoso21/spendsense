import 'package:flutter/material.dart';
import '../../utils/constants.dart';
import '../../utils/formatters.dart';

class BudgetCard extends StatelessWidget {
  final String title;
  final double amount;
  final double spent;
  final String period; // 'monthly', 'weekly', 'daily'
  final VoidCallback? onManage;
  final VoidCallback? onAddBudget;

  const BudgetCard({
    super.key,
    required this.title,
    required this.amount,
    required this.spent,
    this.period = 'monthly',
    this.onManage,
    this.onAddBudget,
  });

  @override
  Widget build(BuildContext context) {
    final remaining = amount - spent;
    final progress = amount > 0 ? (spent / amount).clamp(0.0, 1.0) : 0.0;
    final isOverBudget = spent > amount;

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: AppPadding.lg),
      padding: const EdgeInsets.all(AppPadding.lg),
      decoration: BoxDecoration(
        color: AppColors.surface,
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
        children: [
          // Header
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'BUDGET',
                style: AppTextStyles.overline.copyWith(
                  color: AppColors.textTertiary,
                  fontSize: 12,
                  letterSpacing: 1.5,
                ),
              ),
              if (onManage != null)
                GestureDetector(
                  onTap: onManage,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: AppColors.accent,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      'Manage(1)',
                      style: AppTextStyles.caption.copyWith(
                        color: AppColors.primary,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: AppPadding.md),

          // Period Label
          Text(
            _getPeriodLabel(),
            style: AppTextStyles.overline.copyWith(
              fontSize: 11,
              color: AppColors.textSecondary,
            ),
          ),
          const SizedBox(height: AppPadding.sm),

          // Budget Info
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                title,
                style: AppTextStyles.subtitle.copyWith(
                  fontWeight: FontWeight.w600,
                ),
              ),
              Text(
                'Remain ${CurrencyFormatter.formatCurrency(remaining.abs())}',
                style: AppTextStyles.body.copyWith(
                  color: isOverBudget
                      ? AppColors.expense
                      : AppColors.textSecondary,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
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
          const SizedBox(height: AppPadding.lg),

          // Add Budget Button
          if (onAddBudget != null)
            GestureDetector(
              onTap: onAddBudget,
              child: Row(
                children: [
                  Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: AppColors.border,
                        width: 2,
                        style: BorderStyle.solid,
                      ),
                    ),
                    child: const Icon(
                      Icons.add,
                      color: AppColors.textSecondary,
                      size: 24,
                    ),
                  ),
                  const SizedBox(width: AppPadding.md),
                  Text(
                    'Add Budget',
                    style: AppTextStyles.body.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }

  String _getPeriodLabel() {
    switch (period.toLowerCase()) {
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
}
