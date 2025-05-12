import 'package:cloud_firestore/cloud_firestore.dart';

class IncomeModel {
  final String id;
  final String userId;
  final String title;
  final String category;
  final double amount;
  final DateTime date;
  final String note;
  final String? budgetId;

  IncomeModel({
    required this.id,
    required this.userId,
    required this.title,
    required this.category,
    required this.amount,
    required this.date,
    this.note = '',
    this.budgetId,
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
      'budgetId': budgetId,
    };
  }

  factory IncomeModel.fromMap(Map<String, dynamic> map, String docId) {
    return IncomeModel(
      id: docId,
      userId: map['userId'] ?? '',
      title: map['title'] ?? '',
      category: map['category'] ?? '',
      amount: map['amount']?.toDouble() ?? 0.0,
      date: DateTime.fromMillisecondsSinceEpoch(map['date']),
      note: map['note'] ?? '',
      budgetId: map['budgetId'],
    );
  }

  factory IncomeModel.fromFirestore(DocumentSnapshot doc) {
    Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
    return IncomeModel(
      id: doc.id,
      userId: data['userId'] ?? '',
      title: data['title'] ?? '',
      category: data['category'] ?? '',
      amount: (data['amount'] ?? 0).toDouble(),
      date: data['date'] is int
          ? DateTime.fromMillisecondsSinceEpoch(data['date'])
          : (data['date'] as Timestamp).toDate(),
      note: data['note'] ?? '',
      budgetId: data['budgetId'],
    );
  }
}
