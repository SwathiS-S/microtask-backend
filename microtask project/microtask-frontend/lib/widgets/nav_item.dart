import 'package:flutter/material.dart';
import '../screens/home/home_screen.dart';
import '../screens/auth/login_screen.dart';
import '../screens/wallet/wallet_screen.dart';
import '../screens/tasks/task_list_screen.dart';
import '../screens/profile/account_window.dart';
import '../screens/wallet/transaction_screen.dart';

class NavItem extends StatelessWidget {
  final String title;
  const NavItem({super.key, required this.title});

  void navigate(BuildContext context) {
    // Check current route to avoid unnecessary navigation
    final currentRoute = ModalRoute.of(context)?.settings.name;
    
    try {
      switch (title) {
        case 'Home':
          // Only navigate if not already on home
          if (currentRoute != '/') {
            Navigator.pushReplacementNamed(context, '/');
          }
          break;
        case 'Login':
          // Only navigate if not already on login
          if (currentRoute != '/login') {
            Navigator.pushReplacementNamed(context, '/login');
          }
          break;
        case 'Tasks':
          Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const TaskListScreen()),
          );
          break;
        case 'Wallet':
          Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const WalletScreen()),
          );
          break;
        case 'Transactions':
          Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const TransactionsScreen()),
          );
          break;
        case 'Profile':
          Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const AccountWindow(initialIndex: 1)),
          );
          break;
        default:
          break;
      }
    } catch (e) {
      // Fallback navigation using MaterialPageRoute
      switch (title) {
        case 'Home':
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(builder: (_) => const HomeScreen()),
          );
          break;
        case 'Login':
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(builder: (_) => const LoginScreen()),
          );
          break;
        default:
          break;
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: () => navigate(context),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        child: Text(
          title,
          style: const TextStyle(
            color: Colors.black87,
            fontSize: 16,
          ),
        ),
      ),
    );
  }
}
