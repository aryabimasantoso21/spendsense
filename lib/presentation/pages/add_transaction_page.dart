import 'package:flutter/material.dart';
import '../../data/models/transaction_model.dart';
import '../../data/models/category_model.dart';
import '../../data/models/account_model.dart';
import '../../data/services/local_storage_service.dart';
import '../../data/services/supabase_service.dart';
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
  final SupabaseService _supabase = SupabaseService.instance;
  
  String _transactionType = 'expense'; // expense, income, transfer
  Category? _selectedCategory;
  Account? _selectedAccount;
  Account? _destinationAccount; // For transfers
  DateTime _selectedDate = DateTime.now();
  late final TextEditingController _amountController;
  late final TextEditingController _descriptionController;
  
  List<Category> _categories = [];
  List<Category> _filteredCategories = [];
  List<Account> _accounts = [];
  String _displayAmount = '0';
  bool _isLoading = false;
  bool _isDataLoading = true;

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
      _transactionType = widget.transaction!.type;
      _selectedDate = widget.transaction!.date;
    }
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() => _isDataLoading = true);
    try {
      // Try to load from Supabase first
      _categories = await _supabase.getCategories();
      _accounts = await _supabase.getAccounts();
    } catch (e) {
      // Fallback to local storage
      _categories = await widget.localStorage.getCategories();
      _accounts = await widget.localStorage.getAccounts();
    }
    
    _updateFilteredCategories();
    
    // Set default account
    if (_accounts.isNotEmpty) {
      if (widget.transaction != null) {
        _selectedAccount = _accounts.firstWhere(
          (a) => a.id == widget.transaction!.accountId,
          orElse: () => _accounts.first,
        );
        if (widget.transaction!.destinationAccountId != null) {
          _destinationAccount = _accounts.firstWhere(
            (a) => a.id == widget.transaction!.destinationAccountId,
            orElse: () => _accounts.first,
          );
        }
      } else {
        _selectedAccount = _accounts.first;
      }
    }
    
    if (mounted) setState(() => _isDataLoading = false);
  }

  void _updateFilteredCategories() {
    if (_transactionType == 'transfer') {
      _filteredCategories = [];
      _selectedCategory = null;
    } else {
      _filteredCategories = _categories
          .where((c) => c.type == _transactionType)
          .toList();
      if (_filteredCategories.isNotEmpty) {
        if (widget.transaction != null) {
          _selectedCategory = _filteredCategories.firstWhere(
            (c) => c.id == widget.transaction!.categoryId,
            orElse: () => _filteredCategories.first,
          );
        } else {
          _selectedCategory = _filteredCategories.first;
        }
      }
    }
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

  Future<void> _saveTransaction() async {
    final amount = double.tryParse(_displayAmount) ?? 0;
    if (amount <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Jumlah harus lebih dari 0')),
      );
      return;
    }

    if (_selectedAccount == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Pilih akun terlebih dahulu')),
      );
      return;
    }

    if (_transactionType == 'transfer' && _destinationAccount == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Pilih akun tujuan transfer')),
      );
      return;
    }

    if (_transactionType == 'transfer' && _selectedAccount!.id == _destinationAccount!.id) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Akun asal dan tujuan tidak boleh sama')),
      );
      return;
    }

    if (_transactionType != 'transfer' && _selectedCategory == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Pilih kategori terlebih dahulu')),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      if (widget.transaction == null) {
        // Create new transaction
        final newTransaction = Transaction(
          id: DateTime.now().millisecondsSinceEpoch,
          accountId: _selectedAccount!.id,
          destinationAccountId: _transactionType == 'transfer' ? _destinationAccount!.id : null,
          categoryId: _selectedCategory?.id ?? 0,
          type: _transactionType,
          amount: amount,
          date: _selectedDate,
          description: _descriptionController.text,
          createdAt: DateTime.now(),
          categoryName: _selectedCategory?.name,
          accountName: _selectedAccount!.name,
          destinationAccountName: _destinationAccount?.name,
        );
        
        // Save to Supabase
        await _supabase.saveTransaction(newTransaction);
        // Also save locally for offline access
        await widget.localStorage.saveTransaction(newTransaction);
      } else {
        // Update existing transaction
        final updatedTransaction = widget.transaction!.copyWith(
          type: _transactionType,
          amount: amount,
          date: _selectedDate,
          description: _descriptionController.text,
          categoryId: _selectedCategory?.id ?? 0,
          categoryName: _selectedCategory?.name,
          accountId: _selectedAccount!.id,
          accountName: _selectedAccount!.name,
          destinationAccountId: _transactionType == 'transfer' ? _destinationAccount?.id : null,
          destinationAccountName: _destinationAccount?.name,
        );
        
        await _supabase.updateTransaction(updatedTransaction);
        await widget.localStorage.updateTransaction(updatedTransaction);
      }

      if (mounted) {
        Navigator.pop(context, true); // Return true to indicate data changed
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
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
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
        backgroundColor: AppColors.background,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: AppColors.text),
          onPressed: () => Navigator.pop(context),
        ),
        centerTitle: true,
        title: Text(
          _transactionType == 'expense' 
              ? 'Expense' 
              : _transactionType == 'income' 
                  ? 'Income' 
                  : 'Transfer',
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
          // Toggle Expense/Income/Transfer
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
                  _buildTypeTab('Expense', 'expense', AppColors.expense),
                  _buildTypeTab('Income', 'income', AppColors.primary),
                  _buildTypeTab('Transfer', 'transfer', AppColors.cardBlue),
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
                        color: _transactionType == 'expense' 
                            ? AppColors.expense 
                            : _transactionType == 'income'
                                ? AppColors.primary
                                : AppColors.cardBlue,
                      ),
                    ),
                  ),

                  // Source Account Field
                  _buildFormField(
                    label: _transactionType == 'transfer' ? 'Dari Akun' : 'Akun',
                    child: _isDataLoading
                        ? const Text('Loading...', style: TextStyle(color: AppColors.textSecondary))
                        : _accounts.isNotEmpty
                            ? DropdownButtonHideUnderline(
                                child: DropdownButton<Account>(
                                  value: _selectedAccount,
                                  isExpanded: true,
                                  icon: const Icon(Icons.keyboard_arrow_down, color: AppColors.textSecondary),
                                  items: _accounts
                                      .where((a) => _transactionType != 'transfer' || a.id != _destinationAccount?.id)
                                      .map((account) {
                                    return DropdownMenuItem<Account>(
                                      value: account,
                                      child: Row(
                                        children: [
                                          Icon(_getAccountIcon(account.type), size: 20, color: AppColors.primary),
                                          const SizedBox(width: 12),
                                          Text(
                                            account.name,
                                            style: const TextStyle(fontSize: 16, color: AppColors.text),
                                          ),
                                          const Spacer(),
                                          Text(
                                            CurrencyFormatter.formatCurrency(account.balance),
                                            style: const TextStyle(fontSize: 12, color: AppColors.textSecondary),
                                          ),
                                        ],
                                      ),
                                    );
                                  }).toList(),
                                  onChanged: (account) {
                                    if (account != null) {
                                      setState(() => _selectedAccount = account);
                                    }
                                  },
                                ),
                              )
                            : const Text('Belum ada akun', style: TextStyle(color: AppColors.textSecondary)),
                  ),

                  // Destination Account Field (for transfers)
                  if (_transactionType == 'transfer')
                    _buildFormField(
                      label: 'Ke Akun',
                      child: _accounts.isNotEmpty
                          ? DropdownButtonHideUnderline(
                              child: DropdownButton<Account>(
                                value: _destinationAccount,
                                isExpanded: true,
                                hint: const Text('Pilih akun tujuan'),
                                icon: const Icon(Icons.keyboard_arrow_down, color: AppColors.textSecondary),
                                items: _accounts
                                    .where((a) => a.id != _selectedAccount?.id)
                                    .map((account) {
                                  return DropdownMenuItem<Account>(
                                    value: account,
                                    child: Row(
                                      children: [
                                        Icon(_getAccountIcon(account.type), size: 20, color: AppColors.cardBlue),
                                        const SizedBox(width: 12),
                                        Text(
                                          account.name,
                                          style: const TextStyle(fontSize: 16, color: AppColors.text),
                                        ),
                                        const Spacer(),
                                        Text(
                                          CurrencyFormatter.formatCurrency(account.balance),
                                          style: const TextStyle(fontSize: 12, color: AppColors.textSecondary),
                                        ),
                                      ],
                                    ),
                                  );
                                }).toList(),
                                onChanged: (account) {
                                  if (account != null) {
                                    setState(() => _destinationAccount = account);
                                  }
                                },
                              ),
                            )
                          : const Text('Belum ada akun', style: TextStyle(color: AppColors.textSecondary)),
                    ),

                  // Category Field (not for transfers)
                  if (_transactionType != 'transfer')
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
                    onPressed: _isLoading ? null : _saveTransaction,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: _isLoading
                        ? const SizedBox(
                            height: 20,
                            width: 20,
                            child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                          )
                        : Text(
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

  Widget _buildTypeTab(String label, String type, Color activeColor) {
    final isSelected = _transactionType == type;
    return Expanded(
      child: GestureDetector(
        onTap: () {
          setState(() {
            _transactionType = type;
            _updateFilteredCategories();
          });
        },
        child: Container(
          decoration: BoxDecoration(
            color: isSelected ? activeColor : Colors.transparent,
            borderRadius: BorderRadius.circular(20),
          ),
          child: Center(
            child: Text(
              label,
              style: TextStyle(
                fontSize: 13,
                color: isSelected ? Colors.white : AppColors.textSecondary,
                fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
              ),
            ),
          ),
        ),
      ),
    );
  }

  IconData _getAccountIcon(String type) {
    switch (type) {
      case 'bank':
        return Icons.account_balance;
      case 'ewallet':
        return Icons.phone_android;
      case 'cash':
        return Icons.money;
      case 'savings':
        return Icons.savings;
      default:
        return Icons.wallet;
    }
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
