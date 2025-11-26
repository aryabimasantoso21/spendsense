import 'package:flutter/material.dart';
import '../../data/models/account_model.dart';
import '../../data/services/local_storage_service.dart';
import '../../utils/constants.dart';
import '../../utils/formatters.dart';
import 'add_account_page.dart';

class AccountsPage extends StatefulWidget {
  final LocalStorageService localStorage;
  final VoidCallback onDataChanged;

  const AccountsPage({
    super.key,
    required this.localStorage,
    required this.onDataChanged,
  });

  @override
  State<AccountsPage> createState() => _AccountsPageState();
}

class _AccountsPageState extends State<AccountsPage> {
  List<Account> _accounts = [];

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    _accounts = await widget.localStorage.getAccounts();
    setState(() {});
  }

  double _getTotalBalance() {
    return _accounts.fold(0, (sum, account) => sum + account.balance);
  }

  Future<void> _deleteAccount(int id) async {
    await widget.localStorage.deleteAccount(id);
    await _loadData();
    widget.onDataChanged();
  }

  @override
  Widget build(BuildContext context) {
    final totalBalance = _getTotalBalance();

    return Scaffold(
      backgroundColor: AppColors.background,
      body: CustomScrollView(
        slivers: [
          // Header with Total Balance
          SliverAppBar(
            expandedHeight: 180,
            pinned: true,
            backgroundColor: AppColors.primary,
            elevation: 0,
            flexibleSpace: FlexibleSpaceBar(
              background: Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      AppColors.primary,
                      AppColors.primary.withValues(alpha: 0.85),
                    ],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                ),
                padding: const EdgeInsets.fromLTRB(
                  AppPadding.md,
                  AppPadding.xl,
                  AppPadding.md,
                  AppPadding.md,
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.end,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Saldo Tersedia',
                      style: AppTextStyles.body.copyWith(
                        color: Colors.white70,
                      ),
                    ),
                    const SizedBox(height: AppPadding.sm),
                    Text(
                      CurrencyFormatter.formatCurrency(totalBalance),
                      style: AppTextStyles.heading1.copyWith(
                        color: AppColors.surface,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),

          // Accounts List
          SliverPadding(
            padding: const EdgeInsets.all(AppPadding.md),
            sliver: _accounts.isEmpty
                ? SliverFillRemaining(
                    child: Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.account_balance_wallet,
                            size: 64,
                            color: AppColors.textSecondary,
                          ),
                          const SizedBox(height: AppPadding.md),
                          Text(
                            'Belum ada akun',
                            style: AppTextStyles.heading3.copyWith(
                              color: AppColors.textSecondary,
                            ),
                          ),
                          const SizedBox(height: AppPadding.sm),
                          Text(
                            'Buat akun pertama Anda sekarang',
                            style: AppTextStyles.body.copyWith(
                              color: AppColors.textSecondary,
                            ),
                          ),
                        ],
                      ),
                    ),
                  )
                : SliverList(
                    delegate: SliverChildBuilderDelegate(
                      (context, index) {
                        final account = _accounts[index];
                        return Padding(
                          padding: const EdgeInsets.only(bottom: AppPadding.md),
                          child: _buildAccountCard(account),
                        );
                      },
                      childCount: _accounts.length,
                    ),
                  ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () async {
          final result = await Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const AddAccountPage()),
          );
          if (result == true) {
            _loadData();
            widget.onDataChanged();
          }
        },
        backgroundColor: AppColors.primary,
        child: const Icon(Icons.add),
      ),
    );
  }

  Widget _buildAccountCard(Account account) {
    return GestureDetector(
      onLongPress: () => _showDeleteDialog(account.id),
      child: Container(
        padding: const EdgeInsets.all(AppPadding.md),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.05),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
          border: Border.all(
            color: AppColors.border,
            width: 1,
          ),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppColors.primary.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(
                _getAccountIcon(account.type),
                color: AppColors.primary,
                size: 28,
              ),
            ),
            const SizedBox(width: AppPadding.md),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    account.name,
                    style: AppTextStyles.heading3.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: AppPadding.xs),
                  Text(
                    _getAccountTypeName(account.type),
                    style: AppTextStyles.caption.copyWith(
                      color: AppColors.textSecondary,
                    ),
                  ),
                ],
              ),
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  CurrencyFormatter.formatCurrency(account.balance),
                  style: AppTextStyles.subtitle.copyWith(
                    color: account.balance >= 0
                        ? AppColors.income
                        : AppColors.expense,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  IconData _getAccountIcon(String type) {
    switch (type) {
      case 'cash':
        return Icons.payments;
      case 'bank':
        return Icons.account_balance;
      case 'card':
        return Icons.credit_card;
      case 'savings':
        return Icons.savings;
      default:
        return Icons.account_balance_wallet;
    }
  }

  String _getAccountTypeName(String type) {
    switch (type) {
      case 'cash':
        return 'Tunai';
      case 'bank':
        return 'Bank';
      case 'card':
        return 'Kartu Kredit';
      case 'savings':
        return 'Tabungan';
      default:
        return 'Akun';
    }
  }

  void _showDeleteDialog(int id) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Hapus Akun'),
        content: const Text('Anda yakin ingin menghapus akun ini?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Batal'),
          ),
          TextButton(
            onPressed: () {
              _deleteAccount(id);
              Navigator.pop(context);
            },
            child: Text(
              'Hapus',
              style: TextStyle(color: AppColors.expense),
            ),
          ),
        ],
      ),
    );
  }
}
