import 'package:flutter/material.dart';
import '../../data/services/local_storage_service.dart';
import '../../utils/constants.dart';

class SettingsPage extends StatefulWidget {
  final LocalStorageService localStorage;

  const SettingsPage({
    super.key,
    required this.localStorage,
  });

  @override
  State<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage> {
  String _language = 'id';
  String _dateFormat = 'dd/MM/yyyy';
  String _currency = 'IDR';
  String _theme = 'light';

  @override
  void initState() {
    super.initState();
    _loadSettings();
  }

Future<void> _loadSettings() async {
    await widget.localStorage.init();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Pengaturan'),
        backgroundColor: AppColors.primary,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(AppPadding.md),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            // Logo
            SizedBox(
              height: 80,
              child: Image.asset(
                'img/logo.png',
                fit: BoxFit.contain,
              ),
            ),
            const SizedBox(height: AppPadding.lg),

            // General Settings Section
            Align(
              alignment: Alignment.centerLeft,
              child: Text(
                'Pengaturan Umum',
                style: AppTextStyles.heading3,
              ),
            ),
            const SizedBox(height: AppPadding.md),

            // Language Setting
            _buildSettingItem(
              title: 'Bahasa',
              subtitle: 'Pilih bahasa aplikasi',
              value: _language == 'id' ? 'Indonesia' : 'English',
              onTap: () async {
                final selected = await showDialog<String>(
                  context: context,
                  builder: (context) => SimpleDialog(
                    title: const Text('Pilih Bahasa'),
                    children: [
                      SimpleDialogOption(
                        onPressed: () {
                          Navigator.pop(context, 'id');
                        },
                        child: const Text('Indonesia'),
                      ),
                      SimpleDialogOption(
                        onPressed: () {
                          Navigator.pop(context, 'en');
                        },
                        child: const Text('English'),
                      ),
                    ],
                  ),
                );
                if (selected != null) {
                  setState(() {
                    _language = selected;
                  });
                }
              },
            ),
            const Divider(height: AppPadding.md),

            // Date Format Setting
            _buildSettingItem(
              title: 'Format Tanggal',
              subtitle: 'Pilih format tampilan tanggal',
              value: _dateFormat,
              onTap: () async {
                final formats = ['dd/MM/yyyy', 'MM/dd/yyyy', 'yyyy-MM-dd'];
                final selected = await showDialog<String>(
                  context: context,
                  builder: (context) => SimpleDialog(
                    title: const Text('Pilih Format Tanggal'),
                    children: formats
                        .map((format) => SimpleDialogOption(
                              onPressed: () {
                                Navigator.pop(context, format);
                              },
                              child: Text(format),
                            ))
                        .toList(),
                  ),
                );
                if (selected != null) {
                  setState(() {
                    _dateFormat = selected;
                  });
                }
              },
            ),
            const Divider(height: AppPadding.md),

            // Currency Setting
            _buildSettingItem(
              title: 'Mata Uang',
              subtitle: 'Pilih mata uang untuk transaksi',
              value: _currency,
              onTap: () async {
                final currencies = ['IDR', 'USD', 'EUR'];
                final selected = await showDialog<String>(
                  context: context,
                  builder: (context) => SimpleDialog(
                    title: const Text('Pilih Mata Uang'),
                    children: currencies
                        .map((currency) => SimpleDialogOption(
                              onPressed: () {
                                Navigator.pop(context, currency);
                              },
                              child: Text(currency),
                            ))
                        .toList(),
                  ),
                );
                if (selected != null) {
                  setState(() {
                    _currency = selected;
                  });
                }
              },
            ),
            const Divider(height: AppPadding.md),

            // Theme Setting
            _buildSettingItem(
              title: 'Tema',
              subtitle: 'Pilih tema aplikasi',
              value: _theme == 'light' ? 'Terang' : 'Gelap',
              onTap: () async {
                final selected = await showDialog<String>(
                  context: context,
                  builder: (context) => SimpleDialog(
                    title: const Text('Pilih Tema'),
                    children: [
                      SimpleDialogOption(
                        onPressed: () {
                          Navigator.pop(context, 'light');
                        },
                        child: const Text('Terang'),
                      ),
                      SimpleDialogOption(
                        onPressed: () {
                          Navigator.pop(context, 'dark');
                        },
                        child: const Text('Gelap'),
                      ),
                    ],
                  ),
                );
                if (selected != null) {
                  setState(() {
                    _theme = selected;
                  });
                }
              },
            ),
            const SizedBox(height: AppPadding.lg),

            // About Section
            Text(
              'Tentang',
              style: AppTextStyles.heading3,
            ),
            const SizedBox(height: AppPadding.md),
            _buildSettingItem(
              title: 'Versi Aplikasi',
              subtitle: 'Versi saat ini',
              value: '1.0.0',
              onTap: null,
            ),
            const Divider(height: AppPadding.md),
            _buildSettingItem(
              title: 'Tentang SpendSense',
              subtitle: 'Aplikasi pencatat keuangan pribadi',
              value: '',
              onTap: () {
                showAboutDialog(
                  context: context,
                  applicationName: 'SpendSense',
                  applicationVersion: '1.0.0',
                  applicationLegalese: '© 2024 SpendSense. All rights reserved.',
                );
              },
            ),
            const SizedBox(height: AppPadding.lg),

            // Clear Data Section
            Text(
              'Data',
              style: AppTextStyles.heading3,
            ),
            const SizedBox(height: AppPadding.md),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: () {
                  showDialog(
                    context: context,
                    builder: (context) => AlertDialog(
                      title: const Text('Hapus Semua Data'),
                      content: const Text(
                          'Apakah Anda yakin ingin menghapus semua data? Tindakan ini tidak dapat dibatalkan.'),
                      actions: [
                        TextButton(
                          onPressed: () => Navigator.pop(context),
                          child: const Text('Batal'),
                        ),
                        ElevatedButton(
                          onPressed: () async {
                            await widget.localStorage.clearAllData();
                            Navigator.pop(context);
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text('Semua data telah dihapus'),
                              ),
                            );
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.expense,
                          ),
                          child: const Text('Hapus'),
                        ),
                      ],
                    ),
                  );
                },
                icon: const Icon(Icons.delete),
                label: const Text('Hapus Semua Data'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.expense,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSettingItem({
    required String title,
    required String subtitle,
    required String value,
    VoidCallback? onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(
          vertical: AppPadding.md,
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: AppTextStyles.subtitle,
                  ),
                  const SizedBox(height: AppPadding.xs),
                  Text(
                    subtitle,
                    style: AppTextStyles.caption.copyWith(
                      color: AppColors.textSecondary,
                    ),
                  ),
                ],
              ),
            ),
            if (value.isNotEmpty) ...[
              const SizedBox(width: AppPadding.md),
              Text(
                value,
                style: AppTextStyles.body.copyWith(
                  color: AppColors.primary,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
            if (onTap != null) ...[
              const SizedBox(width: AppPadding.sm),
              const Icon(Icons.chevron_right, color: AppColors.textSecondary),
            ],
          ],
        ),
      ),
    );
  }
}
