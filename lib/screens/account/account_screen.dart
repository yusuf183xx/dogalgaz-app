import 'package:flutter/material.dart';

import '../../app/services.dart';
import '../../app/theme.dart';
import '../auth/admin_login_screen.dart';
import '../auth/email_verification_screen.dart';
import '../auth/login_screen.dart';
import '../auth/register_screen.dart';
import '../complaint/my_complaints_screen.dart';
import '../quote/my_quotes_screen.dart';

class AccountScreen extends StatelessWidget {
  const AccountScreen({super.key, required this.services});

  final AppServices services;

  @override
  Widget build(BuildContext context) {
    return StreamBuilder(
      stream: services.authService.authStateChanges,
      builder: (context, snapshot) {
        final user = services.authService.currentUser;

        if (user == null) {
          return ListView(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 110),
            children: [
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Hesabım',
                        style: TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.w800,
                          color: appPrimary,
                        ),
                      ),
                      const SizedBox(height: 8),
                      const Text(
                        'Arıza bildirimi ve şikayet takibi için giriş yapın.',
                        style: TextStyle(color: appMuted, height: 1.5),
                      ),
                      const SizedBox(height: 18),
                      SizedBox(
                        width: double.infinity,
                        child: FilledButton(
                          onPressed: () {
                            Navigator.of(context).push(
                              MaterialPageRoute(
                                builder: (_) =>
                                    LoginScreen(services: services),
                              ),
                            );
                          },
                          style: FilledButton.styleFrom(
                            backgroundColor: appPrimary,
                            minimumSize: const Size.fromHeight(52),
                          ),
                          child: const Text('Giriş Yap'),
                        ),
                      ),
                      const SizedBox(height: 10),
                      SizedBox(
                        width: double.infinity,
                        child: OutlinedButton(
                          onPressed: () {
                            Navigator.of(context).push(
                              MaterialPageRoute(
                                builder: (_) =>
                                    RegisterScreen(services: services),
                              ),
                            );
                          },
                          child: const Text('Kayıt Ol'),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Center(
                child: TextButton(
                  onPressed: () {
                    Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (_) =>
                            AdminLoginScreen(services: services),
                      ),
                    );
                  },
                  child: const Text('Admin girişi'),
                ),
              ),
            ],
          );
        }

        return ListView(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 110),
          children: [
            Card(
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      user.displayName ?? 'Kullanıcı',
                      style: const TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(user.email ?? '', style: const TextStyle(color: appMuted)),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Icon(
                          services.authService.isEmailVerified
                              ? Icons.verified_outlined
                              : Icons.mark_email_unread_outlined,
                          color: services.authService.isEmailVerified
                              ? appWhatsApp
                              : appAccent,
                          size: 20,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          services.authService.isEmailVerified
                              ? 'E-posta doğrulandı'
                              : 'E-posta doğrulaması bekleniyor',
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 12),
            if (!services.authService.isEmailVerified)
              Card(
                child: ListTile(
                  leading: const Icon(Icons.mark_email_unread_outlined),
                  title: const Text('E-postayı doğrula'),
                  subtitle: const Text('Şikayet göndermek için gerekli'),
                  onTap: () {
                    Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (_) =>
                            EmailVerificationScreen(services: services),
                      ),
                    );
                  },
                ),
              ),
            Card(
              child: ListTile(
                leading: const Icon(Icons.list_alt_outlined),
                title: const Text('Şikayetlerim'),
                subtitle: const Text('Arıza bildirimi durumları'),
                onTap: () {
                  Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (_) =>
                          MyComplaintsScreen(services: services),
                    ),
                  );
                },
              ),
            ),
            Card(
              child: ListTile(
                leading: const Icon(Icons.request_quote_outlined),
                title: const Text('Tekliflerim'),
                subtitle: const Text('Admin cevaplarını buradan takip edin'),
                onTap: () {
                  Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (_) => MyQuotesScreen(services: services),
                    ),
                  );
                },
              ),
            ),
            Card(
              child: ListTile(
                leading: const Icon(Icons.logout),
                title: const Text('Çıkış yap'),
                onTap: () => services.authService.signOut(),
              ),
            ),
            const SizedBox(height: 16),
            Center(
              child: TextButton(
                onPressed: () {
                  Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (_) =>
                          AdminLoginScreen(services: services),
                    ),
                  );
                },
                child: const Text('Admin girişi'),
              ),
            ),
          ],
        );
      },
    );
  }
}
