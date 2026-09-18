import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

// Khai báo màu chuẩn Premium
const Color _primaryColor = Color(0xFF0F2C59);
const Color _bgColor = Color(0xFFF5F7FA);

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  // =========================================================
  // FORM
  // =========================================================
  final _formKey = GlobalKey<FormState>();

  // =========================================================
  // CONTROLLERS & TRẠNG THÁI
  // =========================================================
  final _nameController = TextEditingController();
  final _phoneController = TextEditingController();
  final _cccdController = TextEditingController();
  final _dobController = TextEditingController();
  final _passwordController = TextEditingController();
  final _streetController = TextEditingController();

  String _selectedGender = 'Nam';
  String? _selectedProvince;
  String? _selectedDistrict;

  bool _isProcessing = false; // Trạng thái loading
  bool _isPasswordVisible = false; // Ẩn/hiện mật khẩu

  // =========================================================
  // DỮ LIỆU TỈNH / THÀNH PHỐ VÀ QUẬN / HUYỆN
  // =========================================================
  final Map<String, List<String>> _vnLocations = {
    'Hà Nội': ['Ba Đình', 'Hoàn Kiếm', 'Tây Hồ', 'Long Biên', 'Cầu Giấy', 'Đống Đa', 'Hai Bà Trưng', 'Hoàng Mai', 'Thanh Xuân', 'Hà Đông', 'Nam Từ Liêm', 'Bắc Từ Liêm'],
    'TP. Hồ Chí Minh': ['Quận 1', 'Quận 3', 'Quận 4', 'Quận 5', 'Quận 6', 'Quận 7', 'Quận 8', 'Quận 10', 'Quận 11', 'Quận 12', 'Bình Thạnh', 'Tân Bình', 'Tân Phú', 'Phú Nhuận', 'Gò Vấp', 'Bình Tân', 'Thủ Đức'],
    'Đà Nẵng': ['Hải Châu', 'Thanh Khê', 'Sơn Trà', 'Ngũ Hành Sơn', 'Liên Chiểu', 'Cẩm Lệ', 'Hòa Vang'],
    'Hải Phòng': ['Hồng Bàng', 'Lê Chân', 'Ngô Quyền', 'Kiến An', 'Hải An', 'Đồ Sơn', 'Dương Kinh', 'Thủy Nguyên'],
    'Cần Thơ': ['Ninh Kiều', 'Bình Thủy', 'Cái Răng', 'Ô Môn', 'Thốt Nốt'],
    'Huế': ['Phú Xuân', 'Thuận Hóa', 'Hương Thủy', 'Hương Trà', 'Phong Điền'],
  };

  // =========================================================
  // ĐĂNG KÝ
  // =========================================================
  Future<void> _submitRegister() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isProcessing = true);

    try {
      final fullAddress = '${_streetController.text.trim()}, $_selectedDistrict, $_selectedProvince';

      // 1. TẠO USER
      final newUser = await Supabase.instance.client
          .from('users')
          .insert({
            'full_name': _nameController.text.trim(),
            'phone_number': _phoneController.text.trim(),
            'password_hash': _passwordController.text,
            'cccd_number': _cccdController.text.trim(),
            'dob': _dobController.text.split('/').reversed.join('-'),
            'gender': _selectedGender,
            'address': fullAddress,
          })
          .select()
          .single();

      // 2. TẠO TÀI KHOẢN NGÂN HÀNG
      await Supabase.instance.client.from('bank_accounts').insert({
        'user_id': newUser['id'],
        'account_number': _phoneController.text.trim(),
        'balance': 50000,
      });

      // 3. THÔNG BÁO THÀNH CÔNG
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Đăng ký thành công! Vui lòng đăng nhập.', style: TextStyle(fontWeight: FontWeight.bold)), backgroundColor: Colors.green),
        );
        Navigator.pop(context);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Đăng ký thất bại!\nSố điện thoại hoặc CCCD đã tồn tại.', style: const TextStyle(fontWeight: FontWeight.bold)), backgroundColor: Colors.red),
        );
      }
    } finally {
      if (mounted) setState(() => _isProcessing = false);
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    _cccdController.dispose();
    _dobController.dispose();
    _passwordController.dispose();
    _streetController.dispose();
    super.dispose();
  }

  // HÀM TẠO GIAO DIỆN Ô NHẬP LIỆU CHUẨN PREMIUM
  InputDecoration _customInputDecoration(String label, IconData icon) {
    return InputDecoration(
      labelText: label,
      labelStyle: const TextStyle(color: Colors.grey),
      prefixIcon: Icon(icon, color: _primaryColor),
      filled: true,
      fillColor: Colors.white,
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide.none),
      focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: const BorderSide(color: _primaryColor, width: 1.5)),
      errorBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: const BorderSide(color: Colors.red, width: 1)),
      focusedErrorBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: const BorderSide(color: Colors.red, width: 1.5)),
      contentPadding: const EdgeInsets.symmetric(vertical: 16, horizontal: 20),
    );
  }

  // HÀM TẠO TIÊU ĐỀ PHÂN MỤC
  Widget _buildSectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.only(left: 4, bottom: 12, top: 24),
      child: Text(
        title.toUpperCase(),
        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: _primaryColor, letterSpacing: 1.2),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _bgColor,
      appBar: AppBar(
        title: const Text('Mở tài khoản', style: TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: Colors.transparent,
        foregroundColor: _primaryColor,
        elevation: 0,
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Text('Tham gia HN BANK ngay hôm nay\nđể trải nghiệm dịch vụ ngân hàng số hàng đầu.', 
                style: TextStyle(color: Colors.grey, fontSize: 14), 
                textAlign: TextAlign.center
              ),

              // =================================================
              // PHẦN 1: THÔNG TIN CÁ NHÂN
              // =================================================
              _buildSectionTitle('Thông tin cá nhân'),
              
              Container(
                decoration: BoxDecoration(boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.03), blurRadius: 10, offset: const Offset(0, 4))]),
                child: TextFormField(
                  controller: _nameController,
                  textCapitalization: TextCapitalization.words,
                  decoration: _customInputDecoration('Họ và tên (In hoa có dấu)', Icons.badge),
                  validator: (value) => (value == null || value.trim().isEmpty) ? 'Vui lòng nhập họ và tên' : null,
                ),
              ),
              const SizedBox(height: 16),

              Container(
                decoration: BoxDecoration(boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.03), blurRadius: 10)]),
                child: TextFormField(
                  controller: _cccdController,
                  keyboardType: TextInputType.number,
                  decoration: _customInputDecoration('Số Căn cước công dân', Icons.credit_card),
                  validator: (value) {
                    if (value == null || value.isEmpty) return 'Vui lòng nhập số CCCD';
                    if (!RegExp(r'^\d{12}$').hasMatch(value)) return 'CCCD bắt buộc phải có đúng 12 số';
                    return null;
                  },
                ),
              ),
              const SizedBox(height: 16),

              Row(
                children: [
                  Expanded(
                    flex: 3,
                    child: Container(
                      decoration: BoxDecoration(boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.03), blurRadius: 10)]),
                      child: TextFormField(
                        controller: _dobController,
                        readOnly: true,
                        decoration: _customInputDecoration('Ngày sinh', Icons.calendar_today),
                        onTap: () async {
                          final pickedDate = await showDatePicker(
                            context: context,
                            initialDate: DateTime(2000),
                            firstDate: DateTime(1900),
                            lastDate: DateTime.now(),
                            builder: (context, child) => Theme(
                              data: Theme.of(context).copyWith(colorScheme: const ColorScheme.light(primary: _primaryColor)),
                              child: child!,
                            ),
                          );
                          if (pickedDate != null) {
                            setState(() {
                              _dobController.text = '${pickedDate.day.toString().padLeft(2, '0')}/${pickedDate.month.toString().padLeft(2, '0')}/${pickedDate.year}';
                            });
                          }
                        },
                        validator: (value) => (value == null || value.isEmpty) ? 'Vui lòng chọn' : null,
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    flex: 2,
                    child: Container(
                      decoration: BoxDecoration(boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.03), blurRadius: 10)]),
                      child: DropdownButtonFormField<String>(
                        value: _selectedGender,
                        decoration: _customInputDecoration('Giới tính', Icons.person),
                        icon: const Icon(Icons.keyboard_arrow_down, color: Colors.grey),
                        items: ['Nam', 'Nữ', 'Khác'].map((String value) => DropdownMenuItem<String>(value: value, child: Text(value))).toList(),
                        onChanged: (newValue) => setState(() => _selectedGender = newValue!),
                      ),
                    ),
                  ),
                ],
              ),

              // =================================================
              // PHẦN 2: TÀI KHOẢN & BẢO MẬT
              // =================================================
              _buildSectionTitle('Tài khoản đăng nhập'),

              Container(
                decoration: BoxDecoration(boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.03), blurRadius: 10)]),
                child: TextFormField(
                  controller: _phoneController,
                  keyboardType: TextInputType.phone,
                  decoration: _customInputDecoration('Số điện thoại', Icons.phone_android),
                  validator: (value) {
                    if (value == null || value.isEmpty) return 'Vui lòng nhập số điện thoại';
                    if (!RegExp(r'^0[89]\d{8}$').hasMatch(value)) return 'SĐT phải có 10 số và bắt đầu bằng 08 hoặc 09';
                    return null;
                  },
                ),
              ),
              const SizedBox(height: 16),

              Container(
                decoration: BoxDecoration(boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.03), blurRadius: 10)]),
                child: TextFormField(
                  controller: _passwordController,
                  obscureText: !_isPasswordVisible,
                  decoration: InputDecoration(
                    labelText: 'Mật khẩu',
                    labelStyle: const TextStyle(color: Colors.grey),
                    prefixIcon: const Icon(Icons.lock, color: _primaryColor),
                    suffixIcon: IconButton(
                      icon: Icon(_isPasswordVisible ? Icons.visibility : Icons.visibility_off, color: Colors.grey),
                      onPressed: () => setState(() => _isPasswordVisible = !_isPasswordVisible),
                    ),
                    filled: true,
                    fillColor: Colors.white,
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide.none),
                    focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: const BorderSide(color: _primaryColor, width: 1.5)),
                    errorBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: const BorderSide(color: Colors.red, width: 1)),
                    focusedErrorBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: const BorderSide(color: Colors.red, width: 1.5)),
                  ),
                  validator: (value) {
                    if (value == null || value.isEmpty) return 'Vui lòng nhập mật khẩu';
                    if (!RegExp(r'^(?=.*[A-Z])(?=.*\d)(?=.*[\W_]).{8,}$').hasMatch(value)) {
                      return 'Phải có chữ hoa, số, ký tự đặc biệt và ≥ 8 ký tự';
                    }
                    return null;
                  },
                ),
              ),

              // =================================================
              // PHẦN 3: ĐỊA CHỈ
              // =================================================
              _buildSectionTitle('Địa chỉ liên hệ'),

              Container(
                decoration: BoxDecoration(boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.03), blurRadius: 10)]),
                child: DropdownButtonFormField<String>(
                  value: _selectedProvince,
                  decoration: _customInputDecoration('Tỉnh / Thành phố', Icons.map),
                  icon: const Icon(Icons.keyboard_arrow_down, color: Colors.grey),
                  items: _vnLocations.keys.map((String province) => DropdownMenuItem<String>(value: province, child: Text(province))).toList(),
                  onChanged: (newValue) {
                    setState(() {
                      _selectedProvince = newValue;
                      _selectedDistrict = null; // Đổi tỉnh thì reset quận/huyện
                    });
                  },
                  validator: (value) => (value == null || value.isEmpty) ? 'Vui lòng chọn Tỉnh/Thành phố' : null,
                ),
              ),
              const SizedBox(height: 16),

              Container(
                decoration: BoxDecoration(boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.03), blurRadius: 10)]),
                child: DropdownButtonFormField<String>(
                  value: _selectedDistrict,
                  decoration: _customInputDecoration('Quận / Huyện', Icons.location_city),
                  icon: const Icon(Icons.keyboard_arrow_down, color: Colors.grey),
                  items: _selectedProvince == null
                      ? []
                      : _vnLocations[_selectedProvince]!.map((String district) => DropdownMenuItem<String>(value: district, child: Text(district))).toList(),
                  onChanged: _selectedProvince == null ? null : (newValue) => setState(() => _selectedDistrict = newValue),
                  validator: (value) => (value == null || value.isEmpty) ? 'Vui lòng chọn Quận/Huyện' : null,
                ),
              ),
              const SizedBox(height: 16),

              Container(
                decoration: BoxDecoration(boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.03), blurRadius: 10)]),
                child: TextFormField(
                  controller: _streetController,
                  textCapitalization: TextCapitalization.sentences,
                  decoration: _customInputDecoration('Số nhà, Ngõ, Tên đường...', Icons.home),
                  validator: (value) => (value == null || value.trim().isEmpty) ? 'Vui lòng nhập địa chỉ cụ thể' : null,
                ),
              ),

              const SizedBox(height: 40),

              // =================================================
              // 10. NÚT ĐĂNG KÝ
              // =================================================
              SizedBox(
                height: 56,
                child: ElevatedButton(
                  onPressed: _isProcessing ? null : _submitRegister,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: _primaryColor,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                    elevation: 2,
                  ),
                  child: _isProcessing 
                      ? const SizedBox(width: 24, height: 24, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                      : const Text('MỞ TÀI KHOẢN NGAY', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, letterSpacing: 1)),
                ),
              ),
              const SizedBox(height: 30),
            ],
          ),
        ),
      ),
    );
  }
}