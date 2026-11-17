import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/api/api_client.dart';
import 'package:dio/dio.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});
  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _emailCtrl = TextEditingController();
  final _passwordCtrl = TextEditingController();
  bool _loading = false;
  bool _obscure = true;
  String? _error;

  Future<void> _login() async {
    if (_emailCtrl.text.isEmpty || _passwordCtrl.text.isEmpty) {
      setState(() => _error = 'E-posta ve şifre gereklidir');
      return;
    }
    setState(() { _loading = true; _error = null; });
    try {
      final res = await ApiClient().dio.post('/auth/login', data: {
        'identifier': _emailCtrl.text.trim(),
        'password': _passwordCtrl.text,
      });
      await ApiClient().setTokens(res.data['access_token'], res.data['refresh_token']);
      if (res.data['companies'] != null && (res.data['companies'] as List).isNotEmpty) {
        await ApiClient().setActiveCompany(res.data['companies'][0]['id']);
      }
      if (mounted) context.go('/home');
    } on DioException catch (e) {
      final msg = e.response?.data?['message'];
      if (msg is List) {
        setState(() => _error = msg.join('\n'));
      } else if (msg is String) {
        setState(() => _error = msg);
      } else if (e.type == DioExceptionType.connectionTimeout || e.type == DioExceptionType.connectionError) {
        setState(() => _error = 'Sunucuya bağlanılamadı. Bilgisayarınızda backend sunucusunun (npm run start:dev) çalıştığından ve aynı Wi-Fi ağında olduğunuzdan emin olun.');
      } else {
        setState(() => _error = e.response?.data?['error']?['message'] ?? 'Giriş başarısız (${e.message})');
      }
    } catch (e) {
      setState(() => _error = 'Hata: $e');
    } finally {
      setState(() => _loading = false);
    }
  }

  void _showServerSettingsDialog() async {
    final currentUrl = await ApiClient().getBaseUrl();
    final urlCtrl = TextEditingController(text: currentUrl);
    if (!mounted) return;
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.cardDark,
        title: const Text('Sunucu Bağlantı Ayarı', style: TextStyle(color: Colors.white, fontSize: 18)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Backend API adresinizi girin (Örn: http://192.168.1.152:3000/api/v1 veya bulut URL):',
              style: TextStyle(color: AppColors.textSecondaryDark, fontSize: 13),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: urlCtrl,
              style: const TextStyle(color: Colors.white, fontSize: 14),
              decoration: InputDecoration(
                filled: true,
                fillColor: AppColors.backgroundDark,
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                hintText: 'https://tornadefter.onrender.com/api/v1',
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('İptal', style: TextStyle(color: AppColors.textSecondaryDark)),
          ),
          ElevatedButton(
            onPressed: () async {
              if (urlCtrl.text.trim().isNotEmpty) {
                await ApiClient().setBaseUrl(urlCtrl.text.trim());
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Sunucu adresi kaydedildi')),
                  );
                }
              }
              if (ctx.mounted) Navigator.pop(ctx);
            },
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.primary),
            child: const Text('Kaydet', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.backgroundDark,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.settings, color: AppColors.textSecondaryDark),
            tooltip: 'Sunucu Bağlantı Ayarı',
            onPressed: _showServerSettingsDialog,
          ),
        ],
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
          child: Column(
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(20),
                child: Image.asset(
                  'assets/images/logo.png',
                  width: 90,
                  height: 90,
                  fit: BoxFit.cover,
                  errorBuilder: (_, __, ___) => Container(
                    width: 90, height: 90,
                    decoration: BoxDecoration(color: AppColors.primary, borderRadius: BorderRadius.circular(20)),
                    child: const Center(child: Icon(Icons.settings_suggest, size: 48, color: Colors.white)),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              const Text('TornaDefter', style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.white)),
              const SizedBox(height: 4),
              const Text('Hesabınıza giriş yapın', style: TextStyle(color: AppColors.textSecondaryDark)),
              const SizedBox(height: 32),
              if (_error != null)
                Container(
                  width: double.infinity, padding: const EdgeInsets.all(12), margin: const EdgeInsets.only(bottom: 16),
                  decoration: BoxDecoration(color: AppColors.danger.withOpacity(0.1), borderRadius: BorderRadius.circular(12)),
                  child: Text(_error!, style: const TextStyle(color: AppColors.danger, fontSize: 14)),
                ),
              TextField(
                controller: _emailCtrl,
                keyboardType: TextInputType.emailAddress,
                style: const TextStyle(color: Colors.white),
                decoration: const InputDecoration(hintText: 'E-posta veya telefon', prefixIcon: Icon(Icons.person_outline, color: AppColors.textSecondaryDark)),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: _passwordCtrl,
                obscureText: _obscure,
                style: const TextStyle(color: Colors.white),
                decoration: InputDecoration(
                  hintText: 'Şifre',
                  prefixIcon: const Icon(Icons.lock_outline, color: AppColors.textSecondaryDark),
                  suffixIcon: IconButton(
                    icon: Icon(_obscure ? Icons.visibility_off : Icons.visibility, color: AppColors.textSecondaryDark),
                    onPressed: () => setState(() => _obscure = !_obscure),
                  ),
                ),
                onSubmitted: (_) => _login(),
              ),
              const SizedBox(height: 8),
              Align(
                alignment: Alignment.centerRight,
                child: TextButton(onPressed: () {}, child: const Text('Şifremi Unuttum', style: TextStyle(color: AppColors.primary))),
              ),
              const SizedBox(height: 16),
              SizedBox(
                width: double.infinity, height: 52,
                child: ElevatedButton(
                  onPressed: _loading ? null : _login,
                  child: _loading ? const SizedBox(width: 24, height: 24, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2)) : const Text('Giriş Yap'),
                ),
              ),
              const SizedBox(height: 24),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Text('Hesabınız yok mu?', style: TextStyle(color: AppColors.textSecondaryDark)),
                  TextButton(onPressed: () => context.go('/register'), child: const Text('Kayıt Ol', style: TextStyle(color: AppColors.primary, fontWeight: FontWeight.w600))),
                ],
              ),
              const SizedBox(height: 12),
              TextButton.icon(
                icon: const Icon(Icons.dns_outlined, size: 16, color: AppColors.textSecondaryDark),
                label: const Text('Sunucu Ayarı (IP / Port)', style: TextStyle(color: AppColors.textSecondaryDark, fontSize: 13)),
                onPressed: _showServerSettingsDialog,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

