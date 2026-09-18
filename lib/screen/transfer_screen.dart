import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../main.dart'; 
import 'transfer_success_screen.dart';

class TransferScreen extends StatefulWidget {
  final Map<String, dynamic> userData;
  final String? initialReceiverAccount;
  
  const TransferScreen({super.key, required this.userData, this.initialReceiverAccount});

  @override
  State<TransferScreen> createState() => _TransferScreenState();
}

class _TransferScreenState extends State<TransferScreen> {
  final _receiverController = TextEditingController();
  final _amountController = TextEditingController();
  final _messageController = TextEditingController(text: 'Chuyen tien');
  final _formKey = GlobalKey<FormState>();
  
  final _receiverFocusNode = FocusNode(); 

  List<dynamic> _myAccounts = [];
  dynamic _selectedAccount;
  bool _isLoading = true;
  bool _isProcessing = false;

  String? _receiverName;
  bool _isSearchingName = false;

  final List<Map<String, dynamic>> _mockBanks = [
    {'name': 'HN BANK (Nội bộ)', 'color': Colors.blue},
    {'name': 'MB Bank', 'color': Colors.indigo},
    {'name': 'VietinBank', 'color': Colors.red},
    {'name': 'Vietcombank', 'color': Colors.green},
    {'name': 'Techcombank', 'color': Colors.redAccent},
  ];
  String _selectedTargetBank = 'HN BANK (Nội bộ)';

  final Color primaryColor = const Color(0xFFFF9800); // Orange hiện đại

  @override
  void initState() {
    super.initState();
    _fetchAccounts();

    _receiverFocusNode.addListener(() {
      if (!_receiverFocusNode.hasFocus) {
        _checkReceiverName();
      }
    });

    if (widget.initialReceiverAccount != null) {
      _receiverController.text = widget.initialReceiverAccount!;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _checkReceiverName();
      });
    }
  }

  @override
  void dispose() {
    _receiverFocusNode.dispose();
    _receiverController.dispose();
    _amountController.dispose();
    _messageController.dispose();
    super.dispose();
  }

  // GIỮ NGUYÊN LOGIC FETCH ACCOUNTS
  Future<void> _fetchAccounts() async {
    final response = await Supabase.instance.client
        .from('bank_accounts')
        .select()
        .eq('user_id', widget.userData['id']);
    
    if(mounted) {
      setState(() {
        _myAccounts = response;
        if (_myAccounts.isNotEmpty) {
          _selectedAccount = _myAccounts[0]; 
        }
        _isLoading = false;
      });
    }
  }

  // GIỮ NGUYÊN LOGIC TÌM TÊN NGƯỜI NHẬN
  Future<void> _checkReceiverName() async {
    final accNum = _receiverController.text.trim();
    if (accNum.isEmpty) {
      setState(() => _receiverName = null);
      return;
    }

    setState(() => _isSearchingName = true);

    try {
      final accData = await Supabase.instance.client
          .from('bank_accounts')
          .select('user_id')
          .eq('account_number', accNum)
          .maybeSingle();

      if (accData != null) {
        final userData = await Supabase.instance.client
            .from('users')
            .select('full_name')
            .eq('id', accData['user_id'])
            .maybeSingle();

        if (mounted) {
          setState(() {
            _receiverName = userData?['full_name'] ?? 'Không xác định';
          });
        }
      } else {
        if (mounted) setState(() => _receiverName = 'TÀI KHOẢN KHÔNG TỒN TẠI');
      }
    } catch (e) {
      if (mounted) setState(() => _receiverName = 'LỖI MẠNG');
    } finally {
      if (mounted) setState(() => _isSearchingName = false);
    }
  }

  // GIỮ NGUYÊN LOGIC KIỂM TRA ĐIỀU KIỆN
  Future<void> _processTransfer() async {
    if (!_formKey.currentState!.validate()) return;
    
    if (_selectedAccount == null) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Vui lòng chọn tài khoản nguồn!')));
      return;
    }
    
    if (_receiverName == null || _receiverName == 'TÀI KHOẢN KHÔNG TỒN TẠI' || _receiverName == 'LỖI MẠNG') {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Vui lòng kiểm tra lại tài khoản người nhận!')));
      return;
    }

    final receiverAccountNum = _receiverController.text.trim();
    final amount = int.parse(_amountController.text.replaceAll(RegExp(r'[^0-9]'), ''));
    final currentBalance = _selectedAccount['balance'] as int? ?? 0;

    if (receiverAccountNum == _selectedAccount['account_number']) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Không thể tự chuyển tiền cho chính mình!')));
      return;
    }

    if (currentBalance < amount) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Số dư không đủ!')));
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
            const Text('Tạo mã PIN 6 số để bảo mật giao dịch.', textAlign: TextAlign.center, style: TextStyle(fontSize: 14, color: Colors.grey)),
            const SizedBox(height: 20),
            TextField(
              controller: pinController,
              keyboardType: TextInputType.number,
              maxLength: 6,
              obscureText: true,
              decoration: InputDecoration(
                labelText: 'Mã PIN (6 số)', 
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)), 
                prefixIcon: const Icon(Icons.lock)
              ),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: confirmPinController,
              keyboardType: TextInputType.number,
              maxLength: 6,
              obscureText: true,
              decoration: InputDecoration(
                labelText: 'Nhập lại Mã PIN', 
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)), 
                prefixIcon: const Icon(Icons.lock_reset)
              ),
            ),
          ],
        ),
        actionsAlignment: MainAxisAlignment.center,
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Hủy', style: TextStyle(color: Colors.grey))),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: primaryColor, foregroundColor: Colors.white, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
            onPressed: () async {
              final pin = pinController.text;
              final confirmPin = confirmPinController.text;

              if (pin.length != 6 || !RegExp(r'^\d{6}$').hasMatch(pin)) {
                ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Mã PIN phải là 6 chữ số!')));
                return;
              }
              if (pin != confirmPin) {
                ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Mã PIN không khớp!')));
                return;
              }

              await Supabase.instance.client
                  .from('users')
                  .update({'transaction_pin': pin})
                  .eq('id', widget.userData['id']);
              
              if (mounted) {
                Navigator.pop(context); 
                ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Tạo mã thành công! Đang xử lý...')));
                _executeTransferLogic(); 
              }
            },
            child: const Text('Xác nhận & Chuyển'),
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
            const Text('Vui lòng nhập mã PIN 6 số.', textAlign: TextAlign.center, style: TextStyle(fontSize: 14)),
            const SizedBox(height: 20),
            TextField(
              controller: pinController,
              keyboardType: TextInputType.number,
              maxLength: 6,
              obscureText: true,
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 24, letterSpacing: 8, fontWeight: FontWeight.bold),
              decoration: InputDecoration(
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)), 
                prefixIcon: const Icon(Icons.security)
              ),
            ),
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
              _executeTransferLogic(); 
            },
            child: const Text('Thanh Toán'),
          ),
        ],
      ),
    );
  }

  // GIỮ NGUYÊN LOGIC TRỪ TIỀN
  Future<void> _executeTransferLogic() async {
    setState(() => _isProcessing = true);
    
    final receiverAccountNum = _receiverController.text.trim();
    final amount = int.parse(_amountController.text.replaceAll(RegExp(r'[^0-9]'), ''));
    final currentBalance = _selectedAccount['balance'] as int? ?? 0;

    try {
      final receiverResp = await Supabase.instance.client
          .from('bank_accounts')
          .select()
          .eq('account_number', receiverAccountNum)
          .single();

      await Supabase.instance.client
          .from('bank_accounts')
          .update({'balance': currentBalance - amount})
          .eq('id', _selectedAccount['id']);

      final receiverBalance = receiverResp['balance'] as int? ?? 0;
      await Supabase.instance.client
          .from('bank_accounts')
          .update({'balance': receiverBalance + amount})
          .eq('id', receiverResp['id']);

      await Supabase.instance.client.from('transactions').insert({
        'user_id': widget.userData['id'],
        'from_account': _selectedAccount['account_number'],
        'to_account': receiverAccountNum,
        'amount': amount,
        'type': 'CHUYEN_TIEN',
        'message': _messageController.text.trim(),
      });

      if (mounted) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (context) => TransferSuccessScreen(
              amount: amount,
              receiverName: _receiverName ?? 'Khách hàng',
              receiverAccount: receiverAccountNum,
              targetBank: _selectedTargetBank,
              message: _messageController.text.trim(),
              time: DateTime.now(),
            ),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Lỗi giao dịch: $e')));
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
      backgroundColor: const Color(0xFFF5F7FA), // Xanh xám nhạt
      appBar: AppBar(
        title: const Text('Chuyển tiền', style: TextStyle(fontWeight: FontWeight.bold)),
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
                    const Text('Từ tài khoản', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Colors.black87)),
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

                    const Text('Đến ngân hàng', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Colors.black87)),
                    const SizedBox(height: 12),
                    Container(
                      decoration: BoxDecoration(boxShadow: [BoxShadow(color: Colors.grey.shade200, blurRadius: 10, offset: const Offset(0, 5))]),
                      child: DropdownButtonFormField<String>(
                        value: _selectedTargetBank,
                        decoration: _buildInputDecoration('', Icons.account_balance),
                        icon: const Icon(Icons.keyboard_arrow_down),
                        items: _mockBanks.map((bank) {
                          return DropdownMenuItem<String>(
                            value: bank['name'],
                            child: Row(
                              children: [
                                Icon(Icons.food_bank, color: bank['color'], size: 24),
                                const SizedBox(width: 12),
                                Text(bank['name'], style: const TextStyle(fontWeight: FontWeight.bold)),
                              ],
                            ),
                          );
                        }).toList(),
                        onChanged: (newValue) {
                          setState(() {
                            _selectedTargetBank = newValue!;
                            _receiverController.clear();
                            _receiverName = null;
                          });
                        },
                      ),
                    ),
                    const SizedBox(height: 24),

                    const Text('Số tài khoản người nhận', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Colors.black87)),
                    const SizedBox(height: 12),
                    Container(
                      decoration: BoxDecoration(boxShadow: [BoxShadow(color: Colors.grey.shade200, blurRadius: 10, offset: const Offset(0, 5))]),
                      child: TextFormField(
                        controller: _receiverController,
                        focusNode: _receiverFocusNode, 
                        keyboardType: TextInputType.number,
                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                        decoration: InputDecoration(
                          hintText: 'Nhập số tài khoản',
                          filled: true,
                          fillColor: Colors.white,
                          prefixIcon: Icon(Icons.person_outline, color: primaryColor),
                          suffixIcon: IconButton(
                            icon: Container(
                              padding: const EdgeInsets.all(6),
                              decoration: BoxDecoration(color: primaryColor.withOpacity(0.1), shape: BoxShape.circle),
                              child: Icon(Icons.search, color: primaryColor, size: 20),
                            ),
                            onPressed: _checkReceiverName,
                          ),
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide.none),
                          focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide(color: primaryColor, width: 2)),
                        ),
                        onChanged: (value) {
                          if (_receiverName != null) setState(() => _receiverName = null);
                        },
                        validator: (value) => (value == null || value.trim().isEmpty) ? 'Vui lòng nhập số tài khoản' : null,
                      ),
                    ),
                    
                    if (_isSearchingName)
                      const Padding(
                        padding: EdgeInsets.only(top: 12.0, left: 4.0),
                        child: Row(
                          children: [
                            SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2)),
                            SizedBox(width: 12),
                            Text('Đang truy vấn thông tin...', style: TextStyle(color: Colors.grey, fontStyle: FontStyle.italic)),
                          ],
                        ),
                      )
                    else if (_receiverName != null)
                      Padding(
                        padding: const EdgeInsets.only(top: 12.0),
                        child: Container(
                          width: double.infinity,
                          padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
                          decoration: BoxDecoration(
                            color: _receiverName == 'TÀI KHOẢN KHÔNG TỒN TẠI' || _receiverName == 'LỖI MẠNG' ? Colors.red.shade50 : Colors.green.shade50,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: _receiverName == 'TÀI KHOẢN KHÔNG TỒN TẠI' || _receiverName == 'LỖI MẠNG' ? Colors.red.shade200 : Colors.green.shade200)
                          ),
                          child: Text(
                            _receiverName == 'TÀI KHOẢN KHÔNG TỒN TẠI' || _receiverName == 'LỖI MẠNG'
                                ? _receiverName!
                                : 'Người nhận: ${_receiverName!.toUpperCase()}',
                            style: TextStyle(
                              color: _receiverName == 'TÀI KHOẢN KHÔNG TỒN TẠI' || _receiverName == 'LỖI MẠNG' ? Colors.red.shade700 : Colors.green.shade700,
                              fontWeight: FontWeight.bold,
                              fontSize: 15,
                            ),
                          ),
                        ),
                      ),
                    const SizedBox(height: 24),

                    const Text('Số tiền & Lời nhắn', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Colors.black87)),
                    const SizedBox(height: 12),
                    Container(
                      decoration: BoxDecoration(boxShadow: [BoxShadow(color: Colors.grey.shade200, blurRadius: 10, offset: const Offset(0, 5))]),
                      child: TextFormField(
                        controller: _amountController,
                        keyboardType: TextInputType.number,
                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18, color: Colors.black87),
                        decoration: _buildInputDecoration('Nhập số tiền (VND)', Icons.attach_money),
                        validator: (value) {
                          if (value == null || value.isEmpty || int.tryParse(value) == null || int.parse(value) <= 0) return 'Vui lòng nhập số tiền hợp lệ';
                          return null;
                        },
                      ),
                    ),
                    const SizedBox(height: 16),
                    Container(
                      decoration: BoxDecoration(boxShadow: [BoxShadow(color: Colors.grey.shade200, blurRadius: 10, offset: const Offset(0, 5))]),
                      child: TextFormField(
                        controller: _messageController,
                        decoration: _buildInputDecoration('Nhập lời nhắn', Icons.message_outlined),
                      ),
                    ),
                    const SizedBox(height: 40),

                    SizedBox(
                      width: double.infinity,
                      height: 56,
                      child: ElevatedButton(
                        onPressed: _processTransfer, 
                        style: ElevatedButton.styleFrom(
                          backgroundColor: primaryColor, 
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                          elevation: 2,
                        ),
                        child: const Text('Tiếp tục', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                      ),
                    ),
                    const SizedBox(height: 40),
                  ],
                ),
              ),
            ),
    );
  }
}