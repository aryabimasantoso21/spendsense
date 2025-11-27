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
    if (mounted) setState(() {});
  }

  double get _totalBalance => _accounts.fold(0, (sum, account) => sum + account.balance);

  Future<void> _deleteAccount(int id) async {
    await widget.localStorage.deleteAccount(id);
    await _loadData();
    widget.onDataChanged();
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Akun berhasil dihapus'), duration: Duration(seconds: 2)),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.background,
        elevation: 0,
        centerTitle: true,
        title: const Text(
          'Account',
          style: TextStyle(
            color: AppColors.text,
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
        padding: const EdgeInsets.symmetric(horizontal: 24),
        children: [
          const SizedBox(height: 16),
          // Available Balance Section
          const Text(
            'Available Balance',
            style: TextStyle(
              fontSize: 14,
              color: AppColors.textSecondary,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            CurrencyFormatter.formatCurrency(_totalBalance),
            style: const TextStyle(
              fontSize: 28,
              fontWeight: FontWeight.bold,
              color: AppColors.text,
            ),
          ),
          const SizedBox(height: 24),

          // Select an Account Header
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Select an Account',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: AppColors.text,
                ),
              ),
              GestureDetector(
                onTap: () async {
                  final result = await Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const AddAccountPage()),
                  );
                  if (result == true) {
                    _loadData();
                    widget.onDataChanged();
                  }
                },
                child: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: AppColors.surfaceVariant,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(Icons.add, size: 20, color: AppColors.text),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),

          // Account Cards
          if (_accounts.isEmpty)
            Container(
              padding: const EdgeInsets.all(40),
              child: const Column(
                children: [
                  Icon(Icons.credit_card_outlined, size: 64, color: AppColors.textTertiary),
                  SizedBox(height: 16),
                  Text(
                    'Belum ada akun',
                    style: TextStyle(color: AppColors.textSecondary),
                  ),
                ],
              ),
            )
          else
            ..._accounts.asMap().entries.map((entry) {
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
