import 'package:flutter/material.dart';
import '../../data/services/local_storage_service.dart';
import '../../data/services/supabase_service.dart';
import '../../data/services/theme_service.dart';
import '../../utils/constants.dart';
import '../../utils/formatters.dart';

class SettingsPage extends StatefulWidget {
  final LocalStorageService localStorage;

  const SettingsPage({super.key, required this.localStorage});

  @override
  State<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage> {
  String _username = 'User';
  String _email = '';

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    _username = await SupabaseService.instance.getUsername();
    _email = SupabaseService.instance.user?.email ?? '';
    if (mounted) setState(() {});
  }

  Future<void> _logout() async {
    await SupabaseService.instance.signOut();
    if (mounted) {
      Navigator.of(context).pushReplacementNamed('/login');
    }
  }

  void _showClearDataDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Hapus Semua Data'),
        content: const Text('Tindakan ini akan menghapus semua transaksi dan akun secara permanen. Lanjutkan?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Batal')),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: AppColors.expense),
            onPressed: () async {
              await widget.localStorage.clearAllData();
              Navigator.pop(context);
              if (mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Semua data lokal telah dihapus.')),
                );
              }
            },
            child: const Text('Hapus'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    final textColor = isDarkMode ? Colors.white : AppColors.text;
    final secondaryTextColor = isDarkMode ? Colors.white70 : AppColors.textSecondary;

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        automaticallyImplyLeading: false,
        backgroundColor: Theme.of(context).appBarTheme.backgroundColor,
        elevation: 0,
        centerTitle: true,
        title: Text(
          'Profile',
          style: TextStyle(
            color: Theme.of(context).appBarTheme.foregroundColor,
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
      body: ListView(
        padding: const EdgeInsets.symmetric(horizontal: 24),
        children: [
          const SizedBox(height: 32),
          // Profile Section
          Center(
            child: Column(
              children: [
                // Profile Picture
                Container(
                  width: 120,
                  height: 120,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: LinearGradient(
                      colors: isDarkMode
                          ? [const Color(0xFF004D40), const Color(0xFF00796B)]
                          : [AppColors.primary, AppColors.primaryLight],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: AppColors.primary.withValues(alpha: 0.3),
                        blurRadius: 15,
                        offset: const Offset(0, 5),
                      ),
                    ],
                  ),
                  child: Icon(
                    Icons.person,
                    size: 60,
                    color: Colors.white.withValues(alpha: 0.9),
                  ),
                ),
                const SizedBox(height: 20),
                // Username
                Text(
                  _username,
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: textColor,
                  ),
                ),
                const SizedBox(height: 8),
                // Email
                Text(
                  _email,
                  style: TextStyle(
                    fontSize: 14,
                    color: secondaryTextColor,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 32),

          // Settings List
          ValueListenableBuilder<ThemeMode>(
            valueListenable: ThemeService.instance,
            builder: (context, themeMode, _) {
              final isDark = themeMode == ThemeMode.dark;
              return _buildSettingItem(
                icon: isDark ? Icons.dark_mode : Icons.dark_mode_outlined,
                title: 'Dark Mode',
                textColor: textColor,
                iconColor: secondaryTextColor,
                trailing: Switch(
                  value: isDark,
                  onChanged: (value) => ThemeService.instance.toggleTheme(value),
                  activeTrackColor: AppColors.primary,
                ),
              );
            },
          ),
          _buildSettingItem(
            icon: Icons.person_add_outlined,
            title: 'Invite Friends',
            textColor: textColor,
            iconColor: secondaryTextColor,
            onTap: () {},
          ),
          _buildSettingItem(
            icon: Icons.account_balance_wallet_outlined,
            title: 'My Wallet',
            textColor: textColor,
            iconColor: secondaryTextColor,
            onTap: () {},
          ),
          _buildSettingItem(
            icon: Icons.info_outline,
            title: 'About us',
            textColor: textColor,
            iconColor: secondaryTextColor,
            onTap: () => showAboutDialog(
              context: context,
              applicationName: AppStrings.appName,
              applicationVersion: '1.0.0',
              applicationLegalese: '© 2024 SpendSense',
              children: [const Text('Aplikasi manajer keuangan pribadi yang dibuat dengan Flutter.')],
            ),
          ),
          const SizedBox(height: 16),
          const Divider(),
          _buildSettingItem(
            icon: Icons.delete_outline,
            title: 'Hapus Data Lokal',
            iconColor: AppColors.expense,
            textColor: AppColors.expense,
            onTap: _showClearDataDialog,
          ),
          _buildSettingItem(
            icon: Icons.logout,
            title: 'Logout',
            iconColor: AppColors.expense,
            textColor: AppColors.expense,
            onTap: _logout,
          ),
        ],
      ),
    );
  }

  Widget _buildSettingItem({
    required IconData icon,
    required String title,
    Widget? trailing,
    VoidCallback? onTap,
    Color? iconColor,
    Color? textColor,
  }) {
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 16),
        child: Row(
          children: [
            Icon(icon, color: iconColor ?? AppColors.textSecondary, size: 24),
            const SizedBox(width: 16),
            Expanded(
              child: Text(
                title,
                style: TextStyle(
                  fontSize: 16,
                  color: textColor ?? AppColors.text,
                ),
              ),
            ),
            if (trailing != null) trailing,
            if (trailing == null && onTap != null)
              Icon(
                Icons.chevron_right,
                color: AppColors.textTertiary,
              ),
          ],
        ),
      ),
    );
  }
}
