import 'package:flutter/material.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/api/api_client.dart';
import '../../../core/utils/formatters.dart';

class ChequesScreen extends StatefulWidget {
  const ChequesScreen({super.key});
  @override
  State<ChequesScreen> createState() => _ChequesScreenState();
}

class _ChequesScreenState extends State<ChequesScreen> with SingleTickerProviderStateMixin {
  late TabController _tabCtrl;
  List<dynamic> _received = [];
  List<dynamic> _given = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _tabCtrl = TabController(length: 2, vsync: this);
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() => _loading = true);
    try {
      final cid = await ApiClient().ensureActiveCompany();
      if (cid != null) {
        final res = await ApiClient().dio.get('/companies/$cid/cheques-notes');
        final all = res.data is List ? res.data : (res.data?['data'] ?? []);
        _received = (all as List).where((c) => c['direction'] == 'RECEIVED').toList();
        _given = all.where((c) => c['direction'] == 'GIVEN').toList();
      }
    } catch (_) {}
    if (mounted) setState(() => _loading = false);
  }

  void _showAddDialog() {
    String type = 'CHEQUE'; // CHEQUE / PROMISSORY_NOTE
    String direction = _tabCtrl.index == 0 ? 'RECEIVED' : 'GIVEN';
    final amountCtrl = TextEditingController();
    final numberCtrl = TextEditingController();
    final drawerCtrl = TextEditingController();
    final bankCtrl = TextEditingController();
    DateTime dueDate = DateTime.now().add(const Duration(days: 30));

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppColors.surfaceDark,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setModalState) => Padding(
          padding: EdgeInsets.only(
            left: 20, right: 20, top: 20,
            bottom: MediaQuery.of(ctx).viewInsets.bottom + 20,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text('Yeni Çek / Senet Ekle', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white)),
                  IconButton(icon: const Icon(Icons.close, color: AppColors.textSecondaryDark), onPressed: () => Navigator.pop(ctx)),
                ],
              ),
              const SizedBox(height: 12),
              // Çek mi Senet mi?
              Row(
                children: [
                  Expanded(
                    child: ChoiceChip(
                      label: const Center(child: Text('Çek')),
                      selected: type == 'CHEQUE',
                      selectedColor: AppColors.primary,
                      backgroundColor: AppColors.cardDark,
                      labelStyle: TextStyle(color: type == 'CHEQUE' ? Colors.white : AppColors.textSecondaryDark),
                      onSelected: (_) => setModalState(() => type = 'CHEQUE'),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: ChoiceChip(
                      label: const Center(child: Text('Senet')),
                      selected: type == 'PROMISSORY_NOTE',
                      selectedColor: AppColors.primary,
                      backgroundColor: AppColors.cardDark,
                      labelStyle: TextStyle(color: type == 'PROMISSORY_NOTE' ? Colors.white : AppColors.textSecondaryDark),
                      onSelected: (_) => setModalState(() => type = 'PROMISSORY_NOTE'),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              // Alınan mı Verilen mi?
              Row(
                children: [
                  Expanded(
                    child: ChoiceChip(
                      label: const Center(child: Text('Alınan (Müşteriden)')),
                      selected: direction == 'RECEIVED',
                      selectedColor: AppColors.success,
                      backgroundColor: AppColors.cardDark,
                      labelStyle: TextStyle(color: direction == 'RECEIVED' ? Colors.white : AppColors.textSecondaryDark),
                      onSelected: (_) => setModalState(() => direction = 'RECEIVED'),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: ChoiceChip(
                      label: const Center(child: Text('Verilen (Tedarikçiye)')),
                      selected: direction == 'GIVEN',
                      selectedColor: AppColors.danger,
                      backgroundColor: AppColors.cardDark,
                      labelStyle: TextStyle(color: direction == 'GIVEN' ? Colors.white : AppColors.textSecondaryDark),
                      onSelected: (_) => setModalState(() => direction = 'GIVEN'),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              TextField(
                controller: amountCtrl,
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
                decoration: const InputDecoration(labelText: 'Tutar (TL) *', prefixIcon: Icon(Icons.currency_lira, color: AppColors.primary)),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: numberCtrl,
                style: const TextStyle(color: Colors.white),
                decoration: InputDecoration(labelText: type == 'CHEQUE' ? 'Çek Numarası' : 'Senet Numarası', prefixIcon: const Icon(Icons.tag, color: AppColors.textSecondaryDark)),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: drawerCtrl,
                style: const TextStyle(color: Colors.white),
                decoration: const InputDecoration(labelText: 'Keşideci / Borçlu Adı', prefixIcon: Icon(Icons.person_outline, color: AppColors.textSecondaryDark)),
              ),
              if (type == 'CHEQUE') ...[
                const SizedBox(height: 12),
                TextField(
                  controller: bankCtrl,
                  style: const TextStyle(color: Colors.white),
                  decoration: const InputDecoration(labelText: 'Banka / Şube', prefixIcon: Icon(Icons.account_balance, color: AppColors.textSecondaryDark)),
                ),
              ],
              const SizedBox(height: 12),
              ListTile(
                contentPadding: EdgeInsets.zero,
                leading: const Icon(Icons.calendar_today, color: AppColors.primary),
                title: Text('Vade Tarihi: ${dueDate.day}.${dueDate.month}.${dueDate.year}', style: const TextStyle(color: Colors.white)),
                trailing: const Icon(Icons.arrow_forward_ios, size: 14, color: AppColors.textSecondaryDark),
                onTap: () async {
                  final picked = await showDatePicker(
                    context: context,
                    initialDate: dueDate,
                    firstDate: DateTime(2020),
                    lastDate: DateTime(2035),
                  );
                  if (picked != null) {
                    setModalState(() => dueDate = picked);
                  }
                },
              ),
              const SizedBox(height: 16),
              SizedBox(
                width: double.infinity,
                height: 48,
                child: ElevatedButton(
                  onPressed: () async {
                    final amountNum = double.tryParse(amountCtrl.text.replaceAll(',', '.'));
                    if (amountNum == null || amountNum <= 0) {
                      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Geçerli bir tutar girin')));
                      return;
                    }
                    final cid = await ApiClient().ensureActiveCompany();
                    if (cid == null) return;
                    try {
                      await ApiClient().dio.post('/companies/$cid/cheques-notes', data: {
                        'type': type,
                        'direction': direction,
                        'amount': MoneyUtil.toKurus(amountNum),
                        'cheque_number': numberCtrl.text.trim().isEmpty ? null : numberCtrl.text.trim(),
                        'drawer': drawerCtrl.text.trim().isEmpty ? 'Bilinmeyen' : drawerCtrl.text.trim(),
                        'bank_name': bankCtrl.text.trim().isEmpty ? null : bankCtrl.text.trim(),
                        'due_date': dueDate.toIso8601String().split('T')[0],
                        'status': 'IN_PORTFOLIO',
                      });
                      if (ctx.mounted) Navigator.pop(ctx);
                      _loadData();
                    } catch (e) {
                      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Hata: $e')));
                    }
                  },
                  style: ElevatedButton.styleFrom(backgroundColor: AppColors.primary),
                  child: const Text('Kaydet', style: TextStyle(color: Colors.white, fontSize: 16)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _statusLabel(String? s) => {'IN_PORTFOLIO':'Portföyde','DEPOSITED':'Bankada','COLLECTED':'Tahsil Edildi','ENDORSED':'Ciro Edildi','PAID':'Ödendi','BOUNCED':'Karşılıksız','RETURNED':'İade','CANCELLED':'İptal'}[s] ?? s ?? '';
  Color _statusColor(String? s) => {'IN_PORTFOLIO':AppColors.info,'DEPOSITED':AppColors.warning,'COLLECTED':AppColors.success,'PAID':AppColors.success,'BOUNCED':AppColors.danger,'ENDORSED':Colors.purple,'RETURNED':AppColors.accent,'CANCELLED':AppColors.textSecondaryDark}[s] ?? AppColors.accent;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.backgroundDark,
      appBar: AppBar(
        title: const Text('Çek & Senet Takibi'),
        bottom: TabBar(
          controller: _tabCtrl,
          indicatorColor: AppColors.primary,
          labelColor: AppColors.primary,
          unselectedLabelColor: AppColors.textSecondaryDark,
          tabs: const [Tab(text: 'Alınan (Portföy)'), Tab(text: 'Verilen (Borç)')],
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _showAddDialog,
        backgroundColor: AppColors.primary,
        icon: const Icon(Icons.add),
        label: const Text('Yeni Çek/Senet'),
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator(color: AppColors.primary))
          : TabBarView(
              controller: _tabCtrl,
              children: [_buildList(_received), _buildList(_given)],
            ),
    );
  }

  Widget _buildList(List<dynamic> items) {
    if (items.isEmpty) {
      return RefreshIndicator(
        onRefresh: _loadData,
        child: const Center(child: Text('Kayıt bulunamadı', style: TextStyle(color: AppColors.textSecondaryDark))),
      );
    }
    return RefreshIndicator(
      onRefresh: _loadData,
      child: ListView.builder(
        padding: const EdgeInsets.all(12),
        itemCount: items.length,
        itemBuilder: (ctx, i) {
          final c = items[i];
          final amount = (c['amount'] ?? 0) as int;
          final dueDate = DateTime.tryParse(c['due_date'] ?? '');
          final type = c['type'] == 'CHEQUE' ? 'Çek' : 'Senet';
          final status = c['status'] as String?;
          return Container(
            margin: const EdgeInsets.only(bottom: 8),
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(color: AppColors.surfaceDark, borderRadius: BorderRadius.circular(12)),
            child: Row(
              children: [
                Container(
                  width: 44, height: 44,
                  decoration: BoxDecoration(color: _statusColor(status).withOpacity(0.15), borderRadius: BorderRadius.circular(10)),
                  child: Icon(c['type'] == 'CHEQUE' ? Icons.receipt : Icons.description, color: _statusColor(status), size: 22),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('$type ${c['cheque_number'] ?? ''} - ${c['drawer'] ?? ''}', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w600)),
                      const SizedBox(height: 2),
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
                            decoration: BoxDecoration(color: _statusColor(status).withOpacity(0.2), borderRadius: BorderRadius.circular(4)),
                            child: Text(_statusLabel(status), style: TextStyle(fontSize: 10, color: _statusColor(status))),
                          ),
                          if (dueDate != null) ...[
                            const SizedBox(width: 8),
                            Text('Vade: ${DateUtil.formatDot(dueDate)}', style: const TextStyle(fontSize: 11, color: AppColors.textSecondaryDark)),
                          ],
                        ],
                      ),
                    ],
                  ),
                ),
                Text(MoneyUtil.format(amount), style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.white, fontSize: 15)),
              ],
            ),
          );
        },
      ),
    );
  }
}
