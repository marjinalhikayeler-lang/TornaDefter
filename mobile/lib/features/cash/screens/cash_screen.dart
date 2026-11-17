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
  void initState() {
    super.initState();
    _tabCtrl = TabController(length: 2, vsync: this);
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() => _loading = true);
    try {
      final cid = await ApiClient().ensureActiveCompany();
      if (cid != null) {
        final r1 = await ApiClient().dio.get('/companies/$cid/cash-accounts');
        final r2 = await ApiClient().dio.get('/companies/$cid/bank-accounts');
        _cashAccounts = r1.data is List ? r1.data : (r1.data?['data'] ?? []);
        _bankAccounts = r2.data is List ? r2.data : (r2.data?['data'] ?? []);
      }
    } catch (_) {}
    if (mounted) setState(() => _loading = false);
  }

  void _showAddAccountDialog() {
    final isCash = _tabCtrl.index == 0;
    final nameCtrl = TextEditingController();
    final ibanCtrl = TextEditingController();
    final openingBalCtrl = TextEditingController(text: '0');

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppColors.surfaceDark,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (ctx) => Padding(
        padding: EdgeInsets.only(
          left: 20, right: 20, top: 20,
          bottom: MediaQuery.of(ctx).viewInsets.bottom + 20,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(isCash ? 'Yeni Kasa Ekle' : 'Yeni Banka Hesabı Ekle',
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white)),
            const SizedBox(height: 16),
            TextField(
              controller: nameCtrl,
              style: const TextStyle(color: Colors.white),
              decoration: InputDecoration(
                labelText: isCash ? 'Kasa Adı (Örn: Merkez Kasa)' : 'Hesap Adı (Örn: Garanti Ticari)',
                prefixIcon: Icon(isCash ? Icons.account_balance_wallet : Icons.account_balance, color: AppColors.primary),
              ),
            ),
            if (!isCash) ...[
              const SizedBox(height: 12),
              TextField(
                controller: ibanCtrl,
                style: const TextStyle(color: Colors.white),
                decoration: const InputDecoration(labelText: 'IBAN (Opsiyonel)', prefixIcon: Icon(Icons.credit_card, color: AppColors.textSecondaryDark)),
              ),
            ],
            const SizedBox(height: 12),
            TextField(
              controller: openingBalCtrl,
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              style: const TextStyle(color: Colors.white),
              decoration: const InputDecoration(labelText: 'Açılış Bakiyesi (TL)', prefixIcon: Icon(Icons.currency_lira, color: AppColors.textSecondaryDark)),
            ),
            const SizedBox(height: 20),
            SizedBox(
              width: double.infinity,
              height: 48,
              child: ElevatedButton(
                onPressed: () async {
                  if (nameCtrl.text.trim().isEmpty) {
                    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Lütfen hesap adını girin')));
                    return;
                  }
                  final cid = await ApiClient().ensureActiveCompany();
                  if (cid == null) return;
                  final bal = double.tryParse(openingBalCtrl.text.replaceAll(',', '.')) ?? 0;
                  try {
                    if (isCash) {
                      await ApiClient().dio.post('/companies/$cid/cash-accounts', data: {
                        'name': nameCtrl.text.trim(),
                        'currency': 'TRY',
                        'openingBalance': MoneyUtil.toKurus(bal),
                      });
                    } else {
                      await ApiClient().dio.post('/companies/$cid/bank-accounts', data: {
                        'name': nameCtrl.text.trim(),
                        'iban': ibanCtrl.text.trim().isEmpty ? null : ibanCtrl.text.trim(),
                        'currency': 'TRY',
                        'openingBalance': MoneyUtil.toKurus(bal),
                      });
                    }
                    if (ctx.mounted) Navigator.pop(ctx);
                    _loadData();
                  } catch (e) {
                    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Hata: $e')));
                  }
                },
                style: ElevatedButton.styleFrom(backgroundColor: AppColors.primary),
                child: const Text('Kaydet', style: TextStyle(color: Colors.white, fontSize: 16)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.backgroundDark,
      appBar: AppBar(
        title: const Text('Kasa & Banka'),
        bottom: TabBar(
          controller: _tabCtrl,
          indicatorColor: AppColors.primary,
          labelColor: AppColors.primary,
          unselectedLabelColor: AppColors.textSecondaryDark,
          tabs: const [Tab(text: 'Kasalar'), Tab(text: 'Bankalar')],
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _showAddAccountDialog,
        backgroundColor: AppColors.primary,
        icon: const Icon(Icons.add),
        label: const Text('Yeni Hesap'),
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator(color: AppColors.primary))
          : TabBarView(
              controller: _tabCtrl,
              children: [
                _buildList(_cashAccounts, 'Kasa'),
                _buildList(_bankAccounts, 'Banka'),
              ],
            ),
    );
  }

  Widget _buildList(List<dynamic> items, String label) {
    if (items.isEmpty) {
      return RefreshIndicator(
        onRefresh: _loadData,
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(label == 'Kasa' ? Icons.account_balance_wallet_outlined : Icons.account_balance_outlined, size: 48, color: AppColors.textSecondaryDark),
              const SizedBox(height: 12),
              Text('$label hesabı bulunamadı', style: const TextStyle(color: AppColors.textSecondaryDark, fontSize: 16)),
              const SizedBox(height: 8),
              ElevatedButton.icon(
                onPressed: _showAddAccountDialog,
                icon: const Icon(Icons.add),
                label: Text('Yeni $label Ekle'),
                style: ElevatedButton.styleFrom(backgroundColor: AppColors.primary),
              ),
            ],
          ),
        ),
      );
    }
    final total = items.fold<int>(0, (sum, a) => sum + ((a['current_balance'] ?? 0) as int));
    return RefreshIndicator(
      onRefresh: _loadData,
      child: Column(
        children: [
          Container(
            margin: const EdgeInsets.all(16),
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(color: AppColors.surfaceDark, borderRadius: BorderRadius.circular(12)),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('Toplam $label Bakiyesi', style: const TextStyle(color: AppColors.textSecondaryDark)),
                Text(MoneyUtil.format(total), style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: AppColors.primary)),
              ],
            ),
          ),
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              itemCount: items.length,
              itemBuilder: (ctx, i) {
                final a = items[i];
                final bal = (a['current_balance'] ?? 0) as int;
                return Container(
                  margin: const EdgeInsets.only(bottom: 8),
                  decoration: BoxDecoration(color: AppColors.surfaceDark, borderRadius: BorderRadius.circular(12)),
                  child: ListTile(
                    leading: CircleAvatar(
                      backgroundColor: AppColors.primary.withOpacity(0.15),
                      child: Icon(label == 'Kasa' ? Icons.account_balance_wallet : Icons.account_balance, color: AppColors.primary),
                    ),
                    title: Text(a['name'] ?? '', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w600)),
                    subtitle: Text(a['iban'] ?? a['currency'] ?? 'TRY', style: const TextStyle(color: AppColors.textSecondaryDark, fontSize: 12)),
                    trailing: Text(
                      MoneyUtil.format(bal),
                      style: TextStyle(fontWeight: FontWeight.bold, color: bal >= 0 ? AppColors.success : AppColors.danger, fontSize: 15),
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
