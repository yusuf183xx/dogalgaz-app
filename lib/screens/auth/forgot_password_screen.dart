import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../app/services.dart';
import '../../app/theme.dart';

class ForgotPasswordScreen extends StatefulWidget {
  const ForgotPasswordScreen({
    super.key,
    required this.services,
    this.isAdmin = false,
  });

  final AppServices services;
  final bool isAdmin;

  @override
  State<ForgotPasswordScreen> createState() => _ForgotPasswordScreenState();
}

class _ForgotPasswordScreenState extends State<ForgotPasswordScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  bool _loading = false;
  bool _emailSent = false;

  @override
  void dispose() {
    _emailController.dispose();
    super.dispose();
  }

  Future<void> _sendResetEmail() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() => _loading = true);
    try {
      await widget.services.authService.sendPasswordResetEmail(
        _emailController.text,
      );
      if (mounted) {
        setState(() => _emailSent = true);
      }
    } on FirebaseAuthException catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              widget.services.authService.friendlyAuthError(error) ??
                  'Şifre sıfırlama e-postası gönderilemedi.',
            ),
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _loading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.isAdmin ? 'Admin Şifre Sıfırla' : 'Şifremi Unuttum'),
      ),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          Icon(
            _emailSent ? Icons.mark_email_read_outlined : Icons.lock_reset,
            size: 56,
            color: _emailSent ? appWhatsApp : appBlue,
          ),
          const SizedBox(height: 16),
          Text(
            _emailSent ? 'E-posta gönderildi' : 'Şifrenizi sıfırlayın',
            style: GoogleFonts.manrope(
              fontSize: 24,
              fontWeight: FontWeight.w800,
              color: appPrimary,
            ),
          ),
          const SizedBox(height: 10),
          Text(
            _emailSent
                ? '${_emailController.text.trim()} adresine şifre sıfırlama bağlantısı gönderdik. Gelen kutunuzu ve spam klasörünü kontrol edin. Bağlantıya tıklayıp yeni şifrenizi belirleyebilirsiniz.'
                : 'Kayıtlı e-posta adresinizi girin. Size doğrulama bağlantısı içeren bir e-posta göndereceğiz; bağlantıdan yeni şifrenizi oluşturabilirsiniz.',
            style: const TextStyle(color: appMuted, height: 1.6),
          ),
          if (!_emailSent) ...[
            const SizedBox(height: 24),
            Form(
              key: _formKey,
              child: TextFormField(
                controller: _emailController,
                keyboardType: TextInputType.emailAddress,
                textInputAction: TextInputAction.done,
                decoration: const InputDecoration(
                  labelText: 'E-posta',
                  prefixIcon: Icon(Icons.email_outlined),
                ),
                validator: (value) =>
                    value == null || !value.contains('@')
                        ? 'Geçerli e-posta giriniz.'
                        : null,
                onFieldSubmitted: (_) => _sendResetEmail(),
              ),
            ),
            const SizedBox(height: 20),
            SizedBox(
              width: double.infinity,
              child: FilledButton(
                onPressed: _loading ? null : _sendResetEmail,
                style: FilledButton.styleFrom(
                  backgroundColor: appPrimary,
                  minimumSize: const Size.fromHeight(52),
                ),
                child: _loading
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Text('Sıfırlama E-postası Gönder'),
              ),
            ),
          ] else ...[
            const SizedBox(height: 24),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: const Color(0x141FA463),
                borderRadius: BorderRadius.circular(18),
              ),
              child: const Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Sonraki adımlar',
                    style: TextStyle(fontWeight: FontWeight.w800),
                  ),
                  SizedBox(height: 8),
                  Text(
                    '1. E-postadaki bağlantıya tıklayın\n'
                    '2. Yeni şifrenizi girin\n'
                    '3. Uygulamaya yeni şifre ile giriş yapın',
                    style: TextStyle(color: appMuted, height: 1.6),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: OutlinedButton(
                onPressed: _loading ? null : _sendResetEmail,
                child: const Text('E-postayı Tekrar Gönder'),
              ),
            ),
            const SizedBox(height: 10),
            SizedBox(
              width: double.infinity,
              child: FilledButton(
                onPressed: () => Navigator.of(context).pop(),
                style: FilledButton.styleFrom(
                  backgroundColor: appAccent,
                  foregroundColor: const Color(0xFF1F2019),
                  minimumSize: const Size.fromHeight(52),
                ),
                child: const Text('Giriş Ekranına Dön'),
              ),
            ),
          ],
        ],
      ),
    );
  }
}
