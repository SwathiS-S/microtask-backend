import 'package:flutter/material.dart';
import '../../services/user_service.dart';
import '../../widgets/top_actions.dart';
import 'settings_screen.dart';

class AccountWindow extends StatelessWidget {
  final int initialIndex;

  const AccountWindow({super.key, this.initialIndex = 0});

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 3,
      initialIndex: initialIndex, // Settings/Profile/Notifications
      child: Scaffold(
        backgroundColor: const Color(0xFFF5F6FA),
        appBar: AppBar(
          backgroundColor: Colors.white,
          elevation: 2,
          title: const Text(
            'Account',
            style: TextStyle(
              color: Colors.black87,
              fontWeight: FontWeight.bold,
              fontSize: 24,
            ),
          ),
          actions: [
            ...topActions(context).map((w) => Builder(builder: (c) => Theme(data: Theme.of(c).copyWith(iconTheme: const IconThemeData(color: Colors.black87)), child: w))).toList(),
          ],
          bottom: const TabBar(
            labelColor: Colors.black87,
            indicatorColor: Colors.blue,
            tabs: [
              Tab(text: 'Settings'),
              Tab(text: 'Profile'),
              Tab(text: 'Notifications'),
            ],
          ),
        ),
        body: const TabBarView(
          children: [
            _SettingsTab(),
            _ProfileTab(),
            _NotificationsTab(),
          ],
        ),
      ),
    );
  }
}

class _SettingsTab extends StatelessWidget {
  const _SettingsTab();

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Settings',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            Card(
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              child: Column(
                children: [
                  ListTile(
                    leading: const Icon(Icons.lock, color: Colors.blue),
                    title: const Text('Security'),
                    subtitle: const Text('Change password & security options'),
                    trailing: const Icon(Icons.chevron_right),
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (_) => const SettingsScreen(settingType: 'security')),
                      );
                    },
                  ),
                  const Divider(height: 1),
                  ListTile(
                    leading: const Icon(Icons.notifications, color: Colors.blue),
                    title: const Text('Notifications'),
                    subtitle: const Text('Notification preferences'),
                    trailing: const Icon(Icons.chevron_right),
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (_) => const SettingsScreen(settingType: 'notifications')),
                      );
                    },
                  ),
                  const Divider(height: 1),
                  ListTile(
                    leading: const Icon(Icons.help_outline, color: Colors.blue),
                    title: const Text('Help & Support'),
                    subtitle: const Text('FAQs and contact support'),
                    trailing: const Icon(Icons.chevron_right),
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (_) => const SettingsScreen(settingType: 'help')),
                      );
                    },
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ProfileTab extends StatelessWidget {
  const _ProfileTab();

  @override
  Widget build(BuildContext context) {
    final userName = UserService.userName ?? 'User';
    return SafeArea(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          children: [
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10)],
              ),
              child: Column(
                children: [
                  CircleAvatar(
                    radius: 40,
                    backgroundColor: const Color(0xFF1E3A5F).withOpacity(0.1),
                    child: Text(
                      userName.trim().isNotEmpty ? userName.substring(0, 1).toUpperCase() : 'U',
                      style: const TextStyle(fontSize: 32, fontWeight: FontWeight.bold, color: Color(0xFF1E3A5F)),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text(userName, style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.black87)),
                  const SizedBox(height: 8),
                  Text(UserService.userEmail ?? 'user@email.com', style: const TextStyle(color: Colors.black54)),
                  const SizedBox(height: 12),
                  ElevatedButton(
                    onPressed: () {
                      Navigator.pushNamed(context, '/edit_profile');
                    },
                    child: const Text('Edit Profile'),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                gradient: const LinearGradient(colors: [Color(0xFF1976D2), Color(0xFF1565C0)]),
                borderRadius: BorderRadius.circular(16),
                boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.1), blurRadius: 10)],
              ),
              child: Column(
                children: [
                  const Text('Wallet Balance', style: TextStyle(fontSize: 18, color: Colors.white70)),
                  const SizedBox(height: 8),
                  Text('₹${UserService.walletBalance.toStringAsFixed(0)}', style: const TextStyle(fontSize: 36, fontWeight: FontWeight.bold, color: Colors.white)),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _NotificationsTab extends StatefulWidget {
  const _NotificationsTab();

  @override
  State<_NotificationsTab> createState() => _NotificationsTabState();
}

class _NotificationsTabState extends State<_NotificationsTab> {
  bool taskNotifications = true;
  bool paymentNotifications = true;
  bool emailNotifications = false;

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Notification Preferences', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
            const SizedBox(height: 16),
            Card(
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              child: Column(
                children: [
                  SwitchListTile(
                    title: const Text('Task Notifications'),
                    subtitle: const Text('Get notified about new tasks'),
                    value: taskNotifications,
                    onChanged: (v) => setState(() => taskNotifications = v),
                  ),
                  const Divider(height: 1),
                  SwitchListTile(
                    title: const Text('Payment Notifications'),
                    subtitle: const Text('Get notified about payments'),
                    value: paymentNotifications,
                    onChanged: (v) => setState(() => paymentNotifications = v),
                  ),
                  const Divider(height: 1),
                  SwitchListTile(
                    title: const Text('Email Notifications'),
                    subtitle: const Text('Receive notifications via email'),
                    value: emailNotifications,
                    onChanged: (v) => setState(() => emailNotifications = v),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
