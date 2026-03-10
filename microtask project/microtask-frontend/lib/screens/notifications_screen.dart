import 'package:flutter/material.dart';
import '../../services/api_service.dart';
import '../../services/user_service.dart';
import 'package:intl/intl.dart';

class NotificationsScreen extends StatefulWidget {
  const NotificationsScreen({super.key});

  @override
  State<NotificationsScreen> createState() => _NotificationsScreenState();
}

class _NotificationsScreenState extends State<NotificationsScreen> {
  bool _isLoading = false;
  List<dynamic> _notifications = [];

  @override
  void initState() {
    super.initState();
    _loadNotifications();
  }

  Future<void> _loadNotifications() async {
    setState(() => _isLoading = true);
    try {
      final res = await ApiService.get('/notifications/${UserService.userId}');
      if (res != null && res['success']) {
        setState(() {
          _notifications = res['notifications'];
        });
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error loading notifications: $e')));
    } finally {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Notifications')),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _notifications.isEmpty
              ? const Center(child: Text('No notifications.'))
              : RefreshIndicator(
                  onRefresh: _loadNotifications,
                  child: ListView.builder(
                    itemCount: _notifications.length,
                    itemBuilder: (context, index) {
                      final item = _notifications[index];
                      return _buildNotificationItem(item);
                    },
                  ),
                ),
    );
  }

  Widget _buildNotificationItem(Map<String, dynamic> item) {
    final title = item['title'] ?? 'Notification';
    final message = item['message'] ?? '';
    final createdAt = DateTime.parse(item['createdAt']);

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: ListTile(
        title: Text(title, style: const TextStyle(fontWeight: FontWeight.bold)),
        subtitle: Text('$message\n${DateFormat.yMMMd().add_jm().format(createdAt)}'),
        isThreeLine: true,
      ),
    );
  }
}
