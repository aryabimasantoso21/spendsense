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
      final response = await _client.auth.signUp(email: email, password: password);
      
      // Initialize default categories for new user
      if (response.user != null) {
        await _initializeDefaultCategories();
      }
      
      return response;
    } catch (e) {
      rethrow;
    }
  }

  Future<void> _initializeDefaultCategories() async {
    try {
      // Insert default expense categories
      for (var category in defaultExpenseCategories) {
        await _client.from('categories').insert({
          'user_id': user!.id,
          'name': category.name,
          'type': category.type,
        });
      }

      // Insert default income categories
      for (var category in defaultIncomeCategories) {
        await _client.from('categories').insert({
          'user_id': user!.id,
          'name': category.name,
          'type': category.type,
        });
      }
    } catch (e) {
      // Silently fail - categories might already exist
      // This can happen if signUp completes but user doesn't login immediately
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
        'id': transaction.id,
        'user_id': user!.id,
        'description': transaction.description,
        'amount': transaction.amount,
        'type': transaction.type,
        'category_name': transaction.categoryName,
        'date': transaction.date.toIso8601String(),
        'account_id': transaction.accountId,
        'created_at': DateTime.now().toIso8601String(),
      });
    } catch (e) {
      rethrow;
    }
  }

  Future<List<Transaction>> getTransactions() async {
    try {
      final data = await _client
          .from('transactions')
          .select()
          .eq('user_id', user!.id)
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
        'category_name': transaction.categoryName,
        'date': transaction.date.toIso8601String(),
        'account_id': transaction.accountId,
      }).eq('id', transaction.id);
    } catch (e) {
      rethrow;
    }
  }

  // ==================== ACCOUNTS ====================
  Future<void> saveAccount(Account account) async {
    try {
      await _client.from('accounts').insert({
        'id': account.id,
        'user_id': user!.id,
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
          .select()
          .eq('user_id', user!.id);
      
      return (data as List)
          .map((json) => Account.fromJson(json))
          .toList();
    } catch (e) {
      rethrow;
    }
  }

  Future<void> deleteAccount(int id) async {
    try {
      await _client.from('accounts').delete().eq('id', id);
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
      }).eq('id', account.id);
    } catch (e) {
      rethrow;
    }
  }

  Future<void> saveCategories(List<Category> categories) async {
    try {
      for (var category in categories) {
        await _client.from('categories').upsert({
          'id': category.id,
          'user_id': user!.id,
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
      final data = await _client
          .from('categories')
          .select()
          .eq('user_id', user!.id);
      
      return (data as List)
          .map((json) => Category.fromJson(json))
          .toList();
    } catch (e) {
      rethrow;
    }
  }
}
