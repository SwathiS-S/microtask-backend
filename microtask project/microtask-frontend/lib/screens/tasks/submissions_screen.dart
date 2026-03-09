import 'package:flutter/material.dart';
import '../../models/task_model.dart';
import '../../widgets/top_actions.dart';
import 'task_detail_screen.dart';

class SubmissionsScreen extends StatelessWidget {
  final List<Task> submissions;

  const SubmissionsScreen({super.key, required this.submissions});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: const Color(0xFF1E3A5F),
        title: const Text('Submissions'),
        centerTitle: true,
        actions: topActions(context),
      ),
      body: SafeArea(
        child: submissions.isEmpty
            ? const Center(child: Text('No submissions yet'))
            : ListView.separated(
                padding: const EdgeInsets.all(16),
                itemCount: submissions.length,
                separatorBuilder: (_, __) => const SizedBox(height: 12),
                itemBuilder: (context, index) {
                  final t = submissions[index];
                  return ListTile(
                    tileColor: Colors.white,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    title: Text(t.title, style: const TextStyle(fontWeight: FontWeight.bold)),
                    subtitle: Text(t.description, maxLines: 2, overflow: TextOverflow.ellipsis),
                    trailing: Text('₹${t.amount}'),
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (_) => TaskDetailScreen(task: t)),
                      );
                    },
                  );
                },
              ),
      ),
    );
  }
}
