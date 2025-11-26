import 'package:flutter/material.dart';
import '../../data/models/account_model.dart';
import '../../utils/constants.dart';
import '../../utils/formatters.dart';

class AccountCard extends StatelessWidget {
  final Account account;

  const AccountCard({
    super.key,
    required this.account,
  });

  String _getAccountIcon() {
    return accountTypeIcons[account.type] ?? accountTypeIcons['other']!;
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 160,
      padding: const EdgeInsets.all(AppPadding.md),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [AppColors.primary, AppColors.primaryDark],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(AppBorderRadius.lg),
        boxShadow: [
          BoxShadow(
            color: AppColors.primary.withOpacity(0.3),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          // Icon
          Text(
            _getAccountIcon(),
            style: const TextStyle(fontSize: 28),
          ),
          // Account Name and Balance
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                account.name,
                style: AppTextStyles.body.copyWith(
                  color: Colors.white70,
                  fontWeight: FontWeight.w500,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: AppPadding.xs),
              Text(
                CurrencyFormatter.formatCurrency(account.balance),
                style: AppTextStyles.subtitle.copyWith(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ],
      ),
    );
  }
}
