import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import '../../data/models/transaction_model.dart';
import '../../data/models/category_model.dart';
import '../../data/services/local_storage_service.dart';
import '../../data/services/supabase_service.dart';
import '../../utils/constants.dart';
import '../../utils/formatters.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class StatisticsPage extends StatefulWidget {
  final LocalStorageService localStorage;
  final VoidCallback? onDataChanged;

  const StatisticsPage({
    super.key, 
    required this.localStorage,
    this.onDataChanged,
  });

  @override
  State<StatisticsPage> createState() => _StatisticsPageState();
}

class _StatisticsPageState extends State<StatisticsPage> {
  final SupabaseService _supabase = SupabaseService.instance;
  RealtimeChannel? _txnChannel;
  
  List<Transaction> _transactions = [];
  List<Category> _categories = [];
  String _selectedType = 'expense';
  String _selectedPeriod = 'Monthly';

  final List<Color> _categoryColors = [
    const Color(0xFFF5A572), // Orange/Coral
    const Color(0xFFE57373), // Red
    const Color(0xFFB3E5FC), // Light Blue
    const Color(0xFF64B5F6), // Blue
    const Color(0xFF81C784), // Green
    const Color(0xFFBA68C8), // Purple
    const Color(0xFFFFD54F), // Yellow
    const Color(0xFF4DB6AC), // Teal
  ];

  @override
  void initState() {
    super.initState();
    _loadData();
    _setupRealtime();
  }

  @override
  void didUpdateWidget(StatisticsPage oldWidget) {
    super.didUpdateWidget(oldWidget);
    // Reload data when parent triggers an update
    _loadData();
  }

  void _setupRealtime() {
    try {
      _txnChannel = _supabase.client.channel('public:transactions');
      _txnChannel!.onPostgresChanges(
        event: PostgresChangeEvent.all,
        schema: 'public',
        table: 'transactions',
        callback: (payload) async {
          await _loadData();
          if (widget.onDataChanged != null) widget.onDataChanged!();
        },
      );
      _txnChannel!.subscribe();
    } catch (_) {
      // ignore realtime setup errors; page still works with pull-to-refresh
    }
  }

  @override
  void dispose() {
    try {
      if (_txnChannel != null) {
        _supabase.client.removeChannel(_txnChannel!);
      }
    } catch (_) {}
    super.dispose();
  }

  Future<void> _loadData() async {
    try {
      // Try Supabase first
      _transactions = await _supabase.getTransactions();
      _categories = await _supabase.getCategories();
    } catch (e) {
      // Fallback to local storage
      _transactions = await widget.localStorage.getTransactions();
      _categories = await widget.localStorage.getCategories();
    }
    if (mounted) setState(() {});
  }

  List<Transaction> get _filteredTransactions {
    final now = DateTime.now();
    var filtered = _transactions.where((t) => t.type == _selectedType).toList();
    
    // Filter by period
    switch (_selectedPeriod) {
      case 'Daily':
        filtered = filtered.where((t) => 
          t.date.year == now.year && 
          t.date.month == now.month && 
          t.date.day == now.day
        ).toList();
        break;
      case 'Weekly':
        final weekStart = now.subtract(Duration(days: now.weekday - 1));
        filtered = filtered.where((t) => 
          t.date.isAfter(weekStart.subtract(const Duration(days: 1)))
        ).toList();
        break;
      case 'Monthly':
        filtered = filtered.where((t) => 
          t.date.year == now.year && t.date.month == now.month
        ).toList();
        break;
      case 'Yearly':
        filtered = filtered.where((t) => t.date.year == now.year).toList();
        break;
    }
    
    return filtered;
  }

  Map<String, double> get _categoryTotals {
    final totals = <String, double>{};
    for (var transaction in _filteredTransactions) {
      // Prefer explicit categoryName if present (Supabase may not store categoryId)
      final resolvedName = (transaction.categoryName != null && transaction.categoryName!.trim().isNotEmpty)
          ? transaction.categoryName!.trim()
          : _categories.firstWhere(
              (c) => c.id == transaction.categoryId,
              orElse: () => const Category(id: 0, type: '', name: 'Lainnya'),
            ).name;

      totals[resolvedName] = (totals[resolvedName] ?? 0) + transaction.amount;
    }
    return totals;
  }

  double get _totalAmount => _filteredTransactions.fold(0, (sum, t) => sum + t.amount);

  @override
  Widget build(BuildContext context) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    final textColor = isDarkMode ? Colors.white : AppColors.text;
    final secondaryTextColor = isDarkMode ? Colors.white70 : AppColors.textSecondary;
    final surfaceColor = isDarkMode ? const Color(0xFF2C2C2C) : AppColors.surfaceVariant;
    final borderColor = isDarkMode ? Colors.white24 : AppColors.border;

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        automaticallyImplyLeading: false,
        backgroundColor: Theme.of(context).scaffoldBackgroundColor,
        elevation: 0,
        centerTitle: true,
        title: Text(
          'Statistics',
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
      body: RefreshIndicator(
        onRefresh: _loadData,
        color: AppColors.primary,
        child: ListView(
          children: [
            // Toggle Expense/Income
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
              child: Container(
                height: 44,
                decoration: BoxDecoration(
                  color: surfaceColor,
                  borderRadius: BorderRadius.circular(22),
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: GestureDetector(
                        onTap: () => setState(() => _selectedType = 'expense'),
                        child: Container(
                          decoration: BoxDecoration(
                            color: _selectedType == 'expense' 
                                ? AppColors.expense 
                                : Colors.transparent,
                            borderRadius: BorderRadius.circular(22),
                          ),
                          child: Center(
                            child: Text(
                              'Expense',
                              style: TextStyle(
                                color: _selectedType == 'expense' 
                                    ? Colors.white 
                                    : secondaryTextColor,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                    Expanded(
                      child: GestureDetector(
                        onTap: () => setState(() => _selectedType = 'income'),
                        child: Container(
                          decoration: BoxDecoration(
                            color: _selectedType == 'income' 
                                ? AppColors.primary 
                                : Colors.transparent,
                            borderRadius: BorderRadius.circular(22),
                          ),
                          child: Center(
                            child: Text(
                              'Income',
                              style: TextStyle(
                                color: _selectedType == 'income' 
                                    ? Colors.white 
                                    : secondaryTextColor,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),

            // Period Dropdown
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                decoration: BoxDecoration(
                  border: Border.all(color: borderColor),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: DropdownButton<String>(
                  value: _selectedPeriod,
                  isExpanded: true,
                  underline: const SizedBox(),
                  icon: const Icon(Icons.keyboard_arrow_down),
                  items: ['Daily', 'Weekly', 'Monthly', 'Yearly']
                      .map((e) => DropdownMenuItem(value: e, child: Text(e)))
                      .toList(),
                  onChanged: (value) => setState(() => _selectedPeriod = value!),
                ),
              ),
            ),

            // Donut Chart with center text
            SizedBox(
              height: 220,
              child: Stack(
                alignment: Alignment.center,
                children: [
                  PieChart(
                    PieChartData(
                      sections: _buildPieChartSections(),
                      sectionsSpace: 3,
                      centerSpaceRadius: 60,
                      startDegreeOffset: -90,
                    ),
                  ),
                  Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        'Total ${_selectedType == 'expense' ? 'Expense' : 'Income'}',
                        style: TextStyle(
                          fontSize: 12,
                          color: secondaryTextColor,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        CurrencyFormatter.formatCurrency(_totalAmount),
                        style: TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.bold,
                          color: textColor,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),

            // Category List
            if (_categoryTotals.isEmpty)
              Padding(
                padding: const EdgeInsets.all(32),
                child: Center(
                  child: Text(
                    'Tidak ada data',
                    style: TextStyle(color: secondaryTextColor),
                  ),
                ),
              )
            else
              ...List.generate(_categoryTotals.length, (index) {
                final entry = _categoryTotals.entries.elementAt(index);
                final color = _categoryColors[index % _categoryColors.length];
                return Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 24),
                  child: _buildCategoryItem(entry.key, entry.value, color),
                );
              }),
            
            const SizedBox(height: 80), // Space for FAB
          ],
        ),
      ),
      // FAB is handled by HomePage
    );
  }

  List<PieChartSectionData> _buildPieChartSections() {
    if (_categoryTotals.isEmpty) {
      return [
        PieChartSectionData(
          value: 1,
          color: AppColors.border,
          radius: 25,
          showTitle: false,
        ),
      ];
    }

    int colorIndex = 0;
    return _categoryTotals.entries.map((entry) {
      final color = _categoryColors[colorIndex % _categoryColors.length];
      colorIndex++;
      return PieChartSectionData(
        value: entry.value,
        color: color,
        radius: 25,
        showTitle: false,
      );
    }).toList();
  }

  Widget _buildCategoryItem(String name, double amount, Color color) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    final textColor = isDarkMode ? Colors.white : AppColors.text;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 12),
      child: Row(
        children: [
          Container(
            width: 10,
            height: 10,
            decoration: BoxDecoration(
              color: color,
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Text(
              name,
              style: TextStyle(
                fontSize: 16,
                color: textColor,
              ),
            ),
          ),
          Text(
            CurrencyFormatter.formatCurrency(amount),
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: _selectedType == 'expense' ? AppColors.expense : AppColors.primary,
            ),
          ),
        ],
      ),
    );
  }
}
