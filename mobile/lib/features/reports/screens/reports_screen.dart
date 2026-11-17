import 'package:flutter/material.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/api/api_client.dart';
import '../../../core/utils/formatters.dart';

class ReportsScreen extends StatelessWidget {
  const ReportsScreen({super.key});

  void _openReport(BuildContext context, String title) async {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppColors.surfaceDark,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (ctx) => FutureBuilder(
        future: _fetchReportData(title),
        builder: (ctx, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const SizedBox(
              height: 250,
              child: Center(child: CircularProgressIndicator(color: AppColors.primary)),
            );
          }
          final items = (snapshot.data as List<dynamic>?) ?? [];
          return DraggableScrollableSheet(
            initialChildSize: 0.7,
            maxChildSize: 0.9,
            minChildSize: 0.5,
            expand: false,
            builder: (_, scrollCtrl) => Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(title, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white)),
                      IconButton(icon: const Icon(Icons.close, color: AppColors.textSecondaryDark), onPressed: () => Navigator.pop(ctx)),
                    ],
                  ),
                  const SizedBox(height: 12),
                  if (items.isEmpty)
                    const Expanded(child: Center(child: Text('Bu raporda gösterilecek veri bulunamadı', style: TextStyle(color: AppColors.textSecondaryDark))))
                  else
                    Expanded(
                      child: ListView.builder(
                        controller: scrollCtrl,
                        itemCount: items.length,
                        itemBuilder: (ctx, i) {
                          final item = items[i];
                          final title = item['title'] ?? item['name'] ?? item['description'] ?? 'Kayıt';
                          final bal = (item['current_balance'] ?? item['balance'] ?? item['amount'] ?? 0) as int;
                          return Container(
                            margin: const EdgeInsets.only(bottom: 8),
                            decoration: BoxDecoration(color: AppColors.cardDark, borderRadius: BorderRadius.circular(10)),
                            child: ListTile(
                              title: Text(title, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w600)),
                              subtitle: Text(item['account_type'] ?? item['type'] ?? '', style: const TextStyle(color: AppColors.textSecondaryDark, fontSize: 12)),
                              trailing: Text(
                                MoneyUtil.format(bal),
                                style: TextStyle(fontWeight: FontWeight.bold, color: bal >= 0 ? AppColors.success : AppColors.danger),
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
        },
      ),
    );
  }

  Future<List<dynamic>> _fetchReportData(String title) async {
    final cid = await ApiClient().ensureActiveCompany();
    if (cid == null) return [];
    try {
      if (title.contains('Gelir-Gider') || title.contains('Kar-Zarar')) {
        final res = await ApiClient().dio.get('/companies/$cid/income-expenses');
        return (res.data is List ? res.data : (res.data?['data'] ?? [])) as List;
      } else if (title.contains('Kasa-Banka')) {
        final r1 = await ApiClient().dio.get('/companies/$cid/cash-accounts');
        return (r1.data is List ? r1.data : (r1.data?['data'] ?? [])) as List;
      } else {
        final res = await ApiClient().dio.get('/companies/$cid/accounts');
        final all = (res.data is List ? res.data : (res.data?['data'] ?? [])) as List;
        if (title.contains('Borçlu')) {
          return all.where((a) => ((a['current_balance'] ?? 0) as int) > 0).toList();
        } else if (title.contains('Alacaklı')) {
          return all.where((a) => ((a['current_balance'] ?? 0) as int) < 0).toList();
        }
        return all;
      }
    } catch (_) {
      return [];
    }
  }

  @override
  Widget build(BuildContext context) {
    final reports = [
      ('Bakiye Raporu', 'Tüm carilerin güncel bakiyeleri', Icons.account_balance, AppColors.primary),
      ('Ekstre', 'Cari hesap ekstresi oluştur', Icons.receipt_long, AppColors.success),
      ('Borçlular Listesi', 'Borçlu carilerin listesi', Icons.arrow_upward, AppColors.danger),
      ('Alacaklılar Listesi', 'Alacaklı carilerin listesi', Icons.arrow_downward, AppColors.credit),
      ('Vade Analizi', 'Vadesi geçen/yaklaşan işlemler', Icons.schedule, AppColors.warning),
      ('Kasa-Banka Raporu', 'Kasa ve banka hareketleri', Icons.account_balance_wallet, Colors.purple),
      ('Gelir-Gider Raporu', 'Dönemsel gelir ve gider özeti', Icons.pie_chart, Colors.teal),
      ('Kar-Zarar Raporu', 'Kar ve zarar analizi', Icons.trending_up, AppColors.info),
    ];

    return Scaffold(
      backgroundColor: AppColors.backgroundDark,
      appBar: AppBar(title: const Text('Raporlar')),
      body: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: reports.length,
        itemBuilder: (ctx, i) {
          final r = reports[i];
          return Container(
            margin: const EdgeInsets.only(bottom: 8),
            decoration: BoxDecoration(color: AppColors.surfaceDark, borderRadius: BorderRadius.circular(12)),
            child: ListTile(
              contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              leading: Container(
                width: 44, height: 44,
                decoration: BoxDecoration(color: (r.$4 as Color).withOpacity(0.15), borderRadius: BorderRadius.circular(10)),
                child: Icon(r.$3 as IconData, color: r.$4 as Color, size: 22),
              ),
              title: Text(r.$1, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w600, fontSize: 15)),
              subtitle: Text(r.$2, style: const TextStyle(color: AppColors.textSecondaryDark, fontSize: 12)),
              trailing: const Icon(Icons.chevron_right, color: AppColors.textSecondaryDark),
              onTap: () => _openReport(context, r.$1),
            ),
          );
        },
      ),
    );
  }
}
