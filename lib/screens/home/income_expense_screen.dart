import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../services/auth_service.dart';
import '../../services/transaction_service.dart';
import '../../models/income_model.dart';
import '../../models/expense_model.dart';

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
        title: const Text('Орлого & Зарлага'),
        automaticallyImplyLeading: false,
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(text: 'ОРЛОГО'),
            Tab(text: 'ЗАРЛАГА'),
          ],
          labelColor: Colors.blue,
          indicatorColor: Colors.blue,
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildIncomeTab(user.uid),
          _buildExpenseTab(user.uid),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          if (_tabController.index == 0) {
            _showAddIncomeDialog(context, user.uid);
          } else {
            _showAddExpenseDialog(context, user.uid);
          }
        },
        backgroundColor: Colors.blue,
        child: const Icon(Icons.add),
      ),
    );
  }

  Widget _buildIncomeTab(String userId) {
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
          return const Center(child: Text('Орлогын мэдээлэл байхгүй байна'));
        }

        return ListView.builder(
          itemCount: incomes.length,
          padding: const EdgeInsets.all(8.0),
          itemBuilder: (context, index) {
            final income = incomes[index];
            return Card(
              elevation: 2,
              margin: const EdgeInsets.symmetric(vertical: 4.0),
              child: ListTile(
                leading: CircleAvatar(
                  backgroundColor: Colors.green.shade100,
                  child: const Icon(Icons.arrow_downward, color: Colors.green),
                ),
                title: Text(income.title),
                subtitle:
                    Text('${income.category} - ${_formatDate(income.date)}'),
                trailing: Text(
                  '₮${income.amount.toStringAsFixed(2)}',
                  style: const TextStyle(
                    color: Colors.green,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                onTap: () => _showIncomeDetails(context, income),
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
              margin: const EdgeInsets.symmetric(vertical: 4.0),
              child: ListTile(
                leading: CircleAvatar(
                  backgroundColor: Colors.red.shade100,
                  child: const Icon(Icons.arrow_upward, color: Colors.red),
                ),
                title: Text(expense.title),
                subtitle:
                    Text('${expense.category} - ${_formatDate(expense.date)}'),
                trailing: Text(
                  '₮${expense.amount.toStringAsFixed(2)}',
                  style: const TextStyle(
                    color: Colors.red,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                onTap: () => _showExpenseDetails(context, expense),
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
    final categoryController = TextEditingController(text: 'Цалин');
    final noteController = TextEditingController();
    DateTime selectedDate = DateTime.now();

    showDialog(
      context: context,
      builder: (context) {
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
                TextField(
                  controller: categoryController,
                  decoration: const InputDecoration(
                    labelText: 'Ангилал',
                    border: OutlineInputBorder(),
                  ),
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

                final income = IncomeModel(
                  id: '',
                  userId: userId,
                  title: titleController.text,
                  category: categoryController.text,
                  amount: double.tryParse(amountController.text) ?? 0,
                  date: selectedDate,
                  note: noteController.text,
                );

                _transactionService.addIncome(income).then((value) {
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
              child: const Text('НЭМЭХ'),
            ),
          ],
        );
      },
    );
  }

  void _showAddExpenseDialog(BuildContext context, String userId) {
    final titleController = TextEditingController();
    final amountController = TextEditingController();
    final categoryController = TextEditingController(text: 'Хүнс');
    final noteController = TextEditingController();
    DateTime selectedDate = DateTime.now();

    showDialog(
      context: context,
      builder: (context) {
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
                TextField(
                  controller: categoryController,
                  decoration: const InputDecoration(
                    labelText: 'Ангилал',
                    border: OutlineInputBorder(),
                  ),
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

                final expense = ExpenseModel(
                  id: '',
                  userId: userId,
                  title: titleController.text,
                  category: categoryController.text,
                  amount: double.tryParse(amountController.text) ?? 0,
                  date: selectedDate,
                  note: noteController.text,
                );

                _transactionService.addExpense(expense).then((value) {
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
  }

  void _showEditIncomeDialog(BuildContext context, IncomeModel income) {
    final titleController = TextEditingController(text: income.title);
    final amountController =
        TextEditingController(text: income.amount.toString());
    final categoryController = TextEditingController(text: income.category);
    final noteController = TextEditingController(text: income.note);
    DateTime selectedDate = income.date;

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
                TextField(
                  controller: categoryController,
                  decoration: const InputDecoration(
                    labelText: 'Ангилал',
                    border: OutlineInputBorder(),
                  ),
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
                  category: categoryController.text,
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
    final categoryController = TextEditingController(text: expense.category);
    final noteController = TextEditingController(text: expense.note);
    DateTime selectedDate = expense.date;

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
                TextField(
                  controller: categoryController,
                  decoration: const InputDecoration(
                    labelText: 'Ангилал',
                    border: OutlineInputBorder(),
                  ),
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
                  category: categoryController.text,
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
