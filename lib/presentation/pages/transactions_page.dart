import 'package:flutter/material.dart';
import '../../data/models/transaction_model.dart';
import '../../data/models/category_model.dart';
import '../../data/services/local_storage_service.dart';
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
  List<Transaction> _transactions = [];
  List<Category> _categories = [];
  String _selectedPeriod = 'Today';

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    _transactions = await widget.localStorage.getTransactions();
    _categories = await widget.localStorage.getCategories();
    if (mounted) {
      setState(() {});
    }
  }

  // Group transactions by date
  Map<DateTime, List<Transaction>> get _groupedTransactions {
    final grouped = <DateTime, List<Transaction>>{};
    final sorted = List<Transaction>.from(_transactions)
      ..sort((a, b) => b.date.compareTo(a.date));
    
    for (var t in sorted) {
      final dateKey = DateTime(t.date.year, t.date.month, t.date.day);
      grouped.putIfAbsent(dateKey, () => []).add(t);
    }
    return grouped;
  }

  double get _totalIncome => _transactions
      .where((t) => t.type == 'income')
      .fold(0.0, (sum, t) => sum + t.amount);

  double get _totalExpense => _transactions
      .where((t) => t.type == 'expense')
      .fold(0.0, (sum, t) => sum + t.amount);

  double get _totalBalance => _totalIncome - _totalExpense;

  Future<void> _deleteTransaction(int id) async {
    await widget.localStorage.deleteTransaction(id);
    await _loadData();
    widget.onDataChanged();
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
            child: _transactions.isEmpty
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
                : ListView.builder(
                    padding: const EdgeInsets.symmetric(horizontal: 24),
                    itemCount: _groupedTransactions.length,
                    itemBuilder: (context, index) {
                      final date = _groupedTransactions.keys.elementAt(index);
                      final transactions = _groupedTransactions[date]!;
                      return _buildDateGroup(date, transactions);
                    },
                  ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () async {
          await Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => AddTransactionPage(localStorage: widget.localStorage),
            ),
          );
          await _loadData();
          widget.onDataChanged();
        },
        backgroundColor: AppColors.primary,
        child: const Icon(Icons.add, color: Colors.white),
      ),
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
                '${date.day.toString().padLeft(2, '0')}',
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
      orElse: () => Category(id: 0, name: 'Lainnya', type: transaction.type),
    );
    final isExpense = transaction.type == 'expense';

    return Dismissible(
      key: Key(transaction.id.toString()),
      direction: DismissDirection.endToStart,
      onDismissed: (_) => _deleteTransaction(transaction.id),
      background: Container(
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 20),
        color: AppColors.expense,
        child: const Icon(Icons.delete, color: Colors.white),
      ),
      child: Padding(
        padding: const EdgeInsets.only(left: 32, bottom: 8),
        child: Row(
          children: [
            Expanded(
              child: Text(
                category.name,
                style: const TextStyle(
                  fontSize: 15,
                  color: AppColors.text,
                ),
              ),
            ),
            Text(
              CurrencyFormatter.formatCurrency(transaction.amount),
              style: TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w600,
                color: isExpense ? AppColors.expense : AppColors.primary,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
