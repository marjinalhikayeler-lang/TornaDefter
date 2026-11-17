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
      setState(() => _error = e.response?.data?['message'] ?? 'Giriş başarısız');
    } finally {
      setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.backgroundDark,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            children: [
              const SizedBox(height: 60),
              Container(
                width: 80, height: 80,
                decoration: BoxDecoration(color: AppColors.primary, borderRadius: BorderRadius.circular(20)),
                child: const Center(child: Text('TD', style: TextStyle(fontSize: 36, fontWeight: FontWeight.bold, color: Colors.white))),
              ),
              const SizedBox(height: 16),
              const Text('TornaDefter', style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.white)),
              const SizedBox(height: 4),
              const Text('Hesabınıza giriş yapın', style: TextStyle(color: AppColors.textSecondaryDark)),
              const SizedBox(height: 40),
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
            ],
          ),
        ),
      ),
    );
  }
}

