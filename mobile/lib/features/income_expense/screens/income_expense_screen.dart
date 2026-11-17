import 'package:flutter/material.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/api/api_client.dart';
import '../../../core/utils/formatters.dart';

class IncomeExpenseScreen extends StatefulWidget {
  const IncomeExpenseScreen({super.key});
  @override
  State<IncomeExpenseScreen> createState() => _IncomeExpenseScreenState();
}

class _IncomeExpenseScreenState extends State<IncomeExpenseScreen> with SingleTickerProviderStateMixin {
  late TabController _tabCtrl;
  List<dynamic> _items = [];
  bool _loading = true;
  int _totalIncome = 0;
  int _totalExpense = 0;

  @override
  void initState() {
    super.initState();
    _tabCtrl = TabController(length: 3, vsync: this);
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() => _loading = true);
    try {
      final cid = await ApiClient().ensureActiveCompany();
      if (cid != null) {
        final res = await ApiClient().dio.get('/companies/$cid/income-expenses');
        final data = res.data is List ? res.data : (res.data?['data'] ?? res.data?['items'] ?? []);
        _items = data as List;
        _totalIncome = _items.where((e) => e['type'] == 'INCOME').fold(0, (sum, e) => sum + ((e['amount'] ?? 0) as int));
        _totalExpense = _items.where((e) => e['type'] == 'EXPENSE').fold(0, (sum, e) => sum + ((e['amount'] ?? 0) as int));
      }
    } catch (_) {}
    if (mounted) setState(() => _loading = false);
  }

  void _showAddDialog([String initialType = 'INCOME']) {
    String type = initialType;
    final amountCtrl = TextEditingController();
    final descCtrl = TextEditingController();
    final catCtrl = TextEditingController();
    DateTime date = DateTime.now();

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
                  Text(type == 'INCOME' ? 'Yeni Gelir Ekle' : 'Yeni Gider Ekle',
                    style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white)),
                  IconButton(icon: const Icon(Icons.close, color: AppColors.textSecondaryDark), onPressed: () => Navigator.pop(ctx)),
                ],
              ),
              const SizedBox(height: 12),
              // Tür seçimi
              Row(
                children: [
                  Expanded(
                    child: ChoiceChip(
                      label: const Center(child: Text('Gelir')),
                      selected: type == 'INCOME',
                      selectedColor: AppColors.success,
                      backgroundColor: AppColors.cardDark,
                      labelStyle: TextStyle(color: type == 'INCOME' ? Colors.white : AppColors.textSecondaryDark),
                      onSelected: (_) => setModalState(() => type = 'INCOME'),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ChoiceChip(
                      label: const Center(child: Text('Gider')),
                      selected: type == 'EXPENSE',
                      selectedColor: AppColors.danger,
                      backgroundColor: AppColors.cardDark,
                      labelStyle: TextStyle(color: type == 'EXPENSE' ? Colors.white : AppColors.textSecondaryDark),
                      onSelected: (_) => setModalState(() => type = 'EXPENSE'),
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
                controller: descCtrl,
                style: const TextStyle(color: Colors.white),
                decoration: const InputDecoration(labelText: 'Açıklama', prefixIcon: Icon(Icons.notes, color: AppColors.textSecondaryDark)),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: catCtrl,
                style: const TextStyle(color: Colors.white),
                decoration: const InputDecoration(labelText: 'Kategori (Örn: Kira, Fatura, Maaş)', prefixIcon: Icon(Icons.category, color: AppColors.textSecondaryDark)),
              ),
              const SizedBox(height: 20),
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
                      await ApiClient().dio.post('/companies/$cid/income-expenses', data: {
                        'type': type,
                        'amount': MoneyUtil.toKurus(amountNum),
                        'description': descCtrl.text.trim().isEmpty ? (type == 'INCOME' ? 'Gelir' : 'Gider') : descCtrl.text.trim(),
                        'category': catCtrl.text.trim().isEmpty ? 'Genel' : catCtrl.text.trim(),
                        'date': date.toIso8601String().split('T')[0],
                      });
                      if (ctx.mounted) Navigator.pop(ctx);
                      _loadData();
                    } catch (e) {
                      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Hata: $e')));
                    }
                  },
                  style: ElevatedButton.styleFrom(backgroundColor: type == 'INCOME' ? AppColors.success : AppColors.danger),
                  child: const Text('Kaydet', style: TextStyle(color: Colors.white, fontSize: 16)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final net = _totalIncome - _totalExpense;
    return Scaffold(
      backgroundColor: AppColors.backgroundDark,
      appBar: AppBar(
        title: const Text('Gelir & Gider Takibi'),
        bottom: TabBar(
          controller: _tabCtrl,
          indicatorColor: AppColors.primary,
          labelColor: AppColors.primary,
          unselectedLabelColor: AppColors.textSecondaryDark,
          tabs: const [Tab(text: 'Tümü'), Tab(text: 'Gelirler'), Tab(text: 'Giderler')],
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showAddDialog(),
        backgroundColor: AppColors.primary,
        icon: const Icon(Icons.add),
        label: const Text('Yeni Kayıt'),
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator(color: AppColors.primary))
          : Column(
              children: [
                // Özet kartı
                Container(
                  margin: const EdgeInsets.all(16),
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(color: AppColors.surfaceDark, borderRadius: BorderRadius.circular(14)),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    children: [
                      _summaryCol('Toplam Gelir', MoneyUtil.format(_totalIncome), AppColors.success),
                      Container(width: 1, height: 40, color: AppColors.cardDark),
                      _summaryCol('Toplam Gider', MoneyUtil.format(_totalExpense), AppColors.danger),
                      Container(width: 1, height: 40, color: AppColors.cardDark),
                      _summaryCol('Net Kalan', MoneyUtil.format(net), net >= 0 ? AppColors.success : AppColors.danger),
                    ],
                  ),
                ),
                Expanded(
                  child: TabBarView(
                    controller: _tabCtrl,
                    children: [
                      _buildList(_items),
                      _buildList(_items.where((e) => e['type'] == 'INCOME').toList()),
                      _buildList(_items.where((e) => e['type'] == 'EXPENSE').toList()),
                    ],
                  ),
                ),
              ],
            ),
    );
  }

  Widget _summaryCol(String label, String value, Color color) {
    return Column(
      children: [
        Text(label, style: const TextStyle(fontSize: 11, color: AppColors.textSecondaryDark)),
        const SizedBox(height: 4),
        Text(value, style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: color)),
      ],
    );
  }

  Widget _buildList(List<dynamic> list) {
    if (list.isEmpty) {
      return RefreshIndicator(
        onRefresh: _loadData,
        child: const Center(child: Text('Kayıt bulunamadı', style: TextStyle(color: AppColors.textSecondaryDark))),
      );
    }
    return RefreshIndicator(
      onRefresh: _loadData,
      child: ListView.builder(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        itemCount: list.length,
        itemBuilder: (ctx, i) {
          final item = list[i];
          final isIncome = item['type'] == 'INCOME';
          final amount = (item['amount'] ?? 0) as int;
          return Container(
            margin: const EdgeInsets.only(bottom: 8),
            decoration: BoxDecoration(color: AppColors.surfaceDark, borderRadius: BorderRadius.circular(12)),
            child: ListTile(
              leading: CircleAvatar(
                backgroundColor: (isIncome ? AppColors.success : AppColors.danger).withOpacity(0.15),
                child: Icon(isIncome ? Icons.arrow_downward : Icons.arrow_upward, color: isIncome ? AppColors.success : AppColors.danger),
              ),
              title: Text(item['description'] ?? (isIncome ? 'Gelir' : 'Gider'), style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w600)),
              subtitle: Text('${item['category'] ?? 'Genel'} • ${item['date'] ?? ''}', style: const TextStyle(color: AppColors.textSecondaryDark, fontSize: 12)),
              trailing: Text(
                '${isIncome ? '+' : '-'}${MoneyUtil.format(amount)}',
                style: TextStyle(fontWeight: FontWeight.bold, color: isIncome ? AppColors.success : AppColors.danger, fontSize: 15),
              ),
            ),
          );
        },
      ),
    );
  }
}

