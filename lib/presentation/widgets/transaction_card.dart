import 'package:flutter/material.dart';
import '../../data/models/transaction_model.dart';
import '../../data/models/category_model.dart';
import '../../utils/constants.dart';
import '../../utils/formatters.dart';

class TransactionCard extends StatelessWidget {
  final Transaction transaction;
  final List<Category> categories;

  const TransactionCard({
    super.key,
    required this.transaction,
    required this.categories,
  });

  String _getCategoryName() {
    if (transaction.categoryName != null) {
      return transaction.categoryName!;
    }
    try {
      final category = categories
          .firstWhere((c) => c.id == transaction.categoryId);
      return category.name;
    } catch (e) {
      return 'Lainnya';
    }
  }

  String _getCategoryIcon() {
    final categoryName = _getCategoryName();
    return categoryIcons[categoryName] ?? '📌';
  }

  @override
  Widget build(BuildContext context) {
    final isExpense = transaction.type == 'expense';
    final categoryName = _getCategoryName();
    final categoryIcon = _getCategoryIcon();

    return Container(
      margin: const EdgeInsets.only(bottom: AppPadding.md),
      padding: const EdgeInsets.all(AppPadding.md),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppBorderRadius.lg),
        border: Border.all(
          color: AppColors.border,
          width: 1,
        ),
      ),
      child: Row(
        children: [
          // Icon
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: (isExpense ? AppColors.expense : AppColors.income)
                  .withOpacity(0.1),
              borderRadius: BorderRadius.circular(AppBorderRadius.sm),
            ),
            child: Center(
              child: Text(
                categoryIcon,
                style: const TextStyle(fontSize: 24),
              ),
            ),
          ),
          const SizedBox(width: AppPadding.md),
          // Category and Date
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  categoryName,
                  style: AppTextStyles.subtitle,
                ),
                const SizedBox(height: AppPadding.xs),
                Text(
                  DateFormatter.formatDate(transaction.date),
                  style: AppTextStyles.caption,
                ),
              ],
            ),
          ),
          // Amount
          Text(
            '${isExpense ? '-' : '+'}${CurrencyFormatter.formatCurrency(transaction.amount)}',
            style: AppTextStyles.subtitle.copyWith(
              color: isExpense ? AppColors.expense : AppColors.income,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }
}
