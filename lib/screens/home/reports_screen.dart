import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../services/auth_service.dart';
import '../../services/report_service.dart';
import '../../models/income_model.dart';
import '../../models/expense_model.dart';

class ReportsScreen extends StatefulWidget {
  const ReportsScreen({super.key});

  @override
  State<ReportsScreen> createState() => _ReportsScreenState();
}

class _ReportsScreenState extends State<ReportsScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final ReportService _reportService = ReportService();

  bool _isLoading = false;
  String? _errorMessage;

  // Monthly report data
  DateTime _selectedMonth = DateTime.now();
  Map<String, dynamic>? _monthlyReportData;

  // Yearly report data
  int _selectedYear = DateTime.now().year;
  Map<String, dynamic>? _yearlyReportData;

  // Custom range report data
  DateTime _startDate = DateTime.now().subtract(const Duration(days: 30));
  DateTime _endDate = DateTime.now();
  Map<String, dynamic>? _customReportData;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _tabController.addListener(_handleTabChange);

    // Load initial monthly report
    _loadMonthlyReport();
  }

  void _handleTabChange() {
    if (_tabController.indexIsChanging) {
      return;
    }

    // Console дээр лог хэвлэж шалгах
    print('Tab changed to: ${_tabController.index}');

    switch (_tabController.index) {
      case 0:
        _loadMonthlyReport();
        break;
      case 1:
        _loadYearlyReport();
        break;
      case 2:
        _loadCustomReport();
        break;
    }
  }

  @override
  void dispose() {
    _tabController.removeListener(_handleTabChange);
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
        title: const Text('Санхүүгийн тайлан'),
        automaticallyImplyLeading: false,
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(text: 'САР'),
            Tab(text: 'ЖИЛ'),
            Tab(text: 'ХУГАЦАА'),
          ],
          labelColor: Colors.blue,
          indicatorColor: Colors.blue,
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildMonthlyReportTab(user.uid),
          _buildYearlyReportTab(user.uid),
          _buildCustomReportTab(user.uid),
        ],
      ),
    );
  }

  Widget _buildMonthlyReportTab(String userId) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              IconButton(
                icon: const Icon(Icons.arrow_back_ios),
                onPressed: () {
                  setState(() {
                    _selectedMonth = DateTime(
                      _selectedMonth.year,
                      _selectedMonth.month - 1,
                      1,
                    );
                  });
                  _loadMonthlyReport();
                },
              ),
              Text(
                '${_getMonthName(_selectedMonth.month)} ${_selectedMonth.year}',
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              IconButton(
                icon: const Icon(Icons.arrow_forward_ios),
                onPressed: () {
                  setState(() {
                    _selectedMonth = DateTime(
                      _selectedMonth.year,
                      _selectedMonth.month + 1,
                      1,
                    );
                  });
                  _loadMonthlyReport();
                },
              ),
            ],
          ),
          const SizedBox(height: 16),
          if (_isLoading)
            const Center(child: CircularProgressIndicator())
          else if (_errorMessage != null)
            Center(
              child: SelectableText(
                _errorMessage!,
                style: const TextStyle(color: Colors.red),
              ),
            )
          else if (_monthlyReportData != null)
            _buildMonthlyReportContent()
          else
            const Center(child: Text('Мэдээлэл байхгүй байна')),
        ],
      ),
    );
  }

  Widget _buildYearlyReportTab(String userId) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              IconButton(
                icon: const Icon(Icons.arrow_back_ios),
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
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              IconButton(
                icon: const Icon(Icons.arrow_forward_ios),
                onPressed: () {
                  setState(() {
                    _selectedYear++;
                  });
                  _loadYearlyReport();
                },
              ),
            ],
          ),
          const SizedBox(height: 16),
          if (_isLoading)
            const Center(child: CircularProgressIndicator())
          else if (_errorMessage != null)
            Center(
              child: SelectableText(
                _errorMessage!,
                style: const TextStyle(color: Colors.red),
              ),
            )
          else if (_yearlyReportData != null)
            _buildYearlyReportContent()
          else
            const Center(child: Text('Мэдээлэл байхгүй байна')),
        ],
      ),
    );
  }

  Widget _buildCustomReportTab(String userId) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: InkWell(
                  onTap: () async {
                    final DateTime? picked = await showDatePicker(
                      context: context,
                      initialDate: _startDate,
                      firstDate: DateTime(2000),
                      lastDate: DateTime.now(),
                    );
                    if (picked != null) {
                      setState(() {
                        _startDate = picked;
                      });
                      _loadCustomReport();
                    }
                  },
                  child: InputDecorator(
                    decoration: const InputDecoration(
                      labelText: 'Эхлэх огноо',
                      border: OutlineInputBorder(),
                    ),
                    child: Text(_formatDate(_startDate)),
                  ),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: InkWell(
                  onTap: () async {
                    final DateTime? picked = await showDatePicker(
                      context: context,
                      initialDate: _endDate,
                      firstDate: _startDate,
                      lastDate: DateTime.now(),
                    );
                    if (picked != null) {
                      setState(() {
                        _endDate = picked;
                      });
                      _loadCustomReport();
                    }
                  },
                  child: InputDecorator(
                    decoration: const InputDecoration(
                      labelText: 'Дуусах огноо',
                      border: OutlineInputBorder(),
                    ),
                    child: Text(_formatDate(_endDate)),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          if (_isLoading)
            const Center(child: CircularProgressIndicator())
          else if (_errorMessage != null)
            Center(
              child: SelectableText(
                _errorMessage!,
                style: const TextStyle(color: Colors.red),
              ),
            )
          else if (_customReportData != null)
            _buildCustomReportContent()
          else
            const Center(child: Text('Мэдээлэл байхгүй байна')),
        ],
      ),
    );
  }

  Widget _buildMonthlyReportContent() {
    final data = _monthlyReportData!;
    final double totalIncome = data['totalIncome'] ?? 0.0;
    final double totalExpense = data['totalExpense'] ?? 0.0;
    final double netIncome = data['netIncome'] ?? 0.0;
    final Map<String, dynamic> incomeByCategory =
        data['incomeByCategory'] ?? {};
    final Map<String, dynamic> expenseByCategory =
        data['expenseByCategory'] ?? {};

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSummaryCard(totalIncome, totalExpense, netIncome),
        const SizedBox(height: 24),
        const Text(
          'Орлогын задаргаа',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 8),
        if (incomeByCategory.isEmpty)
          const Text('Орлогын мэдээлэл байхгүй байна')
        else
          _buildCategoryList(incomeByCategory, totalIncome, true),
        const SizedBox(height: 24),
        const Text(
          'Зарлагын задаргаа',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 8),
        if (expenseByCategory.isEmpty)
          const Text('Зарлагын мэдээлэл байхгүй байна')
        else
          _buildCategoryList(expenseByCategory, totalExpense, false),
      ],
    );
  }

  Widget _buildYearlyReportContent() {
    final data = _yearlyReportData!;
    final double totalIncome = data['totalIncome'] ?? 0.0;
    final double totalExpense = data['totalExpense'] ?? 0.0;
    final double netIncome = data['netIncome'] ?? 0.0;
    final Map<dynamic, dynamic> incomeByMonth = data['incomeByMonth'] ?? {};
    final Map<dynamic, dynamic> expenseByMonth = data['expenseByMonth'] ?? {};

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSummaryCard(totalIncome, totalExpense, netIncome),
        const SizedBox(height: 24),
        const Text(
          'Сарын тайлан',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 8),
        if (incomeByMonth.isEmpty && expenseByMonth.isEmpty)
          const Text('Мэдээлэл байхгүй байна')
        else
          _buildMonthlyChart(incomeByMonth, expenseByMonth),
      ],
    );
  }

  Widget _buildCustomReportContent() {
    final data = _customReportData!;
    final double totalIncome = data['totalIncome'] ?? 0.0;
    final double totalExpense = data['totalExpense'] ?? 0.0;
    final double netIncome = data['netIncome'] ?? 0.0;
    final Map<String, dynamic> incomeByCategory =
        data['incomeByCategory'] ?? {};
    final Map<String, dynamic> expenseByCategory =
        data['expenseByCategory'] ?? {};
    final List<dynamic> incomes = data['incomes'] ?? [];
    final List<dynamic> expenses = data['expenses'] ?? [];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSummaryCard(totalIncome, totalExpense, netIncome),
        const SizedBox(height: 24),
        const Text(
          'Орлогын задаргаа',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 8),
        if (incomeByCategory.isEmpty)
          const Text('Орлогын мэдээлэл байхгүй байна')
        else
          _buildCategoryList(incomeByCategory, totalIncome, true),
        const SizedBox(height: 24),
        const Text(
          'Зарлагын задаргаа',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 8),
        if (expenseByCategory.isEmpty)
          const Text('Зарлагын мэдээлэл байхгүй байна')
        else
          _buildCategoryList(expenseByCategory, totalExpense, false),
        const SizedBox(height: 24),
        const Text(
          'Орлогын жагсаалт',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 8),
        if (incomes.isEmpty)
          const Text('Орлогын мэдээлэл байхгүй байна')
        else
          ListView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: incomes.length,
            itemBuilder: (context, index) {
              final income = incomes[index] as IncomeModel;
              return ListTile(
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
              );
            },
          ),
        const SizedBox(height: 24),
        const Text(
          'Зарлагын жагсаалт',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 8),
        if (expenses.isEmpty)
          const Text('Зарлагын мэдээлэл байхгүй байна')
        else
          ListView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: expenses.length,
            itemBuilder: (context, index) {
              final expense = expenses[index] as ExpenseModel;
              return ListTile(
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
              );
            },
          ),
      ],
    );
  }

  Widget _buildSummaryCard(double income, double expense, double netIncome) {
    return Card(
      elevation: 3,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Нийт орлого:',
                  style: TextStyle(fontSize: 16),
                ),
                Text(
                  '₮${income.toStringAsFixed(2)}',
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Colors.green,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            const Divider(),
            const SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Нийт зарлага:',
                  style: TextStyle(fontSize: 16),
                ),
                Text(
                  '₮${expense.toStringAsFixed(2)}',
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Colors.red,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            const Divider(),
            const SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Цэвэр ашиг/алдагдал:',
                  style: TextStyle(fontSize: 16),
                ),
                Text(
                  '₮${netIncome.toStringAsFixed(2)}',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: netIncome >= 0 ? Colors.green : Colors.red,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCategoryList(
      Map<String, dynamic> categories, double total, bool isIncome) {
    return ListView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: categories.length,
      itemBuilder: (context, index) {
        final category = categories.keys.elementAt(index);
        final amount = categories[category] as double;
        final percentage = total > 0 ? (amount / total * 100) : 0;

        return Card(
          margin: const EdgeInsets.symmetric(vertical: 4),
          child: Padding(
            padding: const EdgeInsets.all(8.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      category,
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                    Text(
                      '₮${amount.toStringAsFixed(2)} (${percentage.toStringAsFixed(1)}%)',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: isIncome ? Colors.green : Colors.red,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                ClipRRect(
                  borderRadius: BorderRadius.circular(4),
                  child: LinearProgressIndicator(
                    value: percentage / 100,
                    minHeight: 10,
                    backgroundColor: Colors.grey.shade200,
                    valueColor: AlwaysStoppedAnimation<Color>(
                      isIncome ? Colors.green : Colors.red,
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildMonthlyChart(
      Map<dynamic, dynamic> incomeData, Map<dynamic, dynamic> expenseData) {
    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            for (int month = 1; month <= 12; month++)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 4.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      _getMonthName(month),
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        Expanded(
                          flex: 2,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Орлого: ₮${(incomeData[month] ?? 0).toStringAsFixed(2)}',
                                style: const TextStyle(color: Colors.green),
                              ),
                              const SizedBox(height: 2),
                              ClipRRect(
                                borderRadius: BorderRadius.circular(4),
                                child: LinearProgressIndicator(
                                  value: (incomeData[month] ?? 0) > 0 ? 1 : 0,
                                  minHeight: 8,
                                  backgroundColor: Colors.grey.shade200,
                                  valueColor:
                                      const AlwaysStoppedAnimation<Color>(
                                          Colors.green),
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          flex: 2,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Зарлага: ₮${(expenseData[month] ?? 0).toStringAsFixed(2)}',
                                style: const TextStyle(color: Colors.red),
                              ),
                              const SizedBox(height: 2),
                              ClipRRect(
                                borderRadius: BorderRadius.circular(4),
                                child: LinearProgressIndicator(
                                  value: (expenseData[month] ?? 0) > 0 ? 1 : 0,
                                  minHeight: 8,
                                  backgroundColor: Colors.grey.shade200,
                                  valueColor:
                                      const AlwaysStoppedAnimation<Color>(
                                          Colors.red),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    const Divider(),
                  ],
                ),
              ),
          ],
        ),
      ),
    );
  }

  Future<void> _loadMonthlyReport() async {
    final authService = Provider.of<AuthService>(context, listen: false);
    final user = authService.getCurrentUser();

    if (user == null) return;

    setState(() {
      _isLoading = true;
      _errorMessage = null;
      _monthlyReportData = null;
    });

    try {
      // Лог хэвлэх
      print(
          'Loading monthly report for user: ${user.uid}, month: $_selectedMonth');

      final report =
          await _reportService.getMonthlyReport(user.uid, _selectedMonth);

      // Өгөгдлийг шалгах
      print('Monthly report received: $report');

      setState(() {
        _monthlyReportData = report;
        _isLoading = false;
      });
    } catch (e) {
      print('Error loading monthly report: $e');
      setState(() {
        _errorMessage = 'Тайлан авахад алдаа гарлаа: ${e.toString()}';
        _isLoading = false;
      });
    }
  }

  Future<void> _loadYearlyReport() async {
    final authService = Provider.of<AuthService>(context, listen: false);
    final user = authService.getCurrentUser();

    if (user == null) return;

    setState(() {
      _isLoading = true;
      _errorMessage = null;
      _yearlyReportData = null;
    });

    try {
      final report =
          await _reportService.getYearlyReport(user.uid, _selectedYear);

      setState(() {
        _yearlyReportData = report;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _errorMessage = 'Тайлан авахад алдаа гарлаа: ${e.toString()}';
        _isLoading = false;
      });
    }
  }

  Future<void> _loadCustomReport() async {
    final authService = Provider.of<AuthService>(context, listen: false);
    final user = authService.getCurrentUser();

    if (user == null) return;

    if (_startDate.isAfter(_endDate)) {
      setState(() {
        _errorMessage = 'Эхлэх огноо нь дуусах огнооноос өмнө байх ёстой';
      });
      return;
    }

    setState(() {
      _isLoading = true;
      _errorMessage = null;
      _customReportData = null;
    });

    try {
      final report = await _reportService.getCustomRangeReport(
          user.uid, _startDate, _endDate);

      setState(() {
        _customReportData = report;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _errorMessage = 'Тайлан авахад алдаа гарлаа: ${e.toString()}';
        _isLoading = false;
      });
    }
  }

  String _formatDate(DateTime date) {
    return '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
  }

  String _getMonthName(int month) {
    const monthNames = [
      '',
      'Нэгдүгээр сар',
      'Хоёрдугаар сар',
      'Гуравдугаар сар',
      'Дөрөвдүгээр сар',
      'Тавдугаар сар',
      'Зургадугаар сар',
      'Долдугаар сар',
      'Наймдугаар сар',
      'Есдүгээр сар',
      'Аравдугаар сар',
      'Арван нэгдүгээр сар',
      'Арван хоёрдугаар сар',
    ];

    return monthNames[month];
  }
}
