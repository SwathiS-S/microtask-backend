import 'package:flutter/material.dart';
import '../../models/task_model.dart';
import '../../services/user_service.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  // Mock recent tasks
  final List<Task> recentTasks = [
    Task(
      id: '1',
      title: 'Design a Logo',
      description: 'Design a modern logo',
      amount: 1500,
      createdBy: 'Sarah',
      status: TaskStatus.open,
      createdAt: DateTime.now().subtract(const Duration(hours: 2)),
    ),
    Task(
      id: '2',
      title: 'Fix a WordPress Site',
      description: 'Fix bugs and optimize',
      amount: 800,
      createdBy: 'Mike',
      status: TaskStatus.open,
      createdAt: DateTime.now().subtract(const Duration(days: 1)),
    ),
  ];

  // Mock transactions
  final List<Map<String, dynamic>> transactions = [
    {
      'type': 'income',
      'title': 'Added Funds',
      'posted_by': 'You',
      'amount': '+₹2,000',
      'color': Colors.green,
      'icon': Icons.add_circle,
    },
    {
      'type': 'expense',
      'title': 'Task Payment',
      'posted_by': 'Rasad',
      'amount': '-₹500',
      'color': Colors.red,
      'icon': Icons.remove_circle,
    },
    {
      'type': 'income',
      'title': 'Deposit',
      'posted_by': 'David',
      'amount': '+₹1,000',
      'color': Colors.orange,
      'icon': Icons.arrow_circle_down,
    },
  ];

  @override
  Widget build(BuildContext context) {
    String userName = UserService.userName ?? 'User';
    double walletBalance = UserService.walletBalance;
    bool isTaskProvider = UserService.isTaskProvider;

    return Scaffold(
      backgroundColor: const Color(0xFFF5F6FA),
      
      // 🔹 DRAWER
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
            // Home
            ListTile(
              leading: const Icon(Icons.home, color: Color(0xFF1E3A5F)),
              title: const Text('Home'),
              onTap: () {
                Navigator.pop(context);
                // Already on home; no navigation needed
              },
            ),
            // Tasks
            ListTile(
              leading: const Icon(Icons.task_alt, color: Color(0xFF1E3A5F)),
              title: const Text('Tasks'),
              onTap: () {
                Navigator.pop(context);
                Navigator.pushNamed(context, '/tasks');
              },
            ),
            // Transactions
            ListTile(
              leading: const Icon(Icons.receipt_long, color: Color(0xFF1E3A5F)),
              title: const Text('Transactions'),
              onTap: () {
                Navigator.pop(context);
                Navigator.pushNamed(context, '/transactions');
              },
            ),
            // Wallet
            ListTile(
              leading: const Icon(Icons.account_balance_wallet, color: Color(0xFF1E3A5F)),
              title: const Text('Wallet'),
              onTap: () {
                Navigator.pop(context);
                Navigator.pushNamed(context, '/wallet');
              },
            ),
            // Profile
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
      
      // 🔹 APP BAR - Dark blue header matching template
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
          'TaskNest',
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
            fontSize: 24,
          ),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.notifications_outlined, color: Colors.white),
            onPressed: () {},
          ),
          IconButton(
            icon: const Icon(Icons.settings_outlined, color: Colors.white),
            onPressed: () {},
          ),
          Padding(
            padding: const EdgeInsets.only(right: 8.0),
            child: CircleAvatar(
              radius: 16,
              backgroundColor: Colors.white.withOpacity(0.2),
              child: Text(
                userName.isNotEmpty ? userName[0].toUpperCase() : 'U',
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 14,
                ),
              ),
            ),
          ),
        ],
      ),

      // 🔹 BODY
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // 🔹 WELCOME CARD - Light blue matching template
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: const Color(0xFF64B5F6), // Light blue matching template
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.1),
                      blurRadius: 10,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Welcome, $userName!',
                      style: const TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(height: 20),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Wallet Balance',
                              style: TextStyle(
                                fontSize: 14,
                                color: Colors.white70,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              '₹${walletBalance.toStringAsFixed(0)}',
                              style: const TextStyle(
                                fontSize: 32,
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                              ),
                            ),
                          ],
                        ),
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.2),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: const Icon(
                            Icons.wallet,
                            color: Colors.white,
                            size: 40,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),

              // 🔹 ACTION BUTTONS - Matching image design
              // Only show "Create Task" for Business Leads (taskProvider)
              if (isTaskProvider)
                Row(
                  children: [
                    Expanded(
                      child: ElevatedButton.icon(
                        icon: const Icon(Icons.add, size: 20),
                        label: const Text('Create Task'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.orange,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                          elevation: 2,
                        ),
                        onPressed: () {
                          Navigator.pushNamed(context, '/create-task');
                        },
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: ElevatedButton.icon(
                        icon: const Icon(Icons.visibility, size: 20),
                        label: const Text('View Tasks'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF1976D2),
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                          elevation: 2,
                        ),
                        onPressed: () {
                          Navigator.pushNamed(context, '/tasks');
                        },
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: ElevatedButton.icon(
                        icon: const Icon(Icons.account_balance_wallet, size: 20),
                        label: const Text('Add Money'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF1976D2),
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                          elevation: 2,
                        ),
                        onPressed: () {
                          Navigator.pushNamed(context, '/add-money');
                        },
                      ),
                    ),
                  ],
                )
              else
                // For regular users, only show View Tasks (no Add Money)
                Row(
                  children: [
                    Expanded(
                      child: ElevatedButton.icon(
                        icon: const Icon(Icons.visibility, size: 20),
                        label: const Text('View Tasks'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF1976D2),
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                          elevation: 2,
                        ),
                        onPressed: () {
                          Navigator.pushNamed(context, '/tasks');
                        },
                      ),
                    ),
                  ],
                ),
              const SizedBox(height: 28),

              // 🔹 RECENT TASKS SECTION
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Recent Tasks',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: Colors.black87,
                    ),
                  ),
                  GestureDetector(
                    onTap: () {
                      Navigator.pushNamed(context, '/tasks');
                    },
                    child: const Text(
                      'View all',
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.blue,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              ListView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: recentTasks.length,
                itemBuilder: (context, index) {
                  final task = recentTasks[index];
                  return Container(
                    margin: const EdgeInsets.only(bottom: 12),
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
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                task.title,
                                style: const TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w600,
                                  color: Colors.black87,
                                ),
                              ),
                              const SizedBox(height: 6),
                              Text(
                                'Posted by ${task.createdBy}',
                                style: const TextStyle(
                                  fontSize: 13,
                                  color: Colors.black54,
                                ),
                              ),
                            ],
                          ),
                        ),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            Text(
                              '₹${task.amount}',
                              style: const TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                color: Color(0xFF1E3A5F),
                              ),
                            ),
                            const SizedBox(height: 8),
                            SizedBox(
                              height: 28,
                              child: ElevatedButton(
                                onPressed: () {
                                  Navigator.pushNamed(context, '/tasks');
                                },
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: const Color(0xFF1E3A5F),
                                  foregroundColor: Colors.white,
                                  padding: const EdgeInsets.symmetric(horizontal: 10),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(6),
                                  ),
                                  elevation: 0,
                                ),
                                child: const Text(
                                  'Details',
                                  style: TextStyle(
                                    fontSize: 11,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  );
                },
              ),
              const SizedBox(height: 28),

              // 🔹 LATEST TRANSACTIONS SECTION
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Latest Transactions',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: Colors.black87,
                    ),
                  ),
                  GestureDetector(
                    onTap: () {
                      Navigator.pushNamed(context, '/transactions');
                    },
                    child: const Text(
                      'View all',
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.blue,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              ListView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: transactions.length,
                itemBuilder: (context, index) {
                  final transaction = transactions[index];
                  return Container(
                    margin: const EdgeInsets.only(bottom: 12),
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
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: (transaction['color'] as Color)
                                    .withOpacity(0.1),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Icon(
                                transaction['icon'] as IconData,
                                color: transaction['color'] as Color,
                                size: 24,
                              ),
                            ),
                            const SizedBox(width: 12),
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  transaction['title'] as String,
                                  style: const TextStyle(
                                    fontSize: 15,
                                    fontWeight: FontWeight.w600,
                                    color: Colors.black87,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  'Posted by ${transaction['posted_by']}',
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
                          transaction['amount'] as String,
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: transaction['color'] as Color,
                          ),
                        ),
                      ],
                    ),
                  );
                },
              ),
              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }
}
