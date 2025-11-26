import 'package:flutter/material.dart';
import '../../data/models/transaction_model.dart';
import '../../data/models/category_model.dart';
import '../../data/services/local_storage_service.dart';
import '../../utils/constants.dart';
import '../../utils/formatters.dart';
import '../widgets/transaction_card.dart';
import 'add_transaction_page.dart';

class TransactionsPageNew extends StatefulWidget {
  final LocalStorageService localStorage;

  const TransactionsPageNew({
    super.key,
    required this.localStorage,
  });

  @override
  State<TransactionsPageNew> createState() => _TransactionsPageNewState();
}

class _TransactionsPageNewState extends State<TransactionsPageNew> {
  List<Transaction> _transactions = [];
  List<Category> _categories = [];
  String _filterType = 'Today'; // Today, Week, Month, Year

  @override
  void initState() {
    super.initState();
    _loadTransactions();
    _loadCategories();
  }

  Future<void> _loadTransactions() async {
    final transactions = await widget.localStorage.getTransactions();
    setState(() {
      _transactions = transactions;
    });
  }

  Future<void> _loadCategories() async {
    final categories = await widget.localStorage.getCategories();
    setState(() {
      _categories = categories;
    });
  }

  List<Transaction> _getFilteredTransactions() {
    final now = DateTime.now();
    final filtered = _transactions.where((t) {
      switch (_filterType) {
        case 'Today':
          return t.date.year == now.year &&
              t.date.month == now.month &&
              t.date.day == now.day;
        case 'Week':
          final weekAgo = now.subtract(const Duration(days: 7));
          return t.date.isAfter(weekAgo) && 
              t.date.isBefore(now.add(const Duration(days: 1)));
        case 'Month':
          return t.date.year == now.year && t.date.month == now.month;
        case 'Year':
          return t.date.year == now.year;
        default:
          return true;
      }
    }).toList();

    filtered.sort((a, b) => b.date.compareTo(a.date));
    return filtered;
  }

  double _calculateTotalIncome() {
    return _getFilteredTransactions()
        .where((t) => t.type == 'income')
        .fold(0.0, (sum, t) => sum + t.amount);
  }

  double _calculateTotalExpense() {
    return _getFilteredTransactions()
        .where((t) => t.type == 'expense')
        .fold(0.0, (sum, t) => sum + t.amount);
  }

  Future<void> _deleteTransaction(Transaction transaction) async {
    await widget.localStorage.deleteTransaction(transaction.id);
    await _loadTransactions();
  }

  @override
  Widget build(BuildContext context) {
    final filtered = _getFilteredTransactions();

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Transaction'),
        backgroundColor: AppColors.primary,
        elevation: 0,
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            // Filter Tabs
            Padding(
              padding: const EdgeInsets.all(AppPadding.md),
              child: SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: ['Today', 'Week', 'Month', 'Year'].map((label) {
                    final isSelected = _filterType == label;
                    return Padding(
                      padding: const EdgeInsets.only(right: AppPadding.sm),
                      child: GestureDetector(
                        onTap: () => setState(() => _filterType = label),
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: AppPadding.md,
                            vertical: AppPadding.sm,
                          ),
                          decoration: BoxDecoration(
                            color: isSelected ? AppColors.primary : AppColors.surface,
                            borderRadius: BorderRadius.circular(AppBorderRadius.lg),
                            border: Border.all(
                              color: isSelected ? AppColors.primary : AppColors.border,
                            ),
                          ),
                          child: Text(
                            label,
                            style: AppTextStyles.body.copyWith(
                              color: isSelected ? AppColors.surface : AppColors.text,
                              fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                            ),
                          ),
                        ),
                      ),
                    );
                  }).toList(),
                ),
              ),
            ),

            // Summary Cards
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: AppPadding.md),
              child: Container(
                padding: const EdgeInsets.all(AppPadding.md),
                decoration: BoxDecoration(
                  color: AppColors.primaryDark,
                  borderRadius: BorderRadius.circular(AppBorderRadius.lg),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Pemasukan',
                          style: AppTextStyles.caption.copyWith(
                            color: Colors.white70,
                          ),
                        ),
                        const SizedBox(height: AppPadding.sm),
                        Text(
                          CurrencyFormatter.formatCurrency(_calculateTotalIncome()),
                          style: AppTextStyles.subtitle.copyWith(
                            color: AppColors.surface,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                    Container(
                      height: 40,
                      width: 1,
                      color: Colors.white30,
                    ),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Text(
                          'Pengeluaran',
                          style: AppTextStyles.caption.copyWith(
                            color: Colors.white70,
                          ),
                        ),
                        const SizedBox(height: AppPadding.sm),
                        Text(
                          CurrencyFormatter.formatCurrency(_calculateTotalExpense()),
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
            ),
            const SizedBox(height: AppPadding.md),

            // Transactions List
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: AppPadding.md),
              child: Column(
                children: filtered.isEmpty
                    ? [
                        Padding(
                          padding: const EdgeInsets.all(AppPadding.lg),
                          child: Text(
                            'Tidak ada transaksi',
                            style: AppTextStyles.body.copyWith(
                              color: AppColors.textSecondary,
                            ),
                          ),
                        ),
                      ]
                    : filtered.map((transaction) {
                        return Dismissible(
                          key: Key(transaction.id.toString()),
                          onDismissed: (_) => _deleteTransaction(transaction),
                          child: Padding(
                            padding: const EdgeInsets.only(bottom: AppPadding.md),
                            child: TransactionCard(
                              transaction: transaction,
                              categories: _categories,
                            ),
                          ),
                        );
                      }).toList(),
              ),
            ),
            const SizedBox(height: AppPadding.lg),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () async {
          await Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => AddTransactionPage(
                localStorage: widget.localStorage,
              ),
            ),
          );
          _loadTransactions();
        },
        backgroundColor: AppColors.primary,
        child: const Icon(Icons.add),
      ),
    );
  }
}
