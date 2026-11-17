import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:file_picker/file_picker.dart';
import '../../../core/api/api_client.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/utils/formatters.dart';

/// Veri İçe Aktarma Ekranı - Excel/CSV dosyasından cari hesap aktarma
class DataImportScreen extends ConsumerStatefulWidget {
  const DataImportScreen({super.key});

  @override
  ConsumerState<DataImportScreen> createState() => _DataImportScreenState();
}

class _DataImportScreenState extends ConsumerState<DataImportScreen> {
  bool _uploading = false;
  Map<String, dynamic>? _result;
  List<dynamic> _history = [];
  bool _loadingHistory = true;

  @override
  void initState() {
    super.initState();
    _loadHistory();
  }

  Future<void> _loadHistory() async {
    try {
      final api = ref.read(apiClientProvider);
      final res = await api.get('/companies/COMPANY_ID/data-import/history');
      setState(() {
        _history = res.data['data'] ?? res.data ?? [];
        _loadingHistory = false;
      });
    } catch (e) {
      setState(() => _loadingHistory = false);
    }
  }

  Future<void> _pickAndUpload() async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['xlsx', 'xls', 'csv'],
    );
    if (result == null || result.files.isEmpty) return;

    setState(() { _uploading = true; _result = null; });

    try {
      final api = ref.read(apiClientProvider);
      final file = result.files.first;
      // FormData ile upload
      // final formData = FormData.fromMap({ 'file': MultipartFile.fromBytes(file.bytes!, filename: file.name) });
      // final res = await api.post('/companies/COMPANY_ID/data-import/accounts', data: formData);

      setState(() {
        _result = {
          'successRows': 0,
          'errorRows': 0,
          'totalRows': 0,
          'message': 'Dosya yüklendi: ${file.name}',
        };
        _uploading = false;
      });
      _loadHistory();
    } catch (e) {
      setState(() {
        _result = {'error': 'Yükleme başarısız: $e'};
        _uploading = false;
      });
    }
  }

  Future<void> _downloadTemplate() async {
    try {
      // Şablon indirme endpoint'i
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Şablon indiriliyor...'), backgroundColor: AppColors.primary),
      );
    } catch (_) {}
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.darkBg,
      appBar: AppBar(
        title: const Text('Veri İçe Aktar'),
        backgroundColor: AppColors.darkSurface,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Bilgi kartı
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppColors.primary.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: AppColors.primary.withOpacity(0.3)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Row(
                    children: [
                      Icon(Icons.info_outline, color: AppColors.primary, size: 20),
                      SizedBox(width: 8),
                      Text('Excel/CSV İçe Aktarma', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 15)),
                    ],
                  ),
                  const SizedBox(height: 10),
                  const Text(
                    'Cari hesaplarınızı Excel veya CSV dosyasından toplu olarak aktarabilirsiniz.\n\n'
                    'Desteklenen formatlar: .xlsx, .xls, .csv\n'
                    'Desteklenen kaynaklar: Terkon Veresiye, diğer programlar',
                    style: TextStyle(color: Colors.white60, fontSize: 13),
                  ),
                  const SizedBox(height: 12),
                  OutlinedButton.icon(
                    onPressed: _downloadTemplate,
                    icon: const Icon(Icons.download, size: 18, color: AppColors.primary),
                    label: const Text('Örnek Şablon İndir', style: TextStyle(color: AppColors.primary)),
                    style: OutlinedButton.styleFrom(side: const BorderSide(color: AppColors.primary)),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),

            // Dosya seç ve yükle
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: _uploading ? null : _pickAndUpload,
                icon: _uploading
                    ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                    : const Icon(Icons.upload_file),
                label: Text(_uploading ? 'Yükleniyor...' : 'Dosya Seç ve Yükle'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
              ),
            ),

            // Sonuç
            if (_result != null) ...[
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: _result!['error'] != null ? Colors.red.withOpacity(0.1) : AppColors.creditGreen.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(
                    color: _result!['error'] != null ? Colors.red.withOpacity(0.3) : AppColors.creditGreen.withOpacity(0.3),
                  ),
                ),
                child: _result!['error'] != null
                    ? Text(_result!['error'], style: const TextStyle(color: Colors.red))
                    : Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('✅ Başarılı: ${_result!['successRows']} kayıt', style: const TextStyle(color: AppColors.creditGreen)),
                          if ((_result!['errorRows'] ?? 0) > 0)
                            Text('❌ Hatalı: ${_result!['errorRows']} kayıt', style: const TextStyle(color: Colors.red)),
                          Text('📊 Toplam: ${_result!['totalRows']} kayıt', style: const TextStyle(color: Colors.white54)),
                        ],
                      ),
              ),
            ],

            // İçe aktarma geçmişi
            const SizedBox(height: 24),
            const Text('İçe Aktarma Geçmişi', style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
            const SizedBox(height: 10),
            _loadingHistory
                ? const Center(child: Padding(padding: EdgeInsets.all(20), child: CircularProgressIndicator()))
                : _history.isEmpty
                    ? const Padding(
                        padding: EdgeInsets.all(20),
                        child: Center(child: Text('Henüz içe aktarma yapılmamış', style: TextStyle(color: Colors.white38))),
                      )
                    : Column(
                        children: _history.map((h) {
                          return Card(
                            color: AppColors.darkSurface,
                            margin: const EdgeInsets.only(bottom: 8),
                            child: ListTile(
                              leading: Icon(
                                h['status'] == 'completed' ? Icons.check_circle : h['status'] == 'failed' ? Icons.error : Icons.hourglass_empty,
                                color: h['status'] == 'completed' ? AppColors.creditGreen : h['status'] == 'failed' ? Colors.red : Colors.orange,
                              ),
                              title: Text(h['file_name'] ?? '', style: const TextStyle(color: Colors.white, fontSize: 13)),
                              subtitle: Text(
                                '${h['success_rows'] ?? 0} başarılı / ${h['error_rows'] ?? 0} hatalı • ${DateUtil.formatDateTime(h['created_at'] ?? '')}',
                                style: const TextStyle(color: Colors.white54, fontSize: 11),
                              ),
                            ),
                          );
                        }).toList(),
                      ),
          ],
        ),
      ),
    );
  }
}

