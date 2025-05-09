import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../services/auth_service.dart';
import '../auth/login_screen.dart';
import 'dashboard_screen.dart';
import 'income_expense_screen.dart';
import 'budget_screen.dart';
import 'reports_screen.dart';
import 'tasks_screen.dart';
import 'profile_screen.dart';

// Түгээмэл хэрэглэгдэх өнгөнүүд
const Color kPrimaryColor = Color(0xFF1E88E5); // Үндсэн өнгө
const Color kSecondaryColor = Color(0xFF26A69A); // Хоёрдогч өнгө
const Color kAccentColor = Color(0xFFFFB74D); // Акцент өнгө
const Color kBackgroundColor = Color(0xFFF5F7FA); // Арын өнгө
const Color kCardColor = Colors.white; // Карт өнгө
const Color kTextColor = Color(0xFF212121); // Үндсэн текст өнгө
const Color kTextLightColor = Color(0xFF757575); // Хөнгөн текст өнгө
const Color kIncomeColor = Color(0xFF43A047); // Орлогын өнгө
const Color kExpenseColor = Color(0xFFE53935); // Зарлагын өнгө

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _selectedIndex = 0;

  static final List<Widget> _pages = [
    const DashboardScreen(),
    const IncomeExpenseScreen(),
    const BudgetScreen(),
    const ReportsScreen(),
    const TasksScreen(),
    const ProfileScreen(),
  ];

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  Future<void> _signOut() async {
    try {
      await context.read<AuthService>().signOut();
      if (mounted) {
        Navigator.pushAndRemoveUntil(
          context,
          MaterialPageRoute(builder: (context) => const LoginScreen()),
          (route) => false,
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Системээс гарахад алдаа гарлаа: ${e.toString()}'),
          behavior: SnackBarBehavior.floating,
          backgroundColor: Colors.red.shade700,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final authService = Provider.of<AuthService>(context);
    final user = authService.getCurrentUser();
    final String userInitial = (user?.displayName ?? 'Х')[0].toUpperCase();

    return Scaffold(
      backgroundColor: kBackgroundColor,
      appBar: AppBar(
        title: const Text(
          'Санхүү Апп',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 20,
          ),
        ),
        backgroundColor: kCardColor,
        elevation: 0,
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.logout_rounded, color: kPrimaryColor),
            onPressed: _signOut,
            tooltip: 'Гарах',
          ),
        ],
      ),
      drawer: Drawer(
        backgroundColor: kCardColor,
        elevation: 1,
        child: ListView(
          padding: EdgeInsets.zero,
          children: [
            UserAccountsDrawerHeader(
              accountName: Text(
                user?.displayName ?? 'Хэрэглэгч',
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                ),
              ),
              accountEmail: Text(
                user?.email ?? '',
                style: const TextStyle(
                  fontSize: 14,
                ),
              ),
              currentAccountPicture: CircleAvatar(
                backgroundColor: kPrimaryColor,
                child: Text(
                  userInitial,
                  style: const TextStyle(
                    fontSize: 28.0,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
              ),
              decoration: const BoxDecoration(
                color: kPrimaryColor,
              ),
            ),
            _buildDrawerItem(
              icon: Icons.dashboard_rounded,
              title: 'Хянах самбар',
              isSelected: _selectedIndex == 0,
              onTap: () {
                _onItemTapped(0);
                Navigator.pop(context);
              },
            ),
            _buildDrawerItem(
              icon: Icons.currency_exchange_rounded,
              title: 'Орлого & Зарлага',
              isSelected: _selectedIndex == 1,
              onTap: () {
                _onItemTapped(1);
                Navigator.pop(context);
              },
            ),
            _buildDrawerItem(
              icon: Icons.account_balance_wallet_rounded,
              title: 'Төсөв',
              isSelected: _selectedIndex == 2,
              onTap: () {
                _onItemTapped(2);
                Navigator.pop(context);
              },
            ),
            _buildDrawerItem(
              icon: Icons.bar_chart_rounded,
              title: 'Тайлан',
              isSelected: _selectedIndex == 3,
              onTap: () {
                _onItemTapped(3);
                Navigator.pop(context);
              },
            ),
            _buildDrawerItem(
              icon: Icons.task_alt_rounded,
              title: 'Ажлууд',
              isSelected: _selectedIndex == 4,
              onTap: () {
                _onItemTapped(4);
                Navigator.pop(context);
              },
            ),
            const Divider(height: 1, thickness: 1, color: Color(0xFFEEEEEE)),
            _buildDrawerItem(
              icon: Icons.person_rounded,
              title: 'Профайл',
              isSelected: _selectedIndex == 5,
              onTap: () {
                _onItemTapped(5);
                Navigator.pop(context);
              },
            ),
            _buildDrawerItem(
              icon: Icons.logout_rounded,
              title: 'Гарах',
              isSelected: false,
              onTap: _signOut,
              textColor: Colors.red.shade700,
              iconColor: Colors.red.shade700,
            ),
          ],
        ),
      ),
      body: _pages[_selectedIndex],
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          color: kCardColor,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 10,
              spreadRadius: 0,
              offset: const Offset(0, -3),
            ),
          ],
        ),
        child: BottomNavigationBar(
          type: BottomNavigationBarType.fixed,
          backgroundColor: kCardColor,
          elevation: 0,
          selectedItemColor: kPrimaryColor,
          unselectedItemColor: kTextLightColor,
          selectedLabelStyle: const TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 12,
          ),
          unselectedLabelStyle: const TextStyle(
            fontSize: 11,
          ),
          items: const <BottomNavigationBarItem>[
            BottomNavigationBarItem(
              icon: Icon(Icons.dashboard_rounded),
              label: 'Хянах самбар',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.currency_exchange_rounded),
              label: 'Орлого/Зарлага',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.account_balance_wallet_rounded),
              label: 'Төсөв',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.bar_chart_rounded),
              label: 'Тайлан',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.task_alt_rounded),
              label: 'Ажлууд',
            ),
          ],
          currentIndex: _selectedIndex < 5 ? _selectedIndex : 0,
          onTap: _onItemTapped,
        ),
      ),
    );
  }

  Widget _buildDrawerItem({
    required IconData icon,
    required String title,
    required bool isSelected,
    required VoidCallback onTap,
    Color? textColor,
    Color? iconColor,
  }) {
    return ListTile(
      leading: Icon(
        icon,
        color: iconColor ?? (isSelected ? kPrimaryColor : kTextLightColor),
        size: 22,
      ),
      title: Text(
        title,
        style: TextStyle(
          color: textColor ?? (isSelected ? kPrimaryColor : kTextColor),
          fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
        ),
      ),
      selected: isSelected,
      selectedTileColor: isSelected ? kPrimaryColor.withOpacity(0.1) : null,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(8),
      ),
      onTap: onTap,
      contentPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 4),
      dense: true,
    );
  }
}
