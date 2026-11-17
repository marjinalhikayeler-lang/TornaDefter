import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/utils/formatters.dart';
import '../../../core/api/api_client.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});
  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  Map<String, dynamic>? _stats;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    try {
      var companyId = await ApiClient().getActiveCompany();
      if (companyId == null) {
        final compRes = await ApiClient().dio.get('/companies').catchError((_) => null);
        if (compRes != null && compRes.data != null) {
          final list = compRes.data is List ? compRes.data : (compRes.data['data'] ?? []);
          if (list is List && list.isNotEmpty) {
            companyId = list[0]['id'];
            await ApiClient().setActiveCompany(companyId!);
          }
        }
      }
      if (companyId != null) {
        await Future.wait([
          ApiClient().dio.get('/companies/$companyId/cash-accounts/summary').catchError((_) => null),
          ApiClient().dio.get('/companies/$companyId/bank-accounts/summary').catchError((_) => null),
        ]);
      }
    } catch (_) {
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.backgroundDark,
      appBar: AppBar(
        title: const Text('TornaDefter'),
        actions: [
          IconButton(
            icon: const Icon(Icons.notifications_outlined),
            tooltip: 'Bildirimler',
            onPressed: () => context.push('/notifications'),
          ),
          IconButton(
            icon: const Icon(Icons.settings),
            tooltip: 'Ayarlar',
            onPressed: () => context.push('/more'),
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: _loadData,
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Üst özet kartları
              Row(children: [
                _summaryCard('Toplam Alacak', '0,00 TL', AppColors.success, Icons.arrow_downward),
                const SizedBox(width: 12),
                _summaryCard('Toplam Borç', '0,00 TL', AppColors.danger, Icons.arrow_upward),
              ]),
              const SizedBox(height: 12),
              Row(children: [
                _summaryCard('Net Bakiye', '0,00 TL', AppColors.primary, Icons.account_balance),
                const SizedBox(width: 12),
                _summaryCard('Kasa + Banka', '0,00 TL', AppColors.warning, Icons.account_balance_wallet),
              ]),
              const SizedBox(height: 24),
              // Hızlı erişim
              const Text('Hızlı Erişim', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white)),
              const SizedBox(height: 12),
              GridView.count(
                crossAxisCount: 4,
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                mainAxisSpacing: 12,
                crossAxisSpacing: 12,
                children: [
                  _quickAction(Icons.people, 'Cariler', AppColors.primary, () => context.push('/accounts')),
                  _quickAction(Icons.receipt_long, 'İşlemler', AppColors.success, () => context.push('/accounts')),
                  _quickAction(Icons.account_balance, 'Kasa', AppColors.warning, () => context.push('/cash')),
                  _quickAction(Icons.description, 'Çek/Senet', AppColors.info, () => context.push('/cheques')),
                  _quickAction(Icons.bar_chart, 'Raporlar', AppColors.accent, () => context.push('/reports')),
                  _quickAction(Icons.view_timeline, 'Taksitler', Colors.purple, () => context.push('/installments')),
                  _quickAction(Icons.backup, 'Yedekleme', Colors.teal, () => context.push('/backup')),
                  _quickAction(Icons.help_outline, 'Destek', Colors.pink, () => context.push('/support')),
                ],
              ),
              const SizedBox(height: 24),
              // Vadesi yaklaşanlar
              const Text('Vadesi Yaklaşanlar', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white)),
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(color: AppColors.surfaceDark, borderRadius: BorderRadius.circular(12)),
                child: const Center(child: Text('Vadesi yaklaşan işlem yok', style: TextStyle(color: AppColors.textSecondaryDark))),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _summaryCard(String label, String value, Color color, IconData icon) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(color: AppColors.surfaceDark, borderRadius: BorderRadius.circular(12)),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Row(children: [
            Icon(icon, color: color, size: 20),
            const Spacer(),
          ]),
          const SizedBox(height: 8),
          Text(value, style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: color)),
          const SizedBox(height: 4),
          Text(label, style: const TextStyle(fontSize: 11, color: AppColors.textSecondaryDark)),
        ]),
      ),
    );
  }

  Widget _quickAction(IconData icon, String label, Color color, VoidCallback onTap) {
    return InkWell(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(color: AppColors.surfaceDark, borderRadius: BorderRadius.circular(12)),
        child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
          Container(
            width: 40, height: 40,
            decoration: BoxDecoration(color: color.withOpacity(0.15), borderRadius: BorderRadius.circular(10)),
            child: Icon(icon, color: color, size: 22),
          ),
          const SizedBox(height: 6),
          Text(label, style: const TextStyle(fontSize: 10, color: AppColors.textSecondaryDark), textAlign: TextAlign.center),
        ]),
      ),
    );
  }
}

