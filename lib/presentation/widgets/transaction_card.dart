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
    final isIncome = transaction.type == 'income';
    final isTransfer = transaction.type == 'transfer';
    final categoryName = _getCategoryName();
    final categoryIcon = _getCategoryIcon();

    return Container(
      margin: const EdgeInsets.only(bottom: AppPadding.md),
      padding: const EdgeInsets.all(AppPadding.md),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppBorderRadius.lg),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          // Icon
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: isTransfer 
                  ? AppColors.cardBlue.withOpacity(0.1)
                  : (isExpense ? AppColors.expense : AppColors.income).withOpacity(0.1),
              borderRadius: BorderRadius.circular(AppBorderRadius.sm),
            ),
            child: Center(
              child: isTransfer
                  ? const Icon(Icons.swap_horiz, color: AppColors.cardBlue, size: 28)
                  : Text(
                      categoryIcon,
                      style: const TextStyle(fontSize: 24),
                    ),
            ),
          ),
          const SizedBox(width: AppPadding.md),
          // Category and Details
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  isTransfer 
                      ? 'Transfer'
                      : categoryName,
                  style: AppTextStyles.subtitle.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: AppPadding.xs),
                Text(
                  DateFormatter.formatDate(transaction.date),
                  style: AppTextStyles.caption.copyWith(
                    color: AppColors.textSecondary,
                  ),
                ),
                if (isTransfer) ...[
                  const SizedBox(height: AppPadding.xs),
                  Row(
                    children: [
                      Text(
                        transaction.accountName ?? '',
                        style: AppTextStyles.caption.copyWith(
                          color: AppColors.expense,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      const Padding(
                        padding: EdgeInsets.symmetric(horizontal: 4),
                        child: Icon(
                          Icons.arrow_forward,
                          size: 12,
                          color: AppColors.textSecondary,
                        ),
                      ),
                      Text(
                        transaction.destinationAccountName ?? '',
                        style: AppTextStyles.caption.copyWith(
                          color: AppColors.income,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ] else ...[
                  const SizedBox(height: AppPadding.xs),
                  Text(
                    transaction.accountName ?? '',
                    style: AppTextStyles.caption.copyWith(
                      color: AppColors.textTertiary,
                    ),
                  ),
                ],
                if (transaction.description?.isNotEmpty ?? false) ...[
                  const SizedBox(height: AppPadding.xs),
                  Text(
                    transaction.description!,
                    style: AppTextStyles.caption.copyWith(
                      color: AppColors.textTertiary,
                      fontStyle: FontStyle.italic,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ],
            ),
          ),
          // Amount
          Text(
            isTransfer
                ? CurrencyFormatter.formatCurrency(transaction.amount)
                : '${isExpense ? '-' : '+'}${CurrencyFormatter.formatCurrency(transaction.amount)}',
            style: AppTextStyles.subtitle.copyWith(
              color: isTransfer 
                  ? AppColors.cardBlue
                  : (isExpense ? AppColors.expense : AppColors.income),
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }
}
