import 'package:flutter/material.dart';
import '../../services/api_service.dart';

class AdminWithdrawalManagementScreen extends StatefulWidget {
  const AdminWithdrawalManagementScreen({super.key});

  @override
  State<AdminWithdrawalManagementScreen> createState() => _AdminWithdrawalManagementScreenState();
}

class _AdminWithdrawalManagementScreenState extends State<AdminWithdrawalManagementScreen> {
  bool _isLoading = false;
  List<dynamic> _withdrawals = [];

  @override
  void initState() {
    super.initState();
    _loadWithdrawals();
  }

  Future<void> _loadWithdrawals() async {
    setState(() => _isLoading = true);
    try {
      final res = await ApiService.get('/admin/withdrawals');
      if (res != null && res is Map && res['success']) {
        setState(() {
          _withdrawals = res['withdrawals'];
        });
      }
    } catch (e) {
      debugPrint('Error loading withdrawals: $e');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _updateStatus(String id, String status) async {
    final remarksController = TextEditingController();
    
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('${status.toUpperCase()} Withdrawal'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('Are you sure you want to $status this withdrawal?'),
            const SizedBox(height: 16),
            TextField(
              controller: remarksController,
              decoration: const InputDecoration(labelText: 'Remarks (optional)', border: OutlineInputBorder()),
            ),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(backgroundColor: status == 'completed' ? Colors.green : Colors.red),
            child: Text('Confirm $status'),
          ),
        ],
      ),
    );

    if (confirm != true) return;

    setState(() => _isLoading = true);
    try {
      final res = await ApiService.post('/admin/withdrawals/$id', {
        'status': status,
        'remarks': remarksController.text,
      });

      if (res != null && res is Map && res['success']) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Withdrawal $status successfully')));
        _loadWithdrawals();
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
      appBar: AppBar(title: const Text('Withdrawal Management')),
      body: _isLoading 
        ? const Center(child: CircularProgressIndicator())
        : RefreshIndicator(
            onRefresh: _loadWithdrawals,
            child: ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: _withdrawals.length,
              itemBuilder: (context, index) {
                final w = _withdrawals[index];
                final user = w['userId'];
                final bank = w['bankAccountId'];
                final status = w['status'];

                return Card(
                  margin: const EdgeInsets.only(bottom: 16),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(user?['name'] ?? 'Unknown User', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
                            _buildStatusBadge(status),
                          ],
                        ),
                        Text(user?['email'] ?? ''),
                        const Divider(height: 24),
                        const Text('Bank Details:', style: TextStyle(fontWeight: FontWeight.bold)),
                        Text('A/C Name: ${bank?['accountHolderName'] ?? 'N/A'}'),
                        Text('Bank: ${bank?['bankName'] ?? 'N/A'}'),
                        Text('A/C No: ${bank?['accountNumber'] ?? 'N/A'}'),
                        Text('IFSC: ${bank?['ifscCode'] ?? 'N/A'}'),
                        const SizedBox(height: 16),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text('Amount: ₹${w['amount']}', style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.blue)),
                            if (status == 'pending')
                              Row(
                                children: [
                                  IconButton(
                                    onPressed: () => _updateStatus(w['_id'], 'failed'), 
                                    icon: const Icon(Icons.cancel, color: Colors.red),
                                    tooltip: 'Reject',
                                  ),
                                  const SizedBox(width: 8),
                                  ElevatedButton(
                                    onPressed: () => _updateStatus(w['_id'], 'completed'),
                                    style: ElevatedButton.styleFrom(backgroundColor: Colors.green, foregroundColor: Colors.white),
                                    child: const Text('Approve'),
                                  ),
                                ],
                              ),
                          ],
                        ),
                        if (w['remarks'] != null) ...[
                          const SizedBox(height: 8),
                          Text('Remarks: ${w['remarks']}', style: const TextStyle(fontStyle: FontStyle.italic, color: Colors.grey)),
                        ],
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
    );
  }

  Widget _buildStatusBadge(String status) {
    Color color;
    switch (status) {
      case 'pending': color = Colors.orange; break;
      case 'completed': color = Colors.green; break;
      case 'failed': color = Colors.red; break;
      default: color = Colors.grey;
    }
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      decoration: BoxDecoration(color: color.withOpacity(0.1), borderRadius: BorderRadius.circular(12), border: Border.all(color: color)),
      child: Text(status.toUpperCase(), style: TextStyle(color: color, fontSize: 12, fontWeight: FontWeight.bold)),
    );
  }
}
