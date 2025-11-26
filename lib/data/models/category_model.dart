class Category {
  final int id;
  final String type; // 'expense' or 'income'
  final String name;

  const Category({
    required this.id,
    required this.type,
    required this.name,
  });

  // Create a copy of Category with modified fields
  Category copyWith({
    int? id,
    String? type,
    String? name,
  }) {
    return Category(
      id: id ?? this.id,
      type: type ?? this.type,
      name: name ?? this.name,
    );
  }

  // Convert Category to JSON
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'type': type,
      'name': name,
    };
  }

  // Create Category from JSON
  factory Category.fromJson(Map<String, dynamic> json) {
    return Category(
      id: json['id'] ?? json['category_id'], // Support both 'id' and 'category_id'
      type: json['type'],
      name: json['name'],
    );
  }
}

// Default categories
const List<Category> defaultExpenseCategories = [
  Category(id: 1, type: 'expense', name: 'Makanan'),
  Category(id: 2, type: 'expense', name: 'Transportasi'),
  Category(id: 3, type: 'expense', name: 'Belanja'),
  Category(id: 4, type: 'expense', name: 'Utilitas'),
  Category(id: 5, type: 'expense', name: 'Hiburan'),
  Category(id: 6, type: 'expense', name: 'Kesehatan'),
  Category(id: 7, type: 'expense', name: 'Pendidikan'),
  Category(id: 8, type: 'expense', name: 'Lainnya'),
];

const List<Category> defaultIncomeCategories = [
  Category(id: 9, type: 'income', name: 'Gaji'),
  Category(id: 10, type: 'income', name: 'Bisnis'),
  Category(id: 11, type: 'income', name: 'Freelance'),
  Category(id: 12, type: 'income', name: 'Investasi'),
  Category(id: 13, type: 'income', name: 'Lainnya'),
];
