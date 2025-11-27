import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/transaction_model.dart';
import '../models/account_model.dart';
import '../models/category_model.dart';

class LocalStorageService {
  static const String _transactionsKey = 'transactions';
  static const String _accountsKey = 'accounts';
  static const String _categoriesKey = 'categories';
  static const String _settingsKey = 'settings';

  static LocalStorageService? _instance;
  SharedPreferences? _prefs;
  bool _initialized = false;

  LocalStorageService._();

  static LocalStorageService get instance {
    _instance ??= LocalStorageService._();
    return _instance!;
  }

  Future<void> init() async {
    if (!_initialized) {
      _prefs = await SharedPreferences.getInstance();
      _initialized = true;
    }
  }

  Future<SharedPreferences> get _preferences async {
    if (_prefs == null) {
      await init();
    }
    return _prefs!;
  }

  // Transaction Methods
  Future<void> saveTransaction(Transaction transaction) async {
    final prefs = await _preferences;
    final transactions = await getTransactions();
    transactions.add(transaction);
    await prefs.setString(
      _transactionsKey,
      jsonEncode(transactions.map((t) => t.toJson()).toList()),
    );
  }

  Future<void> saveTransactions(List<Transaction> transactions) async {
    final prefs = await _preferences;
    await prefs.setString(
      _transactionsKey,
      jsonEncode(transactions.map((t) => t.toJson()).toList()),
    );
  }

  Future<List<Transaction>> getTransactions() async {
    final prefs = await _preferences;
    final String? jsonString = prefs.getString(_transactionsKey);
    if (jsonString == null) {
      return [];
    }
    final List<dynamic> jsonList = jsonDecode(jsonString);
    return jsonList.map((json) => Transaction.fromJson(json)).toList();
  }

  Future<void> deleteTransaction(int id) async {
    final transactions = await getTransactions();
    transactions.removeWhere((t) => t.id == id);
    await saveTransactions(transactions);
  }

  Future<void> updateTransaction(Transaction transaction) async {
    final transactions = await getTransactions();
    final index = transactions.indexWhere((t) => t.id == transaction.id);
    if (index != -1) {
      transactions[index] = transaction;
      await saveTransactions(transactions);
    }
  }

  // Account Methods
  Future<void> saveAccount(Account account) async {
    final prefs = await _preferences;
    final accounts = await getAccounts();
    accounts.add(account);
    await prefs.setString(
      _accountsKey,
      jsonEncode(accounts.map((a) => a.toJson()).toList()),
    );
  }

  Future<void> saveAccounts(List<Account> accounts) async {
    final prefs = await _preferences;
    await prefs.setString(
      _accountsKey,
      jsonEncode(accounts.map((a) => a.toJson()).toList()),
    );
  }

  Future<List<Account>> getAccounts() async {
    final prefs = await _preferences;
    final String? jsonString = prefs.getString(_accountsKey);
    if (jsonString == null) {
      return [];
    }
    final List<dynamic> jsonList = jsonDecode(jsonString);
    return jsonList.map((json) => Account.fromJson(json)).toList();
  }

  Future<void> deleteAccount(int id) async {
    final accounts = await getAccounts();
    accounts.removeWhere((a) => a.id == id);
    await saveAccounts(accounts);
  }

  Future<void> updateAccount(Account account) async {
    final accounts = await getAccounts();
    final index = accounts.indexWhere((a) => a.id == account.id);
    if (index != -1) {
      accounts[index] = account;
      await saveAccounts(accounts);
    }
  }

  // Category Methods
  Future<void> saveCategories(List<Category> categories) async {
    final prefs = await _preferences;
    await prefs.setString(
      _categoriesKey,
      jsonEncode(categories.map((c) => c.toJson()).toList()),
    );
  }

  Future<List<Category>> getCategories() async {
    final prefs = await _preferences;
    final String? jsonString = prefs.getString(_categoriesKey);
    if (jsonString == null) {
      return [];
    }
    final List<dynamic> jsonList = jsonDecode(jsonString);
    return jsonList.map((json) => Category.fromJson(json)).toList();
  }

  // Settings Methods
  Future<void> saveSetting(String key, dynamic value) async {
    final prefs = await _preferences;
    final settings = await getSettings();
    settings[key] = value;
    await prefs.setString(_settingsKey, jsonEncode(settings));
  }

  Future<Map<String, dynamic>> getSettings() async {
    final prefs = await _preferences;
    final String? jsonString = prefs.getString(_settingsKey);
    if (jsonString == null) {
      return {};
    }
    return jsonDecode(jsonString);
  }

  Future<void> clearAllData() async {
    final prefs = await _preferences;
    await prefs.remove(_transactionsKey);
    await prefs.remove(_accountsKey);
    await prefs.remove(_categoriesKey);
    await prefs.remove(_settingsKey);
  }
}
