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
          
          // Centered Login Card
          Center(child: SingleChildScrollView(
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
                        _buildLogo(),
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
                          
                        // Email Field
                        _buildLabel("Email Address"),
                        _buildInputField(email, "your@email.com", false),
                        const SizedBox(height: 20),
                        
                        // Password Field
                        _buildLabel("Password"),
                        _buildInputField(password, "••••••••", true),
                        const SizedBox(height: 12),
                        
                        // Sign In Button
                        SizedBox(
                          width: double.infinity,
                          child: ElevatedButton(
                            onPressed: isLoading ? null : _handleLogin,
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
                                : const Text("Sign In", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                          ),
                        ),
                        
                        // Footer Toggle
                        const SizedBox(height: 24),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Text("New to TaskNest?", style: TextStyle(color: Color(0xFF64748b), fontSize: 14)),
                            TextButton(
                              onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const RegisterScreen())),
                              child: const Text("Create account", style: TextStyle(color: Color(0xFFC9A84C), fontWeight: FontWeight.bold)),
                            ),
                          ],
                        ),
                        
                        // Back Button
                        const SizedBox(height: 16),
                        TextButton(
                          onPressed: () => Navigator.pop(context),
                          child: const Text("← Back to Home", style: TextStyle(color: Color(0xFF64748b), fontWeight: FontWeight.w600)),
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

  Widget _buildLogo() {
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
          "Sign in to your account",
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

  Widget _buildInputField(TextEditingController controller, String hint, bool isPassword) {
    return TextField(
      controller: controller,
      obscureText: isPassword,
      decoration: InputDecoration(
        hintText: hint,
        filled: true,
        fillColor: const Color(0xFFf8fafc),
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
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      ),
    );
  }
}
