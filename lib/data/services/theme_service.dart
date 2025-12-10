import 'package:flutter/material.dart';
import 'local_storage_service.dart';

class ThemeService extends ValueNotifier<ThemeMode> {
  static final ThemeService instance = ThemeService._();

  ThemeService._() : super(ThemeMode.light);

  Future<void> init() async {
    final isDarkMode = await LocalStorageService.instance.getThemeMode();
    value = isDarkMode ? ThemeMode.dark : ThemeMode.light;
  }

  Future<void> toggleTheme(bool isDarkMode) async {
    value = isDarkMode ? ThemeMode.dark : ThemeMode.light;
    await LocalStorageService.instance.saveThemeMode(isDarkMode);
  }

  bool get isDarkMode => value == ThemeMode.dark;
}
