import 'package:flutter/material.dart';
import '../../data/models/account_model.dart';
import '../../data/services/local_storage_service.dart';
import '../../utils/constants.dart';

class AddAccountPage extends StatefulWidget {
  const AddAccountPage({super.key});

  @override
  State<AddAccountPage> createState() => _AddAccountPageState();
}

class _AddAccountPageState extends State<AddAccountPage> {
  final LocalStorageService _localStorage = LocalStorageService.instance;
  late final TextEditingController _nameController;
  late final TextEditingController _balanceController;
  String _selectedType = 'cash';

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController();
    _balanceController = TextEditingController();
    _initStorage();
  }

  Future<void> _initStorage() async {
    await _localStorage.init();
  }

  void _saveAccount() {
    if (_nameController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Nama akun tidak boleh kosong')),
      );
      return;
    }

    final balance =
        double.tryParse(_balanceController.text.isEmpty ? '0' : _balanceController.text) ?? 0;

    final newAccount = Account(
      id: DateTime.now().millisecondsSinceEpoch,
      name: _nameController.text,
      type: _selectedType,
      balance: balance,
      createdAt: DateTime.now(),
    );

    _localStorage.saveAccount(newAccount);
    Navigator.pop(context, true);
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Akun berhasil ditambahkan')),
    );
  }

  @override
  void dispose() {
    _nameController.dispose();
    _balanceController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Tambah Akun'),
        backgroundColor: AppColors.primary,
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(AppPadding.md),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Account Name
            Text(
              'Nama Akun',
              style: AppTextStyles.subtitle,
            ),
            const SizedBox(height: AppPadding.sm),
            TextField(
              controller: _nameController,
              decoration: InputDecoration(
                hintText: 'Contoh: BCA, OVO, Tunai',
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

            // Account Type
            Text(
              'Tipe Akun',
              style: AppTextStyles.subtitle,
            ),
            const SizedBox(height: AppPadding.md),
            Wrap(
              spacing: AppPadding.md,
              runSpacing: AppPadding.md,
              children: [
                _buildTypeButton('Tunai', 'cash'),
                _buildTypeButton('Bank', 'bank'),
                _buildTypeButton('E-Wallet', 'ewallet'),
                _buildTypeButton('Tabungan', 'savings'),
              ],
            ),
            const SizedBox(height: AppPadding.lg),

            // Initial Balance
            Text(
              'Saldo Awal (Opsional)',
              style: AppTextStyles.subtitle,
            ),
            const SizedBox(height: AppPadding.sm),
            TextField(
              controller: _balanceController,
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

            // Save Button
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _saveAccount,
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
                  'Tambah Akun',
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
          vertical: AppPadding.sm,
        ),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.primary : AppColors.surface,
          borderRadius: BorderRadius.circular(AppBorderRadius.md),
          border: Border.all(
            color: isSelected ? AppColors.primary : AppColors.border,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              accountTypeIcons[value] ?? '💼',
              style: const TextStyle(fontSize: 20),
            ),
            const SizedBox(width: AppPadding.sm),
            Text(
              label,
              style: AppTextStyles.body.copyWith(
                color: isSelected ? Colors.white : AppColors.text,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
