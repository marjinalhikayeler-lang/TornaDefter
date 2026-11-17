import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:share_plus/share_plus.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/api/api_client.dart';
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
            onTap: () => context.push('/profile'),
            child: Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(color: AppColors.surfaceDark, borderRadius: BorderRadius.circular(12)),
              child: Row(children: [
                CircleAvatar(
                  radius: 28,
                  backgroundColor: AppColors.primary.withOpacity(0.2),
                  child: const Icon(Icons.person, color: AppColors.primary, size: 28),
                ),
                const SizedBox(width: 16),
                const Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text('Kullanıcı Hesabı', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16)),
                  Text('Profil bilgilerini görüntüle ve düzenle', style: TextStyle(color: AppColors.textSecondaryDark, fontSize: 13)),
                ])),
                const Icon(Icons.chevron_right, color: AppColors.textSecondaryDark),
              ]),
            ),
          ),
          const SizedBox(height: 16),
          _section('İşlemler', [
            _tile(Icons.description, 'Çek / Senet', () => context.push('/cheques')),
            _tile(Icons.calendar_month, 'Taksit Takibi', () => context.push('/installments')),
            _tile(Icons.category, 'Gelir / Gider', () => context.push('/income-expenses')),
            _tile(Icons.swap_horiz, 'Kasa & Banka Hesapları', () => context.push('/cash')),
            _tile(Icons.business, 'Firma Yönetimi', () => _showCompanyDialog(context)),
            _tile(Icons.upload_file, 'Veri İçe Aktar (Excel/CSV)', () => context.push('/data-import')),
            _tile(Icons.assessment, 'Finansal Raporlar', () => context.push('/reports')),
          ]),
          const SizedBox(height: 16),
          _section('Ayarlar & Güvenlik', [
            _tile(Icons.notifications, 'Bildirimler', () => context.push('/notifications')),
            _tile(Icons.backup, 'Yedekleme & Geri Yükleme', () => context.push('/backup')),
            _tile(Icons.palette, 'Tema & Renk Seçimi', () => Navigator.push(context, MaterialPageRoute(builder: (_) => const ThemeColorPickerScreen()))),
            _tile(Icons.lock_outline, 'Uygulama Kilidi / PIN', () => _showLockDialog(context)),
            _tile(Icons.language, 'Dil / Language', () => _showLanguageDialog(context)),
          ]),
          const SizedBox(height: 16),
          _section('Destek & Bilgi', [
            _tile(Icons.support_agent, 'Destek Talebi Oluştur', () => context.push('/support')),
            _tile(Icons.help_outline, 'Yardım & Sıkça Sorulan Sorular', () => _showFaqDialog(context)),
            _tile(Icons.star_rate, 'Uygulamayı Değerlendir', () => _showRateDialog(context)),
            _tile(Icons.share, 'Uygulamayı Paylaş', () => _shareApp(context)),
            _tile(Icons.info_outline, 'TornaDefter Hakkında', () => _showAbout(context)),
          ]),
          const SizedBox(height: 20),
          SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              onPressed: () async {
                final confirmed = await showDialog<bool>(
                  context: context,
                  builder: (ctx) => AlertDialog(
                    backgroundColor: AppColors.surfaceDark,
                    title: const Text('Çıkış Yap', style: TextStyle(color: Colors.white)),
                    content: const Text('Hesabınızdan çıkış yapmak istediğinize emin misiniz?', style: TextStyle(color: Colors.white70)),
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
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
          child: Text(title, style: const TextStyle(color: AppColors.textSecondaryDark, fontSize: 12, fontWeight: FontWeight.w600)),
        ),
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

  void _showCompanyDialog(BuildContext context) async {
    final cid = await ApiClient().ensureActiveCompany();
    if (!context.mounted) return;
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.surfaceDark,
        title: const Text('Firma Bilgisi', style: TextStyle(color: Colors.white)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Aktif İşletme / Firma:', style: TextStyle(color: AppColors.textSecondaryDark)),
            const SizedBox(height: 6),
            Text(cid != null ? 'Firma ID: $cid' : 'Aktif firma bulunamadı', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
            const SizedBox(height: 12),
            const Text('TornaDefter tek kullanıcı ve çoklu firma desteği sunmaktadır.', style: TextStyle(color: AppColors.textSecondaryDark, fontSize: 12)),
          ],
        ),
        actions: [
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx),
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.primary),
            child: const Text('Tamam'),
          ),
        ],
      ),
    );
  }

  void _showLockDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.surfaceDark,
        title: const Text('Uygulama Kilidi', style: TextStyle(color: Colors.white)),
        content: const Text(
          'Uygulama açılışında PIN veya Parmak İzi (Biyometrik) koruması telefonunuzun yerel güvenlik sistemiyle entegre çalışmaktadır.',
          style: TextStyle(color: Colors.white70),
        ),
        actions: [
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx),
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.primary),
            child: const Text('Anladım'),
          ),
        ],
      ),
    );
  }

  void _showLanguageDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.surfaceDark,
        title: const Text('Dil Seçimi', style: TextStyle(color: Colors.white)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.check_circle, color: AppColors.success),
              title: const Text('Türkçe (Aktif)', style: TextStyle(color: Colors.white)),
              onTap: () => Navigator.pop(ctx),
            ),
            ListTile(
              leading: const Icon(Icons.radio_button_unchecked, color: AppColors.textSecondaryDark),
              title: const Text('English (Yakında)', style: TextStyle(color: AppColors.textSecondaryDark)),
              onTap: () => Navigator.pop(ctx),
            ),
          ],
        ),
      ),
    );
  }

  void _showFaqDialog(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppColors.surfaceDark,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (ctx) => DraggableScrollableSheet(
        initialChildSize: 0.7,
        maxChildSize: 0.9,
        minChildSize: 0.5,
        expand: false,
        builder: (_, scrollCtrl) => ListView(
          controller: scrollCtrl,
          padding: const EdgeInsets.all(20),
          children: [
            const Text('Sıkça Sorulan Sorular (SSS)', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white)),
            const SizedBox(height: 16),
            _faqItem('TornaDefter ücretli mi?', 'Hayır, TornaDefter tamamen ücretsizdir ve işletmeler için sınırsız cari hesap takip imkanı sunar.'),
            _faqItem('Verilerim güvende mi?', 'Tüm verileriniz Frankfurt merkezli bulut sunucularımızda şifrelenmiş olarak saklanır ve düzenli yedeklenir.'),
            _faqItem('Borç ve Tahsilat nasıl eklenir?', 'Alt bardaki turuncu (+) butonuna basarak Borç Ekle veya Tahsilat Al seçeneklerinden cari seçerek tutar girebilirsiniz.'),
            _faqItem('Başka telefondan erişebilir miyim?', 'Evet, aynı e-posta ve şifrenizle dilediğiniz Android cihazdan giriş yapabilirsiniz.'),
          ],
        ),
      ),
    );
  }

  Widget _faqItem(String q, String a) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(color: AppColors.cardDark, borderRadius: BorderRadius.circular(10)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(q, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14)),
          const SizedBox(height: 6),
          Text(a, style: const TextStyle(color: AppColors.textSecondaryDark, fontSize: 13)),
        ],
      ),
    );
  }

  void _showRateDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.surfaceDark,
        title: const Text('TornaDefter\'i Değerlendirin', style: TextStyle(color: Colors.white)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.star, color: Colors.amber, size: 32),
                Icon(Icons.star, color: Colors.amber, size: 32),
                Icon(Icons.star, color: Colors.amber, size: 32),
                Icon(Icons.star, color: Colors.amber, size: 32),
                Icon(Icons.star, color: Colors.amber, size: 32),
              ],
            ),
            const SizedBox(height: 16),
            const Text('Geri bildiriminiz bizim için çok değerli!', textAlign: TextAlign.center, style: TextStyle(color: Colors.white70)),
          ],
        ),
        actions: [
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx),
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.primary),
            child: const Text('Teşekkürler'),
          ),
        ],
      ),
    );
  }

  void _shareApp(BuildContext context) {
    Share.share(
      'TornaDefter - Kolay ve Ücretsiz Cari Hesap Yönetim Sistemi. İndir ve hemen kullan: https://tornadefter.onrender.com',
      subject: 'TornaDefter Cari Hesap Takip',
    );
  }

  void _showAbout(BuildContext context) {
    showAboutDialog(
      context: context,
      applicationName: 'TornaDefter',
      applicationVersion: 'v1.0.0',
      applicationIcon: ClipRRect(
        borderRadius: BorderRadius.circular(12),
        child: Image.asset('assets/images/logo.png', width: 48, height: 48, fit: BoxFit.cover),
      ),
      children: [
        const Text('Cari Hesap Yönetim Sistemi'),
        const SizedBox(height: 8),
        const Text('Müşteri, tedarikçi ve personel cari hesaplarınızı, çek/senetlerinizi ve gelir-giderlerinizi kolayca takip edin.'),
        const SizedBox(height: 8),
        const Text('© 2024 TornaDefter. Tüm hakları saklıdır.'),
      ],
    );
  }
}
