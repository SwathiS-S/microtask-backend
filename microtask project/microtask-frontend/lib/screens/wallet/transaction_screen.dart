import 'package:flutter/material.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import '../../services/user_service.dart';
import '../../widgets/top_actions.dart';

class TransactionsScreen extends StatefulWidget {
  const TransactionsScreen({super.key});

  @override
  State<TransactionsScreen> createState() => _TransactionsScreenState();
}

class _TransactionsScreenState extends State<TransactionsScreen> {
  List<Map<String, dynamic>> transactions = [];
  bool isLoading = true;
  String? error;

  @override
  void initState() {
    super.initState();
    _fetchTransactions();
  }

  Future<void> _fetchTransactions() async {
    setState(() {
      isLoading = true;
      error = null;
    });

    try {
      final userId = UserService.userId; // make sure UserService exposes userId
      if (userId == null) {
        setState(() {
          error = 'User not logged in';
          isLoading = false;
        });
        return;
      }

      final response = await http.get(
        Uri.parse('YOUR_BASE_URL/wallet/transactions/$userId'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer ${UserService.token}',
        },
      );

      final data = jsonDecode(response.body);

      if (response.statusCode == 200 && data['success'] == true) {
        final List rawTxns = data['transactions'] ?? [];

        setState(() {
          transactions = rawTxns.map((txn) {
            // Map backend transactionType to display type
            final txnType = (txn['transactionType'] ?? '').toString().toLowerCase();
            final isCredit = ['credit', 'escrow_release', 'refund'].contains(txnType);

            return {
              'title': _getTitleFromType(txnType, txn['description']),
              'amount': txn['amount'] ?? 0,
              'type': isCredit ? 'CREDIT' : 'DEBIT',
              'status': (txn['status'] ?? 'completed').toString().toUpperCase(),
              'created_at': txn['date'] != null
                  ? _formatDate(txn['date'])
                  : 'N/A',
              'taskId': txn['taskId'],
            };
          }).toList();
          isLoading = false;
        });
      } else {
        setState(() {
          error = data['message'] ?? 'Failed to load transactions';
          isLoading = false;
        });
      }
    } catch (e) {
      setState(() {
        error = 'Network error: $e';
        isLoading = false;
      });
    }
  }

  String _getTitleFromType(String type, String? description) {
    switch (type) {
      case 'credit':
        return 'Payment Received';
      case 'debit':
        return 'Payment Sent';
      case 'escrow_hold':
        return 'Escrow Held';
      case 'escrow_release':
        return 'Escrow Released';
      case 'refund':
        return 'Refund';
      case 'withdrawal':
        return 'Withdrawal';
      default:
        return description ?? 'Transaction';
    }
  }

  String _formatDate(String rawDate) {
    try {
      final dt = DateTime.parse(rawDate).toLocal();
      return '${dt.year}-${dt.month.toString().padLeft(2, '0')}-${dt.day.toString().padLeft(2, '0')} '
          '${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}';
    } catch (_) {
      return rawDate;
    }
  }

  @override
  Widget build(BuildContext context) {
    final userName = UserService.userName ?? 'User';

    return Scaffold(
      backgroundColor: const Color(0xFFF5F6FA),
      drawer: Drawer(
        child: ListView(
          padding: EdgeInsets.zero,
          children: [
            DrawerHeader(
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  colors: [Color(0xFF1E3A5F), Color(0xFF2C5282)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  const Text('TaskNest',
                      style: TextStyle(
                          color: Colors.white,
                          fontSize: 28,
                          fontWeight: FontWeight.bold)),
                  const SizedBox(height: 8),
                  Text(userName,
                      style: const TextStyle(
                          color: Colors.white70, fontSize: 16)),
                ],
              ),
            ),
            _drawerItem(context, Icons.home, 'Home', '/home'),
            _drawerItem(context, Icons.task_alt, 'Tasks', '/tasks'),
            ListTile(
              leading: const Icon(Icons.receipt_long, color: Color(0xFF1E3A5F)),
              title: const Text('Transactions'),
              onTap: () => Navigator.pop(context),
            ),
            _drawerItem(context, Icons.account_balance_wallet, 'Wallet', '/wallet'),
            _drawerItem(context, Icons.person, 'Profile', '/profile'),
          ],
        ),
      ),
      appBar: AppBar(
        backgroundColor: const Color(0xFF1E3A5F),
        elevation: 0,
        leading: Builder(
          builder: (context) => IconButton(
            icon: const Icon(Icons.menu, color: Colors.white),
            onPressed: () {
              final scaffold = Scaffold.of(context);
              scaffold.isDrawerOpen
                  ? Navigator.pop(context)
                  : scaffold.openDrawer();
            },
          ),
        ),
        title: const Text('Transactions',
            style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
                fontSize: 24)),
        centerTitle: true,
        actions: topActions(context),
      ),
      body: SafeArea(
        child: Column(
          children: [
            // Header
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: Colors.white,
                boxShadow: [
                  BoxShadow(
                      color: Colors.black.withOpacity(0.05),
                      blurRadius: 10)
                ],
              ),
              child: const Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Transaction History',
                      style: TextStyle(
                          fontSize: 28,
                          fontWeight: FontWeight.bold,
                          color: Colors.black87)),
                  SizedBox(height: 4),
                  Text('View all your financial transactions',
                      style: TextStyle(fontSize: 14, color: Colors.black54)),
                ],
              ),
            ),

            // Body
            Expanded(
              child: isLoading
                  ? const Center(child: CircularProgressIndicator())
                  : error != null
                      ? _ErrorState(error: error!, onRetry: _fetchTransactions)
                      : transactions.isEmpty
                          ? const _EmptyState()
                          : RefreshIndicator(
                              onRefresh: _fetchTransactions,
                              child: ListView.builder(
                                padding: const EdgeInsets.all(16),
                                itemCount: transactions.length,
                                itemBuilder: (context, index) {
                                  return _TransactionCard(
                                      transaction: transactions[index]);
                                },
                              ),
                            ),
            ),
          ],
        ),
      ),
    );
  }

  ListTile _drawerItem(
      BuildContext context, IconData icon, String title, String route) {
    return ListTile(
      leading: Icon(icon, color: const Color(0xFF1E3A5F)),
      title: Text(title),
      onTap: () {
        Navigator.pop(context);
        Navigator.pushNamed(context, route);
      },
    );
  }
}

// ── Cards & States ──────────────────────────────────────────────

class _TransactionCard extends StatelessWidget {
  final Map<String, dynamic> transaction;
  const _TransactionCard({required this.transaction});

  @override
  Widget build(BuildContext context) {
    final isCredit = transaction['type'] == 'CREDIT';
    final isSuccess = transaction['status'] == 'COMPLETED' ||
        transaction['status'] == 'SUCCESS';

    return Card(
      elevation: 2,
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: isCredit
                    ? Colors.green.withOpacity(0.1)
                    : Colors.red.withOpacity(0.1),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(
                isCredit ? Icons.arrow_downward : Icons.arrow_upward,
                color: isCredit ? Colors.green : Colors.red,
                size: 24,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(transaction['title'],
                      style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Colors.black87)),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: isSuccess
                              ? Colors.green.withOpacity(0.1)
                              : Colors.orange.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Text(
                          transaction['status'],
                          style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
                              color: isSuccess ? Colors.green : Colors.orange),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text(transaction['created_at'],
                          style: const TextStyle(
                              fontSize: 12, color: Colors.black54)),
                    ],
                  ),
                ],
              ),
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  '${isCredit ? '+' : '-'} ₹${transaction['amount']}',
                  style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: isCredit ? Colors.green : Colors.red),
                ),
                const SizedBox(height: 4),
                Text(transaction['type'],
                    style: TextStyle(
                        fontSize: 12, color: Colors.grey.shade600)),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  const _EmptyState();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.receipt_long_outlined,
                size: 80, color: Colors.grey.shade400),
            const SizedBox(height: 24),
            Text('No Transactions Yet',
                style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: Colors.grey.shade700)),
            const SizedBox(height: 8),
            Text('Your transaction history will appear here',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 16, color: Colors.grey.shade500)),
          ],
        ),
      ),
    );
  }
}

class _ErrorState extends StatelessWidget {
  final String error;
  final VoidCallback onRetry;
  const _ErrorState({required this.error, required this.onRetry});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.error_outline, size: 80, color: Colors.red.shade300),
            const SizedBox(height: 24),
            Text('Failed to Load',
                style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                    color: Colors.grey.shade700)),
            const SizedBox(height: 8),
            Text(error,
                textAlign: TextAlign.center,
                style:
                    TextStyle(fontSize: 14, color: Colors.grey.shade500)),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: onRetry,
              icon: const Icon(Icons.refresh),
              label: const Text('Retry'),
              style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF1E3A5F)),
            ),
          ],
        ),
      ),
    );
  }
}