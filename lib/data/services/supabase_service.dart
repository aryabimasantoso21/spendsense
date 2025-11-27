import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/transaction_model.dart';
import '../models/account_model.dart';
import '../models/category_model.dart';

class SupabaseService {
  static SupabaseService? _instance;
  late SupabaseClient _client;
  
  SupabaseService._();

  static SupabaseService get instance {
    _instance ??= SupabaseService._();
    return _instance!;
  }

  SupabaseClient get client => _client;
  Session? get session => _client.auth.currentSession;
  User? get user => _client.auth.currentUser;
  bool get isAuthenticated => user != null;

  Future<void> init() async {
    await Supabase.initialize(
      url: 'https://ctypfsyhsybkfaieyzrs.supabase.co',
      anonKey: 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6ImN0eXBmc3loc3lia2ZhaWV5enJzIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NjM3OTczOTgsImV4cCI6MjA3OTM3MzM5OH0.XAJZQNGXMJ77fUOFSvcrkn4WFi5bDkKzbuR_8MYvvlE',
    );
    _client = Supabase.instance.client;
  }

  // ==================== AUTHENTICATION ====================
  Future<AuthResponse> signUp({
    required String email,
    required String password,
  }) async {
    try {
      return await _client.auth.signUp(email: email, password: password);
    } catch (e) {
      rethrow;
    }
  }

  Future<AuthResponse> signIn({
    required String email,
    required String password,
  }) async {
    try {
      return await _client.auth.signInWithPassword(
        email: email,
        password: password,
      );
    } catch (e) {
      rethrow;
    }
  }

  Future<void> signOut() async {
    try {
      await _client.auth.signOut();
    } catch (e) {
      rethrow;
    }
  }

  // ==================== TRANSACTIONS ====================
  Future<void> saveTransaction(Transaction transaction) async {
    try {
      await _client.from('transactions').insert({
        'account_id': transaction.accountId,
        'destination_account_id': transaction.destinationAccountId,
        'category_id': transaction.categoryId,
        'type': transaction.type,
        'amount': transaction.amount,
        'date': transaction.date.toIso8601String(),
        'description': transaction.description,
        'created_at': DateTime.now().toIso8601String(),
      });
      // Note: Account balance is updated automatically by database trigger
    } catch (e) {
      rethrow;
    }
  }

  Future<List<Transaction>> getTransactions() async {
    try {
      final data = await _client
          .from('transactions')
          .select()
          .order('date', ascending: false);
      
      return (data as List)
          .map((json) => Transaction.fromJson(json))
          .toList();
    } catch (e) {
      rethrow;
    }
  }

  Future<void> deleteTransaction(int id) async {
    try {
      await _client.from('transactions').delete().eq('id', id);
      // Note: Account balance is updated automatically by database trigger
    } catch (e) {
      rethrow;
    }
  }

  Future<void> updateTransaction(Transaction transaction) async {
    try {
      await _client.from('transactions').update({
        'description': transaction.description,
        'amount': transaction.amount,
        'type': transaction.type,
        'category_id': transaction.categoryId,
        'date': transaction.date.toIso8601String(),
        'account_id': transaction.accountId,
        'destination_account_id': transaction.destinationAccountId,
      }).eq('id', transaction.id);
      // Note: Account balance is updated automatically by database trigger
    } catch (e) {
      rethrow;
    }
  }

  // ==================== ACCOUNTS ====================
  Future<void> saveAccount(Account account) async {
    try {
      await _client.from('accounts').insert({
        'name': account.name,
        'type': account.type,
        'balance': account.balance,
        'created_at': DateTime.now().toIso8601String(),
      });
    } catch (e) {
      rethrow;
    }
  }

  Future<List<Account>> getAccounts() async {
    try {
      final data = await _client
          .from('accounts')
          .select();
      
      return (data as List)
          .map((json) => Account.fromJson(json))
          .toList();
    } catch (e) {
      rethrow;
    }
  }

  Future<void> deleteAccount(int id) async {
    try {
      await _client.from('accounts').delete().eq('account_id', id);
    } catch (e) {
      rethrow;
    }
  }

  Future<void> updateAccount(Account account) async {
    try {
      await _client.from('accounts').update({
        'name': account.name,
        'type': account.type,
        'balance': account.balance,
      }).eq('account_id', account.id);
    } catch (e) {
      rethrow;
    }
  }

  Future<void> saveCategories(List<Category> categories) async {
    try {
      for (var category in categories) {
        // Supabase existing structure: category_id, type, name (no user_id)
        await _client.from('categories').upsert({
          'category_id': category.id,
          'name': category.name,
          'type': category.type,
        });
      }
    } catch (e) {
      rethrow;
    }
  }

  Future<List<Category>> getCategories() async {
    try {
      // Supabase existing struktur tidak punya user_id, jadi get semua categories
      final data = await _client
          .from('categories')
          .select();
      
      return (data as List)
          .map((json) => Category.fromJson(json))
          .toList();
    } catch (e) {
      rethrow;
    }
  }
}
