class BudgetModel {
  final String id;
  final String userId;
  final String category;
  final double amount;
  final DateTime startDate;
  final DateTime endDate;

  BudgetModel({
    required this.id,
    required this.userId,
    required this.category,
    required this.amount,
    required this.startDate,
    required this.endDate,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'userId': userId,
      'category': category,
      'amount': amount,
      'startDate': startDate.millisecondsSinceEpoch,
      'endDate': endDate.millisecondsSinceEpoch,
    };
  }

  factory BudgetModel.fromMap(Map<String, dynamic> map, String docId) {
    return BudgetModel(
      id: docId,
      userId: map['userId'] ?? '',
      category: map['category'] ?? '',
      amount: map['amount']?.toDouble() ?? 0.0,
      startDate: DateTime.fromMillisecondsSinceEpoch(map['startDate']),
      endDate: DateTime.fromMillisecondsSinceEpoch(map['endDate']),
    );
  }
}
