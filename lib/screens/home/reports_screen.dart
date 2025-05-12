import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../../services/auth_service.dart';
import '../../services/transaction_service.dart';
import '../../models/income_model.dart';
import '../../models/expense_model.dart';

// Өнгөний тогтмол утгууд (dashboard_screen.dart-тай ижил)
const Color kPrimaryColor = Color(0xFF1E88E5);
const Color kSecondaryColor = Color(0xFF26A69A);
const Color kAccentColor = Color(0xFFFFB74D);
const Color kBackgroundColor = Color(0xFFF5F5F7);
const Color kCardColor = Colors.white;
const Color kIncomeColor = Color(0xFF2E7D32);
const Color kExpenseColor = Color(0xFFC62828);
const Color kTextColor = Color(0xFF424242);
const Color kTextLightColor = Color(0xFF757575);

class ReportsScreen extends StatefulWidget {
  const ReportsScreen({super.key});

  @override
  State<ReportsScreen> createState() => _ReportsScreenState();
}

class _ReportsScreenState extends State<ReportsScreen> {
  final TransactionService _transactionService = TransactionService();
  bool _isLoading = false;
  String? _errorMessage;

  // Тайлангийн өгөгдөл
  DateTime _selectedMonth = DateTime.now();
  int _selectedYear = DateTime.now().year;

  // Статистик мэдээлэл
  Map<String, double> _incomeByCategory = {};
  Map<String, double> _expenseByCategory = {};
  Map<int, double> _incomeByMonth = {};
  Map<int, double> _expenseByMonth = {};
  List<IncomeModel> _recentIncomes = [];
  List<ExpenseModel> _recentExpenses = [];
  double _totalIncome = 0;
  double _totalExpense = 0;
  double _netBalance = 0;

  @override
  void initState() {
    super.initState();
    _loadMonthlyReport();
  }

  @override
  Widget build(BuildContext context) {
    final authService = Provider.of<AuthService>(context);
    final user = authService.getCurrentUser();
    final numberFormat = NumberFormat("#,##0.00", "mn_MN");

    if (user == null) {
      return const Center(child: Text('Хэрэглэгч нэвтрээгүй байна'));
    }

    return Scaffold(
      backgroundColor: kBackgroundColor,
      appBar: AppBar(
        title: const Text('Санхүүгийн тайлан'),
        backgroundColor: kCardColor,
        elevation: 0,
      ),
      body: _isLoading
          ? _buildLoadingState()
          : _errorMessage != null
              ? _buildErrorState()
              : RefreshIndicator(
                  onRefresh: _loadMonthlyReport,
                  color: kPrimaryColor,
                  child: SingleChildScrollView(
                    physics: const AlwaysScrollableScrollPhysics(),
                    child: Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _buildDateSelector(),
                          const SizedBox(height: 24),
                          _buildSummaryCard(numberFormat),
                          const SizedBox(height: 24),
                          _buildCategoryCharts(),
                          const SizedBox(height: 24),
                          _buildMonthlyCharts(),
                          const SizedBox(height: 24),
                          _buildTransactionsLists(numberFormat),
                        ],
                      ),
                    ),
                  ),
                ),
    );
  }

  Widget _buildLoadingState() {
    return const Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          CircularProgressIndicator(
            valueColor: AlwaysStoppedAnimation<Color>(kPrimaryColor),
          ),
          SizedBox(height: 16),
          Text(
            'Тайлан ачааллаж байна...',
            style: TextStyle(
              color: kTextColor,
              fontSize: 16,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildErrorState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.error_outline_rounded,
            size: 64,
            color: Colors.red.shade300,
          ),
          const SizedBox(height: 16),
          Text(
            _errorMessage!,
            style: TextStyle(
              color: Colors.red.shade700,
              fontSize: 16,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 24),
          ElevatedButton.icon(
            onPressed: _loadMonthlyReport,
            icon: const Icon(Icons.refresh_rounded),
            label: const Text('Дахин оролдох'),
            style: ElevatedButton.styleFrom(
              backgroundColor: kPrimaryColor,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDateSelector() {
    return Container(
      decoration: BoxDecoration(
        color: kCardColor,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          IconButton(
            icon: const Icon(Icons.arrow_back_ios, size: 18),
            onPressed: () {
              setState(() {
                _selectedMonth = DateTime(
                  _selectedMonth.year,
                  _selectedMonth.month - 1,
                );
              });
              _loadMonthlyReport();
            },
          ),
          GestureDetector(
            onTap: () async {
              final DateTime? picked = await showDatePicker(
                context: context,
                initialDate: _selectedMonth,
                firstDate: DateTime(2020),
                lastDate: DateTime.now(),
                initialDatePickerMode: DatePickerMode.year,
              );
              if (picked != null) {
                setState(() {
                  _selectedMonth = DateTime(picked.year, picked.month);
                  _selectedYear = picked.year;
                });
                _loadMonthlyReport();
              }
            },
            child: Text(
              DateFormat('yyyy оны MM сар').format(_selectedMonth),
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: kTextColor,
              ),
            ),
          ),
          IconButton(
            icon: const Icon(Icons.arrow_forward_ios, size: 18),
            onPressed: () {
              final now = DateTime.now();
              final nextMonth =
                  DateTime(_selectedMonth.year, _selectedMonth.month + 1);

              // Ирээдүйн огноо сонгохгүй
              if (nextMonth.isBefore(DateTime(now.year, now.month + 1))) {
                setState(() {
                  _selectedMonth = nextMonth;
                });
                _loadMonthlyReport();
              }
            },
          ),
        ],
      ),
    );
  }

  Widget _buildSummaryCard(NumberFormat numberFormat) {
    return Container(
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [kPrimaryColor, Color(0xFF1565C0)],
        ),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: kPrimaryColor.withOpacity(0.3),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      padding: const EdgeInsets.all(20),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Нийт орлого',
                    style: TextStyle(
                      color: Colors.white70,
                      fontSize: 14,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    '₮${numberFormat.format(_totalIncome)}',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  const Text(
                    'Нийт зарлага',
                    style: TextStyle(
                      color: Colors.white70,
                      fontSize: 14,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    '₮${numberFormat.format(_totalExpense)}',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ],
          ),
          const Divider(
            color: Colors.white30,
            height: 30,
          ),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Text(
                'Цэвэр ашиг/алдагдал: ',
                style: TextStyle(
                  color: Colors.white70,
                  fontSize: 16,
                ),
              ),
              Text(
                '₮${numberFormat.format(_netBalance)}',
                style: TextStyle(
                  color:
                      _netBalance >= 0 ? Colors.greenAccent : Colors.redAccent,
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildCategoryCharts() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Ангилалаар',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: kTextColor,
          ),
        ),
        const SizedBox(height: 16),
        Row(
          children: [
            Expanded(
              child: _buildCategoryChart(
                title: 'Орлого',
                categories: _incomeByCategory,
                total: _totalIncome,
                color: kIncomeColor,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: _buildCategoryChart(
                title: 'Зарлага',
                categories: _expenseByCategory,
                total: _totalExpense,
                color: kExpenseColor,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildCategoryChart({
    required String title,
    required Map<String, double> categories,
    required double total,
    required Color color,
  }) {
    if (categories.isEmpty) {
      return Container(
        decoration: BoxDecoration(
          color: kCardColor,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        padding: const EdgeInsets.all(16),
        child: Center(
          child: Column(
            children: [
              Text(
                title,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: kTextColor,
                ),
              ),
              const SizedBox(height: 12),
              Icon(
                Icons.pie_chart_outline,
                size: 48,
                color: Colors.grey.shade300,
              ),
              const SizedBox(height: 12),
              Text(
                'Мэдээлэл байхгүй',
                style: TextStyle(
                  color: Colors.grey.shade500,
                  fontSize: 14,
                ),
              ),
            ],
          ),
        ),
      );
    }

    return Container(
      decoration: BoxDecoration(
        color: kCardColor,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: kTextColor,
            ),
          ),
          const SizedBox(height: 16),
          ...categories.entries.map((entry) {
            final category = entry.key;
            final amount = entry.value;
            final percentage = total > 0 ? (amount / total * 100) : 0;

            return Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Text(
                          category,
                          style: const TextStyle(
                            fontSize: 14,
                            color: kTextColor,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      Text(
                        '${percentage.toStringAsFixed(1)}%',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                          color: color,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  LinearProgressIndicator(
                    value: percentage / 100,
                    backgroundColor: Colors.grey.shade200,
                    valueColor: AlwaysStoppedAnimation<Color>(color),
                    minHeight: 8,
                    borderRadius: BorderRadius.circular(4),
                  ),
                ],
              ),
            );
          }).toList(),
        ],
      ),
    );
  }

  Widget _buildMonthlyCharts() {
    final months = [
      '1',
      '2',
      '3',
      '4',
      '5',
      '6',
      '7',
      '8',
      '9',
      '10',
      '11',
      '12'
    ];
    final currentMonth = DateTime.now().month;
    final monthsToShow =
        _selectedYear == DateTime.now().year ? currentMonth : 12;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              '$_selectedYear оны үзүүлэлт',
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: kTextColor,
              ),
            ),
            Row(
              children: [
                IconButton(
                  icon: const Icon(Icons.arrow_back_ios, size: 18),
                  onPressed: () {
                    setState(() {
                      _selectedYear--;
                    });
                    _loadYearlyReport();
                  },
                ),
                Text(
                  _selectedYear.toString(),
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.arrow_forward_ios, size: 18),
                  onPressed: () {
                    final currentYear = DateTime.now().year;
                    if (_selectedYear < currentYear) {
                      setState(() {
                        _selectedYear++;
                      });
                      _loadYearlyReport();
                    }
                  },
                ),
              ],
            ),
          ],
        ),
        const SizedBox(height: 16),
        Container(
          decoration: BoxDecoration(
            color: kCardColor,
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.05),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  _legendItem(color: kIncomeColor, label: 'Орлого'),
                  const SizedBox(width: 24),
                  _legendItem(color: kExpenseColor, label: 'Зарлага'),
                ],
              ),
              const SizedBox(height: 16),
              const Divider(),
              const SizedBox(height: 8),
              for (int i = 0; i < monthsToShow; i++)
                Padding(
                  padding: const EdgeInsets.only(bottom: 16),
                  child: Row(
                    children: [
                      SizedBox(
                        width: 30,
                        child: Text(
                          months[i],
                          style: const TextStyle(
                            fontSize: 14,
                            color: kTextLightColor,
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Column(
                          children: [
                            ClipRRect(
                              borderRadius: BorderRadius.circular(4),
                              child: LinearProgressIndicator(
                                value: (_incomeByMonth[i + 1] ?? 0) /
                                    (max(_getMaxMonthlyAmount(), 1)),
                                backgroundColor: Colors.grey.shade200,
                                valueColor: const AlwaysStoppedAnimation<Color>(
                                    kIncomeColor),
                                minHeight: 8,
                              ),
                            ),
                            const SizedBox(height: 4),
                            ClipRRect(
                              borderRadius: BorderRadius.circular(4),
                              child: LinearProgressIndicator(
                                value: (_expenseByMonth[i + 1] ?? 0) /
                                    (max(_getMaxMonthlyAmount(), 1)),
                                backgroundColor: Colors.grey.shade200,
                                valueColor: const AlwaysStoppedAnimation<Color>(
                                    kExpenseColor),
                                minHeight: 8,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _legendItem({required Color color, required String label}) {
    return Row(
      children: [
        Container(
          width: 16,
          height: 16,
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(4),
          ),
        ),
        const SizedBox(width: 8),
        Text(
          label,
          style: const TextStyle(
            fontSize: 14,
            color: kTextColor,
          ),
        ),
      ],
    );
  }

  Widget _buildTransactionsLists(NumberFormat numberFormat) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Сүүлийн гүйлгээнүүд',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: kTextColor,
          ),
        ),
        const SizedBox(height: 16),
        if (_recentIncomes.isEmpty && _recentExpenses.isEmpty)
          Center(
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 32.0),
              child: Column(
                children: [
                  Icon(
                    Icons.receipt_long_outlined,
                    size: 48,
                    color: Colors.grey.shade400,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Энэ сард гүйлгээ бүртгэгдээгүй байна',
                    style: TextStyle(
                      color: Colors.grey.shade500,
                      fontSize: 16,
                    ),
                  ),
                ],
              ),
            ),
          )
        else
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (_recentIncomes.isNotEmpty) ...[
                const Text(
                  'Орлого',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: kIncomeColor,
                  ),
                ),
                const SizedBox(height: 8),
                _buildTransactionList(
                  transactions: _recentIncomes,
                  isIncome: true,
                  numberFormat: numberFormat,
                ),
                const SizedBox(height: 24),
              ],
              if (_recentExpenses.isNotEmpty) ...[
                const Text(
                  'Зарлага',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: kExpenseColor,
                  ),
                ),
                const SizedBox(height: 8),
                _buildTransactionList(
                  transactions: _recentExpenses,
                  isIncome: false,
                  numberFormat: numberFormat,
                ),
              ],
            ],
          ),
      ],
    );
  }

  Widget _buildTransactionList({
    required List<dynamic> transactions,
    required bool isIncome,
    required NumberFormat numberFormat,
  }) {
    return ListView.builder(
      itemCount: transactions.length,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemBuilder: (context, index) {
        final transaction = transactions[index];

        return Container(
          margin: const EdgeInsets.only(bottom: 12),
          decoration: BoxDecoration(
            color: kCardColor,
            borderRadius: BorderRadius.circular(12),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.03),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: ListTile(
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 16,
              vertical: 8,
            ),
            leading: Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: isIncome
                    ? kIncomeColor.withOpacity(0.1)
                    : kExpenseColor.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(
                isIncome
                    ? Icons.arrow_downward_rounded
                    : Icons.arrow_upward_rounded,
                color: isIncome ? kIncomeColor : kExpenseColor,
              ),
            ),
            title: Text(
              transaction.title,
              style: const TextStyle(
                fontWeight: FontWeight.w600,
                fontSize: 16,
              ),
            ),
            subtitle: Text(
              '${transaction.category} - ${_formatDate(transaction.date)}',
              style: const TextStyle(
                color: kTextLightColor,
                fontSize: 13,
              ),
            ),
            trailing: Text(
              '₮${numberFormat.format(transaction.amount)}',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 16,
                color: isIncome ? kIncomeColor : kExpenseColor,
              ),
            ),
          ),
        );
      },
    );
  }

  Future<void> _loadMonthlyReport() async {
    final authService = Provider.of<AuthService>(context, listen: false);
    final user = authService.getCurrentUser();

    if (user == null) return;

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      // Орлогын мэдээлэл авах
      print(
          'Сарын тайлан хүсэлт илгээж байна: ${user.uid}, ${_selectedMonth.year}, ${_selectedMonth.month}');

      final incomes = await _transactionService.getMonthIncomes(
          user.uid, _selectedMonth.year, _selectedMonth.month);

      print('Орлогын мэдээлэл хүлээж авсан: ${incomes.length}');

      // Зарлагын мэдээлэл авах
      final expenses = await _transactionService.getMonthExpenses(
          user.uid, _selectedMonth.year, _selectedMonth.month);

      print('Зарлагын мэдээлэл хүлээж авсан: ${expenses.length}');

      // Ангилалаар бүлэглэх
      final incomeCategories = <String, double>{};
      final expenseCategories = <String, double>{};

      for (final income in incomes) {
        print(
            'Орлого: ${income.title}, ${income.amount}, ${income.category}, ${income.date}');
        final category = income.category;
        incomeCategories[category] =
            (incomeCategories[category] ?? 0) + income.amount;
      }

      for (final expense in expenses) {
        print(
            'Зарлага: ${expense.title}, ${expense.amount}, ${expense.category}, ${expense.date}');
        final category = expense.category;
        expenseCategories[category] =
            (expenseCategories[category] ?? 0) + expense.amount;
      }

      // Нийт дүн тооцоолох
      final totalIncome =
          incomes.fold<double>(0, (sum, income) => sum + income.amount);

      final totalExpense =
          expenses.fold<double>(0, (sum, expense) => sum + expense.amount);

      print('Нийт орлого: $totalIncome, Нийт зарлага: $totalExpense');

      setState(() {
        _incomeByCategory = incomeCategories;
        _expenseByCategory = expenseCategories;
        _recentIncomes = incomes;
        _recentExpenses = expenses;
        _totalIncome = totalIncome;
        _totalExpense = totalExpense;
        _netBalance = totalIncome - totalExpense;
        _isLoading = false;
      });

      print('Өгөгдөл ачаалж дууслаа');

      // Жилийн тайлан ачаалах
      _loadYearlyReport();
    } catch (e) {
      print('Сарын тайлан ачаалахад алдаа гарлаа: $e');
      setState(() {
        _errorMessage = 'Тайлан ачаалахад алдаа гарлаа: ${e.toString()}';
        _isLoading = false;
      });
    }
  }

  Future<void> _loadYearlyReport() async {
    final authService = Provider.of<AuthService>(context, listen: false);
    final user = authService.getCurrentUser();

    if (user == null) return;

    try {
      print('Жилийн тайлан хүсэлт илгээж байна: ${user.uid}, $_selectedYear');

      final incomeByMonth = <int, double>{};
      final expenseByMonth = <int, double>{};

      // Жилийн тайлан хүсэлт илгээх
      final yearIncomes =
          await _transactionService.getYearIncomes(user.uid, _selectedYear);

      print('Жилийн орлогын мэдээлэл хүлээж авсан: ${yearIncomes.length}');

      final yearExpenses =
          await _transactionService.getYearExpenses(user.uid, _selectedYear);

      print('Жилийн зарлагын мэдээлэл хүлээж авсан: ${yearExpenses.length}');

      // Сараар бүлэглэх
      for (final income in yearIncomes) {
        final month = income.date.month;
        incomeByMonth[month] = (incomeByMonth[month] ?? 0) + income.amount;
      }

      for (final expense in yearExpenses) {
        final month = expense.date.month;
        expenseByMonth[month] = (expenseByMonth[month] ?? 0) + expense.amount;
      }

      print('Сараар ангилсан орлого: $incomeByMonth');
      print('Сараар ангилсан зарлага: $expenseByMonth');

      setState(() {
        _incomeByMonth = incomeByMonth;
        _expenseByMonth = expenseByMonth;
      });
    } catch (e) {
      print('Жилийн тайлан ачаалахад алдаа гарлаа: $e');
    }
  }

  double _getMaxMonthlyAmount() {
    double maxIncome = 0;
    double maxExpense = 0;

    _incomeByMonth.forEach((_, amount) {
      if (amount > maxIncome) maxIncome = amount;
    });

    _expenseByMonth.forEach((_, amount) {
      if (amount > maxExpense) maxExpense = amount;
    });

    return max(maxIncome, maxExpense);
  }

  double max(double a, double b) {
    return a > b ? a : b;
  }

  String _formatDate(DateTime date) {
    return DateFormat('yyyy-MM-dd').format(date);
  }
}
