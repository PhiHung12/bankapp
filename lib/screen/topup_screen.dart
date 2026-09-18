import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../main.dart'; 
import 'topup_success_screen.dart';

class TopUpScreen extends StatefulWidget {
  final Map<String, dynamic> userData;
  const TopUpScreen({super.key, required this.userData});

  @override
  State<TopUpScreen> createState() => _TopUpScreenState();
}

class _TopUpScreenState extends State<TopUpScreen> {
  final _phoneController = TextEditingController();
  final _amountController = TextEditingController();
  final _formKey = GlobalKey<FormState>();

  List<dynamic> _myAccounts = [];
  dynamic _selectedAccount;
  bool _isLoading = true;
  bool _isProcessing = false;
  
  final Color primaryColor = const Color(0xFF009688); // Teal hiện đại

  @override
  void initState() {
    super.initState();
    _fetchAccounts();
  }

  // GIỮ NGUYÊN LOGIC FETCH ACCOUNTS
  Future<void> _fetchAccounts() async {
    final response = await Supabase.instance.client
        .from('bank_accounts')
        .select()
        .eq('user_id', widget.userData['id']);
    
    if(mounted){
      setState(() {
        _myAccounts = response;
        if (_myAccounts.isNotEmpty) {
          _selectedAccount = _myAccounts[0]; 
        }
        _isLoading = false;
      });
    }
  }

  // GIỮ NGUYÊN LOGIC XỬ LÝ NẠP TIỀN
  Future<void> _processTopUp() async {
    if (!_formKey.currentState!.validate()) return;
    
    if (_selectedAccount == null) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Vui lòng chọn tài khoản nguồn!')));
      return;
    }

    final int amount = int.parse(_amountController.text.replaceAll(RegExp(r'[^0-9]'), ''));
    final int currentBalance = _selectedAccount['balance'] as int? ?? 0;

    if (currentBalance < amount) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Tài khoản không đủ số dư!')));
      return;
    }

    setState(() => _isProcessing = true);

    try {
      final userResp = await Supabase.instance.client
          .from('users')
          .select('transaction_pin')
          .eq('id', widget.userData['id'])
          .single();
      
      final currentPin = userResp['transaction_pin'];
      setState(() => _isProcessing = false);

      if (currentPin == null || currentPin.toString().isEmpty) {
        _showCreatePinDialog(); 
      } else {
        _showEnterPinDialog(currentPin.toString()); 
      }
    } catch (e) {
      setState(() => _isProcessing = false);
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Lỗi kiểm tra PIN: $e')));
    }
  }

  // LÀM MỚI GIAO DIỆN DIALOG TẠO PIN
  void _showCreatePinDialog() {
    final pinController = TextEditingController();
    final confirmPinController = TextEditingController();
    
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Center(child: Text('Tạo Mã PIN', style: TextStyle(color: primaryColor, fontWeight: FontWeight.bold))),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('Tạo mã PIN 6 số để bảo mật.', textAlign: TextAlign.center, style: TextStyle(fontSize: 14)),
            const SizedBox(height: 20),
            TextField(controller: pinController, keyboardType: TextInputType.number, maxLength: 6, obscureText: true, decoration: InputDecoration(labelText: 'Mã PIN (6 số)', border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)), prefixIcon: const Icon(Icons.lock))),
            const SizedBox(height: 8),
            TextField(controller: confirmPinController, keyboardType: TextInputType.number, maxLength: 6, obscureText: true, decoration: InputDecoration(labelText: 'Nhập lại Mã PIN', border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)), prefixIcon: const Icon(Icons.lock_reset))),
          ],
        ),
        actionsAlignment: MainAxisAlignment.center,
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Hủy', style: TextStyle(color: Colors.grey))),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: primaryColor, foregroundColor: Colors.white, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
            onPressed: () async {
              final pin = pinController.text;
              if (pin.length != 6 || !RegExp(r'^\d{6}$').hasMatch(pin)) {
                ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Mã PIN phải là 6 chữ số!')));
                return;
              }
              if (pin != confirmPinController.text) {
                ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Mã PIN không khớp!')));
                return;
              }

              await Supabase.instance.client.from('users').update({'transaction_pin': pin}).eq('id', widget.userData['id']);
              
              if (mounted) {
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Tạo mã thành công! Đang xử lý...')));
                _executeTopUpLogic(); 
              }
            },
            child: const Text('Xác nhận'),
          ),
        ],
      ),
    );
  }

  // LÀM MỚI GIAO DIỆN DIALOG NHẬP PIN
  void _showEnterPinDialog(String savedPin) {
    final pinController = TextEditingController();
    
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Center(child: Text('Xác Thực Giao Dịch', style: TextStyle(color: primaryColor, fontWeight: FontWeight.bold))),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('Vui lòng nhập mã PIN 6 số.', textAlign: TextAlign.center),
            const SizedBox(height: 20),
            TextField(controller: pinController, keyboardType: TextInputType.number, maxLength: 6, obscureText: true, textAlign: TextAlign.center, style: const TextStyle(fontSize: 24, letterSpacing: 8, fontWeight: FontWeight.bold), decoration: InputDecoration(border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)), prefixIcon: const Icon(Icons.security))),
          ],
        ),
        actionsAlignment: MainAxisAlignment.center,
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Hủy', style: TextStyle(color: Colors.grey))),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: primaryColor, foregroundColor: Colors.white, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
            onPressed: () {
              if (pinController.text != savedPin) {
                ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Sai mã PIN! Vui lòng thử lại.')));
                return;
              }
              Navigator.pop(context); 
              _executeTopUpLogic(); 
            },
            child: const Text('Thanh Toán'),
          ),
        ],
      ),
    );
  }

  // GIỮ NGUYÊN LOGIC TRỪ TIỀN VÀ GHI LOG
  Future<void> _executeTopUpLogic() async {
    setState(() => _isProcessing = true);
    final int amount = int.parse(_amountController.text.replaceAll(RegExp(r'[^0-9]'), ''));
    final int currentBalance = _selectedAccount['balance'] as int? ?? 0;

    try {
      final newBalance = currentBalance - amount;
      await Supabase.instance.client
          .from('bank_accounts')
          .update({'balance': newBalance})
          .eq('id', _selectedAccount['id']);

      await Supabase.instance.client.from('transactions').insert({
        'user_id': widget.userData['id'],
        'from_account': _selectedAccount['account_number'],
        'to_account': 'NẠP ĐIỆN THOẠI', 
        'amount': amount,
        'type': 'NAP_TIEN',
        'message': 'Nạp tiền cho số ${_phoneController.text.trim()}',
      });

      if (mounted) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (context) => TopUpSuccessScreen(
              amount: amount,
              phoneNumber: _phoneController.text,
              paymentAccount: _selectedAccount['account_number'],
              time: DateTime.now(),
            ),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Lỗi: $e')));
      }
    } finally {
      if (mounted) setState(() => _isProcessing = false);
    }
  }

  // GIAO DIỆN INPUT DÙNG CHUNG
  InputDecoration _buildInputDecoration(String hint, IconData icon) {
    return InputDecoration(
      hintText: hint,
      filled: true,
      fillColor: Colors.white,
      prefixIcon: Icon(icon, color: primaryColor),
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide.none),
      focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide(color: primaryColor, width: 2)),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FA),
      appBar: AppBar(
        title: const Text('Nạp tiền điện thoại', style: TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
        foregroundColor: Colors.black87,
      ),
      body: _isLoading || _isProcessing
          ? Center(child: CircularProgressIndicator(color: primaryColor))
          : SingleChildScrollView(
              padding: const EdgeInsets.all(20.0),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Tài khoản thanh toán', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Colors.black87)),
                    const SizedBox(height: 12),
                    Container(
                      decoration: BoxDecoration(boxShadow: [BoxShadow(color: Colors.grey.shade200, blurRadius: 10, offset: const Offset(0, 5))]),
                      child: DropdownButtonFormField<dynamic>(
                        value: _selectedAccount,
                        decoration: _buildInputDecoration('', Icons.account_balance_wallet),
                        icon: const Icon(Icons.keyboard_arrow_down),
                        items: _myAccounts.map((acc) {
                          final balance = acc['balance'] as int? ?? 0;
                          return DropdownMenuItem<dynamic>(
                            value: acc,
                            child: Text('${acc['account_number']} - ${formatMoney(balance)} VND', style: const TextStyle(fontWeight: FontWeight.w600)),
                          );
                        }).toList(),
                        onChanged: (newValue) => setState(() => _selectedAccount = newValue),
                      ),
                    ),
                    const SizedBox(height: 24),

                    const Text('Số điện thoại nạp tiền', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Colors.black87)),
                    const SizedBox(height: 12),
                    Container(
                      decoration: BoxDecoration(boxShadow: [BoxShadow(color: Colors.grey.shade200, blurRadius: 10, offset: const Offset(0, 5))]),
                      child: TextFormField(
                        controller: _phoneController,
                        keyboardType: TextInputType.phone,
                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
                        decoration: _buildInputDecoration('Nhập số điện thoại...', Icons.phone_android),
                        validator: (value) {
                          if (value == null || !RegExp(r'^0[89]\d{8}$').hasMatch(value)) return 'SĐT phải đủ 10 số và bắt đầu bằng 08 hoặc 09';
                          return null;
                        },
                      ),
                    ),
                    const SizedBox(height: 24),

                    const Text('Mệnh giá nạp', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Colors.black87)),
                    const SizedBox(height: 12),
                    Container(
                      decoration: BoxDecoration(boxShadow: [BoxShadow(color: Colors.grey.shade200, blurRadius: 10, offset: const Offset(0, 5))]),
                      child: TextFormField(
                        controller: _amountController,
                        keyboardType: TextInputType.number,
                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
                        decoration: _buildInputDecoration('Nhập số tiền (VD: 50000)', Icons.attach_money),
                        validator: (value) {
                          if (value == null || value.isEmpty || int.tryParse(value) == null || int.parse(value) <= 0) return 'Vui lòng nhập số tiền hợp lệ';
                          return null;
                        },
                      ),
                    ),
                    const SizedBox(height: 40),

                    SizedBox(
                      width: double.infinity,
                      height: 56,
                      child: ElevatedButton(
                        onPressed: _processTopUp,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: primaryColor,
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                          elevation: 2
                        ),
                        child: const Text('Xác nhận nạp tiền', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                      ),
                    ),
                  ],
                ),
              ),
            ),
    );
  }
}