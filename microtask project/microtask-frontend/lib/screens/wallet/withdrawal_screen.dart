import 'package:flutter/material.dart';
import '../../services/user_service.dart';
import '../../services/api_service.dart';

class WithdrawalScreen extends StatefulWidget {
  final double balance;
  const WithdrawalScreen({super.key, required this.balance});

  @override
  State<WithdrawalScreen> createState() => _WithdrawalScreenState();
}

class _WithdrawalScreenState extends State<WithdrawalScreen> {
  final _amountController = TextEditingController();
  bool _isLoading = false;
  Map<String, dynamic>? _bankAccount;

  @override
  void initState() {
    super.initState();
    _loadBankDetails();
  }

  Future<void> _loadBankDetails() async {
    setState(() => _isLoading = true);
    try {
      final res = await ApiService.get('/bank/details/${UserService.userId}');
      if (res != null && res is Map && res['success']) {
        setState(() {
          _bankAccount = res['bankAccount'];
        });
      }
    } catch (e) {
      debugPrint('Error loading bank details: $e');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _requestWithdrawal() async {
    final amount = double.tryParse(_amountController.text);
    if (amount == null || amount <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Invalid amount')));
      return;
    }
    if (amount > widget.balance) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Insufficient balance')));
      return;
    }
    if (_bankAccount == null) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Please connect bank account first')));
      return;
    }

    setState(() => _isLoading = true);
    try {
      final res = await ApiService.post('/wallet/withdraw', {
        'userId': UserService.userId,
        'amount': amount,
        'bankAccountId': _bankAccount!['_id'],
      });

      if (res != null && res is Map && res['success']) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Withdrawal Requested ✅')),
        );
        Navigator.pop(context, true);
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(res?['message'] ?? 'Withdrawal failed')),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e')));
    } finally {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Withdraw Funds')),
      body: _isLoading 
        ? const Center(child: CircularProgressIndicator())
        : Padding(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Available Balance', style: TextStyle(color: Colors.grey)),
                Text(
                  '₹${widget.balance.toStringAsFixed(2)}',
                  style: const TextStyle(fontSize: 32, fontWeight: FontWeight.bold, color: Colors.green),
                ),
                const SizedBox(height: 32),
                TextField(
                  controller: _amountController,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(
                    labelText: 'Enter amount to withdraw',
                    prefixText: '₹ ',
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 24),
                if (_bankAccount != null)
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.grey[100],
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.grey[300]!),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('Connected Bank Account', style: TextStyle(fontWeight: FontWeight.bold)),
                        const SizedBox(height: 8),
                        Text('Name: ${_bankAccount!['accountHolderName']}'),
                        Text('Bank: ${_bankAccount!['bankName'] ?? 'N/A'}'),
                        Text('A/C: ****${_bankAccount!['accountNumber'].toString().substring(_bankAccount!['accountNumber'].toString().length - 4)}'),
                      ],
                    ),
                  ),
                const SizedBox(height: 32),
                const Text(
                  'Expected time: 2-3 business days',
                  style: TextStyle(color: Colors.grey, fontSize: 12),
                ),
                const Spacer(),
                SizedBox(
                  width: double.infinity,
                  height: 50,
                  child: ElevatedButton(
                    onPressed: _requestWithdrawal,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.green,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    child: const Text('Confirm Withdrawal', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                  ),
                ),
              ],
            ),
          ),
    );
  }
}
