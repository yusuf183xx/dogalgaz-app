import 'package:flutter/material.dart';

import '../../app/services.dart';
import '../../app/theme.dart';

class EmailVerificationScreen extends StatefulWidget {
  const EmailVerificationScreen({super.key, required this.services});

  final AppServices services;

  @override
  State<EmailVerificationScreen> createState() => _EmailVerificationScreenState();
}

class _EmailVerificationScreenState extends State<EmailVerificationScreen> {
  bool _loading = false;

  Future<void> _resend() async {
    setState(() => _loading = true);
    await widget.services.authService.sendVerificationEmail();
    if (mounted) {
      setState(() => _loading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Doğrulama e-postası tekrar gönderildi.')),
      );
    }
  }

  Future<void> _checkVerified() async {
    setState(() => _loading = true);
    await widget.services.authService.reloadUser();
    if (!mounted) {
      return;
    }
    setState(() => _loading = false);

    if (widget.services.authService.isEmailVerified) {
      Navigator.of(context).popUntil((route) => route.isFirst);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('E-posta doğrulandı. Hoş geldiniz!')),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Henüz doğrulanmadı. Gelen kutunuzu kontrol edin.'),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final email = widget.services.authService.currentUser?.email ?? '';

    return Scaffold(
      appBar: AppBar(title: const Text('E-posta Doğrulama')),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Icon(Icons.mark_email_unread_outlined, size: 56, color: appBlue),
            const SizedBox(height: 16),
            const Text(
              'E-postanızı doğrulayın',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.w800,
                color: appPrimary,
              ),
            ),
            const SizedBox(height: 10),
            Text(
              '$email adresine doğrulama bağlantısı gönderdik. Bağlantıya tıkladıktan sonra aşağıdaki butona basın.',
              style: const TextStyle(color: appMuted, height: 1.6),
            ),
            const Spacer(),
            SizedBox(
              width: double.infinity,
              child: FilledButton(
                onPressed: _loading ? null : _checkVerified,
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
                    : const Text('Doğruladım, Kontrol Et'),
              ),
            ),
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              child: OutlinedButton(
                onPressed: _loading ? null : _resend,
                child: const Text('Doğrulama E-postasını Tekrar Gönder'),
              ),
            ),
            const SizedBox(height: 12),
            TextButton(
              onPressed: () => widget.services.authService.signOut(),
              child: const Text('Çıkış Yap'),
            ),
          ],
        ),
      ),
    );
  }
}
