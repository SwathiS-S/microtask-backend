import 'package:flutter/material.dart';
import 'package:razorpay_flutter/razorpay_flutter.dart';
import '../../services/api_service.dart';
import '../../services/user_service.dart';

class FundTaskScreen extends StatefulWidget {
  final Map<String, dynamic> task;
  final double platformFee;
  const FundTaskScreen({super.key, required this.task, this.platformFee = 0.0});

  @override
  State<FundTaskScreen> createState() => _FundTaskScreenState();
}

class _FundTaskScreenState extends State<FundTaskScreen> {
  late Razorpay _razorpay;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _razorpay = Razorpay();
    _razorpay.on(Razorpay.EVENT_PAYMENT_SUCCESS, _handlePaymentSuccess);
    _razorpay.on(Razorpay.EVENT_PAYMENT_ERROR, _handlePaymentError);
    _razorpay.on(Razorpay.EVENT_EXTERNAL_WALLET, _handleExternalWallet);
  }

  @override
  void dispose() {
    _razorpay.clear();
    super.dispose();
  }

  void _handlePaymentSuccess(PaymentSuccessResponse response) async {
    setState(() => _isLoading = true);
    try {
      final double amount = widget.task['amount'].toDouble();
      final double total = amount + widget.platformFee;

      final res = await ApiService.post('/razorpay/verify-escrow-payment', {
        'razorpay_order_id': response.orderId,
        'razorpay_payment_id': response.paymentId,
        'razorpay_signature': response.signature,
        'taskId': widget.task['_id'],
        'providerId': UserService.userId,
        'amount': total,
      });

      if (res != null && res['success']) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Task funded and published! ✅'), backgroundColor: Colors.green),
        );
        Navigator.pop(context, true);
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Verification failed: ${res?['message']}')),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e')));
    } finally {
      setState(() => _isLoading = false);
    }
  }

  void _handlePaymentError(PaymentFailureResponse response) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Payment Failed: ${response.message}'), backgroundColor: Colors.red),
    );
  }

  void _handleExternalWallet(ExternalWalletResponse response) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('External Wallet: ${response.walletName}')),
    );
  }

  Future<void> _startPayment() async {
    setState(() => _isLoading = true);
    try {
      final double amount = widget.task['amount'].toDouble();
      final double total = amount + widget.platformFee;

      final orderRes = await ApiService.post('/razorpay/create-order', {
        'amount': total,
        'userId': UserService.userId,
        'currency': 'INR',
        'receipt': 'task_fund_${widget.task['_id']}',
        'notes': {'taskId': widget.task['_id']}
      });

      if (orderRes != null && orderRes['success']) {
          var options = {
            'key': 'rzp_test_SNzqJbQGrxxv81', 
            'amount': (total * 100).toInt(),
            'name': 'TaskNest',
            'description': 'Funding Task: ${widget.task['title']}',
            'order_id': orderRes['order']['id'],
            'prefill': {
              'contact': UserService.userPhone ?? '',
              'email': UserService.userEmail ?? '',
            },
            'external': {
              'wallets': ['paytm']
            }
          };
          _razorpay.open(options);
        } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to create order: ${orderRes?['message']}')),
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
    final double amount = widget.task['amount'].toDouble();
    final double total = amount + widget.platformFee;

    return Scaffold(
      appBar: AppBar(title: const Text('Fund Your Task')),
      body: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Text(
              'Fund your task to make it live',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 32),
            _buildInfoRow('Task Title', widget.task['title']),
            _buildInfoRow('Budget', '₹${amount.toStringAsFixed(2)}'),
            _buildInfoRow('Platform Fee (2%)', '₹${widget.platformFee.toStringAsFixed(2)}'),
            const Divider(height: 32),
            _buildInfoRow('Total to Pay', '₹${total.toStringAsFixed(2)}', isBold: true),
            const Spacer(),
            ElevatedButton(
              onPressed: _isLoading ? null : _startPayment,
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.blue,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 16),
              ),
              child: _isLoading 
                ? const CircularProgressIndicator(color: Colors.white)
                : const Text('Pay & Publish Task', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            ),
            const SizedBox(height: 16),
            const Text(
              "Your task budget will be held securely in escrow. It will only be released when you approve the completed work.",
              style: TextStyle(color: Colors.grey, fontSize: 12),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoRow(String label, String value, {bool isBold = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: TextStyle(fontSize: 16, color: isBold ? Colors.black : Colors.grey[700])),
          Text(value, style: TextStyle(fontSize: 16, fontWeight: isBold ? FontWeight.bold : FontWeight.normal)),
        ],
      ),
    );
  }
}
