import 'package:flutter/material.dart';
import '../../theme/app_theme.dart';
import '../../services/api_service.dart';
import '../../services/user_service.dart';
import '../home/home_screen.dart';
import '../home/business_lead_screen.dart';
import 'register_screen.dart';

class LoginScreen extends StatefulWidget {
  final UserRole? selectedRole;
  const LoginScreen({super.key, this.selectedRole});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final TextEditingController email = TextEditingController();
  final TextEditingController password = TextEditingController();
  bool isLoading = false;
  String? errorMessage;
  late UserRole selectedRole;

  @override
  void initState() {
    super.initState();
    selectedRole = widget.selectedRole ?? UserRole.taskUser;
  }

  Future<void> _handleLogin() async {
    if (email.text.isEmpty || password.text.isEmpty) {
      setState(() => errorMessage = "Please enter email and password");
      return;
    }

    setState(() {
      isLoading = true;
      errorMessage = null;
    });

    try {
      final response = await ApiService.post("/users/login", {
        "email": email.text.trim(),
        "password": password.text,
        "role": selectedRole == UserRole.taskProvider ? "taskProvider" : "taskUser",
      });

      setState(() => isLoading = false);

      if (response != null && (response['success'] == true || response['token'] != null)) {
        UserService.setUser(
          userId: response['userId']?.toString() ?? 'USR-${DateTime.now().millisecondsSinceEpoch}',
          userName: response['name']?.toString() ?? email.text.split('@')[0],
          userEmail: email.text.trim(),
          userPassword: password.text,
          userRole: selectedRole,
        );

        if (mounted) {
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(
              builder: (_) => selectedRole == UserRole.taskProvider
                  ? const BusinessLeadScreen()
                  : const HomeScreen(),
            ),
          );
        }
      } else {
        setState(() => errorMessage = response?['message'] ?? 'Login failed');
      }
    } catch (e) {
      setState(() {
        isLoading = false;
        errorMessage = 'Connection error. Please try again.';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final bool isWide = MediaQuery.of(context).size.width > 800;

    return Scaffold(
      backgroundColor: AppTheme.cream,
      body: isWide ? _buildWideLayout() : _buildMobileLayout(),
    );
  }

  Widget _buildWideLayout() {
    return Row(
      children: [
        // Left Branding Panel
        Expanded(
          flex: 1,
          child: Container(
            color: AppTheme.navy,
            padding: const EdgeInsets.all(60),
            child: _buildBrandingContent(),
          ),
        ),
        // Right Form Panel
        Expanded(
          flex: 1,
          child: Container(
            color: AppTheme.cream,
            child: Center(
              child: Container(
                constraints: const BoxConstraints(maxWidth: 400),
                padding: const EdgeInsets.all(40),
                child: _buildLoginForm(),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildMobileLayout() {
    return SingleChildScrollView(
      child: Column(
        children: [
          Container(
            width: double.infinity,
            padding: const EdgeInsets.fromLTRB(24, 60, 24, 40),
            decoration: const BoxDecoration(
              color: AppTheme.navy,
              borderRadius: BorderRadius.only(
                bottomLeft: Radius.circular(30),
                bottomRight: Radius.circular(30),
              ),
            ),
            child: Column(
              children: [
                _buildLogo(),
                const SizedBox(height: 24),
                const Text(
                  'Welcome Back',
                  style: TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Sign in to your TaskNest account',
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.white.withOpacity(0.7),
                  ),
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(24),
            child: _buildLoginForm(),
          ),
        ],
      ),
    );
  }

  Widget _buildBrandingContent() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        _buildLogo(),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'India\'s trusted\nfreelance task\nplatform',
              style: TextStyle(
                fontSize: 36,
                fontWeight: FontWeight.bold,
                color: Colors.white,
                height: 1.2,
              ),
            ),
            const SizedBox(height: 24),
            Container(width: 40, height: 3, color: AppTheme.gold),
            const SizedBox(height: 24),
            Text(
              'Secure escrow payments powered by Razorpay. Post tasks, find workers and get paid safely.',
              style: TextStyle(
                fontSize: 16,
                color: Colors.white.withOpacity(0.65),
                height: 1.6,
              ),
            ),
          ],
        ),
        Text(
          '© 2026 TaskNest · teamtasknest@gmail.com',
          style: TextStyle(
            fontSize: 12,
            color: Colors.white.withOpacity(0.3),
          ),
        ),
      ],
    );
  }

  Widget _buildLogo() {
    return Row(
      children: [
        Container(
          width: 36,
          height: 36,
          decoration: BoxDecoration(
            color: AppTheme.gold,
            borderRadius: BorderRadius.circular(9),
          ),
          child: const Center(
            child: Icon(Icons.task_alt, color: Colors.white, size: 20),
          ),
        ),
        const SizedBox(width: 12),
        const Text(
          'TaskNest',
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
      ],
    );
  }

  Widget _buildLoginForm() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('Sign in', style: AppTheme.heading2),
        const SizedBox(height: 8),
        const Text('Enter your credentials to continue', style: AppTheme.bodyMuted),
        const SizedBox(height: 32),
        
        if (errorMessage != null) ...[
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: AppTheme.error.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(
              errorMessage!,
              style: const TextStyle(color: AppTheme.error, fontSize: 13),
            ),
          ),
          const SizedBox(height: 20),
        ],

        // Role Selector (Matching Web Style)
        Row(
          children: [
            Expanded(
              child: _buildRoleOption(UserRole.taskUser, 'I\'m a Worker'),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildRoleOption(UserRole.taskProvider, 'I\'m a Provider'),
            ),
          ],
        ),
        const SizedBox(height: 24),

        const Text('EMAIL', style: AppTheme.small),
        const SizedBox(height: 8),
        TextField(
          controller: email,
          keyboardType: TextInputType.emailAddress,
          decoration: const InputDecoration(hintText: 'your@email.com'),
        ),
        const SizedBox(height: 20),
        
        const Text('PASSWORD', style: AppTheme.small),
        const SizedBox(height: 8),
        TextField(
          controller: password,
          obscureText: true,
          decoration: const InputDecoration(hintText: 'Enter password'),
        ),
        const SizedBox(height: 32),

        SizedBox(
          width: double.infinity,
          height: 54,
          child: ElevatedButton(
            onPressed: isLoading ? null : _handleLogin,
            style: AppTheme.goldButton,
            child: isLoading
                ? const SizedBox(
                    height: 20,
                    width: 20,
                    child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                  )
                : const Text('Login', style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold)),
          ),
        ),
        
        const SizedBox(height: 24),
        Center(
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Text('Don\'t have an account? ', style: AppTheme.bodyMuted),
              GestureDetector(
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const RegisterScreen()),
                  );
                },
                child: const Text(
                  'Register',
                  style: TextStyle(color: AppTheme.gold, fontWeight: FontWeight.bold),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildRoleOption(UserRole role, String label) {
    final bool isSelected = selectedRole == role;
    return GestureDetector(
      onTap: () => setState(() => selectedRole = role),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(
          color: isSelected ? AppTheme.navy : Colors.white,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: isSelected ? AppTheme.navy : AppTheme.border),
        ),
        child: Center(
          child: Text(
            label,
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: isSelected ? Colors.white : AppTheme.textMuted,
            ),
          ),
        ),
      ),
    );
  }
}
