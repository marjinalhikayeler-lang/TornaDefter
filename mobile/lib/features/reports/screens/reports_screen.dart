import 'package:flutter/material.dart';
import '../../../core/theme/app_theme.dart';

class ReportsScreen extends StatelessWidget {
  const ReportsScreen({super.key});

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
              onTap: () {
                ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('${r.$1} hazırlanıyor...'), duration: const Duration(seconds: 1)));
              },
            ),
          );
        },
      ),
    );
  }
}

