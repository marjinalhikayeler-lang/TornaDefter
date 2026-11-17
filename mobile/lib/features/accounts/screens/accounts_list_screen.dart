import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/api/api_client.dart';
import '../../../core/utils/formatters.dart';

class AccountsListScreen extends StatefulWidget {
  const AccountsListScreen({super.key});
  @override
  State<AccountsListScreen> createState() => _AccountsListScreenState();
}

class _AccountsListScreenState extends State<AccountsListScreen> {
  List<dynamic> _accounts = [];
  bool _loading = true;
  String _searchQuery = '';
  String _filter = 'ALL';
  final _searchCtrl = TextEditingController();

  @override
  void initState() { super.initState(); _loadAccounts(); }

  Future<void> _loadAccounts() async {
    setState(() => _loading = true);
    try {
      final companyId = await ApiClient().getActiveCompany();
      if (companyId == null) return;
      final res = await ApiClient().dio.get('/companies/$companyId/accounts', queryParameters: {
        if (_searchQuery.isNotEmpty) 'search': _searchQuery,
        if (_filter != 'ALL') 'type': _filter,
      });
      setState(() { _accounts = res.data['data'] ?? res.data ?? []; _loading = false; });
    } catch (_) { setState(() => _loading = false); }
  }

  Color _balanceColor(int balance) => balance > 0 ? AppColors.debit : balance < 0 ? AppColors.credit : AppColors.textSecondaryDark;
  String _typeLabel(String type) => {'CUSTOMER': 'Müşteri', 'SUPPLIER': 'Tedarikçi', 'PERSONNEL': 'Personel', 'PARTNER': 'Ortak', 'OTHER': 'Diğer'}[type] ?? type;
  Color _typeBadgeColor(String type) => {'CUSTOMER': AppColors.primary, 'SUPPLIER': AppColors.warning, 'PERSONNEL': Colors.purple, 'PARTNER': Colors.teal, 'OTHER': AppColors.accent}[type] ?? AppColors.accent;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.backgroundDark,
      appBar: AppBar(
        title: const Text('Cariler'),
        actions: [
          IconButton(icon: const Icon(Icons.filter_list), onPressed: _showFilterSheet),
          IconButton(icon: const Icon(Icons.add), onPressed: () => context.go('/accounts/new')),
        ],
      ),
      body: Column(children: [
        // Arama
        Padding(
          padding: const EdgeInsets.all(12),
          child: TextField(
            controller: _searchCtrl,
            style: const TextStyle(color: Colors.white),
            decoration: InputDecoration(
              hintText: 'Cari ara (ad, telefon, vergi no)...',
              prefixIcon: const Icon(Icons.search, color: AppColors.textSecondaryDark),
              suffixIcon: _searchQuery.isNotEmpty ? IconButton(icon: const Icon(Icons.clear, color: AppColors.textSecondaryDark),
                onPressed: () { _searchCtrl.clear(); setState(() => _searchQuery = ''); _loadAccounts(); }) : null,
            ),
            onSubmitted: (v) { setState(() => _searchQuery = v); _loadAccounts(); },
          ),
        ),
        // Filtre chips
        SizedBox(
          height: 40,
          child: ListView(scrollDirection: Axis.horizontal, padding: const EdgeInsets.symmetric(horizontal: 12), children: [
            for (final f in [('ALL', 'Tümü'), ('CUSTOMER', 'Müşteri'), ('SUPPLIER', 'Tedarikçi'), ('PERSONNEL', 'Personel')])
              Padding(
                padding: const EdgeInsets.only(right: 8),
                child: ChoiceChip(
                  label: Text(f.$2), selected: _filter == f.$1,
                  selectedColor: AppColors.primary, labelStyle: TextStyle(color: _filter == f.$1 ? Colors.white : AppColors.textSecondaryDark),
                  backgroundColor: AppColors.cardDark,
                  onSelected: (_) { setState(() => _filter = f.$1); _loadAccounts(); },
                ),
              ),
          ]),
        ),
        const SizedBox(height: 8),
        // Liste
        Expanded(
          child: _loading
            ? const Center(child: CircularProgressIndicator(color: AppColors.primary))
            : _accounts.isEmpty
              ? const Center(child: Text('Cari hesap bulunamadı', style: TextStyle(color: AppColors.textSecondaryDark)))
              : RefreshIndicator(
                  onRefresh: _loadAccounts,
                  child: ListView.builder(
                    itemCount: _accounts.length,
                    itemBuilder: (ctx, i) {
                      final a = _accounts[i];
                      final balance = (a['current_balance'] ?? a['opening_balance'] ?? 0) as int;
                      return ListTile(
                        onTap: () => context.go('/accounts/${a['id']}'),
                        title: Text(a['title'] ?? '', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w600)),
                        subtitle: Row(children: [
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                            decoration: BoxDecoration(color: _typeBadgeColor(a['account_type'] ?? '').withOpacity(0.2), borderRadius: BorderRadius.circular(4)),
                            child: Text(_typeLabel(a['account_type'] ?? ''), style: TextStyle(fontSize: 10, color: _typeBadgeColor(a['account_type'] ?? ''))),
                          ),
                          const SizedBox(width: 8),
                          Text(a['code'] ?? '', style: const TextStyle(fontSize: 11, color: AppColors.textSecondaryDark)),
                        ]),
                        trailing: Text(MoneyUtil.format(balance), style: TextStyle(fontWeight: FontWeight.bold, color: _balanceColor(balance))),
                      );
                    },
                  ),
                ),
        ),
      ]),
    );
  }

  void _showFilterSheet() {
    showModalBottomSheet(context: context, backgroundColor: AppColors.surfaceDark,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (ctx) => Padding(padding: const EdgeInsets.all(24), child: Column(mainAxisSize: MainAxisSize.min, children: [
        const Text('Filtreler', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white)),
        const SizedBox(height: 16),
        for (final f in [('ALL', 'Tümü'), ('CUSTOMER', 'Müşteriler'), ('SUPPLIER', 'Tedarikçiler'), ('PERSONNEL', 'Personel')])
          ListTile(title: Text(f.$2, style: const TextStyle(color: Colors.white)),
            trailing: _filter == f.$1 ? const Icon(Icons.check, color: AppColors.primary) : null,
            onTap: () { setState(() => _filter = f.$1); Navigator.pop(ctx); _loadAccounts(); }),
      ])));
  }
}

