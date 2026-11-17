import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/api/api_client.dart';
import '../../profile/screens/profile_screen.dart';
import '../../support/screens/support_screen.dart';
import '../../backup/screens/backup_screen.dart';
import '../../data_import/screens/data_import_screen.dart';
import '../../installments/screens/installments_screen.dart';
import '../../notifications/screens/notifications_screen.dart';
import 'theme_color_picker_screen.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.backgroundDark,
      appBar: AppBar(title: const Text('Daha Fazla')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(children: [
          // Profil kartı
          GestureDetector(
            onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const ProfileScreen())),
            child: Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(color: AppColors.surfaceDark, borderRadius: BorderRadius.circular(12)),
              child: Row(children: [
                CircleAvatar(radius: 28, backgroundColor: AppColors.primary.withOpacity(0.2),
                  child: const Icon(Icons.person, color: AppColors.primary, size: 28)),
                const SizedBox(width: 16),
                const Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text('Kullanıcı', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16)),
                  Text('Profili düzenle', style: TextStyle(color: AppColors.textSecondaryDark, fontSize: 13)),
                ])),
                const Icon(Icons.chevron_right, color: AppColors.textSecondaryDark),
              ]),
            ),
          ),
          const SizedBox(height: 16),
          _section('İşlemler', [
            _tile(Icons.description, 'Çek / Senet', () => context.go('/cheques')),
            _tile(Icons.calendar_month, 'Taksit Takibi', () => Navigator.push(context, MaterialPageRoute(builder: (_) => const InstallmentsScreen()))),
            _tile(Icons.category, 'Gelir / Gider', () {}),
            _tile(Icons.swap_horiz, 'Hesap Transferi', () {}),
            _tile(Icons.people, 'Firma Yönetimi', () {}),
            _tile(Icons.upload_file, 'Veri İçe Aktar', () => Navigator.push(context, MaterialPageRoute(builder: (_) => const DataImportScreen()))),
            _tile(Icons.assessment, 'Raporlar', () => context.go('/reports')),
          ]),
          const SizedBox(height: 16),
          _section('Ayarlar', [
            _tile(Icons.notifications, 'Bildirimler', () => Navigator.push(context, MaterialPageRoute(builder: (_) => const NotificationsScreen()))),
            _tile(Icons.backup, 'Yedekleme & Geri Yükleme', () => Navigator.push(context, MaterialPageRoute(builder: (_) => const BackupScreen()))),
            _tile(Icons.palette, 'Tema Rengi', () => Navigator.push(context, MaterialPageRoute(builder: (_) => const ThemeColorPickerScreen()))),
            _tile(Icons.lock, 'Uygulama Kilidi', () {}),
            _tile(Icons.language, 'Dil', () {}),
          ]),
          const SizedBox(height: 16),
          _section('Destek', [
            _tile(Icons.support_agent, 'Destek Talebi', () => Navigator.push(context, MaterialPageRoute(builder: (_) => const SupportScreen()))),
            _tile(Icons.help_outline, 'Yardım & SSS', () {}),
            _tile(Icons.star, 'Uygulamayı Değerlendir', () {}),
            _tile(Icons.share, 'Uygulamayı Paylaş', () {}),
            _tile(Icons.info_outline, 'Hakkında', () => _showAbout(context)),
          ]),
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              onPressed: () async {
                final confirmed = await showDialog<bool>(
                  context: context,
                  builder: (ctx) => AlertDialog(
                    backgroundColor: AppColors.surfaceDark,
                    title: const Text('Çıkış Yap', style: TextStyle(color: Colors.white)),
                    content: const Text('Çıkış yapmak istediğinize emin misiniz?', style: TextStyle(color: Colors.white70)),
                    actions: [
                      TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('İptal', style: TextStyle(color: Colors.white54))),
                      ElevatedButton(
                        onPressed: () => Navigator.pop(ctx, true),
                        style: ElevatedButton.styleFrom(backgroundColor: AppColors.danger),
                        child: const Text('Çıkış Yap'),
                      ),
                    ],
                  ),
                );
                if (confirmed == true) {
                  await ApiClient().clearTokens();
                  if (context.mounted) context.go('/login');
                }
              },
              style: OutlinedButton.styleFrom(side: const BorderSide(color: AppColors.danger), padding: const EdgeInsets.symmetric(vertical: 14)),
              icon: const Icon(Icons.logout, color: AppColors.danger),
              label: const Text('Çıkış Yap', style: TextStyle(color: AppColors.danger)),
            ),
          ),
          const SizedBox(height: 24),
          const Text('TornaDefter v1.0.0', style: TextStyle(color: AppColors.textSecondaryDark, fontSize: 12)),
          const SizedBox(height: 4),
          const Text('Cari Hesap Yönetim Sistemi', style: TextStyle(color: AppColors.textSecondaryDark, fontSize: 11)),
        ]),
      ),
    );
  }

  Widget _section(String title, List<Widget> children) {
    return Container(
      decoration: BoxDecoration(color: AppColors.surfaceDark, borderRadius: BorderRadius.circular(12)),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Padding(padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
          child: Text(title, style: const TextStyle(color: AppColors.textSecondaryDark, fontSize: 12, fontWeight: FontWeight.w600))),
        ...children,
      ]),
    );
  }

  Widget _tile(IconData icon, String label, VoidCallback onTap) {
    return ListTile(
      leading: Icon(icon, color: AppColors.primary, size: 22),
      title: Text(label, style: const TextStyle(color: Colors.white, fontSize: 14)),
      trailing: const Icon(Icons.chevron_right, color: AppColors.textSecondaryDark, size: 20),
      onTap: onTap,
    );
  }

  void _showAbout(BuildContext context) {
    showAboutDialog(
      context: context,
      applicationName: 'TornaDefter',
      applicationVersion: 'v1.0.0',
      applicationIcon: Container(
        width: 48, height: 48,
        decoration: BoxDecoration(color: AppColors.primary, borderRadius: BorderRadius.circular(12)),
        child: const Icon(Icons.settings, color: Colors.white, size: 28),
      ),
      children: [
        const Text('Cari Hesap Yönetim Sistemi'),
        const SizedBox(height: 8),
        const Text('Müşteri, tedarikçi ve personel cari hesaplarınızı kolayca takip edin.'),
        const SizedBox(height: 8),
        const Text('© 2024 TornaDefter. Tüm hakları saklıdır.'),
      ],
    );
  }
}
