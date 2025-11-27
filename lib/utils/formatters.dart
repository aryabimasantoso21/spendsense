import 'package:intl/intl.dart';

class DateFormatter {
  static String formatDate(DateTime date) {
    return DateFormat('dd MMMM yyyy', 'id_ID').format(date);
  }

  static String formatDateShort(DateTime date) {
    return DateFormat('dd/MM/yyyy').format(date);
  }

  static String formatDateWithDay(DateTime date) {
    return DateFormat('EEEE, dd MMMM yyyy', 'id_ID').format(date);
  }

  static String formatTime(DateTime date) {
    return DateFormat('HH:mm').format(date);
  }

  static String formatDateTime(DateTime date) {
    return DateFormat('dd/MM/yyyy HH:mm').format(date);
  }

  static String formatMonthYear(DateTime date) {
    return DateFormat('MMMM yyyy', 'id_ID').format(date);
  }

  static String formatMonth(DateTime date) {
    return DateFormat('MMMM', 'id_ID').format(date);
  }

  static String formatYear(DateTime date) {
    return DateFormat('yyyy').format(date);
  }

  static bool isSameDay(DateTime date1, DateTime date2) {
    return date1.year == date2.year &&
        date1.month == date2.month &&
        date1.day == date2.day;
  }

  static bool isSameMonth(DateTime date1, DateTime date2) {
    return date1.year == date2.year && date1.month == date2.month;
  }

  static bool isToday(DateTime date) {
    return isSameDay(date, DateTime.now());
  }

  static bool isYesterday(DateTime date) {
    final yesterday = DateTime.now().subtract(const Duration(days: 1));
    return isSameDay(date, yesterday);
  }
}

class CurrencyFormatter {
  static String formatCurrency(double amount, {String currencySymbol = 'Rp'}) {
    final formatter = NumberFormat.currency(
      locale: 'id_ID',
      symbol: currencySymbol,
      decimalDigits: 0,
    );
    return formatter.format(amount);
  }

  static String formatNumber(double amount) {
    final formatter = NumberFormat('#,###', 'id_ID');
    return formatter.format(amount);
  }

  static String formatCurrencyCompact(double amount,
      {String currencySymbol = 'Rp'}) {
    if (amount >= 1000000) {
      return '$currencySymbol${(amount / 1000000).toStringAsFixed(1)}JT';
    } else if (amount >= 1000) {
      return '$currencySymbol${(amount / 1000).toStringAsFixed(1)}RB';
    }
    return '$currencySymbol$amount';
  }

  static double parseFromString(String value) {
    // Remove currency symbol and spaces
    String cleaned = value.replaceAll(RegExp(r'[^\d.,]'), '').trim();
    // Replace . with empty if it's a thousand separator, replace , with . for decimal
    if (cleaned.contains(',')) {
      cleaned = cleaned.replaceAll('.', '').replaceAll(',', '.');
    }
    return double.tryParse(cleaned) ?? 0.0;
  }
}

class PercentageFormatter {
  static String formatPercentage(double value,
      {int decimalPlaces = 1, String symbol = '%'}) {
    return '${value.toStringAsFixed(decimalPlaces)}$symbol';
  }
}
