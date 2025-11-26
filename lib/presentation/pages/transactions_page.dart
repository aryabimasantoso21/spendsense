import 'package:flutter/material.dart';
import '../../data/models/transaction_model.dart';
import '../../data/models/category_model.dart';
import '../../data/services/local_storage_service.dart';
import '../../utils/constants.dart';
import '../../utils/formatters.dart';
import '../widgets/transaction_card.dart';
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
  String _filterType = 'all'; // 'all', 'expense', 'income'
  DateTime? _selectedMonth;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    _transactions = await widget.localStorage.getTransactions();
    _categories = await widget.localStorage.getCategories();
    setState(() {});
  }

  List<Transaction> _getFilteredTransactions() {
    var filtered = _transactions;

    if (_filterType != 'all') {
      filtered = filtered.where((t) => t.type == _filterType).toList();
    }

    if (_selectedMonth != null) {
      filtered = filtered
          .where((t) =>
              t.date.year == _selectedMonth!.year &&
              t.date.month == _selectedMonth!.month)
          .toList();
    }

    filtered.sort((a, b) => b.date.compareTo(a.date));
    return filtered;
  }

  Future<void> _deleteTransaction(int id) async {
    await widget.localStorage.deleteTransaction(id);
    await _loadData();
    widget.onDataChanged();
  }

  @override
  Widget build(BuildContext context) {
    final filtered = _getFilteredTransactions();

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text(AppStrings.transactions),
        backgroundColor: AppColors.primary,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.search),
            onPressed: () {
              // TODO: Implement search
            },
          ),
        ],
      ),
      body: Column(
        children: [
          // Filter Section
          Container(
            color: AppColors.surface,
            padding: const EdgeInsets.all(AppPadding.md),
            child: Column(
              children: [
                // Month Selector
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: [
                      for (int i = 0; i < 6; i++) ...[
                        _buildMonthButton(
                          DateTime(DateTime.now().year,
                              DateTime.now().month - i),
                        ),
                        if (i < 5) const SizedBox(width: AppPadding.sm),
                      ],
                    ],
                  ),
                ),
                const SizedBox(height: AppPadding.md),
                // Type Filter
                Row(
                  children: [
                    _buildFilterChip('Semua', 'all'),
                    const SizedBox(width: AppPadding.sm),
                    _buildFilterChip('Pengeluaran', 'expense'),
                    const SizedBox(width: AppPadding.sm),
                    _buildFilterChip('Pemasukan', 'income'),
                  ],
                ),
              ],
            ),
          ),
          // Transaction List
          Expanded(
            child: filtered.isEmpty
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.receipt_long,
                          size: 64,
                          color: AppColors.textSecondary,
                        ),
                        const SizedBox(height: AppPadding.md),
                        Text(
                          'Tidak ada transaksi',
                          style: AppTextStyles.body.copyWith(
                            color: AppColors.textSecondary,
                          ),
                        ),
                      ],
                    ),
                  )
                : ListView.builder(
                    padding: const EdgeInsets.all(AppPadding.md),
                    itemCount: filtered.length,
                    itemBuilder: (context, index) {
                      final transaction = filtered[index];
                      return Dismissible(
                        key: Key(transaction.id.toString()),
                        direction: DismissDirection.endToStart,
                        onDismissed: (_) {
                          _deleteTransaction(transaction.id);
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('Transaksi dihapus'),
                              duration: Duration(seconds: 2),
                            ),
                          );
                        },
                        background: Container(
                          decoration: BoxDecoration(
                            color: AppColors.expense,
                            borderRadius:
                                BorderRadius.circular(AppBorderRadius.lg),
                          ),
                          alignment: Alignment.centerRight,
                          padding: const EdgeInsets.only(right: AppPadding.md),
                          child: const Icon(
                            Icons.delete,
                            color: Colors.white,
                          ),
                        ),
                        child: TransactionCard(
                          transaction: transaction,
                          categories: _categories,
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        backgroundColor: AppColors.primary,
        onPressed: () async {
          await Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => AddTransactionPage(
                localStorage: widget.localStorage,
              ),
            ),
          );
          await _loadData();
          widget.onDataChanged();
        },
        child: const Icon(Icons.add),
      ),
    );
  }

  Widget _buildMonthButton(DateTime date) {
    final isSelected = _selectedMonth != null &&
        _selectedMonth!.year == date.year &&
        _selectedMonth!.month == date.month;

    return GestureDetector(
      onTap: () {
        setState(() {
          _selectedMonth = isSelected ? null : date;
        });
      },
      child: Container(
        padding: const EdgeInsets.symmetric(
          horizontal: AppPadding.md,
          vertical: AppPadding.sm,
        ),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.primary : AppColors.background,
          borderRadius: BorderRadius.circular(AppBorderRadius.sm),
          border: Border.all(
            color: isSelected ? AppColors.primary : AppColors.border,
          ),
        ),
        child: Text(
          DateFormatter.formatMonth(date),
          style: AppTextStyles.body.copyWith(
            color: isSelected ? Colors.white : AppColors.text,
            fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
          ),
        ),
      ),
    );
  }

  Widget _buildFilterChip(String label, String value) {
    final isSelected = _filterType == value;

    return GestureDetector(
      onTap: () {
        setState(() {
          _filterType = value;
        });
      },
      child: Container(
        padding: const EdgeInsets.symmetric(
          horizontal: AppPadding.md,
          vertical: AppPadding.sm,
        ),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.primary : AppColors.background,
          borderRadius: BorderRadius.circular(AppBorderRadius.sm),
          border: Border.all(
            color: isSelected ? AppColors.primary : AppColors.border,
          ),
        ),
        child: Text(
          label,
          style: AppTextStyles.body.copyWith(
            color: isSelected ? Colors.white : AppColors.text,
            fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
          ),
        ),
      ),
    );
  }
}
