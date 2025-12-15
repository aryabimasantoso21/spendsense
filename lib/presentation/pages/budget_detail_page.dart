import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../data/models/budget_model.dart';
import '../../data/models/transaction_model.dart';
import '../../data/services/supabase_service.dart';
import '../../utils/constants.dart';
import '../../utils/formatters.dart';
import 'package:fl_chart/fl_chart.dart';

class BudgetDetailPage extends StatefulWidget {
  final Budget budget;

  const BudgetDetailPage({super.key, required this.budget});

  @override
  State<BudgetDetailPage> createState() => _BudgetDetailPageState();
}

class _BudgetDetailPageState extends State<BudgetDetailPage> {
  final SupabaseService _supabase = SupabaseService.instance;
  List<Transaction> _transactions = [];
  bool _isLoading = true;
  double _spent = 0;

  @override
  void initState() {
    super.initState();
    _loadTransactions();
  }

  Future<void> _loadTransactions() async {
    try {
      final allTransactions = await _supabase.getTransactions();

      // Filter transactions based on budget period and category
      _transactions = allTransactions.where((t) {
        if (t.type != 'expense') return false;
        if (t.date.isBefore(widget.budget.startDate) ||
            t.date.isAfter(widget.budget.endDate))
          return false;
        if (widget.budget.categoryId != null &&
            t.categoryId != widget.budget.categoryId)
          return false;
        return true;
      }).toList();

      _spent = _transactions.fold(0, (sum, t) => sum + t.amount);

      setState(() {
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _deleteBudget() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Delete Budget'),
        content: const Text('Are you sure you want to delete this budget?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.expense,
              foregroundColor: Colors.white,
            ),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirm == true) {
      try {
        await _supabase.deleteBudget(widget.budget.id!);
        if (mounted) {
          Navigator.pop(context, true); // Return true to refresh list
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(SnackBar(content: Text('Error: $e')));
        }
      }
    }
  }

  int _getDaysLeft() {
    final now = DateTime.now();
    if (now.isAfter(widget.budget.endDate)) return 0;
    return widget.budget.endDate.difference(now).inDays;
  }

  double _getAverageSpending() {
    if (_transactions.isEmpty) return 0;
    final days = DateTime.now().difference(widget.budget.startDate).inDays + 1;
    return _spent / days;
  }

  double _getRecommendedSpending() {
    final totalDays =
        widget.budget.endDate.difference(widget.budget.startDate).inDays + 1;
    final daysLeft = _getDaysLeft();
    if (daysLeft <= 0) return 0;

    final remaining = widget.budget.amount - _spent;
    return remaining / daysLeft;
  }

  @override
  Widget build(BuildContext context) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    final backgroundColor = isDarkMode ? const Color(0xFF121212) : Colors.white;
    final textColor = isDarkMode ? Colors.white : AppColors.text;
    final secondaryTextColor = isDarkMode
        ? Colors.white70
        : AppColors.textSecondary;
    final cardColor = isDarkMode
        ? const Color(0xFF1E1E1E)
        : AppColors.surfaceVariant;

    final remaining = widget.budget.amount - _spent;
    final progress = (_spent / widget.budget.amount * 100).clamp(0, 100);
    final isOverBudget = _spent > widget.budget.amount;

    return Scaffold(
      backgroundColor: backgroundColor,
      appBar: AppBar(
        backgroundColor: backgroundColor,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: textColor),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text('Budget', style: TextStyle(color: textColor)),
        actions: [
          IconButton(
            icon: Icon(Icons.edit_outlined, color: textColor),
            onPressed: () {
              // TODO: Implement edit budget
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Edit budget coming soon!')),
              );
            },
          ),
          IconButton(
            icon: Icon(Icons.delete_outline, color: textColor),
            onPressed: _deleteBudget,
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Period Label
                  Text(
                    widget.budget.period.toUpperCase(),
                    style: TextStyle(
                      color: textColor,
                      fontSize: 28,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 24),

                  // Spent and Left
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Spent',
                            style: TextStyle(color: secondaryTextColor),
                          ),
                          Text(
                            CurrencyFormatter.formatCurrency(_spent),
                            style: TextStyle(
                              color: textColor,
                              fontSize: 18,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          Text(
                            'Left',
                            style: TextStyle(color: secondaryTextColor),
                          ),
                          Text(
                            CurrencyFormatter.formatCurrency(remaining),
                            style: TextStyle(
                              color: isOverBudget
                                  ? AppColors.expense
                                  : textColor,
                              fontSize: 18,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),

                  // Progress Bar with Percentage
                  Stack(
                    children: [
                      Container(
                        height: 24,
                        decoration: BoxDecoration(
                          color: cardColor,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: FractionallySizedBox(
                          alignment: Alignment.centerLeft,
                          widthFactor: (progress / 100).clamp(0.0, 1.0),
                          child: Container(
                            decoration: BoxDecoration(
                              color: isOverBudget
                                  ? AppColors.expense
                                  : AppColors.primary,
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                        ),
                      ),
                      Positioned.fill(
                        child: Center(
                          child: Text(
                            '${progress.toStringAsFixed(2)}%',
                            style: TextStyle(
                              color: progress > 50 ? Colors.white : textColor,
                              fontWeight: FontWeight.w600,
                              fontSize: 12,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 32),

                  // Budget Details
                  _buildDetailRow(
                    'Category',
                    widget.budget.title,
                    textColor,
                    secondaryTextColor,
                  ),
                  const SizedBox(height: 16),
                  _buildDetailRow(
                    'Budget',
                    CurrencyFormatter.formatCurrency(widget.budget.amount),
                    textColor,
                    secondaryTextColor,
                  ),
                  const SizedBox(height: 16),
                  _buildDetailRow(
                    'Period',
                    '${DateFormat('dd MMM yyyy').format(widget.budget.startDate)} - ${DateFormat('dd MMM yyyy').format(widget.budget.endDate)}\n${_getDaysLeft()} days left',
                    textColor,
                    secondaryTextColor,
                  ),
                  const SizedBox(height: 32),

                  // Chart Section
                  Container(
                    height: 200,
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: cardColor,
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: _buildSpendingChart(cardColor),
                  ),
                  const SizedBox(height: 24),

                  // Recommended and Average
                  Row(
                    children: [
                      Expanded(
                        child: Column(
                          children: [
                            Text(
                              'Recommended',
                              style: TextStyle(color: secondaryTextColor),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              CurrencyFormatter.formatCurrency(
                                _getRecommendedSpending(),
                              ),
                              style: TextStyle(
                                color: textColor,
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                      ),
                      Expanded(
                        child: Column(
                          children: [
                            Text(
                              'Average',
                              style: TextStyle(color: secondaryTextColor),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              CurrencyFormatter.formatCurrency(
                                _getAverageSpending(),
                              ),
                              style: TextStyle(
                                color: textColor,
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 32),

                  // Transaction List
                  Text(
                    'Transaction list',
                    style: TextStyle(
                      color: textColor,
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 16),
                  _transactions.isEmpty
                      ? Center(
                          child: Padding(
                            padding: const EdgeInsets.all(32),
                            child: Text(
                              'No transactions yet',
                              style: TextStyle(color: secondaryTextColor),
                            ),
                          ),
                        )
                      : ListView.builder(
                          shrinkWrap: true,
                          physics: const NeverScrollableScrollPhysics(),
                          itemCount: _transactions.length,
                          itemBuilder: (context, index) {
                            final transaction = _transactions[index];
                            return _buildTransactionItem(
                              transaction,
                              textColor,
                              secondaryTextColor,
                              cardColor,
                            );
                          },
                        ),
                ],
              ),
            ),
    );
  }

  Widget _buildDetailRow(
    String label,
    String value,
    Color textColor,
    Color secondaryTextColor,
  ) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: TextStyle(color: secondaryTextColor)),
        Expanded(
          child: Text(
            value,
            textAlign: TextAlign.right,
            style: TextStyle(color: textColor, fontWeight: FontWeight.w600),
          ),
        ),
      ],
    );
  }

  Widget _buildSpendingChart(Color cardColor) {
    // Group transactions by date
    final Map<DateTime, double> dailySpending = {};
    for (var transaction in _transactions) {
      final date = DateTime(
        transaction.date.year,
        transaction.date.month,
        transaction.date.day,
      );
      dailySpending[date] = (dailySpending[date] ?? 0) + transaction.amount;
    }

    final sortedDates = dailySpending.keys.toList()..sort();

    if (sortedDates.isEmpty) {
      return Center(
        child: Text(
          'No spending data',
          style: TextStyle(color: AppColors.textSecondary),
        ),
      );
    }

    return LineChart(
      LineChartData(
        gridData: FlGridData(show: true, drawVerticalLine: false),
        titlesData: FlTitlesData(
          leftTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
          rightTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
          topTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
          bottomTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              getTitlesWidget: (value, meta) {
                if (value.toInt() >= 0 && value.toInt() < sortedDates.length) {
                  return Text(
                    DateFormat('MM/dd').format(sortedDates[value.toInt()]),
                    style: const TextStyle(fontSize: 10),
                  );
                }
                return const Text('');
              },
            ),
          ),
        ),
        borderData: FlBorderData(show: false),
        lineBarsData: [
          LineChartBarData(
            spots: List.generate(
              sortedDates.length,
              (index) =>
                  FlSpot(index.toDouble(), dailySpending[sortedDates[index]]!),
            ),
            isCurved: true,
            color: AppColors.primary,
            barWidth: 3,
            dotData: FlDotData(show: false),
            belowBarData: BarAreaData(
              show: true,
              color: AppColors.primary.withValues(alpha: 0.1),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTransactionItem(
    Transaction transaction,
    Color textColor,
    Color secondaryTextColor,
    Color cardColor,
  ) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: AppColors.primary.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(Icons.shopping_bag_outlined, color: AppColors.primary),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  transaction.description ?? 'Transaction',
                  style: TextStyle(
                    color: textColor,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                Text(
                  '${_transactions.where((t) => t.categoryId == transaction.categoryId).length} transaction',
                  style: TextStyle(color: secondaryTextColor, fontSize: 12),
                ),
              ],
            ),
          ),
          Text(
            '-${CurrencyFormatter.formatCurrency(transaction.amount)}',
            style: TextStyle(
              color: AppColors.expense,
              fontWeight: FontWeight.w600,
              fontSize: 16,
            ),
          ),
        ],
      ),
    );
  }
}
