import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../main.dart'; // Import để dùng formatMoney

class TransactionHistoryScreen extends StatefulWidget {
  final String accountNumber;
  final int currentBalance;

  const TransactionHistoryScreen({
    super.key,
    required this.accountNumber,
    required this.currentBalance,
  });

  @override
  State<TransactionHistoryScreen> createState() => _TransactionHistoryScreenState();
}

class _TransactionHistoryScreenState extends State<TransactionHistoryScreen> {
  List<dynamic> _transactions = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _fetchTransactions();
  }

  // Tải danh sách giao dịch của riêng số tài khoản này
  Future<void> _fetchTransactions() async {
    try {
      final response = await Supabase.instance.client
          .from('transactions')
          .select()
          // Tìm những giao dịch mà STK này là người gửi HOẶC người nhận
          .or('from_account.eq.${widget.accountNumber},to_account.eq.${widget.accountNumber}')
          .order('created_at', ascending: false); // Sắp xếp mới nhất lên đầu

      if (mounted) {
        setState(() {
          _transactions = response;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  // Hàm fomat thời gian 
  String _formatTime(String? isoString) {
    if (isoString == null) return '';
    final dt = DateTime.parse(isoString).toLocal();
    return '${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')} - ${dt.day.toString().padLeft(2, '0')}/${dt.month.toString().padLeft(2, '0')}/${dt.year}';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[100],
      appBar: AppBar(
        title: const Text('Chi tiết tài khoản'),
        backgroundColor: Colors.blue[700],
        foregroundColor: Colors.white,
      ),
      body: Column(
        children: [
          // KHỐI HIỂN THỊ SỐ DƯ
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(24),
            decoration: const BoxDecoration(
              color: Colors.white,
              border: Border(bottom: BorderSide(color: Colors.black12, width: 1)),
            ),
            child: Column(
              children: [
                Text(widget.accountNumber, style: const TextStyle(fontSize: 18, color: Colors.grey, fontWeight: FontWeight.bold)),
                const SizedBox(height: 8),
                Text('${formatMoney(widget.currentBalance)} VND', style: TextStyle(fontSize: 32, fontWeight: FontWeight.bold, color: Colors.blue[800])),
              ],
            ),
          ),
          
          // DANH SÁCH GIAO DỊCH
          Expanded(
            child: _isLoading 
              ? const Center(child: CircularProgressIndicator())
              : _transactions.isEmpty
                ? const Center(child: Text('Chưa có giao dịch nào.', style: TextStyle(color: Colors.grey, fontSize: 16)))
                : ListView.separated(
                    padding: const EdgeInsets.all(16),
                    itemCount: _transactions.length,
                    separatorBuilder: (context, index) => const Divider(height: 24),
                    itemBuilder: (context, index) {
                      final trans = _transactions[index];
                      final amount = trans['amount'] as int? ?? 0;
                      
                      // Xác định xem đây là giao dịch TRỪ TIỀN hay CỘNG TIỀN
                      final isExpense = trans['from_account'] == widget.accountNumber;
                      
                      final amountColor = isExpense ? Colors.red : Colors.green;
                      final amountPrefix = isExpense ? '-' : '+';
                      final typeIcon = isExpense ? Icons.arrow_upward : Icons.arrow_downward;
                      final iconColor = isExpense ? Colors.red[100] : Colors.green[100];
                      final typeText = trans['type'] == 'NAP_TIEN' 
                          ? 'Nạp tiền điện thoại' 
                          : (trans['type'] == 'MUA_TK' ? 'Mua tài khoản' : (isExpense ? 'Chuyển tiền' : 'Nhận tiền'));

                      return Row(
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          // Icon
                          Container(
                            padding: const EdgeInsets.all(10),
                            decoration: BoxDecoration(color: iconColor, shape: BoxShape.circle),
                            child: Icon(typeIcon, color: amountColor, size: 20),
                          ),
                          const SizedBox(width: 16),
                          
                          // Thông tin giao dịch
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(typeText, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                                const SizedBox(height: 4),
                                Text(_formatTime(trans['created_at']), style: const TextStyle(color: Colors.grey, fontSize: 13)),
                                if (trans['message'] != null && trans['message'].toString().isNotEmpty) ...[
                                  const SizedBox(height: 4),
                                  Text(trans['message'], style: const TextStyle(fontStyle: FontStyle.italic, color: Colors.black54, fontSize: 13), maxLines: 1, overflow: TextOverflow.ellipsis),
                                ]
                              ],
                            ),
                          ),
                          
                          // Số tiền
                          Text(
                            '$amountPrefix${formatMoney(amount)}',
                            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: amountColor),
                          ),
                        ],
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }
}