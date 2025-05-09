import 'package:cloud_firestore/cloud_firestore.dart';

class TaskModel {
  final String id;
  final String userId;
  final String title;
  final String description;
  final DateTime dueDate;
  final String priority;
  final bool isCompleted;
  final DateTime createdAt;

  TaskModel({
    required this.id,
    required this.userId,
    required this.title,
    required this.description,
    required this.dueDate,
    required this.priority,
    required this.isCompleted,
    required this.createdAt,
  });

  Map<String, dynamic> toMap() {
    return {
      'userId': userId,
      'title': title,
      'description': description,
      'dueDate': dueDate,
      'priority': priority,
      'isCompleted': isCompleted,
      'createdAt': createdAt,
    };
  }

  factory TaskModel.fromMap(Map<String, dynamic> map, String documentId) {
    return TaskModel(
      id: documentId,
      userId: map['userId'] ?? '',
      title: map['title'] ?? '',
      description: map['description'] ?? '',
      dueDate: (map['dueDate'] as Timestamp).toDate(),
      priority: map['priority'] ?? '',
      isCompleted: map['isCompleted'] ?? false,
      createdAt: (map['createdAt'] as Timestamp).toDate(),
    );
  }

  TaskModel copyWith({
    String? id,
    String? userId,
    String? title,
    String? description,
    DateTime? dueDate,
    String? priority,
    bool? isCompleted,
    DateTime? createdAt,
  }) {
    return TaskModel(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      title: title ?? this.title,
      description: description ?? this.description,
      dueDate: dueDate ?? this.dueDate,
      priority: priority ?? this.priority,
      isCompleted: isCompleted ?? this.isCompleted,
      createdAt: createdAt ?? this.createdAt,
    );
  }
}
