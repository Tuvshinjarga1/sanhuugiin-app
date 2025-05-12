import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../services/auth_service.dart';
import '../../services/transaction_service.dart';
import '../../models/income_model.dart';
import '../../models/expense_model.dart';

// Орлогын ангилалууд
const List<String> incomeCategories = [
  'Цалин',
  'Бизнесийн орлого',
  'Тэтгэвэр, тэтгэмж',
  'Шагнал, урамшуулал',
  'Зээл',
  'Бусад орлого',
];

// Зарлагын ангилалууд
const List<String> expenseCategories = [
  'Хүнс',
  'Гэр ахуй',
  'Хувцас',
  'Гоо сайхан',
  'Боловсрол',
  'Эрүүл мэнд',
  'Зээл төлөлт',
  'Унаа, тээвэр',
  'Утас, интернэт',
  'Бусад зарлага',
];

class IncomeExpenseScreen extends StatefulWidget {
  const IncomeExpenseScreen({super.key});

  @override
  State<IncomeExpenseScreen> createState() => _IncomeExpenseScreenState();
}

class _IncomeExpenseScreenState extends State<IncomeExpenseScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final TransactionService _transactionService = TransactionService();

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
        backgroundColor: Theme.of(context).scaffoldBackgroundColor,
        title: const Text(
          'Орлого & Зарлага',
          style: TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.bold,
            color: Colors.black87,
          ),
        ),
        automaticallyImplyLeading: false,
        bottom: TabBar(
          controller: _tabController,
          onTap: (index) {
            setState(() {
              // Индексийг шинэчлэх
            });
          },
          tabs: [
            Tab(
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: const [
                  Icon(Icons.arrow_downward, size: 20),
                  SizedBox(width: 8),
                  Text('ОРЛОГО'),
                ],
              ),
            ),
            Tab(
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: const [
                  Icon(Icons.arrow_upward, size: 20),
                  SizedBox(width: 8),
                  Text('ЗАРЛАГА'),
                ],
              ),
            ),
          ],
          labelColor: Colors.blue,
          unselectedLabelColor: Colors.grey,
          indicatorColor: Colors.blue,
          indicatorWeight: 3,
          indicatorSize: TabBarIndicatorSize.label,
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildIncomeTab(user.uid, user),
          _buildExpenseTab(user.uid),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {
          if (_tabController.index == 0) {
            _showAddIncomeDialog(context, user.uid);
          } else {
            _showAddExpenseDialog(context, user.uid);
          }
        },
        backgroundColor: Colors.blue,
        icon: const Icon(Icons.add),
        label:
            Text(_tabController.index == 0 ? 'Орлого нэмэх' : 'Зарлага нэмэх'),
      ),
    );
  }

  Widget _buildIncomeTab(String userId, dynamic user) {
    return StreamBuilder<List<IncomeModel>>(
      stream: _transactionService.getUserIncomes(userId),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        if (snapshot.hasError) {
          return Center(
              child: SelectableText('Алдаа гарлаа: ${snapshot.error}'));
        }

        final incomes = snapshot.data ?? [];

        if (incomes.isEmpty) {
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
                  'Одоогоор орлогын мэдээлэл байхгүй байна',
                  style: TextStyle(
                    fontSize: 16,
                    color: Colors.grey[600],
                  ),
                ),
                const SizedBox(height: 8),
                ElevatedButton.icon(
                  onPressed: () => _showAddIncomeDialog(context, user.uid),
                  icon: const Icon(Icons.add),
                  label: const Text('Орлого нэмэх'),
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 24, vertical: 12),
                  ),
                ),
              ],
            ),
          );
        }

        return ListView.builder(
          itemCount: incomes.length,
          padding: const EdgeInsets.all(8.0),
          itemBuilder: (context, index) {
            final income = incomes[index];
            return Card(
              elevation: 2,
              margin:
                  const EdgeInsets.symmetric(vertical: 6.0, horizontal: 8.0),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              child: Container(
                decoration: BoxDecoration(
                  border: Border(
                    left: BorderSide(
                      color: Colors.green, // Use Colors.red for expenses
                      width: 4,
                    ),
                  ),
                ),
                child: ListTile(
                  contentPadding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  leading: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Colors.green
                          .withOpacity(0.1), // Use Colors.red for expenses
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Icon(
                      Icons
                          .arrow_downward, // Use Icons.arrow_upward for expenses
                      color: Colors.green, // Use Colors.red for expenses
                    ),
                  ),
                  title: Text(
                    income.title,
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                  subtitle: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          Icon(
                            Icons.category,
                            size: 16,
                            color: Colors.grey[600],
                          ),
                          const SizedBox(width: 4),
                          Text(
                            income.category,
                            style: TextStyle(color: Colors.grey[600]),
                          ),
                          const SizedBox(width: 12),
                          Icon(
                            Icons.calendar_today,
                            size: 16,
                            color: Colors.grey[600],
                          ),
                          const SizedBox(width: 4),
                          Text(
                            _formatDate(income.date),
                            style: TextStyle(color: Colors.grey[600]),
                          ),
                        ],
                      ),
                    ],
                  ),
                  trailing: Text(
                    '₮${income.amount.toStringAsFixed(0)}',
                    style: const TextStyle(
                      color: Colors.green, // Use Colors.red for expenses
                      fontWeight: FontWeight.bold,
                      fontSize: 18,
                    ),
                  ),
                  onTap: () => _showIncomeDetails(context, income),
                ),
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildExpenseTab(String userId) {
    return StreamBuilder<List<ExpenseModel>>(
      stream: _transactionService.getUserExpenses(userId),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        if (snapshot.hasError) {
          return Center(
              child: SelectableText('Алдаа гарлаа: ${snapshot.error}'));
        }

        final expenses = snapshot.data ?? [];

        if (expenses.isEmpty) {
          return const Center(child: Text('Зарлагын мэдээлэл байхгүй байна'));
        }

        return ListView.builder(
          itemCount: expenses.length,
          padding: const EdgeInsets.all(8.0),
          itemBuilder: (context, index) {
            final expense = expenses[index];
            return Card(
              elevation: 2,
              margin:
                  const EdgeInsets.symmetric(vertical: 6.0, horizontal: 8.0),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              child: Container(
                decoration: BoxDecoration(
                  border: Border(
                    left: BorderSide(
                      color: Colors.red, // Use Colors.red for expenses
                      width: 4,
                    ),
                  ),
                ),
                child: ListTile(
                  contentPadding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  leading: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Colors.red
                          .withOpacity(0.1), // Use Colors.red for expenses
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Icon(
                      Icons.arrow_upward, // Use Icons.arrow_upward for expenses
                      color: Colors.red, // Use Colors.red for expenses
                    ),
                  ),
                  title: Text(
                    expense.title,
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                  subtitle: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          Icon(
                            Icons.category,
                            size: 16,
                            color: Colors.grey[600],
                          ),
                          const SizedBox(width: 4),
                          Text(
                            expense.category,
                            style: TextStyle(color: Colors.grey[600]),
                          ),
                          const SizedBox(width: 12),
                          Icon(
                            Icons.calendar_today,
                            size: 16,
                            color: Colors.grey[600],
                          ),
                          const SizedBox(width: 4),
                          Text(
                            _formatDate(expense.date),
                            style: TextStyle(color: Colors.grey[600]),
                          ),
                        ],
                      ),
                    ],
                  ),
                  trailing: Text(
                    '₮${expense.amount.toStringAsFixed(0)}',
                    style: const TextStyle(
                      color: Colors.red,
                      fontWeight: FontWeight.bold,
                      fontSize: 18,
                    ),
                  ),
                  onTap: () => _showExpenseDetails(context, expense),
                ),
              ),
            );
          },
        );
      },
    );
  }

  void _showIncomeDetails(BuildContext context, IncomeModel income) {
    showModalBottomSheet(
      context: context,
      builder: (context) {
        return Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Орлогын мэдээлэл',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 16),
              _buildDetailRow('Гарчиг', income.title),
              _buildDetailRow('Ангилал', income.category),
              _buildDetailRow('Дүн', '₮${income.amount.toStringAsFixed(2)}'),
              _buildDetailRow('Огноо', _formatDate(income.date)),
              if (income.note.isNotEmpty)
                _buildDetailRow('Тэмдэглэл', income.note),
              const SizedBox(height: 16),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  ElevatedButton.icon(
                    onPressed: () {
                      Navigator.pop(context);
                      _showEditIncomeDialog(context, income);
                    },
                    icon: const Icon(Icons.edit),
                    label: const Text('Засах'),
                  ),
                  ElevatedButton.icon(
                    onPressed: () {
                      Navigator.pop(context);
                      _showDeleteIncomeDialog(context, income);
                    },
                    icon: const Icon(Icons.delete),
                    style:
                        ElevatedButton.styleFrom(backgroundColor: Colors.red),
                    label: const Text('Устгах'),
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }

  void _showExpenseDetails(BuildContext context, ExpenseModel expense) {
    showModalBottomSheet(
      context: context,
      builder: (context) {
        return Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Зарлагын мэдээлэл',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 16),
              _buildDetailRow('Гарчиг', expense.title),
              _buildDetailRow('Ангилал', expense.category),
              _buildDetailRow('Дүн', '₮${expense.amount.toStringAsFixed(2)}'),
              _buildDetailRow('Огноо', _formatDate(expense.date)),
              if (expense.note.isNotEmpty)
                _buildDetailRow('Тэмдэглэл', expense.note),
              const SizedBox(height: 16),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  ElevatedButton.icon(
                    onPressed: () {
                      Navigator.pop(context);
                      _showEditExpenseDialog(context, expense);
                    },
                    icon: const Icon(Icons.edit),
                    label: const Text('Засах'),
                  ),
                  ElevatedButton.icon(
                    onPressed: () {
                      Navigator.pop(context);
                      _showDeleteExpenseDialog(context, expense);
                    },
                    icon: const Icon(Icons.delete),
                    style:
                        ElevatedButton.styleFrom(backgroundColor: Colors.red),
                    label: const Text('Устгах'),
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            '$label:',
            style: const TextStyle(fontWeight: FontWeight.bold),
          ),
          Text(value),
        ],
      ),
    );
  }

  String _formatDate(DateTime date) {
    return '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
  }

  void _showAddIncomeDialog(BuildContext context, String userId) {
    final titleController = TextEditingController();
    final amountController = TextEditingController();
    final noteController = TextEditingController();
    DateTime selectedDate = DateTime.now();
    String selectedCategory = incomeCategories[0];
    String? selectedBudgetId;
    List<Map<String, dynamic>> availableBudgets = [];
    bool isLoadingBudgets = false;

    // Төсөв сонгох функц
    Future<void> _loadAvailableBudgets() async {
      setState(() {
        isLoadingBudgets = true;
      });

      try {
        // Тухайн ангилалд тохирох төсвүүдийг авах
        availableBudgets = await _transactionService.getAvailableIncomeBudgets(
            userId, selectedCategory, selectedDate);

        setState(() {
          isLoadingBudgets = false;
        });
      } catch (e) {
        setState(() {
          isLoadingBudgets = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Төсвийн мэдээлэл авахад алдаа гарлаа: $e')),
        );
      }
    }

    showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setState) {
            return AlertDialog(
              title: const Text('Орлого нэмэх'),
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
                    const SizedBox(height: 8),
                    TextField(
                      controller: amountController,
                      decoration: const InputDecoration(
                        labelText: 'Дүн',
                        border: OutlineInputBorder(),
                        prefixText: '₮',
                      ),
                      keyboardType: TextInputType.number,
                    ),
                    const SizedBox(height: 8),
                    DropdownButtonFormField<String>(
                      value: selectedCategory,
                      decoration: const InputDecoration(
                        labelText: 'Ангилал',
                        border: OutlineInputBorder(),
                      ),
                      items: incomeCategories.map((String category) {
                        return DropdownMenuItem<String>(
                          value: category,
                          child: Text(category),
                        );
                      }).toList(),
                      onChanged: (String? newValue) {
                        if (newValue != null) {
                          setState(() {
                            selectedCategory = newValue;
                            selectedBudgetId = null; // Төсвийг дахин сонгуулах
                          });
                          // Ангилал өөрчлөгдөхөд төсвүүдийг дахин ачаалах
                          _loadAvailableBudgets();
                        }
                      },
                    ),
                    const SizedBox(height: 8),
                    InkWell(
                      onTap: () async {
                        final DateTime? picked = await showDatePicker(
                          context: context,
                          initialDate: selectedDate,
                          firstDate: DateTime(2000),
                          lastDate: DateTime(2100),
                        );
                        if (picked != null) {
                          setState(() {
                            selectedDate = picked;
                            selectedBudgetId = null; // Төсвийг дахин сонгуулах
                          });
                          // Огноо өөрчлөгдөхөд төсвүүдийг дахин ачаалах
                          _loadAvailableBudgets();
                        }
                      },
                      child: InputDecorator(
                        decoration: const InputDecoration(
                          labelText: 'Огноо',
                          border: OutlineInputBorder(),
                        ),
                        child: Text(_formatDate(selectedDate)),
                      ),
                    ),
                    const SizedBox(height: 8),
                    // Төсөв сонгох хэсэг
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            const Text(
                              'Төсөв сонгох: ',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(width: 8),
                            if (isLoadingBudgets)
                              const SizedBox(
                                width: 20,
                                height: 20,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                ),
                              ),
                            const Spacer(),
                            TextButton(
                              onPressed: () {
                                _loadAvailableBudgets();
                              },
                              child: const Text('Төсвүүдийг шинэчлэх'),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        if (availableBudgets.isEmpty && !isLoadingBudgets)
                          Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: Colors.amber.shade100,
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: const Row(
                              children: [
                                Icon(Icons.info_outline, color: Colors.amber),
                                SizedBox(width: 8),
                                Expanded(
                                  child: Text(
                                    'Энэ ангилалд тохирох төсөв олдсонгүй. Та шинээр төсөв үүсгэх боломжтой.',
                                    style: TextStyle(fontSize: 14),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        if (availableBudgets.isNotEmpty)
                          Container(
                            decoration: BoxDecoration(
                              border: Border.all(color: Colors.grey.shade300),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            constraints: const BoxConstraints(
                              maxHeight: 200,
                            ),
                            child: ListView.builder(
                              shrinkWrap: true,
                              itemCount: availableBudgets.length,
                              itemBuilder: (context, index) {
                                final budget = availableBudgets[index];
                                return RadioListTile<String>(
                                  title: Text(budget['title']),
                                  subtitle: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        'Төсөв: ₮${budget['amount'].toStringAsFixed(0)} | Ашигласан: ₮${budget['usedAmount'].toStringAsFixed(0)}',
                                      ),
                                      Text(
                                        'Үлдэгдэл: ₮${budget['remainingAmount'].toStringAsFixed(0)}',
                                        style: TextStyle(
                                          color: budget['remainingAmount'] > 0
                                              ? Colors.green
                                              : Colors.red,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    ],
                                  ),
                                  value: budget['id'],
                                  groupValue: selectedBudgetId,
                                  onChanged: (String? value) {
                                    setState(() {
                                      selectedBudgetId = value;
                                    });
                                  },
                                );
                              },
                            ),
                          ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    TextField(
                      controller: noteController,
                      decoration: const InputDecoration(
                        labelText: 'Тэмдэглэл',
                        border: OutlineInputBorder(),
                      ),
                      maxLines: 2,
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
                            content: Text('Бүх талбарыг бөглөнө үү')),
                      );
                      return;
                    }

                    final income = IncomeModel(
                      id: '',
                      userId: userId,
                      title: titleController.text,
                      category: selectedCategory,
                      amount: double.tryParse(amountController.text) ?? 0,
                      date: selectedDate,
                      note: noteController.text,
                      budgetId: selectedBudgetId, // Сонгосон төсвийг ашиглах
                    );

                    // Төсөвтэй эсвэл төсөвгүй орлого нэмэх
                    Future<void> addFuture;
                    if (selectedBudgetId != null) {
                      addFuture =
                          _transactionService.addIncomeWithBudget(income);
                    } else {
                      addFuture = _transactionService.addIncome(income);
                    }

                    addFuture.then((_) {
                      Navigator.pop(context);
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                            content: Text('Орлого амжилттай нэмэгдлээ')),
                      );
                    }).catchError((error) {
                      Navigator.pop(context);
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text('Алдаа гарлаа: $error')),
                      );
                    });
                  },
                  child: const Text('НЭМЭХ'),
                ),
              ],
            );
          },
        );
      },
    ).then((_) {
      // Диалогийг хаах үед контроллеруудыг цэвэрлэх
      titleController.dispose();
      amountController.dispose();
      noteController.dispose();
    });
  }

  void _showAddExpenseDialog(BuildContext context, String userId) {
    final titleController = TextEditingController();
    final amountController = TextEditingController();
    final noteController = TextEditingController();
    DateTime selectedDate = DateTime.now();
    String selectedCategory = expenseCategories[0];
    String? selectedBudgetId;
    List<Map<String, dynamic>> availableBudgets = [];
    bool isLoadingBudgets = false;

    // Төсөв сонгох функц
    Future<void> _loadAvailableBudgets() async {
      setState(() {
        isLoadingBudgets = true;
      });

      try {
        // Тухайн ангилалд тохирох төсвүүдийг авах
        availableBudgets = await _transactionService.getAvailableExpenseBudgets(
            userId, selectedCategory, selectedDate);

        setState(() {
          isLoadingBudgets = false;
        });
      } catch (e) {
        setState(() {
          isLoadingBudgets = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Төсвийн мэдээлэл авахад алдаа гарлаа: $e')),
        );
      }
    }

    showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setState) {
            return AlertDialog(
              title: const Text('Зарлага нэмэх'),
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
                    const SizedBox(height: 8),
                    TextField(
                      controller: amountController,
                      decoration: const InputDecoration(
                        labelText: 'Дүн',
                        border: OutlineInputBorder(),
                        prefixText: '₮',
                      ),
                      keyboardType: TextInputType.number,
                    ),
                    const SizedBox(height: 8),
                    DropdownButtonFormField<String>(
                      value: selectedCategory,
                      decoration: const InputDecoration(
                        labelText: 'Ангилал',
                        border: OutlineInputBorder(),
                      ),
                      items: expenseCategories.map((String category) {
                        return DropdownMenuItem<String>(
                          value: category,
                          child: Text(category),
                        );
                      }).toList(),
                      onChanged: (String? newValue) {
                        if (newValue != null) {
                          setState(() {
                            selectedCategory = newValue;
                            selectedBudgetId = null; // Төсвийг дахин сонгуулах
                          });
                          // Ангилал өөрчлөгдөхөд төсвүүдийг дахин ачаалах
                          _loadAvailableBudgets();
                        }
                      },
                    ),
                    const SizedBox(height: 8),
                    InkWell(
                      onTap: () async {
                        final DateTime? picked = await showDatePicker(
                          context: context,
                          initialDate: selectedDate,
                          firstDate: DateTime(2000),
                          lastDate: DateTime(2100),
                        );
                        if (picked != null) {
                          setState(() {
                            selectedDate = picked;
                            selectedBudgetId = null; // Төсвийг дахин сонгуулах
                          });
                          // Огноо өөрчлөгдөхөд төсвүүдийг дахин ачаалах
                          _loadAvailableBudgets();
                        }
                      },
                      child: InputDecorator(
                        decoration: const InputDecoration(
                          labelText: 'Огноо',
                          border: OutlineInputBorder(),
                        ),
                        child: Text(_formatDate(selectedDate)),
                      ),
                    ),
                    const SizedBox(height: 8),
                    // Төсөв сонгох хэсэг
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            const Text(
                              'Төсөв сонгох: ',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(width: 8),
                            if (isLoadingBudgets)
                              const SizedBox(
                                width: 20,
                                height: 20,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                ),
                              ),
                            const Spacer(),
                            TextButton(
                              onPressed: () {
                                _loadAvailableBudgets();
                              },
                              child: const Text('Төсвүүдийг шинэчлэх'),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        if (availableBudgets.isEmpty && !isLoadingBudgets)
                          Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: Colors.amber.shade100,
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: const Row(
                              children: [
                                Icon(Icons.info_outline, color: Colors.amber),
                                SizedBox(width: 8),
                                Expanded(
                                  child: Text(
                                    'Энэ ангилалд тохирох төсөв олдсонгүй. Та шинээр төсөв үүсгэх боломжтой.',
                                    style: TextStyle(fontSize: 14),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        if (availableBudgets.isNotEmpty)
                          Container(
                            decoration: BoxDecoration(
                              border: Border.all(color: Colors.grey.shade300),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            constraints: const BoxConstraints(
                              maxHeight: 200,
                            ),
                            child: ListView.builder(
                              shrinkWrap: true,
                              itemCount: availableBudgets.length,
                              itemBuilder: (context, index) {
                                final budget = availableBudgets[index];
                                return RadioListTile<String>(
                                  title: Text(budget['title']),
                                  subtitle: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        'Төсөв: ₮${budget['amount'].toStringAsFixed(0)} | Ашигласан: ₮${budget['usedAmount'].toStringAsFixed(0)}',
                                      ),
                                      Text(
                                        'Үлдэгдэл: ₮${budget['remainingAmount'].toStringAsFixed(0)}',
                                        style: TextStyle(
                                          color: budget['remainingAmount'] > 0
                                              ? Colors.green
                                              : Colors.red,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    ],
                                  ),
                                  value: budget['id'],
                                  groupValue: selectedBudgetId,
                                  onChanged: (String? value) {
                                    setState(() {
                                      selectedBudgetId = value;
                                    });
                                  },
                                );
                              },
                            ),
                          ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    TextField(
                      controller: noteController,
                      decoration: const InputDecoration(
                        labelText: 'Тэмдэглэл',
                        border: OutlineInputBorder(),
                      ),
                      maxLines: 2,
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
                            content: Text('Бүх талбарыг бөглөнө үү')),
                      );
                      return;
                    }

                    final expense = ExpenseModel(
                      id: '',
                      userId: userId,
                      title: titleController.text,
                      category: selectedCategory,
                      amount: double.tryParse(amountController.text) ?? 0,
                      date: selectedDate,
                      note: noteController.text,
                      budgetId: selectedBudgetId, // Сонгосон төсвийг ашиглах
                    );

                    // Төсөвтэй эсвэл төсөвгүй зарлага нэмэх
                    Future<void> addFuture;
                    if (selectedBudgetId != null) {
                      addFuture =
                          _transactionService.addExpenseWithBudget(expense);
                    } else {
                      addFuture = _transactionService.addExpense(expense);
                    }

                    addFuture.then((_) {
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
                  child: const Text('НЭМЭХ'),
                ),
              ],
            );
          },
        );
      },
    ).then((_) {
      // Диалогийг хаах үед контроллеруудыг цэвэрлэх
      titleController.dispose();
      amountController.dispose();
      noteController.dispose();
    });
  }

  void _showEditIncomeDialog(BuildContext context, IncomeModel income) {
    final titleController = TextEditingController(text: income.title);
    final amountController =
        TextEditingController(text: income.amount.toString());
    final noteController = TextEditingController(text: income.note);
    DateTime selectedDate = income.date;
    String selectedCategory = income.category;
    // Хэрэв одоогийн ангилал жагсаалтад байхгүй бол эхний ангилалыг сонгоно
    if (!incomeCategories.contains(selectedCategory)) {
      selectedCategory = incomeCategories[0];
    }

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Орлого засах'),
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
                const SizedBox(height: 8),
                TextField(
                  controller: amountController,
                  decoration: const InputDecoration(
                    labelText: 'Дүн',
                    border: OutlineInputBorder(),
                    prefixText: '₮',
                  ),
                  keyboardType: TextInputType.number,
                ),
                const SizedBox(height: 8),
                DropdownButtonFormField<String>(
                  value: selectedCategory,
                  decoration: const InputDecoration(
                    labelText: 'Ангилал',
                    border: OutlineInputBorder(),
                  ),
                  items: incomeCategories.map((String category) {
                    return DropdownMenuItem<String>(
                      value: category,
                      child: Text(category),
                    );
                  }).toList(),
                  onChanged: (String? newValue) {
                    if (newValue != null) {
                      selectedCategory = newValue;
                    }
                  },
                ),
                const SizedBox(height: 8),
                InkWell(
                  onTap: () async {
                    final DateTime? picked = await showDatePicker(
                      context: context,
                      initialDate: selectedDate,
                      firstDate: DateTime(2000),
                      lastDate: DateTime(2100),
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
                    child: Text(_formatDate(selectedDate)),
                  ),
                ),
                const SizedBox(height: 8),
                TextField(
                  controller: noteController,
                  decoration: const InputDecoration(
                    labelText: 'Тэмдэглэл',
                    border: OutlineInputBorder(),
                  ),
                  maxLines: 2,
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
                    const SnackBar(content: Text('Бүх талбарыг бөглөнө үү')),
                  );
                  return;
                }

                final updatedIncome = IncomeModel(
                  id: income.id,
                  userId: income.userId,
                  title: titleController.text,
                  category: selectedCategory,
                  amount: double.tryParse(amountController.text) ?? 0,
                  date: selectedDate,
                  note: noteController.text,
                );

                _transactionService
                    .updateIncome(updatedIncome, income.amount)
                    .then((_) {
                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Орлого амжилттай засагдлаа')),
                  );
                }).catchError((error) {
                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Алдаа гарлаа: $error')),
                  );
                });
              },
              child: const Text('ХАДГАЛАХ'),
            ),
          ],
        );
      },
    );
  }

  void _showEditExpenseDialog(BuildContext context, ExpenseModel expense) {
    final titleController = TextEditingController(text: expense.title);
    final amountController =
        TextEditingController(text: expense.amount.toString());
    final noteController = TextEditingController(text: expense.note);
    DateTime selectedDate = expense.date;
    String selectedCategory = expense.category;
    // Хэрэв одоогийн ангилал жагсаалтад байхгүй бол эхний ангилалыг сонгоно
    if (!expenseCategories.contains(selectedCategory)) {
      selectedCategory = expenseCategories[0];
    }

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Зарлага засах'),
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
                const SizedBox(height: 8),
                TextField(
                  controller: amountController,
                  decoration: const InputDecoration(
                    labelText: 'Дүн',
                    border: OutlineInputBorder(),
                    prefixText: '₮',
                  ),
                  keyboardType: TextInputType.number,
                ),
                const SizedBox(height: 8),
                DropdownButtonFormField<String>(
                  value: selectedCategory,
                  decoration: const InputDecoration(
                    labelText: 'Ангилал',
                    border: OutlineInputBorder(),
                  ),
                  items: expenseCategories.map((String category) {
                    return DropdownMenuItem<String>(
                      value: category,
                      child: Text(category),
                    );
                  }).toList(),
                  onChanged: (String? newValue) {
                    if (newValue != null) {
                      selectedCategory = newValue;
                    }
                  },
                ),
                const SizedBox(height: 8),
                InkWell(
                  onTap: () async {
                    final DateTime? picked = await showDatePicker(
                      context: context,
                      initialDate: selectedDate,
                      firstDate: DateTime(2000),
                      lastDate: DateTime(2100),
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
                    child: Text(_formatDate(selectedDate)),
                  ),
                ),
                const SizedBox(height: 8),
                TextField(
                  controller: noteController,
                  decoration: const InputDecoration(
                    labelText: 'Тэмдэглэл',
                    border: OutlineInputBorder(),
                  ),
                  maxLines: 2,
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
                    const SnackBar(content: Text('Бүх талбарыг бөглөнө үү')),
                  );
                  return;
                }

                final updatedExpense = ExpenseModel(
                  id: expense.id,
                  userId: expense.userId,
                  title: titleController.text,
                  category: selectedCategory,
                  amount: double.tryParse(amountController.text) ?? 0,
                  date: selectedDate,
                  note: noteController.text,
                );

                _transactionService
                    .updateExpense(updatedExpense, expense.amount)
                    .then((_) {
                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                        content: Text('Зарлага амжилттай засагдлаа')),
                  );
                }).catchError((error) {
                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Алдаа гарлаа: $error')),
                  );
                });
              },
              child: const Text('ХАДГАЛАХ'),
            ),
          ],
        );
      },
    );
  }

  void _showDeleteIncomeDialog(BuildContext context, IncomeModel income) {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Орлого устгах'),
          content: const Text('Та энэ орлогыг устгахдаа итгэлтэй байна уу?'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('ҮГҮЙ'),
            ),
            ElevatedButton(
              onPressed: () {
                _transactionService.deleteIncome(income).then((_) {
                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                        content: Text('Орлого амжилттай устгагдлаа')),
                  );
                }).catchError((error) {
                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Алдаа гарлаа: $error')),
                  );
                });
              },
              style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
              child: const Text('УСТГАХ'),
            ),
          ],
        );
      },
    );
  }

  void _showDeleteExpenseDialog(BuildContext context, ExpenseModel expense) {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Зарлага устгах'),
          content: const Text('Та энэ зарлагыг устгахдаа итгэлтэй байна уу?'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('ҮГҮЙ'),
            ),
            ElevatedButton(
              onPressed: () {
                _transactionService.deleteExpense(expense).then((_) {
                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                        content: Text('Зарлага амжилттай устгагдлаа')),
                  );
                }).catchError((error) {
                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Алдаа гарлаа: $error')),
                  );
                });
              },
              style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
              child: const Text('УСТГАХ'),
            ),
          ],
        );
      },
    );
  }
}
