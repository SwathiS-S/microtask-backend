import 'package:flutter/material.dart';
import '../../theme/app_theme.dart';
import '../../services/user_service.dart';
import '../../services/api_service.dart';
import 'add_money_screen.dart';
import 'withdrawal_screen.dart';

class WalletScreen extends StatefulWidget {
  const WalletScreen({super.key});

  @override
  State<WalletScreen> createState() => _WalletScreenState();
}

class _WalletScreenState extends State<WalletScreen> {
  double balance = 0.0;
  List<dynamic> transactions = [];
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    _fetchWalletData();
  }

  Future<void> _fetchWalletData() async {
    final user = UserService.getUser();
    if (user == null) return;

    setState(() => isLoading = true);
    
    final response = await ApiService.get("/users/${user.id}/wallet");
    final txResponse = await ApiService.get("/users/${user.id}/transactions");

    if (mounted) {
      setState(() {
        if (response != null && response['success'] == true) {
          balance = (response['balance'] ?? 0.0).toDouble();
        }
        if (txResponse != null && txResponse['success'] == true) {
          transactions = txResponse['transactions'] ?? [];
        }
        isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final user = UserService.getUser();
    final bool isProvider = user?.role == UserRole.taskProvider;

    return Scaffold(
      backgroundColor: AppTheme.cream,
      appBar: AppBar(
        title: const Text('Wallet'),
        actions: [
          IconButton(
            onPressed: _fetchWalletData,
            icon: const Icon(Icons.refresh),
          ),
        ],
      ),
      body: isLoading 
        ? const Center(child: CircularProgressIndicator())
        : SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Balance Card
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(32),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(24),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.05),
                        blurRadius: 20,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Column(
                    children: [
                      const Text(
                        'Available Balance',
                        style: TextStyle(
                          fontSize: 14,
                          color: AppTheme.textMuted,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 12),
                      Text(
                        '₹${balance.toStringAsFixed(2)}',
                        style: const TextStyle(
                          fontSize: 48,
                          fontWeight: FontWeight.w800,
                          color: AppTheme.navy,
                        ),
                      ),
                      const SizedBox(height: 32),
                      Row(
                        children: [
                          if (!isProvider)
                            Expanded(
                              child: ElevatedButton(
                                onPressed: () => Navigator.push(
                                  context,
                                  MaterialPageRoute(builder: (_) => const WithdrawalScreen()),
                                ).then((_) => _fetchWalletData()),
                                style: AppTheme.goldButton,
                                child: const Text('Withdraw'),
                              ),
                            ),
                          if (!isProvider) const SizedBox(width: 12),
                          Expanded(
                            child: OutlinedButton(
                              onPressed: () => Navigator.push(
                                context,
                                MaterialPageRoute(builder: (_) => const AddMoneyScreen()),
                              ).then((_) => _fetchWalletData()),
                              style: AppTheme.outlineButton,
                              child: const Text('Add Money'),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                
                const SizedBox(height: 40),
                
                // Transaction History
                const Text('Transaction History', style: AppTheme.heading3),
                const SizedBox(height: 16),
                
                if (transactions.isEmpty)
                  const Center(
                    child: Padding(
                      padding: EdgeInsets.symmetric(vertical: 40),
                      child: Text('No transactions yet', style: AppTheme.bodyMuted),
                    ),
                  )
                else
                  ListView.separated(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: transactions.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 12),
                    itemBuilder: (context, index) {
                      final tx = transactions[index];
                      final bool isCredit = tx['type'] == 'credit' || tx['type'] == 'deposit';
                      
                      return Container(
                        padding: const EdgeInsets.all(16),
                        decoration: AppTheme.cardDecoration,
                        child: Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(10),
                              decoration: BoxDecoration(
                                color: (isCredit ? AppTheme.success : AppTheme.error).withOpacity(0.1),
                                shape: BoxShape.circle,
                              ),
                              child: Icon(
                                isCredit ? Icons.arrow_downward : Icons.arrow_upward,
                                color: isCredit ? AppTheme.success : AppTheme.error,
                                size: 20,
                              ),
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    tx['description'] ?? 'Transaction',
                                    style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    tx['date'] ?? '',
                                    style: AppTheme.small,
                                  ),
                                ],
                              ),
                            ),
                            Text(
                              '${isCredit ? '+' : '-'}₹${tx['amount']}',
                              style: TextStyle(
                                fontWeight: FontWeight.w700,
                                fontSize: 15,
                                color: isCredit ? AppTheme.success : AppTheme.error,
                              ),
                            ),
                          ],
                        ),
                      );
                    },
                  ),
              ],
            ),
          ),
    );
  }
}
