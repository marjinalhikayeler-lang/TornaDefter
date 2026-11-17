import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/api/api_client.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/utils/formatters.dart';

/// Yedekleme & Geri Yükleme Ekranı
class BackupScreen extends ConsumerStatefulWidget {
  const BackupScreen({super.key});

  @override
  ConsumerState<BackupScreen> createState() => _BackupScreenState();
}

class _BackupScreenState extends ConsumerState<BackupScreen> {
  List<dynamic> _backups = [];
  bool _loading = true;
  bool _creating = false;

  @override
  void initState() {
    super.initState();
    _loadBackups();
  }

  Future<void> _loadBackups() async {
    try {
      final api = ref.read(apiClientProvider);
      final cid = await api.ensureActiveCompany();
      if (cid == null) {
        if (mounted) setState(() => _loading = false);
        return;
      }
      final res = await api.get('/companies/$cid/backups');
      setState(() {
        _backups = res.data['data'] ?? res.data is List ? res.data : [];
        _loading = false;
      });
    } catch (e) {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _createBackup() async {
    setState(() => _creating = true);
    try {
      final api = ref.read(apiClientProvider);
      final cid = await api.ensureActiveCompany();
      if (cid == null) return;
      await api.post('/companies/$cid/backups');
      await _loadBackups();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Yedekleme oluşturuldu'), backgroundColor: AppColors.creditGreen),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Yedekleme başarısız: $e'), backgroundColor: Colors.red),
        );
      }
    }
    if (mounted) setState(() => _creating = false);
  }

  Future<void> _restoreBackup(String id) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.darkSurface,
        title: const Text('Geri Yükle', style: TextStyle(color: Colors.orange)),
        content: const Text(
          'Bu yedekten geri yükleme yapılacak. Mevcut veriler üzerine yazılacaktır. Devam etmek istiyor musunuz?',
          style: TextStyle(color: Colors.white70),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('İptal', style: TextStyle(color: Colors.white54))),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.orange),
            child: const Text('Geri Yükle'),
          ),
        ],
      ),
    );
    if (confirmed != true) return;

    try {
      final api = ref.read(apiClientProvider);
      final cid = await api.ensureActiveCompany();
      if (cid == null) return;
      await api.post('/companies/$cid/backups/$id/restore');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Geri yükleme başarılı'), backgroundColor: AppColors.creditGreen),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Geri yükleme başarısız: $e'), backgroundColor: Colors.red),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.darkBg,
      appBar: AppBar(
        title: const Text('Yedekleme'),
        backgroundColor: AppColors.darkSurface,
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : Column(
              children: [
                // Yedek oluştur butonu
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(16),
                  child: ElevatedButton.icon(
                    onPressed: _creating ? null : _createBackup,
                    icon: _creating
                        ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                        : const Icon(Icons.backup),
                    label: Text(_creating ? 'Yedekleniyor...' : 'Şimdi Yedekle'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                    ),
                  ),
                ),
                // Otomatik yedekleme bilgisi
                Container(
                  margin: const EdgeInsets.symmetric(horizontal: 16),
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: AppColors.primary.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: AppColors.primary.withOpacity(0.3)),
                  ),
                  child: const Row(
                    children: [
                      Icon(Icons.info_outline, color: AppColors.primary, size: 18),
                      SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          'Otomatik yedekleme her gün yapılmaktadır.',
                          style: TextStyle(color: Colors.white70, fontSize: 12),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 12),
                // Yedek listesi
                Expanded(
                  child: _backups.isEmpty
                      ? const Center(child: Text('Henüz yedek yok', style: TextStyle(color: Colors.white54)))
                      : ListView.builder(
                          padding: const EdgeInsets.symmetric(horizontal: 12),
                          itemCount: _backups.length,
                          itemBuilder: (context, i) {
                            final b = _backups[i];
                            final type = b['type'] ?? 'MANUAL';
                            final status = b['status'] ?? 'COMPLETED';
                            final createdAt = b['created_at'] ?? '';
                            final size = b['file_size'] ?? 0;

                            return Card(
                              color: AppColors.darkSurface,
                              margin: const EdgeInsets.only(bottom: 8),
                              child: ListTile(
                                leading: CircleAvatar(
                                  backgroundColor: type == 'AUTO' ? Colors.blue.withOpacity(0.15) : Colors.orange.withOpacity(0.15),
                                  child: Icon(
                                    type == 'AUTO' ? Icons.schedule : Icons.backup,
                                    color: type == 'AUTO' ? Colors.blue : Colors.orange,
                                    size: 20,
                                  ),
                                ),
                                title: Text(
                                  type == 'AUTO' ? 'Otomatik Yedek' : 'Manuel Yedek',
                                  style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w600, fontSize: 14),
                                ),
                                subtitle: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(DateUtil.formatDateTime(createdAt), style: const TextStyle(color: Colors.white54, fontSize: 12)),
                                    if (size > 0)
                                      Text('${(size / 1024).toStringAsFixed(1)} KB', style: const TextStyle(color: Colors.white38, fontSize: 11)),
                                  ],
                                ),
                                trailing: status == 'COMPLETED'
                                    ? IconButton(
                                        icon: const Icon(Icons.restore, color: Colors.orange),
                                        onPressed: () => _restoreBackup(b['id']),
                                        tooltip: 'Geri Yükle',
                                      )
                                    : const SizedBox(width: 24, height: 24, child: CircularProgressIndicator(strokeWidth: 2)),
                              ),
                            );
                          },
                        ),
                ),
              ],
            ),
    );
  }
}

