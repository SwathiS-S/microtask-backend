import 'package:flutter/material.dart';
import '../../services/api_service.dart';
import '../../services/user_service.dart';
import 'package:intl/intl.dart';

class NotificationScreen extends StatefulWidget {
  const NotificationScreen({super.key});

  @override
  State<NotificationScreen> createState() => _NotificationScreenState();
}

class _NotificationScreenState extends State<NotificationScreen> {
  List<dynamic> _notifications = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _fetchNotifications();
  }

  Future<void> _fetchNotifications() async {
    setState(() => _isLoading = true);
    try {
      final res = await ApiService.get('/notifications/${UserService.userId}');
      if (res != null && res['success']) {
        setState(() {
          _notifications = res['notifications'];
        });
      }
    } catch (e) {
      debugPrint('Error fetching notifications: $e');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _markAsRead(String id) async {
    try {
      await ApiService.post('/notifications/$id/read', {});
      _fetchNotifications();
    } catch (e) {
      debugPrint('Error marking as read: $e');
    }
  }

  Future<void> _markAllAsRead() async {
    try {
      await ApiService.post('/notifications/read-all/${UserService.userId}', {});
      _fetchNotifications();
    } catch (e) {
      debugPrint('Error marking all as read: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F6FA),
      appBar: AppBar(
        backgroundColor: const Color(0xFF1E3A5F),
        title: const Text('Notifications', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        actions: [
          if (_notifications.any((n) => !n['isRead']))
            TextButton(
              onPressed: _markAllAsRead,
              child: const Text('Mark all read', style: TextStyle(color: Colors.white70)),
            ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _fetchNotifications,
              child: _notifications.isEmpty
                  ? const Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.notifications_none, size: 64, color: Colors.grey),
                          SizedBox(height: 16),
                          Text('No notifications yet', style: TextStyle(color: Colors.grey, fontSize: 16)),
                        ],
                      ),
                    )
                  : ListView.builder(
                      itemCount: _notifications.length,
                      itemBuilder: (context, index) {
                        final notification = _notifications[index];
                        final bool isRead = notification['isRead'] ?? false;
                        final date = DateTime.parse(notification['createdAt']);

                        return Container(
                          margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                          decoration: BoxDecoration(
                            color: isRead ? Colors.white : const Color(0xFFE3F2FD),
                            borderRadius: BorderRadius.circular(12),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withOpacity(0.05),
                                blurRadius: 10,
                                offset: const Offset(0, 4),
                              ),
                            ],
                          ),
                          child: ListTile(
                            contentPadding: const EdgeInsets.all(16),
                            leading: CircleAvatar(
                              backgroundColor: _getNotificationColor(notification['type']).withOpacity(0.1),
                              child: Icon(
                                _getNotificationIcon(notification['type']),
                                color: _getNotificationColor(notification['type']),
                              ),
                            ),
                            title: Text(
                              notification['title'],
                              style: TextStyle(
                                fontWeight: isRead ? FontWeight.w600 : FontWeight.bold,
                                fontSize: 16,
                              ),
                            ),
                            subtitle: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const SizedBox(height: 4),
                                Text(notification['message']),
                                const SizedBox(height: 8),
                                Text(
                                  DateFormat('MMM dd, hh:mm a').format(date),
                                  style: const TextStyle(fontSize: 12, color: Colors.grey),
                                ),
                              ],
                            ),
                            onTap: () {
                              if (!isRead) _markAsRead(notification['_id']);
                              if (notification['taskId'] != null) {
                                // Navigate to task detail (requires task object fetch or simplified navigation)
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(content: Text('Navigating to task details...'))
                                );
                              }
                            },
                          ),
                        );
                      },
                    ),
            ),
    );
  }

  IconData _getNotificationIcon(String type) {
    switch (type) {
      case 'APPLICATION_RECEIVED': return Icons.person_add;
      case 'APPLICATION_APPROVED': return Icons.check_circle;
      case 'APPLICATION_REJECTED': return Icons.cancel;
      case 'UPDATE_SUBMITTED': return Icons.update;
      case 'WORK_SUBMITTED': return Icons.work;
      case 'PAYMENT_RELEASED': return Icons.account_balance_wallet;
      case 'DISPUTE_RESOLVED': return Icons.gavel;
      default: return Icons.notifications;
    }
  }

  Color _getNotificationColor(String type) {
    switch (type) {
      case 'APPLICATION_APPROVED':
      case 'PAYMENT_RELEASED':
      case 'DISPUTE_RESOLVED': return Colors.green;
      case 'APPLICATION_REJECTED': return Colors.red;
      case 'APPLICATION_RECEIVED': return Colors.blue;
      case 'UPDATE_SUBMITTED': return Colors.orange;
      case 'WORK_SUBMITTED': return Colors.purple;
      default: return Colors.grey;
    }
  }
}
