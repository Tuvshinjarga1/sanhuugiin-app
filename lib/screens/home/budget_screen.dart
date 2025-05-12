import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../../services/auth_service.dart';
import '../../services/budget_service.dart';
import '../../services/transaction_service.dart';
import '../../models/budget_model.dart';
import '../../models/income_model.dart';
import '../../models/expense_model.dart';
import '../../constants.dart';
// import 'home_screen.dart';
// import 'income_expense_screen.dart';

class BudgetScreen extends StatefulWidget {
  const BudgetScreen({Key? key}) : super(key: key);

  @override
  State<BudgetScreen> createState() => _BudgetScreenState();
}

class _BudgetScreenState extends State<BudgetScreen>
    with SingleTickerProviderStateMixin {
  final BudgetService _budgetService = BudgetService();
  final TransactionService _transactionService = TransactionService();
  late TabController _tabController;
  DateTime _selectedMonth = DateTime.now();
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final authService = Provider.of<AuthService>(context);
    final user = authService.getCurrentUser();

    if (user == null) {
      return const Center(child: Text('Хэрэглэгч нэвтрээгүй байна'));
    }

    return Scaffold(
      appBar: AppBar(
        elevation: 0,
        backgroundColor: kPrimaryColor,
        title: const Text(
          'Төсвийн удирдлага',
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
        // bottom: TabBar(
        //   controller: _tabController,
        //   indicatorColor: Colors.white,
        //   labelColor: Colors.white,
        //   unselectedLabelColor: Colors.white.withOpacity(0.7),
        //   tabs: const [
        //     Tab(text: 'ЗАРЛАГЫН ТӨСӨВ'),
        //     Tab(text: 'ОРЛОГЫН ТӨСӨВ'),
        //   ],
        // ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildBudgetList(user.uid, false),
          _buildBudgetList(user.uid, true),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        backgroundColor: kPrimaryColor,
        onPressed: () {
          bool isIncome = _tabController.index == 1;
          _showAddBudgetDialog(context, user.uid, isIncome);
        },
        child: const Icon(Icons.add),
      ),
    );
  }

  Widget _buildBudgetList(String userId, bool isIncomeTab) {
    return StreamBuilder<List<BudgetModel>>(
      stream: _budgetService.getUserBudgets(userId),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        if (snapshot.hasError) {
          return Center(child: Text('Алдаа гарлаа: ${snapshot.error}'));
        }

        List<BudgetModel> budgets = snapshot.data ?? [];

        if (budgets.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.account_balance_wallet,
                  size: 64,
                  color: Colors.grey[400],
                ),
                const SizedBox(height: 16),
                Text(
                  'Төсөв байхгүй байна',
                  style: TextStyle(
                    fontSize: 16,
                    color: Colors.grey[600],
                  ),
                ),
                const SizedBox(height: 8),
                ElevatedButton.icon(
                  onPressed: () {
                    _showAddBudgetDialog(context, userId, isIncomeTab);
                  },
                  icon: const Icon(Icons.add),
                  label: const Text('Төсөв нэмэх'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: kPrimaryColor,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 24,
                      vertical: 12,
                    ),
                  ),
                ),
              ],
            ),
          );
        }

        return ListView.builder(
          itemCount: budgets.length,
          padding: const EdgeInsets.all(16),
          itemBuilder: (context, index) {
            final budget = budgets[index];
            return _buildBudgetCard(context, budget);
          },
        );
      },
    );
  }

  Widget _buildBudgetCard(BuildContext context, BudgetModel budget) {
    final formatter = NumberFormat('#,##0', 'mn_MN');
    final dateFormatter = DateFormat('yyyy-MM-dd');

    final startDate = dateFormatter.format(budget.startDate);
    final endDate = dateFormatter.format(budget.endDate);

    // Төсвийн дэлгэрэнгүй мэдээллийг авах
    return FutureBuilder<Map<String, dynamic>>(
      future: _budgetService.getBudgetDetails(budget),
      builder: (context, snapshot) {
        double totalIncome = 0;
        double totalExpense = 0;
        double balance = 0;
        double usagePercentage = 0;
        bool isOverBudget = false;

        if (snapshot.hasData) {
          totalIncome = snapshot.data!['totalIncome'];
          totalExpense = snapshot.data!['totalExpense'];
          balance = snapshot.data!['balance'];
          usagePercentage = snapshot.data!['usagePercentage'];
          isOverBudget = snapshot.data!['isOverBudget'];
        }

        return Card(
          margin: const EdgeInsets.only(bottom: 16),
          elevation: 2,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          child: InkWell(
            onTap: () => _showBudgetDetails(context, budget),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              budget.title,
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 18,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              budget.category,
                              style: TextStyle(
                                color: Colors.grey[600],
                                fontSize: 14,
                              ),
                            ),
                          ],
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 12, vertical: 6),
                        decoration: BoxDecoration(
                          color: Colors.blue.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: Text(
                          '₮${formatter.format(budget.amount)}',
                          style: const TextStyle(
                            color: Colors.blue,
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Icon(
                        Icons.date_range,
                        size: 16,
                        color: Colors.grey[600],
                      ),
                      const SizedBox(width: 4),
                      Text(
                        '$startDate аас $endDate хүртэл',
                        style: TextStyle(
                          color: Colors.grey[600],
                          fontSize: 14,
                        ),
                      ),
                    ],
                  ),
                  if (budget.note.isNotEmpty) ...[
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Icon(
                          Icons.notes,
                          size: 16,
                          color: Colors.grey[600],
                        ),
                        const SizedBox(width: 4),
                        Expanded(
                          child: Text(
                            budget.note,
                            style: TextStyle(
                              color: Colors.grey[600],
                              fontSize: 14,
                            ),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                  ],
                  const SizedBox(height: 12),

                  // Төсвийн орлого, зарлагын мэдээлэл
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            'Орлого: ₮${formatter.format(totalIncome)}',
                            style: const TextStyle(
                              color: kIncomeColor,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          Text(
                            'Зарлага: ₮${formatter.format(totalExpense)}',
                            style: TextStyle(
                              color: kExpenseColor,
                              fontWeight: isOverBudget
                                  ? FontWeight.bold
                                  : FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 6),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            'Үлдэгдэл: ₮${formatter.format(balance)}',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              color: balance >= 0 ? Colors.green : Colors.red,
                            ),
                          ),
                          Text(
                            'Зарцуулалт: ${usagePercentage.toStringAsFixed(0)}%',
                            style: TextStyle(
                              fontSize: 14,
                              color:
                                  isOverBudget ? Colors.red : Colors.grey[600],
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  // Зарцуулалтын прогресс
                  LinearProgressIndicator(
                    value: usagePercentage / 100,
                    minHeight: 8,
                    backgroundColor: Colors.grey[200],
                    valueColor: AlwaysStoppedAnimation<Color>(
                      isOverBudget ? Colors.red : Colors.blue,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      TextButton.icon(
                        onPressed: () => _showEditBudgetDialog(context, budget),
                        icon: const Icon(Icons.edit, size: 18),
                        label: const Text('Засах'),
                        style: TextButton.styleFrom(
                          foregroundColor: kPrimaryColor,
                        ),
                      ),
                      const SizedBox(width: 8),
                      TextButton.icon(
                        onPressed: () =>
                            _showDeleteBudgetDialog(context, budget),
                        icon: const Icon(Icons.delete, size: 18),
                        label: const Text('Устгах'),
                        style: TextButton.styleFrom(
                          foregroundColor: Colors.red,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  void _showBudgetDetails(BuildContext context, BudgetModel budget) {
    final authService = Provider.of<AuthService>(context, listen: false);
    final user = authService.getCurrentUser();

    if (user == null) return;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return _buildBudgetDetailSheet(context, user.uid, budget);
      },
    );
  }

  Widget _buildBudgetDetailSheet(
      BuildContext context, String userId, BudgetModel budget) {
    final formatter = NumberFormat('#,##0', 'mn_MN');
    final dateFormatter = DateFormat('yyyy-MM-dd');

    return FutureBuilder<Map<String, dynamic>>(
      future: _budgetService.getBudgetDetails(budget),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        if (snapshot.hasError) {
          return Center(child: Text('Алдаа гарлаа: ${snapshot.error}'));
        }

        final budgetDetails = snapshot.data!;
        final totalIncome = budgetDetails['totalIncome'];
        final totalExpense = budgetDetails['totalExpense'];
        final balance = budgetDetails['balance'];
        final usagePercentage = budgetDetails['usagePercentage'];
        final isOverBudget = budgetDetails['isOverBudget'];

        return DraggableScrollableSheet(
          initialChildSize: 0.9,
          maxChildSize: 0.95,
          minChildSize: 0.6,
          expand: false,
          builder: (context, scrollController) {
            return Container(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Center(
                    child: Container(
                      width: 40,
                      height: 5,
                      decoration: BoxDecoration(
                        color: Colors.grey[300],
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Text(
                          budget.title,
                          style: const TextStyle(
                            fontSize: 22,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      IconButton(
                        onPressed: () => Navigator.pop(context),
                        icon: const Icon(Icons.close),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Container(
                    padding:
                        const EdgeInsets.symmetric(vertical: 4, horizontal: 10),
                    decoration: BoxDecoration(
                      color: Colors.blue,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      budget.category,
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Card(
                    elevation: 2,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _buildDetailRow(
                              'Төсөв:', '₮${formatter.format(budget.amount)}'),
                          _buildDetailRow(
                              'Орлого:', '₮${formatter.format(totalIncome)}'),
                          _buildDetailRow(
                              'Зарлага:', '₮${formatter.format(totalExpense)}'),
                          _buildDetailRow(
                            'Үлдэгдэл:',
                            '₮${formatter.format(balance)}',
                            valueColor:
                                balance >= 0 ? Colors.green : Colors.red,
                          ),
                          _buildDetailRow('Огноо:',
                              '${dateFormatter.format(budget.startDate)} - ${dateFormatter.format(budget.endDate)}'),
                          if (budget.note.isNotEmpty)
                            _buildDetailRow('Тэмдэглэл:', budget.note),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  // Зарцуулалтын прогресс
                  Card(
                    elevation: 2,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Төсвийн ашиглалт: ${usagePercentage.toStringAsFixed(0)}%',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              color: isOverBudget ? Colors.red : Colors.blue,
                            ),
                          ),
                          const SizedBox(height: 8),
                          LinearProgressIndicator(
                            value: usagePercentage / 100,
                            minHeight: 10,
                            backgroundColor: Colors.grey[200],
                            valueColor: AlwaysStoppedAnimation<Color>(
                              isOverBudget ? Colors.red : Colors.blue,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            isOverBudget
                                ? 'Төсвийг ${(usagePercentage - 100).toStringAsFixed(0)}% буюу ₮${formatter.format(totalExpense - budget.amount)} -өөр хэтрүүлсэн байна'
                                : 'Төсөвт ${(100 - usagePercentage).toStringAsFixed(0)}% буюу ₮${formatter.format(budget.amount - totalExpense)} үлдсэн байна',
                            style: TextStyle(
                              fontSize: 14,
                              color: isOverBudget ? Colors.red : Colors.green,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'Гүйлгээний жагсаалт',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Row(
                        children: [
                          ElevatedButton.icon(
                            onPressed: () {
                              Navigator.pop(context);
                              _showAddIncomeToBudgetDialog(
                                  context, userId, budget);
                            },
                            icon: const Icon(Icons.add),
                            label: const Text('Орлого'),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: kIncomeColor,
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 12, vertical: 8),
                            ),
                          ),
                          const SizedBox(width: 8),
                          ElevatedButton.icon(
                            onPressed: () {
                              Navigator.pop(context);
                              _showAddExpenseToBudgetDialog(
                                  context, userId, budget);
                            },
                            icon: const Icon(Icons.add),
                            label: const Text('Зарлага'),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: kExpenseColor,
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 12, vertical: 8),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Expanded(
                    child: _buildBudgetTransactions(
                        userId, budget, scrollController),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildDetailRow(String label, String value, {Color? valueColor}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 120,
            child: Text(
              label,
              style: const TextStyle(
                fontWeight: FontWeight.w500,
                color: Colors.black54,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: TextStyle(
                fontWeight: FontWeight.w600,
                color: valueColor,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBudgetTransactions(
      String userId, BudgetModel budget, ScrollController scrollController) {
    // Төсөвийн гүйлгээний жагсаалт
    return Column(
      children: [
        // Орлогын жагсаалт
        Expanded(
          child: StreamBuilder<List<IncomeModel>>(
            stream: _transactionService.getBudgetIncomes(userId, budget.id),
            builder: (context, incomesSnapshot) {
              // Зарлагын жагсаалт
              return StreamBuilder<List<ExpenseModel>>(
                stream:
                    _transactionService.getBudgetExpenses(userId, budget.id),
                builder: (context, expensesSnapshot) {
                  if (incomesSnapshot.connectionState ==
                          ConnectionState.waiting ||
                      expensesSnapshot.connectionState ==
                          ConnectionState.waiting) {
                    return const Center(child: CircularProgressIndicator());
                  }

                  if (incomesSnapshot.hasError || expensesSnapshot.hasError) {
                    return Center(
                      child: SelectableText(
                          'Алдаа гарлаа: ${incomesSnapshot.error ?? expensesSnapshot.error}'),
                    );
                  }

                  final incomes = incomesSnapshot.data ?? [];
                  final expenses = expensesSnapshot.data ?? [];

                  // Орлого зарлагыг нэгтгэж огноогоор эрэмбэлэх
                  final allTransactions = <dynamic>[];
                  allTransactions.addAll(incomes);
                  allTransactions.addAll(expenses);

                  if (allTransactions.isEmpty) {
                    return const Center(
                      child: Text('Одоогоор бүртгэгдсэн гүйлгээ байхгүй байна'),
                    );
                  }

                  // Огноогоор эрэмбэлэх
                  allTransactions.sort((a, b) {
                    final DateTime aDate =
                        a is IncomeModel ? a.date : (a as ExpenseModel).date;
                    final DateTime bDate =
                        b is IncomeModel ? b.date : (b as ExpenseModel).date;
                    return bDate.compareTo(aDate);
                  });

                  return ListView.builder(
                    controller: scrollController,
                    itemCount: allTransactions.length,
                    itemBuilder: (context, index) {
                      final transaction = allTransactions[index];
                      final bool isIncome = transaction is IncomeModel;

                      return _buildTransactionItem(
                        title: isIncome
                            ? (transaction as IncomeModel).title
                            : (transaction as ExpenseModel).title,
                        amount: isIncome
                            ? (transaction as IncomeModel).amount
                            : (transaction as ExpenseModel).amount,
                        date: isIncome
                            ? (transaction as IncomeModel).date
                            : (transaction as ExpenseModel).date,
                        isIncome: isIncome,
                      );
                    },
                  );
                },
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildTransactionItem({
    required String title,
    required double amount,
    required DateTime date,
    required bool isIncome,
  }) {
    final formatter = NumberFormat('#,##0', 'mn_MN');
    final dateFormatter = DateFormat('yyyy-MM-dd');

    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: ListTile(
        leading: Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: isIncome
                ? kIncomeColor.withOpacity(0.1)
                : kExpenseColor.withOpacity(0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(
            isIncome ? Icons.arrow_downward : Icons.arrow_upward,
            color: isIncome ? kIncomeColor : kExpenseColor,
          ),
        ),
        title: Text(
          title,
          style: const TextStyle(
            fontWeight: FontWeight.w600,
          ),
        ),
        subtitle: Text(dateFormatter.format(date)),
        trailing: Text(
          '₮${formatter.format(amount)}',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: isIncome ? kIncomeColor : kExpenseColor,
          ),
        ),
      ),
    );
  }

  void _showAddIncomeToBudgetDialog(
      BuildContext context, String userId, BudgetModel budget) {
    final titleController = TextEditingController();
    final amountController = TextEditingController();
    final noteController = TextEditingController();
    DateTime selectedDate = DateTime.now();

    // Төсвийн хугацаанд байгаа эсэхийг шалгах
    if (selectedDate.isAfter(budget.endDate) ||
        selectedDate.isBefore(budget.startDate)) {
      selectedDate = budget.startDate;
    }

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text('${budget.title} төсөвт орлого нэмэх'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: titleController,
                  decoration: const InputDecoration(
                    labelText: 'Гарчиг',
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: amountController,
                  decoration: const InputDecoration(
                    labelText: 'Дүн',
                    border: OutlineInputBorder(),
                    prefixText: '₮',
                  ),
                  keyboardType: TextInputType.number,
                ),
                const SizedBox(height: 16),
                InkWell(
                  onTap: () async {
                    final picked = await showDatePicker(
                      context: context,
                      initialDate: selectedDate,
                      firstDate: budget.startDate,
                      lastDate: budget.endDate,
                    );
                    if (picked != null) {
                      selectedDate = picked;
                    }
                  },
                  child: InputDecorator(
                    decoration: const InputDecoration(
                      labelText: 'Огноо',
                      border: OutlineInputBorder(),
                    ),
                    child: Text(
                      DateFormat('yyyy-MM-dd').format(selectedDate),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: noteController,
                  decoration: const InputDecoration(
                    labelText: 'Тэмдэглэл',
                    border: OutlineInputBorder(),
                  ),
                  maxLines: 3,
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('БОЛИХ'),
            ),
            ElevatedButton(
              onPressed: () {
                if (titleController.text.isEmpty ||
                    amountController.text.isEmpty) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                        content: Text('Гарчиг, дүн заавал оруулна уу')),
                  );
                  return;
                }

                final income = IncomeModel(
                  id: '',
                  userId: userId,
                  title: titleController.text,
                  category: budget.category,
                  amount: double.tryParse(amountController.text) ?? 0,
                  date: selectedDate,
                  note: noteController.text,
                  budgetId: budget.id,
                );

                _transactionService.addIncomeWithBudget(income).then((_) {
                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Орлого амжилттай нэмэгдлээ')),
                  );
                }).catchError((error) {
                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Алдаа гарлаа: $error')),
                  );
                });
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: kIncomeColor,
              ),
              child: const Text('НЭМЭХ'),
            ),
          ],
        );
      },
    );
  }

  void _showAddExpenseToBudgetDialog(
      BuildContext context, String userId, BudgetModel budget) {
    final titleController = TextEditingController();
    final amountController = TextEditingController();
    final noteController = TextEditingController();
    DateTime selectedDate = DateTime.now();

    // Төсвийн хугацаанд байгаа эсэхийг шалгах
    if (selectedDate.isAfter(budget.endDate) ||
        selectedDate.isBefore(budget.startDate)) {
      selectedDate = budget.startDate;
    }

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text('${budget.title} төсөвт зарлага нэмэх'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: titleController,
                  decoration: const InputDecoration(
                    labelText: 'Гарчиг',
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: amountController,
                  decoration: const InputDecoration(
                    labelText: 'Дүн',
                    border: OutlineInputBorder(),
                    prefixText: '₮',
                  ),
                  keyboardType: TextInputType.number,
                ),
                const SizedBox(height: 16),
                InkWell(
                  onTap: () async {
                    final picked = await showDatePicker(
                      context: context,
                      initialDate: selectedDate,
                      firstDate: budget.startDate,
                      lastDate: budget.endDate,
                    );
                    if (picked != null) {
                      selectedDate = picked;
                    }
                  },
                  child: InputDecorator(
                    decoration: const InputDecoration(
                      labelText: 'Огноо',
                      border: OutlineInputBorder(),
                    ),
                    child: Text(
                      DateFormat('yyyy-MM-dd').format(selectedDate),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: noteController,
                  decoration: const InputDecoration(
                    labelText: 'Тэмдэглэл',
                    border: OutlineInputBorder(),
                  ),
                  maxLines: 3,
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('БОЛИХ'),
            ),
            ElevatedButton(
              onPressed: () {
                if (titleController.text.isEmpty ||
                    amountController.text.isEmpty) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                        content: Text('Гарчиг, дүн заавал оруулна уу')),
                  );
                  return;
                }

                final expense = ExpenseModel(
                  id: '',
                  userId: userId,
                  title: titleController.text,
                  category: budget.category,
                  amount: double.tryParse(amountController.text) ?? 0,
                  date: selectedDate,
                  note: noteController.text,
                  budgetId: budget.id,
                );

                _transactionService.addExpenseWithBudget(expense).then((_) {
                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                        content: Text('Зарлага амжилттай нэмэгдлээ')),
                  );
                }).catchError((error) {
                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Алдаа гарлаа: $error')),
                  );
                });
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: kExpenseColor,
              ),
              child: const Text('НЭМЭХ'),
            ),
          ],
        );
      },
    );
  }

  void _showAddBudgetDialog(
      BuildContext context, String userId, bool isIncome) {
    final titleController = TextEditingController();
    final amountController = TextEditingController();
    final noteController = TextEditingController();

    DateTime startDate = DateTime.now();
    DateTime endDate =
        DateTime(startDate.year, startDate.month + 1, 0); // Сарын сүүлийн өдөр

    String selectedCategory =
        isIncome ? incomeCategories[0] : expenseCategories[0];

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title:
              Text(isIncome ? 'Орлогын төсөв нэмэх' : 'Зарлагын төсөв нэмэх'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: titleController,
                  decoration: const InputDecoration(
                    labelText: 'Гарчиг',
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: amountController,
                  decoration: const InputDecoration(
                    labelText: 'Дүн',
                    border: OutlineInputBorder(),
                    prefixText: '₮',
                  ),
                  keyboardType: TextInputType.number,
                ),
                const SizedBox(height: 16),
                DropdownButtonFormField<String>(
                  value: selectedCategory,
                  decoration: const InputDecoration(
                    labelText: 'Ангилал',
                    border: OutlineInputBorder(),
                  ),
                  items: (isIncome ? incomeCategories : expenseCategories)
                      .map((category) {
                    return DropdownMenuItem<String>(
                      value: category,
                      child: Text(category),
                    );
                  }).toList(),
                  onChanged: (value) {
                    if (value != null) {
                      selectedCategory = value;
                    }
                  },
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(
                      child: InkWell(
                        onTap: () async {
                          final picked = await showDatePicker(
                            context: context,
                            initialDate: startDate,
                            firstDate: DateTime(2020),
                            lastDate: DateTime(2100),
                          );
                          if (picked != null) {
                            startDate = picked;
                          }
                        },
                        child: InputDecorator(
                          decoration: const InputDecoration(
                            labelText: 'Эхлэх огноо',
                            border: OutlineInputBorder(),
                          ),
                          child: Text(
                            DateFormat('yyyy-MM-dd').format(startDate),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: InkWell(
                        onTap: () async {
                          final picked = await showDatePicker(
                            context: context,
                            initialDate: endDate,
                            firstDate: DateTime(2020),
                            lastDate: DateTime(2100),
                          );
                          if (picked != null) {
                            endDate = picked;
                          }
                        },
                        child: InputDecorator(
                          decoration: const InputDecoration(
                            labelText: 'Дуусах огноо',
                            border: OutlineInputBorder(),
                          ),
                          child: Text(
                            DateFormat('yyyy-MM-dd').format(endDate),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: noteController,
                  decoration: const InputDecoration(
                    labelText: 'Тэмдэглэл',
                    border: OutlineInputBorder(),
                  ),
                  maxLines: 3,
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('БОЛИХ'),
            ),
            ElevatedButton(
              onPressed: () {
                if (titleController.text.isEmpty ||
                    amountController.text.isEmpty) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                        content: Text('Гарчиг, дүн заавал оруулна уу')),
                  );
                  return;
                }

                if (endDate.isBefore(startDate)) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                        content: Text(
                            'Дуусах огноо нь эхлэх огнооноос хойш байх ёстой')),
                  );
                  return;
                }

                final budget = BudgetModel(
                  id: '',
                  userId: userId,
                  title: titleController.text,
                  category: selectedCategory,
                  amount: double.tryParse(amountController.text) ?? 0,
                  startDate: startDate,
                  endDate: endDate,
                  note: noteController.text,
                );

                _budgetService.addBudget(budget).then((_) {
                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Төсөв амжилттай нэмэгдлээ'),
                    ),
                  );
                }).catchError((error) {
                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Алдаа гарлаа: $error')),
                  );
                });
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: kPrimaryColor,
              ),
              child: const Text('НЭМЭХ'),
            ),
          ],
        );
      },
    );
  }

  void _showEditBudgetDialog(BuildContext context, BudgetModel budget) {
    final titleController = TextEditingController(text: budget.title);
    final amountController =
        TextEditingController(text: budget.amount.toString());
    final noteController = TextEditingController(text: budget.note);

    DateTime startDate = budget.startDate;
    DateTime endDate = budget.endDate;
    String selectedCategory = budget.category;

    // Check if the category exists in our lists
    List<String> categories = [...expenseCategories, ...incomeCategories];
    if (!categories.contains(selectedCategory)) {
      selectedCategory = categories[0];
    }

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Төсөв засах'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: titleController,
                  decoration: const InputDecoration(
                    labelText: 'Гарчиг',
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: amountController,
                  decoration: const InputDecoration(
                    labelText: 'Дүн',
                    border: OutlineInputBorder(),
                    prefixText: '₮',
                  ),
                  keyboardType: TextInputType.number,
                ),
                const SizedBox(height: 16),
                DropdownButtonFormField<String>(
                  value: selectedCategory,
                  decoration: const InputDecoration(
                    labelText: 'Ангилал',
                    border: OutlineInputBorder(),
                  ),
                  items: categories.map((category) {
                    return DropdownMenuItem<String>(
                      value: category,
                      child: Text(category),
                    );
                  }).toList(),
                  onChanged: (value) {
                    if (value != null) {
                      selectedCategory = value;
                    }
                  },
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(
                      child: InkWell(
                        onTap: () async {
                          final picked = await showDatePicker(
                            context: context,
                            initialDate: startDate,
                            firstDate: DateTime(2020),
                            lastDate: DateTime(2100),
                          );
                          if (picked != null) {
                            startDate = picked;
                          }
                        },
                        child: InputDecorator(
                          decoration: const InputDecoration(
                            labelText: 'Эхлэх огноо',
                            border: OutlineInputBorder(),
                          ),
                          child: Text(
                            DateFormat('yyyy-MM-dd').format(startDate),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: InkWell(
                        onTap: () async {
                          final picked = await showDatePicker(
                            context: context,
                            initialDate: endDate,
                            firstDate: DateTime(2020),
                            lastDate: DateTime(2100),
                          );
                          if (picked != null) {
                            endDate = picked;
                          }
                        },
                        child: InputDecorator(
                          decoration: const InputDecoration(
                            labelText: 'Дуусах огноо',
                            border: OutlineInputBorder(),
                          ),
                          child: Text(
                            DateFormat('yyyy-MM-dd').format(endDate),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: noteController,
                  decoration: const InputDecoration(
                    labelText: 'Тэмдэглэл',
                    border: OutlineInputBorder(),
                  ),
                  maxLines: 3,
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('БОЛИХ'),
            ),
            ElevatedButton(
              onPressed: () {
                if (titleController.text.isEmpty ||
                    amountController.text.isEmpty) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                        content: Text('Гарчиг, дүн заавал оруулна уу')),
                  );
                  return;
                }

                if (endDate.isBefore(startDate)) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                        content: Text(
                            'Дуусах огноо нь эхлэх огнооноос хойш байх ёстой')),
                  );
                  return;
                }

                final updatedBudget = BudgetModel(
                  id: budget.id,
                  userId: budget.userId,
                  title: titleController.text,
                  category: selectedCategory,
                  amount: double.tryParse(amountController.text) ?? 0,
                  startDate: startDate,
                  endDate: endDate,
                  note: noteController.text,
                );

                _budgetService.updateBudget(updatedBudget).then((_) {
                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Төсөв амжилттай шинэчлэгдлээ'),
                    ),
                  );
                }).catchError((error) {
                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Алдаа гарлаа: $error')),
                  );
                });
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: kPrimaryColor,
              ),
              child: const Text('ХАДГАЛАХ'),
            ),
          ],
        );
      },
    );
  }

  void _showDeleteBudgetDialog(BuildContext context, BudgetModel budget) {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Төсөв устгах'),
          content: Text(
            'Та "${budget.title}" төсвийг устгахдаа итгэлтэй байна уу?',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('БОЛИХ'),
            ),
            ElevatedButton(
              onPressed: () {
                _budgetService.deleteBudget(budget).then((_) {
                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Төсөв амжилттай устгагдлаа')),
                  );
                }).catchError((error) {
                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Алдаа гарлаа: $error')),
                  );
                });
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red,
              ),
              child: const Text('УСТГАХ'),
            ),
          ],
        );
      },
    );
  }
}
