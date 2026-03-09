import 'package:flutter/material.dart';
import 'dart:async';
import '../../widgets/top_actions.dart';
import '../../services/api_service.dart';
import '../../services/user_service.dart';
import 'login_screen.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final TextEditingController nameController = TextEditingController();
  final TextEditingController emailController = TextEditingController();
  final TextEditingController phoneController = TextEditingController();
  final TextEditingController locationController = TextEditingController();
  final TextEditingController passwordController = TextEditingController();
  final TextEditingController confirmPasswordController = TextEditingController();
  final TextEditingController otpController = TextEditingController();

  bool isLoading = false;
  bool obscurePassword = true;
  bool obscureConfirmPassword = true;
  UserRole selectedRole = UserRole.taskUser;
  bool otpSent = false;
  bool otpVerified = false;
  String? _devOtpShown;
  int otpSecondsLeft = 0;
  Timer? _otpTimer;

  static const bool _otpEnabled = false;
  static const bool _devMode = false;

  @override
  void initState() {
    super.initState();
    phoneController.addListener(() {
      final digits = phoneController.text.replaceAll(RegExp(r'\D'), '');
      if (digits.length < 10) {
        _otpTimer?.cancel();
        setState(() {
          otpSent = false;
          otpVerified = false;
          otpSecondsLeft = 0;
        });
      }
    });
  }

  void _startCountdown([int seconds = 60]) {
    _otpTimer?.cancel();
    setState(() {
      otpSecondsLeft = seconds;
    });
    _otpTimer = Timer.periodic(const Duration(seconds: 1), (t) {
      if (otpSecondsLeft <= 0) {
        t.cancel();
        setState(() {});
      } else {
        setState(() {
          otpSecondsLeft -= 1;
        });
      }
    });
  }

  Future<void> _sendOtp() async {
    if (phoneController.text.length < 10) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Please enter a valid phone number")),
      );
      return;
    }
    setState(() {
      isLoading = true;
    });
    try {
      final sendRes = await ApiService.post("/auth/send-otp", {
        "phone": phoneController.text,
      });
      setState(() {
        isLoading = false;
        otpSent = true;
        _devOtpShown = sendRes['devOtp']?.toString();
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(sendRes['message'] ?? 'OTP sent')),
      );
      if (_devMode && _devOtpShown != null) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Dev OTP: $_devOtpShown")),
        );
      }
    } catch (e) {
      setState(() {
        isLoading = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error: ${e.toString()}'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Future<void> _verifyOtp() async {
    if (!otpSent) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Please send OTP first")),
      );
      return;
    }
    if (otpController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Please enter the OTP")),
      );
      return;
    }
    setState(() {
      isLoading = true;
    });
    try {
      final verifyRes = await ApiService.post("/auth/verify-otp", {
        "email": emailController.text,
        "otp": otpController.text,
      });
      setState(() {
        isLoading = false;
        otpVerified = verifyRes['success'] == true;
      });
      if (otpVerified) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(verifyRes['message'] ?? 'Email verified! You can login now.')),
        );
        if (mounted) {
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(builder: (_) => const LoginScreen()),
          );
        }
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content:
                Text(verifyRes['message'] ?? 'OTP verification failed'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } catch (e) {
      setState(() {
        isLoading = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error: ${e.toString()}'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Future<void> _handleRegister() async {
    // Validate inputs
    if (nameController.text.isEmpty ||
        emailController.text.isEmpty ||
        phoneController.text.isEmpty ||
        locationController.text.isEmpty ||
        passwordController.text.isEmpty ||
        confirmPasswordController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Please fill all fields")),
      );
      return;
    }

    // Validate email format
    if (!emailController.text.contains('@')) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Please enter a valid email")),
      );
      return;
    }

    // Validate phone number
    if (phoneController.text.length < 10) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Please enter a valid phone number")),
      );
      return;
    }

    // Validate password
    if (passwordController.text.length < 6) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Password must be at least 6 characters")),
      );
      return;
    }

    // Validate passwords match
    if (passwordController.text != confirmPasswordController.text) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Passwords do not match")),
      );
      return;
    }

    setState(() {
      isLoading = true;
    });

    try {
      final response = await ApiService.post("/users/register", {
        "name": nameController.text,
        "email": emailController.text,
        "phone": phoneController.text,
        "location": locationController.text,
        "password": passwordController.text,
        "role": selectedRole == UserRole.taskProvider ? "taskProvider" : "taskUser"
      });

      setState(() {
        isLoading = false;
      });

      if (response['success'] == true ||
          response['message'].contains('Registration successful')) {
        // Store user data
        UserService.setUser(
          userId: response['userId']?.toString() ??
              'USR-${DateTime.now().millisecondsSinceEpoch}',
          userName: nameController.text.trim(),
          userEmail: emailController.text.trim(),
          userPassword: passwordController.text,
          userLocation: locationController.text.trim(),
          userRole: selectedRole,
        );

        setState(() {
          otpSent = true;
          _devOtpShown = response['devOtp']?.toString();
        });

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(response['message'] ?? 'Registration successful. Verify your email.')),
          );
          if (_devOtpShown != null) {
            // Pre-fill the OTP controller if in dev/mock mode
            otpController.text = _devOtpShown!;
            
            showDialog(
              context: context,
              barrierDismissible: false,
              builder: (context) => AlertDialog(
                title: const Text('Dev/Mock Mode OTP'),
                content: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Text('Since email service is not configured, please use this OTP to verify:'),
                    const SizedBox(height: 16),
                    Text(
                      _devOtpShown!,
                      style: const TextStyle(
                        fontSize: 32,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 4,
                        color: Color(0xFF1E3A5F),
                      ),
                    ),
                  ],
                ),
                actions: [
                  TextButton(
                    onPressed: () => Navigator.pop(context),
                    child: const Text('OK'),
                  ),
                ],
              ),
            );
          }
          _startCountdown();
        }
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(response['message'] ?? 'Registration failed'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    } catch (e) {
      setState(() {
        isLoading = false;
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  void dispose() {
    nameController.dispose();
    emailController.dispose();
    phoneController.dispose();
    otpController.dispose();
    locationController.dispose();
    passwordController.dispose();
    confirmPasswordController.dispose();
    _otpTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F6FA),
      
      appBar: AppBar(
        backgroundColor: const Color(0xFF1E3A5F),
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'Sign Up',
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
            fontSize: 24,
          ),
        ),
        centerTitle: true,
        actions: topActions(context),
      ),

      body: Center(
        child: SingleChildScrollView(
          child: Container(
            width: 500,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              boxShadow: const [
                BoxShadow(
                  color: Colors.black12,
                  blurRadius: 15,
                )
              ],
            ),
            child: Padding(
              padding: const EdgeInsets.all(40),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Create Account',
                    style: TextStyle(
                      fontSize: 28,
                      fontWeight: FontWeight.bold,
                      color: Colors.black87,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Join TaskNest today',
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.black54,
                    ),
                  ),
                  const SizedBox(height: 32),

                  // 🔹 ROLE SELECTION CARDS
                  const Text(
                    'Register as:',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: Colors.black87,
                    ),
                  ),
                  const SizedBox(height: 16),

                  Row(
                    children: [
                      Expanded(
                        child: GestureDetector(
                          onTap: () =>
                              setState(() => selectedRole = UserRole.taskUser),
                          child: Container(
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              border: Border.all(
                                color: selectedRole == UserRole.taskUser
                                    ? Colors.blue
                                    : Colors.grey[300]!,
                                width: selectedRole == UserRole.taskUser ? 2 : 1,
                              ),
                              borderRadius: BorderRadius.circular(12),
                              color: selectedRole == UserRole.taskUser
                                  ? Colors.blue.withOpacity(0.05)
                                  : Colors.transparent,
                            ),
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              crossAxisAlignment: CrossAxisAlignment.center,
                              children: [
                                Icon(
                                  Icons.person,
                                  size: 40,
                                  color: selectedRole == UserRole.taskUser
                                      ? Colors.blue
                                      : Colors.grey[600],
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  'Task User',
                                  style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.w600,
                                    color: selectedRole == UserRole.taskUser
                                        ? Colors.blue
                                        : Colors.black87,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: GestureDetector(
                          onTap: () => setState(
                              () => selectedRole = UserRole.taskProvider),
                          child: Container(
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              border: Border.all(
                                color: selectedRole == UserRole.taskProvider
                                    ? Colors.deepPurple
                                    : Colors.grey[300]!,
                                width: selectedRole == UserRole.taskProvider
                                    ? 2
                                    : 1,
                              ),
                              borderRadius: BorderRadius.circular(12),
                              color: selectedRole == UserRole.taskProvider
                                  ? Colors.deepPurple.withOpacity(0.05)
                                  : Colors.transparent,
                            ),
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              crossAxisAlignment: CrossAxisAlignment.center,
                              children: [
                                Icon(
                                  Icons.business,
                                  size: 40,
                                  color: selectedRole == UserRole.taskProvider
                                      ? Colors.deepPurple
                                      : Colors.grey[600],
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  'Task Provider',
                                  style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.w600,
                                    color: selectedRole == UserRole.taskProvider
                                        ? Colors.deepPurple
                                        : Colors.black87,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 32),

                  // 🔹 FORM FIELDS
                  TextField(
                    key: const Key('nameField'),
                    controller: nameController,
                    enabled: !isLoading,
                    decoration: InputDecoration(
                      labelText: 'Full Name',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                      prefixIcon: const Icon(Icons.person),
                    ),
                  ),
                  const SizedBox(height: 16),

                  TextField(
                    key: const Key('emailField'),
                    controller: emailController,
                    enabled: !isLoading,
                    keyboardType: TextInputType.emailAddress,
                    decoration: InputDecoration(
                      labelText: 'Email Address',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                      prefixIcon: const Icon(Icons.email),
                    ),
                  ),
                  const SizedBox(height: 16),

                  TextField(
                    key: const Key('phoneField'),
                    controller: phoneController,
                    enabled: !isLoading,
                    keyboardType: TextInputType.phone,
                    decoration: InputDecoration(
                      labelText: 'Phone Number',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                      prefixIcon: const Icon(Icons.phone),
                    ),
                  ),
                  const SizedBox(height: 16),
                  if (otpSent) ...[
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Expanded(
                          child: Text(
                          otpSecondsLeft > 0
                              ? 'Resend in ${otpSecondsLeft}s'
                              : 'You can resend now',
                          style: TextStyle(
                            color: otpSecondsLeft > 0
                                ? Colors.black54
                                : Colors.green,
                            fontWeight: FontWeight.w600,
                          ),
                          ),
                        ),
                        SizedBox(
                          height: 36,
                          child: ElevatedButton(
                            key: const Key('resendOtpButton'),
                            onPressed: (isLoading || otpSecondsLeft > 0)
                                ? null
                                : _sendOtp,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.blueGrey,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(6),
                              ),
                            ),
                            child: const Text(
                              'Resend OTP',
                              style: TextStyle(color: Colors.white),
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                  ],
                  if (otpSent) ...[
                    TextField(
                      key: const Key('otpField'),
                      controller: otpController,
                      enabled: !isLoading,
                      keyboardType: TextInputType.number,
                      decoration: InputDecoration(
                        labelText: 'One-Time Password',
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                        prefixIcon: const Icon(Icons.shield),
                      ),
                    ),
                    const SizedBox(height: 16),
                  ],
                  if (otpSent) ...[
                    SizedBox(
                      width: double.infinity,
                      height: 44,
                      child: ElevatedButton(
                        key: const Key('verifyOtpButton'),
                        onPressed: isLoading ? null : _verifyOtp,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.teal,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                        child: const Text(
                          'Verify OTP',
                          style: TextStyle(color: Colors.white),
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                  ],

                  TextField(
                    key: const Key('locationField'),
                    controller: locationController,
                    enabled: !isLoading,
                    decoration: InputDecoration(
                      labelText: 'Location / City',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                      prefixIcon: const Icon(Icons.location_on),
                    ),
                  ),
                  const SizedBox(height: 16),

                  TextField(
                    key: const Key('passwordField'),
                    controller: passwordController,
                    enabled: !isLoading,
                    obscureText: obscurePassword,
                    decoration: InputDecoration(
                      labelText: 'Password',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                      prefixIcon: const Icon(Icons.lock),
                      suffixIcon: IconButton(
                        icon: Icon(
                          obscurePassword
                              ? Icons.visibility_off
                              : Icons.visibility,
                        ),
                        onPressed: () {
                          setState(() {
                            obscurePassword = !obscurePassword;
                          });
                        },
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),

                  TextField(
                    key: const Key('confirmPasswordField'),
                    controller: confirmPasswordController,
                    enabled: !isLoading,
                    obscureText: obscureConfirmPassword,
                    decoration: InputDecoration(
                      labelText: 'Confirm Password',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                      prefixIcon: const Icon(Icons.lock),
                      suffixIcon: IconButton(
                        icon: Icon(
                          obscureConfirmPassword
                              ? Icons.visibility_off
                              : Icons.visibility,
                        ),
                        onPressed: () {
                          setState(() {
                            obscureConfirmPassword =
                                !obscureConfirmPassword;
                          });
                        },
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),

                  // 🔹 REGISTER BUTTON
                  SizedBox(
                    width: double.infinity,
                    height: 48,
                    child: ElevatedButton(
                      key: const Key('registerButton'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: selectedRole == UserRole.taskProvider
                            ? Colors.deepPurple
                            : Colors.blue,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                      onPressed: isLoading ? null : _handleRegister,
                      child: isLoading
                          ? const SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                valueColor: AlwaysStoppedAnimation<Color>(
                                    Colors.white),
                              ),
                            )
                          : Text(
                              !otpSent
                                  ? 'Register'
                                  : (!otpVerified ? 'Verify & Register' : 'Register'),
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                    ),
                  ),
                  const SizedBox(height: 16),

                  // 🔹 LOGIN LINK
                  Center(
                    child: GestureDetector(
                      onTap: isLoading
                          ? null
                          : () {
                              Navigator.pop(context);
                            },
                      child: RichText(
                        text: TextSpan(
                          text: "Already have an account? ",
                          style: const TextStyle(color: Colors.black54),
                          children: [
                            TextSpan(
                              text: "Sign In",
                              style: TextStyle(
                                color: selectedRole == UserRole.taskProvider
                                    ? Colors.deepPurple
                                    : Colors.blue,
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
        ),
      ),
    );
  }
}
