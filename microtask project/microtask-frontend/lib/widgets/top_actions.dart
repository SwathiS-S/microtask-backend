import 'package:flutter/material.dart';
import '../screens/profile/profile_screen.dart';
import '../screens/auth/login_screen.dart';
import '../services/user_service.dart';

List<Widget> topActions(BuildContext context) {
  return [
    // Notification Icon
    IconButton(
      icon: const Icon(Icons.notifications_outlined, color: Colors.white),
      onPressed: () {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Notifications - Coming Soon')),
        );
      },
    ),
    
    // Profile avatar with Dropdown (profile / logout)
    PopupMenuButton<String>(
      icon: CircleAvatar(
        radius: 16,
        backgroundColor: Colors.white.withOpacity(0.2),
        child: Text(
          (UserService.userName ?? 'U').isNotEmpty ? (UserService.userName ?? 'U')[0].toUpperCase() : 'U',
          style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
      ),
      onSelected: (String value) {
        if (value == 'profile') {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const ProfileScreen()),
          );
        } else if (value == 'logout') {
          // Show confirmation dialog
          showDialog(
            context: context,
            builder: (context) => AlertDialog(
              title: const Text('Logout'),
              content: const Text('Are you sure you want to logout?'),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('Cancel'),
                ),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
                  onPressed: () {
                    UserService.clearUser();
                    Navigator.pushReplacement(
                      context,
                      MaterialPageRoute(builder: (_) => const LoginScreen()),
                    );
                  },
                  child: const Text('Logout', style: TextStyle(color: Colors.white)),
                ),
              ],
            ),
          );
        }
      },
      itemBuilder: (BuildContext context) => <PopupMenuEntry<String>>[
        const PopupMenuItem<String>(
          value: 'profile',
          child: Row(
            children: [
              Icon(Icons.person, size: 20),
              SizedBox(width: 8),
              Text('My Profile'),
            ],
          ),
        ),
        const PopupMenuDivider(),
        const PopupMenuItem<String>(
          value: 'logout',
          child: Row(
            children: [
              Icon(Icons.logout, size: 20, color: Colors.red),
              SizedBox(width: 8),
              Text('Logout', style: TextStyle(color: Colors.red)),
            ],
          ),
        ),
      ],
    ),
    const SizedBox(width: 8),
  ];
}
