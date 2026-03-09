import 'package:flutter/material.dart';
import '../../services/user_service.dart';
import '../../services/api_service.dart';
import 'add_money_screen.dart';
import 'bank_setup_screen.dart';
import 'withdrawal_screen.dart';

class WalletScreen extends StatefulWidget {
  const WalletScreen({super.key});

  @override
  State<WalletScreen> createState() => _WalletScreenState();
}

class _WalletScreenState extends State<WalletScreen> {
  bool _isLoading = false;
  double _balance = 0;
  double _escrowBalance = 0;
  double _pendingWithdrawal = 0;
  double _totalEarned = 0;
  double _totalSpent = 0;
  List<dynamic> _transactions = [];
  Map<String, dynamic>? _bankAccount;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);
    try {
      // Load Wallet Balance
      final balRes = await ApiService.get('/wallet/balance/${UserService.userId}');
      if (balRes != null && balRes is Map && balRes['success']) {
        setState(() {
          _balance = (balRes['balance'] ?? 0).toDouble();
          _escrowBalance = (balRes['escrowBalance'] ?? 0).toDouble();
        });
      }

      // Load Transactions
      final txRes = await ApiService.get('/wallet/transactions/${UserService.userId}');
      if (txRes != null && txRes is Map && txRes['success']) {
        setState(() {
          _transactions = txRes['transactions'];
          // Calculate metrics
          _totalEarned = _transactions
              .where((t) => t['type'] == 'credit')
              .fold(0.0, (sum, t) => sum + (t['amount'] ?? 0));
          _totalSpent = _transactions
              .where((t) => t['type'] == 'escrow_hold')
              .fold(0.0, (sum, t) => sum + (t['amount'] ?? 0));
        });
      }

      // Load Bank Details
      final bankRes = await ApiService.get('/bank/details/${UserService.userId}');
      if (bankRes != null && bankRes is Map && bankRes['success']) {
        setState(() {
          _bankAccount = bankRes['bankAccount'];
        });
      }

      // Load Withdrawal History for pending amount
      final withRes = await ApiService.get('/wallet/withdrawal-history/${UserService.userId}');
      if (withRes != null && withRes is Map && withRes['success']) {
        final history = withRes['history'] as List;
        setState(() {
          _pendingWithdrawal = history
              .where((w) => w['status'] == 'pending' || w['status'] == 'processing')
              .fold(0.0, (sum, w) => sum + (w['amount'] ?? 0));
        });
      }
    } catch (e) {
      debugPrint('Error loading wallet data: $e');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  void _handleWithdraw() async {
    if (_bankAccount == null) {
      final result = await Navigator.push(
        context,
        MaterialPageRoute(builder: (context) => BankSetupScreen(role: UserService.isTaskProvider ? 'provider' : 'user')),
      );
      if (result == true) _loadData();
      return;
    }

    final result = await Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => WithdrawalScreen(balance: _balance)),
    );
    if (result == true) _loadData();
  }

  @override
  Widget build(BuildContext context) {
    final isProvider = UserService.isTaskProvider;
    final bool hasBank = _bankAccount != null;

    return Scaffold(
      backgroundColor: const Color(0xFFF5F6FA),
      appBar: AppBar(
        backgroundColor: const Color(0xFF1E3A5F),
        title: const Text('My Wallet', style: TextStyle(fontWeight: FontWeight.bold)),
        actions: [
          IconButton(onPressed: _loadData, icon: const Icon(Icons.refresh)),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: _loadData,
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (!hasBank)
                _buildBankPrompt(),
              
              if (isProvider) 
                _buildProviderHeader()
              else 
                _buildUserHeader(),

              const SizedBox(height: 24),
              const Text('Transaction History', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              const SizedBox(height: 12),
              
              if (_isLoading)
                const Center(child: CircularProgressIndicator())
              else if (_transactions.isEmpty)
                const Center(child: Padding(padding: EdgeInsets.all(20), child: Text('No transactions yet')))
              else
                ..._transactions.map((tx) => _buildTransactionItem(tx)).toList(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildBankPrompt() {
    return Container(
      margin: const EdgeInsets.bottom(20),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.orange[50],
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.orange[200]!),
      ),
      child: Row(
        children: [
          const Icon(Icons.warning_amber_rounded, color: Colors.orange),
          const SizedBox(width: 12),
          const Expanded(child: Text('Please connect your bank account to enable withdrawals.')),
          TextButton(
            onPressed: () async {
              final res = await Navigator.push(
                context, 
                MaterialPageRoute(builder: (context) => BankSetupScreen(role: UserService.isTaskProvider ? 'provider' : 'user'))
              );
              if (res == true) _loadData();
            }, 
            child: const Text('Connect')
          ),
        ],
      ),
    );
  }

  Widget _buildProviderHeader() {
    return Column(
      children: [
        _buildMainCard('Total Balance', _balance, Colors.blue, showWithdraw: _balance > 0),
        const SizedBox(height: 16),
        Row(
          children: [
            Expanded(child: _buildMiniCard('Active Escrow', _escrowBalance, Colors.orange)),
            const SizedBox(width: 16),
            Expanded(child: _buildMiniCard('Total Spent', _totalSpent, Colors.red)),
          ],
        ),
      ],
    );
  }

  Widget _buildUserHeader() {
    return Column(
      children: [
        _buildMainCard('Available Balance', _balance, Colors.green, showWithdraw: true),
        const SizedBox(height: 16),
        Row(
          children: [
            Expanded(child: _buildMiniCard('Pending', _pendingWithdrawal, Colors.orange)),
            const SizedBox(width: 16),
            Expanded(child: _buildMiniCard('Total Earned', _totalEarned, Colors.blue)),
          ],
        ),
      ],
    );
  }

  Widget _buildMainCard(String label, double amount, Color color, {bool showWithdraw = false}) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [BoxShadow(color: color.withOpacity(0.3), blurRadius: 10, offset: const Offset(0, 5))],
      ),
      child: Column(
        children: [
          Text(label, style: const TextStyle(color: Colors.white70, fontSize: 16)),
          const SizedBox(height: 8),
          Text('₹${amount.toStringAsFixed(2)}', style: const TextStyle(color: Colors.white, fontSize: 36, fontWeight: FontWeight.bold)),
          if (showWithdraw) ...[
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: _handleWithdraw,
              style: ElevatedButton.styleFrom(backgroundColor: Colors.white, foregroundColor: color),
              child: const Text('Withdraw Funds'),
            ),
          ]
        ],
      ),
    );
  }

  Widget _buildMiniCard(String label, double amount, Color color) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color.withOpacity(0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: TextStyle(color: Colors.grey[600], fontSize: 12)),
          const SizedBox(height: 4),
          Text('₹${amount.toStringAsFixed(0)}', style: TextStyle(color: color, fontSize: 18, fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }

  Widget _buildTransactionItem(Map<String, dynamic> tx) {
    final type = tx['type'] as String;
    final amount = (tx['amount'] ?? 0).toDouble();
    final status = tx['status'] as String;
    
    Color color;
    String sign;
    IconData icon;
    String title = tx['description'] ?? 'Transaction';

    switch (type) {
      case 'credit':
      case 'refund':
        color = Colors.green; sign = '+'; icon = Icons.add_circle_outline;
        break;
      case 'debit':
      case 'escrow_release':
      case 'withdrawal':
        color = Colors.red; sign = '-'; icon = Icons.remove_circle_outline;
        break;
      case 'escrow_hold':
        color = Colors.orange; sign = '-'; icon = Icons.lock_clock;
        break;
      default:
        color = Colors.grey; sign = ''; icon = Icons.payment;
    }

    return Container(
      margin: const EdgeInsets.bottom(12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12)),
      child: Row(
        children: [
          Icon(icon, color: color),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: const TextStyle(fontWeight: FontWeight.bold)),
                Text(tx['taskTitle'] ?? '', style: const TextStyle(fontSize: 12, color: Colors.grey)),
                Text(status.toUpperCase(), style: TextStyle(fontSize: 10, color: color, fontWeight: FontWeight.bold)),
              ],
            ),
          ),
          Text('$sign₹${amount.toStringAsFixed(0)}', style: TextStyle(color: color, fontWeight: FontWeight.bold, fontSize: 16)),
        ],
      ),
    );
  }
}


class _TransactionItem extends StatelessWidget {
  final String title;
  final String amount;
  final Color color;
  final String date;

  const _TransactionItem({
    required this.title,
    required this.amount,
    required this.color,
    required this.date,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 8,
          ),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(
                  color == Colors.green
                      ? Icons.add_circle
                      : color == Colors.red
                          ? Icons.remove_circle
                          : Icons.account_balance_wallet,
                  color: color,
                  size: 24,
                ),
              ),
              const SizedBox(width: 12),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: Colors.black87,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    date,
                    style: const TextStyle(
                      fontSize: 13,
                      color: Colors.black54,
                    ),
                  ),
                ],
              ),
            ],
          ),
          Text(
            amount,
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
        ],
      ),
    );
  }
}
