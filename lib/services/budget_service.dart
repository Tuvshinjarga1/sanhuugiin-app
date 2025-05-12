import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/budget_model.dart';
import '../models/expense_model.dart';
import '../models/income_model.dart';
import 'transaction_service.dart';

class BudgetService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final TransactionService transactionService = TransactionService();

  // Хэрэглэгчийн бүх төсөв авах
  Stream<List<BudgetModel>> getUserBudgets(String userId) {
    return _firestore
        .collection('budgets')
        .where('userId', isEqualTo: userId)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs
          .map((doc) => BudgetModel.fromFirestore(doc))
          .toList();
    });
  }

  // Төсөв нэмэх
  Future<void> addBudget(BudgetModel budget) async {
    await _firestore.collection('budgets').add(budget.toFirestore());
  }

  // Төсөв шинэчлэх
  Future<void> updateBudget(BudgetModel budget) async {
    await _firestore
        .collection('budgets')
        .doc(budget.id)
        .update(budget.toFirestore());
  }

  // Төсөв устгах
  Future<void> deleteBudget(BudgetModel budget) async {
    await _firestore.collection('budgets').doc(budget.id).delete();
  }

  // Төсөв ба бодит зарцуулалтыг харьцуулах
  Future<List<BudgetComparisonResult>> compareBudgetWithActual(
      String userId, DateTime startDate, DateTime endDate) async {
    List<BudgetComparisonResult> results = [];

    // Төсвийн мэдээлэл авах
    List<BudgetModel> budgets =
        await getUserBudgetsForPeriod(userId, startDate, endDate);

    for (var budget in budgets) {
      // Орлогын мэдээлэл авах
      List<IncomeModel> incomes = await transactionService
          .getBudgetIncomesForPeriod(userId, budget.id, startDate, endDate);

      // Зарлагын мэдээлэл авах
      List<ExpenseModel> expenses = await transactionService
          .getBudgetExpensesForPeriod(userId, budget.id, startDate, endDate);

      // Орлого, зарлагын нийт дүн тооцоолох
      double totalIncome =
          incomes.fold(0, (sum, income) => sum + income.amount);
      double totalExpense =
          expenses.fold(0, (sum, expense) => sum + expense.amount);

      // Төсвийн үлдэгдэл тооцоолох
      double balance = totalIncome - totalExpense;

      // Төсвийн ашиглалтын хувийг тооцоолох
      double usagePercentage =
          budget.amount > 0 ? (totalExpense / budget.amount) * 100 : 0;

      results.add(BudgetComparisonResult(
        category: budget.category,
        budgetAmount: budget.amount,
        incomeAmount: totalIncome,
        expenseAmount: totalExpense,
        balance: balance,
        usagePercentage: usagePercentage,
      ));
    }

    return results;
  }

  // Нийт төсвийн үлдэгдлийг тооцоолох
  Future<double> calculateTotalBudgetBalance(String userId) async {
    double totalBalance = 0;

    try {
      // Бүх төсвийг авах
      QuerySnapshot budgetSnapshot = await _firestore
          .collection('budgets')
          .where('userId', isEqualTo: userId)
          .get();

      List<BudgetModel> budgets = budgetSnapshot.docs
          .map((doc) => BudgetModel.fromFirestore(doc))
          .toList();

      // Төсөв тус бүрийн орлого, зарлагыг тооцоолох
      for (var budget in budgets) {
        // Орлогын мэдээлэл авах
        double totalIncome =
            await transactionService.calculateBudgetIncomeUsage(budget.id);

        // Зарлагын мэдээлэл авах
        double totalExpense =
            await transactionService.calculateBudgetExpenseUsage(budget.id);

        // Төсвийн үлдэгдлийг нийт дүнд нэмэх
        totalBalance += (totalIncome - totalExpense);
      }

      return totalBalance;
    } catch (e) {
      print('calculateTotalBudgetBalance error: $e');
      return 0;
    }
  }

  // Хугацааны хязгаар дотор байгаа төсвүүдийг авах
  Future<List<BudgetModel>> getUserBudgetsForPeriod(
      String userId, DateTime startDate, DateTime endDate) async {
    QuerySnapshot querySnapshot = await _firestore
        .collection('budgets')
        .where('userId', isEqualTo: userId)
        .get();

    List<BudgetModel> allBudgets = querySnapshot.docs
        .map((doc) => BudgetModel.fromFirestore(doc))
        .toList();

    // Хугацааны хязгаарт тохирсон төсвүүдийг шүүх
    return allBudgets.where((budget) {
      return (budget.startDate.isBefore(endDate) ||
              budget.startDate.isAtSameMomentAs(endDate)) &&
          (budget.endDate.isAfter(startDate) ||
              budget.endDate.isAtSameMomentAs(startDate));
    }).toList();
  }

  // Тухайн ангилалын төсөв авах
  Future<BudgetModel?> getBudgetByCategory(
      String userId, String category, DateTime date) async {
    QuerySnapshot querySnapshot = await _firestore
        .collection('budgets')
        .where('userId', isEqualTo: userId)
        .where('category', isEqualTo: category)
        .get();

    List<BudgetModel> budgets = querySnapshot.docs
        .map((doc) => BudgetModel.fromFirestore(doc))
        .toList();

    // Огноо нь төсвийн хугацаанд байгаа эсэхийг шалгах
    for (var budget in budgets) {
      if ((date.isAfter(budget.startDate) ||
              date.isAtSameMomentAs(budget.startDate)) &&
          (date.isBefore(budget.endDate) ||
              date.isAtSameMomentAs(budget.endDate))) {
        return budget;
      }
    }

    return null;
  }

  // Төсөв тус бүрийн дэлгэрэнгүй мэдээлэл авах
  Future<Map<String, dynamic>> getBudgetDetails(BudgetModel budget) async {
    try {
      // Орлогын мэдээлэл авах
      double totalIncome =
          await transactionService.calculateBudgetIncomeUsage(budget.id);

      // Зарлагын мэдээлэл авах
      double totalExpense =
          await transactionService.calculateBudgetExpenseUsage(budget.id);

      // Төсвийн үлдэгдэл тооцоолох
      double balance = totalIncome - totalExpense;

      // Төсвийн ашиглалтын хувийг тооцоолох
      double usagePercentage =
          budget.amount > 0 ? (totalExpense / budget.amount) * 100 : 0;

      return {
        'budget': budget,
        'totalIncome': totalIncome,
        'totalExpense': totalExpense,
        'balance': balance,
        'usagePercentage': usagePercentage,
        'isOverBudget': totalExpense > budget.amount,
      };
    } catch (e) {
      print('getBudgetDetails error: $e');
      rethrow;
    }
  }
}
