import 'package:flutter/material.dart';
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
  late UserRole selectedRole;
  String? errorMessage;
  String? loadingMessage; // ← add this state variable 
  
  // Set to false for production use with real backend
  static const bool _devMode = false;

  @override
  void initState() {
    super.initState();
    // Use the role passed from RoleSelectionScreen, or default to taskUser
    selectedRole = widget.selectedRole ?? UserRole.taskUser;
  }

  Future<void> _handleLogin() async {
    // Validate inputs
    if (email.text.isEmpty || password.text.isEmpty) {
      setState(() {
        errorMessage = "Please enter email and password";
      });
      return;
    }
    // Basic validation (prevent logging in with short password)
    if (!email.text.contains('@')) {
      setState(() {
        errorMessage = "Please enter a valid email address";
      });
      return;
    }
    if (password.text.length < 6) {
      setState(() {
        errorMessage = "Password must be at least 6 characters";
      });
      return;
    }

    setState(() {
      isLoading = true;
      errorMessage = null;
      loadingMessage = 'Connecting to server...'; // ← add this 
    });

    // After 10 seconds, update message 
    Future.delayed(const Duration(seconds: 10), () { 
      if (mounted && isLoading) { 
        setState(() { 
          loadingMessage = 'Server is waking up, please wait...'; 
        }); 
      } 
    }); 

    try {
      final response = await ApiService.post("/users/login", { 
        "email": email.text.trim(), 
        "password": password.text, 
        "role": selectedRole == UserRole.taskProvider ? "taskProvider" : "taskUser", 
      }).timeout( 
        const Duration(seconds: 60),  // ← increase to 60s for Render cold start 
        onTimeout: () { 
          setState(() { 
            isLoading = false; 
            errorMessage = 'Request timed out. Please check your connection.'; 
          }); 
          return {}; 
        }, 
      ); 
      
      // ← ADD null/empty check 
      if (response == null || response.isEmpty) return; 

      setState(() {
        isLoading = false;
        loadingMessage = null; // Clear loading message on success
      });

      // Check if login was successful
      if (response['success'] == true || response['token'] != null || response['message'] == 'Login successful') {
        // Store user data with role
        UserService.setUser(
          userId: response['userId']?.toString() ?? 'USR-${DateTime.now().millisecondsSinceEpoch}',
          userName: response['name']?.toString() ?? email.text.split('@')[0],
          userEmail: email.text.trim(),
          userPassword: password.text,
          userRole: selectedRole,
        );
        
        // Navigate to appropriate home screen based on role
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
        // Show inline error message below fields
        setState(() {
          errorMessage = response['message'] ?? 'Login failed. Please try again.';
        });
      }
    } catch (e) {
      setState(() {
        isLoading = false;
        loadingMessage = null; // Clear on error
        errorMessage = 'Something went wrong. Please try again.';
      });

      // In development mode, allow navigation even if API fails (for testing)
      if (_devMode) {
        // Store user data for dev mode with role
        UserService.setUser(
          userId: 'USR-${DateTime.now().millisecondsSinceEpoch}',
          userName: email.text.split('@')[0], // Use email prefix as name
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
        return;
      }

      // Show error message in production
      // Already set a generic errorMessage above
    }
  }

  @override
  void dispose() {
    email.dispose();
    password.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF1E3A5F), // Dark blue background matching image
      
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            child: Container(
              constraints: const BoxConstraints(maxWidth: 500),
              padding: const EdgeInsets.all(24),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const SizedBox(height: 40),
                  
                  // Logo/Title
                  const Text(
                    'TaskNest',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 32,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 40),

                  // Login Container
                  Container(
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: const [
                        BoxShadow(
                          color: Colors.black26,
                          blurRadius: 20,
                          offset: Offset(0, 10),
                        )
                      ],
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(32),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          // Email Input
                          TextField(
                            controller: email,
                            enabled: !isLoading,
                            decoration: InputDecoration(
                              labelText: 'Email',
                              labelStyle: const TextStyle(color: Colors.black54),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(8),
                                borderSide: const BorderSide(color: Colors.grey),
                              ),
                              enabledBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(8),
                                borderSide: const BorderSide(color: Colors.grey),
                              ),
                              focusedBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(8),
                                borderSide: const BorderSide(color: Color(0xFF1E3A5F), width: 2),
                              ),
                              prefixIcon: const Icon(Icons.email, color: Colors.black54),
                            ),
                          ),
                          const SizedBox(height: 20),

                          // Password Input
                          TextField(
                            controller: password,
                            enabled: !isLoading,
                            obscureText: true,
                            decoration: InputDecoration(
                              labelText: 'Password',
                              labelStyle: const TextStyle(color: Colors.black54),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(8),
                                borderSide: const BorderSide(color: Colors.grey),
                              ),
                              enabledBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(8),
                                borderSide: const BorderSide(color: Colors.grey),
                              ),
                              focusedBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(8),
                                borderSide: const BorderSide(color: Color(0xFF1E3A5F), width: 2),
                              ),
                              prefixIcon: const Icon(Icons.lock, color: Colors.black54),
                            ),
                          ),
                          if (errorMessage != null) ...[
                            const SizedBox(height: 8),
                            Text(
                              errorMessage!,
                              style: const TextStyle(
                                color: Colors.red,
                                fontSize: 13,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                          const SizedBox(height: 32),

                          // Two Login Buttons
                          // User Login Button
                          SizedBox(
                            width: double.infinity,
                            height: 50,
                            child: ElevatedButton(
                              style: ElevatedButton.styleFrom(
                                backgroundColor: const Color(0xFF1976D2), // Blue for user
                                foregroundColor: Colors.white,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                elevation: 2,
                              ),
                              onPressed: isLoading ? null : () {
                                setState(() => selectedRole = UserRole.taskUser);
                                _handleLogin();
                              },
                              child: isLoading && selectedRole == UserRole.taskUser
                                  ? Column(
                                      mainAxisAlignment: MainAxisAlignment.center,
                                      children: [
                                        const SizedBox(
                                          width: 16,
                                          height: 16,
                                          child: CircularProgressIndicator(
                                            strokeWidth: 2,
                                            valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                                          ),
                                        ),
                                        const SizedBox(height: 4),
                                        Text(
                                          loadingMessage ?? 'Please wait...',
                                          style: const TextStyle(fontSize: 10, color: Colors.white),
                                        ),
                                      ],
                                    )
                                  : const Text(
                                      'Login as User',
                                      style: TextStyle(
                                        fontSize: 16,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                            ),
                          ),
                          const SizedBox(height: 16),

                          // Task Provider Login Button
                          SizedBox(
                            width: double.infinity,
                            height: 50,
                            child: ElevatedButton(
                              style: ElevatedButton.styleFrom(
                                backgroundColor: const Color(0xFF7B1FA2), // Purple for task provider
                                foregroundColor: Colors.white,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                elevation: 2,
                              ),
                              onPressed: isLoading ? null : () {
                                setState(() => selectedRole = UserRole.taskProvider);
                                _handleLogin();
                              },
                              child: isLoading && selectedRole == UserRole.taskProvider
                                  ? Column(
                                      mainAxisAlignment: MainAxisAlignment.center,
                                      children: [
                                        const SizedBox(
                                          width: 16,
                                          height: 16,
                                          child: CircularProgressIndicator(
                                            strokeWidth: 2,
                                            valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                                          ),
                                        ),
                                        const SizedBox(height: 4),
                                        Text(
                                          loadingMessage ?? 'Please wait...',
                                          style: const TextStyle(fontSize: 10, color: Colors.white),
                                        ),
                                      ],
                                    )
                                  : const Text(
                                      'Login as Task Provider',
                                      style: TextStyle(
                                        fontSize: 16,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                            ),
                          ),
                          const SizedBox(height: 24),

                          // Sign Up Link
                          Center(
                            child: GestureDetector(
                              onTap: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (_) => const RegisterScreen(),
                                  ),
                                );
                              },
                              child: RichText(
                                text: const TextSpan(
                                  text: "Don't have an account? ",
                                  style: TextStyle(color: Colors.black54),
                                  children: [
                                    TextSpan(
                                      text: "Sign Up",
                                      style: TextStyle(
                                        color: Color(0xFF1E3A5F),
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
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
