class SavingsGoalModel {
  final int? id;
  final int userId;
  final String title;
  final int targetAmount;
  final int currentAmount;
  final DateTime? deadline;
  final DateTime createdAt;

  SavingsGoalModel({
    this.id,
    this.userId = 0,
    required this.title,
    required this.targetAmount,
    this.currentAmount = 0,
    this.deadline,
    DateTime? createdAt,
  }) : createdAt = createdAt ?? DateTime.now();

  double get progress => targetAmount == 0 ? 0 : (currentAmount / targetAmount).clamp(0.0, 1.0);

  Map<String, dynamic> toMap() => {
        'id': id,
        'user_id': userId,
        'title': title,
        'target_amount': targetAmount,
        'current_amount': currentAmount,
        'deadline': deadline?.toIso8601String(),
        'created_at': createdAt.toIso8601String(),
      };

  factory SavingsGoalModel.fromMap(Map<String, dynamic> map) => SavingsGoalModel(
        id: map['id'],
        userId: map['user_id'] as int? ?? 0,
        title: map['title'],
        targetAmount: map['target_amount'],
        currentAmount: map['current_amount'] ?? 0,
        deadline: map['deadline'] != null ? DateTime.parse(map['deadline']) : null,
        createdAt: map['created_at'] != null ? DateTime.parse(map['created_at']) : DateTime.now(),
      );

  SavingsGoalModel copyWith({int? currentAmount, DateTime? deadline}) => SavingsGoalModel(
        id: id,
        userId: userId,
        title: title,
        targetAmount: targetAmount,
        currentAmount: currentAmount ?? this.currentAmount,
        deadline: deadline ?? this.deadline,
        createdAt: createdAt,
      );
}
