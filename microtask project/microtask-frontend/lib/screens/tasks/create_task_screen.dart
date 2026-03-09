import 'package:flutter/material.dart';
import '../../widgets/top_actions.dart';

class CreateTaskScreen extends StatefulWidget {
  const CreateTaskScreen({super.key});

  @override
  State<CreateTaskScreen> createState() => _CreateTaskScreenState();
}

class _CreateTaskScreenState extends State<CreateTaskScreen> {
  final TextEditingController titleController = TextEditingController();
  final TextEditingController descController = TextEditingController();
  final TextEditingController amountController = TextEditingController();

  @override
  void dispose() {
    titleController.dispose();
    descController.dispose();
    amountController.dispose();
    super.dispose();
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
          'Create New Task',
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
                // Task Title
                TextField(
                  controller: titleController,
                  decoration: InputDecoration(
                    labelText: 'Task Title',
                    labelStyle: const TextStyle(color: Colors.black54),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                      borderSide: const BorderSide(color: Colors.grey),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                      borderSide: const BorderSide(color: Color(0xFF1E3A5F), width: 2),
                    ),
                    prefixIcon: const Icon(Icons.title, color: Colors.black54),
                  ),
                ),
                const SizedBox(height: 20),

                // Description
                TextField(
                  controller: descController,
                  maxLines: 5,
                  decoration: InputDecoration(
                    labelText: 'Description',
                    labelStyle: const TextStyle(color: Colors.black54),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                      borderSide: const BorderSide(color: Colors.grey),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                      borderSide: const BorderSide(color: Color(0xFF1E3A5F), width: 2),
                    ),
                    prefixIcon: const Icon(Icons.description, color: Colors.black54),
                  ),
                ),
                const SizedBox(height: 20),

                // Payment Amount
                TextField(
                  controller: amountController,
                  keyboardType: TextInputType.number,
                  decoration: InputDecoration(
                    labelText: 'Payment Amount',
                    labelStyle: const TextStyle(color: Colors.black54),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                      borderSide: const BorderSide(color: Colors.grey),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                      borderSide: const BorderSide(color: Color(0xFF1E3A5F), width: 2),
                    ),
                    prefixIcon: const Icon(Icons.currency_rupee, color: Colors.black54),
                    prefixText: '₹',
                    prefixStyle: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Colors.black87,
                    ),
                  ),
                ),
                const SizedBox(height: 32),

                // Post Task Button
                SizedBox(
                  width: double.infinity,
                  height: 50,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.orange,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                      elevation: 2,
                    ),
                    onPressed: () {
                      if (titleController.text.isEmpty ||
                          descController.text.isEmpty ||
                          amountController.text.isEmpty) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('Please fill all fields'),
                            backgroundColor: Colors.red,
                          ),
                        );
                        return;
                      }
                      // TODO: Call API to create task
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Task created successfully!'),
                          backgroundColor: Colors.green,
                        ),
                      );
                      Navigator.pop(context);
                    },
                    child: const Text(
                      'Post Task',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
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
