import 'package:flutter/material.dart';

// Color Constants
class AppColors {
  static const Color primary = Color(0xFF0BCCF8);
  static const Color primaryDark = Color(0xFF0095A8);
  static const Color accent = Color(0xFFFFA500);
  static const Color expense = Color(0xFFFF6B6B);
  static const Color income = Color(0xFF51CF66);
  static const Color background = Color(0xFFF5F5F5);
  static const Color surface = Color(0xFFFFFFFF);
  static const Color text = Color(0xFF333333);
  static const Color textSecondary = Color(0xFF999999);
  static const Color border = Color(0xFFEEEEEE);
}

// Text Style Constants
class AppTextStyles {
  static const TextStyle heading1 = TextStyle(
    fontSize: 28,
    fontWeight: FontWeight.bold,
    color: AppColors.text,
  );

  static const TextStyle heading2 = TextStyle(
    fontSize: 24,
    fontWeight: FontWeight.bold,
    color: AppColors.text,
  );

  static const TextStyle heading3 = TextStyle(
    fontSize: 20,
    fontWeight: FontWeight.bold,
    color: AppColors.text,
  );

  static const TextStyle subtitle = TextStyle(
    fontSize: 16,
    fontWeight: FontWeight.w500,
    color: AppColors.text,
  );

  static const TextStyle body = TextStyle(
    fontSize: 14,
    fontWeight: FontWeight.normal,
    color: AppColors.text,
  );

  static const TextStyle bodySecondary = TextStyle(
    fontSize: 14,
    fontWeight: FontWeight.normal,
    color: AppColors.textSecondary,
  );

  static const TextStyle caption = TextStyle(
    fontSize: 12,
    fontWeight: FontWeight.normal,
    color: AppColors.textSecondary,
  );
}

// Padding Constants
class AppPadding {
  static const double xs = 4.0;
  static const double sm = 8.0;
  static const double md = 16.0;
  static const double lg = 24.0;
  static const double xl = 32.0;
}

// Border Radius Constants
class AppBorderRadius {
  static const double xs = 4.0;
  static const double sm = 8.0;
  static const double md = 12.0;
  static const double lg = 16.0;
  static const double xl = 24.0;
}

// String Constants
class AppStrings {
  static const String appName = 'SpendSense';
  static const String home = 'Beranda';
  static const String transactions = 'Transaksi';
  static const String statistics = 'Statistik';
  static const String accounts = 'Akun';
  static const String settings = 'Pengaturan';
  static const String addTransaction = 'Tambah Transaksi';
  static const String expense = 'Pengeluaran';
  static const String income = 'Pemasukan';
  static const String transfer = 'Transfer';
  static const String category = 'Kategori';
  static const String amount = 'Jumlah';
  static const String date = 'Tanggal';
  static const String account = 'Akun';
  static const String description = 'Deskripsi';
  static const String balance = 'Saldo';
  static const String totalIncome = 'Total Pemasukan';
  static const String totalExpense = 'Total Pengeluaran';
  static const String net = 'Bersih';
}

// Account Type Icons
const Map<String, String> accountTypeIcons = {
  'bank': '🏦',
  'ewallet': '📱',
  'cash': '💵',
  'savings': '🏧',
  'other': '💼',
};

// Category Icons
const Map<String, String> categoryIcons = {
  'Makanan': '🍔',
  'Transportasi': '🚗',
  'Belanja': '🛍️',
  'Utilitas': '💡',
  'Hiburan': '🎬',
  'Kesehatan': '🏥',
  'Pendidikan': '📚',
  'Gaji': '💰',
  'Bisnis': '💼',
  'Freelance': '💻',
  'Investasi': '📈',
  'Lainnya': '📌',
};
