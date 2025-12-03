import 'package:flutter/material.dart';
import '../../data/models/transaction_model.dart';
import '../../data/models/category_model.dart';
import '../../data/models/account_model.dart';
import '../../data/services/local_storage_service.dart';
import '../../data/services/supabase_service.dart';
import '../../utils/constants.dart';
import '../../utils/formatters.dart';
import 'add_transaction_page.dart';

class TransactionsPage extends StatefulWidget {
  final LocalStorageService localStorage;
  final VoidCallback onDataChanged;

  const TransactionsPage({
    super.key,
    required this.localStorage,
    required this.onDataChanged,
  });

  @override
  State<TransactionsPage> createState() => _TransactionsPageState();
}

class _TransactionsPageState extends State<TransactionsPage> {
  final SupabaseService _supabase = SupabaseService.instance;
  
  List<Transaction> _transactions = [];
  List<Category> _categories = [];
  List<Account> _accounts = [];
  String _selectedPeriod = 'Month';
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);
    try {
      // Try Supabase first
      _transactions = await _supabase.getTransactions();
      _categories = await _supabase.getCategories();
      _accounts = await _supabase.getAccounts();
      
      // Fill in account names from accounts list
      _transactions = _transactions.map((t) {
        final account = _accounts.firstWhere(
          (a) => a.id == t.accountId,
          orElse: () => Account(id: 0, userId: '', name: 'Unknown', type: '', balance: 0, createdAt: DateTime.now()),
        );
        final destAccount = t.destinationAccountId != null
            ? _accounts.firstWhere(
                (a) => a.id == t.destinationAccountId,
                orElse: () => Account(id: 0, userId: '', name: 'Unknown', type: '', balance: 0, createdAt: DateTime.now()),
              )
            : null;
        
        return t.copyWith(
          accountName: account.name,
          destinationAccountName: destAccount?.name,
        );
      }).toList();
    } catch (e) {
      // Fallback to local storage
      _transactions = await widget.localStorage.getTransactions();
      _categories = await widget.localStorage.getCategories();
      _accounts = await widget.localStorage.getAccounts();
      
      // Fill in account names from accounts list
      _transactions = _transactions.map((t) {
        final account = _accounts.firstWhere(
          (a) => a.id == t.accountId,
          orElse: () => Account(id: 0, userId: '', name: 'Unknown', type: '', balance: 0, createdAt: DateTime.now()),
        );
        final destAccount = t.destinationAccountId != null
            ? _accounts.firstWhere(
                (a) => a.id == t.destinationAccountId,
                orElse: () => Account(id: 0, userId: '', name: 'Unknown', type: '', balance: 0, createdAt: DateTime.now()),
              )
            : null;
        
        return t.copyWith(
          accountName: account.name,
          destinationAccountName: destAccount?.name,
        );
      }).toList();
    }
    if (mounted) {
      setState(() => _isLoading = false);
    }
  }

  // Get filtered transactions based on selected period
  List<Transaction> get _filteredTransactions {
    final now = DateTime.now();
    
    return _transactions.where((t) {
      switch (_selectedPeriod) {
        case 'Today':
          return t.date.year == now.year && 
                 t.date.month == now.month && 
                 t.date.day == now.day;
        case 'Week':
          final weekStart = now.subtract(Duration(days: now.weekday - 1));
          return t.date.isAfter(weekStart.subtract(const Duration(days: 1)));
        case 'Month':
          return t.date.year == now.year && t.date.month == now.month;
        case 'Year':
          return t.date.year == now.year;
        default:
          return true;
      }
    }).toList();
  }

  // Group transactions by date
  Map<DateTime, List<Transaction>> get _groupedTransactions {
    final grouped = <DateTime, List<Transaction>>{};
    final sorted = List<Transaction>.from(_filteredTransactions)
      ..sort((a, b) => b.date.compareTo(a.date));
    
    for (var t in sorted) {
      final dateKey = DateTime(t.date.year, t.date.month, t.date.day);
      grouped.putIfAbsent(dateKey, () => []).add(t);
    }
    return grouped;
  }

  double get _totalIncome => _filteredTransactions
      .where((t) => t.type == 'income')
      .fold(0.0, (sum, t) => sum + t.amount);

  double get _totalExpense => _filteredTransactions
      .where((t) => t.type == 'expense')
      .fold(0.0, (sum, t) => sum + t.amount);

  double get _totalBalance => _totalIncome - _totalExpense;

  Future<void> _deleteTransaction(int id) async {
    try {
      await _supabase.deleteTransaction(id);
    } catch (e) {
      // Fallback to local delete
      await widget.localStorage.deleteTransaction(id);
    }
    await _loadData();
    widget.onDataChanged();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        automaticallyImplyLeading: false,
        backgroundColor: AppColors.background,
        elevation: 0,
        centerTitle: true,
        title: const Text(
          'Transaction',
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
      body: Column(
        children: [
          // Period Tabs
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
            child: Container(
              height: 40,
              decoration: BoxDecoration(
                color: AppColors.surfaceVariant,
                borderRadius: BorderRadius.circular(20),
              ),
              child: Row(
                children: ['Today', 'Week', 'Month', 'Year'].map((period) {
                  final isSelected = _selectedPeriod == period;
                  return Expanded(
                    child: GestureDetector(
                      onTap: () => setState(() => _selectedPeriod = period),
                      child: Container(
                        decoration: BoxDecoration(
                          color: isSelected ? Colors.white : Colors.transparent,
                          borderRadius: BorderRadius.circular(20),
                          boxShadow: isSelected
                              ? [
                                  BoxShadow(
                                    color: Colors.black.withValues(alpha: 0.1),
                                    blurRadius: 4,
                                    offset: const Offset(0, 2),
                                  ),
                                ]
                              : null,
                        ),
                        child: Center(
                          child: Text(
                            period,
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
                              color: isSelected ? AppColors.text : AppColors.textSecondary,
                            ),
                          ),
                        ),
                      ),
                    ),
                  );
                }).toList(),
              ),
            ),
          ),

          // Summary Card
          Container(
            margin: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [AppColors.primary, AppColors.primaryLight],
                begin: Alignment.centerLeft,
                end: Alignment.centerRight,
              ),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Income',
                        style: TextStyle(color: Colors.white70, fontSize: 11),
                      ),
                      Text(
                        CurrencyFormatter.formatCurrency(_totalIncome),
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
                Container(
                  width: 1,
                  height: 30,
                  color: Colors.white24,
                ),
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.only(left: 16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Expense',
                          style: TextStyle(color: Colors.white70, fontSize: 11),
                        ),
                        Text(
                          CurrencyFormatter.formatCurrency(_totalExpense),
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                Container(
                  width: 1,
                  height: 30,
                  color: Colors.white24,
                ),
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.only(left: 16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Total',
                          style: TextStyle(color: Colors.white70, fontSize: 11),
                        ),
                        Text(
                          CurrencyFormatter.formatCurrency(_totalBalance),
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),

          // Transactions List
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator(color: AppColors.primary))
                : _filteredTransactions.isEmpty
                    ? const Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.receipt_long, size: 64, color: AppColors.textTertiary),
                            SizedBox(height: 16),
                            Text(
                              'Belum ada transaksi',
                              style: TextStyle(color: AppColors.textSecondary),
                            ),
                          ],
                        ),
                      )
                    : RefreshIndicator(
                        onRefresh: _loadData,
                        color: AppColors.primary,
                        child: ListView.builder(
                          padding: const EdgeInsets.symmetric(horizontal: 24),
                          itemCount: _groupedTransactions.length,
                          itemBuilder: (context, index) {
                            final date = _groupedTransactions.keys.elementAt(index);
                            final transactions = _groupedTransactions[date]!;
                            return _buildDateGroup(date, transactions);
                          },
                        ),
                      ),
          ),
        ],
      ),
      // FAB is handled by HomePage
    );
  }

  Widget _buildDateGroup(DateTime date, List<Transaction> transactions) {
    final dayIncome = transactions
        .where((t) => t.type == 'income')
        .fold(0.0, (sum, t) => sum + t.amount);
    final dayExpense = transactions
        .where((t) => t.type == 'expense')
        .fold(0.0, (sum, t) => sum + t.amount);

    final dayName = _getDayName(date);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 12),
          child: Row(
            children: [
              Text(
                date.day.toString().padLeft(2, '0'),
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: AppColors.text,
                ),
              ),
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  color: AppColors.surfaceVariant,
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Text(
                  dayName,
                  style: const TextStyle(
                    fontSize: 11,
                    color: AppColors.textSecondary,
                  ),
                ),
              ),
              const Spacer(),
              Text(
                CurrencyFormatter.formatCurrency(dayIncome),
                style: const TextStyle(
                  fontSize: 13,
                  color: AppColors.primary,
                ),
              ),
              const SizedBox(width: 16),
              Text(
                CurrencyFormatter.formatCurrency(dayExpense),
                style: const TextStyle(
                  fontSize: 13,
                  color: AppColors.expense,
                ),
              ),
            ],
          ),
        ),
        ...transactions.map((t) => _buildTransactionItem(t)),
      ],
    );
  }

  String _getDayName(DateTime date) {
    final days = ['Min', 'Sen', 'Sel', 'Rab', 'Kam', 'Jum', 'Sab'];
    return days[date.weekday % 7];
  }

  Widget _buildTransactionItem(Transaction transaction) {
    final category = _categories.firstWhere(
      (cat) => cat.id == transaction.categoryId,
      orElse: () => Category(id: 0, name: 'Other', type: transaction.type),
    );
    final isExpense = transaction.type == 'expense';
    final isIncome = transaction.type == 'income';
    final isTransfer = transaction.type == 'transfer';

    return Dismissible(
      key: Key(transaction.id.toString()),
      direction: DismissDirection.endToStart,
      onDismissed: (_) => _deleteTransaction(transaction.id),
      background: Container(
        margin: const EdgeInsets.only(left: 32, bottom: 12),
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 20),
        decoration: BoxDecoration(
          color: AppColors.expense,
          borderRadius: BorderRadius.circular(12),
        ),
        child: const Icon(Icons.delete, color: Colors.white),
      ),
      child: Padding(
        padding: const EdgeInsets.only(left: 32),
        child: GestureDetector(
          onTap: () async {
            await Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => AddTransactionPage(
                  localStorage: widget.localStorage,
                  transaction: transaction,
                ),
              ),
            );
            _loadData();
            widget.onDataChanged();
          },
          child: Container(
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
                    color: isTransfer
                        ? AppColors.cardBlue.withValues(alpha: 0.1)
                        : (isExpense ? AppColors.expense : AppColors.primary).withValues(alpha: 0.1),
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
                      Text(
                        isTransfer ? 'Transfer' : category.name,
                        style: const TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w500,
                          color: AppColors.text,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        isTransfer
                            ? '${transaction.accountName} → ${transaction.destinationAccountName}'
                            : transaction.accountName ?? '',
                        style: const TextStyle(
                          fontSize: 12,
                          color: AppColors.textSecondary,
                        ),
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
        ),
      ),
    );
  }
}
