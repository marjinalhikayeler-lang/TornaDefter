import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/api/api_client.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/utils/formatters.dart';

/// Taksit Takip Ekranı - Taksit planları ve detayları
class InstallmentsScreen extends ConsumerStatefulWidget {
  const InstallmentsScreen({super.key});

  @override
  ConsumerState<InstallmentsScreen> createState() => _InstallmentsScreenState();
}

class _InstallmentsScreenState extends ConsumerState<InstallmentsScreen> {
  List<dynamic> _plans = [];
  bool _loading = true;
  Map<String, dynamic>? _summary;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    try {
      final api = ref.read(apiClientProvider);
      final companyId = ''; // aktif şirket ID'si
      final plansRes = await api.get('/companies/$companyId/installments/plans');
      final summaryRes = await api.get('/companies/$companyId/installments/summary');
      setState(() {
        _plans = plansRes.data['data'] ?? plansRes.data ?? [];
        _summary = summaryRes.data;
        _loading = false;
      });
    } catch (e) {
      setState(() => _loading = false);
    }
  }

  void _showCreatePlan() {
    showModalBottomSheet(
      context: context,
      backgroundColor: AppColors.darkSurface,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (ctx) => _CreateInstallmentSheet(onCreated: () => _loadData()),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.darkBg,
      appBar: AppBar(
        title: const Text('Taksit Takibi'),
        backgroundColor: AppColors.darkSurface,
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _showCreatePlan,
        backgroundColor: AppColors.accentOrange,
        child: const Icon(Icons.add),
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : Column(
              children: [
                // Özet kartları
                if (_summary != null) _buildSummary(),
                // Plan listesi
                Expanded(
                  child: _plans.isEmpty
                      ? Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.calendar_month, size: 64, color: Colors.white.withOpacity(0.2)),
                              const SizedBox(height: 12),
                              const Text('Taksit planı yok', style: TextStyle(color: Colors.white54)),
                              const SizedBox(height: 16),
                              ElevatedButton.icon(
                                onPressed: _showCreatePlan,
                                icon: const Icon(Icons.add, size: 18),
                                label: const Text('Yeni Plan Oluştur'),
                                style: ElevatedButton.styleFrom(backgroundColor: AppColors.primary),
                              ),
                            ],
                          ),
                        )
                      : RefreshIndicator(
                          onRefresh: _loadData,
                          child: ListView.builder(
                            padding: const EdgeInsets.all(12),
                            itemCount: _plans.length,
                            itemBuilder: (context, i) => _PlanCard(plan: _plans[i], onTap: () => _openPlanDetail(_plans[i])),
                          ),
                        ),
                ),
              ],
            ),
    );
  }

  Widget _buildSummary() {
    return Container(
      padding: const EdgeInsets.all(16),
      child: Row(
        children: [
          _SummaryItem(
            label: 'Toplam',
            value: MoneyUtil.format(_summary!['totalAmount'] ?? 0),
            color: Colors.white,
          ),
          _SummaryItem(
            label: 'Ödenen',
            value: MoneyUtil.format(_summary!['paidAmount'] ?? 0),
            color: AppColors.creditGreen,
          ),
          _SummaryItem(
            label: 'Kalan',
            value: MoneyUtil.format(_summary!['remainingAmount'] ?? 0),
            color: AppColors.debitRed,
          ),
          _SummaryItem(
            label: 'Gecikmiş',
            value: '${_summary!['overdueCount'] ?? 0}',
            color: Colors.orange,
          ),
        ],
      ),
    );
  }

  void _openPlanDetail(dynamic plan) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => _InstallmentDetailScreen(plan: plan)),
    );
  }
}

class _SummaryItem extends StatelessWidget {
  final String label;
  final String value;
  final Color color;
  const _SummaryItem({required this.label, required this.value, required this.color});

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 4),
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: AppColors.darkSurface,
          borderRadius: BorderRadius.circular(8),
        ),
        child: Column(
          children: [
            Text(label, style: const TextStyle(color: Colors.white54, fontSize: 11)),
            const SizedBox(height: 4),
            Text(value, style: TextStyle(color: color, fontWeight: FontWeight.bold, fontSize: 13)),
          ],
        ),
      ),
    );
  }
}

class _PlanCard extends StatelessWidget {
  final dynamic plan;
  final VoidCallback onTap;
  const _PlanCard({required this.plan, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final installments = plan['installments'] as List? ?? [];
    final paidCount = installments.where((i) => i['status'] == 'PAID').length;
    final totalCount = plan['installment_count'] ?? installments.length;
    final progress = totalCount > 0 ? paidCount / totalCount : 0.0;
    final overdueCount = installments.where((i) =>
        i['status'] == 'PENDING' && DateTime.tryParse(i['due_date'] ?? '')?.isBefore(DateTime.now()) == true).length;

    return Card(
      color: AppColors.darkSurface,
      margin: const EdgeInsets.only(bottom: 10),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      plan['title'] ?? '',
                      style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 15),
                    ),
                  ),
                  if (overdueCount > 0)
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                      decoration: BoxDecoration(
                        color: Colors.red.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text('$overdueCount gecikmiş', style: const TextStyle(color: Colors.red, fontSize: 11)),
                    ),
                ],
              ),
              const SizedBox(height: 4),
              Text(
                plan['account']?['title'] ?? '',
                style: const TextStyle(color: Colors.white54, fontSize: 13),
              ),
              const SizedBox(height: 10),
              Row(
                children: [
                  Text(
                    MoneyUtil.format(plan['total_amount'] ?? 0),
                    style: const TextStyle(color: AppColors.primary, fontWeight: FontWeight.bold),
                  ),
                  const Spacer(),
                  Text(
                    '$paidCount / $totalCount taksit',
                    style: const TextStyle(color: Colors.white54, fontSize: 12),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              ClipRRect(
                borderRadius: BorderRadius.circular(4),
                child: LinearProgressIndicator(
                  value: progress,
                  backgroundColor: Colors.white10,
                  valueColor: AlwaysStoppedAnimation(
                    progress >= 1.0 ? AppColors.creditGreen : AppColors.primary,
                  ),
                  minHeight: 6,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ============ TAKSİT DETAY EKRANI ============
class _InstallmentDetailScreen extends StatelessWidget {
  final dynamic plan;
  const _InstallmentDetailScreen({required this.plan});

  @override
  Widget build(BuildContext context) {
    final installments = (plan['installments'] as List? ?? []);

    return Scaffold(
      backgroundColor: AppColors.darkBg,
      appBar: AppBar(
        title: Text(plan['title'] ?? 'Taksit Detay'),
        backgroundColor: AppColors.darkSurface,
      ),
      body: ListView.builder(
        padding: const EdgeInsets.all(12),
        itemCount: installments.length,
        itemBuilder: (context, i) {
          final inst = installments[i];
          final status = inst['status'] ?? 'PENDING';
          final dueDate = DateTime.tryParse(inst['due_date'] ?? '');
          final isOverdue = status == 'PENDING' && dueDate != null && dueDate.isBefore(DateTime.now());

          Color statusColor;
          String statusLabel;
          IconData statusIcon;
          switch (status) {
            case 'PAID':
              statusColor = AppColors.creditGreen;
              statusLabel = 'Ödendi';
              statusIcon = Icons.check_circle;
              break;
            case 'OVERDUE':
              statusColor = Colors.red;
              statusLabel = 'Gecikmiş';
              statusIcon = Icons.warning;
              break;
            case 'CANCELLED':
              statusColor = Colors.grey;
              statusLabel = 'İptal';
              statusIcon = Icons.cancel;
              break;
            default:
              statusColor = isOverdue ? Colors.orange : Colors.white54;
              statusLabel = isOverdue ? 'Gecikmiş' : 'Bekliyor';
              statusIcon = isOverdue ? Icons.access_time : Icons.schedule;
          }

          return Card(
            color: AppColors.darkSurface,
            margin: const EdgeInsets.only(bottom: 8),
            child: ListTile(
              leading: CircleAvatar(
                backgroundColor: statusColor.withOpacity(0.15),
                child: Text(
                  '${inst['installment_number'] ?? i + 1}',
                  style: TextStyle(color: statusColor, fontWeight: FontWeight.bold),
                ),
              ),
              title: Text(
                MoneyUtil.format(inst['amount'] ?? 0),
                style: TextStyle(
                  color: status == 'PAID' ? AppColors.creditGreen : Colors.white,
                  fontWeight: FontWeight.bold,
                ),
              ),
              subtitle: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Vade: ${dueDate != null ? DateUtil.format(dueDate) : "-"}',
                    style: TextStyle(color: isOverdue ? Colors.orange : Colors.white54, fontSize: 12),
                  ),
                  if (isOverdue && dueDate != null)
                    Text(
                      DateUtil.overdueText(dueDate),
                      style: const TextStyle(color: Colors.red, fontSize: 11, fontWeight: FontWeight.w600),
                    ),
                  if (status == 'PAID' && inst['paid_date'] != null)
                    Text(
                      'Ödeme: ${DateUtil.format(DateTime.parse(inst['paid_date']))}',
                      style: const TextStyle(color: AppColors.creditGreen, fontSize: 12),
                    ),
                ],
              ),
              trailing: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(statusIcon, color: statusColor, size: 18),
                  const SizedBox(width: 4),
                  Text(statusLabel, style: TextStyle(color: statusColor, fontSize: 11)),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}

// ============ YENİ TAKSİT PLANI OLUŞTURMA ============
class _CreateInstallmentSheet extends StatefulWidget {
  final VoidCallback onCreated;
  const _CreateInstallmentSheet({required this.onCreated});

  @override
  State<_CreateInstallmentSheet> createState() => _CreateInstallmentSheetState();
}

class _CreateInstallmentSheetState extends State<_CreateInstallmentSheet> {
  final _titleController = TextEditingController();
  final _amountController = TextEditingController();
  final _countController = TextEditingController(text: '3');
  DateTime _startDate = DateTime.now();
  String _frequency = 'MONTHLY';
  bool _loading = false;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(
        left: 20, right: 20, top: 20,
        bottom: MediaQuery.of(context).viewInsets.bottom + 20,
      ),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Center(
              child: Text('Yeni Taksit Planı', style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
            ),
            const SizedBox(height: 20),
            _buildField('Plan Adı', _titleController, 'örn: Laptop Taksiti'),
            const SizedBox(height: 12),
            _buildField('Toplam Tutar (₺)', _amountController, '0.00', TextInputType.number),
            const SizedBox(height: 12),
            _buildField('Taksit Sayısı', _countController, '3', TextInputType.number),
            const SizedBox(height: 12),
            // Tekrarlama sıklığı
            const Text('Sıklık', style: TextStyle(color: Colors.white54, fontSize: 13)),
            const SizedBox(height: 6),
            Row(
              children: [
                _freqChip('Haftalık', 'WEEKLY'),
                const SizedBox(width: 8),
                _freqChip('Aylık', 'MONTHLY'),
                const SizedBox(width: 8),
                _freqChip('Yıllık', 'YEARLY'),
              ],
            ),
            const SizedBox(height: 12),
            // Başlangıç tarihi
            ListTile(
              contentPadding: EdgeInsets.zero,
              title: const Text('Başlangıç Tarihi', style: TextStyle(color: Colors.white54, fontSize: 13)),
              subtitle: Text(DateUtil.format(_startDate), style: const TextStyle(color: Colors.white)),
              trailing: const Icon(Icons.calendar_today, color: AppColors.primary),
              onTap: () async {
                final d = await showDatePicker(
                  context: context,
                  initialDate: _startDate,
                  firstDate: DateTime(2020),
                  lastDate: DateTime(2035),
                  locale: const Locale('tr'),
                );
                if (d != null) setState(() => _startDate = d);
              },
            ),
            const SizedBox(height: 20),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _loading ? null : _create,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                ),
                child: _loading
                    ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                    : const Text('Oluştur', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildField(String label, TextEditingController ctrl, String hint, [TextInputType? type]) {
    return TextField(
      controller: ctrl,
      keyboardType: type,
      style: const TextStyle(color: Colors.white),
      decoration: InputDecoration(
        labelText: label,
        hintText: hint,
        labelStyle: const TextStyle(color: Colors.white54),
        hintStyle: const TextStyle(color: Colors.white24),
        enabledBorder: const OutlineInputBorder(borderSide: BorderSide(color: Colors.white24)),
        focusedBorder: const OutlineInputBorder(borderSide: BorderSide(color: AppColors.primary)),
      ),
    );
  }

  Widget _freqChip(String label, String value) {
    final selected = _frequency == value;
    return ChoiceChip(
      label: Text(label),
      selected: selected,
      onSelected: (_) => setState(() => _frequency = value),
      selectedColor: AppColors.primary,
      labelStyle: TextStyle(color: selected ? Colors.white : Colors.white54, fontSize: 12),
      backgroundColor: AppColors.darkBg,
    );
  }

  Future<void> _create() async {
    if (_titleController.text.isEmpty || _amountController.text.isEmpty) return;
    setState(() => _loading = true);
    // API çağrısı yapılacak
    widget.onCreated();
    if (mounted) Navigator.pop(context);
  }
}

