import 'package:flutter/material.dart';
import '../../data/models/transaction_model.dart';
import '../../data/models/account_model.dart';
import '../../data/models/category_model.dart';
import '../../data/services/local_storage_service.dart';
import '../../data/services/supabase_service.dart';
import '../../utils/constants.dart';
import '../../utils/formatters.dart';

import 'add_transaction_page.dart';
import 'add_account_page.dart';
import 'edit_account_balance_page.dart';
import 'transactions_page.dart';
import 'accounts_page.dart';
import 'statistics_page.dart';
import 'settings_page.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  final LocalStorageService _localStorage = LocalStorageService.instance;
  final SupabaseService _supabase = SupabaseService.instance;
  List<Transaction> _transactions = [];
  List<Account> _accounts = [];
  List<Category> _categories = [];
  String _username = 'SpendSense';
  int _currentIndex = 0;

  @override
  void initState() {
    super.initState();
    _initializeApp();
  }

  Future<void> _initializeApp() async {
    await _localStorage.init();
    await _loadData();
  }

  Future<void> _loadData() async {
    try {
      _transactions = await _supabase.getTransactions();
      _accounts = await _supabase.getAccounts();
      _categories = await _supabase.getCategories();
      _username = await _supabase.getUsername();

      await _localStorage.saveCategories(_categories);

      setState(() {});
    } catch (e) {
      _transactions = await _localStorage.getTransactions();
      _accounts = await _localStorage.getAccounts();
      _categories = await _localStorage.getCategories();

      if (_categories.isEmpty) {
        _categories = [
          ...defaultExpenseCategories,
          ...defaultIncomeCategories,
        ];
        await _localStorage.saveCategories(_categories);
      }

      if (_accounts.isEmpty) {
        final defaultAccount = Account(
          id: 1,
          userId: '',
          name: 'Tunai',
          type: 'Cash',
          balance: 0,
          createdAt: DateTime.now(),
        );
        await _localStorage.saveAccount(defaultAccount);
        _accounts = [defaultAccount];
      }

      setState(() {});
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Mode offline: $e')),
        );
      }
    }
  }

  // Navigate to add transaction or account page - used by central FAB
  Future<void> _onFabPressed() async {
    if (_currentIndex == 3) {
      // On Accounts tab, add new account
      final result = await Navigator.push<bool>(
        context,
        MaterialPageRoute(
          builder: (context) => const AddAccountPage(),
        ),
      );
      if (result == true) {
        await _loadData();
      }
    } else {
      // On other tabs, add new transaction
      final result = await Navigator.push<bool>(
        context,
        MaterialPageRoute(
          builder: (context) => AddTransactionPage(localStorage: _localStorage),
        ),
      );
      if (result == true) {
        await _loadData();
      }
    }
  }

  double get _totalIncome => _transactions
      .where((t) => t.type == 'income')
      .fold(0.0, (sum, t) => sum + t.amount);

  double get _totalExpense => _transactions
      .where((t) => t.type == 'expense')
      .fold(0.0, (sum, t) => sum + t.amount);

  double get _totalAccountBalance => _accounts.fold(0.0, (sum, account) => sum + account.balance);

  List<Transaction> get _recentTransactions {
    final sorted = List<Transaction>.from(_transactions)
      ..sort((a, b) => b.date.compareTo(a.date));
    return sorted.take(5).toList();
  }

  String get _getGreeting {
    final hour = DateTime.now().hour;
    if (hour > 5 && hour < 12) {
      return 'Good Morning 🌅';
    } else if (hour >= 12 && hour < 17) {
      return 'Good Afternoon ☀️';
    } else if (hour >= 17 && hour < 21) {
      return 'Good Evening 🌆';
    } else {
      return 'Good Night 🌙';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: IndexedStack(
        index: _currentIndex,
        children: [
          _buildDashboard(),
          TransactionsPage(localStorage: _localStorage, onDataChanged: _loadData),
          StatisticsPage(localStorage: _localStorage, onDataChanged: _loadData),
          AccountsPage(accounts: _accounts, onDataChanged: _loadData, localStorage: _localStorage),
          SettingsPage(localStorage: _localStorage),
        ],
      ),
      floatingActionButton: _currentIndex != 4 // Show FAB on all tabs except Profile/Settings
          ? FloatingActionButton(
              onPressed: _onFabPressed,
              backgroundColor: AppColors.primary,
              child: const Icon(Icons.add, color: Colors.white),
            )
          : null,
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.05),
              blurRadius: 10,
              offset: const Offset(0, -5),
            ),
          ],
        ),
        child: BottomNavigationBar(
          backgroundColor: Colors.transparent,
          elevation: 0,
          selectedItemColor: AppColors.primary,
          unselectedItemColor: AppColors.textTertiary,
          currentIndex: _currentIndex,
          type: BottomNavigationBarType.fixed,
          selectedFontSize: 12,
          unselectedFontSize: 12,
          onTap: (index) => setState(() => _currentIndex = index),
          items: const [
            BottomNavigationBarItem(icon: Icon(Icons.home_filled), label: 'Home'),
            BottomNavigationBarItem(icon: Icon(Icons.receipt_long), label: 'Transaction'),
            BottomNavigationBarItem(icon: Icon(Icons.pie_chart), label: 'Statistics'),
            BottomNavigationBarItem(icon: Icon(Icons.credit_card), label: 'Account'),
            BottomNavigationBarItem(icon: Icon(Icons.person_outline), label: 'Profile'),
          ],
        ),
      ),
    );
  }

  Widget _buildDashboard() {
    return RefreshIndicator(
      onRefresh: _loadData,
      color: AppColors.primary,
      child: ListView(
        padding: EdgeInsets.zero,
        children: [
          // Header Section with gradient
          Container(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                colors: [AppColors.primaryLight, AppColors.primary],
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
              ),
              borderRadius: BorderRadius.only(
                bottomLeft: Radius.circular(30),
                bottomRight: Radius.circular(30),
              ),
            ),
            child: SafeArea(
              bottom: false,
              child: Column(
                children: [
                  // App Bar
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              _getGreeting,
                              style: const TextStyle(
                                color: Colors.white70,
                                fontSize: 14,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              _username,
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 20,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                        Image.asset('img/logo.png', height: 40),
                      ],
                    ),
                  ),
                  
                  // Balance Card
                  Container(
                    margin: const EdgeInsets.fromLTRB(24, 8, 24, 24),
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(20),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.1),
                          blurRadius: 20,
                          offset: const Offset(0, 10),
                        ),
                      ],
                    ),
                    child: Column(
                      children: [
                        const Text(
                          'Total Balance',
                          style: TextStyle(
                            color: AppColors.textSecondary,
                            fontSize: 14,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          CurrencyFormatter.formatCurrency(_totalAccountBalance),
                          style: TextStyle(
                            fontSize: 32,
                            fontWeight: FontWeight.bold,
                            color: _totalAccountBalance >= 0 ? AppColors.text : AppColors.expense,
                          ),
                        ),
                        const SizedBox(height: 20),
                        Row(
                          children: [
                            Expanded(
                              child: _buildBalanceItem(
                                icon: Icons.arrow_downward,
                                iconBg: AppColors.primary.withValues(alpha: 0.1),
                                iconColor: AppColors.primary,
                                label: 'Income',
                                amount: _totalIncome,
                              ),
                            ),
                            Container(width: 1, height: 50, color: AppColors.border),
                            Expanded(
                              child: _buildBalanceItem(
                                icon: Icons.arrow_upward,
                                iconBg: AppColors.expense.withValues(alpha: 0.1),
                                iconColor: AppColors.expense,
                                label: 'Expense',
                                amount: _totalExpense,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),

          // Accounts Section
          if (_accounts.isNotEmpty) _buildAccountsSection(),

          // Recent Transactions Section
          _buildRecentTransactionsSection(),
          
          const SizedBox(height: 24),
        ],
      ),
    );
  }

  Widget _buildBalanceItem({
    required IconData icon,
    required Color iconBg,
    required Color iconColor,
    required String label,
    required double amount,
  }) {
    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                color: iconBg,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(icon, color: iconColor, size: 14),
            ),
            const SizedBox(width: 8),
            Text(
              label,
              style: const TextStyle(
                color: AppColors.textSecondary,
                fontSize: 13,
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        Text(
          CurrencyFormatter.formatCurrency(amount),
          style: const TextStyle(
            fontWeight: FontWeight.w600,
            fontSize: 15,
            color: AppColors.text,
          ),
        ),
      ],
    );
  }

  Widget _buildAccountsSection() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 24, 24, 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'My Accounts',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                  color: AppColors.text,
                ),
              ),
              GestureDetector(
                onTap: () => setState(() => _currentIndex = 3),
                child: const Text(
                  'See All',
                  style: TextStyle(
                    fontSize: 14,
                    color: AppColors.primary,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          SizedBox(
            height: 100,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              itemCount: _accounts.length,
              separatorBuilder: (_, __) => const SizedBox(width: 12),
              itemBuilder: (context, index) => _buildModernAccountCard(_accounts[index], index),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildModernAccountCard(Account account, int index) {
    final gradients = [
      [AppColors.cardBlue, const Color(0xFF6B8CEF)],
      [AppColors.cardPurple, const Color(0xFFB38FDF)],
      [AppColors.cardOrange, AppColors.expense],
    ];
    final colors = gradients[index % gradients.length];

    return GestureDetector(
      onTap: () async {
        final result = await Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => EditAccountBalancePage(
              account: account,
              localStorage: _localStorage,
            ),
          ),
        );
        if (result == true) {
          await _loadData();
        }
      },
      child: Container(
        width: 160,
        padding: const EdgeInsets.all(16),
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
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              account.name,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 14,
                fontWeight: FontWeight.w500,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
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
      ),
    );
  }

  Widget _buildRecentTransactionsSection() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 24, 24, 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Recent Transactions',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                  color: AppColors.text,
                ),
              ),
              GestureDetector(
                onTap: () => setState(() => _currentIndex = 1),
                child: const Text(
                  'See All',
                  style: TextStyle(
                    fontSize: 14,
                    color: AppColors.primary,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          _transactions.isEmpty
              ? Container(
                  padding: const EdgeInsets.all(32),
                  child: const Center(
                    child: Column(
                      children: [
                        Icon(Icons.receipt_long, size: 48, color: AppColors.textTertiary),
                        SizedBox(height: 12),
                        Text(
                          'No transactions yet',
                          style: TextStyle(color: AppColors.textSecondary),
                        ),
                      ],
                    ),
                  ),
                )
              : ListView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: _recentTransactions.length,
                  itemBuilder: (context, index) => _buildModernTransactionCard(_recentTransactions[index]),
                ),
        ],
      ),
    );
  }

  Widget _buildModernTransactionCard(Transaction transaction) {
    final category = _categories.firstWhere(
      (cat) => cat.id == transaction.categoryId,
      orElse: () => Category(id: 0, name: 'Other', type: transaction.type),
    );
    final isExpense = transaction.type == 'expense';

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: (isExpense ? AppColors.expense : AppColors.primary).withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(
              isExpense ? Icons.arrow_upward : Icons.arrow_downward,
              color: isExpense ? AppColors.expense : AppColors.primary,
              size: 20,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  category.name,
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w500,
                    color: AppColors.text,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  DateFormatter.formatDate(transaction.date),
                  style: const TextStyle(
                    fontSize: 12,
                    color: AppColors.textSecondary,
                  ),
                ),
              ],
            ),
          ),
          Text(
            '${isExpense ? '-' : '+'}${CurrencyFormatter.formatCurrency(transaction.amount)}',
            style: TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w600,
              color: isExpense ? AppColors.expense : AppColors.primary,
            ),
          ),
        ],
      ),
    );
  }
}
