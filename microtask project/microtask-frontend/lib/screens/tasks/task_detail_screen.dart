import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import '../../models/task_model.dart';
import '../../services/user_service.dart';
import '../../services/api_service.dart';
import '../../widgets/top_actions.dart';
import '../wallet/fund_task_screen.dart';
import 'create_task_screen.dart';

class TaskDetailScreen extends StatefulWidget {
  final Task? task;
  
  const TaskDetailScreen({super.key, this.task});

  @override
  State<TaskDetailScreen> createState() => _TaskDetailScreenState();
}

class _TaskDetailScreenState extends State<TaskDetailScreen> {
  late Task task;
  bool isAccepted = false;
  bool isSubmitting = false;

  @override
  void initState() {
    super.initState();
    task = widget.task ?? Task(
      id: '1',
      title: 'Website Redesign',
      description: 'Complete redesign of company website with modern UI/UX',
      amount: 1500,
      createdBy: 'Sarah',
      status: TaskStatus.open,
      workType: WorkType.wfh,
      createdAt: DateTime.now().subtract(const Duration(days: 1)),
    );
    isAccepted = task.acceptedBy == UserService.userId || task.status != TaskStatus.open;
  }

  Future<void> _handleApplyTask() async {
    // Step 1: Check bank account
    final bankRes = await ApiService.get('/bank/details/${UserService.userId}');
    if (bankRes == null || !bankRes['success']) {
      if (mounted) {
        showDialog(
          context: context,
          builder: (context) => AlertDialog(
            title: const Text('Bank Account Required'),
            content: const Text('Please connect your bank account to receive payments before applying.'),
            actions: [
              TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
              ElevatedButton(
                onPressed: () {
                  Navigator.pop(context);
                  Navigator.pushNamed(context, '/bank-setup');
                },
                child: const Text('Connect Now'),
              ),
            ],
          ),
        );
      }
      return;
    }

    setState(() => isSubmitting = true);
    try {
      final res = await ApiService.post('/tasks/apply', {
        'taskId': task.id,
        'userId': UserService.userId,
      });

      if (res['message'] == 'Applied successfully' || res['message'] == 'Application already exists') {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Applied successfully! Waiting for provider to accept.')),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(res['message'] ?? 'Failed to apply')),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $e')),
      );
    } finally {
      setState(() => isSubmitting = false);
    }
  }

  Future<void> _handleUploadWork() async {
    FilePickerResult? result = await FilePicker.platform.pickFiles();

    if (result != null) {
      setState(() => isSubmitting = true);
      try {
        final res = await ApiService.postFile(
          '/tasks/${task.id}/submit-final',
          result.files.single.path!,
          {'userId': UserService.userId!},
        );

        if (res['success']) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Work submitted successfully!')),
          );
          // Refresh task status
          _refreshTask();
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(res['message'] ?? 'Upload failed')),
          );
        }
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e')),
        );
      } finally {
        setState(() => isSubmitting = false);
      }
    }
  }

  Future<void> _refreshTask() async {
    try {
      final res = await ApiService.get('/tasks/all');
      if (res != null && res is List) {
        final updatedTaskData = res.firstWhere((t) => (t['_id'] ?? t['id']) == task.id);
        final updatedTask = Task.fromJson(updatedTaskData);
        
        // Check if just completed for this user
        if (task.status != TaskStatus.completed && updatedTask.status == TaskStatus.completed && updatedTask.acceptedBy == UserService.userId) {
          _showPaymentReceivedScreen(updatedTask.amount.toDouble());
        }

        setState(() {
          task = updatedTask;
          isAccepted = task.acceptedBy == UserService.userId || (task.status != TaskStatus.open && task.status != TaskStatus.funded);
        });
      }
    } catch (e) {
      debugPrint('Refresh error: $e');
    }
  }

  void _showPaymentReceivedScreen(double amount) {
    showGeneralDialog(
      context: context,
      barrierDismissible: false,
      barrierColor: Colors.black.withOpacity(0.8),
      transitionDuration: const Duration(milliseconds: 400),
      pageBuilder: (context, anim1, anim2) {
        return Scaffold(
          backgroundColor: Colors.transparent,
          body: Center(
            child: Container(
              margin: const EdgeInsets.symmetric(horizontal: 32),
              padding: const EdgeInsets.all(32),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(24),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text(
                    '🎉',
                    style: TextStyle(fontSize: 64),
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    'Payment Received!',
                    style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    '₹${amount.toStringAsFixed(0)} has been added to your wallet',
                    style: const TextStyle(fontSize: 16, color: Colors.grey),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 32),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: () {
                        Navigator.pop(context);
                        Navigator.pushNamed(context, '/wallet');
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.green,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                      child: const Text('View Wallet', style: TextStyle(fontWeight: FontWeight.bold)),
                    ),
                  ),
                  const SizedBox(height: 12),
                  TextButton(
                    onPressed: () {
                      Navigator.pop(context);
                      Navigator.pushNamed(context, '/wallet'); // Assuming user can withdraw from wallet screen
                    },
                    child: const Text('Withdraw Now', style: TextStyle(color: Colors.green, fontWeight: FontWeight.bold)),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F6FA),
      appBar: AppBar(
        backgroundColor: const Color(0xFF1E3A5F),
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'Task Details',
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
            fontSize: 20,
          ),
        ),
        centerTitle: true,
        actions: topActions(context),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Task Card
                Container(
                  padding: const EdgeInsets.all(20),
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
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Expanded(
                            child: Text(
                              task.title,
                              style: const TextStyle(
                                fontSize: 24,
                                fontWeight: FontWeight.bold,
                                color: Colors.black87,
                              ),
                            ),
                          ),
                          if (isAccepted || task.status != TaskStatus.open)
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 12,
                                vertical: 6,
                              ),
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
                      Text(
                        task.description,
                        style: const TextStyle(
                          fontSize: 16,
                          color: Colors.black54,
                          height: 1.5,
                        ),
                      ),
                      const SizedBox(height: 16),
                      Row(
                        children: [
                          Icon(
                            task.workType == WorkType.wfh ? Icons.home : Icons.location_on,
                            size: 16,
                            color: Colors.blueGrey,
                          ),
                          const SizedBox(width: 8),
                          Text(
                            task.workType == WorkType.wfh ? 'Work From Home' : 'Onsite Task',
                            style: const TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w500,
                              color: Colors.blueGrey,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 24),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                'Budget',
                                style: TextStyle(
                                  fontSize: 14,
                                  color: Colors.black54,
                                ),
                              ),
                              Text(
                                '₹${task.amount}',
                                style: const TextStyle(
                                  fontSize: 32,
                                  fontWeight: FontWeight.bold,
                                  color: Color(0xFF1E3A5F),
                                ),
                              ),
                            ],
                          ),
                          if (task.status != TaskStatus.draft)
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                              decoration: BoxDecoration(
                                color: Colors.green.withOpacity(0.1),
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(color: Colors.green.withOpacity(0.3)),
                              ),
                              child: const Row(
                                children: [
                                  Icon(Icons.verified_user, size: 16, color: Colors.green),
                                  SizedBox(width: 8),
                                  Text(
                                    'Payment Secured\nin Escrow ✅',
                                    style: TextStyle(
                                      fontSize: 12,
                                      fontWeight: FontWeight.bold,
                                      color: Colors.green,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),

                // Applicants List for Provider
                if (UserService.userId == task.createdBy && task.status == TaskStatus.open)
                  _buildApplicantsList(),

                // Provider Actions
                if (UserService.userId == task.createdBy)
                  _buildProviderActions(),

                // User Actions
                if (UserService.userId != task.createdBy)
                  _buildUserActions(),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildApplicantsList() {
    final apps = task.applications ?? [];
    if (apps.isEmpty) {
      return const Center(child: Text('No applicants yet', style: TextStyle(color: Colors.grey)));
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('Applicants', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
        const SizedBox(height: 12),
        ...apps.map((app) {
          final user = app['userId'];
          final state = app['state'];
          if (user == null) return const SizedBox();

          return Container(
            margin: const EdgeInsets.only(bottom: 12),
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 4)],
            ),
            child: Row(
              children: [
                CircleAvatar(child: Text(user['name']?[0] ?? 'U')),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(user['name'] ?? 'Unknown', style: const TextStyle(fontWeight: FontWeight.bold)),
                      Text('Skills: ${user['skills'] ?? 'N/A'}', style: const TextStyle(fontSize: 12, color: Colors.grey)),
                    ],
                  ),
                ),
                if (state == 'APPLIED')
                  Row(
                    children: [
                      IconButton(
                        onPressed: () => _handleApplication(user['_id'], 'REJECTED'),
                        icon: const Icon(Icons.close, color: Colors.red),
                      ),
                      IconButton(
                        onPressed: () => _handleApplication(user['_id'], 'APPROVED'),
                        icon: const Icon(Icons.check, color: Colors.green),
                      ),
                    ],
                  )
                else
                  Text(state, style: TextStyle(color: state == 'ACCEPTED' ? Colors.green : Colors.red, fontWeight: FontWeight.bold)),
              ],
            ),
          );
        }).toList(),
      ],
    );
  }

  Widget _buildProviderActions() {
    switch (task.status) {
      case TaskStatus.draft:
        return _buildActionButton('Fund Task', Colors.orange, () => _handleFundTask());
      case TaskStatus.assigned:
        return _buildStatusIndicator('Worker Assigned. Waiting for them to start.', Colors.teal);
      case TaskStatus.inProgress:
        return _buildActionButton('View Progress Updates', Colors.blue, () => _handleViewUpdates());
      case TaskStatus.submitted:
        return _buildActionButton('Mark as Reviewed', Colors.blue, () => _handleMarkReviewed());
      case TaskStatus.reviewed:
        return Column(
          children: [
            const Text('Work Reviewed', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(child: _buildActionButton('Raise Dispute', Colors.red, () => _handleDispute())),
                const SizedBox(width: 12),
                Expanded(child: _buildActionButton('Approve & Pay', Colors.green, () => _handleReleasePayment())),
              ],
            ),
          ],
        );
      case TaskStatus.completed:
        return _buildStatusIndicator('Completed ✅', Colors.green);
      case TaskStatus.disputed:
        return _buildStatusIndicator('In Dispute ⚠️', Colors.red);
      case TaskStatus.expired:
        return Column(
          children: [
            _buildStatusIndicator('Task Expired', Colors.black),
            const SizedBox(height: 12),
            _buildActionButton('Repost Task', Colors.orange, () => _handleRepost()),
          ],
        );
      default:
        return const SizedBox();
    }
  }

  Widget _buildUserActions() {
    if (isSubmitting) return const Center(child: CircularProgressIndicator());

    switch (task.status) {
      case TaskStatus.open:
      case TaskStatus.funded:
        return _buildActionButton('Apply Now', const Color(0xFF1976D2), () => _handleApplyTask());
      case TaskStatus.assigned:
        if (task.acceptedBy == UserService.userId) {
          return _buildActionButton('Start Task', Colors.orange, () => _handleStartTask());
        }
        return const SizedBox();
      case TaskStatus.inProgress:
        if (task.acceptedBy == UserService.userId) {
          return Column(
            children: [
              _buildActionButton('Submit Daily Update', Colors.blue, () => _handleSubmitUpdate()),
              const SizedBox(height: 12),
              _buildActionButton('Submit Final Work', Colors.green, () => _handleUploadWork()),
            ],
          );
        }
        return const SizedBox();
      case TaskStatus.submitted:
        return _buildStatusIndicator('Work Submitted ✅', Colors.green);
      case TaskStatus.reviewed:
        return _buildStatusIndicator('Under Review ⏳', Colors.orange);
      case TaskStatus.completed:
        if (task.acceptedBy == UserService.userId) {
          return _buildActionButton('Withdraw Payment', Colors.green, () => Navigator.pushNamed(context, '/wallet'));
        }
        return const SizedBox();
      case TaskStatus.disputed:
        return _buildStatusIndicator('In Dispute ⚠️', Colors.red);
      default:
        return const SizedBox();
    }
  }

  Widget _buildActionButton(String label, Color color, VoidCallback onPressed) {
    return SizedBox(
      width: double.infinity,
      height: 50,
      child: ElevatedButton(
        onPressed: onPressed,
        style: ElevatedButton.styleFrom(backgroundColor: color, foregroundColor: Colors.white),
        child: Text(label, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
      ),
    );
  }

  Widget _buildStatusIndicator(String text, Color color) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: color.withOpacity(0.1), borderRadius: BorderRadius.circular(12), border: Border.all(color: color)),
      child: Text(text, textAlign: TextAlign.center, style: TextStyle(color: color, fontWeight: FontWeight.bold, fontSize: 16)),
    );
  }

  Future<void> _handleMarkReviewed() async {
    setState(() => isSubmitting = true);
    try {
      final res = await ApiService.post('/tasks/${task.id}/review', {
        'providerId': UserService.userId,
      });
      if (res['success']) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Task marked as reviewed.')));
        _refreshTask();
      }
    } catch (e) {
      debugPrint('Review error: $e');
    } finally {
      setState(() => isSubmitting = false);
    }
  }

  Future<void> _handleFundTask() async {
     final funded = await Navigator.push(
       context,
       MaterialPageRoute(builder: (context) => FundTaskScreen(task: {'_id': task.id, 'title': task.title, 'amount': task.amount})),
     );
     if (funded == true) _refreshTask();
   }
 
   void _handleViewUpdates() {
     // This would typically navigate to a separate screen or show a bottom sheet
     showModalBottomSheet(
       context: context,
       builder: (context) => Container(
         padding: const EdgeInsets.all(24),
         child: Column(
           mainAxisSize: MainAxisSize.min,
           children: [
             const Text('Recent Updates', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
             const SizedBox(height: 16),
             if (task.applications != null && task.applications!.isNotEmpty)
               const Text('Daily updates from worker will appear here...')
             else
               const Text('No updates yet.'),
           ],
         ),
       ),
     );
   }
 
   void _handleSubmitUpdate() {
     final controller = TextEditingController();
     showDialog(
       context: context,
       builder: (context) => AlertDialog(
         title: const Text('Submit Update'),
         content: TextField(
           controller: controller,
           decoration: const InputDecoration(hintText: 'What did you work on today?'),
           maxLines: 3,
         ),
         actions: [
           TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
           ElevatedButton(
             onPressed: () async {
               if (controller.text.isEmpty) return;
               final res = await ApiService.post('/tasks/${task.id}/status-update', {
                 'userId': UserService.userId,
                 'text': controller.text,
               });
               if (res['success']) {
                 Navigator.pop(context);
                 ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Update submitted!')));
               }
             },
             child: const Text('Submit'),
           ),
         ],
       ),
     );
   }
 
   void _handleRepost() {
     Navigator.push(
       context,
       MaterialPageRoute(builder: (context) => CreateTaskScreen(taskToClone: {'title': task.title, 'description': task.description, 'amount': task.amount})),
     );
   }

  Future<void> _handleApplication(String userId, String status) async {
    setState(() => isSubmitting = true);
    try {
      final res = await ApiService.post('/tasks/applications/status', {
        'taskId': task.id,
        'userId': userId,
        'approvedBy': UserService.userId,
        'status': status,
      });

      if (res['success']) {
        if (status == 'APPROVED') {
          // If approved, we need to call /applications/accept to actually assign it
          await ApiService.post('/tasks/applications/accept', {
            'taskId': task.id,
            'userId': userId,
            'approvedBy': UserService.userId,
          });
        }
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Application $status')));
        _refreshTask();
      }
    } catch (e) {
      debugPrint('App error: $e');
    } finally {
      setState(() => isSubmitting = false);
    }
  }

  Future<void> _handleStartTask() async {
    setState(() => isSubmitting = true);
    try {
      final res = await ApiService.post('/tasks/${task.id}/start', {
        'userId': UserService.userId,
      });
      if (res['success']) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Task started! Good luck.')));
        _refreshTask();
      }
    } catch (e) {
      debugPrint('Start error: $e');
    } finally {
      setState(() => isSubmitting = false);
    }
  }

  Future<void> _handleReleasePayment() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Release Payment'),
        content: const Text('Are you sure you want to approve this work and release ₹500 to the user?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancel')),
          ElevatedButton(onPressed: () => Navigator.pop(context, true), child: const Text('Release')),
        ],
      ),
    );
    if (confirm != true) return;

    setState(() => isSubmitting = true);
    try {
      final res = await ApiService.post('/escrow/release/${task.id}', {
        'userId': task.acceptedBy,
      });
      if (res['success']) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Payment released successfully! ✅')));
        _refreshTask();
      }
    } catch (e) {
      debugPrint('Release error: $e');
    } finally {
      setState(() => isSubmitting = false);
    }
  }

  Future<void> _handleDispute() async {
    final reasonController = TextEditingController();
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Raise Dispute'),
        content: TextField(
          controller: reasonController,
          decoration: const InputDecoration(labelText: 'Reason for dispute'),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancel')),
          ElevatedButton(onPressed: () => Navigator.pop(context, true), child: const Text('Raise Dispute')),
        ],
      ),
    );
    if (confirm != true) return;

    setState(() => isSubmitting = true);
    try {
      final res = await ApiService.post('/escrow/dispute/${task.id}', {
        'reason': reasonController.text,
      });
      if (res['success']) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Dispute raised. Admin will review.')));
        _refreshTask();
      }
    } catch (e) {
      debugPrint('Dispute error: $e');
    } finally {
      setState(() => isSubmitting = false);
    }
  }
}
