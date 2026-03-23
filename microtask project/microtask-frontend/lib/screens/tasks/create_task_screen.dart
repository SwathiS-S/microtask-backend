import 'package:flutter/material.dart';
import '../../theme/app_theme.dart';
import '../../services/api_service.dart';
import '../../services/user_service.dart';

class CreateTaskScreen extends StatefulWidget {
  const CreateTaskScreen({super.key});

  @override
  State<CreateTaskScreen> createState() => _CreateTaskScreenState();
}

class _CreateTaskScreenState extends State<CreateTaskScreen> {
  final TextEditingController title = TextEditingController();
  final TextEditingController skillset = TextEditingController();
  final TextEditingController description = TextEditingController();
  final TextEditingController location = TextEditingController();
  final TextEditingController amount = TextEditingController();
  final TextEditingController duration = TextEditingController();

  String selectedWorkType = "Remote";
  bool isLoading = false;

  Future<void> _handleCreateTask() async {
    if (title.text.isEmpty || skillset.text.isEmpty || amount.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please fill required fields (Title, Skillset, Amount)')),
      );
      return;
    }

    final user = UserService.getUser();
    if (user == null) return;

    setState(() => isLoading = true);

    try {
      final response = await ApiService.post("/tasks/create", {
        "title": title.text.trim(),
        "description": description.text.trim(),
        "amount": double.tryParse(amount.text) ?? 0.0,
        "postedBy": user.id,
        "skillset": skillset.text.trim(),
        "workType": selectedWorkType,
        "location": location.text.trim(),
        "duration": duration.text.trim(),
      });

      setState(() => isLoading = false);

      if (response != null && (response['success'] == true || response['message'] == 'Task created successfully')) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Task posted successfully!')),
          );
          // Clear form
          title.clear();
          skillset.clear();
          description.clear();
          location.clear();
          amount.clear();
          duration.clear();
        }
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(response?['message'] ?? 'Failed to create task')),
        );
      }
    } catch (e) {
      setState(() => isLoading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Error creating task')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.cream,
      appBar: AppBar(title: const Text('Create New Task')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Post a new opportunity', style: AppTheme.heading2),
            const SizedBox(height: 8),
            const Text('Fill in the details to find the best workers', style: AppTheme.bodyMuted),
            const SizedBox(height: 32),

            _buildLabel('TASK TITLE*'),
            TextField(controller: title, decoration: const InputDecoration(hintText: 'e.g. Website Design Project')),
            const SizedBox(height: 20),

            _buildLabel('SKILLSET REQUIRED*'),
            TextField(controller: skillset, decoration: const InputDecoration(hintText: 'e.g. React / JavaScript')),
            const SizedBox(height: 20),

            _buildLabel('DESCRIPTION'),
            TextField(
              controller: description, 
              maxLines: 4,
              decoration: const InputDecoration(hintText: 'Describe the task in detail...'),
            ),
            const SizedBox(height: 20),

            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildLabel('WORK TYPE'),
                      DropdownButtonFormField<String>(
                        value: selectedWorkType,
                        decoration: const InputDecoration(),
                        items: ["Remote", "On-site"].map((type) => DropdownMenuItem(
                          value: type,
                          child: Text(type, style: const TextStyle(fontSize: 14)),
                        )).toList(),
                        onChanged: (val) => setState(() => selectedWorkType = val!),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildLabel('LOCATION'),
                      TextField(controller: location, decoration: const InputDecoration(hintText: 'e.g. New York')),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),

            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildLabel('DURATION (DAYS)'),
                      TextField(controller: duration, keyboardType: TextInputType.number, decoration: const InputDecoration(hintText: 'e.g. 5')),
                    ],
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildLabel('AMOUNT (₹)*'),
                      TextField(controller: amount, keyboardType: TextInputType.number, decoration: const InputDecoration(hintText: 'e.g. 500')),
                    ],
                  ),
                ),
              ],
            ),
            
            const SizedBox(height: 40),

            SizedBox(
              width: double.infinity,
              height: 56,
              child: ElevatedButton(
                onPressed: isLoading ? null : _handleCreateTask,
                style: AppTheme.goldButton,
                child: isLoading
                    ? const CircularProgressIndicator(color: Colors.white)
                    : const Text('Post Task Now', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
              ),
            ),
            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }

  Widget _buildLabel(String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Text(text, style: AppTheme.small),
    );
  }
}
