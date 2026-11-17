import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/api/api_client.dart';
import 'package:dio/dio.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});
  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final _firstNameCtrl = TextEditingController();
  final _lastNameCtrl = TextEditingController();
  final _emailCtrl = TextEditingController();
  final _phoneCtrl = TextEditingController();
  final _passwordCtrl = TextEditingController();
  final _passwordConfirmCtrl = TextEditingController();
  bool _loading = false;
  bool _terms = false;
  String? _error;

  Future<void> _register() async {
    if (!_terms) { setState(() => _error = 'Kullanım koşullarını kabul edin'); return; }
    if (_passwordCtrl.text != _passwordConfirmCtrl.text) { setState(() => _error = 'Şifreler eşleşmiyor'); return; }
    setState(() { _loading = true; _error = null; });
    try {
      final res = await ApiClient().dio.post('/auth/register', data: {
        'first_name': _firstNameCtrl.text.trim(),
        'last_name': _lastNameCtrl.text.trim(),
        'email': _emailCtrl.text.trim(),
        'phone': _phoneCtrl.text.trim().isEmpty ? null : _phoneCtrl.text.trim(),
        'password': _passwordCtrl.text,
        'password_confirm': _passwordConfirmCtrl.text,
        'terms_accepted': true,
      });
      await ApiClient().setTokens(res.data['access_token'], res.data['refresh_token']);
      if (mounted) context.go('/home');
    } on DioException catch (e) {
      setState(() => _error = e.response?.data?['message'] ?? 'Kayıt başarısız');
    } finally {
      setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.backgroundDark,
      appBar: AppBar(title: const Text('Kayıt Ol'), leading: IconButton(icon: const Icon(Icons.arrow_back), onPressed: () => context.go('/login'))),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(children: [
          if (_error != null) Container(width: double.infinity, padding: const EdgeInsets.all(12), margin: const EdgeInsets.only(bottom: 16),
            decoration: BoxDecoration(color: AppColors.danger.withOpacity(0.1), borderRadius: BorderRadius.circular(12)),
            child: Text(_error!, style: const TextStyle(color: AppColors.danger))),
          TextField(controller: _firstNameCtrl, style: const TextStyle(color: Colors.white), decoration: const InputDecoration(hintText: 'Ad', prefixIcon: Icon(Icons.person_outline, color: AppColors.textSecondaryDark))),
          const SizedBox(height: 12),
          TextField(controller: _lastNameCtrl, style: const TextStyle(color: Colors.white), decoration: const InputDecoration(hintText: 'Soyad', prefixIcon: Icon(Icons.person_outline, color: AppColors.textSecondaryDark))),
          const SizedBox(height: 12),
          TextField(controller: _emailCtrl, keyboardType: TextInputType.emailAddress, style: const TextStyle(color: Colors.white), decoration: const InputDecoration(hintText: 'E-posta', prefixIcon: Icon(Icons.email_outlined, color: AppColors.textSecondaryDark))),
          const SizedBox(height: 12),
          TextField(controller: _phoneCtrl, keyboardType: TextInputType.phone, style: const TextStyle(color: Colors.white), decoration: const InputDecoration(hintText: 'Telefon (opsiyonel)', prefixIcon: Icon(Icons.phone_outlined, color: AppColors.textSecondaryDark))),
          const SizedBox(height: 12),
          TextField(controller: _passwordCtrl, obscureText: true, style: const TextStyle(color: Colors.white), decoration: const InputDecoration(hintText: 'Şifre (en az 8 karakter)', prefixIcon: Icon(Icons.lock_outline, color: AppColors.textSecondaryDark))),
          const SizedBox(height: 12),
          TextField(controller: _passwordConfirmCtrl, obscureText: true, style: const TextStyle(color: Colors.white), decoration: const InputDecoration(hintText: 'Şifre Tekrar', prefixIcon: Icon(Icons.lock_outline, color: AppColors.textSecondaryDark))),
          const SizedBox(height: 16),
          Row(children: [
            Checkbox(value: _terms, onChanged: (v) => setState(() => _terms = v ?? false), activeColor: AppColors.primary),
            const Expanded(child: Text('Kullanım koşullarını ve gizlilik politikasını kabul ediyorum', style: TextStyle(color: AppColors.textSecondaryDark, fontSize: 12))),
          ]),
          const SizedBox(height: 16),
          SizedBox(width: double.infinity, height: 52, child: ElevatedButton(onPressed: _loading ? null : _register,
            child: _loading ? const SizedBox(width: 24, height: 24, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2)) : const Text('Kayıt Ol'))),
        ]),
      ),
    );
  }
}

