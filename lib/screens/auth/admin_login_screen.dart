import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../app/admin_config.dart';
import '../../app/services.dart';
import '../../app/theme.dart';
import 'forgot_password_screen.dart';
import '../admin/admin_dashboard_screen.dart';

class AdminLoginScreen extends StatefulWidget {
  const AdminLoginScreen({super.key, required this.services});

  final AppServices services;

  @override
  State<AdminLoginScreen> createState() => _AdminLoginScreenState();
}

class _AdminLoginScreenState extends State<AdminLoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _loading = false;

  @override
  void initState() {
    super.initState();
    _emailController.text = AdminConfig.email;
    _passwordController.text = AdminConfig.password;
  }

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _login() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() => _loading = true);
    try {
      await widget.services.authService.signIn(
        email: _emailController.text,
        password: _passwordController.text,
      );

      final user = widget.services.authService.currentUser;
      if (user == null) {
        throw FirebaseAuthException(code: 'user-not-found');
      }

      final isAdmin = await widget.services.authService.isAdmin(user.uid);
      if (!isAdmin) {
        await widget.services.authService.signOut();
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Bu hesap admin yetkisine sahip değil.'),
            ),
          );
        }
        return;
      }

      if (!mounted) {
        return;
      }

      Navigator.of(context).pushReplacement(
        MaterialPageRoute(
          builder: (_) => AdminDashboardScreen(services: widget.services),
        ),
      );
    } on FirebaseAuthException catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              widget.services.authService.friendlyAuthError(error) ??
                  'Admin girişi başarısız.',
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
      appBar: AppBar(title: const Text('Admin Girişi')),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          Container(
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
              color: const Color(0x14103B2F),
              borderRadius: BorderRadius.circular(20),
            ),
            child: const Row(
              children: [
                Icon(Icons.admin_panel_settings_outlined, color: appPrimary),
                SizedBox(width: 12),
                Expanded(
                  child: Text(
                    'Yalnızca yetkili admin hesapları bu panele erişebilir.',
                    style: TextStyle(color: appMuted, height: 1.5),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),
          Text(
            'Yönetim paneli',
            style: GoogleFonts.manrope(
              fontSize: 24,
              fontWeight: FontWeight.w800,
              color: appPrimary,
            ),
          ),
          const SizedBox(height: 24),
          Form(
            key: _formKey,
            child: Column(
              children: [
                TextFormField(
                  controller: _emailController,
                  keyboardType: TextInputType.emailAddress,
                  decoration: const InputDecoration(
                    labelText: 'Admin e-posta',
                    prefixIcon: Icon(Icons.email_outlined),
                  ),
                  validator: (value) => value == null || !value.contains('@')
                      ? 'Geçerli e-posta giriniz.'
                      : null,
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _passwordController,
                  obscureText: true,
                  decoration: const InputDecoration(
                    labelText: 'Şifre',
                    prefixIcon: Icon(Icons.lock_outline),
                  ),
                  validator: (value) => value == null || value.length < 6
                      ? 'Şifre en az 6 karakter olmalı.'
                      : null,
                ),
                Align(
                  alignment: Alignment.centerRight,
                  child: TextButton(
                    onPressed: _loading
                        ? null
                        : () {
                            Navigator.of(context).push(
                              MaterialPageRoute(
                                builder: (_) => ForgotPasswordScreen(
                                  services: widget.services,
                                  isAdmin: true,
                                ),
                              ),
                            );
                          },
                    child: const Text('Şifremi unuttum'),
                  ),
                ),
                const SizedBox(height: 8),
                SizedBox(
                  width: double.infinity,
                  child: FilledButton(
                    onPressed: _loading ? null : _login,
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
                        : const Text('Admin Olarak Giriş Yap'),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
