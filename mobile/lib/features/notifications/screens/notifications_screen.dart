import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/api/api_client.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/utils/formatters.dart';

/// Bildirimler Ekranı - Push bildirim listesi
class NotificationsScreen extends ConsumerStatefulWidget {
  const NotificationsScreen({super.key});

  @override
  ConsumerState<NotificationsScreen> createState() => _NotificationsScreenState();
}

class _NotificationsScreenState extends ConsumerState<NotificationsScreen> {
  List<dynamic> _notifications = [];
  bool _loading = true;
  int _unreadCount = 0;

  @override
  void initState() {
    super.initState();
    _loadNotifications();
  }

  Future<void> _loadNotifications() async {
    try {
      final api = ref.read(apiClientProvider);
      final res = await api.get('/notifications');
      final data = res.data['data'] ?? res.data ?? [];
      setState(() {
        _notifications = data;
        _unreadCount = data.where((n) => n['read_at'] == null).length;
        _loading = false;
      });
    } catch (e) {
      setState(() => _loading = false);
    }
  }

  Future<void> _markAsRead(String id) async {
    try {
      final api = ref.read(apiClientProvider);
      await api.post('/notifications/$id/read');
      _loadNotifications();
    } catch (_) {}
  }

  Future<void> _markAllRead() async {
    try {
      final api = ref.read(apiClientProvider);
      await api.post('/notifications/read-all');
      _loadNotifications();
    } catch (_) {}
  }

  IconData _getIcon(String type) {
    switch (type) {
      case 'PAYMENT_DUE': return Icons.access_time;
      case 'CHEQUE_DUE': return Icons.receipt_long;
      case 'RISK_LIMIT': return Icons.warning_amber;
      case 'BACKUP_COMPLETE': return Icons.cloud_done;
      case 'SYSTEM': return Icons.info_outline;
      case 'REPORT_READY': return Icons.assessment;
      case 'INVITATION': return Icons.person_add;
      default: return Icons.notifications;
    }
  }

  Color _getIconColor(String type) {
    switch (type) {
      case 'PAYMENT_DUE': return Colors.orange;
      case 'CHEQUE_DUE': return Colors.amber;
      case 'RISK_LIMIT': return Colors.red;
      case 'BACKUP_COMPLETE': return Colors.green;
      case 'INVITATION': return AppColors.primary;
      default: return Colors.white54;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.darkBg,
      appBar: AppBar(
        title: Text('Bildirimler${_unreadCount > 0 ? ' ($_unreadCount)' : ''}'),
        backgroundColor: AppColors.darkSurface,
        actions: [
          if (_unreadCount > 0)
            TextButton(
              onPressed: _markAllRead,
              child: const Text('Tümünü Oku', style: TextStyle(color: AppColors.primary, fontSize: 13)),
            ),
        ],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _notifications.isEmpty
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.notifications_none, size: 64, color: Colors.white.withOpacity(0.2)),
                      const SizedBox(height: 12),
                      const Text('Bildirim yok', style: TextStyle(color: Colors.white54, fontSize: 16)),
                    ],
                  ),
                )
              : RefreshIndicator(
                  onRefresh: _loadNotifications,
                  child: ListView.separated(
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    itemCount: _notifications.length,
                    separatorBuilder: (_, __) => const Divider(color: Colors.white10, height: 1),
                    itemBuilder: (context, index) {
                      final n = _notifications[index];
                      final isRead = n['read_at'] != null;
                      final type = n['type'] ?? 'SYSTEM';
                      final title = n['title'] ?? 'Bildirim';
                      final message = n['message'] ?? '';
                      final createdAt = n['created_at'] ?? '';

                      return ListTile(
                        tileColor: isRead ? null : AppColors.primary.withOpacity(0.05),
                        leading: CircleAvatar(
                          backgroundColor: _getIconColor(type).withOpacity(0.15),
                          child: Icon(_getIcon(type), color: _getIconColor(type), size: 22),
                        ),
                        title: Text(
                          title,
                          style: TextStyle(
                            color: Colors.white,
                            fontWeight: isRead ? FontWeight.normal : FontWeight.bold,
                            fontSize: 14,
                          ),
                        ),
                        subtitle: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(message, style: const TextStyle(color: Colors.white54, fontSize: 12), maxLines: 2),
                            const SizedBox(height: 4),
                            Text(
                              DateUtil.formatDateTime(createdAt),
                              style: const TextStyle(color: Colors.white38, fontSize: 11),
                            ),
                          ],
                        ),
                        trailing: isRead
                            ? null
                            : Container(
                                width: 8,
                                height: 8,
                                decoration: const BoxDecoration(color: AppColors.primary, shape: BoxShape.circle),
                              ),
                        onTap: () {
                          if (!isRead) _markAsRead(n['id']);
                        },
                      );
                    },
                  ),
                ),
    );
  }
}

