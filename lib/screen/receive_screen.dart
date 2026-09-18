import 'package:flutter/material.dart';
import 'package:flutter/services.dart'; // Để dùng tính năng Copy
import 'package:qr_flutter/qr_flutter.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../main.dart'; 

class ReceiveScreen extends StatefulWidget {
  final Map<String, dynamic> userData;
  const ReceiveScreen({super.key, required this.userData});

  @override
  State<ReceiveScreen> createState() => _ReceiveScreenState();
}

class _ReceiveScreenState extends State<ReceiveScreen> {
  List<dynamic> _myAccounts = [];
  dynamic _selectedAccount;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _fetchAccounts();
  }

  Future<void> _fetchAccounts() async {
    final response = await Supabase.instance.client
        .from('bank_accounts')
        .select()
        .eq('user_id', widget.userData['id']);
    
    setState(() {
      _myAccounts = response;
      if (_myAccounts.isNotEmpty) {
        _selectedAccount = _myAccounts[0]; 
      }
      _isLoading = false;
    });
  }

  // Hàm copy STK vào khay nhớ tạm
  void _copyToClipboard(String text) {
    Clipboard.setData(ClipboardData(text: text));
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Đã sao chép Số tài khoản!')),
    );
  }

  @override
  Widget build(BuildContext context) {
    // Chuỗi dữ liệu sẽ được nhúng vào mã QR (Ví dụ: HN_BANK|0987654321)
    // Sau này làm tính năng quét QR, máy ảnh chỉ cần đọc chuỗi này và tách lấy STK
    final String qrData = _selectedAccount != null 
        ? 'HN_BANK|${_selectedAccount['account_number']}' 
        : 'NO_DATA';

    return Scaffold(
      backgroundColor: Colors.grey[100],
      appBar: AppBar(
        title: const Text('Nhận tiền (Mã QR)'),
        backgroundColor: Colors.green,
        foregroundColor: Colors.white,
      ),
      body: _isLoading 
          ? const Center(child: CircularProgressIndicator())
          : Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  const Text('Chọn tài khoản nhận tiền', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                  const SizedBox(height: 8),
                  
                  // DROPDOWN CHỌN TÀI KHOẢN
                  DropdownButtonFormField<dynamic>(
                    value: _selectedAccount,
                    decoration: const InputDecoration(
                      border: OutlineInputBorder(), 
                      prefixIcon: Icon(Icons.account_balance_wallet, color: Colors.green),
                      fillColor: Colors.white,
                      filled: true,
                    ),
                    items: _myAccounts.map((acc) {
                      return DropdownMenuItem<dynamic>(
                        value: acc,
                        child: Text(acc['account_number']),
                      );
                    }).toList(),
                    onChanged: (newValue) => setState(() => _selectedAccount = newValue),
                  ),
                  
                  const SizedBox(height: 40),

                  // KHỐI VẼ MÃ QR
                  Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(20),
                      boxShadow: [
                        BoxShadow(color: Colors.grey.withOpacity(0.3), blurRadius: 10, spreadRadius: 2)
                      ],
                    ),
                    child: Column(
                      children: [
                        const Text('Quét mã này để chuyển tiền cho tôi', style: TextStyle(color: Colors.grey, fontSize: 14)),
                        const SizedBox(height: 16),
                        
                        // VẼ QR CODE TỪ THƯ VIỆN
                        QrImageView(
                          data: qrData, // Dữ liệu nhúng vào QR
                          version: QrVersions.auto,
                          size: 250.0,
                          backgroundColor: Colors.white,
                        ),
                        
                        const SizedBox(height: 16),
                        Text(
                          widget.userData['full_name'].toString().toUpperCase(),
                          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18, color: Colors.green),
                        ),
                        const SizedBox(height: 4),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(
                              _selectedAccount?['account_number'] ?? '',
                              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                            ),
                            IconButton(
                              icon: const Icon(Icons.copy, size: 20, color: Colors.grey),
                              onPressed: () => _copyToClipboard(_selectedAccount?['account_number'] ?? ''),
                            )
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
    );
  }
}