import 'package:flutter/material.dart';
import '../../services/user_service.dart';
import '../../services/api_service.dart';

class BankSetupScreen extends StatefulWidget {
  final String role;
  const BankSetupScreen({super.key, required this.role});

  @override
  State<BankSetupScreen> createState() => _BankSetupScreenState();
}

class _BankSetupScreenState extends State<BankSetupScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController(text: UserService.userName);
  final _accNoController = TextEditingController();
  final _confirmAccNoController = TextEditingController();
  final _ifscController = TextEditingController();
  final _bankNameController = TextEditingController();
  final _branchNameController = TextEditingController();
  String _accountType = 'savings';
  bool _isSaving = false;
  bool _isSaved = false;

  @override
  void dispose() {
    _nameController.dispose();
    _accNoController.dispose();
    _confirmAccNoController.dispose();
    _ifscController.dispose();
    _bankNameController.dispose();
    _branchNameController.dispose();
    super.dispose();
  }

  Future<void> _saveBankDetails() async {
    if (!_formKey.currentState!.validate()) return;
    if (_accNoController.text != _confirmAccNoController.text) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Account numbers do not match')),
      );
      return;
    }

    setState(() => _isSaving = true);
    try {
      final res = await ApiService.post('/bank/add', {
        'userId': UserService.userId,
        'role': widget.role,
        'accountHolderName': _nameController.text,
        'accountNumber': _accNoController.text,
        'ifscCode': _ifscController.text,
        'bankName': _bankNameController.text,
        'branchName': _branchNameController.text,
        'accountType': _accountType,
      });

      if (res != null && res is Map && res['success']) {
        setState(() {
          _isSaved = true;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Bank account added successfully')),
        );
        Future.delayed(const Duration(seconds: 2), () {
          if (mounted) Navigator.pop(context, true);
        });
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(res?['message'] ?? 'Failed to add bank account')),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $e')),
      );
    } finally {
      setState(() => _isSaving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Bank Account Setup'),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        elevation: 0,
      ),
      body: _isSaved 
        ? Center(
            child: Column(
              mainAxisAlignment: MainValue.center,
              children: [
                const Icon(Icons.check_circle, color: Colors.green, size: 80),
                const SizedBox(height: 16),
                const Text(
                  'Bank Connected ✅',
                  style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),
                const Text('You will be redirected shortly...'),
              ],
            ),
          )
        : SingleChildScrollView(
            padding: const EdgeInsets.all(24.0),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Connect your bank account to enable withdrawals and payments.',
                    style: TextStyle(color: Colors.grey),
                  ),
                  const SizedBox(height: 24),
                  TextFormField(
                    controller: _nameController,
                    decoration: const InputDecoration(
                      labelText: 'Account Holder Name',
                      border: OutlineInputBorder(),
                    ),
                    validator: (v) => v!.isEmpty ? 'Required' : null,
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: _accNoController,
                    obscureText: true,
                    decoration: const InputDecoration(
                      labelText: 'Account Number',
                      border: OutlineInputBorder(),
                    ),
                    validator: (v) => v!.isEmpty ? 'Required' : null,
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: _confirmAccNoController,
                    decoration: const InputDecoration(
                      labelText: 'Confirm Account Number',
                      border: OutlineInputBorder(),
                    ),
                    validator: (v) => v!.isEmpty ? 'Required' : null,
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: _ifscController,
                    decoration: const InputDecoration(
                      labelText: 'IFSC Code',
                      border: OutlineInputBorder(),
                      hintText: 'e.g. SBIN0001234',
                    ),
                    onChanged: (v) {
                      if (v.length == 11) {
                        // Auto fetch bank name logic could go here
                        _bankNameController.text = 'Fetching bank name...';
                      }
                    },
                    validator: (v) => v!.length != 11 ? 'Invalid IFSC' : null,
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: _bankNameController,
                    decoration: const InputDecoration(
                      labelText: 'Bank Name',
                      border: OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: 16),
                  DropdownButtonFormField<String>(
                    value: _accountType,
                    decoration: const InputDecoration(
                      labelText: 'Account Type',
                      border: OutlineInputBorder(),
                    ),
                    items: const [
                      DropdownMenuItem(value: 'savings', child: Text('Savings')),
                      DropdownMenuItem(value: 'current', child: Text('Current')),
                    ],
                    onChanged: (v) => setState(() => _accountType = v!),
                  ),
                  const SizedBox(height: 32),
                  SizedBox(
                    width: double.infinity,
                    height: 50,
                    child: ElevatedButton(
                      onPressed: _isSaving ? null : _saveBankDetails,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.blue,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: _isSaving 
                        ? const CircularProgressIndicator(color: Colors.white)
                        : const Text('Save Bank Details', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                    ),
                  ),
                ],
              ),
            ),
          ),
    );
  }
}
