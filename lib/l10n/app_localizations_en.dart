// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for English (`en`).
class AppLocalizationsEn extends AppLocalizations {
  AppLocalizationsEn([String locale = 'en']) : super(locale);

  @override
  String get appName => 'SpendSense';

  @override
  String get home => 'Beranda';

  @override
  String get transactions => 'Transaksi';

  @override
  String get statistics => 'Statistik';

  @override
  String get accounts => 'Akun';

  @override
  String get settings => 'Pengaturan';
}
