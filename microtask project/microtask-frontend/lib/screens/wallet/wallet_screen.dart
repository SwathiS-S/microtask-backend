import 'package:flutter/material.dart';
import '../../services/user_service.dart';
import '../../services/api_service.dart';
import 'add_money_screen.dart';
import '../wallet/transaction_screen.dart';

class WalletScreen extends StatefulWidget {
  const WalletScreen({super.key});

  @override
  State<WalletScreen> createState() => _WalletScreenState();
}

class _WalletScreenState extends State<WalletScreen> {
  bool _isLoading = false;
  List<dynamic> _transactions = [];

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);
    try {
      final userRes = await ApiService.get('/users/${UserService.userId}');
      if (userRes != null && userRes is Map && userRes['success']) {
        final userData = userRes['user'];
        UserService.setUser(
          walletBalance: (userData['wallet'] ?? 0).toDouble(),
          bankDetails: userData['bankDetails'],
        );
      }

      final txRes = await ApiService.get('/users/${UserService.userId}/transactions');
      if (txRes != null && txRes is Map && txRes['success']) {
        setState(() {
          _transactions = txRes['transactions'];
        });
      }
    } catch (e) {
      debugPrint('Error loading wallet data: $e');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  void _handleCreateWallet() {
    final nameController = TextEditingController(text: UserService.userName);
    final accountController = TextEditingController();
    final ifscController = TextEditingController();
    final upiController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Create Wallet / Connect Bank'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text('Enter your bank details for Razorpay payouts:'),
              const SizedBox(height: 16),
              TextField(
                controller: nameController,
                decoration: const InputDecoration(labelText: 'Account Holder Name'),
              ),
              TextField(
                controller: accountController,
                decoration: const InputDecoration(labelText: 'Bank Account Number'),
              ),
              TextField(
                controller: ifscController,
                decoration: const InputDecoration(labelText: 'IFSC Code'),
              ),
              const Divider(height: 32),
              const Text('OR'),
              TextField(
                controller: upiController,
                decoration: const InputDecoration(labelText: 'UPI ID (Optional)'),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              if (nameController.text.isEmpty || 
                  (accountController.text.isEmpty && upiController.text.isEmpty)) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Please fill necessary details')),
                );
                return;
              }

              Navigator.pop(context);
              setState(() => _isLoading = true);

              try {
                final res = await ApiService.post('/users/wallet', {
                  'userId': UserService.userId,
                  'accountHolderName': nameController.text,
                  'bankAccountNumber': accountController.text,
                  'ifsc': ifscController.text,
                  'upiId': upiController.text,
                });

                if (res['success']) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Wallet connected successfully!')),
                  );
                  _loadData();
                } else {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Failed: ${res['message']}')),
                  );
                }
              } catch (e) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('Error: $e')),
                );
              } finally {
                setState(() => _isLoading = false);
              }
            },
            child: const Text('Connect'),
          ),
        ],
      ),
    );
  }

  void _handleWithdraw() async {
    final amountController = TextEditingController();
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Withdraw Money'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('Enter amount to withdraw to your bank account:'),
            TextField(
              controller: amountController,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(
                prefixText: '₹',
                hintText: '0.00',
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              final amount = double.tryParse(amountController.text);
              if (amount == null || amount <= 0) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Please enter a valid amount')),
                );
                return;
              }
              if (amount > UserService.walletBalance) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Insufficient balance')),
                );
                return;
              }

              Navigator.pop(context);
              setState(() => _isLoading = true);

              try {
                final res = await ApiService.post('/users/withdraw-money', {
                  'userId': UserService.userId,
                  'amount': amount,
                });

                if (res['success']) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text(res['message'])),
                  );
                  _loadData();
                } else {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Withdrawal failed: ${res['message']}')),
                  );
                }
              } catch (e) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('Error: $e')),
                );
              } finally {
                setState(() => _isLoading = false);
              }
            },
            child: const Text('Withdraw'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    String userName = UserService.userName ?? 'User';
    final isProvider = UserService.isTaskProvider;
    final bool isWalletCreated = UserService.bankDetails != null && 
        ((UserService.bankDetails!['bankAccountNumber'] != null && UserService.bankDetails!['bankAccountNumber'] != '') || 
         (UserService.bankDetails!['upiId'] != null && UserService.bankDetails!['upiId'] != ''));

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
                Navigator.pushNamed(context, '/transactions');
              },
            ),
            ListTile(
              leading: const Icon(Icons.account_balance_wallet, color: Color(0xFF1E3A5F)),
              title: const Text('Wallet'),
              onTap: () {
                Navigator.pop(context);
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
          'Wallet',
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
            fontSize: 24,
          ),
        ),
        centerTitle: true,
        actions: isProvider
            ? [
                if (!isWalletCreated)
                  Padding(
                    padding: const EdgeInsets.only(right: 8.0),
                    child: TextButton(
                      onPressed: _handleCreateWallet,
                      child: const Text(
                        'Create Wallet',
                        style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ),
                Padding(
                  padding: const EdgeInsets.only(right: 16.0),
                  child: TextButton(
                    onPressed: () {
                      Navigator.pushNamed(context, '/add-money');
                    },
                    child: const Text(
                      'Add Money',
                      style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),
              ]
            : [],
      ),
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: _loadData,
          child: SingleChildScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            child: Padding(
              padding: const EdgeInsets.all(24.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(32),
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [Color(0xFF1976D2), Color(0xFF1565C0)],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.blue.withOpacity(0.3),
                          blurRadius: 10,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: Column(
                      children: [
                        const Text(
                          'Wallet Balance',
                          style: TextStyle(
                            fontSize: 18,
                            color: Colors.white70,
                          ),
                        ),
                        const SizedBox(height: 12),
                        Text(
                          '₹${UserService.walletBalance.toStringAsFixed(2)}',
                          style: const TextStyle(
                            fontSize: 48,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                        if (!isProvider) ...[
                          const SizedBox(height: 24),
                          if (!isWalletCreated)
                            ElevatedButton(
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.white,
                                foregroundColor: const Color(0xFF1976D2),
                                padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 12),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(8),
                                ),
                              ),
                              onPressed: _handleCreateWallet,
                              child: const Text(
                                'Create Wallet / Connect Bank',
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            )
                          else
                            ElevatedButton(
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.white,
                                foregroundColor: const Color(0xFF1976D2),
                                padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 12),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(8),
                                ),
                              ),
                              onPressed: _handleWithdraw,
                              child: const Text(
                                'Withdraw Money',
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                        ],
                      ],
                    ),
                  ),

                  const SizedBox(height: 32),

                  const Text(
                    'Transaction History',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: Colors.black87,
                    ),
                  ),
                  const SizedBox(height: 16),

                  if (_isLoading)
                    const Center(child: CircularProgressIndicator())
                  else if (_transactions.isEmpty)
                    const Center(child: Text('No transactions yet'))
                  else
                    ..._transactions.map((tx) {
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 12.0),
                        child: _TransactionItem(
                          title: tx['type'] == 'CREDIT' ? 'Funds Added' : (tx['type'] == 'COMMISSION' ? 'Commission' : 'Withdrawal/Payment'),
                          amount: '${tx['type'] == 'CREDIT' || tx['type'] == 'COMMISSION' ? '+' : '-'}₹${tx['amount']}',
                          color: tx['type'] == 'CREDIT' ? Colors.green : (tx['type'] == 'COMMISSION' ? Colors.blue : Colors.red),
                          date: tx['created_at'] != null ? DateTime.parse(tx['created_at'].toString()).toLocal().toString().split(' ')[0] : 'Today',
                        ),
                      );
                    }).toList(),
                ],
              ),
            ),
          ),
        ),
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
