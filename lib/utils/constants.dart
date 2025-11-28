import 'package:flutter/material.dart';

// Color Constants - Figma Design
class AppColors {
  // Primary Colors - Teal/Cyan from Figma
  static const Color primary = Color(0xFF2AC3BE);
  static const Color primaryDark = Color(0xFF1A9E9A);
  static const Color primaryLight = Color(0xFF7DD8D5);
  
  // Accent Colors
  static const Color accent = Color(0xFFE8F8F7);
  static const Color accentDark = Color(0xFF48CAE4);
  
  // Secondary Colors  
  static const Color secondary = Color(0xFF6C757D);
  static const Color secondaryLight = Color(0xFFADB5BD);
  
  // Semantic Colors - from Figma
  static const Color expense = Color(0xFFF5A572);  // Coral/Orange from Figma
  static const Color income = Color(0xFF2AC3BE);   // Teal same as primary
  static const Color warning = Color(0xFFFFC43D);
  static const Color success = Color(0xFF2AC3BE);
  
  // Card Colors from Figma
  static const Color cardBlue = Color(0xFF4B7BE5);
  static const Color cardPurple = Color(0xFF9B6DD5);
  static const Color cardOrange = Color(0xFFF5A572);
  static const Color cardYellow = Color(0xFFF5C842);
  
  // Neutral Colors
  static const Color background = Color(0xFFFFFFFF);
  static const Color surface = Color(0xFFFFFFFF);
  static const Color surfaceVariant = Color(0xFFF5F5F5);
  static const Color border = Color(0xFFE0E0E0);
  
  // Text Colors
  static const Color text = Color(0xFF333333);
  static const Color textSecondary = Color(0xFF666666);
  static const Color textTertiary = Color(0xFF999999);
  
  // Card Gradient Colors - from Figma
  static const Color cardGradientStart = Color(0xFF2AC3BE);
  static const Color cardGradientEnd = Color(0xFF7DD8D5);
  
  // Category dot colors from Figma Statistics
  static const Color dotPink = Color(0xFFF5A572);
  static const Color dotRed = Color(0xFFE57373);
  static const Color dotLightBlue = Color(0xFFB3E5FC);
  static const Color dotBlue = Color(0xFF64B5F6);
  static const Color dotGreen = Color(0xFF81C784);
  static const Color dotPurple = Color(0xFFBA68C8);
}

// Text Style Constants - Modern Typography
class AppTextStyles {
  static const TextStyle heading1 = TextStyle(
    fontSize: 32,
    fontWeight: FontWeight.w700,
    color: AppColors.text,
    letterSpacing: -0.5,
  );

  static const TextStyle heading2 = TextStyle(
    fontSize: 28,
    fontWeight: FontWeight.w700,
    color: AppColors.text,
    letterSpacing: -0.5,
  );

  static const TextStyle heading3 = TextStyle(
    fontSize: 22,
    fontWeight: FontWeight.w600,
    color: AppColors.text,
    letterSpacing: -0.3,
  );

  static const TextStyle subtitle = TextStyle(
    fontSize: 18,
    fontWeight: FontWeight.w600,
    color: AppColors.text,
  );

  static const TextStyle body = TextStyle(
    fontSize: 15,
    fontWeight: FontWeight.w400,
    color: AppColors.text,
    height: 1.5,
  );

  static const TextStyle bodySecondary = TextStyle(
    fontSize: 15,
    fontWeight: FontWeight.w400,
    color: AppColors.textSecondary,
    height: 1.5,
  );

  static const TextStyle caption = TextStyle(
    fontSize: 13,
    fontWeight: FontWeight.w400,
    color: AppColors.textSecondary,
  );
  
  static const TextStyle overline = TextStyle(
    fontSize: 11,
    fontWeight: FontWeight.w600,
    color: AppColors.textTertiary,
    letterSpacing: 1.2,
  );
}

// Padding Constants
class AppPadding {
  static const double xs = 4.0;
  static const double sm = 8.0;
  static const double md = 16.0;
  static const double lg = 24.0;
  static const double xl = 32.0;
  static const double xxl = 48.0;
}

// Border Radius Constants - More pronounced for modern look
class AppBorderRadius {
  static const double xs = 6.0;
  static const double sm = 12.0;
  static const double md = 16.0;
  static const double lg = 20.0;
  static const double xl = 28.0;
  static const double xxl = 36.0;
}

// Elevation/Shadow Constants
class AppElevation {
  static const double none = 0.0;
  static const double sm = 2.0;
  static const double md = 4.0;
  static const double lg = 8.0;
  static const double xl = 16.0;
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

// Account Type Names (Indonesian)
const Map<String, String> accountTypeNames = {
  'bank': 'Bank',
  'ewallet': 'E-Wallet',
  'cash': 'Tunai',
  'savings': 'Tabungan',
  'other': 'Lainnya',
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
  'Adjustment': '⚖️',
};
