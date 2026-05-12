class TransactionModel {
  final int? id;
  final int amount;
  final String type; // 'expense' | 'income'
  final String category;
  final String description;
  final DateTime date;

  TransactionModel({
    this.id,
    required this.amount,
    required this.type,
    required this.category,
    required this.description,
    required this.date,
  });

  Map<String, dynamic> toMap() => {
        'id': id,
        'amount': amount,
        'type': type,
        'category': category,
        'description': description,
        'date': date.toIso8601String(),
      };

  factory TransactionModel.fromMap(Map<String, dynamic> map) => TransactionModel(
        id: map['id'],
        amount: map['amount'],
        type: map['type'],
        category: map['category'],
        description: map['description'],
        date: DateTime.parse(map['date']),
      );
}
