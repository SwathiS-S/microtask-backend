import 'package:flutter/material.dart';
import '../../theme/app_theme.dart';
import '../auth/login_screen.dart';

class LandingScreen extends StatelessWidget {
  const LandingScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.cream,
      body: Stack(
        children: [
          // Background Branding Panel (Navy)
          Container(
            height: MediaQuery.of(context).size.height * 0.45,
            width: double.infinity,
            decoration: const BoxDecoration(
              color: AppTheme.navy,
              borderRadius: BorderRadius.only(
                bottomLeft: Radius.circular(40),
                bottomRight: Radius.circular(40),
              ),
            ),
            child: SafeArea(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  // Logo
                  Container(
                    width: 60,
                    height: 60,
                    decoration: BoxDecoration(
                      color: AppTheme.gold,
                      borderRadius: BorderRadius.circular(15),
                    ),
                    child: const Center(
                      child: Icon(
                        Icons.task_alt,
                        color: Colors.white,
                        size: 36,
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    'TaskNest',
                    style: TextStyle(
                      fontSize: 32,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'India\'s trusted freelance task platform',
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.white.withOpacity(0.7),
                    ),
                  ),
                ],
              ),
            ),
          ),

          // Content Area (Cream Form Panel style)
          Align(
            alignment: Alignment.bottomCenter,
            child: Container(
              height: MediaQuery.of(context).size.height * 0.6,
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 40),
              decoration: const BoxDecoration(
                color: AppTheme.cream,
                borderRadius: BorderRadius.only(
                  topLeft: Radius.circular(40),
                  topRight: Radius.circular(40),
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Welcome to TaskNest',
                    style: AppTheme.heading1,
                  ),
                  const SizedBox(height: 12),
                  const Text(
                    'Secure escrow payments powered by Razorpay. Post tasks, find workers and get paid safely.',
                    style: AppTheme.bodyMuted,
                  ),
                  const SizedBox(height: 32),
                  
                  // Feature List
                  _buildFeature(Icons.security, 'Razorpay Escrow Protection'),
                  const SizedBox(height: 16),
                  _buildFeature(Icons.payments_outlined, 'Workers earn 80% per task'),
                  const SizedBox(height: 16),
                  _buildFeature(Icons.verified_outlined, 'Free to register, cancel anytime'),
                  
                  const Spacer(),
                  
                  // Get Started Button
                  SizedBox(
                    width: double.infinity,
                    height: 56,
                    child: ElevatedButton(
                      onPressed: () {
                        Navigator.pushReplacement(
                          context,
                          MaterialPageRoute(builder: (_) => const LoginScreen()),
                        );
                      },
                      style: AppTheme.goldButton,
                      child: const Text(
                        'Get Started',
                        style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFeature(IconData icon, String text) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: AppTheme.navy.withOpacity(0.05),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(icon, color: AppTheme.navy, size: 20),
        ),
        const SizedBox(width: 16),
        Text(text, style: AppTheme.body),
      ],
    );
  }
}
