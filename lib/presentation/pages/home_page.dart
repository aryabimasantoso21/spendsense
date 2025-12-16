import 'package:flutter/material.dart';
import '../../data/models/transaction_model.dart';
import '../../data/models/account_model.dart';
import '../../data/models/category_model.dart';
import '../../data/models/budget_model.dart';
import '../../data/services/local_storage_service.dart';
import '../../data/services/supabase_service.dart';
import '../../utils/constants.dart';
import '../../utils/formatters.dart';
import '../widgets/budget_card.dart';
import '../widgets/budget_card_item.dart';

import 'add_transaction_page.dart';
import 'add_account_page.dart';
import 'add_budget_page.dart';
import 'budget_detail_page.dart';
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
  List<Budget> _budgets = [];
  String _username = 'SpendSense';
  int _currentIndex = 0;
  final _budgetTitleController = TextEditingController();
  final _budgetAmountController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _initializeApp();
  }

  @override
  void dispose() {
    _budgetTitleController.dispose();
    _budgetAmountController.dispose();
    super.dispose();
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
      await _loadBudgets();

      // Fill in account names from accounts list
      _transactions = _transactions.map((t) {
        final account = _accounts.firstWhere(
          (a) => a.id == t.accountId,
          orElse: () => Account(
            id: 0,
            userId: '',
            name: 'Unknown',
            type: '',
            balance: 0,
            createdAt: DateTime.now(),
          ),
        );
        final destAccount = t.destinationAccountId != null
            ? _accounts.firstWhere(
                (a) => a.id == t.destinationAccountId,
                orElse: () => Account(
                  id: 0,
                  userId: '',
                  name: 'Unknown',
                  type: '',
                  balance: 0,
                  createdAt: DateTime.now(),
                ),
              )
            : null;

        return t.copyWith(
          accountName: account.name,
          destinationAccountName: destAccount?.name,
        );
      }).toList();

      await _localStorage.saveCategories(_categories);

      setState(() {});
    } catch (e) {
      _transactions = await _localStorage.getTransactions();
      _accounts = await _localStorage.getAccounts();
      _categories = await _localStorage.getCategories();

      // Fill in account names from accounts list
      _transactions = _transactions.map((t) {
        final account = _accounts.firstWhere(
          (a) => a.id == t.accountId,
          orElse: () => Account(
            id: 0,
            userId: '',
            name: 'Unknown',
            type: '',
            balance: 0,
            createdAt: DateTime.now(),
          ),
        );
        final destAccount = t.destinationAccountId != null
            ? _accounts.firstWhere(
                (a) => a.id == t.destinationAccountId,
                orElse: () => Account(
                  id: 0,
                  userId: '',
                  name: 'Unknown',
                  type: '',
                  balance: 0,
                  createdAt: DateTime.now(),
                ),
              )
            : null;

        return t.copyWith(
          accountName: account.name,
          destinationAccountName: destAccount?.name,
        );
      }).toList();

      if (_categories.isEmpty) {
        _categories = [...defaultExpenseCategories, ...defaultIncomeCategories];
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
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Mode offline: $e')));
      }
    }
  }

  Future<void> _loadBudgets() async {
    try {
      final userId = _supabase.currentUserId;
      if (userId == null) {
        print('DEBUG: User ID is null, skipping budget fetch');
        return;
      }

      print('DEBUG: Fetching budgets for user: $userId');
      final budgets = await _supabase.getBudgets();
      print('DEBUG: Budgets fetched: ${budgets.length} budgets');

      setState(() {
        _budgets = budgets;
      });
    } catch (e) {
      print('DEBUG: Error fetching budgets: $e');
    }
  }

  Future<void> _showAddBudgetDialog() async {
    final result = await Navigator.push<bool>(
      context,
      MaterialPageRoute(builder: (context) => const AddBudgetPage()),
    );

    if (result == true) {
      await _loadBudgets();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Budget added successfully!')),
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
        MaterialPageRoute(builder: (context) => const AddAccountPage()),
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

  double get _totalAccountBalance =>
      _accounts.fold(0.0, (sum, account) => sum + account.balance);

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
    } else {
      return 'Good Evening 🌆';
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: IndexedStack(
        index: _currentIndex,
        children: [
          _buildDashboard(),
          TransactionsPage(
            localStorage: _localStorage,
            onDataChanged: _loadData,
          ),
          StatisticsPage(localStorage: _localStorage, onDataChanged: _loadData),
          AccountsPage(
            accounts: _accounts,
            onDataChanged: _loadData,
            localStorage: _localStorage,
          ),
          SettingsPage(localStorage: _localStorage),
        ],
      ),
      floatingActionButton:
          _currentIndex !=
              4 // Show FAB on all tabs except Profile/Settings
          ? FloatingActionButton(
              onPressed: _onFabPressed,
              backgroundColor: AppColors.primary,
              child: const Icon(Icons.add, color: Colors.white),
            )
          : null,
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          color: isDarkMode ? const Color(0xFF1E1E1E) : Colors.white,
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
            BottomNavigationBarItem(
              icon: Icon(Icons.home_filled),
              label: 'Home',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.receipt_long),
              label: 'Transaction',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.pie_chart),
              label: 'Statistics',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.credit_card),
              label: 'Account',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.person_outline),
              label: 'Profile',
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDashboard() {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    final textColor = isDarkMode ? Colors.white : AppColors.text;
    final secondaryTextColor = isDarkMode
        ? Colors.white70
        : AppColors.textSecondary;
    final cardColor = isDarkMode ? const Color(0xFF1E1E1E) : Colors.white;

    return RefreshIndicator(
      onRefresh: _loadData,
      color: AppColors.primary,
      child: ListView(
        padding: EdgeInsets.zero,
        children: [
          // Header Section with gradient
          Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: isDarkMode
                    ? [const Color(0xFF00796B), const Color(0xFF004D40)]
                    : [AppColors.primaryLight, AppColors.primary],
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
              ),
              borderRadius: const BorderRadius.only(
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
                    padding: const EdgeInsets.symmetric(
                      horizontal: 24,
                      vertical: 16,
                    ),
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
                      color: cardColor,
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
                        Text(
                          'Total Balance',
                          style: TextStyle(
                            color: secondaryTextColor,
                            fontSize: 14,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          CurrencyFormatter.formatCurrency(
                            _totalAccountBalance,
                          ),
                          style: TextStyle(
                            fontSize: 32,
                            fontWeight: FontWeight.bold,
                            color: _totalAccountBalance >= 0
                                ? textColor
                                : AppColors.expense,
                          ),
                        ),
                        const SizedBox(height: 20),
                        Row(
                          children: [
                            Expanded(
                              child: _buildBalanceItem(
                                icon: Icons.arrow_downward,
                                iconBg: AppColors.primary.withValues(
                                  alpha: 0.1,
                                ),
                                iconColor: AppColors.primary,
                                label: 'Income',
                                amount: _totalIncome,
                              ),
                            ),
                            Container(
                              width: 1,
                              height: 50,
                              color: isDarkMode
                                  ? Colors.white24
                                  : AppColors.border,
                            ),
                            Expanded(
                              child: _buildBalanceItem(
                                icon: Icons.arrow_upward,
                                iconBg: AppColors.expense.withValues(
                                  alpha: 0.1,
                                ),
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

          // Budget Section
          _buildBudgetSection(),

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
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    final textColor = isDarkMode ? Colors.white : AppColors.text;
    final secondaryTextColor = isDarkMode
        ? Colors.white70
        : AppColors.textSecondary;

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
              style: TextStyle(color: secondaryTextColor, fontSize: 13),
            ),
          ],
        ),
        const SizedBox(height: 8),
        Text(
          CurrencyFormatter.formatCurrency(amount),
          style: TextStyle(
            fontWeight: FontWeight.w600,
            fontSize: 15,
            color: textColor,
          ),
        ),
      ],
    );
  }

  Widget _buildAccountsSection() {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    final textColor = isDarkMode ? Colors.white : AppColors.text;

    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 24, 24, 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'My Accounts',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                  color: textColor,
                ),
              ),
              GestureDetector(
                onTap: () => setState(() => _currentIndex = 3),
                child: const Text(
                  'See All',
                  style: TextStyle(fontSize: 14, color: AppColors.primary),
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
              itemBuilder: (context, index) =>
                  _buildModernAccountCard(_accounts[index], index),
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

  Widget _buildBudgetSection() {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    final textColor = isDarkMode ? Colors.white : AppColors.text;
    final cardColor = isDarkMode ? const Color(0xFF1E1E1E) : Colors.white;

    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 24, 24, 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Budget',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                  color: textColor,
                ),
              ),
              if (_budgets.isNotEmpty)
                GestureDetector(
                  onTap: () {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Manage all budgets coming soon!'),
                      ),
                    );
                  },
                  child: Text(
                    'Manage(${_budgets.length})',
                    style: const TextStyle(
                      fontSize: 14,
                      color: AppColors.primary,
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 16),

          // Budget Cards - Vertical Layout
          if (_budgets.isEmpty)
            // Add Budget Button (when no budgets)
            GestureDetector(
              onTap: _showAddBudgetDialog,
              child: Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      AppColors.primary.withOpacity(0.1),
                      AppColors.primary.withOpacity(0.05),
                    ],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(AppBorderRadius.lg),
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.primary.withOpacity(0.1),
                      blurRadius: 10,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Container(
                      width: 48,
                      height: 48,
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [
                            AppColors.primary,
                            AppColors.primary.withOpacity(0.8),
                          ],
                        ),
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            color: AppColors.primary.withOpacity(0.3),
                            blurRadius: 8,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: const Icon(
                        Icons.add_rounded,
                        color: Colors.white,
                        size: 28,
                      ),
                    ),
                    const SizedBox(width: 16),
                    Text(
                      'Add Budget',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: AppColors.primary,
                      ),
                    ),
                  ],
                ),
              ),
            )
          else
            // Budget Cards List (vertical)
            Column(
              children: [
                ..._budgets.map((budget) {
                  // Calculate spent for this budget
                  final spent = _transactions
                      .where((t) {
                        if (t.type != 'expense') return false;
                        if (t.date.isBefore(budget.startDate) ||
                            t.date.isAfter(budget.endDate))
                          return false;
                        if (budget.categoryId != null &&
                            t.categoryId != budget.categoryId)
                          return false;
                        return true;
                      })
                      .fold<double>(0, (sum, t) => sum + t.amount);

                  return Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: SizedBox(
                      width: double.infinity,
                      child: BudgetCardItem(
                        budget: budget,
                        spent: spent,
                        onTap: () async {
                          final result = await Navigator.push<bool>(
                            context,
                            MaterialPageRoute(
                              builder: (context) =>
                                  BudgetDetailPage(budget: budget),
                            ),
                          );

                          if (result == true) {
                            await _loadBudgets();
                          }
                        },
                      ),
                    ),
                  );
                }).toList(),

                // Add Budget Button (at the bottom)
                const SizedBox(height: 8),
                GestureDetector(
                  onTap: _showAddBudgetDialog,
                  child: Container(
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          AppColors.primary.withOpacity(0.1),
                          AppColors.primary.withOpacity(0.05),
                        ],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      borderRadius: BorderRadius.circular(AppBorderRadius.lg),
                      boxShadow: [
                        BoxShadow(
                          color: AppColors.primary.withOpacity(0.1),
                          blurRadius: 8,
                          offset: const Offset(0, 3),
                        ),
                      ],
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Container(
                          width: 40,
                          height: 40,
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              colors: [
                                AppColors.primary,
                                AppColors.primary.withOpacity(0.8),
                              ],
                            ),
                            shape: BoxShape.circle,
                            boxShadow: [
                              BoxShadow(
                                color: AppColors.primary.withOpacity(0.3),
                                blurRadius: 6,
                                offset: const Offset(0, 2),
                              ),
                            ],
                          ),
                          child: const Icon(
                            Icons.add_rounded,
                            color: Colors.white,
                            size: 24,
                          ),
                        ),
                        const SizedBox(width: 14),
                        Text(
                          'Add Budget',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: AppColors.primary,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
        ],
      ),
    );
  }

  Widget _buildRecentTransactionsSection() {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    final textColor = isDarkMode ? Colors.white : AppColors.text;
    final secondaryTextColor = isDarkMode
        ? Colors.white70
        : AppColors.textSecondary;

    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 24, 24, 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Recent Transactions',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                  color: textColor,
                ),
              ),
              GestureDetector(
                onTap: () => setState(() => _currentIndex = 1),
                child: const Text(
                  'See All',
                  style: TextStyle(fontSize: 14, color: AppColors.primary),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          _transactions.isEmpty
              ? Container(
                  padding: const EdgeInsets.all(32),
                  child: Center(
                    child: Column(
                      children: [
                        const Icon(
                          Icons.receipt_long,
                          size: 48,
                          color: AppColors.textTertiary,
                        ),
                        const SizedBox(height: 12),
                        Text(
                          'No transactions yet',
                          style: TextStyle(color: secondaryTextColor),
                        ),
                      ],
                    ),
                  ),
                )
              : ListView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: _recentTransactions.length,
                  itemBuilder: (context, index) =>
                      _buildModernTransactionCard(_recentTransactions[index]),
                ),
        ],
      ),
    );
  }

  Widget _buildModernTransactionCard(Transaction transaction) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    final textColor = isDarkMode ? Colors.white : AppColors.text;
    final secondaryTextColor = isDarkMode
        ? Colors.white70
        : AppColors.textSecondary;
    final cardColor = isDarkMode ? const Color(0xFF1E1E1E) : Colors.white;

    final category = _categories.firstWhere(
      (cat) => cat.id == transaction.categoryId,
      orElse: () => Category(id: 0, name: 'Other', type: transaction.type),
    );
    final isExpense = transaction.type == 'expense';
    final isIncome = transaction.type == 'income';
    final isTransfer = transaction.type == 'transfer';

    return GestureDetector(
      onTap: () async {
        await Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => AddTransactionPage(
              localStorage: _localStorage,
              transaction: transaction,
            ),
          ),
        );
        _loadData();
      },
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: cardColor,
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
                color: isTransfer
                    ? AppColors.cardBlue.withValues(alpha: 0.1)
                    : (isExpense ? AppColors.expense : AppColors.primary)
                          .withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(
                isTransfer
                    ? Icons.swap_horiz
                    : (isExpense ? Icons.arrow_upward : Icons.arrow_downward),
                color: isTransfer
                    ? AppColors.cardBlue
                    : (isExpense ? AppColors.expense : AppColors.primary),
                size: 20,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (isTransfer)
                    // Transfer: show Transfer label
                    Text(
                      'Transfer',
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w500,
                        color: textColor,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    )
                  else if (transaction.description.isNotEmpty)
                    // Expense/Income with description: show description
                    Text(
                      transaction.description,
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w500,
                        color: textColor,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    )
                  else
                    // Expense/Income without description: show category
                    Text(
                      category.name,
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w500,
                        color: textColor,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  const SizedBox(height: 4),
                  Text(
                    isTransfer
                        ? '${transaction.accountName} → ${transaction.destinationAccountName}'
                        : transaction.accountName ?? '',
                    style: TextStyle(fontSize: 12, color: secondaryTextColor),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
            Text(
              isTransfer
                  ? CurrencyFormatter.formatCurrency(transaction.amount)
                  : '${isExpense ? '-' : '+'}${CurrencyFormatter.formatCurrency(transaction.amount)}',
              style: TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w600,
                color: isTransfer
                    ? AppColors.cardBlue
                    : (isExpense ? AppColors.expense : AppColors.primary),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
