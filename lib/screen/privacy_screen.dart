import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class PrivacyScreen extends StatefulWidget {
  final Map<String, dynamic> userData;
  const PrivacyScreen({super.key, required this.userData});

  @override
  State<PrivacyScreen> createState() => _PrivacyScreenState();
}

class _PrivacyScreenState extends State<PrivacyScreen> {
  // Hàm hiển thị hộp thoại đổi Số điện thoại
  void _showEditPhoneDialog() {
    final phoneController = TextEditingController(text: widget.userData['phone_number']);
    final formKey = GlobalKey<FormState>();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Đổi Số điện thoại'),
        content: Form(
          key: formKey,
          child: TextFormField(
            controller: phoneController,
            keyboardType: TextInputType.phone,
            decoration: const InputDecoration(labelText: 'Số điện thoại mới', border: OutlineInputBorder()),
            validator: (value) {
              if (value == null || !RegExp(r'^0[89]\d{8}$').hasMatch(value)) {
                return 'SĐT phải có 10 số và bắt đầu bằng 08 hoặc 09';
              }
              return null;
            },
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Hủy')),
          ElevatedButton(
            onPressed: () async {
              if (formKey.currentState!.validate()) {
                try {
                  // Cập nhật lên Supabase
                  await Supabase.instance.client
                      .from('users')
                      .update({'phone_number': phoneController.text})
                      .eq('id', widget.userData['id']);
                  
                  setState(() {
                    widget.userData['phone_number'] = phoneController.text; // Cập nhật lại giao diện
                  });
                  if (context.mounted) {
                    Navigator.pop(context);
                    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Đổi số điện thoại thành công!')));
                  }
                } catch (e) {
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Lỗi: Số điện thoại này đã được sử dụng!')));
                  }
                }
              }
            },
            child: const Text('Cập nhật'),
          ),
        ],
      ),
    );
  }

  // Hàm hiển thị hộp thoại đổi Mật khẩu
  void _showEditPasswordDialog() {
    final oldPassController = TextEditingController();
    final newPassController = TextEditingController();
    final formKey = GlobalKey<FormState>();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Đổi Mật khẩu'),
        content: Form(
          key: formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextFormField(
                controller: oldPassController,
                obscureText: true,
                decoration: const InputDecoration(labelText: 'Mật khẩu hiện tại', border: OutlineInputBorder()),
                validator: (value) => value!.isEmpty ? 'Vui lòng nhập mật khẩu cũ' : null,
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: newPassController,
                obscureText: true,
                decoration: const InputDecoration(labelText: 'Mật khẩu mới', border: OutlineInputBorder()),
                validator: (value) {
                  if (value == null || !RegExp(r'^(?=.*[A-Z])(?=.*\d)(?=.*[\W_]).{8,}$').hasMatch(value)) {
                    return 'Mật khẩu phải > 8 kí tự, có chữ hoa, số và kí tự đặc biệt';
                  }
                  return null;
                },
              ),
            ],
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Hủy')),
          ElevatedButton(
            onPressed: () async {
              if (formKey.currentState!.validate()) {
                // Kiểm tra mật khẩu cũ có khớp không
                if (oldPassController.text != widget.userData['password_hash']) {
                  ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Mật khẩu hiện tại không đúng!')));
                  return;
                }

                try {
                  // Cập nhật mật khẩu mới lên Supabase
                  await Supabase.instance.client
                      .from('users')
                      .update({'password_hash': newPassController.text})
                      .eq('id', widget.userData['id']);
                  
                  setState(() {
                    widget.userData['password_hash'] = newPassController.text; 
                  });
                  if (context.mounted) {
                    Navigator.pop(context);
                    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Đổi mật khẩu thành công!')));
                  }
                } catch (e) {
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Lỗi: $e')));
                  }
                }
              }
            },
            child: const Text('Cập nhật'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[100],
      appBar: AppBar(
        title: const Text('Quyền riêng tư'),
        backgroundColor: Colors.blue[700],
        foregroundColor: Colors.white,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('THÔNG TIN CÁ NHÂN', style: TextStyle(color: Colors.grey, fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            Card(
              child: Column(
                children: [
                  ListTile(
                    leading: const Icon(Icons.person),
                    title: const Text('Họ và tên'),
                    subtitle: Text(widget.userData['full_name'] ?? 'Chưa cập nhật'),
                  ),
                  const Divider(height: 0),
                  ListTile(
                    leading: const Icon(Icons.credit_card),
                    title: const Text('Số CCCD'),
                    subtitle: Text(widget.userData['cccd_number'] ?? 'Chưa cập nhật'),
                  ),
                  const Divider(height: 0),
                  ListTile(
                    leading: const Icon(Icons.phone),
                    title: const Text('Số điện thoại'),
                    subtitle: Text(widget.userData['phone_number'] ?? 'Chưa cập nhật'),
                    trailing: const Icon(Icons.edit, color: Colors.blue), // Icon bấm sửa
                    onTap: _showEditPhoneDialog,
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),
            const Text('BẢO MẬT', style: TextStyle(color: Colors.grey, fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            Card(
              child: ListTile(
                leading: const Icon(Icons.lock),
                title: const Text('Đổi mật khẩu'),
                trailing: const Icon(Icons.arrow_forward_ios, size: 16),
                onTap: _showEditPasswordDialog,
              ),
            ),
          ],
        ),
      ),
    );
  }
}