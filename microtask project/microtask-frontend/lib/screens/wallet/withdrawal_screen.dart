import 'package:flutter/material.dart';
import '../../services/user_service.dart';
import '../../services/api_service.dart';

class WithdrawalScreen extends StatefulWidget {
  final double balance;
  final Map<String, dynamic> bankAccount;
  const WithdrawalScreen({super.key, required this.balance, required this.bankAccount});

  @override
  State<WithdrawalScreen> createState() => _WithdrawalScreenState();
}

class _WithdrawalScreenState extends State<WithdrawalScreen> {
  final _amountController = TextEditingController();
  bool _isLoading = false;

  Future<void> _requestWithdrawal() async {
    final amount = double.tryParse(_amountController.text);

    // 1. Fetch FRESH balance from API before validation
    final balRes = await ApiService.get('/wallet/balance/${UserService.userId}');
    if (balRes == null || !(balRes is Map) || !balRes['success']) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Could not refresh balance. Please try again.')),
      );
      return;
    }
    final freshBalance = (balRes['balance'] ?? 0).toDouble();
    print('Fresh balance from API: $freshBalance');

    if (amount == null || amount <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Invalid amount')));
      return;
    }

    final double minimumWithdrawal = freshBalance < 100 ? 1 : 10;
    if (amount < minimumWithdrawal) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Minimum withdrawal amount is ₹$minimumWithdrawal')));
      return;
    }
    if (amount > freshBalance) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Insufficient balance')));
      return;
    }

    setState(() => _isLoading = true);

    print('=== WITHDRAWAL REQUEST ===');
    print('User ID: ${UserService.userId}');
    print('Amount: $amount');
    print('Wallet Balance: ${widget.balance}');
    print('==========================');

    try {
      final res = await ApiService.post('/wallet/withdraw', {
        'userId': UserService.userId,
        'amount': amount,
        'bankDetails': {
          'accountHolderName': widget.bankAccount['accountHolderName'],
          'accountNumber': widget.bankAccount['accountNumber'],
          'ifscCode': widget.bankAccount['ifscCode'],
          'bankName': widget.bankAccount['bankName'],
          'branchName': widget.bankAccount['branchName'],
        }
      });

      if (res['success']) {
        Navigator.pop(context, true);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('✅ Withdrawal Requested!')),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(res['message'] ?? 'Withdrawal failed')),
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
      body: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Available Balance', style: TextStyle(color: Colors.grey)),
            Text(
              '₹${widget.balance.toStringAsFixed(2)}',
              style: const TextStyle(fontSize: 32, fontWeight: FontWeight.bold, color: Colors.green),
            ),
            const SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Minimum Withdrawal: ₹${widget.balance < 100 ? 1 : 10}',
                  style: const TextStyle(color: Colors.grey, fontSize: 12),
                ),
                Text(
                  'Maximum Withdrawal: ₹${widget.balance.toStringAsFixed(2)}',
                  style: const TextStyle(color: Colors.grey, fontSize: 12),
                ),
              ],
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
                  const Text('Bank Account', style: TextStyle(fontWeight: FontWeight.bold)),
                  const SizedBox(height: 8),
                  Text('Name: ${widget.bankAccount['accountHolderName']}'),
                  Text('Bank: ${widget.bankAccount['bankName'] ?? 'N/A'}'),
                  Text('A/C: ****${widget.bankAccount['accountNumber'].toString().substring(widget.bankAccount['accountNumber'].toString().length - 4)}'),
                ],
              ),
            ),
            const Spacer(),
            SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton(
                onPressed: _isLoading ? null : _requestWithdrawal,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.green,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                child: _isLoading ? const CircularProgressIndicator(color: Colors.white) : const Text('Request Withdrawal', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
