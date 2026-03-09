import 'package:flutter/material.dart';
import '../../widgets/nav_item.dart';
import '../../widgets/top_actions.dart';
import '../../services/user_service.dart';
import 'change_password_screen.dart';

class SettingsScreen extends StatelessWidget {
  final String settingType;

  const SettingsScreen({super.key, required this.settingType});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F6FA),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 2,
        title: Text(
          _getTitle(),
          style: const TextStyle(
            color: Colors.black87,
            fontWeight: FontWeight.bold,
            fontSize: 24,
          ),
        ),
        actions: [
          ...topActions(context).map((w) => Builder(builder: (c) => Theme(data: Theme.of(c).copyWith(iconTheme: const IconThemeData(color: Colors.black87)), child: w))).toList(),
        ],
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.all(24.0),
            child: _buildContent(context),
          ),
        ),
      ),
    );
  }

  String _getTitle() {
    switch (settingType) {
      case 'notifications':
        return 'Notifications';
      case 'security':
        return 'Security';
      case 'help':
        return 'Help & Support';
      default:
        return 'Settings';
    }
  }

  Widget _buildContent(BuildContext context) {
    switch (settingType) {
      case 'notifications':
        return _buildNotificationsSettings();
      case 'security':
        return _buildSecuritySettings(context);
      case 'help':
        return _buildHelpSupport();
      case 'general':
        return _buildGeneralSettings(context);
      default:
        return _buildGeneralSettings(context);
    }
  }

  Widget _buildGeneralSettings(BuildContext context) {
    final name = UserService.userName ?? 'User Name';
    final email = UserService.userEmail ?? 'user@email.com';
    final memberSince = UserService.memberSince;
    final role = UserService.userRole == UserRole.taskProvider ? 'Task Provider' : 'Task User';

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Account',
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: Colors.black87,
          ),
        ),
        const SizedBox(height: 16),
        Card(
          elevation: 2,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: CircleAvatar(
                    backgroundColor: const Color(0xFF1E3A5F).withOpacity(0.1),
                    child: Text(name.isNotEmpty ? name[0].toUpperCase() : 'U'),
                  ),
                  title: Text(name, style: const TextStyle(fontWeight: FontWeight.bold)),
                  subtitle: Text(email),
                ),
                const SizedBox(height: 8),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text('Member since: $memberSince', style: const TextStyle(color: Colors.black54)),
                    Text(role, style: const TextStyle(color: Colors.black54)),
                  ],
                ),
                const SizedBox(height: 12),
                ElevatedButton(
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => const ChangePasswordScreen()),
                    );
                  },
                  child: const Text('Change Password'),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildNotificationsSettings() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Notification Preferences',
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: Colors.black87,
          ),
        ),
        const SizedBox(height: 24),
        Card(
          elevation: 2,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          child: Column(
            children: [
              SwitchListTile(
                title: const Text('Task Notifications'),
                subtitle: const Text('Get notified about new tasks'),
                value: true,
                onChanged: (value) {},
              ),
              const Divider(height: 1),
              SwitchListTile(
                title: const Text('Payment Notifications'),
                subtitle: const Text('Get notified about payments'),
                value: true,
                onChanged: (value) {},
              ),
              const Divider(height: 1),
              SwitchListTile(
                title: const Text('Email Notifications'),
                subtitle: const Text('Receive notifications via email'),
                value: false,
                onChanged: (value) {},
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildSecuritySettings(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Security Settings',
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: Colors.black87,
          ),
        ),
        const SizedBox(height: 24),
        Card(
          elevation: 2,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          child: Column(
            children: [
              ListTile(
                leading: const Icon(Icons.lock, color: Colors.blue),
                title: const Text('Change Password'),
                subtitle: const Text('Update your account password'),
                trailing: const Icon(Icons.chevron_right),
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => const ChangePasswordScreen(),
                    ),
                  );
                },
              ),
              const Divider(height: 1),
              ListTile(
                leading: const Icon(Icons.fingerprint, color: Colors.blue),
                title: const Text('Two-Factor Authentication'),
                subtitle: const Text('Add an extra layer of security'),
                trailing: Switch(
                  value: false,
                  onChanged: (value) {},
                ),
              ),
              const Divider(height: 1),
              ListTile(
                leading: const Icon(Icons.devices, color: Colors.blue),
                title: const Text('Active Sessions'),
                subtitle: const Text('Manage your active devices'),
                trailing: const Icon(Icons.chevron_right),
                onTap: () {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Active sessions feature coming soon!')),
                  );
                },
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildHelpSupport() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Help & Support',
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: Colors.black87,
          ),
        ),
        const SizedBox(height: 24),
        Card(
          elevation: 2,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          child: Column(
            children: [
              ListTile(
                leading: const Icon(Icons.help_outline, color: Colors.blue),
                title: const Text('FAQs'),
                subtitle: const Text('Frequently asked questions'),
                trailing: const Icon(Icons.chevron_right),
                onTap: () {
                  // TODO: Navigate to FAQs
                },
              ),
              const Divider(height: 1),
              ListTile(
                leading: const Icon(Icons.contact_support, color: Colors.blue),
                title: const Text('Contact Support'),
                subtitle: const Text('Get help from our support team'),
                trailing: const Icon(Icons.chevron_right),
                onTap: () {
                  // TODO: Navigate to contact support
                },
              ),
              const Divider(height: 1),
              ListTile(
                leading: const Icon(Icons.info_outline, color: Colors.blue),
                title: const Text('About TaskNest'),
                subtitle: const Text('Version 1.0.0'),
                trailing: const Icon(Icons.chevron_right),
                onTap: () {
                  // TODO: Show about dialog
                },
              ),
            ],
          ),
        ),
      ],
    );
  }
}
