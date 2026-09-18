import 'package:flutter/material.dart';
import '../main.dart'; // Import để dùng hàm formatMoney

class TransferSuccessScreen extends StatelessWidget {
  final int amount;
  final String receiverName;
  final String receiverAccount;
  final String targetBank;
  final String message;
  final DateTime time;

  const TransferSuccessScreen({
    super.key,
    required this.amount,
    required this.receiverName,
    required this.receiverAccount,
    required this.targetBank,
    required this.message,
    required this.time,
  });

  // Hàm fomat thời gian cho đẹp (VD: 14:30 - 15/09/2026)
  String _formatTime(DateTime dt) {
    return '${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')} - ${dt.day.toString().padLeft(2, '0')}/${dt.month.toString().padLeft(2, '0')}/${dt.year}';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[100],
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // ICON TÍCH XANH THÀNH CÔNG
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.green[100],
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.check_circle, color: Colors.green, size: 80),
              ),
              const SizedBox(height: 24),
              
              const Text('Chuyển tiền thành công', style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Colors.green)),
              const SizedBox(height: 8),
              Text('${formatMoney(amount)} VND', style: const TextStyle(fontSize: 32, fontWeight: FontWeight.bold)),
              
              const SizedBox(height: 32),
              
              // THẺ BIÊN LAI
              Card(
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
                elevation: 4,
                child: Padding(
                  padding: const EdgeInsets.all(20.0),
                  child: Column(
                    children: [
                      _buildReceiptRow('Người nhận', receiverName.toUpperCase(), isBold: true),
                      const Divider(height: 24),
                      _buildReceiptRow('Số tài khoản', receiverAccount),
                      const Divider(height: 24),
                      _buildReceiptRow('Ngân hàng', targetBank),
                      const Divider(height: 24),
                      _buildReceiptRow('Lời nhắn', message),
                      const Divider(height: 24),
                      _buildReceiptRow('Thời gian', _formatTime(time)),
                    ],
                  ),
                ),
              ),
              
              const Spacer(),
              
              // NÚT VỀ TRANG CHỦ
              SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(backgroundColor: Colors.blue[700], foregroundColor: Colors.white),
                  onPressed: () {
                    // Lùi về tận màn hình Trang chủ (Home)
                    Navigator.popUntil(context, (route) => route.isFirst);
                  },
                  child: const Text('Về Trang Chủ', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                ),
              ),
              const SizedBox(height: 16),
            ],
          ),
        ),
      ),
    );
  }

  // Hàm vẽ từng dòng trong biên lai
  Widget _buildReceiptRow(String title, String value, {bool isBold = false}) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(title, style: const TextStyle(color: Colors.grey, fontSize: 15)),
        const SizedBox(width: 16),
        Expanded(
          child: Text(
            value, 
            textAlign: TextAlign.right,
            style: TextStyle(
              fontSize: 15, 
              fontWeight: isBold ? FontWeight.bold : FontWeight.w500,
            ),
          ),
        ),
      ],
    );
  }
}