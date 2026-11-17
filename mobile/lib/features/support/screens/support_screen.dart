import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/api/api_client.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/utils/formatters.dart';

/// Destek Talep Ekranı - Uygulama içi destek ticket oluşturma
class SupportScreen extends ConsumerStatefulWidget {
  const SupportScreen({super.key});

  @override
  ConsumerState<SupportScreen> createState() => _SupportScreenState();
}

class _SupportScreenState extends ConsumerState<SupportScreen> {
  List<dynamic> _tickets = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _loadTickets();
  }

  Future<void> _loadTickets() async {
    try {
      final api = ref.read(apiClientProvider);
      final res = await api.get('/support/tickets');
      final data = res.data is Map ? (res.data['items'] ?? res.data['data'] ?? []) : (res.data is List ? res.data : []);
      setState(() {
        _tickets = data as List;
        _loading = false;
      });
    } catch (e) {
      setState(() => _loading = false);
    }
  }

  void _createTicket() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppColors.darkSurface,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(16))),
      builder: (_) => _CreateTicketSheet(onCreated: _loadTickets),
    );
  }

  Color _statusColor(String status) {
    switch (status) {
      case 'OPEN': return Colors.orange;
      case 'IN_PROGRESS': return AppColors.primary;
      case 'RESOLVED': return AppColors.creditGreen;
      case 'CLOSED': return Colors.grey;
      default: return Colors.white54;
    }
  }

  String _statusLabel(String status) {
    switch (status) {
      case 'OPEN': return 'Açık';
      case 'IN_PROGRESS': return 'İşlemde';
      case 'RESOLVED': return 'Çözüldü';
      case 'CLOSED': return 'Kapatıldı';
      default: return status;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.darkBg,
      appBar: AppBar(
        title: const Text('Destek'),
        backgroundColor: AppColors.darkSurface,
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _createTicket,
        backgroundColor: AppColors.accentOrange,
        child: const Icon(Icons.add),
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _tickets.isEmpty
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.support_agent, size: 64, color: Colors.white.withOpacity(0.2)),
                      const SizedBox(height: 12),
                      const Text('Destek talebi yok', style: TextStyle(color: Colors.white54)),
                      const SizedBox(height: 16),
                      ElevatedButton.icon(
                        onPressed: _createTicket,
                        icon: const Icon(Icons.add, size: 18),
                        label: const Text('Yeni Talep Oluştur'),
                        style: ElevatedButton.styleFrom(backgroundColor: AppColors.primary),
                      ),
                    ],
                  ),
                )
              : RefreshIndicator(
                  onRefresh: _loadTickets,
                  child: ListView.builder(
                    padding: const EdgeInsets.all(12),
                    itemCount: _tickets.length,
                    itemBuilder: (context, i) {
                      final t = _tickets[i];
                      final status = t['status'] ?? 'OPEN';
                      return Card(
                        color: AppColors.darkSurface,
                        margin: const EdgeInsets.only(bottom: 8),
                        child: ListTile(
                          title: Text(t['subject'] ?? '', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w600)),
                          subtitle: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(t['message'] ?? '', style: const TextStyle(color: Colors.white54, fontSize: 12), maxLines: 2, overflow: TextOverflow.ellipsis),
                              const SizedBox(height: 6),
                              Row(
                                children: [
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                    decoration: BoxDecoration(
                                      color: _statusColor(status).withOpacity(0.2),
                                      borderRadius: BorderRadius.circular(4),
                                    ),
                                    child: Text(_statusLabel(status), style: TextStyle(color: _statusColor(status), fontSize: 11)),
                                  ),
                                  const Spacer(),
                                  Text(DateUtil.formatDateTime(t['created_at'] ?? ''), style: const TextStyle(color: Colors.white38, fontSize: 11)),
                                ],
                              ),
                            ],
                          ),
                          onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => _TicketDetailScreen(ticket: t))),
                        ),
                      );
                    },
                  ),
                ),
    );
  }
}

class _CreateTicketSheet extends StatefulWidget {
  final VoidCallback onCreated;
  const _CreateTicketSheet({required this.onCreated});

  @override
  State<_CreateTicketSheet> createState() => _CreateTicketSheetState();
}

class _CreateTicketSheetState extends State<_CreateTicketSheet> {
  final _subjectCtrl = TextEditingController();
  final _messageCtrl = TextEditingController();
  String _priority = 'MEDIUM';
  bool _loading = false;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(left: 20, right: 20, top: 20, bottom: MediaQuery.of(context).viewInsets.bottom + 20),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('Yeni Destek Talebi', style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 20),
            TextField(
              controller: _subjectCtrl,
              style: const TextStyle(color: Colors.white),
              decoration: const InputDecoration(
                labelText: 'Konu',
                labelStyle: TextStyle(color: Colors.white54),
                enabledBorder: OutlineInputBorder(borderSide: BorderSide(color: Colors.white24)),
                focusedBorder: OutlineInputBorder(borderSide: BorderSide(color: AppColors.primary)),
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _messageCtrl,
              maxLines: 5,
              style: const TextStyle(color: Colors.white),
              decoration: const InputDecoration(
                labelText: 'Mesajınız',
                alignLabelWithHint: true,
                labelStyle: TextStyle(color: Colors.white54),
                enabledBorder: OutlineInputBorder(borderSide: BorderSide(color: Colors.white24)),
                focusedBorder: OutlineInputBorder(borderSide: BorderSide(color: AppColors.primary)),
              ),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                const Text('Öncelik: ', style: TextStyle(color: Colors.white54)),
                ChoiceChip(label: const Text('Düşük'), selected: _priority == 'LOW', onSelected: (_) => setState(() => _priority = 'LOW'), selectedColor: Colors.green, backgroundColor: AppColors.darkBg, labelStyle: TextStyle(color: _priority == 'LOW' ? Colors.white : Colors.white54, fontSize: 12)),
                const SizedBox(width: 6),
                ChoiceChip(label: const Text('Orta'), selected: _priority == 'MEDIUM', onSelected: (_) => setState(() => _priority = 'MEDIUM'), selectedColor: Colors.orange, backgroundColor: AppColors.darkBg, labelStyle: TextStyle(color: _priority == 'MEDIUM' ? Colors.white : Colors.white54, fontSize: 12)),
                const SizedBox(width: 6),
                ChoiceChip(label: const Text('Yüksek'), selected: _priority == 'HIGH', onSelected: (_) => setState(() => _priority = 'HIGH'), selectedColor: Colors.red, backgroundColor: AppColors.darkBg, labelStyle: TextStyle(color: _priority == 'HIGH' ? Colors.white : Colors.white54, fontSize: 12)),
              ],
            ),
            const SizedBox(height: 20),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _loading ? null : () async {
                  if (_subjectCtrl.text.trim().isEmpty || _messageCtrl.text.trim().isEmpty) {
                    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Lütfen konu ve mesaj girin')));
                    return;
                  }
                  setState(() => _loading = true);
                  try {
                    final api = ApiClient();
                    final cid = await api.ensureActiveCompany();
                    await api.post('/support/tickets', data: {
                      'subject': _subjectCtrl.text.trim(),
                      'message': _messageCtrl.text.trim(),
                      'priority': _priority,
                      'companyId': cid,
                    });
                    widget.onCreated();
                    if (mounted) Navigator.pop(context);
                  } catch (e) {
                    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Talep gönderilemedi: $e')));
                  } finally {
                    if (mounted) setState(() => _loading = false);
                  }
                },
                style: ElevatedButton.styleFrom(backgroundColor: AppColors.primary, padding: const EdgeInsets.symmetric(vertical: 14)),
                child: _loading ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white)) : const Text('Gönder', style: TextStyle(fontSize: 16)),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _TicketDetailScreen extends StatefulWidget {
  final dynamic ticket;
  const _TicketDetailScreen({required this.ticket});

  @override
  State<_TicketDetailScreen> createState() => _TicketDetailScreenState();
}

class _TicketDetailScreenState extends State<_TicketDetailScreen> {
  final _replyCtrl = TextEditingController();
  List<dynamic> _messages = [];
  bool _sending = false;

  @override
  void initState() {
    super.initState();
    _messages = (widget.ticket['messages'] as List?) ?? [];
    _loadTicketDetails();
  }

  Future<void> _loadTicketDetails() async {
    try {
      final res = await ApiClient().dio.get('/support/tickets/${widget.ticket['id']}');
      final data = res.data;
      if (mounted) {
        setState(() {
          _messages = (data['messages'] as List?) ?? [];
        });
      }
    } catch (_) {}
  }

  Future<void> _sendReply() async {
    if (_replyCtrl.text.trim().isEmpty) return;
    setState(() => _sending = true);
    try {
      await ApiClient().dio.post(
        '/support/tickets/${widget.ticket['id']}/messages',
        data: {'message': _replyCtrl.text.trim()},
      );
      _replyCtrl.clear();
      await _loadTicketDetails();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Hata: $e')));
      }
    } finally {
      if (mounted) setState(() => _sending = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.darkBg,
      appBar: AppBar(
        title: Text(widget.ticket['subject'] ?? 'Destek Detay'),
        backgroundColor: AppColors.darkSurface,
      ),
      body: Column(
        children: [
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            color: AppColors.darkSurface,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        widget.ticket['subject'] ?? '',
                        style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16),
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(
                        color: AppColors.primary.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        widget.ticket['status'] ?? 'Açık',
                        style: const TextStyle(color: AppColors.primary, fontSize: 11, fontWeight: FontWeight.bold),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                Text(
                  DateUtil.formatDateTime(widget.ticket['created_at'] ?? ''),
                  style: const TextStyle(color: Colors.white38, fontSize: 11),
                ),
              ],
            ),
          ),
          Expanded(
            child: _messages.isEmpty
                ? const Center(child: Text('Mesaj yok', style: TextStyle(color: Colors.white38)))
                : ListView.builder(
                    padding: const EdgeInsets.all(12),
                    itemCount: _messages.length,
                    itemBuilder: (context, i) {
                      final m = _messages[i];
                      final isAdmin = m['sender_type'] == 'ADMIN';
                      return Align(
                        alignment: isAdmin ? Alignment.centerLeft : Alignment.centerRight,
                        child: Container(
                          margin: const EdgeInsets.only(bottom: 8),
                          padding: const EdgeInsets.all(12),
                          constraints: BoxConstraints(maxWidth: MediaQuery.of(context).size.width * 0.75),
                          decoration: BoxDecoration(
                            color: isAdmin ? AppColors.primary.withOpacity(0.2) : AppColors.darkSurface,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(m['message'] ?? '', style: const TextStyle(color: Colors.white, fontSize: 14)),
                              const SizedBox(height: 4),
                              Text(
                                isAdmin ? 'Destek Ekibi' : 'Siz',
                                style: TextStyle(color: isAdmin ? AppColors.primary : Colors.white38, fontSize: 11),
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
          ),
              },
            ),
          ),
          Container(
            padding: const EdgeInsets.all(8),
            color: AppColors.darkSurface,
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _replyCtrl,
                    style: const TextStyle(color: Colors.white),
                    decoration: const InputDecoration(
                      hintText: 'Yanıt yazın...',
                      hintStyle: TextStyle(color: Colors.white38),
                      border: InputBorder.none,
                      contentPadding: EdgeInsets.symmetric(horizontal: 12),
                    ),
                  ),
                ),
                IconButton(
                  icon: _sending ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2)) : const Icon(Icons.send, color: AppColors.primary),
                  onPressed: _sending ? null : _sendReply,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

