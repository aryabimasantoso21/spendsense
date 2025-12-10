import 'package:flutter/material.dart';
import '../../data/models/account_model.dart';
import '../../data/services/supabase_service.dart';
import '../../data/services/local_storage_service.dart';
import '../../utils/constants.dart';
import '../../utils/formatters.dart';
import 'edit_account_balance_page.dart';

class AccountsPage extends StatefulWidget {
  final List<Account> accounts;
  final VoidCallback onDataChanged;
  final LocalStorageService localStorage;

  const AccountsPage({
    super.key,
    required this.accounts,
    required this.onDataChanged,
    required this.localStorage,
  });

  @override
  State<AccountsPage> createState() => _AccountsPageState();
}

class _AccountsPageState extends State<AccountsPage> {
  final SupabaseService _supabaseService = SupabaseService.instance;

  double get _totalBalance => widget.accounts.fold(0, (sum, account) => sum + account.balance);

  Future<void> _deleteAccount(int id) async {
    try {
      await _supabaseService.deleteAccount(id);
      widget.onDataChanged();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Akun berhasil dihapus'), duration: Duration(seconds: 2)),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Gagal menghapus akun: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    final textColor = isDarkMode ? Colors.white : AppColors.text;
    final secondaryTextColor = isDarkMode ? Colors.white70 : AppColors.textSecondary;

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        automaticallyImplyLeading: false,
        backgroundColor: Theme.of(context).scaffoldBackgroundColor,
        elevation: 0,
        centerTitle: true,
        title: Text(
          'Account',
          style: TextStyle(
            color: textColor,
            fontSize: 18,
            fontWeight: FontWeight.w600,
          ),
        ),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 16),
            child: Image.asset('img/logo.png', height: 32),
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(24, 16, 24, 60),
        children: [
          // Available Balance Section
          Text(
            'Available Balance',
            style: TextStyle(
              fontSize: 14,
              color: secondaryTextColor,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            CurrencyFormatter.formatCurrency(_totalBalance),
            style: TextStyle(
              fontSize: 28,
              fontWeight: FontWeight.bold,
              color: textColor,
            ),
          ),
          const SizedBox(height: 24),

          // Select an Account Header
          Text(
            'Select an Account',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: textColor,
            ),
          ),
          const SizedBox(height: 16),

          // Account Cards
          if (widget.accounts.isEmpty)
            Container(
              padding: const EdgeInsets.all(40),
              child: Column(
                children: [
                  const Icon(Icons.credit_card_outlined, size: 64, color: AppColors.textTertiary),
                  const SizedBox(height: 16),
                  Text(
                    'Belum ada akun',
                    style: TextStyle(color: secondaryTextColor),
                  ),
                ],
              ),
            )
          else
            ...widget.accounts.asMap().entries.map((entry) {
              final index = entry.key;
              final account = entry.value;
              return _buildAccountCard(account, index);
            }),
        ],
      ),
    );
  }

  Widget _buildAccountCard(Account account, int index) {
    // Different gradient colors for each card
    final gradients = [
      [AppColors.cardBlue, const Color(0xFF6B8CEF)],
      [AppColors.cardPurple, const Color(0xFFB38FDF)],
      [AppColors.cardOrange, AppColors.expense],
      [AppColors.cardYellow, const Color(0xFFF5D76E)],
    ];
    final colors = gradients[index % gradients.length];

    return Dismissible(
      key: Key(account.id.toString()),
      direction: DismissDirection.endToStart,
      onDismissed: (_) => _deleteAccount(account.id),
      background: Container(
        margin: const EdgeInsets.only(bottom: 16),
        decoration: BoxDecoration(
          color: AppColors.expense,
          borderRadius: BorderRadius.circular(16),
        ),
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 24),
        child: const Icon(Icons.delete, color: Colors.white),
      ),
      child: GestureDetector(
        onTap: () async {
          final result = await Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => EditAccountBalancePage(
                account: account,
                localStorage: widget.localStorage,
              ),
            ),
          );
          if (result == true) {
            widget.onDataChanged();
          }
        },
        child: Container(
          margin: const EdgeInsets.only(bottom: 16),
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: colors,
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(16),
          ),
          child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  account.name,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                Icon(
                  _getAccountIcon(account.type),
                  color: Colors.white70,
                  size: 28,
                ),
              ],
            ),
            const SizedBox(height: 24),
            Text(
              '**** **** **** ${(account.id % 10000).toString().padLeft(4, '0')}',
              style: const TextStyle(
                color: Colors.white70,
                fontSize: 14,
                letterSpacing: 2,
              ),
            ),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Balance',
                      style: TextStyle(color: Colors.white60, fontSize: 11),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      CurrencyFormatter.formatCurrency(account.balance),
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    const Text(
                      'Type',
                      style: TextStyle(color: Colors.white60, fontSize: 11),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      _getAccountTypeName(account.type),
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 14,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ],
        ),
        ),
      ),
    );
  }

  IconData _getAccountIcon(String type) {
    switch (type) {
      case 'bank':
        return Icons.account_balance;
      case 'ewallet':
        return Icons.phone_android;
      case 'cash':
        return Icons.money;
      case 'savings':
        return Icons.savings;
      default:
        return Icons.credit_card;
    }
  }

  String _getAccountTypeName(String type) {
    return accountTypeNames[type] ?? 'Akun';
  }
}
