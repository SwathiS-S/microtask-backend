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
      // ✅ FIX: correct endpoint is /wallet/withdrawal-history/ not /wallet/withdrawals/
      final res = await ApiService.get('/wallet/withdrawal-history/${UserService.userId}');
      if (res != null && res['success'] == true) {
        setState(() => _withdrawals = res['history'] ?? []);
      } else {
        setState(() => _withdrawals = []);
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error loading history: $e')));
    } finally {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Withdrawal History'),
        backgroundColor: const Color(0xFF1E3A5F),
        foregroundColor: Colors.white,
        actions: [
          IconButton(icon: const Icon(Icons.refresh), onPressed: _loadWithdrawalHistory)
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _withdrawals.isEmpty
              ? const Center(
                  child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
                    Icon(Icons.history, size: 64, color: Colors.grey),
                    SizedBox(height: 16),
                    Text('No withdrawal history.', style: TextStyle(color: Colors.grey, fontSize: 16)),
                  ]),
                )
              : RefreshIndicator(
                  onRefresh: _loadWithdrawalHistory,
                  child: ListView.builder(
                    itemCount: _withdrawals.length,
                    itemBuilder: (context, index) =>
                        _buildHistoryItem(_withdrawals[index] as Map<String, dynamic>),
                  ),
                ),
    );
  }

  Widget _buildHistoryItem(Map<String, dynamic> item) {
    final status = (item['status'] ?? 'pending').toString().toLowerCase();
    final amount = ((item['amount'] ?? 0) as num).toDouble();
    final bankDetails = item['bankDetails'] as Map<String, dynamic>?;

    // Parse date safely
    String dateStr = 'N/A';
    if (item['requestedAt'] != null) {
      try {
        final dt = DateTime.parse(item['requestedAt'].toString()).toLocal();
        dateStr = DateFormat.yMMMd().add_jm().format(dt);
      } catch (_) {}
    }

    // Safe account number display
    String accountDisplay = 'N/A';
    if (bankDetails != null) {
      final accNum = bankDetails['accountNumber']?.toString() ?? '';
      if (accNum.length >= 4) {
        accountDisplay = '****${accNum.substring(accNum.length - 4)}';
      } else if (accNum.isNotEmpty) {
        accountDisplay = accNum;
      }
    }

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
      case 'failed':
        icon = Icons.cancel;
        color = Colors.red;
        statusText = 'Rejected';
        break;
      default:
        icon = Icons.access_time;
        color = Colors.grey;
        statusText = 'Pending';
    }

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, color: color, size: 24),
          ),
          const SizedBox(width: 16),
          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text('₹${amount.toStringAsFixed(2)}',
                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
            if (bankDetails != null) ...[
              const SizedBox(height: 4),
              Text('${bankDetails['bankName'] ?? 'Bank'} - $accountDisplay',
                  style: const TextStyle(fontSize: 13, color: Colors.grey)),
            ],
            const SizedBox(height: 2),
            Text(dateStr, style: const TextStyle(fontSize: 12, color: Colors.grey)),
            if (item['remarks'] != null && item['remarks'].toString().isNotEmpty) ...[
              const SizedBox(height: 4),
              Text('Note: ${item['remarks']}',
                  style: const TextStyle(fontSize: 12, color: Colors.orange)),
            ],
          ])),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(statusText,
                style: TextStyle(color: color, fontWeight: FontWeight.bold, fontSize: 13)),
          ),
        ]),
      ),
    );
  }
}