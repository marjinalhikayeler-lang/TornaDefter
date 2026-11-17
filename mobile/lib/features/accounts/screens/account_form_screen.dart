import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/api/api_client.dart';

class AccountFormScreen extends StatefulWidget {
  final String? accountId;
  const AccountFormScreen({super.key, this.accountId});
  @override
  State<AccountFormScreen> createState() => _AccountFormScreenState();
}

class _AccountFormScreenState extends State<AccountFormScreen> {
  final _titleCtrl = TextEditingController();
  final _phoneCtrl = TextEditingController();
  final _emailCtrl = TextEditingController();
  final _addressCtrl = TextEditingController();
  final _taxOfficeCtrl = TextEditingController();
  final _taxNoCtrl = TextEditingController();
  final _notesCtrl = TextEditingController();
  final _openingBalCtrl = TextEditingController(text: '0');
  String _type = 'CUSTOMER';
  String _balDir = 'DEBIT';
  bool _loading = false;
  bool get _isEdit => widget.accountId != null;

  final _types = [('CUSTOMER', 'Müşteri'), ('SUPPLIER', 'Tedarikçi'), ('PERSONNEL', 'Personel'), ('PARTNER', 'Ortak'), ('OTHER', 'Diğer')];

  @override
  void initState() { super.initState(); if (_isEdit) _loadAccount(); }

  Future<void> _loadAccount() async {
    final companyId = await ApiClient().getActiveCompany();
    if (companyId == null) return;
    try {
      final res = await ApiClient().dio.get('/companies/$companyId/accounts/${widget.accountId}');
      final a = res.data is Map ? res.data : {};
      _titleCtrl.text = a['title'] ?? '';
      _type = a['account_type'] ?? 'CUSTOMER';
      _emailCtrl.text = a['email'] ?? '';
      _addressCtrl.text = a['address'] ?? '';
      _taxOfficeCtrl.text = a['tax_office'] ?? '';
      _taxNoCtrl.text = a['tax_number'] ?? '';
      _notesCtrl.text = a['notes'] ?? '';
      setState(() {});
    } catch (_) {}
  }

  Future<void> _save() async {
    if (_titleCtrl.text.trim().isEmpty) { ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Ünvan zorunludur'))); return; }
    setState(() => _loading = true);
    final companyId = await ApiClient().getActiveCompany();
    if (companyId == null) return;
    final data = {
      'title': _titleCtrl.text.trim(),
      'accountType': _type,
      'phone': _phoneCtrl.text.trim().isEmpty ? null : _phoneCtrl.text.trim(),
      'email': _emailCtrl.text.trim().isEmpty ? null : _emailCtrl.text.trim(),
      'address': _addressCtrl.text.trim().isEmpty ? null : _addressCtrl.text.trim(),
      'taxOffice': _taxOfficeCtrl.text.trim().isEmpty ? null : _taxOfficeCtrl.text.trim(),
      'taxNumber': _taxNoCtrl.text.trim().isEmpty ? null : _taxNoCtrl.text.trim(),
      'notes': _notesCtrl.text.trim().isEmpty ? null : _notesCtrl.text.trim(),
      'openingBalance': int.tryParse(_openingBalCtrl.text) ?? 0,
      'openingBalanceDirection': _balDir,
    };
    try {
      if (_isEdit) { await ApiClient().dio.put('/companies/$companyId/accounts/${widget.accountId}', data: data); }
      else { await ApiClient().dio.post('/companies/$companyId/accounts', data: data); }
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
      appBar: AppBar(title: Text(_isEdit ? 'Cari Düzenle' : 'Yeni Cari'), actions: [
        IconButton(icon: const Icon(Icons.save), onPressed: _loading ? null : _save),
      ]),
      body: SingleChildScrollView(padding: const EdgeInsets.all(16), child: Column(children: [
        _field('Ünvan / Ad Soyad *', _titleCtrl),
        const SizedBox(height: 12),
        // Tür seçimi
        DropdownButtonFormField<String>(
          value: _type, dropdownColor: AppColors.cardDark, style: const TextStyle(color: Colors.white),
          decoration: const InputDecoration(labelText: 'Cari Türü', labelStyle: TextStyle(color: AppColors.textSecondaryDark)),
          items: _types.map((t) => DropdownMenuItem(value: t.$1, child: Text(t.$2))).toList(),
          onChanged: (v) => setState(() => _type = v!),
        ),
        const SizedBox(height: 12),
        _field('Telefon', _phoneCtrl, type: TextInputType.phone),
        const SizedBox(height: 12),
        _field('E-posta', _emailCtrl, type: TextInputType.emailAddress),
        const SizedBox(height: 12),
        _field('Adres', _addressCtrl, maxLines: 2),
        const SizedBox(height: 12),
        Row(children: [
          Expanded(child: _field('Vergi Dairesi', _taxOfficeCtrl)),
          const SizedBox(width: 12),
          Expanded(child: _field('Vergi No', _taxNoCtrl, type: TextInputType.number)),
        ]),
        const SizedBox(height: 12),
        Row(children: [
          Expanded(child: _field('Açılış Bakiyesi (kuruş)', _openingBalCtrl, type: TextInputType.number)),
          const SizedBox(width: 12),
          ToggleButtons(
            isSelected: [_balDir == 'DEBIT', _balDir == 'CREDIT'],
            onPressed: (i) => setState(() => _balDir = i == 0 ? 'DEBIT' : 'CREDIT'),
            borderRadius: BorderRadius.circular(8),
            selectedColor: Colors.white,
            fillColor: _balDir == 'DEBIT' ? AppColors.danger : AppColors.success,
            children: const [Padding(padding: EdgeInsets.symmetric(horizontal: 12), child: Text('Borç')), Padding(padding: EdgeInsets.symmetric(horizontal: 12), child: Text('Alacak'))],
          ),
        ]),
        const SizedBox(height: 12),
        _field('Notlar', _notesCtrl, maxLines: 3),
        const SizedBox(height: 24),
        SizedBox(width: double.infinity, height: 52, child: ElevatedButton(
          onPressed: _loading ? null : _save,
          child: _loading ? const CircularProgressIndicator(color: Colors.white) : Text(_isEdit ? 'Güncelle' : 'Kaydet'),
        )),
      ])),
    );
  }

  Widget _field(String label, TextEditingController ctrl, {TextInputType? type, int maxLines = 1}) {
    return TextField(controller: ctrl, keyboardType: type, maxLines: maxLines, style: const TextStyle(color: Colors.white),
      decoration: InputDecoration(labelText: label, labelStyle: const TextStyle(color: AppColors.textSecondaryDark)));
  }
}

