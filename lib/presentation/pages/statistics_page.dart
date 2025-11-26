import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import '../../data/models/transaction_model.dart';
import '../../data/models/category_model.dart';
import '../../data/services/local_storage_service.dart';
import '../../utils/constants.dart';
import '../../utils/formatters.dart';

class StatisticsPage extends StatefulWidget {
  final LocalStorageService localStorage;

  const StatisticsPage({
    super.key,
    required this.localStorage,
  });

  @override
  State<StatisticsPage> createState() => _StatisticsPageState();
}

class _StatisticsPageState extends State<StatisticsPage> {
  List<Transaction> _transactions = [];
  List<Category> _categories = [];
  String _selectedType = 'expense';
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
    var filtered = _transactions
        .where((t) => t.type == _selectedType)
        .toList();

    if (_selectedMonth != null) {
      filtered = filtered
          .where((t) =>
              t.date.year == _selectedMonth!.year &&
              t.date.month == _selectedMonth!.month)
          .toList();
    } else {
      // Default to current month
      final now = DateTime.now();
      filtered = filtered
          .where((t) =>
              t.date.year == now.year &&
              t.date.month == now.month)
          .toList();
    }

    return filtered;
  }

  Map<String, double> _getCategoryTotals() {
    final filtered = _getFilteredTransactions();
    final totals = <String, double>{};

    for (var transaction in filtered) {
      final category = _categories
          .firstWhere((c) => c.id == transaction.categoryId, orElse: () => const Category(id: 0, type: '', name: 'Other'));
      totals[category.name] = (totals[category.name] ?? 0) + transaction.amount;
    }

    return totals;
  }

  double _getTotalAmount() {
    return _getFilteredTransactions().fold(0, (sum, t) => sum + t.amount);
  }

  @override
  Widget build(BuildContext context) {
    final categoryTotals = _getCategoryTotals();
    final totalAmount = _getTotalAmount();
    final filteredTransactions = _getFilteredTransactions();

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Statistik'),
        backgroundColor: AppColors.primary,
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(AppPadding.md),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Type Selection
            Row(
              children: [
                Expanded(
                  child: _buildTypeButton('Pengeluaran', 'expense'),
                ),
                const SizedBox(width: AppPadding.md),
                Expanded(
                  child: _buildTypeButton('Pemasukan', 'income'),
                ),
              ],
            ),
            const SizedBox(height: AppPadding.lg),

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
            const SizedBox(height: AppPadding.lg),

            // Total Amount
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(AppPadding.md),
              decoration: BoxDecoration(
                color: AppColors.surface,
                borderRadius: BorderRadius.circular(AppBorderRadius.lg),
                border: Border.all(color: AppColors.border),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    _selectedType == 'expense' ? 'Total Pengeluaran' : 'Total Pemasukan',
                    style: AppTextStyles.body.copyWith(
                      color: AppColors.textSecondary,
                    ),
                  ),
                  const SizedBox(height: AppPadding.sm),
                  Text(
                    CurrencyFormatter.formatCurrency(totalAmount),
                    style: AppTextStyles.heading2.copyWith(
                      color: _selectedType == 'expense'
                          ? AppColors.expense
                          : AppColors.income,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: AppPadding.lg),

            // Pie Chart
            if (categoryTotals.isNotEmpty)
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(AppPadding.md),
                decoration: BoxDecoration(
                  color: AppColors.surface,
                  borderRadius: BorderRadius.circular(AppBorderRadius.lg),
                  border: Border.all(color: AppColors.border),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Breakdown per Kategori',
                      style: AppTextStyles.subtitle,
                    ),
                    const SizedBox(height: AppPadding.md),
                    SizedBox(
                      height: 250,
                      child: PieChart(
                        PieChartData(
                          sections: _buildPieChartSections(
                              categoryTotals, totalAmount),
                          centerSpaceRadius: 0,
                          sectionsSpace: 2,
                        ),
                      ),
                    ),
                  ],
                ),
              )
            else
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(AppPadding.lg),
                decoration: BoxDecoration(
                  color: AppColors.surface,
                  borderRadius: BorderRadius.circular(AppBorderRadius.lg),
                  border: Border.all(color: AppColors.border),
                ),
                child: Center(
                  child: Text(
                    'Belum ada data untuk bulan ini',
                    style: AppTextStyles.body.copyWith(
                      color: AppColors.textSecondary,
                    ),
                  ),
                ),
              ),
            const SizedBox(height: AppPadding.lg),

            // Category Breakdown
            if (categoryTotals.isNotEmpty) ...[
              Text(
                'Detail Kategori',
                style: AppTextStyles.subtitle,
              ),
              const SizedBox(height: AppPadding.md),
              ...categoryTotals.entries.map((entry) {
                final percentage = (entry.value / totalAmount * 100);
                return Container(
                  margin: const EdgeInsets.only(bottom: AppPadding.md),
                  padding: const EdgeInsets.all(AppPadding.md),
                  decoration: BoxDecoration(
                    color: AppColors.surface,
                    borderRadius: BorderRadius.circular(AppBorderRadius.lg),
                    border: Border.all(color: AppColors.border),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Row(
                            children: [
                              Text(
                                categoryIcons[entry.key] ?? '📌',
                                style: const TextStyle(fontSize: 24),
                              ),
                              const SizedBox(width: AppPadding.md),
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    entry.key,
                                    style: AppTextStyles.subtitle,
                                  ),
                                  Text(
                                    '${percentage.toStringAsFixed(1)}%',
                                    style: AppTextStyles.caption.copyWith(
                                      color: AppColors.textSecondary,
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                          Text(
                            CurrencyFormatter.formatCurrency(entry.value),
                            style: AppTextStyles.subtitle.copyWith(
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: AppPadding.sm),
                      ClipRRect(
                        borderRadius: BorderRadius.circular(AppBorderRadius.xs),
                        child: LinearProgressIndicator(
                          value: entry.value / totalAmount,
                          minHeight: 6,
                          backgroundColor: AppColors.border,
                          valueColor: AlwaysStoppedAnimation<Color>(
                            _selectedType == 'expense'
                                ? AppColors.expense
                                : AppColors.income,
                          ),
                        ),
                      ),
                    ],
                  ),
                );
              }).toList(),
            ],
          ],
        ),
      ),
    );
  }

  List<PieChartSectionData> _buildPieChartSections(
      Map<String, double> totals, double totalAmount) {
    final colors = [
      const Color(0xFFFF6B6B),
      const Color(0xFF4ECDC4),
      const Color(0xFF45B7D1),
      const Color(0xFFFFA07A),
      const Color(0xFF98D8C8),
      const Color(0xFFF7DC6F),
    ];

    return totals.entries.toList().asMap().entries.map((entry) {
      final index = entry.key;
      final data = entry.value;
      final value = data.value;
      final percentage = (value / totalAmount * 100);

      return PieChartSectionData(
        value: value,
        title: '${percentage.toStringAsFixed(0)}%',
        color: colors[index % colors.length],
        radius: 60,
        titleStyle: AppTextStyles.caption.copyWith(
          color: Colors.white,
          fontWeight: FontWeight.bold,
        ),
      );
    }).toList();
  }

  Widget _buildTypeButton(String label, String value) {
    final isSelected = _selectedType == value;
    return GestureDetector(
      onTap: () {
        setState(() {
          _selectedType = value;
        });
      },
      child: Container(
        padding: const EdgeInsets.symmetric(
          horizontal: AppPadding.md,
          vertical: AppPadding.md,
        ),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.primary : AppColors.surface,
          borderRadius: BorderRadius.circular(AppBorderRadius.md),
          border: Border.all(
            color: isSelected ? AppColors.primary : AppColors.border,
          ),
        ),
        child: Center(
          child: Text(
            label,
            style: AppTextStyles.subtitle.copyWith(
              color: isSelected ? Colors.white : AppColors.text,
            ),
          ),
        ),
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
}
