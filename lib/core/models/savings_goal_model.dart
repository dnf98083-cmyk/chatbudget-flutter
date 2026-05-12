class SavingsGoalModel {
  final int? id;
  final String title;
  final int targetAmount;
  final int currentAmount;
  final DateTime? deadline;

  SavingsGoalModel({
    this.id,
    required this.title,
    required this.targetAmount,
    this.currentAmount = 0,
    this.deadline,
  });

  double get progress => targetAmount == 0 ? 0 : (currentAmount / targetAmount).clamp(0.0, 1.0);

  Map<String, dynamic> toMap() => {
        'id': id,
        'title': title,
        'target_amount': targetAmount,
        'current_amount': currentAmount,
        'deadline': deadline?.toIso8601String(),
      };

  factory SavingsGoalModel.fromMap(Map<String, dynamic> map) => SavingsGoalModel(
        id: map['id'],
        title: map['title'],
        targetAmount: map['target_amount'],
        currentAmount: map['current_amount'] ?? 0,
        deadline: map['deadline'] != null ? DateTime.parse(map['deadline']) : null,
      );

  SavingsGoalModel copyWith({int? currentAmount}) => SavingsGoalModel(
        id: id,
        title: title,
        targetAmount: targetAmount,
        currentAmount: currentAmount ?? this.currentAmount,
        deadline: deadline,
      );
}
