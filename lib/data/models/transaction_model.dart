class Transaction {
  final int id;
  final int accountId;
  final int categoryId; // Can be 0 for Supabase transactions (uses categoryName instead)
  final String type; // 'expense' or 'income'
  final double amount;
  final DateTime date;
  final String description;
  final DateTime createdAt;
  final String? categoryName; // Used with Supabase (stores name instead of ID)
  final String? accountName; // Optional, for display purposes

  Transaction({
    required this.id,
    required this.accountId,
    required this.categoryId,
    required this.type,
    required this.amount,
    required this.date,
    required this.description,
    required this.createdAt,
    this.categoryName,
    this.accountName,
  });

  // Create a copy of Transaction with modified fields
  Transaction copyWith({
    int? id,
    int? accountId,
    int? categoryId,
    String? type,
    double? amount,
    DateTime? date,
    String? description,
    DateTime? createdAt,
    String? categoryName,
    String? accountName,
  }) {
    return Transaction(
      id: id ?? this.id,
      accountId: accountId ?? this.accountId,
      categoryId: categoryId ?? this.categoryId,
      type: type ?? this.type,
      amount: amount ?? this.amount,
      date: date ?? this.date,
      description: description ?? this.description,
      createdAt: createdAt ?? this.createdAt,
      categoryName: categoryName ?? this.categoryName,
      accountName: accountName ?? this.accountName,
    );
  }

  // Convert Transaction to JSON (for LocalStorage - uses categoryId)
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'account_id': accountId,
      'category_id': categoryId,
      'type': type,
      'amount': amount,
      'date': date.toIso8601String(),
      'description': description,
      'created_at': createdAt.toIso8601String(),
    };
  }

  // Create Transaction from JSON (supports both LocalStorage and Supabase formats)
  factory Transaction.fromJson(Map<String, dynamic> json) {
    return Transaction(
      id: json['id'] as int,
      accountId: json['account_id'] as int? ?? json['accountId'] as int? ?? 0,
      categoryId: json['category_id'] as int? ?? json['categoryId'] as int? ?? 0,
      type: json['type'] as String,
      amount: (json['amount'] as num).toDouble(),
      date: json['date'] is String ? DateTime.parse(json['date'] as String) : json['date'] as DateTime,
      description: (json['description'] as String?) ?? '',
      createdAt: json['created_at'] is String ? DateTime.parse(json['created_at'] as String) : json['created_at'] as DateTime,
      categoryName: json['category_name'] as String?,
      accountName: json['account_name'] as String?,
    );
  }
}

