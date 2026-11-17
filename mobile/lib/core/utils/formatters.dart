import 'package:intl/intl.dart';

class MoneyUtil {
  /// Kuruştan TL'ye dönüşüm ve formatlama
  static String format(int amountInKurus, {String currency = 'TRY'}) {
    final amount = amountInKurus / 100.0;
    final formatter = NumberFormat('#,##0.00', 'tr_TR');
    final symbol = currency == 'TRY' ? 'TL' : currency;
    return '${formatter.format(amount)} $symbol';
  }

  /// Sadece sayıyı formatla (para birimi olmadan)
  static String formatNumber(int amountInKurus) {
    final amount = amountInKurus / 100.0;
    final formatter = NumberFormat('#,##0.00', 'tr_TR');
    return formatter.format(amount);
  }

  /// TL'den kuruşa dönüşüm
  static int toKurus(double amountInTL) {
    return (amountInTL * 100).round();
  }

  /// Bakiye rengini belirle
  static bool isDebit(int balance) => balance > 0;
  static bool isCredit(int balance) => balance < 0;
}

class DateUtil {
  static final _turkishMonths = [
    'Oca', 'Şub', 'Mar', 'Nis', 'May', 'Haz',
    'Tem', 'Ağu', 'Eyl', 'Eki', 'Kas', 'Ara'
  ];

  static final _turkishMonthsFull = [
    'Ocak', 'Şubat', 'Mart', 'Nisan', 'Mayıs', 'Haziran',
    'Temmuz', 'Ağustos', 'Eylül', 'Ekim', 'Kasım', 'Aralık'
  ];

  /// Tarih formatla: "17 Kas 26" gibi
  static String formatShort(DateTime date) {
    return '${date.day} ${_turkishMonths[date.month - 1]} ${date.year % 100}';
  }

  /// Tarih formatla: "17 Kasım 2026"
  static String formatLong(DateTime date) {
    return '${date.day} ${_turkishMonthsFull[date.month - 1]} ${date.year}';
  }

  /// Tarih formatla: "17.11.2026"
  static String formatDot(DateTime date) {
    return '${date.day.toString().padLeft(2, '0')}.${date.month.toString().padLeft(2, '0')}.${date.year}';
  }

  /// Tarih formatla: "17.11.2026"
  static String format(DateTime date) => formatDot(date);

  /// Tarih ve saat formatla: "17.11.2026 14:30:00"
  static String formatDateTime(dynamic date) {
    if (date == null) return '';
    DateTime? d;
    if (date is DateTime) {
      d = date;
    } else if (date is String) {
      d = DateTime.tryParse(date);
    }
    if (d == null) return date.toString();
    return '${formatDot(d)} ${formatTime(d)}';
  }

  /// Saat formatla: "17:50:00"
  static String formatTime(DateTime date) {
    return '${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}:${date.second.toString().padLeft(2, '0')}';
  }

  /// Vade geçmişse kaç gün geçtiğini hesapla
  static String overdueText(DateTime dueDate) {
    final now = DateTime.now();
    if (dueDate.isAfter(now)) return '';
    final diff = now.difference(dueDate);
    final months = diff.inDays ~/ 30;
    final days = diff.inDays % 30;
    if (months > 0) {
      return '$months ay $days gün geçti';
    }
    return '$days gün geçti';
  }

  /// Vade yaklaşıyor mu?
  static bool isDueSoon(DateTime dueDate, {int daysThreshold = 7}) {
    final now = DateTime.now();
    final diff = dueDate.difference(now);
    return diff.inDays <= daysThreshold && diff.inDays >= 0;
  }
}

