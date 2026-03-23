import 'package:flutter/material.dart';
import '../../theme/app_theme.dart';
import '../../services/api_service.dart';
import '../../services/user_service.dart';
import 'task_detail_screen.dart';

class TaskListScreen extends StatefulWidget {
  const TaskListScreen({super.key});

  @override
  State<TaskListScreen> createState() => _TaskListScreenState();
}

class _TaskListScreenState extends State<TaskListScreen> {
  List<dynamic> allTasks = [];
  List<dynamic> filteredTasks = [];
  bool isLoading = true;
  String searchQuery = "";
  String selectedCategory = "All";

  final List<String> categories = ["All", "Web Development", "Content Writing", "Data Entry", "Design", "Marketing"];

  @override
  void initState() {
    super.initState();
    _fetchTasks();
  }

  Future<void> _fetchTasks() async {
    setState(() => isLoading = true);
    final response = await ApiService.get("/tasks/all");
    
    if (mounted) {
      setState(() {
        allTasks = response ?? [];
        _applyFilters();
        isLoading = false;
      });
    }
  }

  void _applyFilters() {
    setState(() {
      filteredTasks = allTasks.where((task) {
        final matchesSearch = task['title'].toString().toLowerCase().contains(searchQuery.toLowerCase()) ||
                             task['skillset'].toString().toLowerCase().contains(searchQuery.toLowerCase());
        final matchesCategory = selectedCategory == "All" || 
                               task['skillset'].toString().toLowerCase() == selectedCategory.toLowerCase();
        return matchesSearch && matchesCategory;
      }).toList();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.cream,
      appBar: AppBar(
        title: const Text('Find Tasks'),
        actions: [
          IconButton(onPressed: _fetchTasks, icon: const Icon(Icons.refresh)),
        ],
      ),
      body: Column(
        children: [
          // Search and Categories Header
          Container(
            padding: const EdgeInsets.fromLTRB(24, 20, 24, 24),
            color: Colors.white,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Find your next task', style: AppTheme.heading2),
                const SizedBox(height: 20),
                
                // Search Bar (Joined Input & Button style)
                Container(
                  decoration: BoxDecoration(
                    color: Colors.white,
                    border: Border.all(color: AppTheme.border, width: 1.5),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    children: [
                      const Padding(
                        padding: EdgeInsets.symmetric(horizontal: 12),
                        child: Icon(Icons.search, color: AppTheme.textMuted, size: 20),
                      ),
                      Expanded(
                        child: TextField(
                          onChanged: (val) {
                            searchQuery = val;
                            _applyFilters();
                          },
                          decoration: const InputDecoration(
                            hintText: 'Search tasks...',
                            border: InputBorder.none,
                            enabledBorder: InputBorder.none,
                            focusedBorder: InputBorder.none,
                            contentPadding: EdgeInsets.symmetric(vertical: 12),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                
                const SizedBox(height: 20),
                
                // Category Chips
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: categories.map((cat) {
                      final isSelected = selectedCategory == cat;
                      return Padding(
                        padding: const EdgeInsets.only(right: 8),
                        child: ChoiceChip(
                          label: Text(cat),
                          selected: isSelected,
                          onSelected: (selected) {
                            setState(() {
                              selectedCategory = cat;
                              _applyFilters();
                            });
                          },
                          selectedColor: AppTheme.navy,
                          labelStyle: TextStyle(
                            color: isSelected ? Colors.white : AppTheme.textMuted,
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                          ),
                          backgroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(20),
                            side: BorderSide(color: isSelected ? AppTheme.navy : AppTheme.border),
                          ),
                        ),
                      );
                    }).toList(),
                  ),
                ),
              ],
            ),
          ),

          // Task Grid
          Expanded(
            child: isLoading
                ? const Center(child: CircularProgressIndicator())
                : filteredTasks.isEmpty
                    ? const Center(child: Text('No tasks found matching your criteria'))
                    : GridView.builder(
                        padding: const EdgeInsets.all(24),
                        gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: MediaQuery.of(context).size.width > 600 ? 2 : 1,
                          childAspectRatio: 1.4,
                          crossAxisSpacing: 20,
                          mainAxisSpacing: 20,
                        ),
                        itemCount: filteredTasks.length,
                        itemBuilder: (context, index) {
                          final task = filteredTasks[index];
                          return _buildTaskCard(task);
                        },
                      ),
          ),
        ],
      ),
    );
  }

  Widget _buildTaskCard(Map<String, dynamic> task) {
    return GestureDetector(
      onTap: () => Navigator.push(
        context, 
        MaterialPageRoute(builder: (_) => TaskDetailScreen(taskId: task['_id']))
      ),
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: AppTheme.cardDecoration,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: AppTheme.gold.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(
                    task['skillset'] ?? 'General',
                    style: const TextStyle(color: AppTheme.gold, fontSize: 11, fontWeight: FontWeight.bold),
                  ),
                ),
                Text(
                  '₹${task['amount']}',
                  style: const TextStyle(fontWeight: FontWeight.w800, color: AppTheme.navy, fontSize: 18),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Text(
              task['title'] ?? 'Untitled Task',
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                const Icon(Icons.location_on_outlined, size: 14, color: AppTheme.textMuted),
                const SizedBox(width: 4),
                Text(task['location'] ?? 'Remote', style: AppTheme.small),
                const SizedBox(width: 16),
                const Icon(Icons.timer_outlined, size: 14, color: AppTheme.textMuted),
                const SizedBox(width: 4),
                Text('${task['duration'] ?? "5"} Days', style: AppTheme.small),
              ],
            ),
            const Spacer(),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () => Navigator.push(
                  context, 
                  MaterialPageRoute(builder: (_) => TaskDetailScreen(taskId: task['_id']))
                ),
                style: AppTheme.primaryButton.copyWith(
                  padding: MaterialStateProperty.all(const EdgeInsets.symmetric(vertical: 10)),
                ),
                child: const Text('View Details', style: TextStyle(fontSize: 13)),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
