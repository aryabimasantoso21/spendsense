class Account {
  final int id;
  final String userId;
  final String name;
  final String type; // 'Bank', 'E-Wallet', 'Cash'
  final double balance;
  final DateTime createdAt;

  Account({
    required this.id,
    required this.userId,
    required this.name,
    required this.type,
    required this.balance,
    required this.createdAt,
  });

  // Create a copy of Account with modified fields
  Account copyWith({
    int? id,
    String? userId,
    String? name,
    String? type,
    double? balance,
    DateTime? createdAt,
  }) {
    return Account(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      name: name ?? this.name,
      type: type ?? this.type,
      balance: balance ?? this.balance,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  // Convert Account to JSON
  Map<String, dynamic> toJson() {
    return {
      'account_id': id,
      'user_id': userId,
      'account_name': name,
      'account_type': type,
      'balance': balance,
      'created_at': createdAt.toIso8601String(),
    };
  }

  // Create Account from JSON
  factory Account.fromJson(Map<String, dynamic> json) {
    return Account(
      id: (json['account_id'] ?? json['id']) as int,
      userId: json['user_id']?.toString() ?? '',
      name: (json['account_name'] ?? json['name']) as String,
      type: (json['account_type'] ?? json['type']) as String? ?? 'cash',
      balance: (json['balance'] as num?)?.toDouble() ?? 0.0,
      createdAt: json['created_at'] is String 
          ? DateTime.parse(json['created_at'] as String)
          : json['created_at'] as DateTime? ?? DateTime.now(),
    );
  }
}
