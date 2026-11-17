import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

/// OkLif tarzı hareket kartı - tarih bloğu + açıklama + tutar + yürüyen bakiye
class TransactionCard extends StatelessWidget {
  final int day;
  final String monthShort; // Oca, Şub...
  final String description;
  final String? paymentMethodLabel;
  final String amountText;
  final Color amountColor;
  final String? runningBalanceText;
  final VoidCallback? onTap;

  const TransactionCard({
    super.key,
    required this.day,
    required this.monthShort,
    required this.description,
    this.paymentMethodLabel,
    required this.amountText,
    required this.amountColor,
    this.runningBalanceText,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: AppColors.surfaceDark,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          children: [
            // Tarih bloğu
            Container(
              width: 50,
              padding: const EdgeInsets.symmetric(vertical: 4),
              child: Column(
                children: [
                  Text(
                    day.toString(),
                    style: const TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: AppColors.textPrimaryDark,
                    ),
                  ),
                  Text(
                    monthShort,
                    style: const TextStyle(
                      fontSize: 12,
                      color: AppColors.textSecondaryDark,
                    ),
                  ),
                ],
              ),
            ),
            // Sol kenar çizgisi
            Container(
              width: 3,
              height: 50,
              margin: const EdgeInsets.symmetric(horizontal: 12),
              decoration: BoxDecoration(
                color: amountColor,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            // Açıklama ve ödeme yöntemi
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    description,
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: AppColors.textPrimaryDark,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  if (paymentMethodLabel != null) ...[
                    const SizedBox(height: 4),
                    Text(
                      paymentMethodLabel!,
                      style: const TextStyle(
                        fontSize: 12,
                        color: AppColors.textSecondaryDark,
                      ),
                    ),
                  ],
                ],
              ),
            ),
            // Tutar ve yürüyen bakiye
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  amountText,
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.bold,
                    color: amountColor,
                  ),
                ),
                if (runningBalanceText != null) ...[
                  const SizedBox(height: 4),
                  Text(
                    runningBalanceText!,
                    style: const TextStyle(
                      fontSize: 11,
                      color: AppColors.textSecondaryDark,
                    ),
                  ),
                ],
              ],
            ),
          ],
        ),
      ),
    );
  }
}

/// Reminder kartı - OkLif stili (turuncu/kırmızı vade geçmiş)
class ReminderCard extends StatelessWidget {
  final int day;
  final String monthShort;
  final String description;
  final String subLabel;
  final String amountText;
  final String overdueText;
  final VoidCallback? onTap;

  const ReminderCard({
    super.key,
    required this.day,
    required this.monthShort,
    required this.description,
    required this.subLabel,
    required this.amountText,
    required this.overdueText,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: AppColors.surfaceDark,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: AppColors.cardDark),
        ),
        child: Row(
          children: [
            Container(
              width: 50,
              padding: const EdgeInsets.symmetric(vertical: 4),
              child: Column(
                children: [
                  Text(day.toString(),
                      style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: AppColors.textPrimaryDark)),
                  Text(monthShort,
                      style: const TextStyle(fontSize: 12, color: AppColors.textSecondaryDark)),
                ],
              ),
            ),
            Container(width: 3, height: 50, margin: const EdgeInsets.symmetric(horizontal: 12),
              decoration: BoxDecoration(color: AppColors.warning, borderRadius: BorderRadius.circular(2))),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(description,
                      style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: AppColors.textPrimaryDark),
                      maxLines: 1, overflow: TextOverflow.ellipsis),
                  const SizedBox(height: 2),
                  Text(subLabel,
                      style: const TextStyle(fontSize: 12, color: AppColors.textSecondaryDark)),
                ],
              ),
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(amountText,
                    style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: AppColors.textPrimaryDark)),
                const SizedBox(height: 2),
                Text(overdueText,
                    style: const TextStyle(fontSize: 11, color: AppColors.danger, fontStyle: FontStyle.italic)),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

