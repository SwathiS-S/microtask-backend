import 'package:flutter/material.dart';
import 'dart:async';
import '../../theme/app_theme.dart';
import '../../services/api_service.dart';
import '../../services/user_service.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final TextEditingController name = TextEditingController();
  final TextEditingController email = TextEditingController();
  final TextEditingController phone = TextEditingController();
  final TextEditingController password = TextEditingController();
  final TextEditingController otp = TextEditingController();

  bool isLoading = false;
  bool isOtpSent = false;
  bool isVerified = false;
  String? errorMessage;
  UserRole selectedRole = UserRole.taskUser;

  int resendTimer = 60;
  Timer? timer;

  void _startTimer() {
    resendTimer = 60;
    timer?.cancel();
    timer = Timer.periodic(const Duration(seconds: 1), (t) {
      if (resendTimer > 0) {
        setState(() => resendTimer--);
      } else {
        t.cancel();
      }
    });
  }

  Future<void> _sendOtp() async {
    if (email.text.isEmpty || !email.text.contains('@')) {
      setState(() => errorMessage = "Please enter a valid email");
      return;
    }

    setState(() {
      isLoading = true;
      errorMessage = null;
    });

    try {
      final response = await ApiService.post("/users/send-otp", {"email": email.text.trim()});
      setState(() => isLoading = false);

      if (response != null && response['success'] == true) {
        setState(() => isOtpSent = true);
        _startTimer();
      } else {
        setState(() => errorMessage = response?['message'] ?? 'Failed to send OTP');
      }
    } catch (e) {
      setState(() {
        isLoading = false;
        errorMessage = 'Connection error. Please try again.';
      });
    }
  }

  Future<void> _verifyEmail() async {
    if (otp.text.isEmpty) {
      setState(() => errorMessage = "Please enter the OTP");
      return;
    }

    setState(() {
      isLoading = true;
      errorMessage = null;
    });

    try {
      final response = await ApiService.post("/users/verify-email", {
        "email": email.text.trim(),
        "otp": otp.text.trim(),
      });
      setState(() => isLoading = false);

      if (response != null && response['success'] == true) {
        setState(() => isVerified = true);
      } else {
        setState(() => errorMessage = response?['message'] ?? 'Verification failed');
      }
    } catch (e) {
      setState(() {
        isLoading = false;
        errorMessage = 'Connection error. Please try again.';
      });
    }
  }

  Future<void> _handleRegister() async {
    if (!isVerified) {
      setState(() => errorMessage = "Please verify your email first");
      return;
    }
    if (name.text.isEmpty || phone.text.isEmpty || password.text.isEmpty) {
      setState(() => errorMessage = "All fields are required");
      return;
    }

    setState(() {
      isLoading = true;
      errorMessage = null;
    });

    try {
      final response = await ApiService.post("/users/register", {
        "name": name.text.trim(),
        "email": email.text.trim(),
        "phone": phone.text.trim(),
        "password": password.text,
        "role": selectedRole == UserRole.taskProvider ? "taskProvider" : "taskUser",
      });

      setState(() => isLoading = false);

      if (response != null && response['success'] == true) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Registration successful! Please login.')),
          );
          Navigator.pop(context);
        }
      } else {
        setState(() => errorMessage = response?['message'] ?? 'Registration failed');
      }
    } catch (e) {
      setState(() {
        isLoading = false;
        errorMessage = 'Connection error. Please try again.';
      });
    }
  }

  @override
  void dispose() {
    timer?.cancel();
    super.dispose();
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
        Expanded(
          flex: 1,
          child: Container(
            color: AppTheme.navy,
            padding: const EdgeInsets.all(60),
            child: _buildBrandingContent(),
          ),
        ),
        Expanded(
          flex: 1,
          child: Container(
            color: AppTheme.cream,
            child: Center(
              child: Container(
                constraints: const BoxConstraints(maxWidth: 400),
                padding: const EdgeInsets.all(40),
                child: _buildRegisterForm(),
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
                  'Create Account',
                  style: TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Join our platform and start earning',
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
            child: _buildRegisterForm(),
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
              'Join India\'s\nlargest micro-task\nnetwork',
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
              'Start your journey today. Join thousands of workers earning safely with Razorpay protection.',
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

  Widget _buildRegisterForm() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            IconButton(
              onPressed: () => Navigator.pop(context),
              icon: const Icon(Icons.arrow_back, color: AppTheme.navy),
              padding: EdgeInsets.zero,
              constraints: const BoxConstraints(),
            ),
            const SizedBox(width: 12),
            const Text('Register', style: AppTheme.heading2),
          ],
        ),
        const SizedBox(height: 8),
        const Text('Join our community today', style: AppTheme.bodyMuted),
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

        Row(
          children: [
            Expanded(child: _buildRoleOption(UserRole.taskUser, 'Worker')),
            const SizedBox(width: 12),
            Expanded(child: _buildRoleOption(UserRole.taskProvider, 'Provider')),
          ],
        ),
        const SizedBox(height: 24),

        _buildLabel('FULL NAME'),
        TextField(controller: name, decoration: const InputDecoration(hintText: 'Your name')),
        const SizedBox(height: 16),
        
        _buildLabel('EMAIL'),
        Row(
          children: [
            Expanded(
              child: TextField(
                controller: email,
                enabled: !isVerified,
                decoration: const InputDecoration(hintText: 'your@email.com'),
              ),
            ),
            if (!isVerified) ...[
              const SizedBox(width: 8),
              SizedBox(
                height: 50,
                child: ElevatedButton(
                  onPressed: isLoading ? null : _sendOtp,
                  style: AppTheme.primaryButton.copyWith(
                    padding: MaterialStateProperty.all(const EdgeInsets.symmetric(horizontal: 16)),
                  ),
                  child: Text(isOtpSent ? 'Resend' : 'Send OTP', style: const TextStyle(fontSize: 12)),
                ),
              ),
            ],
          ],
        ),
        
        if (isOtpSent && !isVerified) ...[
          const SizedBox(height: 16),
          _buildLabel('ENTER OTP'),
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: otp,
                  decoration: const InputDecoration(hintText: '6-digit code'),
                ),
              ),
              const SizedBox(width: 8),
              SizedBox(
                height: 50,
                child: ElevatedButton(
                  onPressed: isLoading ? null : _verifyEmail,
                  style: AppTheme.goldButton.copyWith(
                    padding: MaterialStateProperty.all(const EdgeInsets.symmetric(horizontal: 16)),
                  ),
                  child: const Text('Verify', style: TextStyle(fontSize: 12)),
                ),
              ),
            ],
          ),
          if (resendTimer > 0)
            Padding(
              padding: const EdgeInsets.only(top: 8),
              child: Text('Resend in ${resendTimer}s', style: AppTheme.small),
            ),
        ],

        if (isVerified)
          const Padding(
            padding: EdgeInsets.only(top: 8),
            child: Row(
              children: [
                Icon(Icons.verified, color: AppTheme.success, size: 16),
                SizedBox(width: 8),
                Text('Email Verified', style: TextStyle(color: AppTheme.success, fontSize: 13, fontWeight: FontWeight.bold)),
              ],
            ),
          ),

        const SizedBox(height: 16),
        _buildLabel('PHONE'),
        TextField(controller: phone, decoration: const InputDecoration(hintText: 'Enter phone number')),
        const SizedBox(height: 16),
        
        _buildLabel('PASSWORD'),
        TextField(controller: password, obscureText: true, decoration: const InputDecoration(hintText: 'Create password')),
        const SizedBox(height: 32),

        SizedBox(
          width: double.infinity,
          height: 54,
          child: ElevatedButton(
            onPressed: (isLoading || !isVerified) ? null : _handleRegister,
            style: AppTheme.goldButton,
            child: isLoading
                ? const CircularProgressIndicator(color: Colors.white)
                : const Text('Register Now', style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold)),
          ),
        ),
      ],
    );
  }

  Widget _buildLabel(String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Text(text, style: AppTheme.small),
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
