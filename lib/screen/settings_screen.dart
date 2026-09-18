import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../main.dart'; // Import để dùng LoginScreen cho chức năng Đăng xuất

// Khai báo màu chuẩn Premium
const Color _primaryColor = Color(0xFF0F2C59);
const Color _bgColor = Color(0xFFF5F7FA);

class SettingsScreen extends StatefulWidget {
  final Map<String, dynamic> userData;
  const SettingsScreen({super.key, required this.userData});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  
  // ==========================================
  // HÀM MỚI: HIỂN THỊ POPUP ĐỔI SỐ ĐIỆN THOẠI
  // ==========================================
  void _showEditPhoneDialog() {
    final phoneController = TextEditingController(text: widget.userData['phone_number']);
    bool isProcessing = false;

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
              title: const Text('Đổi Số Điện Thoại', style: TextStyle(color: _primaryColor, fontWeight: FontWeight.bold, fontSize: 20)),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text('Vui lòng nhập số điện thoại mới của bạn.', style: TextStyle(fontSize: 14, color: Colors.grey)),
                  const SizedBox(height: 16),
                  TextField(
                    controller: phoneController,
                    keyboardType: TextInputType.phone,
                    decoration: InputDecoration(
                      labelText: 'Số điện thoại', 
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)), 
                      prefixIcon: const Icon(Icons.phone_android, color: _primaryColor)
                    ),
                  ),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: isProcessing ? null : () => Navigator.pop(context), 
                  child: const Text('Hủy', style: TextStyle(color: Colors.grey))
                ),
                ElevatedButton(
                  onPressed: isProcessing ? null : () async {
                    final newPhone = phoneController.text.trim();

                    if (newPhone.isEmpty || !RegExp(r'^0\d{9}$').hasMatch(newPhone)) {
                      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Số điện thoại không hợp lệ (Phải bắt đầu bằng 0 và có 10 số)!')));
                      return;
                    }

                    setDialogState(() => isProcessing = true);

                    try {
                      // 1. Cập nhật lên Database
                      await Supabase.instance.client
                          .from('users')
                          .update({'phone_number': newPhone})
                          .eq('id', widget.userData['id']);
                      
                      // 2. Cập nhật lại UI hiện tại
                      setState(() {
                        widget.userData['phone_number'] = newPhone;
                      });
                      
                      if (context.mounted) {
                        Navigator.pop(context); // Đóng popup
                        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Cập nhật số điện thoại thành công!')));
                      }
                    } catch (e) {
                      if (context.mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Lỗi: Số điện thoại này có thể đã được đăng ký!')));
                        setDialogState(() => isProcessing = false);
                      }
                    }
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: _primaryColor, 
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))
                  ),
                  child: isProcessing 
                      ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2)) 
                      : const Text('Lưu thay đổi'),
                ),
              ],
            );
          }
        );
      },
    );
  }

  // ==========================================
  // HÀM HIỂN THỊ POPUP ĐỔI MÀ PIN / OTP (ĐÃ LÀM ĐẸP UI)
  // ==========================================
  void _showChangePinDialog() {
    final oldPinController = TextEditingController();
    final newPinController = TextEditingController();
    final confirmPinController = TextEditingController();
    bool isProcessing = false;

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) {
        return StatefulBuilder( 
          builder: (context, setDialogState) {
            return AlertDialog(
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
              title: const Text('Đổi Mã PIN / OTP', style: TextStyle(color: _primaryColor, fontWeight: FontWeight.bold, fontSize: 20)),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Text('Vui lòng nhập mã PIN hiện tại và mã PIN mới (6 chữ số).', style: TextStyle(fontSize: 14, color: Colors.grey)),
                    const SizedBox(height: 16),
                    TextField(
                      controller: oldPinController,
                      keyboardType: TextInputType.number,
                      maxLength: 6,
                      obscureText: true,
                      decoration: InputDecoration(labelText: 'Mã PIN hiện tại', border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)), prefixIcon: const Icon(Icons.password, color: _primaryColor)),
                    ),
                    const SizedBox(height: 8),
                    TextField(
                      controller: newPinController,
                      keyboardType: TextInputType.number,
                      maxLength: 6,
                      obscureText: true,
                      decoration: InputDecoration(labelText: 'Mã PIN mới', border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)), prefixIcon: const Icon(Icons.lock_outline, color: _primaryColor)),
                    ),
                    const SizedBox(height: 8),
                    TextField(
                      controller: confirmPinController,
                      keyboardType: TextInputType.number,
                      maxLength: 6,
                      obscureText: true,
                      decoration: InputDecoration(labelText: 'Xác nhận Mã PIN mới', border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)), prefixIcon: const Icon(Icons.lock_reset, color: _primaryColor)),
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: isProcessing ? null : () => Navigator.pop(context), 
                  child: const Text('Hủy', style: TextStyle(color: Colors.grey))
                ),
                ElevatedButton(
                  onPressed: isProcessing ? null : () async {
                    final oldPin = oldPinController.text;
                    final newPin = newPinController.text;
                    final confirmPin = confirmPinController.text;

                    if (oldPin.isEmpty || newPin.isEmpty || confirmPin.isEmpty) {
                      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Vui lòng nhập đầy đủ thông tin!')));
                      return;
                    }
                    if (newPin.length != 6 || !RegExp(r'^\d{6}$').hasMatch(newPin)) {
                      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Mã PIN mới phải đúng 6 chữ số!')));
                      return;
                    }
                    if (newPin != confirmPin) {
                      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Mã PIN mới không khớp!')));
                      return;
                    }

                    setDialogState(() => isProcessing = true);

                    try {
                      final userResp = await Supabase.instance.client
                          .from('users')
                          .select('transaction_pin')
                          .eq('id', widget.userData['id'])
                          .single();
                      
                      final currentPinDB = userResp['transaction_pin'];

                      if (currentPinDB != null && currentPinDB.toString().isNotEmpty) {
                        if (oldPin != currentPinDB.toString()) {
                          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Mã PIN hiện tại không chính xác!')));
                          setDialogState(() => isProcessing = false);
                          return;
                        }
                      } else {
                        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Bạn chưa tạo mã PIN nào để đổi. Hãy thực hiện giao dịch để tạo mới!')));
                        setDialogState(() => isProcessing = false);
                        return;
                      }

                      await Supabase.instance.client
                          .from('users')
                          .update({'transaction_pin': newPin})
                          .eq('id', widget.userData['id']);
                      
                      if (context.mounted) {
                        Navigator.pop(context); 
                        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Cập nhật mã PIN / OTP thành công!')));
                      }
                    } catch (e) {
                      if (context.mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Lỗi: $e')));
                        setDialogState(() => isProcessing = false);
                      }
                    }
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: _primaryColor, 
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))
                  ),
                  child: isProcessing 
                      ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2)) 
                      : const Text('Lưu thay đổi'),
                ),
              ],
            );
          }
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _bgColor,
      appBar: AppBar(
        title: const Text('Cài đặt', style: TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: Colors.transparent,
        foregroundColor: _primaryColor,
        elevation: 0,
        centerTitle: true,
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // KHỐI THÔNG TIN KHÁCH HÀNG (CÓ NÚT EDIT)
          Container(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(20),
              boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10, offset: const Offset(0, 4))],
            ),
            padding: const EdgeInsets.all(20),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: _primaryColor.withOpacity(0.1),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.person, color: _primaryColor, size: 40),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(widget.userData['full_name']?.toString().toUpperCase() ?? 'KHÁCH HÀNG', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18, color: _primaryColor)),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          const Icon(Icons.phone_android, size: 14, color: Colors.grey),
                          const SizedBox(width: 4),
                          Text(widget.userData['phone_number'] ?? 'Chưa cập nhật', style: const TextStyle(color: Colors.black87, fontWeight: FontWeight.w500)),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          const Icon(Icons.badge, size: 14, color: Colors.grey),
                          const SizedBox(width: 4),
                          Text(widget.userData['cccd_number'] ?? 'Chưa cập nhật', style: const TextStyle(color: Colors.grey)),
                        ],
                      ),
                    ],
                  ),
                ),
                // NÚT SỬA SỐ ĐIỆN THOẠI
                IconButton(
                  onPressed: _showEditPhoneDialog,
                  icon: const Icon(Icons.edit_square, color: _primaryColor),
                  tooltip: 'Chỉnh sửa thông tin',
                ),
              ],
            ),
          ),
          
          const SizedBox(height: 32),
          const Padding(
            padding: EdgeInsets.only(left: 4),
            child: Text('BẢO MẬT & TÀI KHOẢN', style: TextStyle(color: Colors.grey, fontWeight: FontWeight.bold, fontSize: 13, letterSpacing: 1.2)),
          ),
          const SizedBox(height: 12),
          
          // NÚT ĐỔI MÃ PIN
          Container(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10)],
            ),
            child: ListTile(
              contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              leading: Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(color: Colors.orange.withOpacity(0.15), borderRadius: BorderRadius.circular(12)),
                child: const Icon(Icons.password, color: Colors.orange),
              ),
              title: const Text('Đổi mã PIN / OTP Giao dịch', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 16)),
              trailing: const Icon(Icons.arrow_forward_ios, size: 16, color: Colors.grey),
              onTap: _showChangePinDialog, 
            ),
          ),
          
          const SizedBox(height: 16),
          
          // NÚT ĐĂNG XUẤT (ĐÃ SỬA LỖI NAVIGATOR)
          Container(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10)],
            ),
            child: ListTile(
              contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              leading: Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(color: Colors.red.withOpacity(0.15), borderRadius: BorderRadius.circular(12)),
                child: const Icon(Icons.logout, color: Colors.red),
              ),
              title: const Text('Đăng xuất', style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold, fontSize: 16)),
              onTap: () {
                // Sửa lỗi: Xóa toàn bộ lịch sử màn hình và đẩy về LoginScreen
                Navigator.pushAndRemoveUntil(
                  context,
                  MaterialPageRoute(builder: (context) => const LoginScreen()),
                  (Route<dynamic> route) => false,
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}