import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/income_model.dart';
import '../models/expense_model.dart';

class ReportService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  /// Сарын тайлан авах
  Future<Map<String, dynamic>> getMonthlyReport(
      String userId, DateTime month) async {
    try {
      // Сарын эхлэл, төгсгөлийн огноо
      final DateTime startDate = DateTime(month.year, month.month, 1);
      final DateTime endDate =
          DateTime(month.year, month.month + 1, 0, 23, 59, 59);

      // Орлогууд авах
      final incomeSnapshot = await _firestore
          .collection('incomes')
          .where('userId', isEqualTo: userId)
          .where('date', isGreaterThanOrEqualTo: startDate)
          .where('date', isLessThanOrEqualTo: endDate)
          .get();

      // Зарлагууд авах
      final expenseSnapshot = await _firestore
          .collection('expenses')
          .where('userId', isEqualTo: userId)
          .where('date', isGreaterThanOrEqualTo: startDate)
          .where('date', isLessThanOrEqualTo: endDate)
          .get();

      List<IncomeModel> incomes = incomeSnapshot.docs
          .map((doc) => IncomeModel.fromMap(doc.data(), doc.id))
          .toList();

      List<ExpenseModel> expenses = expenseSnapshot.docs
          .map((doc) => ExpenseModel.fromMap(doc.data(), doc.id))
          .toList();

      // Тайлан боловсруулах
      return _processReport(incomes, expenses);
    } catch (e) {
      rethrow;
    }
  }

  /// Жилийн тайлан авах
  Future<Map<String, dynamic>> getYearlyReport(String userId, int year) async {
    try {
      // Жилийн эхлэл, төгсгөлийн огноо
      final DateTime startDate = DateTime(year, 1, 1);
      final DateTime endDate = DateTime(year, 12, 31, 23, 59, 59);

      // Орлогууд авах
      final incomeSnapshot = await _firestore
          .collection('incomes')
          .where('userId', isEqualTo: userId)
          .where('date', isGreaterThanOrEqualTo: startDate)
          .where('date', isLessThanOrEqualTo: endDate)
          .get();

      // Зарлагууд авах
      final expenseSnapshot = await _firestore
          .collection('expenses')
          .where('userId', isEqualTo: userId)
          .where('date', isGreaterThanOrEqualTo: startDate)
          .where('date', isLessThanOrEqualTo: endDate)
          .get();

      List<IncomeModel> incomes = incomeSnapshot.docs
          .map((doc) => IncomeModel.fromMap(doc.data(), doc.id))
          .toList();

      List<ExpenseModel> expenses = expenseSnapshot.docs
          .map((doc) => ExpenseModel.fromMap(doc.data(), doc.id))
          .toList();

      // Тайлан боловсруулах
      Map<String, dynamic> report = _processReport(incomes, expenses);

      // Сараар ялгах
      Map<int, double> incomeByMonth = {};
      Map<int, double> expenseByMonth = {};

      // Сараар орлого, зарлагыг бүртгэх
      for (var income in incomes) {
        final month = income.date.month;
        incomeByMonth[month] = (incomeByMonth[month] ?? 0) + income.amount;
      }

      for (var expense in expenses) {
        final month = expense.date.month;
        expenseByMonth[month] = (expenseByMonth[month] ?? 0) + expense.amount;
      }

      report['incomeByMonth'] = incomeByMonth;
      report['expenseByMonth'] = expenseByMonth;

      return report;
    } catch (e) {
      rethrow;
    }
  }

  /// Тодорхой хугацааны тайлан авах
  Future<Map<String, dynamic>> getCustomRangeReport(
      String userId, DateTime startDate, DateTime endDate) async {
    try {
      // Өдрийн төгсгөл хүртэл
      final DateTime endOfDay =
          DateTime(endDate.year, endDate.month, endDate.day, 23, 59, 59);

      // Орлогууд авах
      final incomeSnapshot = await _firestore
          .collection('incomes')
          .where('userId', isEqualTo: userId)
          .where('date', isGreaterThanOrEqualTo: startDate)
          .where('date', isLessThanOrEqualTo: endOfDay)
          .get();

      // Зарлагууд авах
      final expenseSnapshot = await _firestore
          .collection('expenses')
          .where('userId', isEqualTo: userId)
          .where('date', isGreaterThanOrEqualTo: startDate)
          .where('date', isLessThanOrEqualTo: endOfDay)
          .get();

      List<IncomeModel> incomes = incomeSnapshot.docs
          .map((doc) => IncomeModel.fromMap(doc.data(), doc.id))
          .toList();

      List<ExpenseModel> expenses = expenseSnapshot.docs
          .map((doc) => ExpenseModel.fromMap(doc.data(), doc.id))
          .toList();

      // Тайлан боловсруулах
      Map<String, dynamic> report = _processReport(incomes, expenses);

      // Хугацааны тайланд орлого, зарлагын жагсаалтыг оруулах
      report['incomes'] = incomes;
      report['expenses'] = expenses;

      return report;
    } catch (e) {
      rethrow;
    }
  }

  /// Орлого зарлагын тайланг боловсруулах
  Map<String, dynamic> _processReport(
      List<IncomeModel> incomes, List<ExpenseModel> expenses) {
    double totalIncome = 0;
    double totalExpense = 0;
    Map<String, double> incomeByCategory = {};
    Map<String, double> expenseByCategory = {};

    // Орлогын боловсруулалт
    for (var income in incomes) {
      totalIncome += income.amount;
      incomeByCategory[income.category] =
          (incomeByCategory[income.category] ?? 0) + income.amount;
    }

    // Зарлагын боловсруулалт
    for (var expense in expenses) {
      totalExpense += expense.amount;
      expenseByCategory[expense.category] =
          (expenseByCategory[expense.category] ?? 0) + expense.amount;
    }

    // Цэвэр ашиг/алдагдал
    double netIncome = totalIncome - totalExpense;

    return {
      'totalIncome': totalIncome,
      'totalExpense': totalExpense,
      'netIncome': netIncome,
      'incomeByCategory': incomeByCategory,
      'expenseByCategory': expenseByCategory,
    };
  }
}
