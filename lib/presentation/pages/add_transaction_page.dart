import 'package:flutter/material.dart';
import '../../data/models/transaction_model.dart';
import '../../data/models/category_model.dart';
import '../../data/services/local_storage_service.dart';
import '../../utils/constants.dart';
import '../../utils/formatters.dart';

class AddTransactionPage extends StatefulWidget {
  final LocalStorageService localStorage;
  final Transaction? transaction;

  const AddTransactionPage({
    super.key,
    required this.localStorage,
    this.transaction,
  });

  @override
  State<AddTransactionPage> createState() => _AddTransactionPageState();
}

class _AddTransactionPageState extends State<AddTransactionPage> {
  late String _transactionType = 'expense';
  late Category _selectedCategory;
  late DateTime _selectedDate = DateTime.now();
  late final TextEditingController _amountController;
  late final TextEditingController _descriptionController;
  List<Category> _categories = [];
  List<Category> _filteredCategories = [];
  String _displayAmount = '0';

  @override
  void initState() {
    super.initState();
    _amountController = TextEditingController(
      text: widget.transaction?.amount.toString() ?? '',
    );
    _descriptionController = TextEditingController(
      text: widget.transaction?.description ?? '',
    );
    if (widget.transaction != null) {
      _displayAmount = widget.transaction!.amount.toInt().toString();
    }
    _loadCategories();
  }

  Future<void> _loadCategories() async {
    _categories = await widget.localStorage.getCategories();
    _transactionType = widget.transaction?.type ?? 'expense';
    _updateFilteredCategories();
  }

  void _updateFilteredCategories() {
    _filteredCategories = _categories
        .where((c) => c.type == _transactionType)
        .toList();
    if (_filteredCategories.isNotEmpty) {
      _selectedCategory = _filteredCategories.first;
    }
    setState(() {});
  }

  Future<void> _selectDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime(2024),
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );
    if (picked != null) {
      setState(() {
        _selectedDate = picked;
      });
    }
  }

  void _onKeyPressed(String key) {
    setState(() {
      if (key == 'backspace') {
        if (_displayAmount.length > 1) {
          _displayAmount = _displayAmount.substring(0, _displayAmount.length - 1);
        } else {
          _displayAmount = '0';
        }
      } else if (key == 'done') {
        _saveTransaction();
      } else {
        if (_displayAmount == '0') {
          _displayAmount = key;
        } else if (_displayAmount.length < 12) {
          _displayAmount += key;
        }
      }
      _amountController.text = _displayAmount;
    });
  }

  void _saveTransaction() {
    final amount = double.tryParse(_displayAmount) ?? 0;
    if (amount <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Jumlah harus lebih dari 0')),
      );
      return;
    }

    if (widget.transaction == null) {
      final newTransaction = Transaction(
        id: DateTime.now().millisecondsSinceEpoch,
        accountId: 1,
        categoryId: _selectedCategory.id,
        type: _transactionType,
        amount: amount,
        date: _selectedDate,
        description: _descriptionController.text,
        createdAt: DateTime.now(),
        categoryName: _selectedCategory.name,
      );
      widget.localStorage.saveTransaction(newTransaction);
    } else {
      final updatedTransaction = widget.transaction!.copyWith(
        type: _transactionType,
        amount: amount,
        date: _selectedDate,
        description: _descriptionController.text,
        categoryId: _selectedCategory.id,
        categoryName: _selectedCategory.name,
      );
      widget.localStorage.updateTransaction(updatedTransaction);
    }

    Navigator.pop(context);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          widget.transaction == null
              ? 'Transaksi berhasil ditambahkan'
              : 'Transaksi berhasil diperbarui',
        ),
      ),
    );
  }

  @override
  void dispose() {
    _amountController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isExpense = _transactionType == 'expense';

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.background,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: AppColors.text),
          onPressed: () => Navigator.pop(context),
        ),
        centerTitle: true,
        title: Text(
          isExpense ? 'Expense' : 'Income',
          style: const TextStyle(
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
          // Toggle Expense/Income
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
            child: Container(
              height: 40,
              decoration: BoxDecoration(
                color: AppColors.surfaceVariant,
                borderRadius: BorderRadius.circular(20),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: GestureDetector(
                      onTap: () {
                        setState(() {
                          _transactionType = 'expense';
                          _updateFilteredCategories();
                        });
                      },
                      child: Container(
                        decoration: BoxDecoration(
                          color: isExpense ? AppColors.expense : Colors.transparent,
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Center(
                          child: Text(
                            'Expense',
                            style: TextStyle(
                              color: isExpense ? Colors.white : AppColors.textSecondary,
                              fontWeight: isExpense ? FontWeight.w600 : FontWeight.w400,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                  Expanded(
                    child: GestureDetector(
                      onTap: () {
                        setState(() {
                          _transactionType = 'income';
                          _updateFilteredCategories();
                        });
                      },
                      child: Container(
                        decoration: BoxDecoration(
                          color: !isExpense ? AppColors.primary : Colors.transparent,
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Center(
                          child: Text(
                            'Income',
                            style: TextStyle(
                              color: !isExpense ? Colors.white : AppColors.textSecondary,
                              fontWeight: !isExpense ? FontWeight.w600 : FontWeight.w400,
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

          // Form Fields
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Date Field
                  _buildFormField(
                    label: 'Tanggal',
                    child: GestureDetector(
                      onTap: _selectDate,
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            DateFormatter.formatDateWithDay(_selectedDate),
                            style: const TextStyle(
                              fontSize: 16,
                              color: AppColors.text,
                            ),
                          ),
                          const Icon(Icons.calendar_today, size: 20, color: AppColors.textSecondary),
                        ],
                      ),
                    ),
                  ),

                  // Amount Field
                  _buildFormField(
                    label: 'Total',
                    child: Text(
                      'Rp ${CurrencyFormatter.formatNumber(double.tryParse(_displayAmount) ?? 0)}',
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: isExpense ? AppColors.expense : AppColors.primary,
                      ),
                    ),
                  ),

                  // Category Field
                  _buildFormField(
                    label: 'Kategori',
                    child: _filteredCategories.isNotEmpty
                        ? DropdownButtonHideUnderline(
                            child: DropdownButton<Category>(
                              value: _selectedCategory,
                              isExpanded: true,
                              icon: const Icon(Icons.keyboard_arrow_down, color: AppColors.textSecondary),
                              items: _filteredCategories.map((category) {
                                return DropdownMenuItem<Category>(
                                  value: category,
                                  child: Text(
                                    category.name,
                                    style: const TextStyle(fontSize: 16, color: AppColors.text),
                                  ),
                                );
                              }).toList(),
                              onChanged: (category) {
                                if (category != null) {
                                  setState(() => _selectedCategory = category);
                                }
                              },
                            ),
                          )
                        : const Text('Loading...', style: TextStyle(color: AppColors.textSecondary)),
                  ),

                  // Description Field
                  _buildFormField(
                    label: 'Catatan',
                    child: TextField(
                      controller: _descriptionController,
                      decoration: const InputDecoration(
                        hintText: 'Tulis catatan...',
                        hintStyle: TextStyle(color: AppColors.textTertiary),
                        border: InputBorder.none,
                        isDense: true,
                        contentPadding: EdgeInsets.zero,
                      ),
                      style: const TextStyle(fontSize: 16, color: AppColors.text),
                    ),
                  ),
                ],
              ),
            ),
          ),

          // Numeric Keypad
          Container(
            padding: const EdgeInsets.all(16),
            color: AppColors.surface,
            child: Column(
              children: [
                Row(
                  children: [
                    _buildKeypadButton('1'),
                    _buildKeypadButton('2'),
                    _buildKeypadButton('3'),
                  ],
                ),
                Row(
                  children: [
                    _buildKeypadButton('4'),
                    _buildKeypadButton('5'),
                    _buildKeypadButton('6'),
                  ],
                ),
                Row(
                  children: [
                    _buildKeypadButton('7'),
                    _buildKeypadButton('8'),
                    _buildKeypadButton('9'),
                  ],
                ),
                Row(
                  children: [
                    _buildKeypadButton('000'),
                    _buildKeypadButton('0'),
                    _buildKeypadButton('backspace', icon: Icons.backspace_outlined),
                  ],
                ),
                const SizedBox(height: 8),
                SizedBox(
                  width: double.infinity,
                  height: 50,
                  child: ElevatedButton(
                    onPressed: _saveTransaction,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: Text(
                      widget.transaction == null ? 'Simpan' : 'Update',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFormField({required String label, required Widget child}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: const TextStyle(
              fontSize: 13,
              color: AppColors.textSecondary,
            ),
          ),
          const SizedBox(height: 8),
          child,
          const Divider(height: 1, color: AppColors.border),
        ],
      ),
    );
  }

  Widget _buildKeypadButton(String value, {IconData? icon}) {
    return Expanded(
      child: GestureDetector(
        onTap: () => _onKeyPressed(value),
        child: Container(
          height: 56,
          margin: const EdgeInsets.all(4),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Center(
            child: icon != null
                ? Icon(icon, color: AppColors.text, size: 24)
                : Text(
                    value,
                    style: const TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.w500,
                      color: AppColors.text,
                    ),
                  ),
          ),
        ),
      ),
    );
  }
}
