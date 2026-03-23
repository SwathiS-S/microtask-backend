import 'package:flutter/material.dart';
import '../../theme/app_theme.dart';
import '../tasks/create_task_screen.dart';
import '../wallet/wallet_screen.dart';
import '../profile/profile_screen.dart';
import '../profile/legal_screen.dart';

class BusinessLeadScreen extends StatefulWidget {
  const BusinessLeadScreen({super.key});

  @override
  State<BusinessLeadScreen> createState() => _BusinessLeadScreenState();
}

class _BusinessLeadScreenState extends State<BusinessLeadScreen> {
  int _currentIndex = 0;
  final List<Widget> _tabs = [
    const CreateTaskScreen(),
    const WalletScreen(),
    const DashboardScreen(), // Replaces ProfileScreen
    const LegalScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.cream,
      body: IndexedStack(
        index: _currentIndex,
        children: _tabs,
      ),
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          color: AppTheme.navy,
          border: const Border(
            top: BorderSide(color: AppTheme.gold, width: 2),
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.15),
              blurRadius: 12,
              offset: const Offset(0, -4),
            ),
          ],
        ),
        child: BottomNavigationBar(
          currentIndex: _currentIndex,
          onTap: (index) => setState(() => _currentIndex = index),
          backgroundColor: Colors.transparent,
          elevation: 0,
          type: BottomNavigationBarType.fixed,
          selectedItemColor: AppTheme.gold,
          unselectedItemColor: Colors.white.withOpacity(0.5),
          selectedFontSize: 11,
          unselectedFontSize: 11,
          items: const [
            BottomNavigationBarItem(
              icon: Icon(Icons.add_circle_outline),
              label: 'Create Task',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.account_balance_wallet_outlined),
              label: 'Wallet',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.dashboard_outlined),
              label: 'Dashboard',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.policy_outlined),
              label: 'Legal',
            ),
          ],
        ),
      ),
    );
  }
}
