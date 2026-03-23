import 'package:flutter/material.dart';
import '../../theme/app_theme.dart';
import 'package:url_launcher/url_launcher.dart';

class LegalScreen extends StatelessWidget {
  const LegalScreen({super.key});

  Future<void> _launchUrl(String url) async {
    final Uri uri = Uri.parse(url);
    if (!await launchUrl(uri)) {
      throw Exception('Could not launch $url');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.cream,
      appBar: AppBar(title: const Text('Legal & Policies')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Legal Information', style: AppTheme.heading2),
            const SizedBox(height: 8),
            const Text('Transparency and security for our users', style: AppTheme.bodyMuted),
            const SizedBox(height: 32),

            _buildLegalCard(
              context,
              'Terms of Service',
              'Rules for using TaskNest platform',
              Icons.description_outlined,
              () => _launchUrl('https://tasknest.com/terms'),
            ),
            const SizedBox(height: 16),
            _buildLegalCard(
              context,
              'Privacy Policy',
              'How we protect your data',
              Icons.privacy_tip_outlined,
              () => _launchUrl('https://tasknest.com/privacy'),
            ),
            const SizedBox(height: 16),
            _buildLegalCard(
              context,
              'Refund Policy',
              'Escrow and cancellation rules',
              Icons.assignment_return_outlined,
              () => _launchUrl('https://tasknest.com/refund'),
            ),
            const SizedBox(height: 16),
            _buildLegalCard(
              context,
              'Contact Us',
              'teamtasknest@gmail.com',
              Icons.email_outlined,
              () => _launchUrl('mailto:teamtasknest@gmail.com'),
            ),
            
            const SizedBox(height: 40),
            Center(
              child: Text(
                '© 2026 TaskNest · All Rights Reserved',
                style: AppTheme.small,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLegalCard(BuildContext context, String title, String subtitle, IconData icon, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: AppTheme.cardDecoration,
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppTheme.navy.withOpacity(0.05),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(icon, color: AppTheme.navy, size: 24),
            ),
            const SizedBox(width: 20),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                  const SizedBox(height: 4),
                  Text(subtitle, style: AppTheme.bodyMuted),
                ],
              ),
            ),
            const Icon(Icons.chevron_right, color: AppTheme.textMuted),
          ],
        ),
      ),
    );
  }
}
