import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'register_screen.dart';
import 'screen/shop_screen.dart';
import 'screen/settings_screen.dart'; 
import 'screen/topup_screen.dart';
import 'screen/transfer_screen.dart';
import 'screen/receive_screen.dart';
import 'screen/scan_qr_screen.dart';
import 'screen/transaction_history_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // Khởi tạo Supabase (GIỮ NGUYÊN KEY CỦA BẠN)
  await Supabase.initialize(
    url: 'https://vchfcmjaduoiukzxqnch.supabase.co', 
    anonKey: 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6InZjaGZjbWphZHVvaXVrenhxbmNoIiwicm9sZSI6ImFub24iLCJpYXQiOjE3ODg3NzA2NzYsImV4cCI6MjEwNDM0NjY3Nn0.b5Bt-_IjV14RHh2DJUJHqlm6tecMf6KGLxRKGu0Su6U',      
  );

  runApp(const MyApp());
}

// ==========================================
// THEME & SHARED WIDGETS (Tạo giao diện chuẩn chung)
// ==========================================
class AppColors {
  static const Color primary = Color(0xFF0F2C59); // Navy Blue
  static const Color accent = Color(0xFF2196F3); // Sáng hơn
  static const Color background = Color(0xFFF5F7FA); // Xanh xám nhạt
  static const Color card = Colors.white;
  static const Color textMain = Color(0xFF1E1E1E);
  static const Color textLight = Color(0xFF757575);
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'HN BANK',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        useMaterial3: true,
        scaffoldBackgroundColor: AppColors.background,
        colorScheme: ColorScheme.fromSeed(
          seedColor: AppColors.primary,
          primary: AppColors.primary,
        ),
        appBarTheme: const AppBarTheme(
          backgroundColor: Colors.transparent,
          elevation: 0,
          centerTitle: true,
          iconTheme: IconThemeData(color: AppColors.primary),
          titleTextStyle: TextStyle(color: AppColors.primary, fontSize: 20, fontWeight: FontWeight.bold),
        ),
      ),
      home: const LoginScreen(),
    );
  }
}

// Hàm định dạng tiền tệ (Giữ nguyên logic của bạn)
String formatMoney(int amount) {
  return amount.toString().replaceAllMapped(
      RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (Match m) => '${m[1]},');
}

// ==========================================
// MÀN HÌNH ĐĂNG NHẬP (Làm lại UI sang trọng)
// ==========================================
class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _usernameController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _isPasswordVisible = false;
  bool _isLoading = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 40),
              Center(
                child: Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: AppColors.primary.withOpacity(0.1),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.account_balance, size: 60, color: AppColors.primary),
                ),
              ),
              const SizedBox(height: 16),
              const Center(
                child: Text('HN BANK', style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold, color: AppColors.primary, letterSpacing: 1.5)),
              ),
              const SizedBox(height: 48),
              const Text('Xin chào,', style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: AppColors.textMain)),
              const Text('Đăng nhập để tiếp tục', style: TextStyle(fontSize: 16, color: AppColors.textLight)),
              const SizedBox(height: 32),
              
              // Custom TextField
              TextField(
                controller: _usernameController,
                keyboardType: TextInputType.phone,
                decoration: InputDecoration(
                  labelText: 'Số điện thoại / CCCD',
                  prefixIcon: const Icon(Icons.person_outline, color: AppColors.primary),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(16)),
                  focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: const BorderSide(color: AppColors.primary, width: 2)),
                ),
              ),
              const SizedBox(height: 20),
              TextField(
                controller: _passwordController,
                obscureText: !_isPasswordVisible, 
                decoration: InputDecoration(
                  labelText: 'Mật khẩu',
                  prefixIcon: const Icon(Icons.lock_outline, color: AppColors.primary),
                  suffixIcon: IconButton(
                    icon: Icon(_isPasswordVisible ? Icons.visibility : Icons.visibility_off, color: Colors.grey),
                    onPressed: () => setState(() => _isPasswordVisible = !_isPasswordVisible),
                  ),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(16)),
                  focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: const BorderSide(color: AppColors.primary, width: 2)),
                ),
              ),
              const SizedBox(height: 40),
              
              // Nút đăng nhập
              SizedBox(
                width: double.infinity, 
                height: 56,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                    elevation: 2,
                  ),
                  onPressed: _isLoading ? null : () async {
                    final account = _usernameController.text.trim();
                    final password = _passwordController.text;

                    if (account.isEmpty || password.isEmpty) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Vui lòng nhập đủ thông tin!'), backgroundColor: Colors.orange),
                      );
                      return;
                    }

                    setState(() => _isLoading = true);

                    try {
                      // GIỮ NGUYÊN LOGIC SUPABASE
                      final user = await Supabase.instance.client
                          .from('users')
                          .select()
                          .or('phone_number.eq.$account,cccd_number.eq.$account')
                          .eq('password_hash', password)
                          .maybeSingle(); 

                      if (!context.mounted) return;

                      if (user != null) {
                        Navigator.pushReplacement(
                          context,
                          MaterialPageRoute(builder: (context) => HomeScreen(userData: user)), 
                        );
                      } else {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('Sai Số điện thoại / CCCD hoặc mật khẩu!'), backgroundColor: Colors.red),
                        );
                      }
                    } catch (e) {
                      if (context.mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text('Lỗi hệ thống: $e'), backgroundColor: Colors.red),
                        );
                      }
                    } finally {
                      setState(() => _isLoading = false);
                    }
                  },
                  child: _isLoading 
                    ? const CircularProgressIndicator(color: Colors.white)
                    : const Text('Đăng nhập', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                ),
              ),
              const SizedBox(height: 24),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Text('Chưa có tài khoản?', style: TextStyle(color: AppColors.textLight)),
                  TextButton(
                    onPressed: () {
                      Navigator.push(context, MaterialPageRoute(builder: (context) => const RegisterScreen()));
                    },
                    child: const Text('Đăng ký ngay', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppColors.accent)),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ==========================================
// MÀN HÌNH TRANG CHỦ (Modern Premium)
// ==========================================
class HomeScreen extends StatefulWidget {
  final Map<String, dynamic> userData;
  const HomeScreen({super.key, required this.userData});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _totalBalance = 0;
  bool _isLoading = true;
  bool _isBalanceVisible = false; // Thêm logic ẩn hiện số dư

  @override
  void initState() {
    super.initState();
    _fetchTotalBalance();
  }

  // GIỮ NGUYÊN LOGIC FETCH DATA
  Future<void> _fetchTotalBalance() async {
    try {
      final response = await Supabase.instance.client
          .from('bank_accounts')
          .select('balance')
          .eq('user_id', widget.userData['id']);
      
      int sum = 0;
      for (var row in response) {
        sum += (row['balance'] as int? ?? 0);
      }
      if(mounted){
        setState(() {
          _totalBalance = sum;
          _isLoading = false;
        });
      }
    } catch(e) {
      if(mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final String fullName = widget.userData['full_name'] ?? 'Khách hàng';

    return Scaffold(
      body: _isLoading 
        ? const Center(child: CircularProgressIndicator(color: AppColors.primary))
        : CustomScrollView(
            slivers: [
              // Header Appbar hiện đại
              SliverAppBar(
                expandedHeight: 80,
                backgroundColor: AppColors.background,
                floating: true,
                pinned: true,
                automaticallyImplyLeading: false,
                title: Row(
                  children: [
                    CircleAvatar(
                      backgroundColor: AppColors.primary.withOpacity(0.1),
                      child: const Icon(Icons.person, color: AppColors.primary),
                    ),
                    const SizedBox(width: 12),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('Xin chào,', style: TextStyle(fontSize: 14, color: AppColors.textLight)),
                        Text(fullName, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppColors.textMain)),
                      ],
                    ),
                  ],
                ),
                actions: [
                  IconButton(
                    icon: const Icon(Icons.notifications_none, color: AppColors.textMain),
                    onPressed: () {},
                  ),
                  IconButton(
                    icon: const Icon(Icons.settings, color: AppColors.textMain),
                    onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (context) => SettingsScreen(userData: widget.userData))),
                  ),
                  const SizedBox(width: 8),
                ],
              ),
              
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const SizedBox(height: 16),
                      // CARD TỔNG SỐ DƯ
                      GestureDetector(
                        onTap: () async {
                          await Navigator.push(context, MaterialPageRoute(builder: (context) => AccountDetailsScreen(userData: widget.userData)));
                          _fetchTotalBalance();
                        },
                        child: Container(
                          padding: const EdgeInsets.all(24),
                          decoration: BoxDecoration(
                            gradient: const LinearGradient(
                              colors: [AppColors.primary, Color(0xFF1E4C90)],
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                            ),
                            borderRadius: BorderRadius.circular(20),
                            boxShadow: [
                              BoxShadow(color: AppColors.primary.withOpacity(0.3), blurRadius: 15, offset: const Offset(0, 8)),
                            ],
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  const Text('Tổng số dư', style: TextStyle(color: Colors.white70, fontSize: 16)),
                                  GestureDetector(
                                    onTap: () => setState(() => _isBalanceVisible = !_isBalanceVisible),
                                    child: Icon(_isBalanceVisible ? Icons.visibility : Icons.visibility_off, color: Colors.white70, size: 20),
                                  )
                                ],
                              ),
                              const SizedBox(height: 12),
                              Text(
                                _isBalanceVisible ? '${formatMoney(_totalBalance)} VND' : '****** VND', 
                                style: const TextStyle(color: Colors.white, fontSize: 32, fontWeight: FontWeight.bold)
                              ),
                              const SizedBox(height: 16),
                              Row(
                                children: [
                                  const Text('Xem chi tiết thẻ', style: TextStyle(color: Colors.white70, fontSize: 14)),
                                  const SizedBox(width: 4),
                                  const Icon(Icons.arrow_forward_ios, color: Colors.white70, size: 12),
                                ],
                              )
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: 32),
                      
                      // DỊCH VỤ CHÍNH (QUICK ACTIONS)
                      const Text('Dịch vụ', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppColors.textMain)),
                      const SizedBox(height: 16),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceAround,
                        children: [
                          _buildQuickAction(Icons.send_rounded, 'Chuyển tiền', Colors.orange, () async {
                            await Navigator.push(context, MaterialPageRoute(builder: (context) => TransferScreen(userData: widget.userData)));
                            _fetchTotalBalance();
                          }),
                          _buildQuickAction(Icons.qr_code_rounded, 'Nhận tiền', Colors.green, () {
                            Navigator.push(context, MaterialPageRoute(builder: (context) => ReceiveScreen(userData: widget.userData)));
                          }),
                          _buildQuickAction(Icons.phone_android_rounded, 'Nạp điện thoại', Colors.teal, () async {
                            await Navigator.push(context, MaterialPageRoute(builder: (context) => TopUpScreen(userData: widget.userData)));
                            _fetchTotalBalance();
                          }),
                          _buildQuickAction(Icons.qr_code_scanner_rounded, 'Quét QR', Colors.blue, () {
                            Navigator.push(context, MaterialPageRoute(builder: (context) => ScanQRScreen(userData: widget.userData)));
                          }),
                        ],
                      ),
                      const SizedBox(height: 32),

                      // CỬA HÀNG BANNER
                      const Text('Khám phá', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppColors.textMain)),
                      const SizedBox(height: 16),
                      GestureDetector(
                        onTap: () async {
                          await Navigator.push(context, MaterialPageRoute(builder: (context) => ShopScreen(userData: widget.userData)));
                          _fetchTotalBalance(); 
                        },
                        child: Container(
                          padding: const EdgeInsets.all(20),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(color: Colors.grey.shade200),
                            boxShadow: [BoxShadow(color: Colors.grey.shade200, blurRadius: 10, offset: const Offset(0, 5))],
                          ),
                          child: Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.all(12),
                                decoration: BoxDecoration(color: Colors.purple.withOpacity(0.1), borderRadius: BorderRadius.circular(12)),
                                child: const Icon(Icons.storefront_rounded, color: Colors.purple, size: 30),
                              ),
                              const SizedBox(width: 16),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    const Text('Cửa hàng Tài khoản', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                                    const SizedBox(height: 4),
                                    Text('Chọn số đẹp, rước tài lộc', style: TextStyle(fontSize: 13, color: Colors.grey.shade600)),
                                  ],
                                ),
                              ),
                              const Icon(Icons.chevron_right, color: Colors.grey),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: 40),
                    ],
                  ),
                ),
              ),
            ],
          ),
    );
  }

  // Widget con hỗ trợ tạo nút Action
  Widget _buildQuickAction(IconData icon, String label, Color color, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: color.withOpacity(0.15),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Icon(icon, size: 28, color: color),
          ),
          const SizedBox(height: 8),
          Text(label, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500, color: AppColors.textMain)),
        ],
      ),
    );
  }
}

// ==========================================
// MÀN HÌNH CHI TIẾT TÀI KHOẢN (Modern)
// ==========================================
class AccountDetailsScreen extends StatefulWidget {
  final Map<String, dynamic> userData;
  const AccountDetailsScreen({super.key, required this.userData});
  @override
  State<AccountDetailsScreen> createState() => _AccountDetailsScreenState();
}

class _AccountDetailsScreenState extends State<AccountDetailsScreen> {
  List<dynamic> _bankAccounts = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _fetchBankAccounts();
  }

  // GIỮ NGUYÊN LOGIC FETCH DATA
  Future<void> _fetchBankAccounts() async {
    try {
      final response = await Supabase.instance.client.from('bank_accounts').select().eq('user_id', widget.userData['id']);
      if(mounted){
        setState(() { _bankAccounts = response; _isLoading = false; });
      }
    } catch (e) {
      if(mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    int totalBalance = 0;
    for (var acc in _bankAccounts) totalBalance += (acc['balance'] as int? ?? 0);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Tài khoản của tôi'),
      ),
      body: _isLoading 
        ? const Center(child: CircularProgressIndicator(color: AppColors.primary)) 
        : Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Thẻ tổng quan
                Container(
                  width: double.infinity, 
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    color: Colors.white, 
                    borderRadius: BorderRadius.circular(16), 
                    border: Border.all(color: Colors.grey.shade200),
                    boxShadow: [BoxShadow(color: Colors.grey.shade100, blurRadius: 10, offset: const Offset(0, 5))]
                  ),
                  child: Column(
                    children: [
                      const Text('Tổng tài sản', style: TextStyle(fontSize: 14, color: AppColors.textLight)),
                      const SizedBox(height: 8),
                      Text('${formatMoney(totalBalance)} VND', style: const TextStyle(fontSize: 32, fontWeight: FontWeight.bold, color: AppColors.primary)),
                    ],
                  ),
                ),
                const SizedBox(height: 24),
                const Text('Danh sách thẻ / Tài khoản', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppColors.textMain)),
                const SizedBox(height: 12),
                
                // Danh sách tài khoản
                Expanded(
                  child: ListView.builder(
                    itemCount: _bankAccounts.length,
                    itemBuilder: (context, index) {
                      final account = _bankAccounts[index];
                      final accountBalance = account['balance'] as int? ?? 0;
                      return Container(
                        margin: const EdgeInsets.only(bottom: 16),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(16),
                          boxShadow: [BoxShadow(color: Colors.grey.shade100, blurRadius: 8, offset: const Offset(0, 2))],
                        ),
                        child: Material(
                          color: Colors.transparent,
                          borderRadius: BorderRadius.circular(16),
                          child: InkWell(
                            borderRadius: BorderRadius.circular(16),
                            // GIỮ NGUYÊN LOGIC CHUYỂN TRANG
                            onTap: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) => TransactionHistoryScreen(
                                    accountNumber: account['account_number'],
                                    currentBalance: accountBalance,
                                  ),
                                ),
                              );
                            },
                            child: Padding(
                              padding: const EdgeInsets.all(16.0),
                              child: Row(
                                children: [
                                  Container(
                                    padding: const EdgeInsets.all(12),
                                    decoration: BoxDecoration(color: AppColors.background, borderRadius: BorderRadius.circular(12)),
                                    child: const Icon(Icons.credit_card, color: AppColors.primary, size: 28),
                                  ),
                                  const SizedBox(width: 16),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(account['account_number'], style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, letterSpacing: 1.2)),
                                        const SizedBox(height: 4),
                                        Text('${formatMoney(accountBalance)} VND', style: const TextStyle(color: Colors.green, fontWeight: FontWeight.w600, fontSize: 15)),
                                      ],
                                    ),
                                  ),
                                  const Icon(Icons.arrow_forward_ios, size: 16, color: Colors.grey),
                                ],
                              ),
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
    );
  }
}