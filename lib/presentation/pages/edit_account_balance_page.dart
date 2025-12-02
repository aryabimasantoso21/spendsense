import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../data/models/account_model.dart';
import '../../data/models/transaction_model.dart';
import '../../data/services/local_storage_service.dart';
import '../../data/services/supabase_service.dart';
import '../../utils/constants.dart';
import '../../utils/formatters.dart';

class EditAccountBalancePage extends StatefulWidget {
  final Account account;
  final LocalStorageService localStorage;

  const EditAccountBalancePage({
    super.key,
    required this.account,
    required this.localStorage,
  });

  @override
  State<EditAccountBalancePage> createState() => _EditAccountBalancePageState();
}

class _EditAccountBalancePageState extends State<EditAccountBalancePage> {
  final _formKey = GlobalKey<FormState>();
  final _amountController = TextEditingController();
  final SupabaseService _supabase = SupabaseService.instance;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _amountController.text = widget.account.balance.toStringAsFixed(0);
  }

  @override
  void dispose() {
    _amountController.dispose();
    super.dispose();
  }

  Future<void> _showUpdateMethodDialog() async {
    if (!_formKey.currentState!.validate()) return;

    final newBalance = double.parse(_amountController.text);
    final difference = newBalance - widget.account.balance;

    if (difference == 0) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Tidak ada perubahan saldo')),
        );
      }
      return;
    }

    final result = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text(
          'Pilih Metode Update',
          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Saldo akan berubah dari ${CurrencyFormatter.formatCurrency(widget.account.balance)} menjadi ${CurrencyFormatter.formatCurrency(newBalance)}',
              style: const TextStyle(fontSize: 14, color: AppColors.textSecondary),
            ),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: (difference > 0 ? AppColors.income : AppColors.expense).withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    difference > 0 ? Icons.arrow_upward : Icons.arrow_downward,
                    color: difference > 0 ? AppColors.income : AppColors.expense,
                    size: 20,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    '${difference > 0 ? '+' : ''}${CurrencyFormatter.formatCurrency(difference.abs())}',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: difference > 0 ? AppColors.income : AppColors.expense,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),
            _buildMethodButton(
              icon: Icons.edit_outlined,
              title: 'Update Initial Amount',
              description: 'Ubah saldo awal tanpa mencatat transaksi',
              color: AppColors.primary,
              onTap: () => Navigator.pop(context, 'direct'),
            ),
            const SizedBox(height: 12),
            _buildMethodButton(
              icon: Icons.sync_alt,
              title: 'Adjustment Transaction',
              description: 'Catat perubahan sebagai transaksi',
              color: AppColors.income,
              onTap: () => Navigator.pop(context, 'adjustment'),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Batal'),
          ),
        ],
      ),
    );

    if (result != null) {
      await _updateBalance(result, newBalance, difference);
    }
  }

  Widget _buildMethodButton({
    required IconData icon,
    required String title,
    required String description,
    required Color color,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          border: Border.all(color: AppColors.border),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(icon, color: color, size: 24),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      fontWeight: FontWeight.w600,
                      fontSize: 15,
                      color: AppColors.text,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    description,
                    style: const TextStyle(
                      fontSize: 12,
                      color: AppColors.textSecondary,
                    ),
                  ),
                ],
              ),
            ),
            Icon(Icons.arrow_forward_ios, size: 16, color: AppColors.textTertiary),
          ],
        ),
      ),
    );
  }

  Future<void> _updateBalance(String method, double newBalance, double difference) async {
    setState(() => _isLoading = true);

    try {
      if (method == 'direct') {
        // Update langsung
        final updatedAccount = widget.account.copyWith(balance: newBalance);
        await _supabase.updateAccount(updatedAccount);
        await widget.localStorage.saveAccount(updatedAccount);

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Saldo berhasil diupdate')),
          );
          Navigator.pop(context, true);
        }
      } else {        
        final categoryId = difference > 0 ? 14 : 15;
        final categoryType = difference > 0 ? 'income' : 'expense';
        
        final transaction = Transaction(
          id: DateTime.now().millisecondsSinceEpoch,
          accountId: widget.account.id,
          categoryId: categoryId,
          type: categoryType,
          amount: difference.abs(),
          date: DateTime.now(),
          description: 'Balance adjustment',
          createdAt: DateTime.now(),
        );

        await _supabase.saveTransaction(transaction);
        await widget.localStorage.saveTransaction(transaction);

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Transaksi berhasil dibuat')),
          );
          Navigator.pop(context, true);
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e')),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
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
        title: const Text(
          'Edit Saldo Akun',
          style: TextStyle(
            color: AppColors.text,
            fontSize: 18,
            fontWeight: FontWeight.w600,
          ),
        ),
        centerTitle: true,
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(24),
          children: [
            // Account Info Card
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [AppColors.primary, AppColors.primaryDark],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: AppColors.primary.withValues(alpha: 0.3),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Text(
                        accountTypeIcons[widget.account.type] ?? '💼',
                        style: const TextStyle(fontSize: 32),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              widget.account.name,
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              accountTypeNames[widget.account.type] ?? 'Akun',
                              style: const TextStyle(
                                color: Colors.white70,
                                fontSize: 14,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    'Saldo Saat Ini',
                    style: TextStyle(
                      color: Colors.white60,
                      fontSize: 12,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    CurrencyFormatter.formatCurrency(widget.account.balance),
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 28,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 32),

            // Amount Input
            const Text(
              'Saldo Baru',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: AppColors.text,
              ),
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _amountController,
              keyboardType: TextInputType.number,
              inputFormatters: [FilteringTextInputFormatter.digitsOnly],
              style: const TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: AppColors.text,
              ),
              decoration: InputDecoration(
                hintText: '0',
                prefixText: 'Rp ',
                prefixStyle: const TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: AppColors.textSecondary,
                ),
                filled: true,
                fillColor: Colors.white,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(color: AppColors.border),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(color: AppColors.border),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(color: AppColors.primary, width: 2),
                ),
              ),
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Masukkan jumlah saldo';
                }
                final amount = double.tryParse(value);
                if (amount == null || amount < 0) {
                  return 'Jumlah tidak valid';
                }
                return null;
              },
            ),

            const SizedBox(height: 32),

            // Save Button
            SizedBox(
              height: 56,
              child: ElevatedButton(
                onPressed: _isLoading ? null : _showUpdateMethodDialog,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  elevation: 0,
                ),
                child: _isLoading
                    ? const SizedBox(
                        height: 24,
                        width: 24,
                        child: CircularProgressIndicator(
                          color: Colors.white,
                          strokeWidth: 2,
                        ),
                      )
                    : const Text(
                        'Update Saldo',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
