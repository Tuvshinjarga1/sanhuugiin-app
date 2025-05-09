class ExpenseModel {
  final String id;
  final String userId;
  final String title;
  final String category;
  final double amount;
  final DateTime date;
  final String note;

  ExpenseModel({
    required this.id,
    required this.userId,
    required this.title,
    required this.category,
    required this.amount,
    required this.date,
    this.note = '',
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'userId': userId,
      'title': title,
      'category': category,
      'amount': amount,
      'date': date.millisecondsSinceEpoch,
      'note': note,
    };
  }

  factory ExpenseModel.fromMap(Map<String, dynamic> map, String docId) {
    return ExpenseModel(
      id: docId,
      userId: map['userId'] ?? '',
      title: map['title'] ?? '',
      category: map['category'] ?? '',
      amount: map['amount']?.toDouble() ?? 0.0,
      date: DateTime.fromMillisecondsSinceEpoch(map['date']),
      note: map['note'] ?? '',
    );
  }
}
