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
import 'chat_screen.dart';

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
    // const IncomeExpenseScreen(),
    const BudgetScreen(),
    const ReportsScreen(),
    const TasksScreen(),
    const ChatScreen(),
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
      body: _pages[_selectedIndex],
      bottomNavigationBar: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
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
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _buildBottomNavItem(
                  icon: Icons.dashboard_rounded,
                  title: 'Хянах самбар',
                  isSelected: _selectedIndex == 0,
                  onTap: () {
                    _onItemTapped(0);
                  },
                ),
                // _buildBottomNavItem(
                //   icon: Icons.currency_exchange_rounded,
                //   title: 'Орлого & Зарлага',
                //   isSelected: _selectedIndex == 1,
                //   onTap: () {
                //     _onItemTapped(1);
                //   },
                // ),
                _buildBottomNavItem(
                  icon: Icons.account_balance_wallet_rounded,
                  title: 'Төсөв',
                  isSelected: _selectedIndex == 1,
                  onTap: () {
                    _onItemTapped(1);
                  },
                ),
                _buildBottomNavItem(
                  icon: Icons.bar_chart_rounded,
                  title: 'Тайлан',
                  isSelected: _selectedIndex == 2,
                  onTap: () {
                    _onItemTapped(2);
                  },
                ),
                _buildBottomNavItem(
                  icon: Icons.task_alt_rounded,
                  title: 'Ажлууд',
                  isSelected: _selectedIndex == 3,
                  onTap: () {
                    _onItemTapped(3);
                  },
                ),
                _buildBottomNavItem(
                  icon: Icons.chat_rounded,
                  title: 'Чат',
                  isSelected: _selectedIndex == 4,
                  onTap: () {
                    _onItemTapped(4);
                  },
                ),
                _buildBottomNavItem(
                  icon: Icons.person_rounded,
                  title: 'Профайл',
                  isSelected: _selectedIndex == 5,
                  onTap: () {
                    _onItemTapped(5);
                  },
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBottomNavItem({
    required IconData icon,
    required String title,
    required bool isSelected,
    required VoidCallback onTap,
    Color? textColor,
    Color? iconColor,
  }) {
    return Expanded(
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 8),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                icon,
                color:
                    iconColor ?? (isSelected ? kPrimaryColor : kTextLightColor),
                size: 24,
              ),
              const SizedBox(height: 2),
              Text(
                title,
                style: TextStyle(
                  color: textColor ?? (isSelected ? kPrimaryColor : kTextColor),
                  fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                  fontSize: 11,
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
