import 'package:flutter/material.dart';
import '../../services/user_service.dart';
import '../../services/api_service.dart';
import 'add_money_screen.dart';
import 'bank_setup_screen.dart';
import 'withdrawal_screen.dart';
import 'withdrawal_history_screen.dart';

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
      if (balRes != null && balRes is Map && balRes['success'] == true) {
        setState(() {
          _balance = (balRes['balance'] ?? 0).toDouble();
          _escrowBalance = (balRes['escrowBalance'] ?? 0).toDouble();
          _pendingWithdrawal = (balRes['pendingWithdrawal'] ?? 0).toDouble();
        });
      }

      // Load Transactions
      final txRes = await ApiService.get('/wallet/transactions/${UserService.userId}');
      if (txRes != null && txRes is Map && txRes['success'] == true) {
        final List txns = txRes['transactions'] ?? [];
        setState(() {
          _transactions = txns;
          // Compute totals from transaction history
          _totalEarned = txns
              .where((t) => ['credit', 'refund', 'escrow_release']
                  .contains((t['transactionType'] ?? t['type'] ?? '').toString().toLowerCase()))
              .fold(0.0, (sum, t) => sum + ((t['amount'] ?? 0) as num).toDouble());
          _totalSpent = txns
              .where((t) => ['debit', 'escrow_hold', 'withdrawal']
                  .contains((t['transactionType'] ?? t['type'] ?? '').toString().toLowerCase()))
              .fold(0.0, (sum, t) => sum + ((t['amount'] ?? 0) as num).toDouble());
        });
      }

      // Load Bank Details
      final bankRes = await ApiService.get('/bank/details/${UserService.userId}');
      if (bankRes != null && bankRes is Map && bankRes['success'] == true) {
        setState(() {
          _bankAccount = bankRes['bankAccount'];
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
        MaterialPageRoute(
            builder: (context) => BankSetupScreen(
                role: UserService.isTaskProvider ? 'provider' : 'user')),
      );
      if (result == true) _loadData();
      return;
    }

    final result = await Navigator.push(
      context,
      MaterialPageRoute(
          builder: (context) =>
              WithdrawalScreen(balance: _balance, bankAccount: _bankAccount!)),
    );
    if (result == true) _loadData();
  }

  @override
  Widget build(BuildContext context) {
    final bool hasBank = _bankAccount != null;

    return Scaffold(
      backgroundColor: const Color(0xFFF5F6FA),
      appBar: AppBar(
        backgroundColor: const Color(0xFF1E3A5F),
        title: const Text('My Wallet',
            style: TextStyle(fontWeight: FontWeight.bold)),
        actions: [
          IconButton(
              onPressed: () => Navigator.push(
                  context,
                  MaterialPageRoute(
                      builder: (context) => const WithdrawalHistoryScreen())),
              icon: const Icon(Icons.history)),
          IconButton(onPressed: _loadData, icon: const Icon(Icons.refresh)),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: _loadData,
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (!hasBank) _buildBankPrompt(),

              // Show correct header based on role
              UserService.isTaskProvider
                  ? _buildProviderHeader()
                  : _buildUserHeader(),

              const SizedBox(height: 24),
              const Text('Transaction History',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              const SizedBox(height: 12),

              if (_isLoading)
                const Center(child: CircularProgressIndicator())
              else if (_transactions.isEmpty)
                const Center(
                    child: Padding(
                        padding: EdgeInsets.all(20),
                        child: Text('No transactions yet')))
              else
                ..._transactions
                    .map((tx) =>
                        _buildTransactionItem(tx as Map<String, dynamic>))
                    .toList(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildBankPrompt() {
    return Container(
      margin: const EdgeInsets.only(bottom: 20),
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
          const Expanded(
              child: Text(
                  'Please connect your bank account to enable withdrawals.')),
          TextButton(
            onPressed: () async {
              final res = await Navigator.push(
                  context,
                  MaterialPageRoute(
                      builder: (context) => BankSetupScreen(
                          role: UserService.isTaskProvider
                              ? 'provider'
                              : 'user')));
              if (res == true) _loadData();
            },
            child: const Text('Connect'),
          ),
        ],
      ),
    );
  }

  Widget _buildProviderHeader() {
    return Column(
      children: [
        _buildMainCard('Total Balance', _balance, Colors.blue,
            showWithdraw: _balance > 0),
        const SizedBox(height: 16),
        Row(
          children: [
            Expanded(
                child: _buildMiniCard('Active Escrow', _escrowBalance, Colors.orange)),
            const SizedBox(width: 16),
            Expanded(
                child: _buildMiniCard('Total Spent', _totalSpent, Colors.red)),
          ],
        ),
      ],
    );
  }

  Widget _buildUserHeader() {
    return Column(
      children: [
        _buildMainCard('Available Balance', _balance, Colors.green,
            showWithdraw: true),
        const SizedBox(height: 16),
        Row(
          children: [
            Expanded(
                child: _buildMiniCard(
                    'Pending', _pendingWithdrawal, Colors.orange)),
            const SizedBox(width: 16),
            Expanded(
                child:
                    _buildMiniCard('Total Earned', _totalEarned, Colors.blue)),
          ],
        ),
      ],
    );
  }

  Widget _buildMainCard(String label, double amount, Color color,
      {bool showWithdraw = false}) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
              color: color.withOpacity(0.3),
              blurRadius: 10,
              offset: const Offset(0, 5))
        ],
      ),
      child: Column(
        children: [
          Text(label,
              style: const TextStyle(color: Colors.white70, fontSize: 16)),
          const SizedBox(height: 8),
          Text('₹${amount.toStringAsFixed(2)}',
              style: const TextStyle(
                  color: Colors.white,
                  fontSize: 36,
                  fontWeight: FontWeight.bold)),
          if (showWithdraw) ...[
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: _handleWithdraw,
              style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.white, foregroundColor: color),
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
          Text('₹${amount.toStringAsFixed(0)}',
              style: TextStyle(
                  color: color, fontSize: 18, fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }

  Widget _buildTransactionItem(Map<String, dynamic> tx) {
    // ✅ FIX: read transactionType first, fallback to type
    final type = (tx['transactionType'] ?? tx['type'] ?? '').toString().toLowerCase();
    final amount = ((tx['amount'] ?? 0) as num).toDouble();
    final status = (tx['status'] ?? 'completed').toString();
    final description = tx['description'] ?? tx['taskTitle'] ?? 'Transaction';

    Color color;
    String sign;
    IconData icon;

    switch (type) {
      case 'credit':
      case 'refund':
      case 'escrow_release':
        color = Colors.green;
        sign = '+';
        icon = Icons.add_circle_outline;
        break;
      case 'debit':
      case 'withdrawal':
      case 'withdrawal_completed':
        color = Colors.red;
        sign = '-';
        icon = Icons.remove_circle_outline;
        break;
      case 'escrow_hold':
        color = Colors.orange;
        sign = '-';
        icon = Icons.lock_clock;
        break;
      default:
        color = Colors.grey;
        sign = '';
        icon = Icons.payment;
    }

    // Format date
    String dateStr = '';
    if (tx['date'] != null) {
      try {
        final dt = DateTime.parse(tx['date'].toString()).toLocal();
        dateStr =
            '${dt.day}/${dt.month}/${dt.year} ${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}';
      } catch (_) {}
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
          color: Colors.white, borderRadius: BorderRadius.circular(12),
          boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 6)]),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, color: color, size: 20),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(description,
                    style: const TextStyle(
                        fontWeight: FontWeight.bold, fontSize: 14)),
                if (tx['taskTitle'] != null && tx['taskTitle'] != '')
                  Text(tx['taskTitle'],
                      style: const TextStyle(fontSize: 12, color: Colors.grey)),
                if (dateStr.isNotEmpty)
                  Text(dateStr,
                      style: const TextStyle(fontSize: 11, color: Colors.grey)),
                Container(
                  margin: const EdgeInsets.only(top: 2),
                  padding:
                      const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(
                    color: color.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Text(status.toUpperCase(),
                      style: TextStyle(
                          fontSize: 10,
                          color: color,
                          fontWeight: FontWeight.bold)),
                ),
              ],
            ),
          ),
          Text('$sign₹${amount.toStringAsFixed(0)}',
              style: TextStyle(
                  color: color, fontWeight: FontWeight.bold, fontSize: 16)),
        ],
      ),
    );
  }
}