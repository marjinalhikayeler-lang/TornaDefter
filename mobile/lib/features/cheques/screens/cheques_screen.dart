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
  void initState() { super.initState(); _tabCtrl = TabController(length: 2, vsync: this); _loadData(); }

  Future<void> _loadData() async {
    final cid = await ApiClient().getActiveCompany();
    if (cid == null) return;
    try {
      final res = await ApiClient().dio.get('/companies/$cid/cheques-notes');
      final all = res.data is List ? res.data : (res.data?['data'] ?? []);
      _received = (all as List).where((c) => c['direction'] == 'RECEIVED').toList();
      _given = all.where((c) => c['direction'] == 'GIVEN').toList();
    } catch (_) {}
    if (mounted) setState(() => _loading = false);
  }

  String _statusLabel(String? s) => {'IN_PORTFOLIO':'Portföyde','DEPOSITED':'Bankada','COLLECTED':'Tahsil Edildi','ENDORSED':'Ciro Edildi','PAID':'Ödendi','BOUNCED':'Karşılıksız','RETURNED':'İade','CANCELLED':'İptal'}[s] ?? s ?? '';
  Color _statusColor(String? s) => {'IN_PORTFOLIO':AppColors.info,'DEPOSITED':AppColors.warning,'COLLECTED':AppColors.success,'PAID':AppColors.success,'BOUNCED':AppColors.danger,'ENDORSED':Colors.purple,'RETURNED':AppColors.accent,'CANCELLED':AppColors.textSecondaryDark}[s] ?? AppColors.accent;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.backgroundDark,
      appBar: AppBar(title: const Text('Çek / Senet'),
        bottom: TabBar(controller: _tabCtrl, indicatorColor: AppColors.primary, labelColor: AppColors.primary, unselectedLabelColor: AppColors.textSecondaryDark,
          tabs: const [Tab(text: 'Alınan'), Tab(text: 'Verilen')])),
      body: _loading ? const Center(child: CircularProgressIndicator(color: AppColors.primary))
        : TabBarView(controller: _tabCtrl, children: [_buildList(_received), _buildList(_given)]),
      floatingActionButton: FloatingActionButton(onPressed: () {}, backgroundColor: AppColors.fab, child: const Icon(Icons.add)),
    );
  }

  Widget _buildList(List<dynamic> items) {
    if (items.isEmpty) return const Center(child: Text('Kayıt yok', style: TextStyle(color: AppColors.textSecondaryDark)));
    return ListView.builder(padding: const EdgeInsets.all(12), itemCount: items.length, itemBuilder: (ctx, i) {
      final c = items[i];
      final amount = (c['amount'] ?? 0) as int;
      final dueDate = DateTime.tryParse(c['due_date'] ?? '');
      final type = c['type'] == 'CHEQUE' ? 'Çek' : 'Senet';
      final status = c['status'] as String?;
      return Container(
        margin: const EdgeInsets.only(bottom: 8),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(color: AppColors.surfaceDark, borderRadius: BorderRadius.circular(12)),
        child: Row(children: [
          Container(width: 44, height: 44,
            decoration: BoxDecoration(color: _statusColor(status).withOpacity(0.15), borderRadius: BorderRadius.circular(10)),
            child: Icon(c['type'] == 'CHEQUE' ? Icons.receipt : Icons.description, color: _statusColor(status), size: 22)),
          const SizedBox(width: 12),
          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text('$type ${c['cheque_number'] ?? ''}', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w600)),
            const SizedBox(height: 2),
            Row(children: [
              Container(padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
                decoration: BoxDecoration(color: _statusColor(status).withOpacity(0.2), borderRadius: BorderRadius.circular(4)),
                child: Text(_statusLabel(status), style: TextStyle(fontSize: 10, color: _statusColor(status)))),
              if (dueDate != null) ...[const SizedBox(width: 8), Text('Vade: ${DateUtil.formatDot(dueDate)}', style: const TextStyle(fontSize: 11, color: AppColors.textSecondaryDark))],
            ]),
          ])),
          Text(MoneyUtil.format(amount), style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.white)),
        ]),
      );
    });
  }
}

