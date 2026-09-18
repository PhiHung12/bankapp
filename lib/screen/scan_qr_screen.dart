import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'transfer_screen.dart';

class ScanQRScreen extends StatefulWidget {
  final Map<String, dynamic> userData;
  const ScanQRScreen({super.key, required this.userData});

  @override
  State<ScanQRScreen> createState() => _ScanQRScreenState();
}

class _ScanQRScreenState extends State<ScanQRScreen> {
  bool _isScanned = false; 
  bool _isShowingError = false; // THÊM BIẾN NÀY: Khóa báo lỗi để không bị spam

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Quét mã QR'),
        backgroundColor: Colors.blue[900],
        foregroundColor: Colors.white,
      ),
      body: MobileScanner(
        onDetect: (capture) {
          if (_isScanned) return; 

          final List<Barcode> barcodes = capture.barcodes;
          for (final barcode in barcodes) {
            final String rawData = barcode.rawValue ?? '';
            
            if (rawData.startsWith('HN_BANK|')) {
              _isScanned = true; 
              
              final String accountNumber = rawData.split('|')[1];

              Navigator.pushReplacement(
                context,
                MaterialPageRoute(
                  builder: (context) => TransferScreen(
                    userData: widget.userData,
                    initialReceiverAccount: accountNumber, 
                  ),
                ),
              );
              break; 
            } else {
              // XỬ LÝ KHÔNG SPAM LỖI: Chỉ báo lỗi khi khóa đang mở
              if (!_isShowingError) {
                _isShowingError = true; // Khóa lại ngay lập tức
                
                // Dọn sạch các thông báo cũ đang kẹt trên màn hình
                ScaffoldMessenger.of(context).clearSnackBars();
                
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Mã QR không thuộc HN BANK!')),
                );

                // Cài giờ: 3 giây sau mới mở khóa báo lỗi tiếp
                Future.delayed(const Duration(seconds: 3), () {
                  if (mounted) {
                    _isShowingError = false;
                  }
                });
              }
            }
          }
        },
      ),
    );
  }
}