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
  List<dynamic> _accounts = [];

  final _typeLabels = {'SALE': 'Borç Ekle', 'COLLECTION': 'Tahsilat', 'PURCHASE': 'Alacak Ekle', 'PAYMENT': 'Ödeme'};
  final _paymentMethods = [('CASH', 'Nakit'), ('BANK_TRANSFER', 'Havale/EFT'), ('CREDIT_CARD', 'Kredi Kartı'), ('CHEQUE', 'Çek'), ('PROMISSORY_NOTE', 'Senet')];

  @override
  void initState() {
    super.initState();
    _type = widget.type ?? 'SALE';
    _accountId = widget.accountId;
    _loadAccounts();
  }

  Future<void> _loadAccounts() async {
    try {
      final cid = await ApiClient().ensureActiveCompany();
      if (cid != null) {
        final res = await ApiClient().dio.get('/companies/$cid/accounts');
        final list = res.data is List ? res.data : (res.data?['data'] ?? []);
        setState(() {
          _accounts = list as List;
          if (_accountId == null && _accounts.isNotEmpty) {
            _accountId = _accounts[0]['id'];
          }
        });
      }
    } catch (_) {}
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
    if (amount == null || amount <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Geçerli bir tutar girin')));
      return;
    }
    if (_accountId == null) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Lütfen bir cari hesap seçin veya yeni cari ekleyin')));
      return;
    }

    setState(() => _loading = true);
    final companyId = await ApiClient().ensureActiveCompany();
    if (companyId == null) {
      if (mounted) {
        setState(() => _loading = false);
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Aktif firma bulunamadı. Lütfen tekrar giriş yapın.')));
      }
      return;
    }

    try {
      await ApiClient().dio.post('/companies/$companyId/transactions', data: {
        'accountId': _accountId,
        'account_id': _accountId,
        'type': _type,
        'amount': MoneyUtil.toKurus(amount),
        'date': _date.toIso8601String().split('T')[0],
        'description': _descCtrl.text.trim().isEmpty ? null : _descCtrl.text.trim(),
        'documentNumber': _docNoCtrl.text.trim().isEmpty ? null : _docNoCtrl.text.trim(),
        'document_number': _docNoCtrl.text.trim().isEmpty ? null : _docNoCtrl.text.trim(),
        'paymentMethod': _paymentMethod,
        'payment_method': _paymentMethod,
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('İşlem başarıyla kaydedildi')));
        context.pop();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Hata: $e')));
      }
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.backgroundDark,
      appBar: AppBar(title: Text(_title), actions: [
        IconButton(icon: const Icon(Icons.save), onPressed: _loading ? null : _save),
      ]),
      body: SingleChildScrollView(padding: const EdgeInsets.all(16), child: Column(children: [
        if (_accounts.isEmpty) ...[
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppColors.cardDark,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: AppColors.warning.withOpacity(0.5)),
            ),
            child: Column(
              children: [
                const Icon(Icons.info_outline, color: AppColors.warning, size: 36),
                const SizedBox(height: 8),
                const Text(
                  'Henüz kayıtlı bir cari hesabınız bulunmuyor.',
                  style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 15),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 4),
                const Text(
                  'İşlem (Borç / Tahsilat / Alacak) eklemek için önce bir cari hesap oluşturmalısınız.',
                  style: TextStyle(color: AppColors.textSecondaryDark, fontSize: 12),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 12),
                ElevatedButton.icon(
                  onPressed: () async {
                    await context.push('/accounts/new');
                    _loadAccounts();
                  },
                  icon: const Icon(Icons.person_add),
                  label: const Text('Yeni Cari Hesap Ekle'),
                  style: ElevatedButton.styleFrom(backgroundColor: AppColors.primary),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
        ] else ...[
          DropdownButtonFormField<String>(
            value: _accountId,
            dropdownColor: AppColors.surfaceDark,
            style: const TextStyle(color: Colors.white, fontSize: 16),
            decoration: const InputDecoration(
              labelText: 'Cari Hesap Seçin *',
              prefixIcon: Icon(Icons.person, color: AppColors.primary),
            ),
            items: _accounts.map<DropdownMenuItem<String>>((a) => DropdownMenuItem(
              value: a['id'] as String,
              child: Text(a['title'] ?? '', overflow: TextOverflow.ellipsis),
            )).toList(),
            onChanged: (v) => setState(() => _accountId = v),
          ),
          const SizedBox(height: 16),
        ],
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

