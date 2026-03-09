import 'package:flutter/material.dart';
import '../../services/user_service.dart';
import '../../widgets/top_actions.dart';

class TransactionsScreen extends StatelessWidget {
  const TransactionsScreen({super.key});

  // Dummy list simulating what backend would return
  final List<Map<String, dynamic>> transactions = const [
    {
      "title": "Added Money",
      "amount": 500,
      "type": "CREDIT",
      "status": "SUCCESS",
      "created_at": "2026-01-26 10:00"
    },
    {
      "title": "Task Accepted",
      "amount": 200,
      "type": "DEBIT",
      "status": "SUCCESS",
      "created_at": "2026-01-25 16:00"
    },
    {
      "title": "Task Completed",
      "amount": 150,
      "type": "CREDIT",
      "status": "SUCCESS",
      "created_at": "2026-01-24 12:30"
    },
    {
      "title": "Task Completed",
      "amount": 300,
      "type": "CREDIT",
      "status": "SUCCESS",
      "created_at": "2026-01-23 09:15"
    },
  ];

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
                  const Text(
                    'TaskNest',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 28,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    userName,
                    style: const TextStyle(
                      color: Colors.white70,
                      fontSize: 16,
                    ),
                  ),
                ],
              ),
            ),
            ListTile(
              leading: const Icon(Icons.home, color: Color(0xFF1E3A5F)),
              title: const Text('Home'),
              onTap: () {
                Navigator.pop(context);
                Navigator.pushNamed(context, '/home');
              },
            ),
            ListTile(
              leading: const Icon(Icons.task_alt, color: Color(0xFF1E3A5F)),
              title: const Text('Tasks'),
              onTap: () {
                Navigator.pop(context);
                Navigator.pushNamed(context, '/tasks');
              },
            ),
            ListTile(
              leading: const Icon(Icons.receipt_long, color: Color(0xFF1E3A5F)),
              title: const Text('Transactions'),
              onTap: () {
                Navigator.pop(context);
              },
            ),
            ListTile(
              leading: const Icon(Icons.account_balance_wallet, color: Color(0xFF1E3A5F)),
              title: const Text('Wallet'),
              onTap: () {
                Navigator.pop(context);
                Navigator.pushNamed(context, '/wallet');
              },
            ),
            ListTile(
              leading: const Icon(Icons.person, color: Color(0xFF1E3A5F)),
              title: const Text('Profile'),
              onTap: () {
                Navigator.pop(context);
                Navigator.pushNamed(context, '/profile');
              },
            ),
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
              if (scaffold.isDrawerOpen) {
                Navigator.pop(context);
              } else {
                scaffold.openDrawer();
              }
            },
          ),
        ),
        title: const Text(
          'Transactions',
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
            fontSize: 24,
          ),
        ),
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
                    blurRadius: 10,
                  ),
                ],
              ),
              child: const Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Transaction History',
                    style: TextStyle(
                      fontSize: 28,
                      fontWeight: FontWeight.bold,
                      color: Colors.black87,
                    ),
                  ),
                  SizedBox(height: 4),
                  Text(
                    'View all your financial transactions',
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.black54,
                    ),
                  ),
                ],
              ),
            ),

            // Transactions List
            Expanded(
              child: transactions.isEmpty
                  ? _EmptyState()
                  : ListView.builder(
                      padding: const EdgeInsets.all(16),
                      itemCount: transactions.length,
                      itemBuilder: (context, index) {
                        final txn = transactions[index];
                        return _TransactionCard(transaction: txn);
                      },
                    ),
            ),
          ],
        ),
      ),
    );
  }
}

class _TransactionCard extends StatelessWidget {
  final Map<String, dynamic> transaction;

  const _TransactionCard({required this.transaction});

  @override
  Widget build(BuildContext context) {
    final isCredit = transaction['type'] == 'CREDIT';
    final isSuccess = transaction['status'] == 'SUCCESS';

    return Card(
      elevation: 2,
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            // Icon Container
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

            // Transaction Details
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    transaction['title'],
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Colors.black87,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 6,
                          vertical: 2,
                        ),
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
                            color: isSuccess ? Colors.green : Colors.orange,
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        transaction['created_at'],
                        style: const TextStyle(
                          fontSize: 12,
                          color: Colors.black54,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),

            // Amount
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  '${isCredit ? '+' : '-'} ₹${transaction['amount']}',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: isCredit ? Colors.green : Colors.red,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  transaction['type'],
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey.shade600,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.receipt_long_outlined,
              size: 80,
              color: Colors.grey.shade400,
            ),
            const SizedBox(height: 24),
            Text(
              'No Transactions Yet',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: Colors.grey.shade700,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Your transaction history will appear here',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 16,
                color: Colors.grey.shade500,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
