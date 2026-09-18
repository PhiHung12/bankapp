import 'package:flutter/material.dart';
import '../main.dart'; // Import để dùng hàm formatMoney

class TopUpSuccessScreen extends StatelessWidget {
  final int amount;
  final String phoneNumber;
  final String paymentAccount;
  final DateTime time;

  const TopUpSuccessScreen({
    super.key,
    required this.amount,
    required this.phoneNumber,
    required this.paymentAccount,
    required this.time,
  });

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
              // ICON THÀNH CÔNG
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.teal[100],
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.check_circle, color: Colors.teal, size: 80),
              ),
              const SizedBox(height: 24),
              
              const Text('Nạp tiền thành công', style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Colors.teal)),
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
                      _buildReceiptRow('Số điện thoại', phoneNumber, isBold: true),
                      const Divider(height: 24),
                      _buildReceiptRow('Tài khoản nguồn', paymentAccount),
                      const Divider(height: 24),
                      _buildReceiptRow('Dịch vụ', 'Nạp tiền điện thoại trả trước'),
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
                  style: ElevatedButton.styleFrom(backgroundColor: Colors.teal, foregroundColor: Colors.white),
                  onPressed: () {
                    // Lùi về tận màn hình Trang chủ
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