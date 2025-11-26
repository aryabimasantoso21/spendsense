import 'package:flutter/material.dart';
import '../../data/models/transaction_model.dart';
import '../../data/models/account_model.dart';
import '../../data/models/category_model.dart';
import '../../data/services/local_storage_service.dart';
import '../../utils/constants.dart';
import '../../utils/formatters.dart';
import '../widgets/transaction_card.dart';
import '../widgets/account_card.dart';
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
  List<Transaction> _transactions = [];
  List<Account> _accounts = [];
  List<Category> _categories = [];
  int _currentIndex = 0;

  @override
  void initState() {
    super.initState();
    _initializeApp();
  }

  Future<void> _initializeApp() async {
    await _localStorage.init();
    _loadData();
  }

  Future<void> _loadData() async {
    _transactions = await _localStorage.getTransactions();
    _accounts = await _localStorage.getAccounts();
    _categories = await _localStorage.getCategories();

    // Initialize default categories if not exist
    if (_categories.isEmpty) {
      _categories = [
        ...defaultExpenseCategories,
        ...defaultIncomeCategories,
      ];
      await _localStorage.saveCategories(_categories);
    }

    // Initialize default account if not exist
    if (_accounts.isEmpty) {
      final defaultAccount = Account(
        id: 1,
        name: 'Tunai',
        type: 'cash',
        balance: 0,
        createdAt: DateTime.now(),
      );
      await _localStorage.saveAccount(defaultAccount);
      _accounts = [defaultAccount];
    }

    setState(() {});
  }

  double _calculateTotalIncome() {
    return _transactions
        .where((t) => t.type == 'income')
        .fold(0.0, (sum, t) => sum + t.amount);
  }

  double _calculateTotalExpense() {
    return _transactions
        .where((t) => t.type == 'expense')
        .fold(0.0, (sum, t) => sum + t.amount);
  }

  double _calculateNetBalance() {
    return _calculateTotalIncome() - _calculateTotalExpense();
  }

  List<Transaction> _getRecentTransactions({int limit = 5}) {
    final sorted = List<Transaction>.from(_transactions);
    sorted.sort((a, b) => b.date.compareTo(a.date));
    return sorted.take(limit).toList();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: IndexedStack(
        index: _currentIndex,
        children: [
          _buildDashboard(),
          TransactionsPage(
            localStorage: _localStorage,
            onDataChanged: _loadData,
          ),
          StatisticsPage(
            localStorage: _localStorage,
          ),
          AccountsPage(
            localStorage: _localStorage,
            onDataChanged: _loadData,
          ),
          SettingsPage(
            localStorage: _localStorage,
          ),
        ],
      ),
      bottomNavigationBar: BottomNavigationBar(
        backgroundColor: AppColors.surface,
        selectedItemColor: AppColors.primary,
        unselectedItemColor: AppColors.textSecondary,
        currentIndex: _currentIndex,
        type: BottomNavigationBarType.fixed,
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.home),
            label: 'Beranda',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.receipt),
            label: 'Transaksi',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.bar_chart),
            label: 'Statistik',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.account_balance_wallet),
            label: 'Akun',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.settings),
            label: 'Pengaturan',
          ),
        ],
        onTap: (index) {
          setState(() {
            _currentIndex = index;
          });
        },
      ),
    );
  }

  Widget _buildDashboard() {
    return RefreshIndicator(
      onRefresh: _loadData,
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        child: Column(
          children: [
            // Header with teal background
            Container(
              width: double.infinity,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [AppColors.primary, AppColors.primary.withValues(alpha: 0.8)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: const BorderRadius.only(
                  bottomLeft: Radius.circular(24),
                  bottomRight: Radius.circular(24),
                ),
              ),
              padding: const EdgeInsets.fromLTRB(
                AppPadding.md,
                AppPadding.xl,
                AppPadding.md,
                AppPadding.xl,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  SizedBox(
                    height: 35,
                    child: Image.asset(
                      'img/logo.png',
                      fit: BoxFit.contain,
                    ),
                  ),
                  const SizedBox(height: AppPadding.lg),
                  Text(
                    'Hi, Selamat Datang 👋',
                    style: AppTextStyles.heading2.copyWith(
                      color: AppColors.surface,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: AppPadding.sm),
                  Text(
                    DateFormatter.formatDateWithDay(DateTime.now()),
                    style: AppTextStyles.body.copyWith(
                      color: Colors.white70,
                    ),
                  ),
                ],
              ),
            ),

            // Summary Cards
            Padding(
              padding: const EdgeInsets.all(AppPadding.md),
              child: Column(
                children: [
                  // Income and Expense Cards (Combined in Teal)
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: AppPadding.lg,
                      vertical: AppPadding.lg,
                    ),
                    decoration: BoxDecoration(
                      color: AppColors.primary,
                      borderRadius: BorderRadius.circular(20),
                      boxShadow: [
                        BoxShadow(
                          color: AppColors.primary.withValues(alpha: 0.3),
                          blurRadius: 15,
                          offset: const Offset(0, 8),
                        ),
                      ],
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceAround,
                      children: [
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.center,
                          children: [
                            Container(
                              padding: const EdgeInsets.all(10),
                              decoration: BoxDecoration(
                                color: Colors.white.withValues(alpha: 0.2),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: const Icon(
                                Icons.arrow_downward,
                                color: Colors.white,
                                size: 20,
                              ),
                            ),
                            const SizedBox(height: AppPadding.sm),
                            Text(
                              'Pemasukan',
                              style: AppTextStyles.caption.copyWith(
                                color: Colors.white70,
                              ),
                            ),
                            const SizedBox(height: AppPadding.xs),
                            Text(
                              CurrencyFormatter.formatCurrency(
                                  _calculateTotalIncome()),
                              style: AppTextStyles.heading3.copyWith(
                                color: AppColors.surface,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                        Container(
                          height: 50,
                          width: 1,
                          color: Colors.white.withValues(alpha: 0.2),
                        ),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.center,
                          children: [
                            Container(
                              padding: const EdgeInsets.all(10),
                              decoration: BoxDecoration(
                                color: Colors.white.withValues(alpha: 0.2),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: const Icon(
                                Icons.arrow_upward,
                                color: Colors.white,
                                size: 20,
                              ),
                            ),
                            const SizedBox(height: AppPadding.sm),
                            Text(
                              'Pengeluaran',
                              style: AppTextStyles.caption.copyWith(
                                color: Colors.white70,
                              ),
                            ),
                            const SizedBox(height: AppPadding.xs),
                            Text(
                              CurrencyFormatter.formatCurrency(
                                  _calculateTotalExpense()),
                              style: AppTextStyles.subtitle.copyWith(
                                color: AppColors.surface,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: AppPadding.md),

                  // Net Balance Card
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(AppPadding.md),
                    decoration: BoxDecoration(
                      color: AppColors.surface,
                      borderRadius: BorderRadius.circular(AppBorderRadius.lg),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.05),
                          blurRadius: 8,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Saldo Bersih',
                          style: AppTextStyles.body.copyWith(
                            color: AppColors.textSecondary,
                          ),
                        ),
                        const SizedBox(height: AppPadding.sm),
                        Text(
                          CurrencyFormatter.formatCurrency(_calculateNetBalance()),
                          style: AppTextStyles.heading2.copyWith(
                            color: _calculateNetBalance() >= 0
                                ? AppColors.income
                                : AppColors.expense,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            // Accounts Section
            if (_accounts.isNotEmpty)
              Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: AppPadding.md,
                  vertical: AppPadding.sm,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Akun Saya',
                      style: AppTextStyles.heading3,
                    ),
                    const SizedBox(height: AppPadding.md),
                    SizedBox(
                      height: 120,
                      child: ListView.builder(
                        scrollDirection: Axis.horizontal,
                        itemCount: _accounts.length,
                        itemBuilder: (context, index) {
                          return Padding(
                            padding: const EdgeInsets.only(right: AppPadding.md),
                            child: AccountCard(account: _accounts[index]),
                          );
                        },
                      ),
                    ),
                  ],
                ),
              ),

            // Recent Transactions Section
            Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: AppPadding.md,
                vertical: AppPadding.md,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Transaksi Terbaru',
                        style: AppTextStyles.heading3,
                      ),
                      GestureDetector(
                        onTap: () {
                          setState(() {
                            _currentIndex = 1;
                          });
                        },
                        child: Text(
                          'Lihat Semua',
                          style: AppTextStyles.body.copyWith(
                            color: AppColors.primary,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: AppPadding.md),
                  if (_transactions.isEmpty)
                    Center(
                      child: Padding(
                        padding: const EdgeInsets.symmetric(
                          vertical: AppPadding.lg,
                        ),
                        child: Column(
                          children: [
                            Icon(
                              Icons.receipt_long,
                              size: 48,
                              color: AppColors.textSecondary,
                            ),
                            const SizedBox(height: AppPadding.md),
                            Text(
                              'Belum ada transaksi',
                              style: AppTextStyles.body.copyWith(
                                color: AppColors.textSecondary,
                              ),
                            ),
                          ],
                        ),
                      ),
                    )
                  else
                    Column(
                      children: _getRecentTransactions()
                          .map((transaction) => TransactionCard(
                                transaction: transaction,
                                categories: _categories,
                              ))
                          .toList(),
                    ),
                ],
              ),
            ),
            const SizedBox(height: AppPadding.lg),
          ],
        ),
      ),
    );
  }
}
