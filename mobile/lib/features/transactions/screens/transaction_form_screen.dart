import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/api/api_client.dart';
import '../../../core/utils/formatters.dart';

class TransactionFormScreen extends StatefulWidget {
  final String? accountId;
  final String? type;
  const TransactionFormScreen({super.key, this.accountId, this.type});
  @override
  State<TransactionFormScreen> createState() => _TransactionFormScreenState();
}

class _TransactionFormScreenState extends State<TransactionFormScreen> {
  final _amountCtrl = TextEditingController();
  final _descCtrl = TextEditingController();
  final _docNoCtrl = TextEditingController();
  DateTime _date = DateTime.now();
  TimeOfDay _time = TimeOfDay.now();
  String _type = 'SALE';
  String _paymentMethod = 'CASH';
  String? _accountId;
  bool _loading = false;

  final _typeLabels = {'SALE': 'Borç Ekle', 'COLLECTION': 'Tahsilat', 'PURCHASE': 'Alacak Ekle', 'PAYMENT': 'Ödeme'};
  final _paymentMethods = [('CASH', 'Nakit'), ('BANK_TRANSFER', 'Havale/EFT'), ('CREDIT_CARD', 'Kredi Kartı'), ('CHEQUE', 'Çek'), ('PROMISSORY_NOTE', 'Senet')];

  @override
  void initState() {
    super.initState();
    _type = widget.type ?? 'SALE';
    _accountId = widget.accountId;
  }

  String get _title => _typeLabels[_type] ?? 'İşlem Ekle';

  Future<void> _pickDate() async {
    // OkLif tarzı scroll picker yerine standart picker
    final d = await showDatePicker(context: context, initialDate: _date, firstDate: DateTime(2020), lastDate: DateTime(2030), locale: const Locale('tr'));
    if (d != null) setState(() => _date = d);
  }

  Future<void> _pickTime() async {
    final t = await showTimePicker(context: context, initialTime: _time);
    if (t != null) setState(() => _time = t);
  }

  Future<void> _save() async {
    final amount = double.tryParse(_amountCtrl.text.replaceAll(',', '.'));
    if (amount == null || amount <= 0) { ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Geçerli bir tutar girin'))); return; }
    if (_accountId == null) { ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Cari seçin'))); return; }

    setState(() => _loading = true);
    final companyId = await ApiClient().getActiveCompany();
    if (companyId == null) return;

    try {
      await ApiClient().dio.post('/companies/$companyId/transactions', data: {
        'accountId': _accountId,
        'type': _type,
        'amount': MoneyUtil.toKurus(amount),
        'date': _date.toIso8601String().split('T')[0],
        'description': _descCtrl.text.trim().isEmpty ? null : _descCtrl.text.trim(),
        'documentNumber': _docNoCtrl.text.trim().isEmpty ? null : _docNoCtrl.text.trim(),
        'paymentMethod': _paymentMethod,
      });
      if (mounted) context.pop();
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Hata: $e')));
    }
    setState(() => _loading = false);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.backgroundDark,
      appBar: AppBar(title: Text(_title), actions: [
        IconButton(icon: const Icon(Icons.save), onPressed: _loading ? null : _save),
      ]),
      body: SingleChildScrollView(padding: const EdgeInsets.all(16), child: Column(children: [
        // Tarih ve saat - OkLif stili
        Row(children: [
          Expanded(child: InkWell(onTap: _pickDate, child: Container(
            padding: const EdgeInsets.all(14), decoration: BoxDecoration(color: AppColors.cardDark, borderRadius: BorderRadius.circular(12)),
            child: Row(children: [const Icon(Icons.calendar_today, size: 18, color: AppColors.textSecondaryDark), const SizedBox(width: 8),
              Text(DateUtil.formatDot(_date), style: const TextStyle(color: Colors.white))]),
          ))),
          const SizedBox(width: 12),
          Expanded(child: InkWell(onTap: _pickTime, child: Container(
            padding: const EdgeInsets.all(14), decoration: BoxDecoration(color: AppColors.cardDark, borderRadius: BorderRadius.circular(12)),
            child: Row(children: [const Icon(Icons.access_time, size: 18, color: AppColors.textSecondaryDark), const SizedBox(width: 8),
              Text('${_time.hour.toString().padLeft(2, '0')}:${_time.minute.toString().padLeft(2, '0')}:00', style: const TextStyle(color: Colors.white))]),
          ))),
        ]),
        const SizedBox(height: 12),
        // Belge no ve özel kod
        Row(children: [
          Expanded(child: TextField(controller: _docNoCtrl, style: const TextStyle(color: Colors.white),
            decoration: const InputDecoration(labelText: 'Belge No', prefixIcon: Icon(Icons.tag, color: AppColors.textSecondaryDark), labelStyle: TextStyle(color: AppColors.textSecondaryDark)))),
          const SizedBox(width: 12),
          Expanded(child: TextField(style: const TextStyle(color: Colors.white),
            decoration: const InputDecoration(labelText: 'Özel Kod', prefixIcon: Icon(Icons.tag, color: AppColors.textSecondaryDark), labelStyle: TextStyle(color: AppColors.textSecondaryDark)))),
        ]),
        const SizedBox(height: 16),
        // Tutar
        TextField(controller: _amountCtrl, keyboardType: const TextInputType.numberWithOptions(decimal: true),
          style: const TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.bold),
          decoration: const InputDecoration(labelText: 'Tutar (TL)', prefixIcon: Icon(Icons.attach_money, color: AppColors.primary), labelStyle: TextStyle(color: AppColors.textSecondaryDark)),
        ),
        const SizedBox(height: 16),
        // Ödeme yöntemi
        const Align(alignment: Alignment.centerLeft, child: Text('Ödeme Yöntemi', style: TextStyle(color: AppColors.textSecondaryDark, fontSize: 13))),
        const SizedBox(height: 8),
        Wrap(spacing: 8, runSpacing: 8, children: _paymentMethods.map((m) =>
          ChoiceChip(
            label: Text(m.$2), selected: _paymentMethod == m.$1,
            selectedColor: AppColors.primary, backgroundColor: AppColors.cardDark,
            labelStyle: TextStyle(color: _paymentMethod == m.$1 ? Colors.white : AppColors.textSecondaryDark),
            onSelected: (_) => setState(() => _paymentMethod = m.$1),
          ),
        ).toList()),
        const SizedBox(height: 16),
        // Açıklama
        TextField(controller: _descCtrl, maxLines: 2, style: const TextStyle(color: Colors.white),
          decoration: const InputDecoration(labelText: 'Açıklama', labelStyle: TextStyle(color: AppColors.textSecondaryDark))),
        const SizedBox(height: 24),
        // Kaydet
        Row(children: [
          Expanded(child: SizedBox(height: 52, child: ElevatedButton(
            onPressed: _loading ? null : _save,
            child: _loading ? const CircularProgressIndicator(color: Colors.white) : const Text('Kaydet'),
          ))),
          const SizedBox(width: 12),
          Expanded(child: SizedBox(height: 52, child: OutlinedButton(
            onPressed: _loading ? null : () { _save().then((_) { _amountCtrl.clear(); _descCtrl.clear(); _docNoCtrl.clear(); }); },
            style: OutlinedButton.styleFrom(side: const BorderSide(color: AppColors.primary)),
            child: const Text('Kaydet & Yeni', style: TextStyle(color: AppColors.primary)),
          ))),
        ]),
      ])),
    );
  }
}

