import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/task_model.dart';

class TaskService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final String _collection = 'tasks';

  // Хэрэглэгчийн ажлуудыг авах
  Future<List<TaskModel>> getUserTasks(String userId) async {
    try {
      final QuerySnapshot querySnapshot = await _firestore
          .collection(_collection)
          .where('userId', isEqualTo: userId)
          .orderBy('dueDate', descending: false)
          .get();

      List<TaskModel> tasks = querySnapshot.docs
          .map((doc) =>
              TaskModel.fromMap(doc.data() as Map<String, dynamic>, doc.id))
          .toList();

      return tasks;
    } catch (e) {
      rethrow;
    }
  }

  // Шинэ ажил нэмэх
  Future<void> addTask(TaskModel task) async {
    try {
      await _firestore.collection(_collection).add(task.toMap());
    } catch (e) {
      rethrow;
    }
  }

  // Ажил шинэчлэх
  Future<void> updateTask(TaskModel task) async {
    try {
      await _firestore
          .collection(_collection)
          .doc(task.id)
          .update(task.toMap());
    } catch (e) {
      rethrow;
    }
  }

  // Ажил устгах
  Future<void> deleteTask(String taskId) async {
    try {
      await _firestore.collection(_collection).doc(taskId).delete();
    } catch (e) {
      rethrow;
    }
  }

  // Ажлын чухалчлалаар шүүх
  Future<List<TaskModel>> getTasksByPriority(
      String userId, String priority) async {
    try {
      final QuerySnapshot querySnapshot = await _firestore
          .collection(_collection)
          .where('userId', isEqualTo: userId)
          .where('priority', isEqualTo: priority)
          .orderBy('dueDate', descending: false)
          .get();

      List<TaskModel> tasks = querySnapshot.docs
          .map((doc) =>
              TaskModel.fromMap(doc.data() as Map<String, dynamic>, doc.id))
          .toList();

      return tasks;
    } catch (e) {
      rethrow;
    }
  }

  // Дуусгасан/Дуусаагүй ажлуудаар шүүх
  Future<List<TaskModel>> getTasksByCompletionStatus(
      String userId, bool isCompleted) async {
    try {
      final QuerySnapshot querySnapshot = await _firestore
          .collection(_collection)
          .where('userId', isEqualTo: userId)
          .where('isCompleted', isEqualTo: isCompleted)
          .orderBy('dueDate', descending: false)
          .get();

      List<TaskModel> tasks = querySnapshot.docs
          .map((doc) =>
              TaskModel.fromMap(doc.data() as Map<String, dynamic>, doc.id))
          .toList();

      return tasks;
    } catch (e) {
      rethrow;
    }
  }

  // Өнөөдрийн ажлуудыг авах
  Future<List<TaskModel>> getTodayTasks(String userId) async {
    try {
      // Өнөөдрийн эхлэл, төгсгөл
      final DateTime today = DateTime.now();
      final DateTime startOfDay = DateTime(today.year, today.month, today.day);
      final DateTime endOfDay =
          DateTime(today.year, today.month, today.day, 23, 59, 59);

      final QuerySnapshot querySnapshot = await _firestore
          .collection(_collection)
          .where('userId', isEqualTo: userId)
          .where('dueDate', isGreaterThanOrEqualTo: startOfDay)
          .where('dueDate', isLessThanOrEqualTo: endOfDay)
          .orderBy('dueDate', descending: false)
          .get();

      List<TaskModel> tasks = querySnapshot.docs
          .map((doc) =>
              TaskModel.fromMap(doc.data() as Map<String, dynamic>, doc.id))
          .toList();

      return tasks;
    } catch (e) {
      rethrow;
    }
  }

  // Хугацаа хэтэрсэн ажлуудыг авах
  Future<List<TaskModel>> getOverdueTasks(String userId) async {
    try {
      final DateTime today = DateTime.now();
      final DateTime startOfDay = DateTime(today.year, today.month, today.day);

      final QuerySnapshot querySnapshot = await _firestore
          .collection(_collection)
          .where('userId', isEqualTo: userId)
          .where('dueDate', isLessThan: startOfDay)
          .where('isCompleted', isEqualTo: false)
          .orderBy('dueDate', descending: false)
          .get();

      List<TaskModel> tasks = querySnapshot.docs
          .map((doc) =>
              TaskModel.fromMap(doc.data() as Map<String, dynamic>, doc.id))
          .toList();

      return tasks;
    } catch (e) {
      rethrow;
    }
  }

  // Тодорхой хугацааны ажлуудыг авах
  Future<List<TaskModel>> getTasksByDateRange(
      String userId, DateTime startDate, DateTime endDate) async {
    try {
      final QuerySnapshot querySnapshot = await _firestore
          .collection(_collection)
          .where('userId', isEqualTo: userId)
          .where('dueDate', isGreaterThanOrEqualTo: startDate)
          .where('dueDate', isLessThanOrEqualTo: endDate)
          .orderBy('dueDate', descending: false)
          .get();

      List<TaskModel> tasks = querySnapshot.docs
          .map((doc) =>
              TaskModel.fromMap(doc.data() as Map<String, dynamic>, doc.id))
          .toList();

      return tasks;
    } catch (e) {
      rethrow;
    }
  }
}
