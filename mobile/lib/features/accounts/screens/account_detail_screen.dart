import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/api/api_client.dart';
import '../../../core/utils/formatters.dart';
import '../../../core/widgets/transaction_card.dart';

class AccountDetailScreen extends StatefulWidget {
  final String accountId;
  const AccountDetailScreen({super.key, required this.accountId});
  @override
  State<AccountDetailScreen> createState() => _AccountDetailScreenState();
}

class _AccountDetailScreenState extends State<AccountDetailScreen> with SingleTickerProviderStateMixin {
  Map<String, dynamic>? _account;
  List<dynamic> _transactions = [];
  bool _loading = true;
  late TabController _tabCtrl;

  final _turkishMonths = ['Oca','Şub','Mar','Nis','May','Haz','Tem','Ağu','Eyl','Eki','Kas','Ara'];

  @override
  void initState() {
    super.initState();
    _tabCtrl = TabController(length: 4, vsync: this);
    _loadData();
  }

  Future<void> _loadData() async {
    try {
      final companyId = await ApiClient().getActiveCompany();
      if (companyId == null) return;
      final res = await ApiClient().dio.get('/companies/$companyId/accounts/${widget.accountId}');
      _account = res.data is Map ? res.data : (res.data?['data'] ?? {});
      
      final txRes = await ApiClient().dio.get('/companies/$companyId/accounts/${widget.accountId}/transactions');
      _transactions = txRes.data?['items'] ?? txRes.data?['data'] ?? [];
    } catch (_) {}
    if (mounted) setState(() => _loading = false);
  }

  String _typeLabel(String? t) => {'CUSTOMER':'Müşteri','SUPPLIER':'Tedarikçi','PERSONNEL':'Personel','PARTNER':'Ortak','OTHER':'Diğer'}[t] ?? '';
  
  String _paymentLabel(String? method, String? type) {
    if (method == null) return '';
    final labels = {
      'CASH': type == 'COLLECTION' ? 'Nakit Tahsilat' : type == 'PAYMENT' ? 'Nakit Ödeme' : 'Nakit',
      'BANK_TRANSFER': type == 'COLLECTION' ? 'Havale / Eft Geldi' : 'Havale / Eft Gönderildi',
      'CREDIT_CARD': type == 'PAYMENT' ? 'K.Kartı ile Ödeme Yapıldı' : 'Kredi Kartı',
      'CHEQUE': 'Çek Tahsilat',
      'PROMISSORY_NOTE': 'Senet',
    };
    return labels[method] ?? method;
  }

  String _txDescription(Map<String, dynamic> tx) {
    final type = tx['type'] as String?;
    final desc = tx['description'] as String?;
    if (desc != null && desc.isNotEmpty) return desc;
    return {'SALE':'Yapılan Satış','COLLECTION':'Tahsilat','PURCHASE':'Alınan Ürünler','PAYMENT':'Ödeme Yapıldı','SALARY':'Maaş Ödemesi','ADVANCE':'Avans','OFFSET':'Mahsup','CORRECTION':'Düzeltme'}[type] ?? type ?? '';
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) return Scaffold(backgroundColor: AppColors.backgroundDark, body: const Center(child: CircularProgressIndicator(color: AppColors.primary)));
    
    final balance = (_account?['current_balance'] ?? _account?['opening_balance'] ?? 0) as int;
    final balColor = balance > 0 ? AppColors.debit : balance < 0 ? AppColors.credit : AppColors.textSecondaryDark;

    return Scaffold(
      backgroundColor: AppColors.backgroundDark,
      appBar: AppBar(
        title: Text(_account?['title'] ?? '', overflow: TextOverflow.ellipsis),
        actions: [
          IconButton(icon: const Icon(Icons.more_vert), onPressed: () => _showOptions()),
        ],
      ),
      body: Column(children: [
        // Header - OkLif stili
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          color: AppColors.surfaceDark,
          child: Column(children: [
            Row(children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(color: AppColors.primary.withOpacity(0.2), borderRadius: BorderRadius.circular(4)),
                child: Text(_typeLabel(_account?['account_type']), style: const TextStyle(fontSize: 11, color: AppColors.primary)),
              ),
              const Spacer(),
              Text(MoneyUtil.format(balance), style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: balColor)),
            ]),
            const SizedBox(height: 8),
            // Tab bar - OkLif stili (ⓘ, takvim, not, paylaş)
            TabBar(controller: _tabCtrl, indicatorColor: AppColors.primary, labelColor: AppColors.primary, unselectedLabelColor: AppColors.textSecondaryDark, tabs: const [
              Tab(icon: Icon(Icons.info_outline, size: 20)),
              Tab(icon: Icon(Icons.calendar_today, size: 20)),
              Tab(icon: Icon(Icons.note, size: 20)),
              Tab(icon: Icon(Icons.share, size: 20)),
            ]),
          ]),
        ),
        // Tab content
        Expanded(
          child: TabBarView(controller: _tabCtrl, children: [
            // Tab 1: İşlem listesi
            _buildTransactionsList(),
            // Tab 2: Bilgiler
            _buildInfoTab(),
            // Tab 3: Notlar
            _buildNotesTab(),
            // Tab 4: Paylaşım
            _buildShareTab(),
          ]),
        ),
      ]),
      // Alt bar - OkLif stili (geri, +, telefon)
      bottomNavigationBar: Container(
        height: 60, color: AppColors.surfaceDark,
        child: Row(mainAxisAlignment: MainAxisAlignment.spaceEvenly, children: [
          IconButton(icon: const Icon(Icons.arrow_back, color: Colors.white), onPressed: () => context.pop()),
          FloatingActionButton(
            mini: false, backgroundColor: AppColors.fab,
            onPressed: () => _showAddTransaction(),
            child: const Icon(Icons.add, size: 28),
          ),
          IconButton(icon: const Icon(Icons.phone, color: AppColors.success), onPressed: () {}),
        ]),
      ),
    );
  }

  Widget _buildTransactionsList() {
    if (_transactions.isEmpty) {
      return const Center(child: Text('Henüz işlem yok', style: TextStyle(color: AppColors.textSecondaryDark)));
    }
    return ListView.builder(
      padding: const EdgeInsets.only(top: 8),
      itemCount: _transactions.length,
      itemBuilder: (ctx, i) {
        final tx = _transactions[i] as Map<String, dynamic>;
        final date = DateTime.tryParse(tx['date'] ?? '') ?? DateTime.now();
        final amount = (tx['amount'] ?? 0) as int;
        final type = tx['type'] as String?;
        final isDebit = type == 'SALE' || type == 'PURCHASE';
        final color = isDebit ? AppColors.debit : AppColors.credit;
        final sign = isDebit ? '' : '-';
        final runBal = tx['running_balance'] as int?;

        return TransactionCard(
          day: date.day,
          monthShort: '${_turkishMonths[date.month - 1]} ${date.year % 100}',
          description: _txDescription(tx),
          paymentMethodLabel: _paymentLabel(tx['payment_method'], type),
          amountText: '$sign${MoneyUtil.format(amount)}',
          amountColor: color,
          runningBalanceText: runBal != null ? MoneyUtil.format(runBal) : null,
          onTap: () {},
        );
      },
    );
  }

  Widget _buildInfoTab() {
    final a = _account ?? {};
    return SingleChildScrollView(padding: const EdgeInsets.all(16), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      _infoRow('Ünvan', a['title']),
      _infoRow('Kod', a['code']),
      _infoRow('Tür', _typeLabel(a['account_type'])),
      _infoRow('Yetkili', a['authorized_person']),
      _infoRow('Telefon', (a['phones'] is List) ? (a['phones'] as List).join(', ') : a['phones']?.toString()),
      _infoRow('E-posta', a['email']),
      _infoRow('Adres', a['address']),
      _infoRow('Vergi Dairesi', a['tax_office']),
      _infoRow('Vergi No', a['tax_number']),
      _infoRow('Risk Limiti', a['risk_limit'] != null ? MoneyUtil.format(a['risk_limit']) : null),
    ]));
  }

  Widget _infoRow(String label, String? value) {
    if (value == null || value.isEmpty) return const SizedBox.shrink();
    return Padding(padding: const EdgeInsets.only(bottom: 12), child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
      SizedBox(width: 120, child: Text(label, style: const TextStyle(color: AppColors.textSecondaryDark, fontSize: 13))),
      Expanded(child: Text(value, style: const TextStyle(color: Colors.white, fontSize: 14))),
    ]));
  }

  Widget _buildNotesTab() => Center(child: Text(_account?['notes'] ?? 'Not yok', style: const TextStyle(color: AppColors.textSecondaryDark)));
  Widget _buildShareTab() => Center(child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
    ElevatedButton.icon(onPressed: () {}, icon: const Icon(Icons.picture_as_pdf), label: const Text('PDF Ekstre')),
    const SizedBox(height: 12),
    ElevatedButton.icon(onPressed: () {}, icon: const Icon(Icons.table_chart), label: const Text('Excel Ekstre')),
    const SizedBox(height: 12),
    ElevatedButton.icon(onPressed: () {}, icon: const Icon(Icons.message), label: const Text('WhatsApp Gönder'), style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF25D366))),
  ]));

  void _showOptions() {}
  void _showAddTransaction() {
    showModalBottomSheet(context: context, backgroundColor: AppColors.surfaceDark,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (ctx) => Padding(padding: const EdgeInsets.all(24), child: Column(mainAxisSize: MainAxisSize.min, children: [
        const Text('İşlem Ekle', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white)),
        const SizedBox(height: 16),
        ListTile(leading: const Icon(Icons.add_circle, color: AppColors.danger), title: const Text('Borç Ekle', style: TextStyle(color: Colors.white)),
          onTap: () { Navigator.pop(ctx); context.go('/transactions/new?accountId=${widget.accountId}&type=SALE'); }),
        ListTile(leading: const Icon(Icons.download, color: AppColors.success), title: const Text('Tahsilat Al', style: TextStyle(color: Colors.white)),
          onTap: () { Navigator.pop(ctx); context.go('/transactions/new?accountId=${widget.accountId}&type=COLLECTION'); }),
        ListTile(leading: const Icon(Icons.upload, color: AppColors.warning), title: const Text('Ödeme Yap', style: TextStyle(color: Colors.white)),
          onTap: () { Navigator.pop(ctx); context.go('/transactions/new?accountId=${widget.accountId}&type=PAYMENT'); }),
      ])));
  }
}

