import 'package:flutter/material.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/api/api_client.dart';
import '../../../core/utils/formatters.dart';

class CashScreen extends StatefulWidget {
  const CashScreen({super.key});
  @override
  State<CashScreen> createState() => _CashScreenState();
}

class _CashScreenState extends State<CashScreen> with SingleTickerProviderStateMixin {
  late TabController _tabCtrl;
  List<dynamic> _cashAccounts = [];
  List<dynamic> _bankAccounts = [];
  bool _loading = true;

  @override
  void initState() { super.initState(); _tabCtrl = TabController(length: 2, vsync: this); _loadData(); }

  Future<void> _loadData() async {
    final cid = await ApiClient().getActiveCompany();
    if (cid == null) return;
    try {
      final r1 = await ApiClient().dio.get('/companies/$cid/cash-accounts');
      final r2 = await ApiClient().dio.get('/companies/$cid/bank-accounts');
      _cashAccounts = r1.data is List ? r1.data : (r1.data?['data'] ?? []);
      _bankAccounts = r2.data is List ? r2.data : (r2.data?['data'] ?? []);
    } catch (_) {}
    if (mounted) setState(() => _loading = false);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.backgroundDark,
      appBar: AppBar(title: const Text('Kasa & Banka'),
        bottom: TabBar(controller: _tabCtrl, indicatorColor: AppColors.primary, labelColor: AppColors.primary, unselectedLabelColor: AppColors.textSecondaryDark,
          tabs: const [Tab(text: 'Kasalar'), Tab(text: 'Bankalar')])),
      body: _loading ? const Center(child: CircularProgressIndicator(color: AppColors.primary))
        : TabBarView(controller: _tabCtrl, children: [
            _buildList(_cashAccounts, 'Kasa'),
            _buildList(_bankAccounts, 'Banka'),
          ]),
    );
  }

  Widget _buildList(List<dynamic> items, String label) {
    if (items.isEmpty) return Center(child: Text('$label hesabı yok', style: const TextStyle(color: AppColors.textSecondaryDark)));
    final total = items.fold<int>(0, (sum, a) => sum + ((a['current_balance'] ?? 0) as int));
    return Column(children: [
      Container(
        margin: const EdgeInsets.all(16), padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(color: AppColors.primary.withOpacity(0.1), borderRadius: BorderRadius.circular(12)),
        child: Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
          Text('Toplam $label', style: const TextStyle(color: AppColors.textSecondaryDark)),
          Text(MoneyUtil.format(total), style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: AppColors.primary)),
        ]),
      ),
      Expanded(child: ListView.builder(itemCount: items.length, itemBuilder: (ctx, i) {
        final a = items[i];
        final bal = (a['current_balance'] ?? 0) as int;
        return ListTile(
          leading: CircleAvatar(backgroundColor: AppColors.primary.withOpacity(0.2), child: Icon(label == 'Kasa' ? Icons.account_balance_wallet : Icons.account_balance, color: AppColors.primary)),
          title: Text(a['name'] ?? '', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w600)),
          subtitle: Text(a['currency'] ?? 'TRY', style: const TextStyle(color: AppColors.textSecondaryDark, fontSize: 12)),
          trailing: Text(MoneyUtil.format(bal), style: TextStyle(fontWeight: FontWeight.bold, color: bal >= 0 ? AppColors.success : AppColors.danger)),
        );
      })),
    ]);
  }
}

