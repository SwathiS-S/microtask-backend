import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import '../../models/task_model.dart';
import '../../services/user_service.dart';
import '../../services/api_service.dart';
import '../../widgets/top_actions.dart';

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
        final updatedTask = res.firstWhere((t) => (t['_id'] ?? t['id']) == task.id);
        setState(() {
          task = Task.fromJson(updatedTask);
          isAccepted = task.acceptedBy == UserService.userId || task.status != TaskStatus.open;
        });
      }
    } catch (e) {
      debugPrint('Refresh error: $e');
    }
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
                                'Payment Amount',
                                style: TextStyle(
                                  fontSize: 14,
                                  color: Colors.black54,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                '₹${task.amount}',
                                style: const TextStyle(
                                  fontSize: 28,
                                  fontWeight: FontWeight.bold,
                                  color: Color(0xFF1E3A5F),
                                ),
                              ),
                            ],
                          ),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.end,
                            children: [
                              const Text(
                                'Posted by',
                                style: TextStyle(
                                  fontSize: 14,
                                  color: Colors.black54,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                task.createdBy,
                                style: const TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w600,
                                  color: Colors.black87,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),

                // Action Buttons based on status and workType
                if (isSubmitting)
                  const Center(child: CircularProgressIndicator())
                else if (!isAccepted && task.status == TaskStatus.open)
                  SizedBox(
                    width: double.infinity,
                    height: 50,
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF1976D2),
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                        elevation: 2,
                      ),
                      onPressed: _handleApplyTask,
                      child: const Text(
                        'Apply for Task',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  )
                else if (isAccepted && task.status == TaskStatus.accepted)
                  Column(
                    children: [
                      if (task.workType == WorkType.wfh)
                        SizedBox(
                          width: double.infinity,
                          height: 50,
                          child: ElevatedButton.icon(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.green,
                              foregroundColor: Colors.white,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(8),
                              ),
                            ),
                            onPressed: _handleUploadWork,
                            icon: const Icon(Icons.upload_file),
                            label: const Text('Upload Final Work'),
                          ),
                        )
                      else
                        Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: Colors.blue.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(color: Colors.blue),
                          ),
                          child: const Row(
                            children: [
                              Icon(Icons.info, color: Colors.blue),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Text(
                                  'This is an onsite task. Please complete the work at the location. The provider will approve once verified.',
                                  style: TextStyle(color: Colors.blue, fontWeight: FontWeight.w500),
                                ),
                              ),
                            ],
                          ),
                        ),
                    ],
                  )
                else if (task.status == TaskStatus.submitted)
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.orange.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: Colors.orange),
                    ),
                    child: const Row(
                      children: [
                        Icon(Icons.hourglass_empty, color: Colors.orange),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            'Final work submitted! Waiting for provider review.',
                            style: TextStyle(color: Colors.orange, fontWeight: FontWeight.w500),
                          ),
                        ),
                      ],
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
