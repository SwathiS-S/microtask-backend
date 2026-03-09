import 'package:flutter/material.dart';
import '../auth/login_screen.dart';

class LandingScreen extends StatelessWidget {
  const LandingScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [Color(0xFF1E3A5F), Color(0xFF2C5282), Color(0xFF1976D2)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: SafeArea(
          child: SingleChildScrollView(
            child: Padding(
              padding: const EdgeInsets.all(24.0),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const SizedBox(height: 40),
                  
                  // Logo/Icon Section
                  Container(
                    padding: const EdgeInsets.all(30),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.2),
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: Colors.white.withOpacity(0.3),
                        width: 3,
                      ),
                    ),
                    child: const Icon(
                      Icons.task_alt,
                      size: 80,
                      color: Colors.white,
                    ),
                  ),
                  
                  const SizedBox(height: 40),
                  
                  // App Name
                  const Text(
                    'TaskNest',
                    style: TextStyle(
                      fontSize: 42,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                      letterSpacing: 2,
                    ),
                  ),
                  
                  const SizedBox(height: 16),
                  
                  // Tagline
                  const Text(
                    'Your Gateway to Micro-Task Success',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 20,
                      color: Colors.white70,
                      fontWeight: FontWeight.w300,
                    ),
                  ),
                  
                  const SizedBox(height: 60),
                  
                  // Features Section
                  _FeatureCard(
                    icon: Icons.work_outline,
                    title: 'Find Tasks',
                    description: 'Browse and accept tasks that match your skills',
                  ),
                  
                  const SizedBox(height: 20),
                  
                  _FeatureCard(
                    icon: Icons.account_balance_wallet,
                    title: 'Earn Money',
                    description: 'Complete tasks and get paid directly to your wallet',
                  ),
                  
                  const SizedBox(height: 20),
                  
                  // Focus this card on wallet/earnings instead of task creation
                  _FeatureCard(
                    icon: Icons.insights,
                    title: 'Track Your Wallet',
                    description: 'See your earnings grow with a clear, simple wallet view',
                  ),
                  
                  const SizedBox(height: 50),
                  
                  // Get Started Button with gradient effect
                  Container(
                    width: double.infinity,
                    height: 60,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.3),
                          blurRadius: 15,
                          offset: const Offset(0, 8),
                        ),
                      ],
                    ),
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.white,
                        foregroundColor: const Color(0xFF1E3A5F),
                        elevation: 0,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                      ),
                      onPressed: () {
                        Navigator.pushReplacement(
                          context,
                          MaterialPageRoute(
                            builder: (_) => const LoginScreen(),
                          ),
                        );
                      },
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: const [
                          Text(
                            'Get Started',
                            style: TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                              letterSpacing: 1.2,
                            ),
                          ),
                          SizedBox(width: 12),
                          Icon(
                            Icons.arrow_forward,
                            size: 24,
                          ),
                        ],
                      ),
                    ),
                  ),
                  
                  const SizedBox(height: 24),
                  
                  // Additional Info with icons
                  Wrap(
                    spacing: 20,
                    runSpacing: 12,
                    alignment: WrapAlignment.center,
                    children: [
                      _InfoItem(
                        icon: Icons.verified_user,
                        text: 'Secure',
                      ),
                      _InfoItem(
                        icon: Icons.payment,
                        text: 'Fast Payments',
                      ),
                      _InfoItem(
                        icon: Icons.people,
                        text: 'Trusted',
                      ),
                    ],
                  ),
                  
                  const SizedBox(height: 40),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _FeatureCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String description;

  const _FeatureCard({
    required this.icon,
    required this.title,
    required this.description,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.15),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: Colors.white.withOpacity(0.2),
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  Colors.white.withOpacity(0.3),
                  Colors.white.withOpacity(0.2),
                ],
              ),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(
              icon,
              color: Colors.white,
              size: 32,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  description,
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.white.withOpacity(0.9),
                    height: 1.3,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _InfoItem extends StatelessWidget {
  final IconData icon;
  final String text;

  const _InfoItem({
    required this.icon,
    required this.text,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(
          icon,
          color: Colors.white.withOpacity(0.8),
          size: 18,
        ),
        const SizedBox(width: 6),
        Text(
          text,
          style: TextStyle(
            color: Colors.white.withOpacity(0.8),
            fontSize: 13,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }
}
