import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/budget_model.dart';
import '../models/expense_model.dart';

class BudgetService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Төсөв нэмэх
  Future<String> addBudget(BudgetModel budget) async {
    try {
      DocumentReference docRef =
          await _firestore.collection('budgets').add(budget.toMap());
      return docRef.id;
    } catch (e) {
      rethrow;
    }
  }

  // Төсөв засах
  Future<void> updateBudget(BudgetModel budget) async {
    try {
      await _firestore
          .collection('budgets')
          .doc(budget.id)
          .update(budget.toMap());
    } catch (e) {
      rethrow;
    }
  }

  // Төсөв устгах
  Future<void> deleteBudget(String budgetId) async {
    try {
      await _firestore.collection('budgets').doc(budgetId).delete();
    } catch (e) {
      rethrow;
    }
  }

  // Хэрэглэгчийн төсвүүдийг авах
  Stream<List<BudgetModel>> getUserBudgets(String userId) {
    return _firestore
        .collection('budgets')
        .where('userId', isEqualTo: userId)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => BudgetModel.fromMap(doc.data(), doc.id))
            .toList());
  }

  // Төсвийн биелэлтийг харах
  Future<Map<String, dynamic>> getBudgetStatus(BudgetModel budget) async {
    try {
      // Тухайн төсвийн хугацаанд хамаарах зарлагуудыг авах
      QuerySnapshot expenseSnapshot = await _firestore
          .collection('expenses')
          .where('userId', isEqualTo: budget.userId)
          .where('category', isEqualTo: budget.category)
          .where('date',
              isGreaterThanOrEqualTo: budget.startDate.millisecondsSinceEpoch)
          .where('date',
              isLessThanOrEqualTo: budget.endDate.millisecondsSinceEpoch)
          .get();

      // Нийт зарцуулсан дүнг тооцох
      double totalSpent = 0;
      for (var doc in expenseSnapshot.docs) {
        ExpenseModel expense =
            ExpenseModel.fromMap(doc.data() as Map<String, dynamic>, doc.id);
        totalSpent += expense.amount;
      }

      // Төсвийн үлдэгдэл
      double remaining = budget.amount - totalSpent;

      // Төсвийн биелэлтийн хувь
      double percentUsed = (totalSpent / budget.amount) * 100;

      return {
        'budgetAmount': budget.amount,
        'totalSpent': totalSpent,
        'remaining': remaining,
        'percentUsed': percentUsed > 100 ? 100 : percentUsed,
        'isOverBudget': totalSpent > budget.amount,
      };
    } catch (e) {
      rethrow;
    }
  }
}
