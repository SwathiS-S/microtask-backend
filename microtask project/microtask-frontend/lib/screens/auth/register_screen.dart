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
    return Scaffold(
      body: Stack(
        children: [
          // Background with Dark Blue Gradient and Image Overlay
          Container(
            width: double.infinity,
            height: double.infinity,
            decoration: BoxDecoration(
              color: AppTheme.navy,
              image: const DecorationImage(
                image: NetworkImage(
                  'https://images.unsplash.com/photo-1517245386807-bb43f82c33c4?auto=format&fit=crop&q=80&w=2070',
                ),
                fit: BoxFit.cover,
                opacity: 0.08, // 92% dark blue overlay
              ),
            ),
          ),
          
          // Centered Register Card
          Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 440),
                child: Card(
                  elevation: 20,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(24),
                  ),
                  color: Colors.white.withOpacity(0.98),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 30, vertical: 40),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        // Logo and Title
                        _buildLogoContent(),
                        const SizedBox(height: 32),
                        
                        // Error Message
                        if (errorMessage != null)
                          Container(
                            padding: const EdgeInsets.all(10),
                            margin: const EdgeInsets.only(bottom: 20),
                            decoration: BoxDecoration(
                              color: Colors.red.shade50,
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Text(
                              errorMessage!,
                              style: const TextStyle(color: Colors.red, fontSize: 13),
                            ),
                          ),
                          
                        // Role Selection
                        _buildLabel("I WANT TO"),
                        Row(
                          children: [
                            Expanded(child: _buildRoleOption(UserRole.taskUser, "Find Tasks")),
                            const SizedBox(width: 12),
                            Expanded(child: _buildRoleOption(UserRole.taskProvider, "Post Tasks")),
                          ],
                        ),
                        const SizedBox(height: 24),

                        // Form Fields
                        _buildLabel("Full Name"),
                        _buildInputField(name, "John Doe", false),
                        const SizedBox(height: 16),
                        
                        _buildLabel("Email Address"),
                        _buildInputField(email, "your@email.com", false, enabled: !isVerified),
                        const SizedBox(height: 16),

                        _buildLabel("Phone Number"),
                        _buildInputField(phone, "Enter phone number", false),
                        const SizedBox(height: 16),

                        // OTP Section
                        if (isOtpSent && !isVerified)
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              _buildLabel("One-Time Password"),
                              Row(
                                children: [
                                  Expanded(child: _buildInputField(otp, "Enter OTP", false)),
                                  const SizedBox(width: 12),
                                  ElevatedButton(
                                    onPressed: isLoading ? null : _verifyEmail,
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: const Color(0xFF1E3A5F),
                                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                                    ),
                                    child: const Text("Verify", style: TextStyle(fontSize: 13, color: Colors.white)),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 8),
                              Text(
                                resendTimer > 0 ? "Resend in ${resendTimer}s" : "You can resend now",
                                style: const TextStyle(fontSize: 11, color: Color(0xFF64748b)),
                              ),
                              if (resendTimer <= 0)
                                TextButton(
                                  onPressed: isLoading ? null : _sendOtp,
                                  child: const Text("Resend OTP", style: TextStyle(fontSize: 12, color: Color(0xFFC9A84C))),
                                ),
                              const SizedBox(height: 24),
                            ],
                          ),

                        if (isVerified)
                          const Padding(
                            padding: EdgeInsets.only(bottom: 16),
                            child: Row(
                              children: [
                                Icon(Icons.verified, color: Colors.green, size: 16),
                                SizedBox(width: 8),
                                Text('Email Verified', style: TextStyle(color: Colors.green, fontSize: 13, fontWeight: FontWeight.bold)),
                              ],
                            ),
                          ),

                        _buildLabel("Password"),
                        _buildInputField(password, "••••••••", true),
                        const SizedBox(height: 24),
                        
                        // Register Button
                        SizedBox(
                          width: double.infinity,
                          child: ElevatedButton(
                            onPressed: isLoading ? null : (isVerified ? _handleRegister : _sendOtp),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppTheme.navy,
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(vertical: 16),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                              elevation: 4,
                            ),
                            child: isLoading
                                ? const SizedBox(
                                    height: 20,
                                    width: 20,
                                    child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                                  )
                                : Text(isVerified ? "Create Account" : (isOtpSent ? "Send OTP Again" : "Send Verification Code"), 
                                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                          ),
                        ),
                        
                        // Footer Toggle
                        const SizedBox(height: 24),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Text("Already have an account?", style: TextStyle(color: Color(0xFF64748b), fontSize: 14)),
                            TextButton(
                              onPressed: () => Navigator.pop(context),
                              child: const Text("Sign in", style: TextStyle(color: Color(0xFFC9A84C), fontWeight: FontWeight.bold)),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLogoContent() {
    return Column(
      children: [
        Container(
          width: 48,
          height: 48,
          decoration: BoxDecoration(
            color: const Color(0xFFC9A84C),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Center(
            child: Container(
              width: 22,
              height: 22,
              decoration: BoxDecoration(
                border: Border.all(color: Colors.white, width: 3),
                borderRadius: BorderRadius.circular(6),
              ),
            ),
          ),
        ),
        const SizedBox(height: 16),
        const Text(
          "TaskNest",
          style: TextStyle(
            fontSize: 32,
            fontWeight: FontWeight.w800,
            color: Color(0xFF1E3A5F),
            letterSpacing: -0.02,
          ),
        ),
        const Text(
          "Create your account",
          style: TextStyle(color: Color(0xFF64748b), fontSize: 15, fontWeight: FontWeight.w500),
        ),
      ],
    );
  }

  Widget _buildLabel(String text) {
    return Align(
      alignment: Alignment.centerLeft,
      child: Padding(
        padding: const EdgeInsets.only(bottom: 8.0),
        child: Text(
          text.toUpperCase(),
          style: const TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.bold,
            color: Color(0xFF475569),
            letterSpacing: 0.05,
          ),
        ),
      ),
    );
  }

  Widget _buildInputField(TextEditingController controller, String hint, bool isPassword, {bool enabled = true}) {
    return TextField(
      controller: controller,
      obscureText: isPassword,
      enabled: enabled,
      decoration: InputDecoration(
        hintText: hint,
        filled: true,
        fillColor: enabled ? const Color(0xFFf8fafc) : const Color(0xFFf1f5f9),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Color(0xFFe2e8f0), width: 1.5),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Color(0xFFe2e8f0), width: 1.5),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Color(0xFF1E3A5F), width: 1.5),
        ),
        disabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Color(0xFFe2e8f0), width: 1.5),
        ),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      ),
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
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: isSelected ? AppTheme.navy : const Color(0xFFe2e8f0), width: 1.5),
        ),
        child: Center(
          child: Text(
            label,
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.bold,
              color: isSelected ? Colors.white : const Color(0xFF64748b),
            ),
          ),
        ),
      ),
    );
  }
}
