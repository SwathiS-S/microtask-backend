import 'package:flutter/material.dart';
import 'theme/app_theme.dart';
import 'screens/onboarding/role_selection_screen.dart';
import 'screens/onboarding/landing_screen.dart';
import 'screens/auth/login_screen.dart';
import 'screens/home/home_screen.dart';
import 'screens/home/business_lead_screen.dart';
import 'screens/tasks/create_task_screen.dart';
import 'screens/tasks/task_list_screen.dart';
import 'screens/wallet/add_money_screen.dart';
import 'screens/wallet/wallet_screen.dart';
import 'screens/wallet/transaction_screen.dart';
import 'screens/wallet/bank_setup_screen.dart';
import 'screens/wallet/withdrawal_screen.dart';
import 'screens/admin/withdrawal_management_screen.dart';
import 'screens/profile/profile_screen.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'TaskNest',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.theme,
      initialRoute: '/',
      routes: {
        '/': (context) => const RoleSelectionScreen(),
        '/landing': (context) => const LandingScreen(),
        '/home': (context) => const HomeScreen(),
        '/login': (context) => const LoginScreen(),
        '/business': (context) => const BusinessLeadScreen(),
        '/create-task': (context) => const CreateTaskScreen(),
        '/tasks': (context) => const TaskListScreen(),
        '/transactions': (context) => const TransactionsScreen(),
        '/add-money': (context) => const AddMoneyScreen(),
        '/wallet': (context) => const WalletScreen(),
        '/profile': (context) => const ProfileScreen(),
        '/bank-setup': (context) => const BankSetupScreen(role: 'user'),
        '/admin/withdrawals': (context) => const AdminWithdrawalManagementScreen(),
      },
    );
  }
}
