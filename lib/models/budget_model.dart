class BudgetModel {
  final String id;
  final String userId;
  final String category;
  final double amount;
  final DateTime startDate;
  final DateTime endDate;
  final double income;
  final double expense;

  BudgetModel({
    required this.id,
    required this.userId,
    required this.category,
    required this.amount,
    required this.startDate,
    required this.endDate,
    this.income = 0.0,
    this.expense = 0.0,
  });

  // Үлдэгдэл тооцоолох
  double get remaining => amount + income - expense;

  // Хувь тооцоолох
  double get percentUsed {
    if (amount <= 0) return 0;
    return ((expense - income) / amount) * 100;
  }

  // Хэтэрсэн эсэхийг шалгах
  bool get isOverBudget => remaining < 0;

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'userId': userId,
      'category': category,
      'amount': amount,
      'startDate': startDate.millisecondsSinceEpoch,
      'endDate': endDate.millisecondsSinceEpoch,
      'income': income,
      'expense': expense,
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
      income: map['income']?.toDouble() ?? 0.0,
      expense: map['expense']?.toDouble() ?? 0.0,
    );
  }

  // Шинэ орлого нэмэх
  BudgetModel addIncome(double value) {
    return BudgetModel(
      id: id,
      userId: userId,
      category: category,
      amount: amount,
      startDate: startDate,
      endDate: endDate,
      income: income + value,
      expense: expense,
    );
  }

  // Шинэ зарлага нэмэх
  BudgetModel addExpense(double value) {
    return BudgetModel(
      id: id,
      userId: userId,
      category: category,
      amount: amount,
      startDate: startDate,
      endDate: endDate,
      income: income,
      expense: expense + value,
    );
  }

  // Өөрчлөлт хийх
  BudgetModel copyWith({
    String? id,
    String? userId,
    String? category,
    double? amount,
    DateTime? startDate,
    DateTime? endDate,
    double? income,
    double? expense,
  }) {
    return BudgetModel(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      category: category ?? this.category,
      amount: amount ?? this.amount,
      startDate: startDate ?? this.startDate,
      endDate: endDate ?? this.endDate,
      income: income ?? this.income,
      expense: expense ?? this.expense,
    );
  }
}
