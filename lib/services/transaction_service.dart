import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/income_model.dart';
import '../models/expense_model.dart';

class TransactionService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Орлого нэмэх
  Future<String> addIncome(IncomeModel income) async {
    try {
      DocumentReference docRef =
          await _firestore.collection('incomes').add(income.toMap());

      // Хэрэглэгчийн үлдэгдлийг шинэчлэх
      await updateUserBalance(income.userId, income.amount);

      return docRef.id;
    } catch (e) {
      rethrow;
    }
  }

  // Зарлага нэмэх
  Future<String> addExpense(ExpenseModel expense) async {
    try {
      DocumentReference docRef =
          await _firestore.collection('expenses').add(expense.toMap());

      // Хэрэглэгчийн үлдэгдлийг шинэчлэх
      await updateUserBalance(expense.userId, -expense.amount);

      return docRef.id;
    } catch (e) {
      rethrow;
    }
  }

  // Орлого засах
  Future<void> updateIncome(
      IncomeModel updatedIncome, double previousAmount) async {
    try {
      // Хуучин орлогыг хасаж, шинэ орлогыг нэмэх
      double amountDifference = updatedIncome.amount - previousAmount;

      await _firestore
          .collection('incomes')
          .doc(updatedIncome.id)
          .update(updatedIncome.toMap());

      // Хэрэглэгчийн үлдэгдлийг шинэчлэх
      await updateUserBalance(updatedIncome.userId, amountDifference);
    } catch (e) {
      rethrow;
    }
  }

  // Зарлага засах
  Future<void> updateExpense(
      ExpenseModel updatedExpense, double previousAmount) async {
    try {
      // Хуучин зарлагыг нэмж, шинэ зарлагыг хасах
      double amountDifference = previousAmount - updatedExpense.amount;

      await _firestore
          .collection('expenses')
          .doc(updatedExpense.id)
          .update(updatedExpense.toMap());

      // Хэрэглэгчийн үлдэгдлийг шинэчлэх
      await updateUserBalance(updatedExpense.userId, amountDifference);
    } catch (e) {
      rethrow;
    }
  }

  // Орлого устгах
  Future<void> deleteIncome(IncomeModel income) async {
    try {
      await _firestore.collection('incomes').doc(income.id).delete();

      // Хэрэглэгчийн үлдэгдлийг шинэчлэх
      await updateUserBalance(income.userId, -income.amount);
    } catch (e) {
      rethrow;
    }
  }

  // Зарлага устгах
  Future<void> deleteExpense(ExpenseModel expense) async {
    try {
      await _firestore.collection('expenses').doc(expense.id).delete();

      // Хэрэглэгчийн үлдэгдлийг шинэчлэх
      await updateUserBalance(expense.userId, expense.amount);
    } catch (e) {
      rethrow;
    }
  }

  // Хэрэглэгчийн орлогуудыг авах
  Stream<List<IncomeModel>> getUserIncomes(String userId) {
    return _firestore
        .collection('incomes')
        .where('userId', isEqualTo: userId)
        .orderBy('date', descending: true)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => IncomeModel.fromMap(doc.data(), doc.id))
            .toList());
  }

  // Хэрэглэгчийн зарлагуудыг авах
  Stream<List<ExpenseModel>> getUserExpenses(String userId) {
    return _firestore
        .collection('expenses')
        .where('userId', isEqualTo: userId)
        .orderBy('date', descending: true)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => ExpenseModel.fromMap(doc.data(), doc.id))
            .toList());
  }

  // Хэрэглэгчийн үлдэгдлийг шинэчлэх
  Future<void> updateUserBalance(String userId, double amount) async {
    try {
      DocumentReference userRef = _firestore.collection('users').doc(userId);

      await _firestore.runTransaction((transaction) async {
        DocumentSnapshot userSnapshot = await transaction.get(userRef);

        if (!userSnapshot.exists) {
          throw Exception("User doesn't exist");
        }

        Map<String, dynamic> userData =
            userSnapshot.data() as Map<String, dynamic>;
        double currentBalance = userData['balance'] ?? 0.0;
        double newBalance = currentBalance + amount;

        transaction.update(userRef, {'balance': newBalance});

        return newBalance;
      });
    } catch (e) {
      rethrow;
    }
  }

  // Орлогын төрлүүдийг авах
  Stream<List<String>> getIncomeCategories(String userId) {
    return _firestore
        .collection('categories')
        .doc(userId)
        .collection('income')
        .snapshots()
        .map((snapshot) =>
            snapshot.docs.map((doc) => doc.data()['name'] as String).toList());
  }

  // Зарлагын төрлүүдийг авах
  Stream<List<String>> getExpenseCategories(String userId) {
    return _firestore
        .collection('categories')
        .doc(userId)
        .collection('expense')
        .snapshots()
        .map((snapshot) =>
            snapshot.docs.map((doc) => doc.data()['name'] as String).toList());
  }

  // Орлогын төрөл нэмэх
  Future<void> addIncomeCategory(String userId, String categoryName) async {
    try {
      await _firestore
          .collection('categories')
          .doc(userId)
          .collection('income')
          .add({'name': categoryName});
    } catch (e) {
      rethrow;
    }
  }

  // Зарлагын төрөл нэмэх
  Future<void> addExpenseCategory(String userId, String categoryName) async {
    try {
      await _firestore
          .collection('categories')
          .doc(userId)
          .collection('expense')
          .add({'name': categoryName});
    } catch (e) {
      rethrow;
    }
  }

  // Сүүлийн орлогуудыг авах
  Future<List<IncomeModel>> getRecentIncomes(String userId, int limit) async {
    try {
      final querySnapshot = await _firestore
          .collection('incomes')
          .where('userId', isEqualTo: userId)
          .orderBy('date', descending: true)
          .limit(limit)
          .get();

      return querySnapshot.docs
          .map((doc) => IncomeModel.fromMap(doc.data(), doc.id))
          .toList();
    } catch (e) {
      rethrow;
    }
  }

// Сүүлийн зарлагуудыг авах
  Future<List<ExpenseModel>> getRecentExpenses(String userId, int limit) async {
    try {
      final querySnapshot = await _firestore
          .collection('expenses')
          .where('userId', isEqualTo: userId)
          .orderBy('date', descending: true)
          .limit(limit)
          .get();

      return querySnapshot.docs
          .map((doc) => ExpenseModel.fromMap(doc.data(), doc.id))
          .toList();
    } catch (e) {
      rethrow;
    }
  }
}
