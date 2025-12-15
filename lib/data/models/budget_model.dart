class Budget {
  final int? id;
  final String title;
  final double amount;
  final String period; // 'monthly', 'weekly', 'daily'
  final int? categoryId;
  final DateTime startDate;
  final DateTime endDate;
  final String userId;

  Budget({
    this.id,
    required this.title,
    required this.amount,
    required this.period,
    this.categoryId,
    required this.startDate,
    required this.endDate,
    required this.userId,
  });

  factory Budget.fromJson(Map<String, dynamic> json) {
    return Budget(
      id: json['id'] as int?,
      title: json['title'] as String,
      amount: (json['amount'] as num).toDouble(),
      period: json['period'] as String,
      categoryId: json['category_id'] as int?,
      startDate: DateTime.parse(json['start_date'] as String),
      endDate: DateTime.parse(json['end_date'] as String),
      userId: json['user_id'] as String,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      if (id != null) 'id': id,
      'title': title,
      'amount': amount,
      'period': period,
      'category_id': categoryId,
      'start_date': startDate.toIso8601String(),
      'end_date': endDate.toIso8601String(),
      'user_id': userId,
    };
  }
}
