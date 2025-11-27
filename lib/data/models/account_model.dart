class Account {
  final int id;
  final String name;
  final String type; // 'bank', 'ewallet', 'cash'
  final double balance;
  final DateTime createdAt;

  Account({
    required this.id,
    required this.name,
    required this.type,
    required this.balance,
    required this.createdAt,
  });

  // Create a copy of Account with modified fields
  Account copyWith({
    int? id,
    String? name,
    String? type,
    double? balance,
    DateTime? createdAt,
  }) {
    return Account(
      id: id ?? this.id,
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
      'name': name,
      'type': type,
      'balance': balance,
      'created_at': createdAt.toIso8601String(),
    };
  }

  // Create Account from JSON
  factory Account.fromJson(Map<String, dynamic> json) {
    return Account(
      id: json['account_id'] as int,
      name: json['name'] as String,
      type: json['type'] as String? ?? 'cash',
      balance: (json['balance'] as num?)?.toDouble() ?? 0.0,
      createdAt: json['created_at'] is String 
          ? DateTime.parse(json['created_at'] as String)
          : json['created_at'] as DateTime? ?? DateTime.now(),
    );
  }
}
