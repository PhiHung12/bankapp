import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../main.dart'; // Import để dùng hàm formatMoney

// Khai báo màu chuẩn Premium
const Color _primaryColor = Color(0xFF0F2C59);
const Color _goldAccent = Color(0xFFFFD700);

class ShopScreen extends StatefulWidget {
  final Map<String, dynamic> userData;
  const ShopScreen({super.key, required this.userData});

  @override
  State<ShopScreen> createState() => _ShopScreenState();
}

class _ShopScreenState extends State<ShopScreen> {
  bool _isLoading = true;
  bool _isProcessing = false;
  List<dynamic> _myAccounts = [];
  List<String> _soldNumbers = [];

  // ==========================================
  // KHO SỐ VIP VÀ THIẾT KẾ MÀU SẮC, ICON NỀN
  // ==========================================
  final List<Map<String, dynamic>> _vipNumbers = [
    // 👑 HÀNG SIÊU VIP 
    {'number': '9999999999', 'price': 99000, 'label': 'Cửu Ngũ Chí Tôn', 'colors': [Color(0xFF8E2DE2), Color(0xFF4A00E0)], 'bgIcon': Icons.diamond},
    {'number': '8888888888', 'price': 88000, 'label': 'Đại Phát Trường Tồn', 'colors': [Color(0xFFF7971E), Color(0xFFFFD200)], 'bgIcon': Icons.workspace_premium},
    {'number': '6666666666', 'price': 66000, 'label': 'Lục Quý Đại Lộc', 'colors': [Color(0xFF11998E), Color(0xFF38EF7D)], 'bgIcon': Icons.diamond_outlined},
    
    // 🐉 SẢNH RỒNG
    {'number': '1234567890', 'price': 50000, 'label': 'Sảnh Rồng Thăng Tiến', 'colors': [Color(0xFF0F2C59), Color(0xFF2196F3)], 'bgIcon': Icons.trending_up},
    {'number': '0987654321', 'price': 45000, 'label': 'Tiền Vào Như Nước', 'colors': [Color(0xFF00B4DB), Color(0xFF0083B0)], 'bgIcon': Icons.water_drop_outlined},
    
    // 💰 THẦN TÀI - LỘC PHÁT
    {'number': '7979797979', 'price': 39000, 'label': 'Đại Thần Tài', 'colors': [Color(0xFFCB2D3E), Color(0xFFEF473A)], 'bgIcon': Icons.monetization_on},
    {'number': '6868686868', 'price': 68000, 'label': 'Lộc Phát Toàn Diện', 'colors': [Color(0xFFf12711), Color(0xFFf5af19)], 'bgIcon': Icons.account_balance_wallet},
    {'number': '1368136813', 'price': 25000, 'label': 'Sinh Tài Lộc Phát', 'colors': [Color(0xFF8E0E00), Color(0xFF1F1C18)], 'bgIcon': Icons.diamond},

    // ⭐ TỨ QUÝ - NGŨ QUÝ
    {'number': '2222222222', 'price': 22000, 'label': 'Mãi Mãi Bình An', 'colors': [Color(0xFF4CB8C4), Color(0xFF3CD3AD)], 'bgIcon': Icons.shield_outlined},
    {'number': '5555555555', 'price': 55000, 'label': 'Ngũ Phúc Lâm Môn', 'colors': [Color(0xFFEB5757), Color(0xFF000000)], 'bgIcon': Icons.stars},
    
    // 🎂 SỐ CẶP 
     {'number': '1234567890', 'price': 200000, 'label': 'Sảnh Rồng Thăng Tiến', 'colors': [Color(0xFFCB2D3E), Color(0xFFEF473A)], 'bgIcon': Icons.monetization_on},
    {'number': '0987654321', 'price': 99000, 'label': 'Tiền Vào Như Nước', 'colors': [Color(0xFFf12711), Color(0xFFf5af19)], 'bgIcon': Icons.account_balance_wallet},
    {'number': '1357924680', 'price': 199000, 'label': 'Quần Long Hội Tụ', 'colors': [Color(0xFF8E0E00), Color(0xFF1F1C18)], 'bgIcon': Icons.diamond},
    {'number': '0909090909', 'price': 19999, 'label': 'Trường Cửu Mãi Mãi', 'colors': [Color(0xFF141E30), Color(0xFF243B55)], 'bgIcon': Icons.all_inclusive},
  ];

  @override
  void initState() {
    super.initState();
    _fetchShopData();
  }

  // GIỮ NGUYÊN LOGIC GET DATA
  Future<void> _fetchShopData() async {
    final userId = widget.userData['id'];
    final myAccs = await Supabase.instance.client.from('bank_accounts').select().eq('user_id', userId);
    final allAccs = await Supabase.instance.client.from('bank_accounts').select('account_number');
    final soldList = (allAccs as List).map((e) => e['account_number'].toString()).toList();

    if(mounted) {
      setState(() {
        _myAccounts = myAccs;
        _soldNumbers = soldList;
        _isLoading = false;
      });
    }
  }

  // GIỮ NGUYÊN LOGIC THANH TOÁN
  Future<void> _buyVipAccount(String accountNumber, int price) async {
    final fundingAccount = _myAccounts.where((acc) => (acc['balance'] as int? ?? 0) >= price).firstOrNull;

    if (fundingAccount == null) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Không thẻ nào đủ tiền thanh toán!')));
      return;
    }

    setState(() => _isProcessing = true);

    try {
      await Supabase.instance.client.from('bank_accounts').insert({
        'user_id': widget.userData['id'],
        'account_number': accountNumber,
        'balance': 0 
      });

      await Supabase.instance.client.from('bank_accounts').update({
        'balance': fundingAccount['balance'] - price
      }).eq('id', fundingAccount['id']);

      if(mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Đã mua $accountNumber! Tiền trừ vào thẻ ${fundingAccount['account_number']}')));
      }
      
      _fetchShopData();
    } catch (e) {
      if(mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Lỗi: Số này vừa bị người khác mua!')));
    } finally {
      if(mounted) setState(() => _isProcessing = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final availableNumbers = _vipNumbers.where((item) => !_soldNumbers.contains(item['number'])).toList();

    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FA),
      appBar: AppBar(
        title: const Text('Kho Số Đẹp', style: TextStyle(fontWeight: FontWeight.bold)), 
        backgroundColor: Colors.transparent, 
        foregroundColor: _primaryColor,
        elevation: 0,
        centerTitle: true,
      ),
      body: _isLoading || _isProcessing
          ? const Center(child: CircularProgressIndicator(color: _primaryColor))
          : availableNumbers.isEmpty 
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.sentiment_dissatisfied, size: 80, color: Colors.grey[400]),
                      const SizedBox(height: 16),
                      const Text('Kho số tạm thời cháy hàng!', style: TextStyle(fontSize: 20, color: Colors.grey, fontWeight: FontWeight.bold)),
                    ],
                  ),
                )
              : ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: availableNumbers.length,
                  itemBuilder: (context, index) {
                    final item = availableNumbers[index];
                    final List<Color> gradientColors = item['colors'];
                    final IconData bgIcon = item['bgIcon'];

                    return Container(
                      margin: const EdgeInsets.only(bottom: 16),
                      clipBehavior: Clip.hardEdge, // Cắt những phần ảnh tràn ra khỏi viền bo góc
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(20),
                        gradient: LinearGradient(colors: gradientColors, begin: Alignment.topLeft, end: Alignment.bottomRight),
                        boxShadow: [BoxShadow(color: gradientColors[0].withOpacity(0.4), blurRadius: 12, offset: const Offset(0, 6))],
                      ),
                      
                      // DÙNG STACK ĐỂ TẠO LỚP HÌNH NỀN (KIM CƯƠNG) CHÌM XUỐNG DƯỚI
                      child: Stack(
                        children: [
                          // 1. LỚP BACKGROUND ICON (KIM CƯƠNG) MỜ CHÌM
                          Positioned(
                            right: -20,
                            bottom: -30,
                            child: Icon(
                              bgIcon, 
                              size: 160, 
                              color: Colors.white.withOpacity(0.15) // Làm mờ 15%
                            ),
                            // NẾU BẠN MUỐN DÙNG ẢNH THẬT TRONG MÁY, HÃY XÓA ICON TRÊN VÀ BỎ COMMENT DÒNG DƯỚI:
                            // child: Opacity(opacity: 0.15, child: Image.asset('assets/diamond.png', width: 160)),
                          ),

                          // 2. LỚP NỘI DUNG CHÍNH (SỐ, CHỮ, NÚT MUA)
                          Padding(
                            padding: const EdgeInsets.all(20.0),
                            child: Row(
                              children: [
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Container(
                                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                        decoration: BoxDecoration(color: Colors.white.withOpacity(0.2), borderRadius: BorderRadius.circular(8)),
                                        child: Text(item['label'], style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w600, fontSize: 12)),
                                      ),
                                      const SizedBox(height: 12),
                                      Text(item['number'], style: const TextStyle(fontSize: 26, fontWeight: FontWeight.bold, color: Colors.white, letterSpacing: 2)),
                                      const SizedBox(height: 8),
                                      Text('${formatMoney(item['price'])} VND', style: const TextStyle(fontSize: 16, color: _goldAccent, fontWeight: FontWeight.bold)),
                                    ],
                                  ),
                                ),
                                ElevatedButton(
                                  onPressed: () => _buyVipAccount(item['number'], item['price']),
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: Colors.white, 
                                    foregroundColor: gradientColors[0],
                                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                                  ),
                                  child: const Text('MUA NGAY', style: TextStyle(fontWeight: FontWeight.bold)),
                                )
                              ],
                            ),
                          ),
                        ],
                      ),
                    );
                  },
                ),
    );
  }
}