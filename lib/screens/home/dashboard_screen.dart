import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../services/auth_service.dart';
import '../../services/user_service.dart';
import '../../services/transaction_service.dart';
import '../../services/budget_service.dart';
import '../../models/income_model.dart';
import '../../models/expense_model.dart';
import '../../models/budget_model.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import '../home/home_screen.dart'; // Import for the color constants

// Бүх файлдаа нэмж оруулах өнгөний тогтмол утгууд
const Color kPrimaryColor = Color(0xFF1E88E5);
const Color kSecondaryColor = Color(0xFF26A69A);
const Color kAccentColor = Color(0xFFFFB74D);
const Color kBackgroundColor = Color(0xFFF5F5F7);
const Color kCardColor = Colors.white;
const Color kIncomeColor = Color(0xFF2E7D32);
const Color kExpenseColor = Color(0xFFC62828);
const Color kTextColor = Color(0xFF424242);
const Color kLightTextColor = Color(0xFF757575);

// ThemeData - app/main.dart файлд оруулах
ThemeData appTheme() {
  return ThemeData(
    primaryColor: kPrimaryColor,
    scaffoldBackgroundColor: kBackgroundColor,
    fontFamily: 'Roboto',
    colorScheme: ColorScheme.light(
      primary: kPrimaryColor,
      secondary: kSecondaryColor,
      surface: kCardColor,
    ),
    appBarTheme: const AppBarTheme(
      backgroundColor: kCardColor,
      elevation: 0,
      centerTitle: true,
      iconTheme: IconThemeData(color: kTextColor),
      titleTextStyle: TextStyle(
        color: kTextColor,
        fontSize: 20,
        fontWeight: FontWeight.bold,
      ),
    ),
    cardTheme: CardTheme(
      color: kCardColor,
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
    ),
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: kPrimaryColor,
        foregroundColor: Colors.white,
        padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 20),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        elevation: 2,
      ),
    ),
    tabBarTheme: const TabBarTheme(
      labelColor: kPrimaryColor,
      unselectedLabelColor: kLightTextColor,
      indicator: BoxDecoration(
        border: Border(bottom: BorderSide(color: kPrimaryColor, width: 3)),
      ),
    ),
  );
}

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen>
    with SingleTickerProviderStateMixin {
  final UserService _userService = UserService();
  final TransactionService _transactionService = TransactionService();
  final BudgetService _budgetService = BudgetService();
  bool _isLoading = true;
  double _balance = 0.0;
  double _totalIncome = 0.0;
  double _totalExpense = 0.0;
  List<dynamic> _recentTransactions = [];
  List<BudgetComparisonResult> _budgetComparisons = [];
  String? _errorMessage;
  late AnimationController _animationController;
  late Animation<double> _balanceAnimation;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    );
    _balanceAnimation = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeOutCubic),
    );
    _loadData();
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  Future<void> _loadData() async {
    final authService = Provider.of<AuthService>(context, listen: false);
    final user = authService.getCurrentUser();

    if (user == null) {
      setState(() {
        _isLoading = false;
        _errorMessage = 'Хэрэглэгч нэвтрээгүй байна';
      });
      return;
    }

    try {
      setState(() {
        _isLoading = true;
        _errorMessage = null;
      });

      // Нийт төсвийн үлдэгдлийг тооцоолох
      final balance =
          await _budgetService.calculateTotalBudgetBalance(user.uid);

      // Сүүлийн 5 орлого авах
      final incomes = await _transactionService.getRecentIncomes(user.uid, 5);

      // Сүүлийн 5 зарлага авах
      final expenses = await _transactionService.getRecentExpenses(user.uid, 5);

      // Нийт орлого тооцох
      _totalIncome = incomes.fold(0, (sum, income) => sum + income.amount);

      // Нийт зарлага тооцох
      _totalExpense = expenses.fold(0, (sum, expense) => sum + expense.amount);

      // Орлого, зарлагыг нэгтгэж огноогоор эрэмбэлэх
      final allTransactions = [...incomes, ...expenses];
      allTransactions.sort((a, b) {
        final DateTime aDate =
            a is IncomeModel ? a.date : (a as ExpenseModel).date;
        final DateTime bDate =
            b is IncomeModel ? b.date : (b as ExpenseModel).date;
        return bDate.compareTo(aDate);
      });

      // Төсөв ба бодит зарцуулалтын харьцуулалт
      final now = DateTime.now();
      final startOfMonth = DateTime(now.year, now.month, 1);
      final endOfMonth = DateTime(now.year, now.month + 1, 0);

      final budgetComparisons = await _budgetService.compareBudgetWithActual(
          user.uid, startOfMonth, endOfMonth);

      setState(() {
        _balance = balance;
        _recentTransactions = allTransactions.take(5).toList();
        _budgetComparisons = budgetComparisons;
        _isLoading = false;
      });

      _animationController.forward();
    } catch (e) {
      setState(() {
        _errorMessage = 'Мэдээлэл ачаалахад алдаа гарлаа: ${e.toString()}';
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final authService = Provider.of<AuthService>(context);
    final user = authService.getCurrentUser();
    final size = MediaQuery.of(context).size;
    final numberFormat = NumberFormat("#,##0.00", "mn_MN");

    return Scaffold(
      backgroundColor: kBackgroundColor,
      body: RefreshIndicator(
        onRefresh: _loadData,
        color: kPrimaryColor,
        backgroundColor: Colors.white,
        child: _isLoading
            ? _buildLoadingState()
            : _errorMessage != null
                ? _buildErrorState()
                : SafeArea(
                    child: SingleChildScrollView(
                      physics: const AlwaysScrollableScrollPhysics(),
                      padding: const EdgeInsets.symmetric(horizontal: 16.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const SizedBox(height: 16),
                          _buildUserGreeting(user),
                          const SizedBox(height: 24),
                          _buildBalanceCard(numberFormat),
                          const SizedBox(height: 24),
                          _buildSummaryCards(numberFormat),
                          const SizedBox(height: 24),
                          _buildBudgetComparisonSection(),
                          const SizedBox(height: 24),
                          _buildRecentTransactionsHeader(),
                          const SizedBox(height: 12),
                          _buildRecentTransactionsList(numberFormat),
                          const SizedBox(height: 24),
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
            'Мэдээлэл ачааллаж байна...',
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
            onPressed: _loadData,
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

  Widget _buildUserGreeting(user) {
    final String userName = user?.displayName ?? 'Хэрэглэгч';
    final greeting = _getGreeting();

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              greeting,
              style: const TextStyle(
                fontSize: 14,
                color: kTextLightColor,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              userName,
              style: const TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: kTextColor,
              ),
            ),
          ],
        ),
        GestureDetector(
          onTap: () {
            Navigator.of(context).pushNamed('/profile');
          },
          child: CircleAvatar(
            backgroundColor: kPrimaryColor.withOpacity(0.1),
            radius: 24,
            child: Text(
              (user?.displayName ?? 'Х')[0].toUpperCase(),
              style: const TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: kPrimaryColor,
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildBalanceCard(NumberFormat numberFormat) {
    return AnimatedBuilder(
      animation: _balanceAnimation,
      builder: (context, child) {
        final displayBalance = _balance * _balanceAnimation.value;

        return Container(
          width: double.infinity,
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [kPrimaryColor, Color(0xFF1565C0)],
            ),
            borderRadius: BorderRadius.circular(20),
            boxShadow: [
              BoxShadow(
                color: kPrimaryColor.withOpacity(0.3),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Row(
                children: [
                  Icon(
                    Icons.account_balance_wallet_rounded,
                    color: Colors.white70,
                    size: 20,
                  ),
                  SizedBox(width: 8),
                  Text(
                    'Нийт үлдэгдэл',
                    style: TextStyle(
                      color: Colors.white70,
                      fontSize: 14,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Text(
                '₮ ${numberFormat.format(displayBalance)}',
                style: const TextStyle(
                  fontSize: 32,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
              const SizedBox(height: 16),
            ],
          ),
        );
      },
    );
  }

  Widget _buildSummaryCards(NumberFormat numberFormat) {
    return Row(
      children: [
        Expanded(
          child: _buildSummaryCard(
            title: 'Орлого',
            amount: _totalIncome,
            icon: Icons.arrow_downward_rounded,
            color: kIncomeColor,
            numberFormat: numberFormat,
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: _buildSummaryCard(
            title: 'Зарлага',
            amount: _totalExpense,
            icon: Icons.arrow_upward_rounded,
            color: kExpenseColor,
            numberFormat: numberFormat,
          ),
        ),
      ],
    );
  }

  Widget _buildSummaryCard({
    required String title,
    required double amount,
    required IconData icon,
    required Color color,
    required NumberFormat numberFormat,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: kCardColor,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.03),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(
                  icon,
                  color: color,
                  size: 16,
                ),
              ),
              const SizedBox(width: 8),
              Text(
                title,
                style: TextStyle(
                  color: kTextLightColor,
                  fontSize: 14,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            '₮ ${numberFormat.format(amount)}',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRecentTransactionsHeader() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        const Text(
          'Сүүлийн гүйлгээнүүд',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: kTextColor,
          ),
        ),
        TextButton(
          onPressed: () {
            // Navigate to Income/Expense screen
            Navigator.of(context).pushNamed('/income-expense');
          },
          style: TextButton.styleFrom(
            padding: EdgeInsets.zero,
            minimumSize: const Size(50, 30),
            tapTargetSize: MaterialTapTargetSize.shrinkWrap,
          ),
          child: const Text(
            'Бүгдийг харах',
            style: TextStyle(
              color: kPrimaryColor,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildRecentTransactionsList(NumberFormat numberFormat) {
    if (_recentTransactions.isEmpty) {
      return SizedBox(
        height: 200,
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.hourglass_empty_rounded,
                size: 48,
                color: Colors.grey.shade400,
              ),
              const SizedBox(height: 16),
              const Text(
                'Гүйлгээний түүх байхгүй байна',
                style: TextStyle(
                  color: kTextLightColor,
                  fontSize: 16,
                ),
              ),
            ],
          ),
        ),
      );
    }

    return ListView.builder(
      itemCount: _recentTransactions.length,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemBuilder: (context, index) {
        final transaction = _recentTransactions[index];
        final bool isIncome = transaction is IncomeModel;

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
              _formatDate(transaction.date),
              style: const TextStyle(
                color: kTextLightColor,
                fontSize: 13,
              ),
            ),
            trailing: Text(
              '${isIncome ? "+" : "-"}₮ ${numberFormat.format(transaction.amount)}',
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

  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final yesterday = DateTime(now.year, now.month, now.day - 1);
    final dateToCheck = DateTime(date.year, date.month, date.day);

    if (dateToCheck == today) {
      return 'Өнөөдөр, ${DateFormat('HH:mm').format(date)}';
    } else if (dateToCheck == yesterday) {
      return 'Өчигдөр, ${DateFormat('HH:mm').format(date)}';
    } else {
      return DateFormat('yyyy-MM-dd, HH:mm').format(date);
    }
  }

  String _getGreeting() {
    final hour = DateTime.now().hour;
    if (hour < 12) {
      return 'Өглөөний мэнд,';
    } else if (hour < 17) {
      return 'Өдрийн мэнд,';
    } else {
      return 'Оройн мэнд,';
    }
  }

  Widget _buildBudgetComparisonSection() {
    if (_budgetComparisons.isEmpty) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Төсөв харьцуулалт',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: kTextColor,
            ),
          ),
          const SizedBox(height: 12),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: kCardColor,
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.03),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.account_balance_wallet_outlined,
                  size: 48,
                  color: Colors.grey.shade400,
                ),
                const SizedBox(height: 16),
                const Text(
                  'Төсөв тохируулаагүй байна',
                  style: TextStyle(
                    color: kTextLightColor,
                    fontSize: 16,
                  ),
                ),
                const SizedBox(height: 8),
                ElevatedButton.icon(
                  onPressed: () {
                    // Navigate to budget screen
                    Navigator.pushNamed(context, '/budget');
                  },
                  icon: const Icon(Icons.add),
                  label: const Text('Төсөв тохируулах'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: kPrimaryColor,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(
                      vertical: 12,
                      horizontal: 16,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Төсөв vs. Бодит зарцуулалт',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: kTextColor,
          ),
        ),
        const SizedBox(height: 12),
        ..._budgetComparisons
            .map((comparison) => _buildBudgetComparisonItem(comparison))
            .toList(),
      ],
    );
  }

  Widget _buildBudgetComparisonItem(BudgetComparisonResult comparison) {
    final bool isPositiveBalance = comparison.balance >= 0;

    final statusColor = isPositiveBalance ? Colors.green : kExpenseColor;

    final statusText = isPositiveBalance
        ? 'Үлдэгдэл: ₮${comparison.balance.toStringAsFixed(0)}'
        : 'Алдагдал: ₮${(-comparison.balance).toStringAsFixed(0)}';

    final numberFormat = NumberFormat("#,##0.00", "mn_MN");

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: kCardColor,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.03),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          ListTile(
            contentPadding: const EdgeInsets.all(16),
            title: Text(
              comparison.category,
              style: const TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 16,
              ),
            ),
            subtitle: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 8),
                Text(
                  statusText,
                  style: TextStyle(
                    color: statusColor,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
            child: Column(
              children: [
                // Прогресс хэсэг
                ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: LinearProgressIndicator(
                    value: comparison.usagePercentage / 100,
                    backgroundColor: Colors.grey.shade200,
                    color: comparison.usagePercentage > 100
                        ? Colors.red
                        : Colors.blue,
                    minHeight: 10,
                  ),
                ),
                const SizedBox(height: 8),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Орлого: ₮${numberFormat.format(comparison.incomeAmount)}',
                      style: TextStyle(
                        color: kIncomeColor,
                        fontSize: 14,
                      ),
                    ),
                    Text(
                      'Зарлага: ₮${numberFormat.format(comparison.expenseAmount)}',
                      style: TextStyle(
                        color: kExpenseColor,
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
