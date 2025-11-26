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

  @override
  void initState() {
    super.initState();
    _amountController = TextEditingController(
      text: widget.transaction?.amount.toString() ?? '',
    );
    _descriptionController = TextEditingController(
      text: widget.transaction?.description ?? '',
    );
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

  void _saveTransaction() {
    if (_amountController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Jumlah tidak boleh kosong')),
      );
      return;
    }

    final amount = double.tryParse(_amountController.text) ?? 0;
    if (amount <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Jumlah harus lebih dari 0')),
      );
      return;
    }

    if (widget.transaction == null) {
      // Create new transaction
      final newTransaction = Transaction(
        id: DateTime.now().millisecondsSinceEpoch,
        accountId: 1, // Default to first account
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
      // Update existing transaction
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
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text(widget.transaction == null
            ? 'Tambah Transaksi'
            : 'Edit Transaksi'),
        backgroundColor: AppColors.primary,
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(AppPadding.md),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Transaction Type Selection
            Text(
              'Tipe Transaksi',
              style: AppTextStyles.subtitle,
            ),
            const SizedBox(height: AppPadding.md),
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

            // Amount Input
            Text(
              'Jumlah (Rp)',
              style: AppTextStyles.subtitle,
            ),
            const SizedBox(height: AppPadding.sm),
            TextField(
              controller: _amountController,
              keyboardType: TextInputType.number,
              decoration: InputDecoration(
                hintText: '0',
                prefixText: 'Rp ',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(AppBorderRadius.md),
                ),
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: AppPadding.md,
                  vertical: AppPadding.md,
                ),
              ),
              style: AppTextStyles.body,
            ),
            const SizedBox(height: AppPadding.lg),

            // Category Selection
            Text(
              'Kategori',
              style: AppTextStyles.subtitle,
            ),
            const SizedBox(height: AppPadding.sm),
            if (_filteredCategories.isNotEmpty)
              Container(
                decoration: BoxDecoration(
                  border: Border.all(color: AppColors.border),
                  borderRadius: BorderRadius.circular(AppBorderRadius.md),
                ),
                child: DropdownButton<Category>(
                  value: _selectedCategory,
                  isExpanded: true,
                  underline: const SizedBox.shrink(),
                  items: _filteredCategories.map((category) {
                    return DropdownMenuItem<Category>(
                      value: category,
                      child: Padding(
                        padding: const EdgeInsets.symmetric(
                          horizontal: AppPadding.md,
                          vertical: AppPadding.sm,
                        ),
                        child: Row(
                          children: [
                            Text(
                              categoryIcons[category.name] ?? '📌',
                              style: const TextStyle(fontSize: 20),
                            ),
                            const SizedBox(width: AppPadding.md),
                            Text(category.name),
                          ],
                        ),
                      ),
                    );
                  }).toList(),
                  onChanged: (category) {
                    if (category != null) {
                      setState(() {
                        _selectedCategory = category;
                      });
                    }
                  },
                ),
              ),
            const SizedBox(height: AppPadding.lg),

            // Date Selection
            Text(
              'Tanggal',
              style: AppTextStyles.subtitle,
            ),
            const SizedBox(height: AppPadding.sm),
            GestureDetector(
              onTap: _selectDate,
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: AppPadding.md,
                  vertical: AppPadding.md,
                ),
                decoration: BoxDecoration(
                  border: Border.all(color: AppColors.border),
                  borderRadius: BorderRadius.circular(AppBorderRadius.md),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      DateFormatter.formatDateWithDay(_selectedDate),
                      style: AppTextStyles.body,
                    ),
                    const Icon(Icons.calendar_today),
                  ],
                ),
              ),
            ),
            const SizedBox(height: AppPadding.lg),

            // Description Input
            Text(
              'Keterangan (Opsional)',
              style: AppTextStyles.subtitle,
            ),
            const SizedBox(height: AppPadding.sm),
            TextField(
              controller: _descriptionController,
              maxLines: 3,
              decoration: InputDecoration(
                hintText: 'Tulis keterangan transaksi...',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(AppBorderRadius.md),
                ),
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: AppPadding.md,
                  vertical: AppPadding.md,
                ),
              ),
              style: AppTextStyles.body,
            ),
            const SizedBox(height: AppPadding.lg),

            // Save Button
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _saveTransaction,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  padding: const EdgeInsets.symmetric(
                    vertical: AppPadding.md,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(AppBorderRadius.md),
                  ),
                ),
                child: Text(
                  widget.transaction == null ? 'Tambah' : 'Update',
                  style: AppTextStyles.subtitle.copyWith(
                    color: Colors.white,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTypeButton(String label, String value) {
    final isSelected = _transactionType == value;
    return GestureDetector(
      onTap: () {
        setState(() {
          _transactionType = value;
          _updateFilteredCategories();
        });
      },
      child: Container(
        padding: const EdgeInsets.symmetric(
          horizontal: AppPadding.md,
          vertical: AppPadding.md,
        ),
        decoration: BoxDecoration(
          color: isSelected
              ? (value == 'expense' ? AppColors.expense : AppColors.income)
              : AppColors.surface,
          borderRadius: BorderRadius.circular(AppBorderRadius.md),
          border: Border.all(
            color: isSelected
                ? (value == 'expense' ? AppColors.expense : AppColors.income)
                : AppColors.border,
          ),
        ),
        child: Center(
          child: Text(
            label,
            style: AppTextStyles.subtitle.copyWith(
              color: isSelected ? Colors.white : AppColors.text,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
      ),
    );
  }
}
