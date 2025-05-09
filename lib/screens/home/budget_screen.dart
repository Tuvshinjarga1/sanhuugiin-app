import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../../services/auth_service.dart';
import '../../services/budget_service.dart';
import '../../models/budget_model.dart';
import '../home/home_screen.dart'; // For accessing color constants

class BudgetScreen extends StatefulWidget {
  const BudgetScreen({super.key});

  @override
  State<BudgetScreen> createState() => _BudgetScreenState();
}

class _BudgetScreenState extends State<BudgetScreen>
    with SingleTickerProviderStateMixin {
  final BudgetService _budgetService = BudgetService();
  late AnimationController _animationController;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1000),
    );

    _animationController.forward();
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final authService = Provider.of<AuthService>(context);
    final user = authService.getCurrentUser();

    if (user == null) {
      return _buildErrorState('Хэрэглэгч нэвтрээгүй байна');
    }

    return Scaffold(
      backgroundColor: kBackgroundColor,
      appBar: AppBar(
        title: const Text(
          'Төсөв',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: kTextColor,
          ),
        ),
        backgroundColor: kCardColor,
        elevation: 0,
        centerTitle: true,
        automaticallyImplyLeading: false,
      ),
      body: StreamBuilder<List<BudgetModel>>(
        stream: _budgetService.getUserBudgets(user.uid),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return _buildLoadingState();
          }

          if (snapshot.hasError) {
            return _buildErrorState('Алдаа гарлаа: ${snapshot.error}');
          }

          final budgets = snapshot.data ?? [];

          if (budgets.isEmpty) {
            return _buildEmptyState(user.uid);
          }

          return _buildBudgetList(budgets);
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showAddBudgetDialog(context, user.uid),
        backgroundColor: kPrimaryColor,
        elevation: 4,
        child: const Icon(Icons.add_rounded, color: Colors.white),
      ),
    );
  }

  Widget _buildLoadingState() {
    return const Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          CircularProgressIndicator(
            valueColor: AlwaysStoppedAnimation<Color>(kPrimaryColor),
          ),
          SizedBox(height: 16),
          Text(
            'Төсвийн мэдээлэл ачааллаж байна...',
            style: TextStyle(
              color: kTextLightColor,
              fontSize: 16,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildErrorState(String message) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.error_outline_rounded,
            size: 64,
            color: Colors.red.shade300,
          ),
          const SizedBox(height: 16),
          Text(
            message,
            style: TextStyle(
              color: Colors.red.shade700,
              fontSize: 16,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState(String userId) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.account_balance_wallet_outlined,
            size: 80,
            color: Colors.grey.shade400,
          ),
          const SizedBox(height: 24),
          const Text(
            'Төсвийн мэдээлэл байхгүй байна',
            style: TextStyle(
              fontSize: 18,
              color: kTextColor,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            'Шинэ төсөв үүсгэж санхүүгээ төлөвлөнө үү',
            style: TextStyle(
              fontSize: 14,
              color: kTextLightColor,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 32),
          ElevatedButton.icon(
            onPressed: () => _showAddBudgetDialog(context, userId),
            icon: const Icon(Icons.add_rounded),
            label: const Padding(
              padding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              child: Text(
                'Төсөв үүсгэх',
                style: TextStyle(fontSize: 16),
              ),
            ),
            style: ElevatedButton.styleFrom(
              backgroundColor: kPrimaryColor,
              foregroundColor: Colors.white,
              elevation: 2,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBudgetList(List<BudgetModel> budgets) {
    final numberFormat = NumberFormat("#,##0.00", "mn_MN");

    return ListView.builder(
      itemCount: budgets.length,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      itemBuilder: (context, index) {
        final budget = budgets[index];

        // Create staggered animation for each item
        final Animation<double> animation = CurvedAnimation(
          parent: _animationController,
          curve: Interval(
            (1 / budgets.length) * index,
            (1 / budgets.length) * (index + 1),
            curve: Curves.easeOut,
          ),
        );

        return AnimatedBuilder(
          animation: animation,
          builder: (context, child) {
            return FadeTransition(
              opacity: animation,
              child: SlideTransition(
                position: Tween<Offset>(
                  begin: const Offset(0.5, 0),
                  end: Offset.zero,
                ).animate(animation),
                child: child,
              ),
            );
          },
          child: FutureBuilder<Map<String, dynamic>>(
            future: _budgetService.getBudgetStatus(budget),
            builder: (context, statusSnapshot) {
              double percentUsed = 0;
              double remaining = budget.amount;
              bool isOverBudget = false;

              if (statusSnapshot.hasData) {
                percentUsed = statusSnapshot.data!['percentUsed'];
                remaining = statusSnapshot.data!['remaining'];
                isOverBudget = statusSnapshot.data!['isOverBudget'];
              }

              return Container(
                margin: const EdgeInsets.only(bottom: 16),
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
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.all(8),
                                decoration: BoxDecoration(
                                  color: kPrimaryColor.withOpacity(0.1),
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                child: Icon(
                                  _getCategoryIcon(budget.category),
                                  color: kPrimaryColor,
                                  size: 20,
                                ),
                              ),
                              const SizedBox(width: 12),
                              Text(
                                budget.category,
                                style: const TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                  color: kTextColor,
                                ),
                              ),
                            ],
                          ),
                          PopupMenuButton<String>(
                            icon: const Icon(
                              Icons.more_vert_rounded,
                              color: kTextLightColor,
                            ),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            onSelected: (value) {
                              if (value == 'edit') {
                                _showEditBudgetDialog(context, budget);
                              } else if (value == 'delete') {
                                _showDeleteBudgetDialog(context, budget.id);
                              }
                            },
                            itemBuilder: (context) => [
                              const PopupMenuItem(
                                value: 'edit',
                                child: Row(
                                  children: [
                                    Icon(Icons.edit_rounded, size: 20),
                                    SizedBox(width: 8),
                                    Text('Засах'),
                                  ],
                                ),
                              ),
                              PopupMenuItem(
                                value: 'delete',
                                child: Row(
                                  children: [
                                    Icon(
                                      Icons.delete_rounded,
                                      size: 20,
                                      color: Colors.red.shade700,
                                    ),
                                    const SizedBox(width: 8),
                                    Text(
                                      'Устгах',
                                      style: TextStyle(
                                        color: Colors.red.shade700,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text(
                                  'Хугацаа:',
                                  style: TextStyle(
                                    color: kTextLightColor,
                                    fontSize: 13,
                                  ),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  '${_formatDate(budget.startDate)} - ${_formatDate(budget.endDate)}',
                                  style: const TextStyle(
                                    color: kTextColor,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.end,
                            children: [
                              const Text(
                                'Хугацаа:',
                                style: TextStyle(
                                  color: kTextLightColor,
                                  fontSize: 13,
                                ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                _getRemainingDays(budget.endDate),
                                style: TextStyle(
                                  color: _getTimeColor(budget.endDate),
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                      const SizedBox(height: 20),
                      _buildBudgetProgressSection(
                        budget: budget,
                        percentUsed: percentUsed,
                        remaining: remaining,
                        isOverBudget: isOverBudget,
                        numberFormat: numberFormat,
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        );
      },
    );
  }

  Widget _buildBudgetProgressSection({
    required BudgetModel budget,
    required double percentUsed,
    required double remaining,
    required bool isOverBudget,
    required NumberFormat numberFormat,
  }) {
    final Color progressColor = isOverBudget ? kExpenseColor : kIncomeColor;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Төсөв:',
                  style: TextStyle(
                    color: kTextLightColor,
                    fontSize: 13,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  '₮${numberFormat.format(budget.amount)}',
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
              ],
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                const Text(
                  'Үлдэгдэл:',
                  style: TextStyle(
                    color: kTextLightColor,
                    fontSize: 13,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  '₮${numberFormat.format(remaining)}',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                    color: isOverBudget ? kExpenseColor : kIncomeColor,
                  ),
                ),
              ],
            ),
          ],
        ),
        const SizedBox(height: 16),
        Stack(
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: LinearProgressIndicator(
                value: percentUsed.clamp(0, 100) / 100,
                minHeight: 12,
                backgroundColor: Colors.grey.shade200,
                valueColor: AlwaysStoppedAnimation<Color>(progressColor),
              ),
            ),
            if (isOverBudget)
              Positioned(
                right: (1 - (100 / percentUsed)).clamp(0, 1) * 100,
                top: 0,
                bottom: 0,
                child: Center(
                  child: Container(
                    height: 12,
                    width: 2,
                    color: Colors.white,
                  ),
                ),
              ),
          ],
        ),
        const SizedBox(height: 8),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              '${percentUsed.toStringAsFixed(1)}% ашигласан',
              style: TextStyle(
                color: isOverBudget ? kExpenseColor : kTextColor,
                fontWeight: FontWeight.w500,
                fontSize: 13,
              ),
            ),
            if (isOverBudget)
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: kExpenseColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  'Хэтэрсэн',
                  style: TextStyle(
                    color: kExpenseColor,
                    fontWeight: FontWeight.bold,
                    fontSize: 12,
                  ),
                ),
              ),
          ],
        ),
      ],
    );
  }

  IconData _getCategoryIcon(String category) {
    final lowerCategory = category.toLowerCase();

    if (lowerCategory.contains('хоол') || lowerCategory.contains('хүнс')) {
      return Icons.restaurant_rounded;
    } else if (lowerCategory.contains('шатахуун') ||
        lowerCategory.contains('унаа')) {
      return Icons.directions_car_rounded;
    } else if (lowerCategory.contains('хувцас')) {
      return Icons.shopping_bag_rounded;
    } else if (lowerCategory.contains('амралт') ||
        lowerCategory.contains('аялал')) {
      return Icons.beach_access_rounded;
    } else if (lowerCategory.contains('эмчилгээ') ||
        lowerCategory.contains('эрүүл мэнд')) {
      return Icons.medical_services_rounded;
    } else if (lowerCategory.contains('боловсрол') ||
        lowerCategory.contains('сургалт')) {
      return Icons.school_rounded;
    } else if (lowerCategory.contains('бэлэг') ||
        lowerCategory.contains('найр')) {
      return Icons.card_giftcard_rounded;
    } else if (lowerCategory.contains('цахилгаан') ||
        lowerCategory.contains('гэр')) {
      return Icons.home_rounded;
    }

    return Icons.account_balance_wallet_rounded;
  }

  String _getRemainingDays(DateTime endDate) {
    final now = DateTime.now();
    final difference = endDate.difference(now).inDays;

    if (difference < 0) {
      return 'Хугацаа дууссан';
    } else if (difference == 0) {
      return 'Өнөөдөр дуусна';
    } else {
      return '$difference өдөр үлдсэн';
    }
  }

  Color _getTimeColor(DateTime endDate) {
    final now = DateTime.now();
    final difference = endDate.difference(now).inDays;

    if (difference < 0) {
      return kExpenseColor; // Past due
    } else if (difference < 3) {
      return Colors.orange; // Almost due
    } else {
      return kTextColor; // Plenty of time
    }
  }

  String _formatDate(DateTime date) {
    return '${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
  }

  void _showAddBudgetDialog(BuildContext context, String userId) {
    final categoryController = TextEditingController();
    final amountController = TextEditingController();
    DateTime startDate = DateTime.now();
    DateTime endDate = DateTime.now().add(const Duration(days: 30));

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Төсөв нэмэх'),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                _buildTextField(
                  controller: categoryController,
                  labelText: 'Ангилал',
                  hintText: 'Жишээ: Хүнс, Зугаа цэнгэл, Хувцас',
                  prefixIcon: Icons.category_rounded,
                ),
                const SizedBox(height: 16),
                _buildTextField(
                  controller: amountController,
                  labelText: 'Дүн',
                  hintText: '0',
                  prefixIcon: Icons.money_rounded,
                  keyboardType: TextInputType.number,
                  prefixText: '₮',
                ),
                const SizedBox(height: 16),
                _buildDateSelector(
                  label: 'Эхлэх огноо',
                  initialDate: startDate,
                  onDateSelected: (date) {
                    startDate = date;
                  },
                ),
                const SizedBox(height: 16),
                _buildDateSelector(
                  label: 'Дуусах огноо',
                  initialDate: endDate,
                  onDateSelected: (date) {
                    endDate = date;
                  },
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text(
                'БОЛИХ',
                style: TextStyle(color: kTextLightColor),
              ),
            ),
            ElevatedButton(
              onPressed: () {
                if (categoryController.text.isEmpty ||
                    amountController.text.isEmpty) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Бүх талбарыг бөглөнө үү'),
                      behavior: SnackBarBehavior.floating,
                    ),
                  );
                  return;
                }

                if (startDate.isAfter(endDate)) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text(
                          'Эхлэх огноо нь дуусах огнооноос өмнө байх ёстой'),
                      behavior: SnackBarBehavior.floating,
                    ),
                  );
                  return;
                }

                final budget = BudgetModel(
                  id: '',
                  userId: userId,
                  category: categoryController.text,
                  amount: double.tryParse(amountController.text) ?? 0,
                  startDate: startDate,
                  endDate: endDate,
                );

                _budgetService.addBudget(budget).then((value) {
                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: const Text('Төсөв амжилттай нэмэгдлээ'),
                      behavior: SnackBarBehavior.floating,
                      backgroundColor: Colors.green.shade700,
                    ),
                  );
                }).catchError((error) {
                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Алдаа гарлаа: $error'),
                      behavior: SnackBarBehavior.floating,
                      backgroundColor: Colors.red.shade700,
                    ),
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
    final categoryController = TextEditingController(text: budget.category);
    final amountController =
        TextEditingController(text: budget.amount.toString());
    DateTime startDate = budget.startDate;
    DateTime endDate = budget.endDate;

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Төсөв засах'),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                _buildTextField(
                  controller: categoryController,
                  labelText: 'Ангилал',
                  hintText: 'Жишээ: Хүнс, Зугаа цэнгэл, Хувцас',
                  prefixIcon: Icons.category_rounded,
                ),
                const SizedBox(height: 16),
                _buildTextField(
                  controller: amountController,
                  labelText: 'Дүн',
                  hintText: '0',
                  prefixIcon: Icons.money_rounded,
                  keyboardType: TextInputType.number,
                  prefixText: '₮',
                ),
                const SizedBox(height: 16),
                _buildDateSelector(
                  label: 'Эхлэх огноо',
                  initialDate: startDate,
                  onDateSelected: (date) {
                    startDate = date;
                  },
                ),
                const SizedBox(height: 16),
                _buildDateSelector(
                  label: 'Дуусах огноо',
                  initialDate: endDate,
                  onDateSelected: (date) {
                    endDate = date;
                  },
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text(
                'БОЛИХ',
                style: TextStyle(color: kTextLightColor),
              ),
            ),
            ElevatedButton(
              onPressed: () {
                if (categoryController.text.isEmpty ||
                    amountController.text.isEmpty) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Бүх талбарыг бөглөнө үү'),
                      behavior: SnackBarBehavior.floating,
                    ),
                  );
                  return;
                }

                if (startDate.isAfter(endDate)) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text(
                          'Эхлэх огноо нь дуусах огнооноос өмнө байх ёстой'),
                      behavior: SnackBarBehavior.floating,
                    ),
                  );
                  return;
                }

                final updatedBudget = BudgetModel(
                  id: budget.id,
                  userId: budget.userId,
                  category: categoryController.text,
                  amount: double.tryParse(amountController.text) ?? 0,
                  startDate: startDate,
                  endDate: endDate,
                );

                _budgetService.updateBudget(updatedBudget).then((_) {
                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: const Text('Төсөв амжилттай засагдлаа'),
                      behavior: SnackBarBehavior.floating,
                      backgroundColor: Colors.green.shade700,
                    ),
                  );
                }).catchError((error) {
                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Алдаа гарлаа: $error'),
                      behavior: SnackBarBehavior.floating,
                      backgroundColor: Colors.red.shade700,
                    ),
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

  void _showDeleteBudgetDialog(BuildContext context, String budgetId) {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Төсөв устгах'),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          content: const Text(
            'Та энэ төсвийг устгахдаа итгэлтэй байна уу?',
            style: TextStyle(fontSize: 16),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text(
                'ҮГҮЙ',
                style: TextStyle(color: kTextColor),
              ),
            ),
            ElevatedButton(
              onPressed: () {
                _budgetService.deleteBudget(budgetId).then((_) {
                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: const Text('Төсөв амжилттай устгагдлаа'),
                      behavior: SnackBarBehavior.floating,
                      backgroundColor: Colors.green.shade700,
                    ),
                  );
                }).catchError((error) {
                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Алдаа гарлаа: $error'),
                      behavior: SnackBarBehavior.floating,
                      backgroundColor: Colors.red.shade700,
                    ),
                  );
                });
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red.shade700,
              ),
              child: const Text('УСТГАХ'),
            ),
          ],
        );
      },
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String labelText,
    required String hintText,
    required IconData prefixIcon,
    TextInputType keyboardType = TextInputType.text,
    String? prefixText,
  }) {
    return TextField(
      controller: controller,
      keyboardType: keyboardType,
      decoration: InputDecoration(
        labelText: labelText,
        hintText: hintText,
        prefixIcon: Icon(prefixIcon),
        prefixText: prefixText,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Colors.grey),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Colors.grey.shade300),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: kPrimaryColor, width: 2),
        ),
        filled: true,
        fillColor: Colors.white,
      ),
    );
  }

  Widget _buildDateSelector({
    required String label,
    required DateTime initialDate,
    required Function(DateTime) onDateSelected,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontSize: 14,
            color: kTextLightColor,
          ),
        ),
        const SizedBox(height: 8),
        InkWell(
          onTap: () async {
            final DateTime? picked = await showDatePicker(
              context: context,
              initialDate: initialDate,
              firstDate: DateTime(2000),
              lastDate: DateTime(2100),
              builder: (context, child) {
                return Theme(
                  data: Theme.of(context).copyWith(
                    colorScheme: const ColorScheme.light(
                      primary: kPrimaryColor,
                      onPrimary: Colors.white,
                      onSurface: kTextColor,
                    ),
                    textButtonTheme: TextButtonThemeData(
                      style: TextButton.styleFrom(
                        foregroundColor: kPrimaryColor,
                      ),
                    ),
                  ),
                  child: child!,
                );
              },
            );
            if (picked != null) {
              onDateSelected(picked);
            }
          },
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              border: Border.all(color: Colors.grey.shade300),
              borderRadius: BorderRadius.circular(12),
              color: Colors.white,
            ),
            child: Row(
              children: [
                const Icon(
                  Icons.calendar_today_rounded,
                  size: 18,
                  color: kTextLightColor,
                ),
                const SizedBox(width: 12),
                Text(
                  DateFormat('yyyy-MM-dd').format(initialDate),
                  style: const TextStyle(
                    fontSize: 16,
                    color: kTextColor,
                  ),
                ),
                const Spacer(),
                const Icon(
                  Icons.arrow_drop_down,
                  color: kTextLightColor,
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}
