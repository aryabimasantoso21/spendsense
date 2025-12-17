import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
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
  String _selectedPeriod = 'Daily';
  DateTime _selectedDate = DateTime.now();
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
    return _transactions.where((t) {
      switch (_selectedPeriod) {
        case 'Daily':
          return t.date.year == _selectedDate.year && 
                 t.date.month == _selectedDate.month && 
                 t.date.day == _selectedDate.day;
        case 'Weekly':
          final weekStart = _selectedDate.subtract(Duration(days: _selectedDate.weekday - 1));
          final weekEnd = weekStart.add(const Duration(days: 6));
          // Check if date is within the week range (inclusive)
          final date = DateTime(t.date.year, t.date.month, t.date.day);
          final start = DateTime(weekStart.year, weekStart.month, weekStart.day);
          final end = DateTime(weekEnd.year, weekEnd.month, weekEnd.day);
          return (date.isAtSameMomentAs(start) || date.isAfter(start)) && 
                 (date.isAtSameMomentAs(end) || date.isBefore(end));
        case 'Monthly':
          return t.date.year == _selectedDate.year && t.date.month == _selectedDate.month;
        case 'Yearly':
          return t.date.year == _selectedDate.year;
        default:
          return true;
      }
    }).toList();
  }

  void _navigateDate(int count) {
    setState(() {
      switch (_selectedPeriod) {
        case 'Daily':
          _selectedDate = _selectedDate.add(Duration(days: count));
          break;
        case 'Weekly':
          _selectedDate = _selectedDate.add(Duration(days: count * 7));
          break;
        case 'Monthly':
          _selectedDate = DateTime(_selectedDate.year, _selectedDate.month + count);
          break;
        case 'Yearly':
          _selectedDate = DateTime(_selectedDate.year + count);
          break;
      }
    });
  }

  String get _dateRangeText {
    switch (_selectedPeriod) {
      case 'Daily':
        return DateFormat('d MMMM yyyy').format(_selectedDate);
      case 'Weekly':
        final start = _selectedDate.subtract(Duration(days: _selectedDate.weekday - 1));
        final end = start.add(const Duration(days: 6));
        // Format: 30 Nov - 06 Dec 2025
        return '${DateFormat('d MMM').format(start)} - ${DateFormat('d MMM yyyy').format(end)}';
      case 'Monthly':
        return DateFormat('MMMM yyyy').format(_selectedDate);
      case 'Yearly':
        return DateFormat('yyyy').format(_selectedDate);
      default:
        return '';
    }
  }

  Future<void> _pickDate() async {
    final firstDate = DateTime(2020);
    final lastDate = DateTime(2030);

    if (_selectedPeriod == 'Daily') {
      final picked = await showDatePicker(
        context: context,
        initialDate: _selectedDate,
        firstDate: firstDate,
        lastDate: lastDate,
      );
      if (picked != null) setState(() => _selectedDate = picked);
    } else if (_selectedPeriod == 'Weekly') {
      // For weekly, we pick a date and it selects that week
      final picked = await showDatePicker(
        context: context,
        initialDate: _selectedDate,
        firstDate: firstDate,
        lastDate: lastDate,
        helpText: 'Select any day in the week',
      );
      if (picked != null) setState(() => _selectedDate = picked);
    } else if (_selectedPeriod == 'Monthly') {
      // Custom Month Picker
      await showDialog(
        context: context,
        builder: (context) {
          int dialogYear = _selectedDate.year;
          return StatefulBuilder(
            builder: (context, setStateDialog) {
              return AlertDialog(
                title: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    IconButton(
                      icon: const Icon(Icons.chevron_left),
                      onPressed: () => setStateDialog(() => dialogYear--),
                    ),
                    Text(
                      '$dialogYear',
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                    IconButton(
                      icon: const Icon(Icons.chevron_right),
                      onPressed: () => setStateDialog(() => dialogYear++),
                    ),
                  ],
                ),
                content: SizedBox(
                  width: double.maxFinite,
                  child: GridView.builder(
                    shrinkWrap: true,
                    gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 3,
                      childAspectRatio: 1.5,
                    ),
                    itemCount: 12,
                    itemBuilder: (context, index) {
                      final monthDate = DateTime(dialogYear, index + 1);
                      final isSelected = index + 1 == _selectedDate.month && dialogYear == _selectedDate.year;
                      return InkWell(
                        onTap: () {
                          setState(() {
                            _selectedDate = DateTime(dialogYear, index + 1);
                          });
                          Navigator.pop(context);
                        },
                        child: Container(
                          alignment: Alignment.center,
                          margin: const EdgeInsets.all(4),
                          decoration: BoxDecoration(
                            color: isSelected ? AppColors.primary : null,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            DateFormat('MMM').format(monthDate),
                            style: TextStyle(
                              color: isSelected ? Colors.white : Colors.black,
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                ),
                actions: [
                  TextButton(
                    onPressed: () => Navigator.pop(context),
                    child: const Text('Cancel'),
                  ),
                ],
              );
            },
          );
        },
      );
    } else if (_selectedPeriod == 'Yearly') {
      // Custom Year Picker (2020-2025)
      await showDialog(
        context: context,
        builder: (context) {
          return SimpleDialog(
            title: const Text('Select Year'),
            children: List.generate(6, (index) {
              final year = 2025 - index; // 2025 down to 2020
              return SimpleDialogOption(
                onPressed: () {
                  setState(() => _selectedDate = DateTime(year));
                  Navigator.pop(context);
                },
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  child: Text(
                    year.toString(),
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: year == _selectedDate.year ? FontWeight.bold : FontWeight.normal,
                      color: year == _selectedDate.year ? AppColors.primary : Colors.black,
                    ),
                  ),
                ),
              );
            }),
          );
        },
      );
    }
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
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    final textColor = isDarkMode ? Colors.white : AppColors.text;
    final secondaryTextColor = isDarkMode ? Colors.white70 : AppColors.textSecondary;
    final cardColor = isDarkMode ? const Color(0xFF1E1E1E) : Colors.white;
    final surfaceColor = isDarkMode ? const Color(0xFF2C2C2C) : AppColors.surfaceVariant;

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        automaticallyImplyLeading: false,
        backgroundColor: Theme.of(context).scaffoldBackgroundColor,
        elevation: 0,
        centerTitle: true,
        title: Text(
          'Transaction',
          style: TextStyle(
            color: textColor,
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
                color: surfaceColor,
                borderRadius: BorderRadius.circular(20),
              ),
              child: Row(
                children: ['Daily', 'Weekly', 'Monthly', 'Yearly'].map((period) {
                  final isSelected = _selectedPeriod == period;
                  return Expanded(
                    child: GestureDetector(
                      onTap: () => setState(() => _selectedPeriod = period),
                      child: Container(
                        decoration: BoxDecoration(
                          color: isSelected ? cardColor : Colors.transparent,
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
                              color: isSelected ? textColor : secondaryTextColor,
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

          // Date Navigator
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 4),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                IconButton(
                  icon: const Icon(Icons.chevron_left),
                  onPressed: () => _navigateDate(-1),
                  color: textColor,
                ),
                Expanded(
                  child: GestureDetector(
                    onTap: _pickDate,
                    child: Container(
                      padding: const EdgeInsets.symmetric(vertical: 8),
                      alignment: Alignment.center,
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            _dateRangeText,
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                              color: textColor,
                            ),
                          ),
                          const SizedBox(width: 4),
                          Icon(Icons.arrow_drop_down, color: textColor),
                        ],
                      ),
                    ),
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.chevron_right),
                  onPressed: () => _navigateDate(1),
                  color: textColor,
                ),
              ],
            ),
          ),

          // Summary Card
          Container(
            margin: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: isDarkMode
                    ? [const Color(0xFF004D40), const Color(0xFF00796B)]
                    : [AppColors.primary, AppColors.primaryLight],
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
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    final textColor = isDarkMode ? Colors.white : AppColors.text;
    final secondaryTextColor = isDarkMode ? Colors.white70 : AppColors.textSecondary;
    final surfaceColor = isDarkMode ? const Color(0xFF2C2C2C) : AppColors.surfaceVariant;

    final dayIncome = transactions
        .where((t) => t.type == 'income')
        .fold(0.0, (sum, t) => sum + t.amount);
    final dayExpense = transactions
        .where((t) => t.type == 'expense')
        .fold(0.0, (sum, t) => sum + t.amount);

    final dayName = _getDayName(date);
    final monthName = DateFormat('MMMM').format(date);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 12),
          child: Row(
            children: [
              // Large date on the left
              Text(
                date.day.toString().padLeft(2, '0'),
                style: TextStyle(
                  fontSize: 25,
                  fontWeight: FontWeight.bold,
                  color: textColor,
                ),
              ),
              const SizedBox(width: 12),
              // Day and month stacked on the right
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    dayName,
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                      color: textColor,
                    ),
                  ),
                  Row(
                    children: [
                      Text(
                        monthName,
                        style: TextStyle(
                          fontSize: 12,
                          color: secondaryTextColor,
                        ),
                      ),
                      const SizedBox(width: 4),
                      Text(
                        date.year.toString(),
                        style: TextStyle(
                          fontSize: 12,
                          color: secondaryTextColor,
                        ),
                      ),
                    ],
                  ),
                ],
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
    final days = ['Sunday', 'Monday', 'Tuesday', 'Wednesday', 'Thursday', 'Friday', 'Saturday'];
    return days[date.weekday % 7];
  }

  Widget _buildTransactionItem(Transaction transaction) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    final textColor = isDarkMode ? Colors.white : AppColors.text;
    final secondaryTextColor = isDarkMode ? Colors.white70 : AppColors.textSecondary;
    final cardColor = isDarkMode ? const Color(0xFF1E1E1E) : Colors.white;

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
                        style: TextStyle(
                          fontSize: 12,
                          color: secondaryTextColor,
                        ),
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
        ),
      ),
    );
  }
}
