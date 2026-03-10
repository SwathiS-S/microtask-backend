import 'package:flutter/material.dart';
import '../../services/api_service.dart';
import '../../services/user_service.dart';
import 'package:intl/intl.dart';

class WithdrawalHistoryScreen extends StatefulWidget {
  const WithdrawalHistoryScreen({super.key});

  @override
  State<WithdrawalHistoryScreen> createState() => _WithdrawalHistoryScreenState();
}

class _WithdrawalHistoryScreenState extends State<WithdrawalHistoryScreen> {
  bool _isLoading = false;
  List<dynamic> _withdrawals = [];

  @override
  void initState() {
    super.initState();
    _loadWithdrawalHistory();
  }

  Future<void> _loadWithdrawalHistory() async {
    setState(() => _isLoading = true);
    try {
      final res = await ApiService.get('/wallet/withdrawals/${UserService.userId}');
      if (res != null && res['success']) {
        setState(() {
          _withdrawals = res['withdrawals'];
        });
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error loading history: $e')));
    } finally {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Withdrawal History')),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _withdrawals.isEmpty
              ? const Center(child: Text('No withdrawal history.'))
              : RefreshIndicator(
                  onRefresh: _loadWithdrawalHistory,
                  child: ListView.builder(
                    itemCount: _withdrawals.length,
                    itemBuilder: (context, index) {
                      final item = _withdrawals[index];
                      return _buildHistoryItem(item);
                    },
                  ),
                ),
    );
  }

  Widget _buildHistoryItem(Map<String, dynamic> item) {
    final status = item['status'] ?? 'pending';
    final amount = (item['amount'] ?? 0).toDouble();
    final requestedAt = DateTime.parse(item['requestedAt']);
    final bankDetails = item['bankDetails'];

    IconData icon;
    Color color;
    String statusText;

    switch (status) {
      case 'completed':
        icon = Icons.check_circle;
        color = Colors.green;
        statusText = 'Completed';
        break;
      case 'processing':
        icon = Icons.hourglass_bottom;
        color = Colors.orange;
        statusText = 'Processing';
        break;
      case 'rejected':
        icon = Icons.cancel;
        color = Colors.red;
        statusText = 'Rejected';
        break;
      default:
        icon = Icons.history;
        color = Colors.grey;
        statusText = 'Pending';
    }

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: ListTile(
        leading: Icon(icon, color: color),
        title: Text('₹${amount.toStringAsFixed(2)}', style: const TextStyle(fontWeight: FontWeight.bold)),
        subtitle: Text('To: ${bankDetails['bankName']} - ****${bankDetails['accountNumber'].substring(bankDetails['accountNumber'].length - 4)}\n${DateFormat.yMMMd().add_jm().format(requestedAt)}'),
        trailing: Text(statusText, style: TextStyle(color: color, fontWeight: FontWeight.bold)),
      ),
    );
  }
}
