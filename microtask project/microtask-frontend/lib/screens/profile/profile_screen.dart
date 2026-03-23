import 'package:flutter/material.dart';
import '../../theme/app_theme.dart';
import '../../services/user_service.dart';
import '../../services/api_service.dart';
import '../auth/login_screen.dart';
import 'package:file_picker/file_picker.dart';
import 'dart:io';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  bool isLoading = true;
  Map<String, dynamic> stats = {
    "activeTasks": 0,
    "completedTasks": 0,
    "totalEarned": 0.0,
    "totalTasks": 0,
    "activeWorkers": 0,
    "totalPaid": 0.0
  };
  List<dynamic> activeTasks = [];

  @override
  void initState() {
    super.initState();
    _fetchDashboardData();
  }

  Future<void> _fetchDashboardData() async {
    final user = UserService.getUser();
    if (user == null) return;

    setState(() => isLoading = true);

    try {
      final statsRes = await ApiService.get("/users/${user.id}/stats");
      final tasksRes = user.role == UserRole.taskProvider 
          ? await ApiService.get("/tasks/provider/${user.id}")
          : await ApiService.get("/tasks/worker/${user.id}");

      if (mounted) {
        setState(() {
          if (statsRes != null && statsRes['success'] == true) {
            stats = statsRes['stats'];
          }
          activeTasks = tasksRes ?? [];
          isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) setState(() => isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final user = UserService.getUser();
    final bool isProvider = user?.role == UserRole.taskProvider;

    return Scaffold(
      backgroundColor: AppTheme.cream,
      appBar: AppBar(
        title: const Text('Dashboard'),
        actions: [
          IconButton(
            onPressed: () {
              UserService.clearUser();
              Navigator.pushAndRemoveUntil(
                context,
                MaterialPageRoute(builder: (_) => const LoginScreen()),
                (route) => false,
              );
            },
            icon: const Icon(Icons.logout, size: 20),
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: _fetchDashboardData,
        child: isLoading
            ? const Center(child: CircularProgressIndicator())
            : SingleChildScrollView(
                padding: const EdgeInsets.all(24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Welcome back,', style: AppTheme.bodyMuted),
                    Text(user?.name ?? 'User', style: AppTheme.heading1),
                    const SizedBox(height: 32),

                    GridView.count(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      crossAxisCount: 2,
                      crossAxisSpacing: 16,
                      mainAxisSpacing: 16,
                      childAspectRatio: 1.5,
                      children: isProvider ? _buildProviderStats() : _buildWorkerStats(),
                    ),

                    const SizedBox(height: 40),

                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(isProvider ? 'Your Active Tasks' : 'Tasks in Progress', style: AppTheme.heading3),
                        if (!isProvider)
                          Text('${activeTasks.length} Active', style: const TextStyle(color: AppTheme.gold, fontWeight: FontWeight.bold, fontSize: 12)),
                      ],
                    ),
                    const SizedBox(height: 16),

                    if (activeTasks.isEmpty)
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(40),
                        decoration: AppTheme.cardDecoration,
                        child: Column(
                          children: [
                            Icon(Icons.assignment_outlined, size: 48, color: AppTheme.textMuted.withOpacity(0.3)),
                            const SizedBox(height: 16),
                            Text(
                              isProvider ? 'You haven\'t posted any tasks yet.' : 'You aren\'t working on any tasks yet.',
                              style: AppTheme.bodyMuted,
                              textAlign: TextAlign.center,
                            ),
                          ],
                        ),
                      )
                    else
                      ListView.separated(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        itemCount: activeTasks.length,
                        separatorBuilder: (_, __) => const SizedBox(height: 16),
                        itemBuilder: (context, index) {
                          final task = activeTasks[index];
                          return _buildTaskCard(task, isProvider);
                        },
                      ),
                    
                    const SizedBox(height: 40),
                  ],
                ),
              ),
      ),
    );
  }

  List<Widget> _buildWorkerStats() {
    return [
      _buildStatCard('Active Tasks', stats['activeTasks'].toString(), Icons.bolt, AppTheme.gold),
      _buildStatCard('Completed', stats['completedTasks'].toString(), Icons.check_circle_outline, AppTheme.success),
      _buildStatCard('Total Earned', '₹${stats['totalEarned']}', Icons.payments_outlined, AppTheme.navy),
      _buildStatCard('Rank', 'Pro', Icons.star_outline, Colors.orange),
    ];
  }

  List<Widget> _buildProviderStats() {
    return [
      _buildStatCard('Total Tasks', stats['totalTasks'].toString(), Icons.list_alt, AppTheme.navy),
      _buildStatCard('Active Workers', stats['activeWorkers'].toString(), Icons.people_outline, AppTheme.gold),
      _buildStatCard('Total Paid', '₹${stats['totalPaid']}', Icons.account_balance_wallet_outlined, AppTheme.success),
      _buildStatCard('Status', 'Verified', Icons.verified_user_outlined, Colors.blue),
    ];
  }

  Widget _buildStatCard(String label, String value, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: AppTheme.cardDecoration,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(label, style: const TextStyle(fontSize: 11, color: AppTheme.textMuted, fontWeight: FontWeight.w600)),
              Icon(icon, size: 16, color: color),
            ],
          ),
          Text(value, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w800, color: AppTheme.navy)),
        ],
      ),
    );
  }

  Widget _buildTaskCard(Map<String, dynamic> task, bool isProvider) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: AppTheme.cardDecoration,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Text(task['title'] ?? 'Untitled Task', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: _getStatusColor(task['status']).withOpacity(0.1),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Text(
                  task['status']?.toUpperCase() ?? 'OPEN',
                  style: TextStyle(color: _getStatusColor(task['status']), fontSize: 10, fontWeight: FontWeight.bold),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text('Amount: ₹${task['amount']}', style: const TextStyle(fontWeight: FontWeight.w600, color: AppTheme.gold, fontSize: 14)),
          const SizedBox(height: 20),
          
          if (isProvider) 
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () => _viewReports(task),
                    style: AppTheme.outlineButton.copyWith(padding: MaterialStateProperty.all(EdgeInsets.zero)),
                    child: const Text('Reports', style: TextStyle(fontSize: 12)),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: ElevatedButton(
                    onPressed: () => _viewSubmissions(task),
                    style: AppTheme.primaryButton.copyWith(padding: MaterialStateProperty.all(EdgeInsets.zero)),
                    child: const Text('Submissions', style: TextStyle(fontSize: 12)),
                  ),
                ),
              ],
            )
          else
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () => _postDailyStatus(task),
                    style: AppTheme.outlineButton.copyWith(padding: MaterialStateProperty.all(EdgeInsets.zero)),
                    child: const Text('Daily Status', style: TextStyle(fontSize: 12)),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: ElevatedButton(
                    onPressed: () => _submitWork(task),
                    style: AppTheme.goldButton.copyWith(padding: MaterialStateProperty.all(EdgeInsets.zero)),
                    child: const Text('Submit Work', style: TextStyle(fontSize: 12)),
                  ),
                ),
              ],
            ),
        ],
      ),
    );
  }

  Color _getStatusColor(String? status) {
    switch (status?.toLowerCase()) {
      case 'accepted': return Colors.blue;
      case 'inprogress': return Colors.orange;
      case 'submitted': return Colors.purple;
      case 'completed': return AppTheme.success;
      case 'underreview': return Colors.teal;
      default: return AppTheme.textMuted;
    }
  }

  void _postDailyStatus(Map<String, dynamic> task) {
    final TextEditingController controller = TextEditingController();
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Post Daily Status', style: AppTheme.heading3),
        content: TextField(
          controller: controller,
          maxLines: 3,
          decoration: const InputDecoration(hintText: 'Describe what you did today...'),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () async {
              if (controller.text.isEmpty) return;
              final user = UserService.getUser();
              final res = await ApiService.post("/tasks/${task['_id']}/status-update", {
                "userId": user?.id,
                "text": controller.text
              });
              if (mounted) {
                Navigator.pop(context);
                if (res != null && res['success'] == true) {
                  ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Status updated successfully')));
                }
              }
            },
            child: const Text('Post'),
          ),
        ],
      ),
    );
  }

  Future<void> _submitWork(Map<String, dynamic> task) async {
    FilePickerResult? result = await FilePicker.platform.pickFiles();
    if (result == null) return;

    File file = File(result.files.single.path!);
    final user = UserService.getUser();

    if (mounted) {
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => const Center(child: CircularProgressIndicator()),
      );
    }

    final res = await ApiService.postFile(
      "/tasks/${task['_id']}/submit-final",
      file.path,
      {"userId": user?.id ?? ""}
    );

    if (mounted) {
      Navigator.pop(context); // Close loading
      if (res != null && res['success'] == true) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Work submitted for review')));
        _fetchDashboardData();
      } else {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(res?['message'] ?? 'Submission failed')));
      }
    }
  }

  void _viewReports(Map<String, dynamic> task) async {
    showDialog(
      context: context,
      builder: (context) => const Center(child: CircularProgressIndicator()),
    );
    
    final res = await ApiService.get("/tasks/${task['_id']}/updates");
    
    if (mounted) {
      Navigator.pop(context); // Close loading
      if (res != null && res['success'] == true) {
        final List updates = res['updates'] ?? [];
        showModalBottomSheet(
          context: context,
          backgroundColor: Colors.white,
          shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
          builder: (context) => Container(
            padding: const EdgeInsets.all(24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Daily Reports', style: AppTheme.heading3),
                const SizedBox(height: 20),
                Expanded(
                  child: updates.isEmpty 
                    ? const Center(child: Text('No reports yet'))
                    : ListView.separated(
                        itemCount: updates.length,
                        separatorBuilder: (_, __) => const Divider(),
                        itemBuilder: (context, index) {
                          final up = updates[index];
                          return ListTile(
                            title: Text(up['text'] ?? '', style: const TextStyle(fontSize: 14)),
                            subtitle: Text(up['createdAt']?.toString().substring(0, 10) ?? '', style: AppTheme.small),
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
  }

  void _viewSubmissions(Map<String, dynamic> task) {
    if (task['finalStatus'] != 'SUBMITTED' && task['status'] != 'submitted') {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('No submissions yet')));
      return;
    }

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (context) => Container(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('Final Submission', style: AppTheme.heading3),
            const SizedBox(height: 20),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: AppTheme.cardDecoration,
              child: Row(
                children: [
                  const Icon(Icons.file_present, color: AppTheme.gold),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(task['finalFile']?['filename'] ?? 'Final Work File', overflow: TextOverflow.ellipsis),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 32),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () => _handleFinalAction(task, 'reject'),
                    style: AppTheme.outlineButton,
                    child: const Text('Reject'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton(
                    onPressed: () => _handleFinalAction(task, 'approve'),
                    style: AppTheme.primaryButton,
                    child: const Text('Approve & Pay'),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _handleFinalAction(Map<String, dynamic> task, String action) async {
    final user = UserService.getUser();
    Navigator.pop(context); // Close bottom sheet
    
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const Center(child: CircularProgressIndicator()),
    );

    final endpoint = action == 'approve' ? "/tasks/approve-final" : "/tasks/reject-final";
    final payload = action == 'approve' 
        ? {"taskId": task['_id'], "providerId": user?.id}
        : {"taskId": task['_id'], "approvedBy": user?.id, "remark": "Rejected by provider"};

    final res = await ApiService.post(endpoint, payload);
    
    if (mounted) {
      Navigator.pop(context); // Close loading
      if (res != null && res['success'] == true) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Task ${action}ed successfully')));
        _fetchDashboardData();
      } else {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(res?['message'] ?? 'Action failed')));
      }
    }
  }
}
