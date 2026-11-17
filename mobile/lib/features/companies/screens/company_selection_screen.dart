import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/api/api_client.dart';
import '../../../core/theme/app_theme.dart';

/// Şirket Seçim Ekranı - Birden fazla şirketi varsa login sonrası gösterilir
class CompanySelectionScreen extends ConsumerStatefulWidget {
  const CompanySelectionScreen({super.key});

  @override
  ConsumerState<CompanySelectionScreen> createState() => _CompanySelectionScreenState();
}

class _CompanySelectionScreenState extends ConsumerState<CompanySelectionScreen> {
  List<dynamic> _companies = [];
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadCompanies();
  }

  Future<void> _loadCompanies() async {
    try {
      final api = ref.read(apiClientProvider);
      final res = await api.get('/companies');
      setState(() {
        _companies = res.data['data'] ?? res.data ?? [];
        _loading = false;
      });
    } catch (e) {
      setState(() {
        _error = 'Şirketler yüklenemedi';
        _loading = false;
      });
    }
  }

  void _selectCompany(dynamic company) {
    // SharedPreferences'e kaydet ve ana ekrana yönlendir
    // ref.read(selectedCompanyProvider.notifier).set(company);
    Navigator.of(context).pushReplacementNamed('/home');
  }

  void _createCompany() {
    showDialog(
      context: context,
      builder: (ctx) => _CreateCompanyDialog(
        onCreated: (company) {
          setState(() => _companies.add(company));
          _selectCompany(company);
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.darkBg,
      appBar: AppBar(
        title: const Text('Şirket Seçin'),
        backgroundColor: AppColors.darkSurface,
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.add_business),
            onPressed: _createCompany,
            tooltip: 'Yeni Şirket Oluştur',
          ),
        ],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.error_outline, size: 48, color: Colors.red),
                      const SizedBox(height: 12),
                      Text(_error!, style: const TextStyle(color: Colors.white70)),
                      const SizedBox(height: 16),
                      ElevatedButton(
                        onPressed: () {
                          setState(() { _loading = true; _error = null; });
                          _loadCompanies();
                        },
                        child: const Text('Tekrar Dene'),
                      ),
                    ],
                  ),
                )
              : _companies.isEmpty
                  ? Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.business, size: 64, color: Colors.white.withOpacity(0.3)),
                          const SizedBox(height: 16),
                          const Text('Henüz şirket yok', style: TextStyle(color: Colors.white54, fontSize: 16)),
                          const SizedBox(height: 20),
                          ElevatedButton.icon(
                            onPressed: _createCompany,
                            icon: const Icon(Icons.add),
                            label: const Text('Yeni Şirket Oluştur'),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppColors.primary,
                              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
                            ),
                          ),
                        ],
                      ),
                    )
                  : ListView.builder(
                      padding: const EdgeInsets.all(16),
                      itemCount: _companies.length,
                      itemBuilder: (context, index) {
                        final c = _companies[index];
                        return _CompanyCard(
                          name: c['name'] ?? '',
                          taxNumber: c['tax_number'] ?? '',
                          city: c['city'] ?? '',
                          role: c['role'] ?? 'OWNER',
                          onTap: () => _selectCompany(c),
                        );
                      },
                    ),
    );
  }
}

class _CompanyCard extends StatelessWidget {
  final String name;
  final String taxNumber;
  final String city;
  final String role;
  final VoidCallback onTap;

  const _CompanyCard({
    required this.name,
    required this.taxNumber,
    required this.city,
    required this.role,
    required this.onTap,
  });

  String get _roleLabel {
    switch (role) {
      case 'OWNER': return 'Sahip';
      case 'MANAGER': return 'Yönetici';
      case 'ACCOUNTANT': return 'Muhasebeci';
      case 'VIEWER': return 'Görüntüleyici';
      default: return role;
    }
  }

  Color get _roleColor {
    switch (role) {
      case 'OWNER': return AppColors.primary;
      case 'MANAGER': return Colors.orange;
      case 'ACCOUNTANT': return Colors.purple;
      default: return Colors.grey;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      color: AppColors.darkSurface,
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        leading: CircleAvatar(
          backgroundColor: AppColors.primary.withOpacity(0.2),
          radius: 28,
          child: const Icon(Icons.business, color: AppColors.primary, size: 28),
        ),
        title: Text(name, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16)),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (taxNumber.isNotEmpty)
              Text('VN: $taxNumber', style: const TextStyle(color: Colors.white54, fontSize: 12)),
            if (city.isNotEmpty)
              Text(city, style: const TextStyle(color: Colors.white54, fontSize: 12)),
            const SizedBox(height: 4),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
              decoration: BoxDecoration(
                color: _roleColor.withOpacity(0.2),
                borderRadius: BorderRadius.circular(4),
              ),
              child: Text(_roleLabel, style: TextStyle(color: _roleColor, fontSize: 11, fontWeight: FontWeight.w600)),
            ),
          ],
        ),
        trailing: const Icon(Icons.chevron_right, color: Colors.white38),
        onTap: onTap,
      ),
    );
  }
}

class _CreateCompanyDialog extends StatefulWidget {
  final Function(dynamic) onCreated;
  const _CreateCompanyDialog({required this.onCreated});

  @override
  State<_CreateCompanyDialog> createState() => _CreateCompanyDialogState();
}

class _CreateCompanyDialogState extends State<_CreateCompanyDialog> {
  final _nameController = TextEditingController();
  final _taxController = TextEditingController();
  bool _loading = false;

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      backgroundColor: AppColors.darkSurface,
      title: const Text('Yeni Şirket', style: TextStyle(color: Colors.white)),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          TextField(
            controller: _nameController,
            style: const TextStyle(color: Colors.white),
            decoration: const InputDecoration(
              labelText: 'Şirket Adı *',
              labelStyle: TextStyle(color: Colors.white54),
              enabledBorder: OutlineInputBorder(borderSide: BorderSide(color: Colors.white24)),
              focusedBorder: OutlineInputBorder(borderSide: BorderSide(color: AppColors.primary)),
            ),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _taxController,
            style: const TextStyle(color: Colors.white),
            decoration: const InputDecoration(
              labelText: 'Vergi Numarası',
              labelStyle: TextStyle(color: Colors.white54),
              enabledBorder: OutlineInputBorder(borderSide: BorderSide(color: Colors.white24)),
              focusedBorder: OutlineInputBorder(borderSide: BorderSide(color: AppColors.primary)),
            ),
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('İptal', style: TextStyle(color: Colors.white54)),
        ),
        ElevatedButton(
          onPressed: _loading ? null : () async {
            if (_nameController.text.trim().isEmpty) return;
            setState(() => _loading = true);
            // API çağrısı yapılacak
            Navigator.pop(context);
          },
          style: ElevatedButton.styleFrom(backgroundColor: AppColors.primary),
          child: _loading ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2)) : const Text('Oluştur'),
        ),
      ],
    );
  }
}

