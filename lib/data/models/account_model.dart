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
      'id': id,
      'name': name,
      'type': type,
      'balance': balance,
      'created_at': createdAt.toIso8601String(),
    };
  }

  // Create Account from JSON
  factory Account.fromJson(Map<String, dynamic> json) {
    return Account(
      id: json['id'] ?? json['account_id'], // Support both 'id' and 'account_id'
      name: json['name'],
      type: json['type'] ?? 'cash',
      balance: (json['balance'] as num).toDouble(),
      createdAt: DateTime.parse(json['created_at']),
    );
  }
}
