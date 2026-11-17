import 'package:url_launcher/url_launcher.dart';
import 'package:share_plus/share_plus.dart';

/// WhatsApp ve genel paylaşım yardımcı sınıfı
class ShareUtil {
  /// WhatsApp ile mesaj gönder
  static Future<void> shareViaWhatsApp({
    required String phone,
    required String message,
  }) async {
    // Telefon numarasını düzenle (başındaki 0'ı kaldır, +90 ekle)
    String formattedPhone = phone.replaceAll(RegExp(r'[^0-9]'), '');
    if (formattedPhone.startsWith('0')) {
      formattedPhone = '90${formattedPhone.substring(1)}';
    } else if (!formattedPhone.startsWith('90')) {
      formattedPhone = '90$formattedPhone';
    }

    final encodedMessage = Uri.encodeComponent(message);
    final whatsappUrl = 'https://wa.me/$formattedPhone?text=$encodedMessage';

    final uri = Uri.parse(whatsappUrl);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    } else {
      // WhatsApp yüklü değilse normal SMS'e yönlendir
      final smsUri = Uri.parse('sms:$phone?body=$encodedMessage');
      await launchUrl(smsUri);
    }
  }

  /// Ekstre metnini WhatsApp'tan gönder
  static Future<void> shareStatement({
    required String accountTitle,
    required int balance,
    required String balanceDirection,
    String? phone,
  }) async {
    final balanceText = (balance / 100).toStringAsFixed(2);
    final dirText = balanceDirection == 'DEBIT' ? 'Borç' : 'Alacak';

    final message = '''
📋 *TornaDefter - Cari Hesap Ekstresi*

👤 *$accountTitle*
💰 Bakiye: $balanceText ₺ ($dirText)
📅 Tarih: ${DateTime.now().day}.${DateTime.now().month}.${DateTime.now().year}

_Bu mesaj TornaDefter uygulaması ile gönderilmiştir._
''';

    if (phone != null && phone.isNotEmpty) {
      await shareViaWhatsApp(phone: phone, message: message);
    } else {
      await Share.share(message, subject: 'TornaDefter - $accountTitle Ekstresi');
    }
  }

  /// Genel paylaşım (PDF dosyası ile)
  static Future<void> shareFile({
    required String filePath,
    required String subject,
    String? text,
  }) async {
    await Share.shareXFiles(
      [XFile(filePath)],
      subject: subject,
      text: text,
    );
  }

  /// Raporu paylaş
  static Future<void> shareReport({
    required String reportTitle,
    required String content,
  }) async {
    await Share.share(
      content,
      subject: 'TornaDefter - $reportTitle',
    );
  }

  /// Telefon araması yap
  static Future<void> makeCall(String phone) async {
    final uri = Uri.parse('tel:$phone');
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri);
    }
  }

  /// E-posta gönder
  static Future<void> sendEmail({
    required String email,
    String? subject,
    String? body,
  }) async {
    final uri = Uri(
      scheme: 'mailto',
      path: email,
      queryParameters: {
        if (subject != null) 'subject': subject,
        if (body != null) 'body': body,
      },
    );
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri);
    }
  }
}

