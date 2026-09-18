import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

String formatMoney(int amount) {
  return amount.toString().replaceAllMapped(
      RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (Match m) => '${m[1]},');
}

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

  final List<Map<String, dynamic>> _vipNumbers = [
    {'number': '9999999999', 'price': 20000, 'label': 'Cửu Ngũ Chí Tôn', 'icon': Icons.diamond},
    {'number': '8888888888', 'price': 15000, 'label': 'Đại Phát', 'icon': Icons.trending_up},
    {'number': '6868686868', 'price': 10000, 'label': 'Lộc Phát', 'icon': Icons.local_fire_department},
    {'number': '1234567890', 'price': 5000, 'label': 'Sảnh Rồng', 'icon': Icons.military_tech},
  ];

  @override
  void initState() {
    super.initState();
    _fetchShopData();
  }

  // GIỮ NGUYÊN LOGIC FETCH DATA
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

  // GIỮ NGUYÊN LOGIC MUA SỐ ĐẸP
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

      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Đã mua $accountNumber! Tiền trừ vào thẻ ${fundingAccount['account_number']}')));
      
      _fetchShopData();
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Lỗi: Số này vừa bị người khác mua!')));
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
        elevation: 0,
        centerTitle: true,
        foregroundColor: Colors.black87,
      ),
      body: _isLoading || _isProcessing
          ? const Center(child: CircularProgressIndicator(color: Colors.purple))
          : availableNumbers.isEmpty 
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.inventory_2_outlined, size: 80, color: Colors.grey.shade400),
                      const SizedBox(height: 16),
                      const Text('Kho số hiện đang trống!', style: TextStyle(fontSize: 18, color: Colors.grey, fontWeight: FontWeight.w600)),
                    ],
                  ),
                )
              : ListView.builder(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
                  itemCount: availableNumbers.length,
                  itemBuilder: (context, index) {
                    final item = availableNumbers[index];
                    return Container(
                      margin: const EdgeInsets.only(bottom: 16),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(16),
                        boxShadow: [BoxShadow(color: Colors.grey.shade200, blurRadius: 10, offset: const Offset(0, 5))],
                      ),
                      child: Padding(
                        padding: const EdgeInsets.all(20.0),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Expanded(
                              child: Row(
                                children: [
                                  Container(
                                    padding: const EdgeInsets.all(12),
                                    decoration: BoxDecoration(color: Colors.purple.withOpacity(0.1), borderRadius: BorderRadius.circular(12)),
                                    child: Icon(item['icon'], color: Colors.purple.shade700, size: 28),
                                  ),
                                  const SizedBox(width: 16),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(item['number'], style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Colors.purple.shade800, letterSpacing: 1.2)),
                                        const SizedBox(height: 4),
                                        Text(item['label'], style: TextStyle(color: Colors.grey.shade600, fontSize: 14, fontWeight: FontWeight.w500)),
                                        const SizedBox(height: 4),
                                        Text('${formatMoney(item['price'])} VND', style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: Colors.black87)),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            ElevatedButton(
                              onPressed: () => _buyVipAccount(item['number'], item['price']),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.purple.shade600, 
                                foregroundColor: Colors.white,
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                                elevation: 0
                              ),
                              child: const Text('MUA NGAY', style: TextStyle(fontWeight: FontWeight.bold)),
                            )
                          ],
                        ),
                      ),
                    );
                  },
                ),
    );
  }
}