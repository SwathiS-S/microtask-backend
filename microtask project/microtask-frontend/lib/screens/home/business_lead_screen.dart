import 'package:flutter/material.dart';
import 'package:razorpay_flutter/razorpay_flutter.dart';
import '../../models/task_model.dart';
import '../../services/user_service.dart';
import '../../services/api_service.dart';
import '../auth/login_screen.dart';
import '../../widgets/top_actions.dart';
import '../tasks/create_task_screen.dart';
import '../tasks/task_detail_screen.dart';
import '../tasks/submissions_screen.dart';

class BusinessLeadScreen extends StatefulWidget {
  const BusinessLeadScreen({super.key});

  @override
  State<BusinessLeadScreen> createState() => _BusinessLeadScreenState();
}

class _BusinessLeadScreenState extends State<BusinessLeadScreen> {
  late Razorpay _razorpay;
  String? _currentTaskId;

  List<Task> pendingReviews = [];
  List<Task> activeTasks = [];
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    _fetchTasks();
    _razorpay = Razorpay();
    _razorpay.on(Razorpay.EVENT_PAYMENT_SUCCESS, _handlePaymentSuccess);
    _razorpay.on(Razorpay.EVENT_PAYMENT_ERROR, _handlePaymentError);
    _razorpay.on(Razorpay.EVENT_EXTERNAL_WALLET, _handleExternalWallet);
  }

  Future<void> _fetchTasks() async {
    setState(() => isLoading = true);
    try {
      final res = await ApiService.get('/tasks/all');
      if (res != null && res is List) {
        final allTasks = res.map((json) => Task.fromJson(json)).toList();
        setState(() {
          // Pending reviews are tasks submitted but not yet approved/paid
          pendingReviews = allTasks.where((t) => 
            t.createdBy == UserService.userId && 
            (t.status == TaskStatus.submitted || (t.workType == WorkType.onsite && t.status == TaskStatus.assigned))
          ).toList();
          
          // Active tasks are open tasks posted by this user
          activeTasks = allTasks.where((t) => 
            t.createdBy == UserService.userId && 
            t.status == TaskStatus.open
          ).toList();
        });
      }
    } catch (e) {
      debugPrint('Fetch error: $e');
    } finally {
      setState(() => isLoading = false);
    }
  }

  // Track approved tasks
  Set<String> approvedTaskIds = {};

  @override
  Widget build(BuildContext context) {
    final stats = _calculateStats();
    String userName = UserService.userName ?? 'Task Provider';

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
          'TaskNest - Task Provider',
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
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Welcome Section - Matching professional design
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [Color(0xFF7B1FA2), Color(0xFF6A1B9A)], // Purple gradient
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.purple.withOpacity(0.3),
                        blurRadius: 10,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Welcome, ${UserService.userName ?? 'Task Provider'}!',
                        style: const TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Manage tasks and review submissions',
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.white.withOpacity(0.9),
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 32),

                // Quick Actions
                const Text(
                  'Quick Actions',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: Colors.black87,
                  ),
                ),
                const SizedBox(height: 16),

                Row(
                  children: [
                    Expanded(
                      child: _buildActionCard(
                        icon: Icons.add_circle,
                        title: 'Create Task',
                        subtitle: 'Post a new task',
                        color: Colors.blue,
                        onTap: () {
                          // Navigate to create task screen
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => const CreateTaskScreen(),
                            ),
                          );
                        },
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: _buildActionCard(
                        icon: Icons.check_circle,
                        title: 'Review Submissions',
                        subtitle: '${pendingReviews.length} pending',
                        color: Colors.orange,
                        onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => SubmissionsScreen(submissions: pendingReviews),
                              ),
                            );
                          },
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 32),

                // Statistics Section
                const Text(
                  'Your Statistics',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: Colors.black87,
                  ),
                ),
                const SizedBox(height: 16),

                Row(
                  children: [
                    Expanded(
                      child: _buildStatCard(
                        icon: Icons.assignment,
                        value: stats['totalTasks'].toString(),
                        label: 'Total Tasks',
                        color: Colors.blue,
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: _buildStatCard(
                        icon: Icons.check_circle,
                        value: stats['activeTasks'].toString(),
                        label: 'Active',
                        color: Colors.green,
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: _buildStatCard(
                        icon: Icons.hourglass_top,
                        value: stats['pendingReview'].toString(),
                        label: 'Pending Review',
                        color: Colors.orange,
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: _buildStatCard(
                        icon: Icons.account_balance_wallet,
                        value: '\₹${stats['totalBudget']}',
                        label: 'Total Budget',
                        color: Colors.deepPurple,
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 32),

                // Pending Reviews Section
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'Pending Reviews',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: Colors.black87,
                      ),
                    ),
                    TextButton(
                      onPressed: () {},
                      child: const Text('View all'),
                    ),
                  ],
                ),
                const SizedBox(height: 16),

                if (pendingReviews.isEmpty)
                  Center(
                    child: Padding(
                      padding: const EdgeInsets.all(24),
                      child: Column(
                        children: [
                          Icon(
                            Icons.check_circle,
                            size: 48,
                            color: Colors.green[300],
                          ),
                          const SizedBox(height: 16),
                          const Text(
                            'No pending reviews',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                              color: Colors.black54,
                            ),
                          ),
                        ],
                      ),
                    ),
                  )
                else
                  Column(
                    children: pendingReviews.map((task) {
                      return _buildSubmissionCard(task);
                    }).toList(),
                  ),

                const SizedBox(height: 32),

                // Active Tasks Section
                const Text(
                  'Active Tasks',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: Colors.black87,
                  ),
                ),
                const SizedBox(height: 16),

                Column(
                  children: activeTasks.map((task) {
                    return _buildTaskCard(task);
                  }).toList(),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildActionCard({
    required IconData icon,
    required String title,
    required String subtitle,
    required Color color,
    required VoidCallback onTap,
  }) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(
                  icon,
                  color: color,
                  size: 32,
                ),
              ),
              const SizedBox(height: 16),
              Text(
                title,
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Colors.black87,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                subtitle,
                style: const TextStyle(
                  fontSize: 14,
                  color: Colors.black54,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStatCard({
    required IconData icon,
    required String value,
    required String label,
    required Color color,
  }) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: color.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(icon, color: color, size: 24),
            ),
            const SizedBox(height: 12),
            Text(
              value,
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              label,
              style: const TextStyle(
                fontSize: 12,
                color: Colors.black54,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSubmissionCard(Task task) {
    bool isApproved = approvedTaskIds.contains(task.id) || task.status == TaskStatus.completed;

    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => TaskDetailScreen(task: task),
          ),
        );
      },
      child: Card(
        elevation: 2,
        margin: const EdgeInsets.only(bottom: 16),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          task.title,
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: Colors.black87,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Row(
                          children: [
                            Icon(
                              task.workType == WorkType.wfh ? Icons.home : Icons.location_on,
                              size: 14,
                              color: Colors.blueGrey,
                            ),
                            const SizedBox(width: 4),
                            Text(
                              task.workType == WorkType.wfh ? 'WFH' : 'Onsite',
                              style: const TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w500,
                                color: Colors.blueGrey,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: task.statusColor.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                        color: task.statusColor,
                      ),
                    ),
                    child: Text(
                      task.statusDisplay,
                      style: TextStyle(
                        color: task.statusColor,
                        fontWeight: FontWeight.w600,
                        fontSize: 12,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              if (task.finalFileUrl != null)
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.grey.shade100,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.file_present, color: Colors.blueGrey),
                      const SizedBox(width: 8),
                      const Expanded(
                        child: Text(
                          'Final work submitted',
                          style: TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
                        ),
                      ),
                      TextButton(
                        onPressed: () {
                          // TODO: Open file URL
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(content: Text('File path: ${task.finalFileUrl}')),
                          );
                        },
                        child: const Text('View File'),
                      ),
                    ],
                  ),
                ),
              const SizedBox(height: 16),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Reward: ₹${task.amount}',
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Colors.deepPurple,
                    ),
                  ),
                  Row(
                    children: [
                      SizedBox(
                        height: 36,
                        child: ElevatedButton.icon(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: isApproved
                                ? Colors.grey.shade500
                                : Colors.green.shade400,
                            foregroundColor: Colors.white,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                            elevation: 0,
                          ),
                          onPressed: isApproved
                              ? null
                              : () async {
                                  try {
                                    // Check if WFH has final file
                                    if (task.workType == WorkType.wfh && task.finalFileUrl == null) {
                                      ScaffoldMessenger.of(context).showSnackBar(
                                        const SnackBar(content: Text('Waiting for user to upload final work.')),
                                      );
                                      return;
                                    }

                                    final res = await ApiService.post('/tasks/approve', {
                                      'taskId': task.id,
                                      'approvedBy': UserService.userId,
                                    });

                                    if (res['success']) {
                                      _startPayment(res['order'], task.amount, task.id);
                                    } else {
                                      ScaffoldMessenger.of(context).showSnackBar(
                                        SnackBar(content: Text('Failed: ${res['message']}')),
                                      );
                                    }
                                  } catch (e) {
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      SnackBar(content: Text('Error: $e')),
                                    );
                                  }
                                },
                          icon: Icon(
                              isApproved ? Icons.check_circle : Icons.check,
                              size: 16),
                          label: Text(isApproved ? 'Approved' : 'Approve & Pay'),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTaskCard(Task task) {
    return Card(
      elevation: 2,
      margin: const EdgeInsets.only(bottom: 16),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: Padding(
        padding: const EdgeInsets.all(20),
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
                      fontWeight: FontWeight.bold,
                      color: Colors.black87,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    task.description,
                    style: const TextStyle(
                      fontSize: 12,
                      color: Colors.black54,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    '₹${task.amount}',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      color: Colors.deepPurple,
                    ),
                  ),
                ],
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: task.statusColor.withOpacity(0.1),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: task.statusColor),
              ),
              child: Text(
                task.statusDisplay,
                style: TextStyle(
                  color: task.statusColor,
                  fontWeight: FontWeight.w600,
                  fontSize: 12,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  void dispose() {
    _razorpay.clear();
    super.dispose();
  }

  void _handlePaymentSuccess(PaymentSuccessResponse response) async {
    if (_currentTaskId == null) return;
    
    try {
      final res = await ApiService.post('/payments/razorpay/verify-task-payment', {
        'razorpay_order_id': response.orderId,
        'razorpay_payment_id': response.paymentId,
        'razorpay_signature': response.signature,
        'taskId': _currentTaskId,
      });

      if (res['success']) {
        setState(() {
          approvedTaskIds.add(_currentTaskId!);
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Payment successful! ₹${res['userEarnings']} added to worker wallet.')),
        );
        _fetchTasks();
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Verification failed: ${res['message']}')),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $e')),
      );
    }
  }

  void _handlePaymentError(PaymentFailureResponse response) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Payment failed: ${response.message}')),
    );
  }

  void _handleExternalWallet(ExternalWalletResponse response) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('External wallet selected: ${response.walletName}')),
    );
  }

  void _startPayment(Map order, int amount, String taskId) {
    _currentTaskId = taskId;
    var options = {
      'key': 'rzp_live_STnxXSruVLrlO2', 
      'amount': amount * 100,
      'name': 'TaskNest',
      'order_id': order['id'],
      'description': 'Task Payment',
      'timeout': 300,
      'prefill': {
        'contact': UserService.userPhone ?? '',
        'email': UserService.userEmail ?? '',
      }
    };

    try {
      _razorpay.open(options);
    } catch (e) {
      debugPrint('Error: $e');
    }
  }

  Map<String, int> _calculateStats() {
    final numActiveTasks = activeTasks.length;
    final numPendingReview = pendingReviews.length;
    final totalTasks = numPendingReview + numActiveTasks;
    final totalBudget = [...pendingReviews, ...activeTasks]
        .fold<int>(0, (sum, task) => sum + task.amount);

    return {
      'totalTasks': totalTasks,
      'activeTasks': numActiveTasks,
      'pendingReview': numPendingReview,
      'totalBudget': totalBudget,
    };
  }
}
