import 'package:flutter/material.dart';
import '../../services/user_service.dart';
import '../../services/api_service.dart';
import '../../widgets/top_actions.dart';
import 'task_detail_screen.dart';

class TaskListScreen extends StatefulWidget {
  const TaskListScreen({super.key});

  @override
  State<TaskListScreen> createState() => _TaskListScreenState();
}

class _TaskListScreenState extends State<TaskListScreen> {
  List<Map<String, dynamic>> _filteredTasks = [];
  List<Map<String, dynamic>> _allTasks = [];
  String? _selectedSkill;
  List<String> _skills = [];
  bool _loading = false;

  @override
  void initState() {
    super.initState();
    _loadTasks();
  }

  @override
  void dispose() {
    super.dispose();
  }

  Future<void> _loadTasks() async {
    setState(() {
      _loading = true;
    });
    try {
      final data = await ApiService.get('/tasks/all');
      final tasks = (data as List).where((t) => t['status'] != 'draft').map<Map<String, dynamic>>((t) {
        final postedBy = t['postedBy'];
        return {
          'id': t['_id'] ?? t['id'],
          'title': t['title'] ?? '',
          'description': t['description'] ?? '',
          'amount': t['amount'] ?? 0,
          'postedBy': postedBy is Map ? (postedBy['name'] ?? 'Task Provider') : 'Task Provider',
          'skillset': t['skillset'] ?? '',
          'location': t['location'] ?? '',
          'workType': t['workType'] ?? '',
          'status': t['status'] ?? 'open',
          'acceptedBy': t['acceptedBy'] is Map ? (t['acceptedBy']['_id'] ?? t['acceptedBy']) : (t['acceptedBy'] ?? ''),
          'raw': t,
        };
      }).toList();
      final skills = <String>{};
      for (final task in tasks) {
        final s = (task['skillset'] ?? '').toString().trim();
        if (s.isNotEmpty) skills.add(s);
      }
      setState(() {
        _allTasks = tasks;
        _skills = skills.toList()..sort();
        _filteredTasks = tasks;
        _loading = false;
      });
    } catch (e) {
      setState(() {
        _loading = false;
        _filteredTasks = _allTasks;
      });
    }
  }

  void _filterTasks() {
    setState(() {
      _filteredTasks = _allTasks.where((task) {
        final matchesSkill = _selectedSkill == null || _selectedSkill!.isEmpty
            ? true
            : task['skillset'].toString().toLowerCase() ==
                _selectedSkill!.toLowerCase();
        return matchesSkill;
      }).toList();
    });
  }

  @override
  Widget build(BuildContext context) {
    String userName = UserService.userName ?? 'User';

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
            // Home
            ListTile(
              leading: const Icon(Icons.home, color: Color(0xFF1E3A5F)),
              title: const Text('Home'),
              onTap: () {
                Navigator.pop(context);
                Navigator.pushNamed(context, '/home');
              },
            ),
            // Tasks
            ListTile(
              leading: const Icon(Icons.task_alt, color: Color(0xFF1E3A5F)),
              title: const Text('Tasks'),
              onTap: () {
                Navigator.pop(context);
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
      appBar: AppBar(
        backgroundColor: const Color(0xFF1E3A5F),
        elevation: 0,
        leading: Builder(
          builder: (context) => IconButton(
            icon: const Icon(Icons.arrow_back, color: Colors.white),
            onPressed: () => Navigator.pop(context),
          ),
        ),
        title: const Text(
          'Tasks',
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
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
              child: Row(
                children: [
                  Expanded(
                    child: DropdownButtonFormField<String>(
                      value: _selectedSkill?.isEmpty == true ? null : _selectedSkill,
                      items: [
                        const DropdownMenuItem<String>(
                          value: '',
                          child: Text('All skills'),
                        ),
                        ..._skills.map(
                          (s) => DropdownMenuItem<String>(
                            value: s,
                            child: Text(s),
                          ),
                        ),
                      ],
                      onChanged: (val) {
                        setState(() {
                          _selectedSkill = val == '' ? null : val;
                        });
                        _filterTasks();
                      },
                      decoration: InputDecoration(
                        hintText: 'Filter by skillset',
                        prefixIcon: const Icon(Icons.category, color: Colors.black54),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: const BorderSide(color: Colors.grey),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: const BorderSide(color: Colors.grey),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: const BorderSide(color: Color(0xFF1E3A5F), width: 2),
                        ),
                        filled: true,
                        fillColor: Colors.white,
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  IconButton(
                    onPressed: () {
                      setState(() {
                        _selectedSkill = null;
                      });
                      _filterTasks();
                    },
                    icon: const Icon(Icons.clear_all),
                    tooltip: 'Clear filters',
                  ),
                ],
              ),
            ),
            const SizedBox(height: 8),

            // Tasks List
            Expanded(
              child: _loading
                  ? const Center(child: CircularProgressIndicator())
                  : _filteredTasks.isEmpty
                  ? Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.search_off,
                            size: 64,
                            color: Colors.grey[400],
                          ),
                          const SizedBox(height: 16),
                          Text(
                            'No tasks found',
                            style: TextStyle(
                              fontSize: 18,
                              color: Colors.grey[600],
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'Try a different search term',
                            style: TextStyle(
                              fontSize: 14,
                              color: Colors.grey[500],
                            ),
                          ),
                        ],
                      ),
                    )
                  : ListView.builder(
                      padding: const EdgeInsets.all(16),
                      itemCount: _filteredTasks.length,
                      itemBuilder: (context, index) {
                        final task = _filteredTasks[index];
                        return _TaskCard(
                          title: task['title'],
                          description: task['description'],
                          amount: task['amount'],
                          postedBy: task['postedBy'] ?? 'Task Provider',
                          status: task['status'] ?? 'open',
                          acceptedBy: (task['acceptedBy'] ?? '').toString(),
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => TaskDetailScreen(task: Task.fromJson(task['raw'])),
                              ),
                            );
                          },
                        );
                      },
                    ),
            ),
          ],
        ),
      ),
    );
  }
}

class _TaskCard extends StatelessWidget {
  final String title;
  final String description;
  final int amount;
  final String postedBy;
  final String status;
  final String acceptedBy;
  final VoidCallback onTap;

  const _TaskCard({
    required this.title,
    required this.description,
    required this.amount,
    required this.postedBy,
    required this.status,
    required this.acceptedBy,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final currentUserId = UserService.userId ?? '';
    final isMine = acceptedBy.isNotEmpty && acceptedBy == currentUserId;
    String badgeText = '';
    if (isMine && status.toLowerCase() == 'accepted') badgeText = 'Applied';
    if (isMine && status.toLowerCase() == 'completed') badgeText = 'Completed';
    
    // Status that imply funding
    final isFunded = status != 'draft';

    return Card(
      elevation: 2,
      margin: const EdgeInsets.only(bottom: 16),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
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
                      title,
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Colors.black87,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Posted by $postedBy',
                      style: const TextStyle(
                        fontSize: 13,
                        color: Colors.black54,
                      ),
                    ),
                    const SizedBox(height: 8),
                    if (isFunded)
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: Colors.green.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(6),
                          border: Border.all(color: Colors.green.withOpacity(0.3)),
                        ),
                        child: const Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.verified_user, size: 12, color: Colors.green),
                            SizedBox(width: 4),
                            Text(
                              'Payment Secured in Escrow ✅',
                              style: TextStyle(
                                fontSize: 10,
                                fontWeight: FontWeight.bold,
                                color: Colors.green,
                              ),
                            ),
                          ],
                        ),
                      ),
                    if (badgeText.isNotEmpty) ...[
                      const SizedBox(height: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: badgeText == 'Completed' ? Colors.green.withOpacity(0.1) : Colors.orange.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          badgeText,
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: badgeText == 'Completed' ? Colors.green : Colors.orange,
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    '₹$amount',
                    style: const TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF1E3A5F),
                    ),
                  ),
                  const SizedBox(height: 12),
                  SizedBox(
                    height: 32,
                    child: ElevatedButton(
                      onPressed: onTap,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF1E3A5F),
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(horizontal: 12),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(6),
                        ),
                        elevation: 0,
                      ),
                      child: const Text(
                        'View Details',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
