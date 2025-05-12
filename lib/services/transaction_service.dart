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

  // Тодорхой сарын орлогуудыг авах
  Future<List<IncomeModel>> getMonthIncomes(
      String userId, int year, int month) async {
    try {
      // Тухайн сарын эхлэл, төгсгөлийн огноог тооцоолох
      final startOfMonth = DateTime(year, month, 1);
      final endOfMonth = DateTime(year, month + 1, 0, 23, 59, 59);

      print('getMonthIncomes: $userId, $startOfMonth - $endOfMonth');
      print('startOfMonth ms: ${startOfMonth.millisecondsSinceEpoch}');
      print('endOfMonth ms: ${endOfMonth.millisecondsSinceEpoch}');

      // Firestore-д композит индекс байхыг шаарддаг тул date,userId-р хайх боломжгүй
      // Тиймээс userId-р хайгаад дараа нь хугацаагаар шүүнэ
      final querySnapshot = await _firestore
          .collection('incomes')
          .where('userId', isEqualTo: userId)
          .get();

      print('getMonthIncomes raw results: ${querySnapshot.docs.length}');

      // Хугацаагаар шүүх - date нь millisecondsSinceEpoch хэлбэрээр хадгалагдсан
      final filteredDocs = querySnapshot.docs.where((doc) {
        final data = doc.data();
        final int dateMs = data['date'] as int;
        return dateMs >= startOfMonth.millisecondsSinceEpoch &&
            dateMs <= endOfMonth.millisecondsSinceEpoch;
      }).toList();

      print('getMonthIncomes filtered results: ${filteredDocs.length}');

      return filteredDocs
          .map((doc) => IncomeModel.fromMap(doc.data(), doc.id))
          .toList();
    } catch (e) {
      print('getMonthIncomes error: $e');
      rethrow;
    }
  }

  // Тодорхой сарын зарлагуудыг авах
  Future<List<ExpenseModel>> getMonthExpenses(
      String userId, int year, int month) async {
    try {
      // Тухайн сарын эхлэл, төгсгөлийн огноог тооцоолох
      final startOfMonth = DateTime(year, month, 1);
      final endOfMonth = DateTime(year, month + 1, 0, 23, 59, 59);

      print('getMonthExpenses: $userId, $startOfMonth - $endOfMonth');
      print('startOfMonth ms: ${startOfMonth.millisecondsSinceEpoch}');
      print('endOfMonth ms: ${endOfMonth.millisecondsSinceEpoch}');

      // Firestore-д композит индекс байхыг шаарддаг тул date,userId-р хайх боломжгүй
      // Тиймээс userId-р хайгаад дараа нь хугацаагаар шүүнэ
      final querySnapshot = await _firestore
          .collection('expenses')
          .where('userId', isEqualTo: userId)
          .get();

      print('getMonthExpenses raw results: ${querySnapshot.docs.length}');

      // Хугацаагаар шүүх - date нь millisecondsSinceEpoch хэлбэрээр хадгалагдсан
      final filteredDocs = querySnapshot.docs.where((doc) {
        final data = doc.data();
        final int dateMs = data['date'] as int;
        return dateMs >= startOfMonth.millisecondsSinceEpoch &&
            dateMs <= endOfMonth.millisecondsSinceEpoch;
      }).toList();

      print('getMonthExpenses filtered results: ${filteredDocs.length}');

      return filteredDocs
          .map((doc) => ExpenseModel.fromMap(doc.data(), doc.id))
          .toList();
    } catch (e) {
      print('getMonthExpenses error: $e');
      rethrow;
    }
  }

  // Тодорхой жилийн орлогуудыг авах
  Future<List<IncomeModel>> getYearIncomes(String userId, int year) async {
    try {
      // Тухайн жилийн эхлэл, төгсгөлийн огноог тооцоолох
      final startOfYear = DateTime(year, 1, 1);
      final endOfYear = DateTime(year, 12, 31, 23, 59, 59);

      print('getYearIncomes: $userId, $startOfYear - $endOfYear');
      print('startOfYear ms: ${startOfYear.millisecondsSinceEpoch}');
      print('endOfYear ms: ${endOfYear.millisecondsSinceEpoch}');

      // Firestore-д композит индекс байхыг шаарддаг тул date,userId-р хайх боломжгүй
      // Тиймээс userId-р хайгаад дараа нь хугацаагаар шүүнэ
      final querySnapshot = await _firestore
          .collection('incomes')
          .where('userId', isEqualTo: userId)
          .get();

      print('getYearIncomes raw results: ${querySnapshot.docs.length}');

      // Хугацаагаар шүүх - date нь millisecondsSinceEpoch хэлбэрээр хадгалагдсан
      final filteredDocs = querySnapshot.docs.where((doc) {
        final data = doc.data();
        final int dateMs = data['date'] as int;
        return dateMs >= startOfYear.millisecondsSinceEpoch &&
            dateMs <= endOfYear.millisecondsSinceEpoch;
      }).toList();

      print('getYearIncomes filtered results: ${filteredDocs.length}');

      return filteredDocs
          .map((doc) => IncomeModel.fromMap(doc.data(), doc.id))
          .toList();
    } catch (e) {
      print('getYearIncomes error: $e');
      rethrow;
    }
  }

  // Тодорхой жилийн зарлагуудыг авах
  Future<List<ExpenseModel>> getYearExpenses(String userId, int year) async {
    try {
      // Тухайн жилийн эхлэл, төгсгөлийн огноог тооцоолох
      final startOfYear = DateTime(year, 1, 1);
      final endOfYear = DateTime(year, 12, 31, 23, 59, 59);

      print('getYearExpenses: $userId, $startOfYear - $endOfYear');
      print('startOfYear ms: ${startOfYear.millisecondsSinceEpoch}');
      print('endOfYear ms: ${endOfYear.millisecondsSinceEpoch}');

      // Firestore-д композит индекс байхыг шаарддаг тул date,userId-р хайх боломжгүй
      // Тиймээс userId-р хайгаад дараа нь хугацаагаар шүүнэ
      final querySnapshot = await _firestore
          .collection('expenses')
          .where('userId', isEqualTo: userId)
          .get();

      print('getYearExpenses raw results: ${querySnapshot.docs.length}');

      // Хугацаагаар шүүх - date нь millisecondsSinceEpoch хэлбэрээр хадгалагдсан
      final filteredDocs = querySnapshot.docs.where((doc) {
        final data = doc.data();
        final int dateMs = data['date'] as int;
        return dateMs >= startOfYear.millisecondsSinceEpoch &&
            dateMs <= endOfYear.millisecondsSinceEpoch;
      }).toList();

      print('getYearExpenses filtered results: ${filteredDocs.length}');

      return filteredDocs
          .map((doc) => ExpenseModel.fromMap(doc.data(), doc.id))
          .toList();
    } catch (e) {
      print('getYearExpenses error: $e');
      rethrow;
    }
  }
}
