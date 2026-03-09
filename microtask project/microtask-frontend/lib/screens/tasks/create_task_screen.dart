import 'package:flutter/material.dart';
import '../../services/user_service.dart';
import '../../services/api_service.dart';
import '../../widgets/top_actions.dart';
import '../wallet/fund_task_screen.dart';

class CreateTaskScreen extends StatefulWidget {
  final Map<String, dynamic>? taskToClone;
  const CreateTaskScreen({super.key, this.taskToClone});

  @override
  State<CreateTaskScreen> createState() => _CreateTaskScreenState();
}

class _CreateTaskScreenState extends State<CreateTaskScreen> {
  late TextEditingController titleController;
  late TextEditingController descController;
  late TextEditingController amountController;
  late TextEditingController deadlineController;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    titleController = TextEditingController(text: widget.taskToClone?['title'] ?? '');
    descController = TextEditingController(text: widget.taskToClone?['description'] ?? '');
    amountController = TextEditingController(text: widget.taskToClone?['amount']?.toString() ?? '');
    deadlineController = TextEditingController();
  }

  @override
  void dispose() {
    titleController.dispose();
    descController.dispose();
    amountController.dispose();
    deadlineController.dispose();
    super.dispose();
  }

  Future<void> _handlePostTask() async {
    if (titleController.text.isEmpty ||
        descController.text.isEmpty ||
        amountController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please fill all fields'), backgroundColor: Colors.red),
      );
      return;
    }

    setState(() => _isLoading = true);
    try {
      // 1. Create the task as draft
      final taskRes = await ApiService.post('/tasks/create', {
        'postedBy': UserService.userId,
        'title': titleController.text,
        'description': descController.text,
        'amount': double.parse(amountController.text),
        'deadline': deadlineController.text,
      });

      if (taskRes != null && taskRes['success']) {
        final task = taskRes['task'];
        if (mounted) {
          final funded = await Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => FundTaskScreen(task: task, platformFee: task['amount'] * 0.02)),
          );
          Navigator.pop(context, funded == true);
        }
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to create task: ${taskRes?['message']}')),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e')));
    } finally {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F6FA),
      appBar: AppBar(
        backgroundColor: const Color(0xFF1E3A5F),
        elevation: 0,
        title: const Text('Create New Task', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        centerTitle: true,
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              TextField(
                controller: titleController,
                decoration: const InputDecoration(labelText: 'Task Title', border: OutlineInputBorder(), prefixIcon: Icon(Icons.title)),
              ),
              const SizedBox(height: 20),
              TextField(
                controller: descController,
                maxLines: 5,
                decoration: const InputDecoration(labelText: 'Description', border: OutlineInputBorder(), prefixIcon: Icon(Icons.description)),
              ),
              const SizedBox(height: 20),
              TextField(
                controller: amountController,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(labelText: 'Payment Amount', prefixText: '₹', border: OutlineInputBorder(), prefixIcon: Icon(Icons.currency_rupee)),
              ),
              const SizedBox(height: 20),
              TextField(
                controller: deadlineController,
                decoration: const InputDecoration(labelText: 'Deadline (YYYY-MM-DD)', border: OutlineInputBorder(), prefixIcon: Icon(Icons.calendar_today)),
                onTap: () async {
                  final date = await showDatePicker(
                    context: context, 
                    initialDate: DateTime.now().add(const Duration(days: 7)),
                    firstDate: DateTime.now(), 
                    lastDate: DateTime.now().add(const Duration(days: 365))
                  );
                  if (date != null) deadlineController.text = date.toIso8601String().split('T')[0];
                },
              ),
              const SizedBox(height: 32),
              
              const Text(
                "Your task will be saved as a draft first. You'll need to fund it via Razorpay to make it live for users.",
                style: TextStyle(color: Colors.grey, fontSize: 12),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 16),

              SizedBox(
                height: 50,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(backgroundColor: Colors.orange, foregroundColor: Colors.white),
                  onPressed: _isLoading ? null : _handlePostTask,
                  child: _isLoading 
                    ? const CircularProgressIndicator(color: Colors.white)
                    : const Text('Save & Continue to Payment', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
