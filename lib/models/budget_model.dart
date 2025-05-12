import 'package:cloud_firestore/cloud_firestore.dart';

class BudgetModel {
  final String id;
  final String userId;
  final String title;
  final String category;
  final double amount;
  final DateTime startDate;
  final DateTime endDate;
  final String note;

  BudgetModel({
    required this.id,
    required this.userId,
    required this.title,
    required this.category,
    required this.amount,
    required this.startDate,
    required this.endDate,
    this.note = '',
  });

  // Firestore-с мэдээлэл цуглуулах
  factory BudgetModel.fromFirestore(DocumentSnapshot doc) {
    Map data = doc.data() as Map<String, dynamic>;

    // Parse startDate handling both Timestamp and int
    DateTime startDate;
    if (data['startDate'] is Timestamp) {
      startDate = (data['startDate'] as Timestamp).toDate();
    } else if (data['startDate'] is int) {
      startDate = DateTime.fromMillisecondsSinceEpoch(data['startDate'] as int);
    } else {
      startDate = DateTime.now();
    }

    // Parse endDate handling both Timestamp and int
    DateTime endDate;
    if (data['endDate'] is Timestamp) {
      endDate = (data['endDate'] as Timestamp).toDate();
    } else if (data['endDate'] is int) {
      endDate = DateTime.fromMillisecondsSinceEpoch(data['endDate'] as int);
    } else {
      endDate = DateTime.now();
    }

    return BudgetModel(
      id: doc.id,
      userId: data['userId'] ?? '',
      title: data['title'] ?? '',
      category: data['category'] ?? '',
      amount: (data['amount'] ?? 0).toDouble(),
      startDate: startDate,
      endDate: endDate,
      note: data['note'] ?? '',
    );
  }

  // Firestore руу хадгалах мэдээлэл
  Map<String, dynamic> toFirestore() {
    return {
      'userId': userId,
      'title': title,
      'category': category,
      'amount': amount,
      'startDate': Timestamp.fromDate(startDate),
      'endDate': Timestamp.fromDate(endDate),
      'note': note,
    };
  }
}

class BudgetComparisonResult {
  final String category;
  final double budgetAmount;
  final double incomeAmount;
  final double expenseAmount;
  final double balance;
  final double usagePercentage;

  BudgetComparisonResult({
    required this.category,
    required this.budgetAmount,
    required this.incomeAmount,
    required this.expenseAmount,
    required this.balance,
    required this.usagePercentage,
  });
}
