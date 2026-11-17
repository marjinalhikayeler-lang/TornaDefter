import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/utils/formatters.dart';
import '../../../core/api/api_client.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});
  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  Map<String, dynamic>? _stats;
  List<dynamic> _upcomingCheques = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() => _loading = true);
    try {
      final companyId = await ApiClient().ensureActiveCompany();
      if (companyId != null) {
        // 1. Birincil: Backend dashboard summary endpoint'i dene
        try {
          final res = await ApiClient().dio.get('/companies/$companyId/reports/dashboard-summary');
          if (res.data != null && res.data is Map) {
            final data = res.data as Map<String, dynamic>;
            setState(() {
              _stats = data;
              _upcomingCheques = (data['upcoming_cheques'] as List?) ?? [];
              _loading = false;
            });
            return;
          }
        } catch (_) {}

        // 2. Yedek: Doğrudan hesapla (Fallback)
        int receivables = 0;
        int payables = 0;
        int cashTotal = 0;
        int bankTotal = 0;
        int incomeTotal = 0;
        int expenseTotal = 0;
        List<dynamic> cheques = [];

        try {
          final accRes = await ApiClient().dio.get('/companies/$companyId/accounts');
          final accList = (accRes.data is List ? accRes.data : (accRes.data?['data'] ?? [])) as List;
          for (final a in accList) {
            final bal = (a['current_balance'] ?? a['opening_balance'] ?? 0) as int;
            if (bal > 0) receivables += bal;
            else if (bal < 0) payables += bal.abs();
          }
        } catch (_) {}

        try {
          final cashRes = await ApiClient().dio.get('/companies/$companyId/cash-accounts');
          final cashList = (cashRes.data is List ? cashRes.data : (cashRes.data?['data'] ?? [])) as List;
          for (final c in cashList) {
            cashTotal += (c['current_balance'] ?? 0) as int;
          }
        } catch (_) {}

        try {
          final bankRes = await ApiClient().dio.get('/companies/$companyId/bank-accounts');
          final bankList = (bankRes.data is List ? bankRes.data : (bankRes.data?['data'] ?? [])) as List;
          for (final b in bankList) {
            bankTotal += (b['current_balance'] ?? 0) as int;
          }
        } catch (_) {}

        try {
          final ieRes = await ApiClient().dio.get('/companies/$companyId/income-expenses');
          final ieList = (ieRes.data is List ? ieRes.data : (ieRes.data?['data'] ?? [])) as List;
          for (final item in ieList) {
            final amount = (item['amount'] ?? 0) as int;
            if (item['type'] == 'INCOME') {
              incomeTotal += amount;
            } else if (item['type'] == 'EXPENSE') {
              expenseTotal += amount;
            }
          }
        } catch (_) {}

        try {
          final chkRes = await ApiClient().dio.get('/companies/$companyId/cheques-notes');
          final chkList = (chkRes.data is List ? chkRes.data : (chkRes.data?['data'] ?? [])) as List;
          cheques = chkList.take(5).toList();
        } catch (_) {}

        if (mounted) {
          setState(() {
            _stats = {
              'total_receivables': receivables,
              'total_payables': payables,
              'net_balance': receivables - payables,
              'total_cash': cashTotal,
              'total_bank': bankTotal,
              'total_cash_bank': cashTotal + bankTotal,
              'total_income': incomeTotal,
              'total_expense': expenseTotal,
              'net_income': incomeTotal - expenseTotal,
            };
            _upcomingCheques = cheques;
          });
        }
      }
    } catch (_) {
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final int receivables = _stats?['total_receivables'] ?? 0;
    final int payables = _stats?['total_payables'] ?? 0;
    final int netBalance = _stats?['net_balance'] ?? (receivables - payables);
    final int cashBank = _stats?['total_cash_bank'] ?? 0;
    final int totalIncome = _stats?['total_income'] ?? 0;
    final int totalExpense = _stats?['total_expense'] ?? 0;
    final int netIncome = _stats?['net_income'] ?? (totalIncome - totalExpense);

    return Scaffold(
      backgroundColor: AppColors.backgroundDark,
      appBar: AppBar(
        title: const Text('TornaDefter'),
        actions: [
          IconButton(
            icon: const Icon(Icons.notifications_outlined),
            tooltip: 'Bildirimler',
            onPressed: () => context.push('/notifications'),
          ),
          IconButton(
            icon: const Icon(Icons.settings),
            tooltip: 'Ayarlar',
            onPressed: () => context.push('/more'),
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: _loadData,
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // 1. Cari ve Kasa Durumu
              const Text('Cari ve Kasa Durumu', style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: Colors.white70)),
              const SizedBox(height: 10),
              Row(children: [
                _summaryCard('Toplam Alacak', MoneyUtil.format(receivables), AppColors.success, Icons.arrow_downward),
                const SizedBox(width: 12),
                _summaryCard('Toplam Borç', MoneyUtil.format(payables), AppColors.danger, Icons.arrow_upward),
              ]),
              const SizedBox(height: 12),
              Row(children: [
                _summaryCard('Net Bakiye', MoneyUtil.format(netBalance), netBalance >= 0 ? AppColors.primary : AppColors.danger, Icons.account_balance),
                const SizedBox(width: 12),
                _summaryCard('Kasa + Banka', MoneyUtil.format(cashBank), AppColors.warning, Icons.account_balance_wallet),
              ]),

              const SizedBox(height: 20),

              // 2. Net Gelir & Gider Durumu
              const Text('Gelir & Gider Durumu (Kâr / Zarar)', style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: Colors.white70)),
              const SizedBox(height: 10),
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: AppColors.surfaceDark,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.white.withOpacity(0.05)),
                ),
                child: Column(
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        _miniStat('Toplam Gelir', MoneyUtil.format(totalIncome), AppColors.success, Icons.trending_up),
                        Container(width: 1, height: 40, color: Colors.white12),
                        _miniStat('Toplam Gider', MoneyUtil.format(totalExpense), AppColors.danger, Icons.trending_down),
                        Container(width: 1, height: 40, color: Colors.white12),
                        _miniStat('Net Gelir', MoneyUtil.format(netIncome), netIncome >= 0 ? AppColors.success : AppColors.danger, Icons.pie_chart),
                      ],
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 24),

              // 3. Hızlı Erişim
              const Text('Hızlı Erişim', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white)),
              const SizedBox(height: 12),
              GridView.count(
                crossAxisCount: 4,
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                mainAxisSpacing: 12,
                crossAxisSpacing: 12,
                children: [
                  _quickAction(Icons.people, 'Cariler', AppColors.primary, () => context.push('/accounts')),
                  _quickAction(Icons.category, 'Gelir/Gider', Colors.purple, () => context.push('/income-expenses')),
                  _quickAction(Icons.account_balance, 'Kasa', AppColors.warning, () => context.push('/cash')),
                  _quickAction(Icons.description, 'Çek/Senet', AppColors.info, () => context.push('/cheques')),
                  _quickAction(Icons.bar_chart, 'Raporlar', AppColors.accent, () => context.push('/reports')),
                  _quickAction(Icons.view_timeline, 'Taksitler', Colors.orange, () => context.push('/installments')),
                  _quickAction(Icons.backup, 'Yedekleme', Colors.teal, () => context.push('/backup')),
                  _quickAction(Icons.help_outline, 'Destek', Colors.pink, () => context.push('/support')),
                ],
              ),

              const SizedBox(height: 24),

              // 4. Vadesi Yaklaşanlar
              const Text('Vadesi Yaklaşan Çek & Senetler', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white)),
              const SizedBox(height: 12),
              if (_upcomingCheques.isEmpty)
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(color: AppColors.surfaceDark, borderRadius: BorderRadius.circular(12)),
                  child: const Center(
                    child: Text('Vadesi yaklaşan işlem yok', style: TextStyle(color: AppColors.textSecondaryDark)),
                  ),
                )
              else
                Column(
                  children: _upcomingCheques.map<Widget>((chk) {
                    final amount = (chk['amount'] ?? 0) as int;
                    final drawer = chk['drawer'] ?? chk['bank_name'] ?? 'Çek/Senet';
                    final dueDateStr = chk['due_date'] ?? '';
                    final isReceived = chk['direction'] == 'RECEIVED';
                    return Container(
                      margin: const EdgeInsets.only(bottom: 8),
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                      decoration: BoxDecoration(
                        color: AppColors.surfaceDark,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Row(
                        children: [
                          Icon(
                            isReceived ? Icons.arrow_circle_down : Icons.arrow_circle_up,
                            color: isReceived ? AppColors.success : AppColors.danger,
                            size: 28,
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(drawer, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14)),
                                const SizedBox(height: 2),
                                Text(
                                  'Vade: ${dueDateStr.length >= 10 ? dueDateStr.substring(0, 10) : dueDateStr}',
                                  style: const TextStyle(color: AppColors.textSecondaryDark, fontSize: 11),
                                ),
                              ],
                            ),
                          ),
                          Text(
                            MoneyUtil.format(amount),
                            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: isReceived ? AppColors.success : AppColors.danger),
                          ),
                        ],
                      ),
                    );
                  }).toList(),
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _miniStat(String label, String value, Color color, IconData icon) {
    return Expanded(
      child: Column(
        children: [
          Icon(icon, color: color, size: 18),
          const SizedBox(height: 4),
          Text(value, style: TextStyle(color: color, fontWeight: FontWeight.bold, fontSize: 14), textAlign: TextAlign.center, overflow: TextOverflow.ellipsis),
          const SizedBox(height: 2),
          Text(label, style: const TextStyle(color: AppColors.textSecondaryDark, fontSize: 10), textAlign: TextAlign.center),
        ],
      ),
    );
  }

  Widget _summaryCard(String label, String value, Color color, IconData icon) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(color: AppColors.surfaceDark, borderRadius: BorderRadius.circular(12)),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Row(children: [
            Icon(icon, color: color, size: 20),
            const Spacer(),
          ]),
          const SizedBox(height: 8),
          Text(value, style: TextStyle(fontSize: 17, fontWeight: FontWeight.bold, color: color), overflow: TextOverflow.ellipsis),
          const SizedBox(height: 4),
          Text(label, style: const TextStyle(fontSize: 11, color: AppColors.textSecondaryDark)),
        ]),
      ),
    );
  }

  Widget _quickAction(IconData icon, String label, Color color, VoidCallback onTap) {
    return InkWell(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(color: AppColors.surfaceDark, borderRadius: BorderRadius.circular(12)),
        child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
          Container(
            width: 40, height: 40,
            decoration: BoxDecoration(color: color.withOpacity(0.15), borderRadius: BorderRadius.circular(10)),
            child: Icon(icon, color: color, size: 22),
          ),
          const SizedBox(height: 6),
          Text(label, style: const TextStyle(fontSize: 10, color: AppColors.textSecondaryDark), textAlign: TextAlign.center),
        ]),
      ),
    );
  }
}
