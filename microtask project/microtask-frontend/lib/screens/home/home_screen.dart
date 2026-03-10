import 'package:flutter/material.dart';
import '../../models/task_model.dart';
import '../../services/user_service.dart';
import '../../services/api_service.dart';
import '../wallet/bank_setup_screen.dart';

import '../models/task_model.dart';
import '../screens/create_task_screen.dart';
import '../screens/task_detail_screen.dart';
import '../notifications/notification_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

import '../wallet/fund_task_screen.dart';

class _HomeScreenState extends State<HomeScreen> {
  List<dynamic> _draftTasks = [];
  List<dynamic> _activeTasks = [];
  List<dynamic> _completedTasks = [];
  List<dynamic> _disputedTasks = [];
  List<dynamic> _expiredTasks = [];

  // Earner specific
  List<dynamic> _availableTasks = [];
  List<dynamic> _myApplications = [];
  List<dynamic> _earnerActiveTasks = [];
  List<dynamic> _earnerCompletedTasks = [];
  List<dynamic> _earnerRejectedTasks = [];
  
  List<dynamic> _notifications = [];
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _loadDashboard();
    _loadNotifications();
  }

  Future<void> _loadNotifications() async {
    try {
      final res = await ApiService.get('/notifications/${UserService.userId}');
      if (res != null && res['success']) {
        setState(() {
          _notifications = res['notifications'];
        });
      }
    } catch (e) {
      debugPrint('Error loading notifications: $e');
    }
  }

  Future<void> _loadDashboard() async {
    setState(() => _isLoading = true);
    if (UserService.isTaskProvider) {
      await _loadProviderDashboard();
    } else {
      await _loadEarnerDashboard();
    }
    setState(() => _isLoading = false);
  }

  Future<void> _loadProviderDashboard() async {
    try {
      final res = await ApiService.get('/tasks/provider/${UserService.userId}');
      if (res != null && res['success']) {
        final allTasks = res['tasks'] as List;
        setState(() {
          _draftTasks = allTasks.where((t) => t['status'] == 'draft').toList();
          _activeTasks = allTasks.where((t) => 
            ['funded', 'open', 'assigned', 'in_progress', 'submitted', 'reviewed'].contains(t['status'])
          ).toList();
          _completedTasks = allTasks.where((t) => t['status'] == 'completed').toList();
          _disputedTasks = allTasks.where((t) => ['disputed', 'resolved'].contains(t['status'])).toList();
          _expiredTasks = allTasks.where((t) => t['status'] == 'expired').toList();
        });
      }
    } catch (e) {
      debugPrint('Error loading provider dashboard: $e');
    }
  }

  Future<void> _loadEarnerDashboard() async {
    try {
      final allRes = await ApiService.get('/tasks/all');
      if (allRes != null && allRes is List) {
        // 1. Available Tasks (Funded + Open) - exclude those I applied for
        _availableTasks = allRes.where((t) {
          final isFundedOrOpen = ['funded', 'open'].contains(t['status']);
          final apps = t['applications'] as List? ?? [];
          final alreadyApplied = apps.any((a) => (a['userId'] is Map ? a['userId']['_id'] : a['userId']) == UserService.userId);
          return isFundedOrOpen && !alreadyApplied;
        }).toList();

        // 2. My Applications (Applied + Pending Approval)
        _myApplications = allRes.where((t) {
          final apps = t['applications'] as List? ?? [];
          final myApp = apps.firstWhere(
            (a) => (a['userId'] is Map ? a['userId']['_id'] : a['userId']) == UserService.userId,
            orElse: () => null
          );
          return myApp != null && myApp['state'] == 'APPLIED' && t['status'] == 'open';
        }).toList();

        // 3. Active Tasks (Approved + Working)
        _earnerActiveTasks = allRes.where((t) {
          return (t['acceptedBy'] is Map ? t['acceptedBy']['_id'] : t['acceptedBy']) == UserService.userId &&
                 ['assigned', 'in_progress', 'submitted', 'reviewed', 'disputed'].contains(t['status']);
        }).toList();

        // 4. Completed Tasks
        _earnerCompletedTasks = allRes.where((t) {
          return (t['acceptedBy'] is Map ? t['acceptedBy']['_id'] : t['acceptedBy']) == UserService.userId &&
                 t['status'] == 'completed';
        }).toList();

        // 5. Rejected Applications
        _earnerRejectedTasks = allRes.where((t) {
          final apps = t['applications'] as List? ?? [];
          final myApp = apps.firstWhere(
            (a) => (a['userId'] is Map ? a['userId']['_id'] : a['userId']) == UserService.userId,
            orElse: () => null
          );
          return myApp != null && myApp['state'] == 'REJECTED';
        }).toList();
      }
    } catch (e) {
      debugPrint('Error loading earner dashboard: $e');
    }
  }

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
          Stack(
            children: [
              IconButton(
                icon: const Icon(Icons.notifications_outlined, color: Colors.white),
                onPressed: () async {
                  await Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => const NotificationScreen()),
                  );
                  _loadNotifications();
                },
              ),
              if (_notifications.any((n) => !n['isRead']))
                Positioned(
                  right: 12,
                  top: 12,
                  child: Container(
                    padding: const EdgeInsets.all(2),
                    decoration: BoxDecoration(
                      color: Colors.red,
                      borderRadius: BorderRadius.circular(6),
                    ),
                    constraints: const BoxConstraints(
                      minWidth: 12,
                      minHeight: 12,
                    ),
                  ),
                ),
            ],
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
                        onPressed: () async {
                          try {
                            final bankRes = await ApiService.get('/bank/details/${UserService.userId}');
                            if (bankRes != null && bankRes['success']) {
                              final result = await Navigator.pushNamed(context, '/create-task');
                              if (result == true) {
                                _loadProviderDashboard();
                              }
                            } else {
                              _showBankSetupDialog(andThen: () => Navigator.pushNamed(context, '/create-task'));
                            }
                          } catch (e) {
                            _showBankSetupDialog(andThen: () => Navigator.pushNamed(context, '/create-task'));
                          }
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

              // 🔹 PROVIDER DASHBOARD SECTIONS
              if (isTaskProvider) ...[
                if (_isLoading)
                  const Center(child: CircularProgressIndicator())
                else ...[
                  _buildProviderSection('Draft Tasks (Unfunded)', _draftTasks, (task) => _buildDraftAction(task)),
                  _buildProviderSection('Active Tasks', _activeTasks, (task) => _buildActiveAction(task)),
                  _buildProviderSection('Completed Tasks', _completedTasks, (task) => _buildCompletedAction(task)),
                  _buildProviderSection('Disputed Tasks', _disputedTasks, (task) => _buildDisputedAction(task)),
                  _buildProviderSection('Expired Tasks', _expiredTasks, (task) => _buildExpiredAction(task)),
                ],
              ],

              // 🔹 EARNER DASHBOARD SECTIONS
              if (!isTaskProvider) ...[
                if (_isLoading)
                  const Center(child: CircularProgressIndicator())
                else ...[
                  _buildProviderSection('Available Tasks', _availableTasks, (task) => _buildAvailableAction(task)),
                  _buildProviderSection('My Applications', _myApplications, (task) => _buildApplicationAction(task)),
                  _buildProviderSection('Active Work', _earnerActiveTasks, (task) => _buildEarnerActiveAction(task)),
                  _buildProviderSection('Completed Work', _earnerCompletedTasks, (task) => _buildEarnerCompletedAction(task)),
                  _buildProviderSection('Rejected Applications', _earnerRejectedTasks, (task) => _buildRejectedAction(task)),
                ],
              ],
              const SizedBox(height: 24),

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
                    onTap: () => Navigator.pushNamed(context, '/transactions'),
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
                  return _buildTransactionItem(transaction);
                },
              ),
              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }

  void _showBankSetupDialog({VoidCallback? andThen}) {
    if (mounted) {
      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('Bank Account Required'),
          content: const Text('Please connect your bank account first to create tasks.'),
          actions: [
            TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
            ElevatedButton(
              onPressed: () async {
                Navigator.pop(context);
                final result = await Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => const BankSetupScreen(role: 'provider')),
                );
                if (result == true && andThen != null) {
                  andThen();
                }
              },
              child: const Text('Connect Now'),
            ),
          ],
        ),
      );
    }
  }

  Widget _buildProviderSection(String title, List<dynamic> tasks, Widget Function(dynamic) actionBuilder) {
    if (tasks.isEmpty) return const SizedBox();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.black87),
        ),
        const SizedBox(height: 12),
        SizedBox(
          height: 170,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            itemCount: tasks.length,
            itemBuilder: (context, index) {
              final task = tasks[index];
              return Container(
                width: 280,
                margin: const EdgeInsets.only(right: 16, bottom: 8),
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10)],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Expanded(
                          child: Text(
                            task['title'],
                            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        _buildStatusBadge(task['status']),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Budget: ₹${task['amount']}',
                      style: const TextStyle(color: Colors.blueGrey, fontWeight: FontWeight.w600),
                    ),
                    const Spacer(),
                    actionBuilder(task),
                  ],
                ),
              );
            },
          ),
        ),
        const SizedBox(height: 24),
      ],
    );
  }

  Widget _buildStatusBadge(String status) {
    Color color;
    switch (status) {
      case 'draft': color = Colors.grey; break;
      case 'open': color = Colors.blue; break;
      case 'assigned': color = Colors.teal; break;
      case 'in_progress': color = Colors.orange; break;
      case 'submitted': color = Colors.purple; break;
      case 'reviewed': color = Colors.cyan; break;
      case 'completed': color = Colors.green; break;
      case 'disputed': color = Colors.red; break;
      case 'expired': color = Colors.black; break;
      default: color = Colors.blueGrey;
    }
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(color: color.withOpacity(0.1), borderRadius: BorderRadius.circular(8)),
      child: Text(status.toUpperCase(), style: TextStyle(color: color, fontSize: 10, fontWeight: FontWeight.bold)),
    );
  }

  Widget _buildDraftAction(dynamic task) {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton(
        onPressed: () async {
          final funded = await Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => FundTaskScreen(task: task)),
          );
          if (funded == true) _loadProviderDashboard();
        },
        style: ElevatedButton.styleFrom(backgroundColor: Colors.blue, foregroundColor: Colors.white),
        child: const Text('Fund Task'),
      ),
    );
  }

  Widget _buildActiveAction(dynamic task) {
    String label = 'View Details';
    IconData icon = Icons.visibility;
    
    switch (task['status']) {
      case 'open': label = 'View Applicants'; icon = Icons.people; break;
      case 'in_progress': label = 'View Updates'; icon = Icons.update; break;
      case 'submitted': label = 'View Final Work'; icon = Icons.task; break;
      case 'reviewed': label = 'Approve/Dispute'; icon = Icons.gavel; break;
    }

    return SizedBox(
      width: double.infinity,
      child: ElevatedButton.icon(
        onPressed: () async {
          final result = await Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => TaskDetailScreen(task: Task.fromJson(task))),
          );
          if (result == true) {
            _loadProviderDashboard();
          }
        },
        icon: Icon(icon, size: 16),
        label: Text(label),
        style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF1E3A5F), foregroundColor: Colors.white),
      ),
    );
  }

  Widget _buildCompletedAction(dynamic task) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        const Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Paid On', style: TextStyle(fontSize: 10, color: Colors.grey)),
            Text('Today', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.green)),
          ],
        ),
        Text('₹${task['amount']}', style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.green, fontSize: 18)),
      ],
    );
  }

  Widget _buildDisputedAction(dynamic task) {
    return Column(
      children: [
        Text(
          task['status'] == 'resolved' ? '✅ Resolved by Admin' : '⚠️ Under Admin Review',
          style: TextStyle(color: task['status'] == 'resolved' ? Colors.green : Colors.red, fontSize: 12, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 8),
        SizedBox(
          width: double.infinity,
          height: 30,
          child: OutlinedButton(
            onPressed: () async {
              final result = await Navigator.push(context, MaterialPageRoute(builder: (context) => TaskDetailScreen(task: Task.fromJson(task))));
              if (result == true) _loadProviderDashboard();
            },
            child: const Text('View Case', style: TextStyle(fontSize: 12)),
          ),
        ),
      ],
    );
  }

  Widget _buildExpiredAction(dynamic task) {
    return Row(
      children: [
        const Expanded(
          child: Text('Escrow Refunded ✅', style: TextStyle(color: Colors.blueGrey, fontSize: 12, fontWeight: FontWeight.bold)),
        ),
        ElevatedButton(
          onPressed: () {
            // Repost logic (clone task)
            Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => CreateTaskScreen(taskToClone: task)),
            );
          },
          style: ElevatedButton.styleFrom(backgroundColor: Colors.orange, foregroundColor: Colors.white, padding: const EdgeInsets.symmetric(horizontal: 12)),
          child: const Text('Repost', style: TextStyle(fontSize: 12)),
        ),
      ],
    );
  }

  Widget _buildRejectedAction(dynamic task) {
    return Row(
      children: [
        const Expanded(
          child: Text('Application Rejected', style: TextStyle(color: Colors.red, fontSize: 12, fontWeight: FontWeight.bold)),
        ),
        ElevatedButton(
          onPressed: () => Navigator.pushNamed(context, '/tasks'),
          style: ElevatedButton.styleFrom(backgroundColor: Colors.blue, foregroundColor: Colors.white, padding: const EdgeInsets.symmetric(horizontal: 12)),
          child: const Text('Find New', style: TextStyle(fontSize: 12)),
        ),
      ],
    );
  }

  Widget _buildAvailableAction(dynamic task) {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton(
        onPressed: () async {
          final result = await Navigator.push(context, MaterialPageRoute(builder: (context) => TaskDetailScreen(task: Task.fromJson(task))));
          if (result == true) _loadEarnerDashboard();
        },
        style: ElevatedButton.styleFrom(backgroundColor: Colors.blue, foregroundColor: Colors.white),
        child: const Text('Apply Now'),
      ),
    );
  }

  Widget _buildApplicationAction(dynamic task) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 8),
      decoration: BoxDecoration(color: Colors.orange.withOpacity(0.1), borderRadius: BorderRadius.circular(8)),
      child: const Center(
        child: Text('Waiting for approval...', style: TextStyle(color: Colors.orange, fontWeight: FontWeight.bold, fontSize: 12)),
      ),
    );
  }

  Widget _buildEarnerActiveAction(dynamic task) {
    String label = 'View Details';
    if (task['status'] == 'assigned') label = 'Start Task';
    else if (task['status'] == 'in_progress') label = 'Submit Work';
    else if (task['status'] == 'submitted') label = 'Work Submitted ✅';
    else if (task['status'] == 'reviewed') label = 'Under Review ⏳';

    return SizedBox(
      width: double.infinity,
      child: ElevatedButton(
        onPressed: () async {
          final result = await Navigator.push(context, MaterialPageRoute(builder: (context) => TaskDetailScreen(task: Task.fromJson(task))));
          if (result == true) _loadEarnerDashboard();
        },
        style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF1E3A5F), foregroundColor: Colors.white),
        child: Text(label),
      ),
    );
  }

  Widget _buildEarnerCompletedAction(dynamic task) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Received', style: TextStyle(fontSize: 10, color: Colors.grey)),
            Text('₹${task['amount']}', style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.green, fontSize: 16)),
          ],
        ),
        ElevatedButton(
          onPressed: () => Navigator.pushNamed(context, '/wallet'),
          style: ElevatedButton.styleFrom(backgroundColor: Colors.green, foregroundColor: Colors.white, padding: const EdgeInsets.symmetric(horizontal: 12)),
          child: const Text('Withdraw', style: TextStyle(fontSize: 12)),
        ),
      ],
    );
  }

  Widget _buildRecentTaskItem(Task task) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 8)],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(task.title, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: Colors.black87)),
                const SizedBox(height: 6),
                Text('Posted by ${task.createdBy}', style: const TextStyle(fontSize: 13, color: Colors.black54)),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text('₹${task.amount}', style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Color(0xFF1E3A5F))),
              const SizedBox(height: 8),
              SizedBox(
                height: 28,
                child: ElevatedButton(
                  onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (context) => TaskDetailScreen(task: task))),
                  style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF1E3A5F), foregroundColor: Colors.white, padding: const EdgeInsets.symmetric(horizontal: 10), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)), elevation: 0),
                  child: const Text('Details', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600)),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

  Widget _buildTransactionItem(Map<String, dynamic> transaction) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 8)],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(color: (transaction['color'] as Color).withOpacity(0.1), borderRadius: BorderRadius.circular(8)),
                child: Icon(transaction['icon'] as IconData, color: transaction['color'] as Color, size: 24),
              ),
              const SizedBox(width: 12),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(transaction['title'] as String, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600, color: Colors.black87)),
                  const SizedBox(height: 4),
                  Text('Posted by ${transaction['posted_by']}', style: const TextStyle(fontSize: 13, color: Colors.black54)),
                ],
              ),
            ],
          ),
          Text(transaction['amount'] as String, style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: transaction['color'] as Color)),
        ],
      ),
    );
  }
            ],
          ),
        ),
      ),
    );
  }
}
