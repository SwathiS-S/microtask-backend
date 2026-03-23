import 'package:flutter/material.dart';
import '../../theme/app_theme.dart';
import '../../services/api_service.dart';
import '../../services/user_service.dart';

class TaskDetailScreen extends StatefulWidget {
  final String taskId;
  const TaskDetailScreen({super.key, required this.taskId});

  @override
  State<TaskDetailScreen> createState() => _TaskDetailScreenState();
}

class _TaskDetailScreenState extends State<TaskDetailScreen> {
  Map<String, dynamic>? task;
  bool isLoading = true;
  bool isApplying = false;

  @override
  void initState() {
    super.initState();
    _fetchTaskDetails();
  }

  Future<void> _fetchTaskDetails() async {
    setState(() => isLoading = true);
    final response = await ApiService.get("/tasks/${widget.taskId}");
    if (mounted) {
      setState(() {
        task = response;
        isLoading = false;
      });
    }
  }

  Future<void> _handleApply() async {
    final user = UserService.getUser();
    if (user == null) return;

    setState(() => isApplying = true);
    try {
      final response = await ApiService.post("/tasks/accept", {
        "taskId": widget.taskId,
        "userId": user.id,
      });

      if (mounted) {
        setState(() => isApplying = false);
        if (response != null && response['success'] == true) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Successfully applied for task!')),
          );
          _fetchTaskDetails();
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(response?['message'] ?? 'Failed to apply')),
          );
        }
      }
    } catch (e) {
      setState(() => isApplying = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (isLoading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    if (task == null) {
      return const Scaffold(body: Center(child: Text('Task not found')));
    }

    final user = UserService.getUser();
    final bool isProvider = user?.role == UserRole.taskProvider;
    final bool isOwner = task!['postedBy'] == user?.id;
    final bool isAccepted = task!['acceptedBy'] != null;
    final bool isAcceptedByMe = task!['acceptedBy'] == user?.id;

    return Scaffold(
      backgroundColor: AppTheme.cream,
      appBar: AppBar(title: const Text('Task Details')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header Card
            Container(
              padding: const EdgeInsets.all(24),
              decoration: AppTheme.cardDecoration,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                        decoration: BoxDecoration(
                          color: AppTheme.navy.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          task!['skillset'] ?? 'General',
                          style: const TextStyle(color: AppTheme.navy, fontSize: 12, fontWeight: FontWeight.bold),
                        ),
                      ),
                      Text(
                        '₹${task!['amount']}',
                        style: const TextStyle(fontSize: 24, fontWeight: FontWeight.w800, color: AppTheme.gold),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),
                  Text(task!['title'] ?? 'Untitled Task', style: AppTheme.heading2),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      _buildInfoBadge(Icons.location_on_outlined, task!['location'] ?? 'Remote'),
                      const SizedBox(width: 16),
                      _buildInfoBadge(Icons.work_outline, task!['workType'] ?? 'Remote'),
                      const SizedBox(width: 16),
                      _buildInfoBadge(Icons.timer_outlined, '${task!['duration'] ?? "5"} Days'),
                    ],
                  ),
                ],
              ),
            ),

            const SizedBox(height: 32),
            const Text('Description', style: AppTheme.heading3),
            const SizedBox(height: 12),
            Text(
              task!['description'] ?? 'No description provided.',
              style: const TextStyle(fontSize: 15, color: AppTheme.textDark, height: 1.6),
            ),

            const SizedBox(height: 40),
            
            // Actions
            if (!isProvider && !isAccepted)
              SizedBox(
                width: double.infinity,
                height: 56,
                child: ElevatedButton(
                  onPressed: isApplying ? null : _handleApply,
                  style: AppTheme.goldButton,
                  child: isApplying 
                    ? const CircularProgressIndicator(color: Colors.white)
                    : const Text('Apply for Task', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                ),
              ),
            
            if (isAcceptedByMe)
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: AppTheme.success.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: AppTheme.success.withOpacity(0.3)),
                ),
                child: const Row(
                  children: [
                    Icon(Icons.check_circle, color: AppTheme.success),
                    SizedBox(width: 12),
                    Text('You have accepted this task', style: TextStyle(color: AppTheme.success, fontWeight: FontWeight.bold)),
                  ],
                ),
              ),

            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoBadge(IconData icon, String text) {
    return Row(
      children: [
        Icon(icon, size: 16, color: AppTheme.textMuted),
        const SizedBox(width: 4),
        Text(text, style: AppTheme.small),
      ],
    );
  }
}
